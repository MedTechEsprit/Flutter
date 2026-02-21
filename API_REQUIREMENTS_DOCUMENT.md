# DiabCare Backend API Requirements Document

## Overview
This document outlines all API endpoints required for the DiabCare Flutter application. The application is a diabetes management platform with three user roles: **Patient**, **Doctor**, and **Pharmacy**.

---

## Table of Contents
1. [Authentication APIs](#authentication-apis)
2. [Patient APIs](#patient-apis)
3. [Doctor APIs](#doctor-apis)
4. [Pharmacy APIs](#pharmacy-apis)
5. [Common Data Models](#common-data-models)
6. [Error Handling](#error-handling)

---

## Authentication APIs

### 1. POST /api/auth/register/patient
**Description:** Register a new patient user  
**Authentication:** None  
**Request Body:**
```json
{
  "name": "string (required)",
  "email": "string (required, unique, valid email)",
  "phone": "string (required)",
  "password": "string (required, min 6 chars)",
  "age": "number (required)",
  "diabetesType": "string (required, e.g., 'Type 1', 'Type 2')",
  "bloodType": "string (required, e.g., 'A+', 'O-')"
}
```
**Response (201):**
```json
{
  "success": true,
  "token": "JWT_TOKEN_STRING",
  "user": {
    "id": "string",
    "name": "string",
    "email": "string",
    "phone": "string",
    "role": "patient",
    "age": "number",
    "diabetesType": "string",
    "bloodType": "string",
    "status": "Stable",
    "createdAt": "ISO8601 timestamp"
  }
}
```
**Error Response (409):**
```json
{
  "success": false,
  "error": "Un utilisateur avec cet email existe déjà"
}
```

### 2. POST /api/auth/register/medecin
**Description:** Register a new doctor user  
**Authentication:** None  
**Request Body:**
```json
{
  "name": "string (required)",
  "email": "string (required, unique)",
  "phone": "string (required)",
  "password": "string (required, min 6 chars)",
  "specialty": "string (required, e.g., 'Endocrinologue')",
  "license": "string (required)",
  "hospital": "string (required)"
}
```
**Response (201):**
```json
{
  "success": true,
  "token": "JWT_TOKEN_STRING",
  "user": {
    "id": "string",
    "name": "string",
    "email": "string",
    "phone": "string",
    "role": "doctor",
    "specialty": "string",
    "license": "string",
    "hospital": "string",
    "isAvailable": true,
    "totalPatients": 0,
    "satisfactionRate": 0,
    "yearsExperience": 0,
    "createdAt": "ISO8601 timestamp"
  }
}
```

### 3. POST /api/auth/register/pharmacien
**Description:** Register a new pharmacy user  
**Authentication:** None  
**Request Body:**
```json
{
  "name": "string (required)",
  "email": "string (required, unique)",
  "phone": "string (required)",
  "password": "string (required, min 6 chars)",
  "pharmacyName": "string (required)",
  "license": "string (required)",
  "address": "string (required)"
}
```
**Response (201):**
```json
{
  "success": true,
  "token": "JWT_TOKEN_STRING",
  "user": {
    "id": "string",
    "name": "string",
    "email": "string",
    "phone": "string",
    "role": "pharmacy",
    "pharmacyName": "string",
    "license": "string",
    "address": "string",
    "isOpen": true,
    "rating": 0,
    "totalReviews": 0,
    "createdAt": "ISO8601 timestamp"
  }
}
```

### 4. POST /api/auth/login
**Description:** Login user with email and password  
**Authentication:** None  
**Request Body:**
```json
{
  "email": "string (required)",
  "password": "string (required)",
  "role": "string (required, one of: 'patient', 'medecin', 'pharmacien')"
}
```
**Response (200):**
```json
{
  "success": true,
  "token": "JWT_TOKEN_STRING",
  "user": {
    "id": "string",
    "name": "string",
    "email": "string",
    "phone": "string",
    "role": "string",
    "... role-specific fields"
  }
}
```
**Error Response (401):**
```json
{
  "success": false,
  "error": "Email ou mot de passe incorrect"
}
```

### 5. POST /api/auth/logout
**Description:** Logout current user  
**Authentication:** Bearer Token (required)  
**Request Body:** None  
**Response (200):**
```json
{
  "success": true,
  "message": "Déconnexion réussie"
}
```

### 6. GET /api/auth/me
**Description:** Get current authenticated user profile  
**Authentication:** Bearer Token (required)  
**Response (200):**
```json
{
  "id": "string",
  "name": "string",
  "email": "string",
  "phone": "string",
  "role": "string",
  "... role-specific fields"
}
```

---

## Patient APIs

### Glucose Management

### 7. POST /api/patients/:patientId/glucose
**Description:** Add a new glucose reading  
**Authentication:** Bearer Token (Patient only)  
**Request Body:**
```json
{
  "value": "number (required, mg/dL)",
  "timestamp": "ISO8601 timestamp (required)",
  "type": "string (required: 'fasting', 'before_meal', 'after_meal', 'bedtime', 'random')",
  "source": "string (required: 'manual', 'glucometer')",
  "notes": "string (optional)"
}
```
**Response (201):**
```json
{
  "id": "string",
  "patientId": "string",
  "value": "number",
  "timestamp": "ISO8601 timestamp",
  "type": "string",
  "source": "string",
  "notes": "string",
  "status": "string (Normal, Bas, Élevé, Critique)"
}
```

### 8. GET /api/patients/:patientId/glucose
**Description:** Get all glucose readings for a patient  
**Authentication:** Bearer Token (Patient or their Doctor)  
**Query Parameters:**
- `limit`: number (optional, default 100)
- `offset`: number (optional, default 0)
- `startDate`: ISO8601 timestamp (optional)
- `endDate`: ISO8601 timestamp (optional)
- `type`: string (optional filter by type)

**Response (200):**
```json
{
  "readings": [
    {
      "id": "string",
      "patientId": "string",
      "value": "number",
      "timestamp": "ISO8601 timestamp",
      "type": "string",
      "source": "string",
      "notes": "string",
      "status": "string"
    }
  ],
  "total": "number",
  "statistics": {
    "average": "number",
    "min": "number",
    "max": "number",
    "timeInRange": "number (percentage)",
    "normalReadingsCount": "number",
    "highReadingsCount": "number",
    "lowReadingsCount": "number"
  }
}
```

### 9. GET /api/patients/:patientId/glucose/latest
**Description:** Get the most recent glucose reading  
**Authentication:** Bearer Token (Patient or their Doctor)  
**Response (200):**
```json
{
  "id": "string",
  "patientId": "string",
  "value": "number",
  "timestamp": "ISO8601 timestamp",
  "type": "string",
  "source": "string",
  "status": "string"
}
```

### 10. GET /api/patients/:patientId/glucose/statistics
**Description:** Get glucose statistics for different periods  
**Authentication:** Bearer Token (Patient or their Doctor)  
**Query Parameters:**
- `period`: string (required: '7d', '14d', '30d', '90d')

**Response (200):**
```json
{
  "period": "string",
  "average": "number",
  "min": "number",
  "max": "number",
  "timeInRange": "number (percentage)",
  "normalReadingsCount": "number",
  "highReadingsCount": "number",
  "lowReadingsCount": "number",
  "totalReadings": "number",
  "dailyAverages": [
    {
      "date": "ISO8601 date",
      "average": "number",
      "count": "number"
    }
  ]
}
```

### Patient Profile

### 11. GET /api/patients/:patientId
**Description:** Get patient profile details  
**Authentication:** Bearer Token (Patient or their Doctor)  
**Response (200):**
```json
{
  "id": "string",
  "name": "string",
  "email": "string",
  "phone": "string",
  "age": "number",
  "diabetesType": "string",
  "bloodType": "string",
  "status": "string (Stable, Attention, Critical)",
  "emergencyContact": "string",
  "diagnosisDate": "ISO8601 timestamp",
  "currentGlucose": "number",
  "hba1c": "number",
  "bmi": "number",
  "height": "number (cm)",
  "weight": "number (kg)",
  "avatarUrl": "string"
}
```

### 12. PUT /api/patients/:patientId
**Description:** Update patient profile  
**Authentication:** Bearer Token (Patient only)  
**Request Body:**
```json
{
  "name": "string (optional)",
  "phone": "string (optional)",
  "emergencyContact": "string (optional)",
  "height": "number (optional)",
  "weight": "number (optional)",
  "hba1c": "number (optional)"
}
```
**Response (200):**
```json
{
  "id": "string",
  "... updated patient fields"
}
```

### Doctors Search

### 13. GET /api/patients/:patientId/doctors
**Description:** Search for doctors available to the patient  
**Authentication:** Bearer Token (Patient only)  
**Query Parameters:**
- `search`: string (optional, search by name or specialty)
- `specialty`: string (optional filter)
- `limit`: number (optional, default 20)

**Response (200):**
```json
{
  "doctors": [
    {
      "id": "string",
      "name": "string",
      "email": "string",
      "phone": "string",
      "specialty": "string",
      "hospital": "string",
      "isAvailable": "boolean",
      "totalPatients": "number",
      "satisfactionRate": "number (0-100)",
      "yearsExperience": "number",
      "avatarUrl": "string"
    }
  ],
  "total": "number"
}
```

### Pharmacy Search

### 14. GET /api/patients/:patientId/pharmacies
**Description:** Search for pharmacies near the patient  
**Authentication:** Bearer Token (Patient only)  
**Query Parameters:**
- `search`: string (optional, search by name or address)
- `isOpen`: boolean (optional filter)
- `limit`: number (optional, default 20)

**Response (200):**
```json
{
  "pharmacies": [
    {
      "id": "string",
      "name": "string",
      "address": "string",
      "phone": "string",
      "isOpen": "boolean",
      "rating": "number (0-5)",
      "totalReviews": "number",
      "distance": "number (km, optional)"
    }
  ],
  "total": "number"
}
```

### Medication Requests

### 15. POST /api/patients/:patientId/medication-requests
**Description:** Create a new medication request to a pharmacy  
**Authentication:** Bearer Token (Patient only)  
**Request Body:**
```json
{
  "pharmacyId": "string (required)",
  "medicationName": "string (required)",
  "quantity": "number (required)",
  "dosage": "string (required)",
  "patientNote": "string (optional)",
  "isUrgent": "boolean (optional, default false)"
}
```
**Response (201):**
```json
{
  "id": "string",
  "patientId": "string",
  "patientName": "string",
  "pharmacyId": "string",
  "medicationName": "string",
  "quantity": "number",
  "dosage": "string",
  "patientNote": "string",
  "status": "pending",
  "timestamp": "ISO8601 timestamp",
  "isUrgent": "boolean"
}
```

### 16. GET /api/patients/:patientId/medication-requests
**Description:** Get all medication requests for a patient  
**Authentication:** Bearer Token (Patient only)  
**Query Parameters:**
- `status`: string (optional: 'pending', 'accepted', 'declined', 'expired')

**Response (200):**
```json
{
  "requests": [
    {
      "id": "string",
      "patientId": "string",
      "patientName": "string",
      "pharmacyId": "string",
      "pharmacyName": "string",
      "medicationName": "string",
      "quantity": "number",
      "dosage": "string",
      "patientNote": "string",
      "status": "string",
      "timestamp": "ISO8601 timestamp",
      "isUrgent": "boolean",
      "declineReason": "string",
      "price": "number",
      "pickupDeadline": "ISO8601 timestamp",
      "pharmacyMessage": "string",
      "preparationTimeMinutes": "number",
      "isPickedUp": "boolean"
    }
  ],
  "total": "number"
}
```

### Messaging

### 17. GET /api/patients/:patientId/conversations
**Description:** Get all conversations for a patient  
**Authentication:** Bearer Token (Patient only)  
**Response (200):**
```json
{
  "conversations": [
    {
      "id": "string",
      "doctorId": "string",
      "doctorName": "string",
      "patientId": "string",
      "patientName": "string",
      "lastMessage": "string",
      "lastMessageTime": "ISO8601 timestamp",
      "unreadCount": "number"
    }
  ]
}
```

### 18. GET /api/conversations/:conversationId/messages
**Description:** Get all messages in a conversation  
**Authentication:** Bearer Token (Patient or Doctor in conversation)  
**Query Parameters:**
- `limit`: number (optional, default 50)
- `before`: ISO8601 timestamp (optional, for pagination)

**Response (200):**
```json
{
  "messages": [
    {
      "id": "string",
      "senderId": "string",
      "receiverId": "string",
      "content": "string",
      "timestamp": "ISO8601 timestamp",
      "isRead": "boolean",
      "senderName": "string"
    }
  ],
  "hasMore": "boolean"
}
```

### 19. POST /api/conversations/:conversationId/messages
**Description:** Send a message in a conversation  
**Authentication:** Bearer Token (Patient or Doctor in conversation)  
**Request Body:**
```json
{
  "content": "string (required)"
}
```
**Response (201):**
```json
{
  "id": "string",
  "senderId": "string",
  "receiverId": "string",
  "content": "string",
  "timestamp": "ISO8601 timestamp",
  "isRead": false,
  "senderName": "string"
}
```

### 20. POST /api/patients/:patientId/conversations
**Description:** Create a new conversation with a doctor  
**Authentication:** Bearer Token (Patient only)  
**Request Body:**
```json
{
  "doctorId": "string (required)"
}
```
**Response (201):**
```json
{
  "id": "string",
  "doctorId": "string",
  "doctorName": "string",
  "patientId": "string",
  "patientName": "string",
  "lastMessage": "",
  "lastMessageTime": "ISO8601 timestamp",
  "unreadCount": 0
}
```

### Recommendations

### 21. GET /api/patients/:patientId/recommendations
**Description:** Get personalized health recommendations based on glucose data  
**Authentication:** Bearer Token (Patient only)  
**Response (200):**
```json
{
  "recommendations": [
    {
      "id": "string",
      "type": "string (diet, exercise, medication, lifestyle)",
      "priority": "string (high, medium, low)",
      "title": "string",
      "description": "string",
      "icon": "string",
      "createdAt": "ISO8601 timestamp"
    }
  ]
}
```

---

## Doctor APIs

### Patient Management

### 22. GET /api/doctors/:doctorId/patients
**Description:** Get all patients under a doctor's care  
**Authentication:** Bearer Token (Doctor only)  
**Query Parameters:**
- `search`: string (optional, search by name)
- `status`: string (optional: 'Stable', 'Attention', 'Critical')
- `limit`: number (optional, default 50)
- `offset`: number (optional, default 0)

**Response (200):**
```json
{
  "patients": [
    {
      "id": "string",
      "name": "string",
      "age": "number",
      "diabetesType": "string",
      "status": "string",
      "lastReading": "number (glucose value)",
      "lastReadingTime": "ISO8601 timestamp",
      "riskScore": "string (Low, Medium, High)",
      "avatarUrl": "string"
    }
  ],
  "total": "number",
  "statistics": {
    "totalPatients": "number",
    "stableCount": "number",
    "attentionCount": "number",
    "criticalCount": "number"
  }
}
```

### 23. GET /api/doctors/:doctorId/patients/:patientId
**Description:** Get detailed patient information including medical history  
**Authentication:** Bearer Token (Doctor only)  
**Response (200):**
```json
{
  "id": "string",
  "name": "string",
  "email": "string",
  "phone": "string",
  "age": "number",
  "diabetesType": "string",
  "bloodType": "string",
  "status": "string",
  "emergencyContact": "string",
  "diagnosisDate": "ISO8601 timestamp",
  "currentGlucose": "number",
  "hba1c": "number",
  "bmi": "number",
  "height": "number",
  "weight": "number",
  "recentReadings": [
    {
      "value": "number",
      "timestamp": "ISO8601 timestamp",
      "type": "string",
      "status": "string"
    }
  ],
  "statistics": {
    "average": "number",
    "timeInRange": "number",
    "totalReadings": "number"
  }
}
```

### Patient Requests

### 24. GET /api/doctors/:doctorId/patient-requests
**Description:** Get all patient requests waiting for approval  
**Authentication:** Bearer Token (Doctor only)  
**Response (200):**
```json
{
  "requests": [
    {
      "id": "string",
      "patientId": "string",
      "patientName": "string",
      "age": "number",
      "diabetesType": "string",
      "requestDate": "ISO8601 timestamp",
      "hasUrgentNote": "boolean",
      "status": "string (pending, accepted, declined)"
    }
  ],
  "total": "number"
}
```

### 25. POST /api/doctors/:doctorId/patient-requests/:requestId/accept
**Description:** Accept a patient request  
**Authentication:** Bearer Token (Doctor only)  
**Request Body:** None  
**Response (200):**
```json
{
  "success": true,
  "message": "Patient request accepted",
  "patientId": "string"
}
```

### 26. POST /api/doctors/:doctorId/patient-requests/:requestId/decline
**Description:** Decline a patient request  
**Authentication:** Bearer Token (Doctor only)  
**Request Body:**
```json
{
  "reason": "string (optional)"
}
```
**Response (200):**
```json
{
  "success": true,
  "message": "Patient request declined"
}
```

### 27. POST /api/patients/:patientId/request-doctor
**Description:** Patient sends a request to add a doctor  
**Authentication:** Bearer Token (Patient only)  
**Request Body:**
```json
{
  "doctorId": "string (required)",
  "urgentNote": "string (optional)"
}
```
**Response (201):**
```json
{
  "id": "string",
  "patientId": "string",
  "doctorId": "string",
  "status": "pending",
  "requestDate": "ISO8601 timestamp"
}
```

### Appointments

### 28. GET /api/doctors/:doctorId/appointments
**Description:** Get all appointments for a doctor  
**Authentication:** Bearer Token (Doctor only)  
**Query Parameters:**
- `date`: ISO8601 date (optional, filter by date)
- `status`: string (optional: 'Confirmed', 'Pending', 'Completed', 'Cancelled')
- `type`: string (optional: 'Online', 'Physical')

**Response (200):**
```json
{
  "appointments": [
    {
      "id": "string",
      "patientId": "string",
      "patientName": "string",
      "doctorId": "string",
      "doctorName": "string",
      "dateTime": "ISO8601 timestamp",
      "type": "string",
      "status": "string",
      "notes": "string"
    }
  ],
  "total": "number"
}
```

### 29. POST /api/doctors/:doctorId/appointments
**Description:** Create a new appointment  
**Authentication:** Bearer Token (Doctor or Patient)  
**Request Body:**
```json
{
  "patientId": "string (required)",
  "dateTime": "ISO8601 timestamp (required)",
  "type": "string (required: 'Online', 'Physical')",
  "notes": "string (optional)"
}
```
**Response (201):**
```json
{
  "id": "string",
  "patientId": "string",
  "patientName": "string",
  "doctorId": "string",
  "doctorName": "string",
  "dateTime": "ISO8601 timestamp",
  "type": "string",
  "status": "Pending",
  "notes": "string"
}
```

### 30. PUT /api/appointments/:appointmentId
**Description:** Update appointment status  
**Authentication:** Bearer Token (Doctor or Patient in appointment)  
**Request Body:**
```json
{
  "status": "string (required: 'Confirmed', 'Pending', 'Completed', 'Cancelled')",
  "notes": "string (optional)"
}
```
**Response (200):**
```json
{
  "id": "string",
  "... updated appointment fields"
}
```

### Dashboard Statistics

### 31. GET /api/doctors/:doctorId/dashboard
**Description:** Get dashboard statistics for doctor  
**Authentication:** Bearer Token (Doctor only)  
**Response (200):**
```json
{
  "totalPatients": "number",
  "appointmentsToday": "number",
  "activeToday": "number",
  "alertsCount": "number",
  "patientTrends": {
    "growthPercentage": "number",
    "newThisMonth": "number"
  },
  "recentActivity": [
    {
      "type": "string",
      "message": "string",
      "timestamp": "ISO8601 timestamp"
    }
  ]
}
```

### Notifications

### 32. GET /api/doctors/:doctorId/notifications
**Description:** Get all notifications for doctor  
**Authentication:** Bearer Token (Doctor only)  
**Query Parameters:**
- `unreadOnly`: boolean (optional, default false)
- `limit`: number (optional, default 20)

**Response (200):**
```json
{
  "notifications": [
    {
      "id": "string",
      "type": "string (patient_alert, new_request, appointment, message)",
      "title": "string",
      "message": "string",
      "timestamp": "ISO8601 timestamp",
      "isRead": "boolean",
      "relatedId": "string (optional, e.g., patientId)",
      "severity": "string (info, warning, critical)"
    }
  ],
  "unreadCount": "number"
}
```

### 33. PUT /api/notifications/:notificationId/read
**Description:** Mark notification as read  
**Authentication:** Bearer Token (required)  
**Request Body:** None  
**Response (200):**
```json
{
  "success": true
}
```

### Doctor Profile

### 34. GET /api/doctors/:doctorId
**Description:** Get doctor profile  
**Authentication:** Bearer Token (Any authenticated user)  
**Response (200):**
```json
{
  "id": "string",
  "name": "string",
  "email": "string",
  "phone": "string",
  "specialty": "string",
  "license": "string",
  "hospital": "string",
  "isAvailable": "boolean",
  "totalPatients": "number",
  "satisfactionRate": "number",
  "yearsExperience": "number",
  "avatarUrl": "string"
}
```

### 35. PUT /api/doctors/:doctorId
**Description:** Update doctor profile  
**Authentication:** Bearer Token (Doctor only)  
**Request Body:**
```json
{
  "name": "string (optional)",
  "phone": "string (optional)",
  "specialty": "string (optional)",
  "hospital": "string (optional)",
  "isAvailable": "boolean (optional)"
}
```
**Response (200):**
```json
{
  "id": "string",
  "... updated doctor fields"
}
```

---

## Pharmacy APIs

### Medication Requests Management

### 36. GET /api/pharmacies/:pharmacyId/medication-requests
**Description:** Get all medication requests for a pharmacy  
**Authentication:** Bearer Token (Pharmacy only)  
**Query Parameters:**
- `status`: string (optional: 'pending', 'accepted', 'declined', 'expired')
- `urgent`: boolean (optional, filter urgent requests)
- `limit`: number (optional, default 50)

**Response (200):**
```json
{
  "requests": [
    {
      "id": "string",
      "patientId": "string",
      "patientName": "string",
      "medicationName": "string",
      "quantity": "number",
      "dosage": "string",
      "patientNote": "string",
      "status": "string",
      "timestamp": "ISO8601 timestamp",
      "isUrgent": "boolean",
      "declineReason": "string",
      "price": "number",
      "pickupDeadline": "ISO8601 timestamp",
      "pharmacyMessage": "string",
      "preparationTimeMinutes": "number",
      "isPickedUp": "boolean"
    }
  ],
  "total": "number",
  "statistics": {
    "pending": "number",
    "accepted": "number",
    "declined": "number",
    "expired": "number"
  }
}
```

### 37. PUT /api/pharmacies/:pharmacyId/medication-requests/:requestId/accept
**Description:** Accept a medication request  
**Authentication:** Bearer Token (Pharmacy only)  
**Request Body:**
```json
{
  "price": "number (required)",
  "preparationTimeMinutes": "number (optional)",
  "pharmacyMessage": "string (optional)"
}
```
**Response (200):**
```json
{
  "id": "string",
  "status": "accepted",
  "price": "number",
  "pickupDeadline": "ISO8601 timestamp",
  "preparationTimeMinutes": "number",
  "pharmacyMessage": "string"
}
```

### 38. PUT /api/pharmacies/:pharmacyId/medication-requests/:requestId/decline
**Description:** Decline a medication request  
**Authentication:** Bearer Token (Pharmacy only)  
**Request Body:**
```json
{
  "declineReason": "string (required: 'Rupture de stock', 'Ordonnance requise', 'Hors catalogue', 'Autre')"
}
```
**Response (200):**
```json
{
  "id": "string",
  "status": "declined",
  "declineReason": "string"
}
```

### 39. PUT /api/pharmacies/:pharmacyId/medication-requests/:requestId/mark-picked
**Description:** Mark medication as picked up  
**Authentication:** Bearer Token (Pharmacy only)  
**Request Body:** None  
**Response (200):**
```json
{
  "id": "string",
  "isPickedUp": true,
  "pickupTime": "ISO8601 timestamp"
}
```

### Dashboard Statistics

### 40. GET /api/pharmacies/:pharmacyId/dashboard
**Description:** Get dashboard statistics and analytics  
**Authentication:** Bearer Token (Pharmacy only)  
**Query Parameters:**
- `period`: string (optional: '24h', '7j', '30j', '90j', default '7j')

**Response (200):**
```json
{
  "stats": {
    "totalRequests": "number",
    "acceptedRequests": "number",
    "newClients": "number",
    "estimatedRevenue": "number",
    "growthPercentage": "number",
    "pendingRequests": "number",
    "averageRating": "number",
    "totalReviews": "number",
    "responseTimeMinutes": "number",
    "acceptanceRate": "number"
  },
  "revenueChart": [
    {
      "date": "ISO8601 date",
      "revenue": "number"
    }
  ],
  "requestsChart": [
    {
      "date": "ISO8601 date",
      "count": "number"
    }
  ]
}
```

### Badges and Performance

### 41. GET /api/pharmacies/:pharmacyId/badges
**Description:** Get pharmacy badges and levels  
**Authentication:** Bearer Token (Pharmacy only)  
**Response (200):**
```json
{
  "badges": [
    {
      "name": "string",
      "icon": "string",
      "pointsRequired": "number",
      "currentPoints": "number",
      "advantages": ["string"],
      "isUnlocked": "boolean",
      "progress": "number (0-1)"
    }
  ]
}
```

### 42. GET /api/pharmacies/:pharmacyId/performance
**Description:** Get pharmacy performance metrics  
**Authentication:** Bearer Token (Pharmacy only)  
**Response (200):**
```json
{
  "metrics": [
    {
      "label": "string",
      "yourValue": "string",
      "stars": "number (1-5)",
      "benchmark": "string",
      "badge": "string"
    }
  ]
}
```

### Activity

### 43. GET /api/pharmacies/:pharmacyId/activity
**Description:** Get recent activity events  
**Authentication:** Bearer Token (Pharmacy only)  
**Query Parameters:**
- `limit`: number (optional, default 20)

**Response (200):**
```json
{
  "events": [
    {
      "icon": "string",
      "description": "string",
      "timestamp": "ISO8601 timestamp",
      "value": "string",
      "type": "string (success, pending, info, achievement)"
    }
  ]
}
```

### Reviews

### 44. GET /api/pharmacies/:pharmacyId/reviews
**Description:** Get pharmacy reviews from patients  
**Authentication:** Bearer Token (Pharmacy only)  
**Query Parameters:**
- `limit`: number (optional, default 20)
- `offset`: number (optional, default 0)

**Response (200):**
```json
{
  "reviews": [
    {
      "id": "string",
      "patientName": "string",
      "rating": "number (1-5)",
      "comment": "string",
      "timestamp": "ISO8601 timestamp"
    }
  ],
  "total": "number",
  "averageRating": "number"
}
```

### 45. POST /api/pharmacies/:pharmacyId/reviews
**Description:** Patient submits a review for a pharmacy  
**Authentication:** Bearer Token (Patient only)  
**Request Body:**
```json
{
  "rating": "number (required, 1-5)",
  "comment": "string (required)"
}
```
**Response (201):**
```json
{
  "id": "string",
  "patientId": "string",
  "pharmacyId": "string",
  "rating": "number",
  "comment": "string",
  "timestamp": "ISO8601 timestamp"
}
```

### Pharmacy Profile

### 46. GET /api/pharmacies/:pharmacyId
**Description:** Get pharmacy profile  
**Authentication:** Bearer Token (Any authenticated user)  
**Response (200):**
```json
{
  "id": "string",
  "name": "string",
  "email": "string",
  "phone": "string",
  "pharmacyName": "string",
  "license": "string",
  "address": "string",
  "isOpen": "boolean",
  "rating": "number",
  "totalReviews": "number",
  "operatingHours": {
    "monday": { "open": "string", "close": "string" },
    "tuesday": { "open": "string", "close": "string" },
    "... other days"
  }
}
```

### 47. PUT /api/pharmacies/:pharmacyId
**Description:** Update pharmacy profile  
**Authentication:** Bearer Token (Pharmacy only)  
**Request Body:**
```json
{
  "name": "string (optional)",
  "phone": "string (optional)",
  "address": "string (optional)",
  "isOpen": "boolean (optional)",
  "operatingHours": "object (optional)"
}
```
**Response (200):**
```json
{
  "id": "string",
  "... updated pharmacy fields"
}
```

---

## Common Data Models

### User Model
```typescript
interface User {
  id: string;
  name: string;
  email: string;
  phone: string;
  role: 'patient' | 'doctor' | 'pharmacy';
  avatarUrl?: string;
  createdAt: string;
  updatedAt: string;
}
```

### Patient Model (extends User)
```typescript
interface Patient extends User {
  age: number;
  diabetesType: string;
  bloodType: string;
  status: 'Stable' | 'Attention' | 'Critical';
  emergencyContact?: string;
  diagnosisDate?: string;
  currentGlucose?: number;
  hba1c?: number;
  bmi?: number;
  height?: number;
  weight?: number;
}
```

### Doctor Model (extends User)
```typescript
interface Doctor extends User {
  specialty: string;
  license: string;
  hospital: string;
  isAvailable: boolean;
  totalPatients: number;
  satisfactionRate: number;
  yearsExperience: number;
}
```

### Pharmacy Model (extends User)
```typescript
interface Pharmacy extends User {
  pharmacyName: string;
  license: string;
  address: string;
  isOpen: boolean;
  rating: number;
  totalReviews: number;
}
```

### Glucose Reading Model
```typescript
interface GlucoseReading {
  id: string;
  patientId: string;
  value: number; // mg/dL
  timestamp: string;
  type: 'fasting' | 'before_meal' | 'after_meal' | 'bedtime' | 'random';
  source: 'manual' | 'glucometer';
  notes?: string;
  status: 'Bas' | 'Normal' | 'Élevé' | 'Critique';
}
```

### Medication Request Model
```typescript
interface MedicationRequest {
  id: string;
  patientId: string;
  patientName: string;
  pharmacyId: string;
  medicationName: string;
  quantity: number;
  dosage: string;
  patientNote?: string;
  status: 'pending' | 'accepted' | 'declined' | 'expired';
  timestamp: string;
  isUrgent: boolean;
  declineReason?: string;
  price?: number;
  pickupDeadline?: string;
  pharmacyMessage?: string;
  preparationTimeMinutes?: number;
  isPickedUp: boolean;
}
```

### Appointment Model
```typescript
interface Appointment {
  id: string;
  patientId: string;
  patientName: string;
  doctorId: string;
  doctorName: string;
  dateTime: string;
  type: 'Online' | 'Physical';
  status: 'Confirmed' | 'Pending' | 'Completed' | 'Cancelled';
  notes?: string;
}
```

### Message Model
```typescript
interface Message {
  id: string;
  senderId: string;
  receiverId: string;
  content: string;
  timestamp: string;
  isRead: boolean;
  senderName: string;
}
```

### Conversation Model
```typescript
interface Conversation {
  id: string;
  doctorId: string;
  doctorName: string;
  patientId: string;
  patientName: string;
  lastMessage: string;
  lastMessageTime: string;
  unreadCount: number;
}
```

---

## Error Handling

### Standard Error Response Format
```json
{
  "success": false,
  "error": "Human-readable error message",
  "errorCode": "ERROR_CODE",
  "details": {} // Optional additional error details
}
```

### HTTP Status Codes
- **200 OK**: Successful GET, PUT requests
- **201 Created**: Successful POST requests that create resources
- **400 Bad Request**: Invalid request data/parameters
- **401 Unauthorized**: Missing or invalid authentication token
- **403 Forbidden**: User lacks permission for requested resource
- **404 Not Found**: Requested resource doesn't exist
- **409 Conflict**: Resource conflict (e.g., duplicate email)
- **422 Unprocessable Entity**: Validation errors
- **500 Internal Server Error**: Server-side errors

### Common Error Codes
- `AUTH_REQUIRED`: Authentication token required
- `INVALID_TOKEN`: Invalid or expired token
- `FORBIDDEN`: User not authorized for this action
- `NOT_FOUND`: Resource not found
- `VALIDATION_ERROR`: Input validation failed
- `DUPLICATE_EMAIL`: Email already registered
- `INVALID_CREDENTIALS`: Incorrect email/password
- `SERVER_ERROR`: Internal server error

### Validation Error Response Example
```json
{
  "success": false,
  "error": "Validation failed",
  "errorCode": "VALIDATION_ERROR",
  "details": {
    "email": ["Invalid email format"],
    "password": ["Password must be at least 6 characters"]
  }
}
```

---

## Authentication & Authorization

### JWT Token Structure
All authenticated endpoints require a Bearer token in the Authorization header:
```
Authorization: Bearer <JWT_TOKEN>
```

### Token Payload
```json
{
  "userId": "string",
  "email": "string",
  "role": "patient | doctor | pharmacy",
  "iat": "number (issued at)",
  "exp": "number (expiration)"
}
```

### Token Expiration
- Access tokens expire after 24 hours
- Refresh tokens expire after 30 days
- Implement token refresh endpoint if needed

### Role-Based Access Control
- **Patient**: Can only access their own data and public doctor/pharmacy info
- **Doctor**: Can access their own data and their patients' data
- **Pharmacy**: Can access their own data and medication requests directed to them

---

## Additional API Endpoints (Nice to Have)

### 48. POST /api/auth/forgot-password
**Description:** Request password reset  
**Request Body:**
```json
{
  "email": "string (required)"
}
```

### 49. POST /api/auth/reset-password
**Description:** Reset password with token  
**Request Body:**
```json
{
  "token": "string (required)",
  "newPassword": "string (required)"
}
```

### 50. POST /api/patients/:patientId/glucose/bulk
**Description:** Bulk upload glucose readings (for glucometer data sync)  
**Request Body:**
```json
{
  "readings": [
    {
      "value": "number",
      "timestamp": "string",
      "type": "string"
    }
  ]
}
```

### 51. GET /api/doctors/:doctorId/patients/:patientId/medical-report
**Description:** Generate comprehensive medical report for patient  

### 52. POST /api/notifications/send
**Description:** Send push notification to user(s)  

### 53. GET /api/analytics/system
**Description:** System-wide analytics (admin only)  

---

## WebSocket Events (Real-time Features)

### Patient-Doctor Messaging
- **Event**: `message:new`
- **Event**: `message:read`
- **Event**: `typing:start`
- **Event**: `typing:stop`

### Real-time Glucose Monitoring
- **Event**: `glucose:critical` (when patient has critical reading)
- **Event**: `glucose:alert` (pattern detection)

### Notifications
- **Event**: `notification:new`

---

## Database Schema Recommendations

### Users Table
- id (UUID, Primary Key)
- email (Unique, Indexed)
- password_hash
- role (Enum: patient, doctor, pharmacy)
- created_at, updated_at

### Patients Table (extends Users)
- user_id (Foreign Key to Users)
- age, diabetes_type, blood_type, status
- emergency_contact, diagnosis_date
- hba1c, bmi, height, weight

### Doctors Table (extends Users)
- user_id (Foreign Key to Users)
- specialty, license, hospital
- is_available, total_patients
- satisfaction_rate, years_experience

### Pharmacies Table (extends Users)
- user_id (Foreign Key to Users)
- pharmacy_name, license, address
- is_open, rating, total_reviews

### Glucose Readings Table
- id, patient_id (Foreign Key)
- value, timestamp (Indexed), type, source
- notes, status

### Medication Requests Table
- id, patient_id, pharmacy_id (Foreign Keys)
- medication_name, quantity, dosage
- status, timestamp, is_urgent
- decline_reason, price, pickup_deadline

### Appointments Table
- id, patient_id, doctor_id (Foreign Keys)
- date_time (Indexed), type, status, notes

### Messages Table
- id, sender_id, receiver_id (Foreign Keys)
- content, timestamp, is_read

### Conversations Table
- id, doctor_id, patient_id (Foreign Keys, Unique together)
- last_message, last_message_time
- created_at, updated_at

---

## Implementation Notes for NestJS

### 1. Project Structure
```
src/
├── auth/
│   ├── auth.controller.ts
│   ├── auth.service.ts
│   ├── jwt.strategy.ts
│   └── guards/
├── patients/
│   ├── patients.controller.ts
│   ├── patients.service.ts
│   └── dto/
├── doctors/
│   ├── doctors.controller.ts
│   ├── doctors.service.ts
│   └── dto/
├── pharmacies/
│   ├── pharmacies.controller.ts
│   ├── pharmacies.service.ts
│   └── dto/
├── glucose/
│   ├── glucose.controller.ts
│   ├── glucose.service.ts
│   └── dto/
├── appointments/
├── messages/
├── medication-requests/
├── notifications/
├── common/
│   ├── decorators/
│   ├── filters/
│   ├── guards/
│   ├── interceptors/
│   └── pipes/
└── database/
    ├── entities/
    └── migrations/
```

### 2. Required NestJS Packages
```bash
npm install @nestjs/common @nestjs/core @nestjs/platform-express
npm install @nestjs/typeorm typeorm pg
npm install @nestjs/jwt @nestjs/passport passport passport-jwt
npm install @nestjs/config
npm install bcrypt
npm install class-validator class-transformer
npm install @nestjs/swagger # For API documentation
```

### 3. Guards & Decorators
- `@UseGuards(JwtAuthGuard)` - For authentication
- `@Roles('patient', 'doctor', 'pharmacy')` - For role-based access
- `@CurrentUser()` - Custom decorator to get current user from JWT

### 4. Validation
Use `class-validator` DTOs for all request validation:
```typescript
export class CreateGlucoseReadingDto {
  @IsNumber()
  @Min(0)
  @Max(600)
  value: number;

  @IsDateString()
  timestamp: string;

  @IsEnum(['fasting', 'before_meal', 'after_meal', 'bedtime', 'random'])
  type: string;
}
```

### 5. Database Relations
- Use TypeORM entities with proper relations
- Implement soft deletes where appropriate
- Add indexes on frequently queried fields

### 6. Security Best Practices
- Hash passwords with bcrypt (salt rounds: 10)
- Implement rate limiting
- Validate all inputs
- Sanitize outputs
- Use parameterized queries (TypeORM handles this)
- Implement CORS properly

### 7. Testing Requirements
- Unit tests for all services
- E2E tests for critical endpoints
- Mock external dependencies

---

## Summary

This document provides a complete specification for building the DiabCare backend API using NestJS. It includes:

- **47 Core API Endpoints** + 6 optional endpoints
- **Complete Request/Response Schemas**
- **Data Models with TypeScript interfaces**
- **Authentication & Authorization flow**
- **Error Handling specifications**
- **Database schema recommendations**
- **NestJS implementation guidelines**

**Total Endpoints by Category:**
- Authentication: 6 endpoints
- Patient APIs: 21 endpoints
- Doctor APIs: 14 endpoints
- Pharmacy APIs: 12 endpoints
- Common/Shared: 6 endpoints

All endpoints are designed to support the Flutter frontend's functionality including:
- User registration and authentication for 3 roles
- Glucose monitoring and tracking
- Patient-Doctor relationships
- Medication request management
- Real-time messaging
- Appointment scheduling
- Dashboard analytics
- Notifications system

**Next Steps:**
1. Set up NestJS project structure
2. Configure database and TypeORM
3. Implement authentication module
4. Build modules in this order: Users → Patients → Glucose → Doctors → Pharmacies → Messages
5. Add validation and error handling
6. Implement tests
7. Deploy with proper security measures

