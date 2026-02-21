# Missing Backend APIs - DiabCare Flutter Frontend Requirements

**Based on:** Flutter Frontend Analysis vs Existing NestJS Backend  
**Date:** February 20, 2026  
**Purpose:** Document ONLY the APIs that are needed by the Flutter frontend but NOT YET implemented in the backend

---

## 📋 Analysis Summary

### ✅ Already Implemented in Backend (53 APIs)
Your NestJS backend already has these modules fully implemented:
- ✅ Authentication (register patient/doctor/pharmacist, login, profile)
- ✅ Users Management (CRUD, stats)
- ✅ Patients Management (CRUD, by diabetes type)
- ✅ Doctors/Medecins (CRUD, patient assignments, ratings)
- ✅ Pharmacists (CRUD, nearby search, medication inventory, ratings)
- ✅ Glucose Tracking (CRUD, statistics, HbA1c, time-in-range, trends)
- ✅ Nutrition/Meals (CRUD, food items)
- ✅ Medication Requests (full workflow: create, respond, confirm, pickup)
- ✅ Sessions Management (active sessions, logout)
- ✅ Reviews (create, get, summary, delete)
- ✅ Boosts (pharmacy promotions)
- ✅ Activities (pharmacy activity logs)

### ❌ Missing APIs Required by Flutter Frontend (17 APIs)

The Flutter frontend requires these additional APIs that are **NOT in your current backend**:

---

## 🔴 Missing APIs to Implement

### 1. Appointments Management (6 APIs)

#### 1.1 Create Appointment
**Endpoint:** `POST /api/appointments`  
**Access:** Protected (Patient or Doctor)  
**Flutter Usage:** Doctor creates appointment, Patient books appointment  
**Description:** Schedule a new appointment between doctor and patient

**Request Body:**
```json
{
  "patientId": "507f1f77bcf86cd799439030",
  "doctorId": "507f1f77bcf86cd799439012",
  "dateTime": "2024-02-25T10:00:00Z",
  "type": "Online|Physical",
  "notes": "Follow-up consultation"
}
```

**Response:** `201 Created`
```json
{
  "_id": "507f1f77bcf86cd799439200",
  "patientId": "507f1f77bcf86cd799439030",
  "patientName": "John Doe",
  "doctorId": "507f1f77bcf86cd799439012",
  "doctorName": "Dr. Smith",
  "dateTime": "2024-02-25T10:00:00Z",
  "type": "Online",
  "status": "Pending",
  "notes": "Follow-up consultation",
  "createdAt": "2024-02-20T10:30:00Z"
}
```

---

#### 1.2 Get Doctor's Appointments
**Endpoint:** `GET /api/doctors/:doctorId/appointments`  
**Access:** Protected (Doctor only)  
**Flutter Usage:** Doctor dashboard - appointments calendar  
**Description:** Get all appointments for a specific doctor

**Query Parameters:**
```
?date=2024-02-25&status=Confirmed&type=Online
```

**Response:** `200 OK`
```json
{
  "data": [
    {
      "_id": "507f1f77bcf86cd799439200",
      "patientId": "507f1f77bcf86cd799439030",
      "patientName": "John Doe",
      "dateTime": "2024-02-25T10:00:00Z",
      "type": "Online",
      "status": "Confirmed",
      "notes": "Follow-up"
    }
  ],
  "total": 12
}
```

---

#### 1.3 Get Patient's Appointments
**Endpoint:** `GET /api/patients/:patientId/appointments`  
**Access:** Protected (Patient only)  
**Flutter Usage:** Patient view - upcoming appointments  
**Description:** Get all appointments for a specific patient

**Response:** `200 OK`
```json
{
  "data": [
    {
      "_id": "507f1f77bcf86cd799439200",
      "doctorId": "507f1f77bcf86cd799439012",
      "doctorName": "Dr. Smith",
      "specialty": "Endocrinologie",
      "dateTime": "2024-02-25T10:00:00Z",
      "type": "Online",
      "status": "Confirmed"
    }
  ],
  "total": 3
}
```

---

#### 1.4 Get Appointment by ID
**Endpoint:** `GET /api/appointments/:id`  
**Access:** Protected (Patient or Doctor in appointment)  
**Flutter Usage:** View appointment details  
**Description:** Retrieve specific appointment information

**Response:** `200 OK`
```json
{
  "_id": "507f1f77bcf86cd799439200",
  "patientId": "507f1f77bcf86cd799439030",
  "patientName": "John Doe",
  "doctorId": "507f1f77bcf86cd799439012",
  "doctorName": "Dr. Smith",
  "dateTime": "2024-02-25T10:00:00Z",
  "type": "Online",
  "status": "Confirmed",
  "notes": "Follow-up consultation",
  "createdAt": "2024-02-20T10:30:00Z",
  "updatedAt": "2024-02-20T10:30:00Z"
}
```

---

#### 1.5 Update Appointment Status
**Endpoint:** `PATCH /api/appointments/:id`  
**Access:** Protected (Patient or Doctor in appointment)  
**Flutter Usage:** Confirm, cancel, or complete appointment  
**Description:** Update appointment status and details

**Request Body:**
```json
{
  "status": "Confirmed|Pending|Completed|Cancelled",
  "notes": "Updated notes"
}
```

**Response:** `200 OK`
```json
{
  "_id": "507f1f77bcf86cd799439200",
  "status": "Confirmed",
  "notes": "Updated notes",
  "updatedAt": "2024-02-20T11:00:00Z"
}
```

---

#### 1.6 Delete Appointment
**Endpoint:** `DELETE /api/appointments/:id`  
**Access:** Protected (Patient or Doctor in appointment)  
**Flutter Usage:** Cancel/Delete appointment  
**Description:** Remove appointment from schedule

**Response:** `200 OK`
```json
{
  "message": "Appointment deleted successfully"
}
```

---

### 2. Messaging System (5 APIs)

#### 2.1 Get Patient Conversations
**Endpoint:** `GET /api/patients/:patientId/conversations`  
**Access:** Protected (Patient only)  
**Flutter Usage:** Patient chat list screen  
**Description:** Get all conversations for a patient

**Response:** `200 OK`
```json
{
  "conversations": [
    {
      "_id": "507f1f77bcf86cd799439210",
      "doctorId": "507f1f77bcf86cd799439012",
      "doctorName": "Dr. Smith",
      "specialty": "Endocrinologie",
      "patientId": "507f1f77bcf86cd799439030",
      "patientName": "John Doe",
      "lastMessage": "Your glucose levels look good",
      "lastMessageTime": "2024-02-20T10:00:00Z",
      "unreadCount": 2
    }
  ]
}
```

---

#### 2.2 Get Doctor Conversations
**Endpoint:** `GET /api/doctors/:doctorId/conversations`  
**Access:** Protected (Doctor only)  
**Flutter Usage:** Doctor messages screen  
**Description:** Get all conversations for a doctor

**Response:** `200 OK`
```json
{
  "conversations": [
    {
      "_id": "507f1f77bcf86cd799439210",
      "patientId": "507f1f77bcf86cd799439030",
      "patientName": "John Doe",
      "typeDiabete": "TYPE_2",
      "doctorId": "507f1f77bcf86cd799439012",
      "doctorName": "Dr. Smith",
      "lastMessage": "Thank you, doctor",
      "lastMessageTime": "2024-02-20T10:30:00Z",
      "unreadCount": 0
    }
  ]
}
```

---

#### 2.3 Create Conversation
**Endpoint:** `POST /api/conversations`  
**Access:** Protected (Patient or Doctor)  
**Flutter Usage:** Start new chat with doctor  
**Description:** Create a new conversation between patient and doctor

**Request Body:**
```json
{
  "patientId": "507f1f77bcf86cd799439030",
  "doctorId": "507f1f77bcf86cd799439012"
}
```

**Response:** `201 Created`
```json
{
  "_id": "507f1f77bcf86cd799439210",
  "patientId": "507f1f77bcf86cd799439030",
  "patientName": "John Doe",
  "doctorId": "507f1f77bcf86cd799439012",
  "doctorName": "Dr. Smith",
  "lastMessage": "",
  "lastMessageTime": "2024-02-20T10:30:00Z",
  "unreadCount": 0,
  "createdAt": "2024-02-20T10:30:00Z"
}
```

---

#### 2.4 Get Messages in Conversation
**Endpoint:** `GET /api/conversations/:conversationId/messages`  
**Access:** Protected (Patient or Doctor in conversation)  
**Flutter Usage:** Chat detail screen - message history  
**Description:** Retrieve all messages in a conversation

**Query Parameters:**
```
?limit=50&before=2024-02-20T10:00:00Z
```

**Response:** `200 OK`
```json
{
  "messages": [
    {
      "_id": "507f1f77bcf86cd799439220",
      "conversationId": "507f1f77bcf86cd799439210",
      "senderId": "507f1f77bcf86cd799439012",
      "senderName": "Dr. Smith",
      "receiverId": "507f1f77bcf86cd799439030",
      "content": "How are you feeling today?",
      "timestamp": "2024-02-20T09:00:00Z",
      "isRead": true
    },
    {
      "_id": "507f1f77bcf86cd799439221",
      "conversationId": "507f1f77bcf86cd799439210",
      "senderId": "507f1f77bcf86cd799439030",
      "senderName": "John Doe",
      "receiverId": "507f1f77bcf86cd799439012",
      "content": "I'm feeling much better, thank you!",
      "timestamp": "2024-02-20T10:30:00Z",
      "isRead": false
    }
  ],
  "hasMore": true
}
```

---

#### 2.5 Send Message
**Endpoint:** `POST /api/conversations/:conversationId/messages`  
**Access:** Protected (Patient or Doctor in conversation)  
**Flutter Usage:** Send message in chat  
**Description:** Send a new message in conversation

**Request Body:**
```json
{
  "content": "I'm feeling much better, thank you!"
}
```

**Response:** `201 Created`
```json
{
  "_id": "507f1f77bcf86cd799439221",
  "conversationId": "507f1f77bcf86cd799439210",
  "senderId": "507f1f77bcf86cd799439030",
  "senderName": "John Doe",
  "receiverId": "507f1f77bcf86cd799439012",
  "content": "I'm feeling much better, thank you!",
  "timestamp": "2024-02-20T10:30:00Z",
  "isRead": false
}
```

---

### 3. Doctor Patient Requests (3 APIs)

#### 3.1 Get Patient Requests
**Endpoint:** `GET /api/doctors/:doctorId/patient-requests`  
**Access:** Protected (Doctor only)  
**Flutter Usage:** Doctor dashboard - pending patient requests  
**Description:** Get all patient requests waiting for doctor approval

**Response:** `200 OK`
```json
{
  "requests": [
    {
      "_id": "507f1f77bcf86cd799439230",
      "patientId": "507f1f77bcf86cd799439030",
      "patientName": "John Doe",
      "age": 35,
      "diabetesType": "TYPE_2",
      "requestDate": "2024-02-20T10:00:00Z",
      "hasUrgentNote": false,
      "status": "pending",
      "urgentNote": ""
    }
  ],
  "total": 5
}
```

---

#### 3.2 Accept Patient Request
**Endpoint:** `POST /api/doctors/:doctorId/patient-requests/:requestId/accept`  
**Access:** Protected (Doctor only)  
**Flutter Usage:** Accept button in patient request card  
**Description:** Doctor accepts patient request and adds patient to their list

**Response:** `200 OK`
```json
{
  "success": true,
  "message": "Patient request accepted",
  "patientId": "507f1f77bcf86cd799439030",
  "requestId": "507f1f77bcf86cd799439230"
}
```

---

#### 3.3 Decline Patient Request
**Endpoint:** `POST /api/doctors/:doctorId/patient-requests/:requestId/decline`  
**Access:** Protected (Doctor only)  
**Flutter Usage:** Decline button in patient request card  
**Description:** Doctor declines patient request

**Request Body:**
```json
{
  "reason": "Patient limit reached"
}
```

**Response:** `200 OK`
```json
{
  "success": true,
  "message": "Patient request declined",
  "requestId": "507f1f77bcf86cd799439230"
}
```

---

### 4. Notifications (2 APIs)

#### 4.1 Get User Notifications
**Endpoint:** `GET /api/notifications`  
**Access:** Protected (Any authenticated user)  
**Flutter Usage:** Notifications screen, notification bell badge  
**Description:** Get all notifications for current user

**Query Parameters:**
```
?unreadOnly=true&limit=20&type=patient_alert
```

**Response:** `200 OK`
```json
{
  "notifications": [
    {
      "_id": "507f1f77bcf86cd799439240",
      "userId": "507f1f77bcf86cd799439012",
      "type": "patient_alert|new_request|appointment|message",
      "title": "Critical Glucose Alert",
      "message": "Patient John Doe has critical glucose level: 250 mg/dL",
      "timestamp": "2024-02-20T10:30:00Z",
      "isRead": false,
      "relatedId": "507f1f77bcf86cd799439030",
      "severity": "critical|warning|info"
    }
  ],
  "unreadCount": 3
}
```

---

#### 4.2 Mark Notification as Read
**Endpoint:** `PATCH /api/notifications/:notificationId/read`  
**Access:** Protected (Owner only)  
**Flutter Usage:** When user views notification  
**Description:** Mark specific notification as read

**Response:** `200 OK`
```json
{
  "success": true,
  "_id": "507f1f77bcf86cd799439240",
  "isRead": true
}
```

---

### 5. Patient Request Doctor (1 API)

#### 5.1 Request to Add Doctor
**Endpoint:** `POST /api/patients/:patientId/request-doctor`  
**Access:** Protected (Patient only)  
**Flutter Usage:** "Request Doctor" button in Find Doctors screen  
**Description:** Patient sends request to connect with a doctor

**Request Body:**
```json
{
  "doctorId": "507f1f77bcf86cd799439012",
  "urgentNote": "Need urgent consultation"
}
```

**Response:** `201 Created`
```json
{
  "_id": "507f1f77bcf86cd799439230",
  "patientId": "507f1f77bcf86cd799439030",
  "doctorId": "507f1f77bcf86cd799439012",
  "status": "pending",
  "requestDate": "2024-02-20T10:30:00Z",
  "urgentNote": "Need urgent consultation"
}
```

---

## 📊 New Database Schemas Required

### Appointment Schema
```typescript
{
  _id: ObjectId,
  patientId: ObjectId, // ref: 'Patient'
  doctorId: ObjectId, // ref: 'Medecin'
  dateTime: Date,
  type: 'Online' | 'Physical',
  status: 'Confirmed' | 'Pending' | 'Completed' | 'Cancelled',
  notes: String,
  createdAt: Date,
  updatedAt: Date
}
```

### Conversation Schema
```typescript
{
  _id: ObjectId,
  patientId: ObjectId, // ref: 'Patient'
  doctorId: ObjectId, // ref: 'Medecin'
  lastMessage: String,
  lastMessageTime: Date,
  createdAt: Date,
  updatedAt: Date
}
```

### Message Schema
```typescript
{
  _id: ObjectId,
  conversationId: ObjectId, // ref: 'Conversation'
  senderId: ObjectId, // ref: 'User'
  receiverId: ObjectId, // ref: 'User'
  content: String,
  timestamp: Date,
  isRead: Boolean,
  createdAt: Date
}
```

### PatientRequest Schema
```typescript
{
  _id: ObjectId,
  patientId: ObjectId, // ref: 'Patient'
  doctorId: ObjectId, // ref: 'Medecin'
  status: 'pending' | 'accepted' | 'declined',
  requestDate: Date,
  urgentNote: String,
  declineReason: String,
  createdAt: Date,
  updatedAt: Date
}
```

### Notification Schema
```typescript
{
  _id: ObjectId,
  userId: ObjectId, // ref: 'User'
  type: 'patient_alert' | 'new_request' | 'appointment' | 'message',
  title: String,
  message: String,
  timestamp: Date,
  isRead: Boolean,
  relatedId: ObjectId, // Generic reference to related entity
  severity: 'info' | 'warning' | 'critical',
  createdAt: Date
}
```

---

## 🎯 Implementation Priority

### High Priority (Core Features - Week 1)
1. **Appointments Management** (6 APIs) - Essential for doctor-patient interaction
2. **Messaging System** (5 APIs) - Critical for real-time communication

### Medium Priority (Enhanced UX - Week 2)
3. **Doctor Patient Requests** (3 APIs) - Workflow improvement
4. **Notifications** (2 APIs) - User engagement

### Low Priority (Optional - Week 3)
5. **Patient Request Doctor** (1 API) - Alternative request flow

---

## 🔧 NestJS Implementation Guide

### Step 1: Create Appointments Module

```bash
nest g module appointments
nest g controller appointments
nest g service appointments
```

**appointments.schema.ts:**
```typescript
import { Prop, Schema, SchemaFactory } from '@nestjs/mongoose';
import { Document, Types } from 'mongoose';

@Schema({ timestamps: true })
export class Appointment extends Document {
  @Prop({ type: Types.ObjectId, ref: 'Patient', required: true })
  patientId: Types.ObjectId;

  @Prop({ type: Types.ObjectId, ref: 'Medecin', required: true })
  doctorId: Types.ObjectId;

  @Prop({ required: true })
  dateTime: Date;

  @Prop({ enum: ['Online', 'Physical'], default: 'Physical' })
  type: string;

  @Prop({ enum: ['Confirmed', 'Pending', 'Completed', 'Cancelled'], default: 'Pending' })
  status: string;

  @Prop()
  notes: string;
}

export const AppointmentSchema = SchemaFactory.createForClass(Appointment);
```

**appointments.controller.ts:**
```typescript
import { Controller, Get, Post, Patch, Delete, Body, Param, Query, UseGuards } from '@nestjs/common';
import { JwtAuthGuard } from '../auth/jwt-auth.guard';
import { RolesGuard } from '../auth/roles.guard';
import { Roles } from '../auth/roles.decorator';
import { Role } from '../common/enums/role.enum';

@Controller('appointments')
@UseGuards(JwtAuthGuard, RolesGuard)
export class AppointmentsController {
  constructor(private readonly appointmentsService: AppointmentsService) {}

  @Post()
  @Roles(Role.PATIENT, Role.MEDECIN)
  create(@Body() createDto: CreateAppointmentDto) {
    return this.appointmentsService.create(createDto);
  }

  @Get('doctors/:doctorId')
  @Roles(Role.MEDECIN)
  getDoctorAppointments(@Param('doctorId') doctorId: string, @Query() query: any) {
    return this.appointmentsService.getDoctorAppointments(doctorId, query);
  }

  @Get('patients/:patientId')
  @Roles(Role.PATIENT)
  getPatientAppointments(@Param('patientId') patientId: string) {
    return this.appointmentsService.getPatientAppointments(patientId);
  }

  @Get(':id')
  findOne(@Param('id') id: string) {
    return this.appointmentsService.findOne(id);
  }

  @Patch(':id')
  update(@Param('id') id: string, @Body() updateDto: UpdateAppointmentDto) {
    return this.appointmentsService.update(id, updateDto);
  }

  @Delete(':id')
  remove(@Param('id') id: string) {
    return this.appointmentsService.remove(id);
  }
}
```

---

### Step 2: Create Conversations & Messages Module

```bash
nest g module conversations
nest g controller conversations
nest g service conversations
```

**conversation.schema.ts:**
```typescript
@Schema({ timestamps: true })
export class Conversation extends Document {
  @Prop({ type: Types.ObjectId, ref: 'Patient', required: true })
  patientId: Types.ObjectId;

  @Prop({ type: Types.ObjectId, ref: 'Medecin', required: true })
  doctorId: Types.ObjectId;

  @Prop({ default: '' })
  lastMessage: string;

  @Prop({ default: Date.now })
  lastMessageTime: Date;
}
```

**message.schema.ts:**
```typescript
@Schema({ timestamps: true })
export class Message extends Document {
  @Prop({ type: Types.ObjectId, ref: 'Conversation', required: true })
  conversationId: Types.ObjectId;

  @Prop({ type: Types.ObjectId, ref: 'User', required: true })
  senderId: Types.ObjectId;

  @Prop({ type: Types.ObjectId, ref: 'User', required: true })
  receiverId: Types.ObjectId;

  @Prop({ required: true })
  content: string;

  @Prop({ default: Date.now })
  timestamp: Date;

  @Prop({ default: false })
  isRead: boolean;
}
```

---

### Step 3: Create Patient Requests Module

```bash
nest g module patient-requests
nest g controller patient-requests
nest g service patient-requests
```

**patient-request.schema.ts:**
```typescript
@Schema({ timestamps: true })
export class PatientRequest extends Document {
  @Prop({ type: Types.ObjectId, ref: 'Patient', required: true })
  patientId: Types.ObjectId;

  @Prop({ type: Types.ObjectId, ref: 'Medecin', required: true })
  doctorId: Types.ObjectId;

  @Prop({ enum: ['pending', 'accepted', 'declined'], default: 'pending' })
  status: string;

  @Prop({ default: Date.now })
  requestDate: Date;

  @Prop()
  urgentNote: string;

  @Prop()
  declineReason: string;
}
```

---

### Step 4: Create Notifications Module

```bash
nest g module notifications
nest g controller notifications
nest g service notifications
```

**notification.schema.ts:**
```typescript
@Schema({ timestamps: true })
export class Notification extends Document {
  @Prop({ type: Types.ObjectId, ref: 'User', required: true })
  userId: Types.ObjectId;

  @Prop({ enum: ['patient_alert', 'new_request', 'appointment', 'message'], required: true })
  type: string;

  @Prop({ required: true })
  title: string;

  @Prop({ required: true })
  message: string;

  @Prop({ default: Date.now })
  timestamp: Date;

  @Prop({ default: false })
  isRead: boolean;

  @Prop({ type: Types.ObjectId })
  relatedId: Types.ObjectId;

  @Prop({ enum: ['info', 'warning', 'critical'], default: 'info' })
  severity: string;
}
```

---

## 📋 Integration Checklist

### Before Implementation
- [ ] Review existing backend code structure
- [ ] Confirm MongoDB connection is working
- [ ] Verify JWT authentication is properly configured
- [ ] Check existing guards and decorators

### During Implementation
- [ ] Create all 5 new modules (appointments, conversations, patient-requests, notifications, messages)
- [ ] Define Mongoose schemas with proper refs and indexes
- [ ] Implement DTOs with class-validator decorators
- [ ] Add proper guards (@UseGuards(JwtAuthGuard, RolesGuard))
- [ ] Add role restrictions (@Roles(Role.PATIENT))
- [ ] Implement pagination for list endpoints
- [ ] Add proper error handling

### After Implementation
- [ ] Test all endpoints with Postman/Thunder Client
- [ ] Verify authentication works correctly
- [ ] Test role-based access control
- [ ] Verify data relationships (populate refs)
- [ ] Test with Flutter frontend
- [ ] Update Swagger documentation
- [ ] Add unit tests for services
- [ ] Add E2E tests for critical flows

---

## 🚀 Quick Start Commands

```bash
# Generate all modules at once
nest g module appointments
nest g controller appointments
nest g service appointments

nest g module conversations
nest g controller conversations
nest g service conversations

nest g module patient-requests
nest g controller patient-requests  
nest g service patient-requests

nest g module notifications
nest g controller notifications
nest g service notifications

# Install additional dependencies (if needed)
npm install @nestjs/websockets @nestjs/platform-socket.io
# For real-time messaging (optional enhancement)
```

---

## 📝 Testing Examples

### Test Appointment Creation
```bash
curl -X POST http://localhost:3000/api/appointments \
  -H "Authorization: Bearer YOUR_JWT_TOKEN" \
  -H "Content-Type: application/json" \
  -d '{
    "patientId": "507f1f77bcf86cd799439030",
    "doctorId": "507f1f77bcf86cd799439012",
    "dateTime": "2024-02-25T10:00:00Z",
    "type": "Online",
    "notes": "Follow-up"
  }'
```

### Test Send Message
```bash
curl -X POST http://localhost:3000/api/conversations/CONVERSATION_ID/messages \
  -H "Authorization: Bearer YOUR_JWT_TOKEN" \
  -H "Content-Type: application/json" \
  -d '{
    "content": "Hello, doctor!"
  }'
```

---

## 🎯 Flutter Integration Points

### Update Flutter Auth Service
```dart
// Add base URL if not already configured
static const String baseUrl = 'http://10.0.2.2:3000'; // Android emulator
// Or 'http://localhost:3000' for iOS simulator
// Or 'https://your-production-api.com' for production
```

### Appointments in Flutter
```dart
// Create appointment
final response = await http.post(
  Uri.parse('$baseUrl/api/appointments'),
  headers: {
    'Authorization': 'Bearer $token',
    'Content-Type': 'application/json',
  },
  body: jsonEncode({
    'patientId': patientId,
    'doctorId': doctorId,
    'dateTime': dateTime.toIso8601String(),
    'type': 'Online',
  }),
);
```

### Messaging in Flutter
```dart
// Get conversations
final response = await http.get(
  Uri.parse('$baseUrl/api/patients/$patientId/conversations'),
  headers: {'Authorization': 'Bearer $token'},
);

// Send message
await http.post(
  Uri.parse('$baseUrl/api/conversations/$conversationId/messages'),
  headers: {
    'Authorization': 'Bearer $token',
    'Content-Type': 'application/json',
  },
  body: jsonEncode({'content': messageText}),
);
```

---

## ⚠️ Important Notes

1. **Existing APIs Work Perfect**: Don't modify your existing 53 APIs - they match the Flutter frontend requirements
2. **Authentication**: All new endpoints should use your existing JWT auth setup
3. **Guards**: Use your existing JwtAuthGuard and RolesGuard
4. **Pagination**: Follow your existing pagination pattern (page, limit)
5. **Error Handling**: Use your existing error handling middleware
6. **Validation**: Use class-validator DTOs like your existing endpoints
7. **MongoDB Refs**: Use proper references to existing User/Patient/Medecin collections

---

## 📚 Summary

**Total Missing APIs: 17**
- Appointments: 6 APIs
- Messaging: 5 APIs  
- Patient Requests: 3 APIs
- Notifications: 2 APIs
- Request Doctor: 1 API

**Estimated Implementation Time:**
- With experience: 2-3 days
- New to NestJS: 5-7 days

**All your existing 53 APIs are perfect and require NO changes!**

---

**Last Updated:** February 20, 2026  
**Status:** Ready for Implementation  
**Compatibility:** NestJS 11.x, MongoDB 8.x, Mongoose 11.x

