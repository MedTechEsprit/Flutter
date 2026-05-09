import 'package:flutter/material.dart';
import 'package:diab_care/core/theme/app_colors.dart';
import 'package:diab_care/data/services/complaint_service.dart';

class ComplaintDialog extends StatefulWidget {
  const ComplaintDialog({super.key});

  @override
  State<ComplaintDialog> createState() => _ComplaintDialogState();
}

class _ComplaintDialogState extends State<ComplaintDialog> {
  final _formKey = GlobalKey<FormState>();
  final _subjectController = TextEditingController();
  final _messageController = TextEditingController();
  final _complaintService = ComplaintService();
  bool _isSubmitting = false;
  String _category = 'general';

  @override
  void dispose() {
    _subjectController.dispose();
    _messageController.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() => _isSubmitting = true);

    try {
      await _complaintService.createComplaint(
        subject: _subjectController.text.trim(),
        message: _messageController.text.trim(),
        category: _category,
      );

      if (!mounted) return;
      Navigator.of(context).pop(true);
    } catch (_) {
      if (!mounted) return;
      setState(() => _isSubmitting = false);
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Impossible d\'envoyer la réclamation'),
          backgroundColor: Color(0xFFFF6B6B),
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text('Nouvelle réclamation'),
      content: Form(
        key: _formKey,
        child: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              DropdownButtonFormField<String>(
                value: _category,
                decoration: const InputDecoration(labelText: 'Catégorie'),
                items: const [
                  DropdownMenuItem(value: 'general', child: Text('Général')),
                  DropdownMenuItem(value: 'technical', child: Text('Technique')),
                  DropdownMenuItem(value: 'billing', child: Text('Facturation')),
                  DropdownMenuItem(value: 'account', child: Text('Compte')),
                ],
                onChanged: (value) => setState(() => _category = value ?? 'general'),
              ),
              const SizedBox(height: 12),
              TextFormField(
                controller: _subjectController,
                maxLength: 120,
                decoration: const InputDecoration(labelText: 'Sujet'),
                validator: (value) {
                  if (value == null || value.trim().isEmpty) {
                    return 'Sujet requis';
                  }
                  return null;
                },
              ),
              TextFormField(
                controller: _messageController,
                maxLines: 5,
                maxLength: 2000,
                decoration: const InputDecoration(labelText: 'Message'),
                validator: (value) {
                  if (value == null || value.trim().isEmpty) {
                    return 'Message requis';
                  }
                  return null;
                },
              ),
            ],
          ),
        ),
      ),
      actions: [
        TextButton(
          onPressed: _isSubmitting ? null : () => Navigator.of(context).pop(false),
          child: const Text('Annuler'),
        ),
        ElevatedButton(
          style: ElevatedButton.styleFrom(
            backgroundColor: AppColors.softGreen,
            foregroundColor: Colors.white,
          ),
          onPressed: _isSubmitting ? null : _submit,
          child: _isSubmitting
              ? const SizedBox(
                  width: 18,
                  height: 18,
                  child: CircularProgressIndicator(
                    strokeWidth: 2,
                    valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                  ),
                )
              : const Text('Envoyer'),
        ),
      ],
    );
  }
}