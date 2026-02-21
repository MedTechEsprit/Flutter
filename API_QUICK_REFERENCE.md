# DiabCare API Quick Reference Guide

## 📱 Application Overview

DiabCare is a diabetes management platform with **3 user roles**:
- 👤 **Patient**: Track glucose, find doctors, request medications
- 👨‍⚕️ **Doctor**: Monitor patients, manage appointments, receive alerts
- 💊 **Pharmacy**: Handle medication requests, manage inventory

---

## 🔑 Authentication Flow

```
┌─────────────┐
│   Client    │
│  (Flutter)  │
└──────┬──────┘
       │
       │ 1. POST /api/auth/register/{role}
       │    { name, email, password, ... }
       │
       v
┌──────────────┐
│   Backend    │
│   (NestJS)   │
│              │
│  - Hash pwd  │
│  - Save user │
│  - Gen JWT   │
└──────┬───────┘
       │
       │ 2. Response
       │    { token, user }
       │
       v
┌─────────────┐
│   Client    │
│  Stores JWT │
└─────────────┘
       │
       │ 3. All future requests
       │    Header: Authorization: Bearer {token}
       │
       v
┌──────────────┐
│   Backend    │
│  Validates   │
│     JWT      │
└──────────────┘
```

---

## 🏥 Patient Journey

### 1. Register & Login
```
POST /api/auth/register/patient
{
  "name": "John Doe",
  "email": "john@example.com",
  "password": "securepass",
  "age": 35,
  "diabetesType": "Type 2",
  "bloodType": "A+"
}

Response: { token, user }
```

### 2. Add Glucose Reading
```
POST /api/patients/{patientId}/glucose
Authorization: Bearer {token}
{
  "value": 120,
  "timestamp": "2024-02-20T10:30:00Z",
  "type": "fasting",
  "source": "manual"
}

Response: { id, value, status: "Normal" }
```

### 3. View Statistics
```
GET /api/patients/{patientId}/glucose/statistics?period=7d
Authorization: Bearer {token}

Response: {
  "average": 125,
  "min": 80,
  "max": 180,
  "timeInRange": 75,
  "normalReadingsCount": 20,
  "highReadingsCount": 5,
  "lowReadingsCount": 2
}
```

### 4. Find Doctors
```
GET /api/patients/{patientId}/doctors?search=cardio
Authorization: Bearer {token}

Response: {
  "doctors": [
    {
      "id": "doc-123",
      "name": "Dr. Sarah Smith",
      "specialty": "Endocrinologue",
      "hospital": "City Hospital",
      "isAvailable": true
    }
  ]
}
```

### 5. Request Medication
```
POST /api/patients/{patientId}/medication-requests
Authorization: Bearer {token}
{
  "pharmacyId": "pharm-456",
  "medicationName": "Metformin",
  "quantity": 30,
  "dosage": "500mg",
  "isUrgent": false
}

Response: { id, status: "pending", timestamp }
```

---

## 👨‍⚕️ Doctor Journey

### 1. View Patients
```
GET /api/doctors/{doctorId}/patients?status=Critical
Authorization: Bearer {token}

Response: {
  "patients": [
    {
      "id": "pat-789",
      "name": "John Doe",
      "age": 35,
      "status": "Critical",
      "lastReading": 250,
      "riskScore": "High"
    }
  ],
  "statistics": {
    "totalPatients": 248,
    "criticalCount": 3
  }
}
```

### 2. View Patient Details
```
GET /api/doctors/{doctorId}/patients/{patientId}
Authorization: Bearer {token}

Response: {
  "id": "pat-789",
  "name": "John Doe",
  "currentGlucose": 250,
  "hba1c": 8.5,
  "recentReadings": [...],
  "statistics": {
    "average": 180,
    "timeInRange": 45
  }
}
```

### 3. Manage Patient Requests
```
GET /api/doctors/{doctorId}/patient-requests
Authorization: Bearer {token}

Response: {
  "requests": [
    {
      "id": "req-123",
      "patientName": "Jane Smith",
      "diabetesType": "Type 1",
      "hasUrgentNote": true,
      "status": "pending"
    }
  ]
}

POST /api/doctors/{doctorId}/patient-requests/{requestId}/accept
Authorization: Bearer {token}
Response: { success: true }
```

### 4. Dashboard Statistics
```
GET /api/doctors/{doctorId}/dashboard
Authorization: Bearer {token}

Response: {
  "totalPatients": 248,
  "appointmentsToday": 12,
  "activeToday": 28,
  "alertsCount": 3,
  "patientTrends": {
    "growthPercentage": 12
  }
}
```

---

## 💊 Pharmacy Journey

### 1. View Medication Requests
```
GET /api/pharmacies/{pharmacyId}/medication-requests?status=pending
Authorization: Bearer {token}

Response: {
  "requests": [
    {
      "id": "med-456",
      "patientName": "John Doe",
      "medicationName": "Metformin",
      "quantity": 30,
      "dosage": "500mg",
      "isUrgent": false,
      "status": "pending"
    }
  ],
  "statistics": {
    "pending": 5,
    "accepted": 120
  }
}
```

### 2. Accept Request
```
PUT /api/pharmacies/{pharmacyId}/medication-requests/{requestId}/accept
Authorization: Bearer {token}
{
  "price": 45.50,
  "preparationTimeMinutes": 30,
  "pharmacyMessage": "Ready for pickup today"
}

Response: {
  "id": "med-456",
  "status": "accepted",
  "pickupDeadline": "2024-02-20T18:00:00Z"
}
```

### 3. Decline Request
```
PUT /api/pharmacies/{pharmacyId}/medication-requests/{requestId}/decline
Authorization: Bearer {token}
{
  "declineReason": "Rupture de stock"
}

Response: {
  "id": "med-456",
  "status": "declined"
}
```

### 4. Dashboard
```
GET /api/pharmacies/{pharmacyId}/dashboard?period=7j
Authorization: Bearer {token}

Response: {
  "stats": {
    "totalRequests": 150,
    "acceptedRequests": 120,
    "estimatedRevenue": 5420.50,
    "averageRating": 4.8,
    "responseTimeMinutes": 18
  }
}
```

---

## 💬 Messaging System

### 1. Get Conversations (Patient)
```
GET /api/patients/{patientId}/conversations
Authorization: Bearer {token}

Response: {
  "conversations": [
    {
      "id": "conv-123",
      "doctorName": "Dr. Sarah Smith",
      "lastMessage": "Your glucose levels look good",
      "lastMessageTime": "2024-02-20T10:00:00Z",
      "unreadCount": 2
    }
  ]
}
```

### 2. Get Messages
```
GET /api/conversations/{conversationId}/messages?limit=50
Authorization: Bearer {token}

Response: {
  "messages": [
    {
      "id": "msg-456",
      "senderId": "doc-123",
      "content": "How are you feeling today?",
      "timestamp": "2024-02-20T09:00:00Z",
      "isRead": true
    }
  ]
}
```

### 3. Send Message
```
POST /api/conversations/{conversationId}/messages
Authorization: Bearer {token}
{
  "content": "I'm feeling much better, thank you!"
}

Response: {
  "id": "msg-789",
  "senderId": "pat-456",
  "content": "I'm feeling much better, thank you!",
  "timestamp": "2024-02-20T10:30:00Z",
  "isRead": false
}
```

---

## 📊 Data Flow Diagram

```
┌─────────────────────────────────────────────────────────────┐
│                        Flutter App                          │
├─────────────────────────────────────────────────────────────┤
│  Patient Screen  │  Doctor Screen  │  Pharmacy Screen       │
│   - Dashboard    │   - Dashboard   │   - Dashboard          │
│   - Add Glucose  │   - Patients    │   - Requests           │
│   - Doctors      │   - Requests    │   - Performance        │
│   - Pharmacies   │   - Appts       │   - Reviews            │
│   - Messages     │   - Messages    │                        │
└─────────┬───────────────┬───────────────┬───────────────────┘
          │               │               │
          │   HTTP/JSON   │               │
          │   REST API    │               │
          v               v               v
┌─────────────────────────────────────────────────────────────┐
│                      NestJS Backend                          │
├─────────────────────────────────────────────────────────────┤
│  Controllers        │  Services        │  Guards/Pipes      │
│  - Auth             │  - Business      │  - JWT Auth        │
│  - Patients         │    Logic         │  - Role Guard      │
│  - Doctors          │  - Validation    │  - Validation      │
│  - Pharmacies       │  - Calculations  │                    │
└─────────┬───────────────────────────────────────────────────┘
          │
          │   TypeORM
          v
┌─────────────────────────────────────────────────────────────┐
│                    PostgreSQL Database                       │
├─────────────────────────────────────────────────────────────┤
│  Users  │  Patients  │  Doctors  │  Pharmacies             │
│  Glucose Readings   │  Medication Requests                  │
│  Appointments       │  Messages      │  Conversations       │
│  Notifications      │  Reviews       │  Patient Requests    │
└─────────────────────────────────────────────────────────────┘
```

---

## 🔐 Security Matrix

| Endpoint | Patient | Doctor | Pharmacy | Public |
|----------|---------|--------|----------|--------|
| POST /auth/register/* | ✅ | ✅ | ✅ | ✅ |
| POST /auth/login | ✅ | ✅ | ✅ | ✅ |
| GET /patients/:id | ✅ (own) | ✅ (their patients) | ❌ | ❌ |
| POST /patients/:id/glucose | ✅ (own) | ❌ | ❌ | ❌ |
| GET /doctors/:id/patients | ❌ | ✅ (own) | ❌ | ❌ |
| GET /doctors/:id | ✅ | ✅ | ✅ | ✅ |
| POST /medication-requests | ✅ | ❌ | ❌ | ❌ |
| PUT /medication-requests/:id/accept | ❌ | ❌ | ✅ (own) | ❌ |
| GET /conversations/:id/messages | ✅ (in conv) | ✅ (in conv) | ❌ | ❌ |

---

## 📈 API Endpoint Summary

### Authentication (6 endpoints)
- ✅ Register Patient/Doctor/Pharmacy
- ✅ Login
- ✅ Logout
- ✅ Get Current User

### Patient APIs (21 endpoints)
- ✅ Glucose CRUD & Statistics (5)
- ✅ Profile Management (2)
- ✅ Search Doctors/Pharmacies (2)
- ✅ Medication Requests (2)
- ✅ Conversations & Messages (3)
- ✅ Recommendations (1)
- ✅ Request Doctor (1)
- ✅ Appointments (5)

### Doctor APIs (14 endpoints)
- ✅ Patient Management (2)
- ✅ Patient Requests (3)
- ✅ Appointments (3)
- ✅ Dashboard & Stats (1)
- ✅ Notifications (2)
- ✅ Profile (2)
- ✅ Messages (1)

### Pharmacy APIs (12 endpoints)
- ✅ Medication Requests (4)
- ✅ Dashboard & Analytics (1)
- ✅ Badges & Performance (2)
- ✅ Activity & Reviews (3)
- ✅ Profile (2)

### Shared APIs (6 endpoints)
- ✅ Messages (2)
- ✅ Appointments (1)
- ✅ Notifications (1)
- ✅ Conversations (2)

**Total: 53 API Endpoints**

---

## 🎯 Key Features by Role

### 👤 Patient
- ✅ Track glucose readings (manual & glucometer)
- ✅ View trends, charts, and statistics
- ✅ Get personalized health recommendations
- ✅ Search and connect with doctors
- ✅ Request medications from pharmacies
- ✅ Chat with doctors
- ✅ Schedule appointments
- ✅ View medical history

### 👨‍⚕️ Doctor
- ✅ Monitor all patients' health data
- ✅ View real-time glucose readings
- ✅ Receive critical alerts
- ✅ Accept/decline patient requests
- ✅ Manage appointments
- ✅ Chat with patients
- ✅ Generate medical reports
- ✅ Dashboard with statistics

### 💊 Pharmacy
- ✅ Receive medication requests
- ✅ Accept/decline with pricing
- ✅ Track order fulfillment
- ✅ Performance analytics
- ✅ Gamification (badges, levels)
- ✅ Review management
- ✅ Revenue tracking
- ✅ Response time metrics

---

## 🚀 Quick Start

### 1. Backend Setup
```bash
# Clone or create NestJS project
nest new diabcare-backend

# Install dependencies
npm install @nestjs/typeorm typeorm pg
npm install @nestjs/jwt @nestjs/passport passport-jwt
npm install bcrypt class-validator class-transformer

# Setup database
createdb diabcare

# Configure .env
DATABASE_URL=postgresql://user:pass@localhost:5432/diabcare
JWT_SECRET=your-super-secret-key
PORT=8000

# Run migrations
npm run migration:run

# Start server
npm run start:dev
```

### 2. Test Endpoints
```bash
# Test registration
curl -X POST http://localhost:8000/api/auth/register/patient \
  -H "Content-Type: application/json" \
  -d '{
    "name": "Test Patient",
    "email": "test@example.com",
    "password": "password123",
    "age": 30,
    "diabetesType": "Type 2",
    "bloodType": "A+"
  }'

# Test login
curl -X POST http://localhost:8000/api/auth/login \
  -H "Content-Type: application/json" \
  -d '{
    "email": "test@example.com",
    "password": "password123",
    "role": "patient"
  }'
```

### 3. Access Swagger Documentation
```
Open browser: http://localhost:8000/api/docs
```

---

## 📝 Common Response Formats

### Success Response
```json
{
  "id": "uuid-here",
  "name": "John Doe",
  "email": "john@example.com",
  "... other fields"
}
```

### Error Response
```json
{
  "success": false,
  "error": "Email ou mot de passe incorrect",
  "errorCode": "INVALID_CREDENTIALS",
  "statusCode": 401
}
```

### Validation Error
```json
{
  "success": false,
  "error": "Validation failed",
  "errorCode": "VALIDATION_ERROR",
  "statusCode": 422,
  "details": {
    "email": ["Invalid email format"],
    "password": ["Password must be at least 6 characters"]
  }
}
```

---

## 🔍 Filtering & Pagination

Most list endpoints support:

```
GET /api/resource?limit=20&offset=0&sortBy=createdAt&order=DESC

Query Parameters:
- limit: Number of items (default: 20, max: 100)
- offset: Skip N items (default: 0)
- sortBy: Field name (default: createdAt)
- order: ASC or DESC (default: DESC)
- search: Search term (where applicable)
- status: Filter by status (where applicable)
- startDate: Date range start (ISO8601)
- endDate: Date range end (ISO8601)
```

---

## ⚡ Performance Tips

1. **Database Indexes**: Already on frequently queried fields
2. **Caching**: Implement Redis for dashboard stats
3. **Pagination**: Always use limit/offset for lists
4. **Eager Loading**: Use TypeORM relations wisely
5. **Connection Pooling**: Configure in database config
6. **Rate Limiting**: Implemented via @nestjs/throttler

---

## 🐛 Debugging

### Enable Debug Logging
```typescript
// In main.ts
app.useLogger(['log', 'error', 'warn', 'debug', 'verbose']);
```

### Database Query Logging
```typescript
// In database config
logging: true,
logger: 'advanced-console',
```

### Test with curl
```bash
# Get with auth
curl -X GET http://localhost:8000/api/patients/123 \
  -H "Authorization: Bearer YOUR_JWT_TOKEN"

# Post with body
curl -X POST http://localhost:8000/api/patients/123/glucose \
  -H "Authorization: Bearer YOUR_JWT_TOKEN" \
  -H "Content-Type: application/json" \
  -d '{"value": 120, "type": "fasting", "timestamp": "2024-02-20T10:00:00Z", "source": "manual"}'
```

---

## 📚 Resources

- **Full API Spec**: See `API_REQUIREMENTS_DOCUMENT.md`
- **Generation Prompt**: See `NESTJS_GENERATION_PROMPT.md`
- **NestJS Docs**: https://docs.nestjs.com
- **TypeORM Docs**: https://typeorm.io
- **Swagger UI**: http://localhost:8000/api/docs (when running)

---

**Happy Coding! 🎉**

