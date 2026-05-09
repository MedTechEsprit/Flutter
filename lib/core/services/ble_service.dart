import 'dart:async';
import 'dart:convert';
import 'package:flutter_reactive_ble/flutter_reactive_ble.dart';

class BleService {
  BleService._private();
  static final BleService instance = BleService._private();

  final _ble = FlutterReactiveBle();
  final _glucoseController = StreamController<double>.broadcast();
  final _connectionController = StreamController<ConnectionStateUpdate>.broadcast();
  bool _isConnected = false;
  bool _isNotifying = false;

  Stream<double> get glucoseStream => _glucoseController.stream;
  Stream<ConnectionStateUpdate> get connectionStream => _connectionController.stream;
  bool get isConnected => _isConnected;
  bool get isNotifying => _isNotifying;

  DiscoveredDevice? _foundDevice;
  StreamSubscription<DiscoveredDevice>? _scanSub;
  StreamSubscription<ConnectionStateUpdate>? _connection;
  StreamSubscription<List<int>>? _notifySub;

  static final Uuid _serviceUuid = Uuid.parse('6e400001-b5a3-f393-e0a9-e50e24dcca9e');
  static final Uuid _charNotifyUuid = Uuid.parse('6e400003-b5a3-f393-e0a9-e50e24dcca9e');

  /// Start scanning and connect to the first GlucoMeter device found.
  void startScanAndConnect({Duration timeout = const Duration(seconds: 8)}) {
    stopScan();
    _scanSub = _ble.scanForDevices(withServices: [_serviceUuid]).listen((device) {
      if (_foundDevice == null) {
        _foundDevice = device;
        _connectToDevice(device.id);
      }
    });
    // optional timeout to stop scanning
    Future.delayed(timeout, () => stopScan());
  }

  void stopScan() {
    _scanSub?.cancel();
    _scanSub = null;
  }

  void _connectToDevice(String deviceId) {
    _connection?.cancel();
    _connection = _ble.connectToDevice(id: deviceId).listen((update) {
      _isConnected = update.connectionState == DeviceConnectionState.connected;
      _connectionController.add(update);
      if (update.connectionState == DeviceConnectionState.connected) {
        _subscribeToNotifications(deviceId);
      } else if (update.connectionState == DeviceConnectionState.disconnected) {
        _notifySub?.cancel();
        _notifySub = null;
        _isNotifying = false;
      }
    }, onError: (e) {
      // connection errors
    });
  }

  void _subscribeToNotifications(String deviceId) {
    final characteristic = QualifiedCharacteristic(
      serviceId: _serviceUuid,
      characteristicId: _charNotifyUuid,
      deviceId: deviceId,
    );

    _notifySub?.cancel();
    _notifySub = _ble.subscribeToCharacteristic(characteristic).listen((data) {
      _isNotifying = true;
      final text = utf8.decode(data, allowMalformed: true).trim();
      print('BLE RAW: $text');
      try {
        final parsed = jsonDecode(text) as Map<String, dynamic>;
        final value = (parsed['glucose'] as num).toDouble();
        final unit = parsed['unit']?.toString() ?? 'mg/dL';
        print('BLE glucose: $value $unit');
        _glucoseController.add(value);
      } catch (e) {
        final match = RegExp(r'(-?\d+(?:\.\d+)?)').firstMatch(text);
        if (match != null) {
          final value = double.parse(match.group(1)!);
          print('BLE glucose (fallback): $value');
          _glucoseController.add(value);
        } else {
          print('BLE parse error: $e');
        }
      }
    }, onError: (e) {
      print('BLE notify error: $e');
    });
  }

  Future<void> disconnect() async {
    await _notifySub?.cancel();
    _notifySub = null;
    await _connection?.cancel();
    _connection = null;
    _foundDevice = null;
    _isConnected = false;
    _isNotifying = false;
  }

  void dispose() {
    _glucoseController.close();
    _connectionController.close();
    stopScan();
    disconnect();
  }
}
