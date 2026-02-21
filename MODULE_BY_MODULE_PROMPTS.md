# Module-by-Module Generation Prompts

**Instructions:** Send these prompts to Copilot ONE AT A TIME. After each module is generated, tested, and working, move to the next one.

---

## 📦 MODULE 1: APPOINTMENTS (Priority: CRITICAL)

**Send this prompt first:**

```
I have an existing NestJS 11.x project with MongoDB/Mongoose that uses:
- @nestjs/mongoose with Mongoose schemas
- class-validator DTOs
- JwtAuthGuard and RolesGuard from my auth module
- Role enum (PATIENT, MEDECIN, PHARMACIEN)
- Swagger decorators (@ApiTags, @ApiOperation)

I need to create a complete APPOINTMENTS module with the following specifications:

LOCATION: src/appointments/

SCHEMA (appointments.schema.ts):
Create Appointment schema with these fields:
- patientId: ObjectId reference to 'Patient' collection (required, indexed)
- doctorId: ObjectId reference to 'Medecin' collection (required, indexed)
- dateTime: Date (required, indexed)
- type: enum ['Online', 'Physical'] (default: 'Physical')
- status: enum ['Confirmed', 'Pending', 'Completed', 'Cancelled'] (default: 'Pending')
- notes: string (optional)
- Add timestamps (createdAt, updatedAt)
- Add compound index on { doctorId: 1, dateTime: 1 } for performance

DTOs (in dto/ folder):
1. create-appointment.dto.ts:
   - patientId: string (required, IsMongoId)
   - doctorId: string (required, IsMongoId)
   - dateTime: Date (required, IsDateString)
   - type: string (required, IsEnum(['Online', 'Physical']))
   - notes: string (optional, IsString)

2. update-appointment.dto.ts:
   - status: string (optional, IsEnum(['Confirmed', 'Pending', 'Completed', 'Cancelled']))
   - notes: string (optional, IsString)

CONTROLLER (appointments.controller.ts):
Create 6 endpoints with proper guards and Swagger docs:

1. POST /api/appointments
   - @UseGuards(JwtAuthGuard, RolesGuard)
   - @Roles(Role.PATIENT, Role.MEDECIN)
   - @ApiTags('appointments')
   - @ApiOperation({ summary: 'Create new appointment' })
   - Create appointment and return with populated patient and doctor names

2. GET /api/doctors/:doctorId/appointments
   - @UseGuards(JwtAuthGuard, RolesGuard)
   - @Roles(Role.MEDECIN)
   - @ApiTags('appointments')
   - Query params: date (optional), status (optional), type (optional)
   - Return doctor's appointments with filters

3. GET /api/patients/:patientId/appointments
   - @UseGuards(JwtAuthGuard, RolesGuard)
   - @Roles(Role.PATIENT)
   - @ApiTags('appointments')
   - Return all patient's appointments

4. GET /api/appointments/:id
   - @UseGuards(JwtAuthGuard)
   - @ApiTags('appointments')
   - Return single appointment with populated patient and doctor info

5. PATCH /api/appointments/:id
   - @UseGuards(JwtAuthGuard)
   - @ApiTags('appointments')
   - Update appointment status and/or notes

6. DELETE /api/appointments/:id
   - @UseGuards(JwtAuthGuard)
   - @ApiTags('appointments')
   - Delete appointment

SERVICE (appointments.service.ts):
Implement these methods:
- create(createDto): Create appointment with error handling
- getDoctorAppointments(doctorId, filters): Filter by date, status, type
- getPatientAppointments(patientId): Get all patient appointments
- findOne(id): Find by ID with population
- update(id, updateDto): Update with validation
- remove(id): Delete appointment

ERROR HANDLING:
- Use NotFoundException when appointment not found
- Use BadRequestException for validation errors

RESPONSE FORMAT:
When populating, include:
- patientName (from Patient.nom + prenom)
- doctorName (from Medecin.nom + prenom)
- doctorSpecialty (from Medecin.specialite)

MODULE FILE (appointments.module.ts):
- Import MongooseModule.forFeature for Appointment schema
- Import and inject Patient and Medecin models (for population)
- Export AppointmentsService

Generate complete, production-ready code with:
- Proper TypeScript types
- Error handling in all methods
- Swagger decorators on all endpoints
- Guards on all protected routes
- Validation decorators on all DTOs
```

**After Module 1 is generated:**
- [ ] Review the generated code
- [ ] Test all 6 endpoints with Postman/Thunder Client
- [ ] Verify appointments are created in MongoDB
- [ ] Test with different roles (patient, doctor)
- [ ] Check if population works correctly

---

## 📦 MODULE 2: CONVERSATIONS & MESSAGES (Priority: CRITICAL)

**Send this prompt after Module 1 is complete and tested:**

```
I have a working NestJS project with existing auth guards. I need to create CONVERSATIONS and MESSAGES modules for a chat system between patients and doctors.

LOCATION: src/conversations/ and src/messages/

CONVERSATIONS MODULE:

Schema (conversations.schema.ts):
- patientId: ObjectId ref 'Patient' (required, indexed)
- doctorId: ObjectId ref 'Medecin' (required, indexed)
- lastMessage: string (default: '')
- lastMessageTime: Date (default: now)
- timestamps: true
- Add UNIQUE compound index: { patientId: 1, doctorId: 1 }

DTOs:
1. create-conversation.dto.ts:
   - patientId: string (required, IsMongoId)
   - doctorId: string (required, IsMongoId)

MESSAGES MODULE:

Schema (messages.schema.ts):
- conversationId: ObjectId ref 'Conversation' (required, indexed)
- senderId: ObjectId ref 'User' (required)
- receiverId: ObjectId ref 'User' (required)
- content: string (required)
- timestamp: Date (default: now, indexed)
- isRead: boolean (default: false)
- timestamps: true
- Add compound index: { conversationId: 1, timestamp: -1 }

DTOs:
1. send-message.dto.ts:
   - content: string (required, IsString, MinLength(1))

CONVERSATIONS CONTROLLER (conversations.controller.ts):
Create 5 endpoints:

1. GET /api/patients/:patientId/conversations
   - @Roles(Role.PATIENT)
   - Return patient's conversations with:
     * Populated doctor info (nom, prenom, specialite)
     * Unread message count per conversation
   - @ApiTags('conversations')

2. GET /api/doctors/:doctorId/conversations
   - @Roles(Role.MEDECIN)
   - Return doctor's conversations with:
     * Populated patient info (nom, prenom, typeDiabete)
     * Unread message count per conversation
   - @ApiTags('conversations')

3. POST /api/conversations
   - @Roles(Role.PATIENT, Role.MEDECIN)
   - Create new conversation
   - Check if conversation already exists (same patientId + doctorId)
   - If exists, return existing conversation
   - @ApiTags('conversations')

4. GET /api/conversations/:conversationId/messages
   - @UseGuards(JwtAuthGuard)
   - Query params: limit (default: 50), before (timestamp for pagination)
   - Return messages paginated, sorted by timestamp DESC
   - Populate senderName
   - @ApiTags('messages')

5. POST /api/conversations/:conversationId/messages
   - @UseGuards(JwtAuthGuard)
   - Body: { content: string }
   - Create message
   - Update conversation.lastMessage and lastMessageTime
   - Return created message
   - @ApiTags('messages')

CONVERSATIONS SERVICE:
- getPatientConversations(patientId): Get with doctor info and unread count
- getDoctorConversations(doctorId): Get with patient info and unread count
- create(dto): Create or return existing conversation
- findOne(id): Find conversation by ID

MESSAGES SERVICE:
- getMessages(conversationId, limit, before): Paginated messages
- sendMessage(conversationId, senderId, receiverId, content): Create and update conversation
- countUnread(conversationId, receiverId): Count unread messages for user

Calculate unread count by:
```typescript
const unreadCount = await this.messageModel.countDocuments({
  conversationId: conversation._id,
  receiverId: userId,
  isRead: false,
});
```

Both modules need:
- Proper error handling
- Swagger decorators
- Guards on all endpoints
- Validation on DTOs

Generate complete code for both modules.
```

**After Module 2 is generated:**
- [ ] Test creating conversations
- [ ] Test sending messages
- [ ] Verify unread count calculation
- [ ] Test pagination of messages
- [ ] Check conversation uniqueness

---

## 📦 MODULE 3: PATIENT REQUESTS (Priority: HIGH)

**Send this prompt after Module 2 is complete and tested:**

```
I need a PATIENT REQUESTS module for managing patient-doctor connection requests in my NestJS app.

LOCATION: src/patient-requests/

Schema (patient-requests.schema.ts):
- patientId: ObjectId ref 'Patient' (required, indexed)
- doctorId: ObjectId ref 'Medecin' (required, indexed)
- status: enum ['pending', 'accepted', 'declined'] (default: 'pending', indexed)
- requestDate: Date (default: now)
- urgentNote: string (optional)
- declineReason: string (optional)
- timestamps: true
- Add compound index: { doctorId: 1, status: 1 }

DTOs:
1. create-patient-request.dto.ts:
   - doctorId: string (required, IsMongoId)
   - urgentNote: string (optional, IsString)

2. decline-request.dto.ts:
   - reason: string (required, IsString)

CONTROLLER (patient-requests.controller.ts):
Create 4 endpoints:

1. GET /api/doctors/:doctorId/patient-requests
   - @Roles(Role.MEDECIN)
   - Return pending requests with populated patient info
   - Include: patient nom, prenom, age, diabetesType
   - @ApiTags('patient-requests')

2. POST /api/doctors/:doctorId/patient-requests/:requestId/accept
   - @Roles(Role.MEDECIN)
   - Update request status to 'accepted'
   - Add patientId to Medecin.patientIds array using $addToSet
   - Return success message
   - @ApiTags('patient-requests')

3. POST /api/doctors/:doctorId/patient-requests/:requestId/decline
   - @Roles(Role.MEDECIN)
   - Body: { reason: string }
   - Update request status to 'declined'
   - Save decline reason
   - Return updated request
   - @ApiTags('patient-requests')

4. POST /api/patients/:patientId/request-doctor
   - @Roles(Role.PATIENT)
   - Body: { doctorId: string, urgentNote?: string }
   - Check if request already exists (same patient + doctor + pending status)
   - If exists, return error "Request already exists"
   - Create new request
   - Return created request
   - @ApiTags('patient-requests')

SERVICE (patient-requests.service.ts):
Methods:
- getDoctorRequests(doctorId): Get pending requests with patient details
- acceptRequest(doctorId, requestId): 
  * Update request status
  * Update Medecin model to add patient to patientIds array
  * Inject MedecinModel from existing medecins module
- declineRequest(requestId, reason): Update status and reason
- createRequest(patientId, dto): Check duplicates, create request

To update doctor's patient list:
```typescript
await this.medecinModel.findByIdAndUpdate(
  doctorId,
  { $addToSet: { patientIds: request.patientId } }
);
```

MODULE (patient-requests.module.ts):
- Import MongooseModule.forFeature for PatientRequest
- Import MedecinModule to access Medecin model
- Import PatientModule to access Patient model for population

Add all guards, Swagger docs, and error handling.
```

**After Module 3 is generated:**
- [ ] Test creating patient request
- [ ] Test doctor accepting request
- [ ] Verify patient added to doctor's patientIds
- [ ] Test declining request with reason
- [ ] Check duplicate request prevention

---

## 📦 MODULE 4: NOTIFICATIONS (Priority: MEDIUM)

**Send this prompt after Module 3 is complete and tested:**

```
I need a NOTIFICATIONS module for my NestJS app to send alerts to users.

LOCATION: src/notifications/

Schema (notifications.schema.ts):
- userId: ObjectId ref 'User' (required, indexed)
- type: enum ['patient_alert', 'new_request', 'appointment', 'message'] (required)
- title: string (required)
- message: string (required)
- timestamp: Date (default: now, indexed)
- isRead: boolean (default: false, indexed)
- relatedId: ObjectId (optional - generic reference to related document)
- severity: enum ['info', 'warning', 'critical'] (default: 'info')
- timestamps: true
- Add compound index: { userId: 1, isRead: 1, timestamp: -1 }

DTOs:
1. create-notification.dto.ts:
   - userId: string (required, IsMongoId)
   - type: string (required, IsEnum)
   - title: string (required, IsString)
   - message: string (required, IsString)
   - relatedId: string (optional, IsMongoId)
   - severity: string (optional, IsEnum(['info', 'warning', 'critical']))

CONTROLLER (notifications.controller.ts):
Create 2 endpoints:

1. GET /api/notifications
   - @UseGuards(JwtAuthGuard)
   - Get current user from JWT (@CurrentUser() decorator)
   - Query params:
     * unreadOnly: boolean (optional, filter by isRead: false)
     * type: string (optional, filter by notification type)
     * limit: number (optional, default: 20)
   - Return notifications sorted by timestamp DESC
   - Include unreadCount in response
   - @ApiTags('notifications')

2. PATCH /api/notifications/:notificationId/read
   - @UseGuards(JwtAuthGuard)
   - Mark notification as read (isRead: true)
   - Return updated notification
   - @ApiTags('notifications')

SERVICE (notifications.service.ts):
Methods:
- getUserNotifications(userId, filters): Get with pagination and filters
- markAsRead(notificationId): Update isRead to true
- create(dto): Create notification (used by other modules)
- markAllAsRead(userId): Mark all user notifications as read
- getUnreadCount(userId): Count unread notifications

HELPER METHOD for other modules:
Export a helper method that other modules can use:
```typescript
async sendNotification(
  userId: string,
  type: string,
  title: string,
  message: string,
  severity?: string,
  relatedId?: string
) {
  return this.create({
    userId,
    type,
    title,
    message,
    severity: severity || 'info',
    relatedId,
  });
}
```

MODULE (notifications.module.ts):
- Import MongooseModule.forFeature for Notification
- Export NotificationsService so other modules can inject it

Add guards, Swagger docs, and error handling.
```

**After Module 4 is generated:**
- [ ] Test getting notifications
- [ ] Test marking as read
- [ ] Test filtering (unreadOnly, by type)
- [ ] Verify the helper method works
- [ ] Test unread count calculation

---

## 📦 MODULE 5: INTEGRATION & FINAL TOUCHES

**Send this prompt after all 4 modules are complete and tested:**

```
I have successfully created 4 new modules: Appointments, Conversations, Messages, Patient Requests, and Notifications.

Now I need to:

1. UPDATE app.module.ts:
Add these to imports array:
- AppointmentsModule
- ConversationsModule
- PatientRequestsModule
- NotificationsModule

2. ADD NOTIFICATION TRIGGERS in existing modules:

In glucose.service.ts (in create method):
After creating glucose reading, check if value is critical:
```typescript
if (reading.value > 250 || reading.value < 70) {
  // Get patient's doctor ID from patient.medecinIds[0]
  const patient = await this.patientModel.findById(reading.patientId);
  if (patient && patient.medecinIds && patient.medecinIds.length > 0) {
    await this.notificationsService.sendNotification(
      patient.medecinIds[0].toString(),
      'patient_alert',
      'Critical Glucose Alert',
      `Patient ${patient.nom} has critical glucose level: ${reading.value} mg/dL`,
      'critical',
      reading.patientId.toString()
    );
  }
}
```

In patient-requests.service.ts (in acceptRequest method):
After accepting request, notify patient:
```typescript
await this.notificationsService.sendNotification(
  request.patientId.toString(),
  'new_request',
  'Request Accepted',
  `Dr. ${doctor.nom} has accepted your connection request!`,
  'info'
);
```

In conversations.service.ts (in sendMessage method):
After sending message, notify receiver:
```typescript
await this.notificationsService.sendNotification(
  receiverId.toString(),
  'message',
  'New Message',
  `You have a new message from ${senderName}`,
  'info',
  conversationId.toString()
);
```

In appointments.service.ts (in create method):
After creating appointment, notify both parties:
```typescript
// Notify patient
await this.notificationsService.sendNotification(
  dto.patientId,
  'appointment',
  'Appointment Scheduled',
  `Your appointment with Dr. ${doctor.nom} is scheduled for ${dto.dateTime}`,
  'info'
);

// Notify doctor
await this.notificationsService.sendNotification(
  dto.doctorId,
  'appointment',
  'New Appointment',
  `New appointment scheduled with patient ${patient.nom} for ${dto.dateTime}`,
  'info'
);
```

3. INJECT NotificationsService in these modules:
- GlucoseModule: import NotificationsModule
- PatientRequestsModule: import NotificationsModule
- ConversationsModule: import NotificationsModule
- AppointmentsModule: import NotificationsModule

Show me the updated imports for each module and the exact code to add to each service.
```

**After Module 5 integration:**
- [ ] Test glucose critical alert triggers notification
- [ ] Test patient request acceptance triggers notification
- [ ] Test message sending triggers notification
- [ ] Test appointment creation triggers notifications
- [ ] Verify all notifications appear in GET /api/notifications

---

## ✅ FINAL VERIFICATION CHECKLIST

After all modules are generated and integrated:

### Module 1: Appointments
- [ ] All 6 endpoints working
- [ ] Population of patient/doctor names works
- [ ] Filters work correctly
- [ ] Guards restrict access properly

### Module 2: Conversations & Messages
- [ ] Conversations created successfully
- [ ] Messages sent and received
- [ ] Unread count calculates correctly
- [ ] Pagination works
- [ ] Conversation uniqueness enforced

### Module 3: Patient Requests
- [ ] Requests created
- [ ] Doctor can accept/decline
- [ ] Patient added to doctor's list on accept
- [ ] Duplicate prevention works

### Module 4: Notifications
- [ ] Notifications created
- [ ] Filtering works (unreadOnly, type)
- [ ] Mark as read works
- [ ] Unread count correct

### Integration
- [ ] Critical glucose triggers notification
- [ ] Request acceptance triggers notification
- [ ] Message triggers notification
- [ ] Appointment triggers notifications
- [ ] All services can access NotificationsService

### Testing
- [ ] Test all endpoints with Postman
- [ ] Test with Flutter app
- [ ] Verify MongoDB documents created correctly
- [ ] Check indexes are created
- [ ] Test error cases (not found, unauthorized, etc.)

---

## 🎯 SENDING ORDER

**Day 1:**
1. Send Module 1 prompt (Appointments)
2. Wait for generation, review, and test
3. Send Module 2 prompt (Conversations & Messages)
4. Wait for generation, review, and test

**Day 2:**
5. Send Module 3 prompt (Patient Requests)
6. Wait for generation, review, and test
7. Send Module 4 prompt (Notifications)
8. Wait for generation, review, and test

**Day 3:**
9. Send Module 5 prompt (Integration)
10. Test everything together
11. Deploy to staging server

---

**This approach gives you full control and understanding of each module before moving to the next one!** 🚀

