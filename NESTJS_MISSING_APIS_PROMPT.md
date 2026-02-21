# NestJS Missing APIs - Copilot Generation Prompt

**Purpose:** Generate ONLY the missing 17 APIs needed by the Flutter frontend  
**Target:** Existing NestJS project with 53 APIs already implemented  
**Action:** Add 5 new modules without modifying existing code

---

## 🎯 Main Generation Prompt for GitHub Copilot

Copy and paste this prompt into VS Code (in your existing NestJS project folder):

```
I have an existing NestJS 11.x project with MongoDB/Mongoose that already has these modules working:
- Auth (JWT, register, login)
- Users, Patients, Medecins, Pharmaciens (full CRUD)
- Glucose tracking with statistics
- Nutrition/Meals management
- Medication requests workflow
- Sessions, Reviews, Boosts, Activities

I need to ADD 5 new modules with 17 endpoints total, following my existing code patterns.

EXISTING CODE PATTERNS TO FOLLOW:
- Use @nestjs/mongoose with Mongoose schemas
- Use class-validator DTOs
- Use existing JwtAuthGuard and RolesGuard
- Use existing Role enum (PATIENT, MEDECIN, PHARMACIEN)
- Follow existing pagination pattern (page, limit)
- Use Types.ObjectId for MongoDB refs
- Include @ApiTags() and Swagger decorators
- Return consistent response format

MODULE 1: APPOINTMENTS MODULE
Location: src/appointments/

Schema (appointments.schema.ts):
@Schema({ timestamps: true })
export class Appointment extends Document {
  @Prop({ type: Types.ObjectId, ref: 'Patient', required: true, index: true })
  patientId: Types.ObjectId;

  @Prop({ type: Types.ObjectId, ref: 'Medecin', required: true, index: true })
  doctorId: Types.ObjectId;

  @Prop({ required: true, index: true })
  dateTime: Date;

  @Prop({ enum: ['Online', 'Physical'], default: 'Physical' })
  type: string;

  @Prop({ enum: ['Confirmed', 'Pending', 'Completed', 'Cancelled'], default: 'Pending' })
  status: string;

  @Prop()
  notes: string;
}

DTOs needed:
- CreateAppointmentDto (patientId, doctorId, dateTime, type, notes)
- UpdateAppointmentDto (status, notes - all optional)

Controller endpoints (appointments.controller.ts):
1. POST /api/appointments - @Roles(Role.PATIENT, Role.MEDECIN) - Create appointment
2. GET /api/doctors/:doctorId/appointments - @Roles(Role.MEDECIN) - Get doctor's appointments with query filters (date, status, type)
3. GET /api/patients/:patientId/appointments - @Roles(Role.PATIENT) - Get patient's appointments
4. GET /api/appointments/:id - Get single appointment (patient or doctor in appointment)
5. PATCH /api/appointments/:id - Update appointment status
6. DELETE /api/appointments/:id - Delete appointment

Service methods:
- create(dto) - Create and populate patient/doctor names
- getDoctorAppointments(doctorId, filters) - Filter by date, status, type
- getPatientAppointments(patientId) - Get all patient appointments
- findOne(id) - Populate patient and doctor info
- update(id, dto) - Update status/notes
- remove(id) - Delete appointment

---

MODULE 2: CONVERSATIONS & MESSAGES MODULES
Location: src/conversations/ and src/messages/

Conversation Schema (conversations.schema.ts):
@Schema({ timestamps: true })
export class Conversation extends Document {
  @Prop({ type: Types.ObjectId, ref: 'Patient', required: true, index: true })
  patientId: Types.ObjectId;

  @Prop({ type: Types.ObjectId, ref: 'Medecin', required: true, index: true })
  doctorId: Types.ObjectId;

  @Prop({ default: '' })
  lastMessage: string;

  @Prop({ default: Date.now })
  lastMessageTime: Date;
}
// Add compound index: { patientId: 1, doctorId: 1 } unique

Message Schema (messages.schema.ts):
@Schema({ timestamps: true })
export class Message extends Document {
  @Prop({ type: Types.ObjectId, ref: 'Conversation', required: true, index: true })
  conversationId: Types.ObjectId;

  @Prop({ type: Types.ObjectId, ref: 'User', required: true })
  senderId: Types.ObjectId;

  @Prop({ type: Types.ObjectId, ref: 'User', required: true })
  receiverId: Types.ObjectId;

  @Prop({ required: true })
  content: string;

  @Prop({ default: Date.now, index: true })
  timestamp: Date;

  @Prop({ default: false })
  isRead: boolean;
}

DTOs needed:
- CreateConversationDto (patientId, doctorId)
- SendMessageDto (content: string)

Conversations Controller endpoints (conversations.controller.ts):
1. GET /api/patients/:patientId/conversations - @Roles(Role.PATIENT) - Get patient conversations with unread count
2. GET /api/doctors/:doctorId/conversations - @Roles(Role.MEDECIN) - Get doctor conversations
3. POST /api/conversations - @Roles(Role.PATIENT, Role.MEDECIN) - Create new conversation
4. GET /api/conversations/:conversationId/messages - Get messages with pagination (limit, before timestamp)
5. POST /api/conversations/:conversationId/messages - Send message and update conversation lastMessage

Service methods:
- getPatientConversations(patientId) - Populate doctor info, count unread messages
- getDoctorConversations(doctorId) - Populate patient info
- create(dto) - Check if conversation already exists
- getMessages(conversationId, limit, before) - Paginated messages
- sendMessage(conversationId, senderId, content) - Create message and update conversation

---

MODULE 3: PATIENT REQUESTS MODULE
Location: src/patient-requests/

Schema (patient-request.schema.ts):
@Schema({ timestamps: true })
export class PatientRequest extends Document {
  @Prop({ type: Types.ObjectId, ref: 'Patient', required: true, index: true })
  patientId: Types.ObjectId;

  @Prop({ type: Types.ObjectId, ref: 'Medecin', required: true, index: true })
  doctorId: Types.ObjectId;

  @Prop({ enum: ['pending', 'accepted', 'declined'], default: 'pending', index: true })
  status: string;

  @Prop({ default: Date.now })
  requestDate: Date;

  @Prop()
  urgentNote: string;

  @Prop()
  declineReason: string;
}

DTOs needed:
- CreatePatientRequestDto (doctorId, urgentNote - optional)
- DeclineRequestDto (reason: string)

Controller endpoints (patient-requests.controller.ts):
1. GET /api/doctors/:doctorId/patient-requests - @Roles(Role.MEDECIN) - Get pending requests with patient info
2. POST /api/doctors/:doctorId/patient-requests/:requestId/accept - @Roles(Role.MEDECIN) - Accept request, add patient to doctor
3. POST /api/doctors/:doctorId/patient-requests/:requestId/decline - @Roles(Role.MEDECIN) - Decline with reason
4. POST /api/patients/:patientId/request-doctor - @Roles(Role.PATIENT) - Create request

Service methods:
- getDoctorRequests(doctorId) - Get pending requests with patient details
- acceptRequest(doctorId, requestId) - Update status, add patient to Medecin.patientIds array
- declineRequest(requestId, reason) - Update status and reason
- createRequest(patientId, dto) - Check if request already exists

---

MODULE 4: NOTIFICATIONS MODULE
Location: src/notifications/

Schema (notification.schema.ts):
@Schema({ timestamps: true })
export class Notification extends Document {
  @Prop({ type: Types.ObjectId, ref: 'User', required: true, index: true })
  userId: Types.ObjectId;

  @Prop({ enum: ['patient_alert', 'new_request', 'appointment', 'message'], required: true })
  type: string;

  @Prop({ required: true })
  title: string;

  @Prop({ required: true })
  message: string;

  @Prop({ default: Date.now, index: true })
  timestamp: Date;

  @Prop({ default: false, index: true })
  isRead: boolean;

  @Prop({ type: Types.ObjectId })
  relatedId: Types.ObjectId;

  @Prop({ enum: ['info', 'warning', 'critical'], default: 'info' })
  severity: string;
}

DTOs needed:
- CreateNotificationDto (userId, type, title, message, relatedId, severity)

Controller endpoints (notifications.controller.ts):
1. GET /api/notifications - Get user notifications with filters (unreadOnly, type, limit)
2. PATCH /api/notifications/:notificationId/read - Mark as read

Service methods:
- getUserNotifications(userId, filters) - Paginated, filter by isRead and type
- markAsRead(notificationId) - Set isRead to true
- create(dto) - Create notification (used internally by other modules)

---

INTEGRATION REQUIREMENTS:

1. Update AppModule imports to include new modules:
imports: [
  // ... existing modules
  AppointmentsModule,
  ConversationsModule,
  MessagesModule,
  PatientRequestsModule,
  NotificationsModule,
]

2. Create helper service for notifications:
- When doctor accepts patient request → create notification for patient
- When critical glucose detected → create notification for doctor
- When message sent → create notification for receiver
- When appointment created → create notifications for both

3. Add virtual fields where needed:
- Appointment: populate patientName, doctorName
- Conversation: calculate unreadCount from messages
- Message: populate senderName

4. Indexes for performance:
- Appointment: { doctorId: 1, dateTime: 1 }
- Conversation: { patientId: 1, doctorId: 1 } unique
- Message: { conversationId: 1, timestamp: -1 }
- PatientRequest: { doctorId: 1, status: 1 }
- Notification: { userId: 1, isRead: 1, timestamp: -1 }

5. Error handling:
- Use NotFoundException for missing documents
- Use BadRequestException for validation errors
- Use ConflictException for duplicate conversations/requests

Generate complete, production-ready code following these exact specifications. Include:
- All schemas with proper decorators and indexes
- All DTOs with class-validator decorators
- All controllers with proper guards and Swagger docs
- All services with error handling
- Export statements in module files
- Integration points clearly commented
```

---

## 📋 Step-by-Step Generation (Alternative Approach)

If you prefer to generate module by module:

### Step 1: Appointments Module

```
Create a complete NestJS appointments module with:

Schema: Appointment
- patientId (ObjectId ref Patient, indexed)
- doctorId (ObjectId ref Medecin, indexed)
- dateTime (Date, indexed)
- type (enum: Online/Physical)
- status (enum: Confirmed/Pending/Completed/Cancelled)
- notes (string)
- timestamps

DTOs:
- CreateAppointmentDto (all required except notes)
- UpdateAppointmentDto (status, notes - optional)

Controller with 6 endpoints:
1. POST /api/appointments - create (patient or doctor role)
2. GET /api/doctors/:doctorId/appointments - get doctor appointments with filters
3. GET /api/patients/:patientId/appointments - get patient appointments
4. GET /api/appointments/:id - get single
5. PATCH /api/appointments/:id - update status
6. DELETE /api/appointments/:id - delete

Use JwtAuthGuard and RolesGuard from existing code.
Add Swagger decorators.
Populate patient and doctor names in responses.
```

### Step 2: Conversations & Messages

```
Create two related NestJS modules:

CONVERSATIONS MODULE:
Schema: Conversation
- patientId (ObjectId ref Patient, indexed)
- doctorId (ObjectId ref Medecin, indexed)
- lastMessage (string)
- lastMessageTime (Date)
- Unique compound index on patientId + doctorId

MESSAGES MODULE:
Schema: Message
- conversationId (ObjectId ref Conversation, indexed)
- senderId (ObjectId ref User)
- receiverId (ObjectId ref User)
- content (string)
- timestamp (Date, indexed)
- isRead (boolean)

Conversations Controller:
1. GET /api/patients/:patientId/conversations - with unread count
2. GET /api/doctors/:doctorId/conversations - with unread count
3. POST /api/conversations - create conversation
4. GET /api/conversations/:id/messages - paginated messages
5. POST /api/conversations/:id/messages - send message

Follow existing JWT auth and role patterns.
```

### Step 3: Patient Requests

```
Create NestJS patient-requests module:

Schema: PatientRequest
- patientId (ObjectId ref Patient, indexed)
- doctorId (ObjectId ref Medecin, indexed)
- status (enum: pending/accepted/declined, indexed)
- requestDate (Date)
- urgentNote (string)
- declineReason (string)

Controller with 4 endpoints:
1. GET /api/doctors/:doctorId/patient-requests - get pending
2. POST /api/doctors/:id/patient-requests/:requestId/accept - accept and add patient to doctor
3. POST /api/doctors/:id/patient-requests/:requestId/decline - decline with reason
4. POST /api/patients/:patientId/request-doctor - create request

When accepting request, also add patientId to Medecin.patientIds array.
Use existing auth guards and roles.
```

### Step 4: Notifications

```
Create NestJS notifications module:

Schema: Notification
- userId (ObjectId ref User, indexed)
- type (enum: patient_alert/new_request/appointment/message)
- title (string)
- message (string)
- timestamp (Date, indexed)
- isRead (boolean, indexed)
- relatedId (ObjectId - generic reference)
- severity (enum: info/warning/critical)

Controller with 2 endpoints:
1. GET /api/notifications - get user notifications with filters (unreadOnly, type, limit)
2. PATCH /api/notifications/:id/read - mark as read

Create helper service method to send notifications from other modules.
Add compound index on userId + isRead + timestamp.
```

---

## 🚀 Quick Integration Commands

After generation, run these commands in your NestJS project:

```bash
# Generate modules (if doing manually)
nest g module appointments
nest g controller appointments
nest g service appointments

nest g module conversations
nest g controller conversations
nest g service conversations

nest g module messages  
nest g controller messages
nest g service messages

nest g module patient-requests
nest g controller patient-requests
nest g service patient-requests

nest g module notifications
nest g controller notifications
nest g service notifications

# Install any missing dependencies
npm install

# Start development server
npm run start:dev
```

---

## ✅ Verification Checklist

After generation, verify:

- [ ] All 5 modules created and imported in AppModule
- [ ] All schemas have proper indexes
- [ ] DTOs have class-validator decorators
- [ ] Controllers use JwtAuthGuard and RolesGuard
- [ ] Swagger decorators added (@ApiTags, @ApiOperation)
- [ ] Services handle errors properly
- [ ] Population/refs work correctly
- [ ] Pagination follows existing pattern
- [ ] Test with Postman/Thunder Client
- [ ] Test with Flutter frontend

---

## 🧪 Test Endpoints

### Test Appointment Creation
```bash
curl -X POST http://localhost:3000/api/appointments \
  -H "Authorization: Bearer YOUR_JWT_TOKEN" \
  -H "Content-Type: application/json" \
  -d '{
    "patientId": "PATIENT_ID",
    "doctorId": "DOCTOR_ID",
    "dateTime": "2024-02-25T10:00:00Z",
    "type": "Online",
    "notes": "Follow-up"
  }'
```

### Test Create Conversation
```bash
curl -X POST http://localhost:3000/api/conversations \
  -H "Authorization: Bearer YOUR_JWT_TOKEN" \
  -H "Content-Type: application/json" \
  -d '{
    "patientId": "PATIENT_ID",
    "doctorId": "DOCTOR_ID"
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

### Test Accept Patient Request
```bash
curl -X POST http://localhost:3000/api/doctors/DOCTOR_ID/patient-requests/REQUEST_ID/accept \
  -H "Authorization: Bearer YOUR_JWT_TOKEN"
```

### Test Get Notifications
```bash
curl -X GET "http://localhost:3000/api/notifications?unreadOnly=true&limit=20" \
  -H "Authorization: Bearer YOUR_JWT_TOKEN"
```

---

## 📁 Expected File Structure

After generation, your project should have:

```
src/
├── appointments/
│   ├── appointments.module.ts
│   ├── appointments.controller.ts
│   ├── appointments.service.ts
│   ├── appointments.schema.ts
│   └── dto/
│       ├── create-appointment.dto.ts
│       └── update-appointment.dto.ts
│
├── conversations/
│   ├── conversations.module.ts
│   ├── conversations.controller.ts
│   ├── conversations.service.ts
│   ├── conversations.schema.ts
│   └── dto/
│       └── create-conversation.dto.ts
│
├── messages/
│   ├── messages.module.ts (if separate)
│   ├── messages.schema.ts
│   └── dto/
│       └── send-message.dto.ts
│
├── patient-requests/
│   ├── patient-requests.module.ts
│   ├── patient-requests.controller.ts
│   ├── patient-requests.service.ts
│   ├── patient-requests.schema.ts
│   └── dto/
│       ├── create-request.dto.ts
│       └── decline-request.dto.ts
│
├── notifications/
│   ├── notifications.module.ts
│   ├── notifications.controller.ts
│   ├── notifications.service.ts
│   ├── notifications.schema.ts
│   └── dto/
│       └── create-notification.dto.ts
│
└── app.module.ts (updated imports)
```

---

## 🔗 Integration Points

### In Existing Modules

**glucose.service.ts** - Add notification trigger:
```typescript
async create(dto: CreateGlucoseDto) {
  const reading = await this.glucoseModel.create(dto);
  
  // If critical, notify doctor
  if (reading.value > 250 || reading.value < 70) {
    await this.notificationsService.create({
      userId: doctorId, // Get from patient's medecinIds
      type: 'patient_alert',
      title: 'Critical Glucose Alert',
      message: `Patient has critical glucose: ${reading.value}`,
      severity: 'critical',
      relatedId: reading.patientId,
    });
  }
  
  return reading;
}
```

**patient-requests.service.ts** - Notify on accept:
```typescript
async acceptRequest(doctorId: string, requestId: string) {
  const request = await this.requestModel.findByIdAndUpdate(
    requestId,
    { status: 'accepted' },
    { new: true }
  );
  
  // Add patient to doctor's list
  await this.medecinModel.findByIdAndUpdate(
    doctorId,
    { $addToSet: { patientIds: request.patientId } }
  );
  
  // Notify patient
  await this.notificationsService.create({
    userId: request.patientId,
    type: 'new_request',
    title: 'Request Accepted',
    message: 'Your doctor request has been accepted!',
    severity: 'info',
  });
  
  return request;
}
```

---

## 💡 Pro Tips

1. **Use existing patterns**: Copy-paste from your existing modules (glucose, medecins) and adapt
2. **Test incrementally**: Test each endpoint as you create it
3. **Check MongoDB**: Verify documents are created correctly
4. **Populate refs**: Use `.populate('patientId', 'nom prenom email')` for clean responses
5. **Indexes matter**: Add indexes on frequently queried fields
6. **Error handling**: Use try-catch and throw proper NestJS exceptions
7. **Swagger docs**: Add @ApiTags() and @ApiOperation() for documentation
8. **Validation**: Use class-validator decorators in DTOs

---

## 🎯 Summary

**What to Generate:**
- 5 new modules
- 17 new endpoints
- 5 new schemas
- 10+ new DTOs

**What NOT to Change:**
- Existing 53 endpoints (they're perfect!)
- Auth system (JWT, guards, decorators)
- Existing schemas (User, Patient, Medecin, etc.)
- Database connection
- Error handling middleware

**Time Estimate:**
- With Copilot: 2-4 hours
- Manual coding: 1-2 days

---

**Ready to use with GitHub Copilot! Just copy the main prompt and let it generate everything.** 🚀

