# NestJS Backend Generation Prompt for GitHub Copilot

Copy and paste this prompt into VS Code when you have GitHub Copilot enabled to auto-generate the DiabCare backend API.

---

## 🚀 Main Generation Prompt

```
Create a complete NestJS backend API for the DiabCare diabetes management application with the following specifications:

PROJECT SETUP:
- Initialize NestJS project with TypeScript
- Use PostgreSQL with TypeORM for database
- Implement JWT authentication with Passport
- Add Swagger/OpenAPI documentation
- Configure CORS for Flutter app
- Add class-validator for DTO validation
- Implement proper error handling and logging

DATABASE ENTITIES:
1. User (base entity)
   - id (UUID), email (unique), password_hash, role (enum: patient/doctor/pharmacy)
   - created_at, updated_at, avatar_url

2. Patient (extends User)
   - age, diabetes_type, blood_type, status (enum: Stable/Attention/Critical)
   - emergency_contact, diagnosis_date, current_glucose, hba1c, bmi, height, weight

3. Doctor (extends User)
   - specialty, license, hospital, is_available, total_patients
   - satisfaction_rate, years_experience

4. Pharmacy (extends User)
   - pharmacy_name, license, address, is_open, rating, total_reviews

5. GlucoseReading
   - id, patient_id (FK), value (decimal), timestamp (indexed)
   - type (enum: fasting/before_meal/after_meal/bedtime/random)
   - source (enum: manual/glucometer), notes, status

6. MedicationRequest
   - id, patient_id (FK), pharmacy_id (FK)
   - medication_name, quantity, dosage, patient_note
   - status (enum: pending/accepted/declined/expired)
   - timestamp, is_urgent, decline_reason, price
   - pickup_deadline, pharmacy_message, preparation_time_minutes, is_picked_up

7. Appointment
   - id, patient_id (FK), doctor_id (FK), date_time (indexed)
   - type (enum: Online/Physical), status (enum: Confirmed/Pending/Completed/Cancelled)
   - notes

8. Message
   - id, sender_id (FK), receiver_id (FK), content, timestamp, is_read

9. Conversation
   - id, doctor_id (FK), patient_id (FK, unique together)
   - last_message, last_message_time

10. PatientRequest
    - id, patient_id (FK), doctor_id (FK)
    - status (enum: pending/accepted/declined), request_date, urgent_note

11. Notification
    - id, user_id (FK), type, title, message, timestamp, is_read, severity

MODULES TO IMPLEMENT:

1. AUTH MODULE (auth/)
   POST /api/auth/register/patient - Register patient
   POST /api/auth/register/medecin - Register doctor
   POST /api/auth/register/pharmacien - Register pharmacy
   POST /api/auth/login - Login (email, password, role)
   POST /api/auth/logout - Logout
   GET /api/auth/me - Get current user profile
   - Implement JwtAuthGuard and JwtStrategy
   - Hash passwords with bcrypt (10 rounds)
   - Return JWT token on successful auth

2. PATIENTS MODULE (patients/)
   POST /api/patients/:patientId/glucose - Add glucose reading
   GET /api/patients/:patientId/glucose - Get glucose readings (with filters)
   GET /api/patients/:patientId/glucose/latest - Get latest reading
   GET /api/patients/:patientId/glucose/statistics - Get statistics
   GET /api/patients/:patientId - Get patient profile
   PUT /api/patients/:patientId - Update patient profile
   GET /api/patients/:patientId/doctors - Search doctors
   GET /api/patients/:patientId/pharmacies - Search pharmacies
   POST /api/patients/:patientId/medication-requests - Create med request
   GET /api/patients/:patientId/medication-requests - Get med requests
   GET /api/patients/:patientId/conversations - Get conversations
   POST /api/patients/:patientId/conversations - Create conversation
   GET /api/patients/:patientId/recommendations - Get health recommendations
   POST /api/patients/:patientId/request-doctor - Request to add doctor

3. DOCTORS MODULE (doctors/)
   GET /api/doctors/:doctorId/patients - Get all patients
   GET /api/doctors/:doctorId/patients/:patientId - Get patient details
   GET /api/doctors/:doctorId/patient-requests - Get patient requests
   POST /api/doctors/:doctorId/patient-requests/:requestId/accept - Accept request
   POST /api/doctors/:doctorId/patient-requests/:requestId/decline - Decline request
   GET /api/doctors/:doctorId/appointments - Get appointments
   POST /api/doctors/:doctorId/appointments - Create appointment
   GET /api/doctors/:doctorId/dashboard - Get dashboard stats
   GET /api/doctors/:doctorId/notifications - Get notifications
   GET /api/doctors/:doctorId - Get doctor profile
   PUT /api/doctors/:doctorId - Update doctor profile

4. PHARMACIES MODULE (pharmacies/)
   GET /api/pharmacies/:pharmacyId/medication-requests - Get all requests
   PUT /api/pharmacies/:pharmacyId/medication-requests/:requestId/accept - Accept request
   PUT /api/pharmacies/:pharmacyId/medication-requests/:requestId/decline - Decline request
   PUT /api/pharmacies/:pharmacyId/medication-requests/:requestId/mark-picked - Mark picked up
   GET /api/pharmacies/:pharmacyId/dashboard - Get dashboard stats
   GET /api/pharmacies/:pharmacyId/badges - Get badges
   GET /api/pharmacies/:pharmacyId/performance - Get performance metrics
   GET /api/pharmacies/:pharmacyId/activity - Get activity events
   GET /api/pharmacies/:pharmacyId/reviews - Get reviews
   POST /api/pharmacies/:pharmacyId/reviews - Submit review (patient only)
   GET /api/pharmacies/:pharmacyId - Get pharmacy profile
   PUT /api/pharmacies/:pharmacyId - Update pharmacy profile

5. APPOINTMENTS MODULE (appointments/)
   PUT /api/appointments/:appointmentId - Update appointment status

6. MESSAGES MODULE (messages/)
   GET /api/conversations/:conversationId/messages - Get messages
   POST /api/conversations/:conversationId/messages - Send message

7. NOTIFICATIONS MODULE (notifications/)
   PUT /api/notifications/:notificationId/read - Mark as read

AUTHENTICATION & GUARDS:
- Implement JwtAuthGuard for protected routes
- Implement RolesGuard with @Roles() decorator
- Create custom @CurrentUser() decorator
- Role-based access control:
  * Patient: Own data only
  * Doctor: Own data + their patients' data
  * Pharmacy: Own data + requests directed to them

VALIDATION:
- Create DTOs with class-validator for all endpoints
- Example:
  class CreateGlucoseReadingDto {
    @IsNumber() @Min(0) @Max(600) value: number;
    @IsDateString() timestamp: string;
    @IsEnum(['fasting', 'before_meal', 'after_meal', 'bedtime', 'random']) type: string;
    @IsEnum(['manual', 'glucometer']) source: string;
    @IsOptional() @IsString() notes?: string;
  }

ERROR HANDLING:
- Global exception filter
- Standard error response format:
  {
    "success": false,
    "error": "Human-readable message",
    "errorCode": "ERROR_CODE",
    "details": {}
  }
- HTTP status codes: 200, 201, 400, 401, 403, 404, 409, 422, 500

SPECIAL LOGIC:
1. Glucose readings:
   - Calculate status based on value (Bas<70, Normal 70-180, Élevé 180-250, Critique >250)
   - Calculate statistics (avg, min, max, time in range)
   
2. Medication requests:
   - Auto-expire pending requests after 48 hours
   - Calculate pickup deadline based on preparation time
   
3. Patient status:
   - Auto-update based on recent glucose patterns
   - Trigger notifications for doctors on critical readings

4. Dashboard statistics:
   - Calculate real-time stats from database
   - Cache frequently accessed data

CONFIGURATION:
- Environment variables (.env):
  * DATABASE_URL
  * JWT_SECRET
  * JWT_EXPIRATION=24h
  * PORT=8000
  * FRONTEND_URL (for CORS)

SWAGGER SETUP:
- Add @ApiTags() to controllers
- Add @ApiOperation() to endpoints
- Add @ApiResponse() for responses
- Add @ApiBearerAuth() for protected routes
- Document all DTOs with @ApiProperty()

ADDITIONAL FEATURES:
- Add logging with Winston
- Implement rate limiting with @nestjs/throttler
- Add request validation pipe globally
- Implement soft deletes on entities
- Add database indexes on frequently queried fields
- Implement pagination for list endpoints

TESTING:
- Unit tests for services
- E2E tests for critical endpoints
- Mock TypeORM repositories
- Test authentication flows

Generate the complete backend with proper folder structure, all controllers, services, entities, DTOs, guards, decorators, and configuration files. Include a comprehensive README.md with setup instructions.
```

---

## 📋 Step-by-Step Generation Commands

If you prefer to generate module by module, use these prompts in sequence:

### Step 1: Project Setup
```
Create a new NestJS project called 'diabcare-backend' with:
- TypeScript configuration
- PostgreSQL connection with TypeORM
- JWT authentication setup
- Swagger documentation
- Global validation pipe
- Exception filters
- CORS configuration for Flutter app

Include:
- main.ts with all configurations
- app.module.ts importing all modules
- .env.example file
- tsconfig.json
- package.json with all dependencies
```

### Step 2: Auth Module
```
Create a complete authentication module for DiabCare with:

Entities:
- User (base entity with discriminator for role)
- Patient extends User
- Doctor extends User  
- Pharmacy extends User

Auth Service implementing:
- register(role, data) - Register new user based on role
- login(email, password, role) - Authenticate user
- validateUser(userId) - Validate JWT token

Auth Controller with endpoints:
- POST /api/auth/register/patient
- POST /api/auth/register/medecin
- POST /api/auth/register/pharmacien
- POST /api/auth/login
- POST /api/auth/logout
- GET /api/auth/me

Include:
- JWT strategy with Passport
- JwtAuthGuard
- RolesGuard with @Roles() decorator
- @CurrentUser() custom decorator
- All DTOs with validation
- Bcrypt password hashing
```

### Step 3: Patients Module
```
Create a complete patients module with:

Entities:
- GlucoseReading entity

Service methods:
- addGlucoseReading()
- getGlucoseReadings() with filters
- getLatestReading()
- getStatistics() - calculate avg, min, max, time in range
- getPatientProfile()
- updatePatientProfile()
- searchDoctors()
- searchPharmacies()
- createMedicationRequest()
- getMedicationRequests()
- getConversations()
- createConversation()
- getRecommendations()
- requestDoctor()

Controller with all patient endpoints from API spec.
Include all DTOs with class-validator decorators.
Implement proper authorization checks.
```

### Step 4: Doctors Module
```
Create a complete doctors module with:

Service methods:
- getPatients() - with search and filters
- getPatientDetails() - including glucose readings
- getPatientRequests()
- acceptPatientRequest()
- declinePatientRequest()
- getAppointments() - with filters
- createAppointment()
- getDashboardStats() - calculate from database
- getNotifications()
- getDoctorProfile()
- updateDoctorProfile()

Controller with all doctor endpoints from API spec.
Include PatientRequest entity.
Include Notification entity.
Add proper role guards (doctor only).
```

### Step 5: Pharmacies Module
```
Create a complete pharmacies module with:

Entities:
- MedicationRequest entity (if not created)
- Review entity

Service methods:
- getMedicationRequests() - with status filters
- acceptMedicationRequest() - set price, deadline
- declineMedicationRequest() - set reason
- markAsPickedUp()
- getDashboardStats() - with period filtering
- getBadges() - gamification system
- getPerformanceMetrics()
- getActivityEvents()
- getReviews()
- addReview() (patient creates)
- getPharmacyProfile()
- updatePharmacyProfile()

Controller with all pharmacy endpoints.
Include statistics calculations.
Implement auto-expire logic for old requests.
```

### Step 6: Messages & Appointments
```
Create messages and appointments modules:

MESSAGES MODULE:
- Message entity
- Conversation entity
- ConversationsService
- MessagesController with:
  * GET /api/conversations/:id/messages
  * POST /api/conversations/:id/messages
- Real-time messaging support structure
- Mark messages as read functionality

APPOINTMENTS MODULE:
- Appointment entity (if not created)
- AppointmentsService
- AppointmentsController with:
  * PUT /api/appointments/:id
- Status update logic
- Notification triggers
```

### Step 7: Database Migrations
```
Create TypeORM migrations for all entities:
- users table (with type for discriminator)
- patients table
- doctors table
- pharmacies table
- glucose_readings table with indexes
- medication_requests table
- appointments table
- messages table
- conversations table
- patient_requests table
- notifications table
- reviews table

Include proper foreign keys, indexes, and constraints.
```

### Step 8: Testing Setup
```
Create comprehensive tests:

Unit tests for each service:
- auth.service.spec.ts
- patients.service.spec.ts
- doctors.service.spec.ts
- pharmacies.service.spec.ts

E2E tests for critical flows:
- auth.e2e-spec.ts - registration and login
- glucose.e2e-spec.ts - CRUD operations
- medication-requests.e2e-spec.ts - full workflow

Include mock data and repository mocks.
```

---

## 🎯 Quick Start Commands After Generation

```bash
# Install dependencies
npm install

# Set up database
createdb diabcare
cp .env.example .env
# Edit .env with your database credentials

# Run migrations
npm run migration:run

# Start development server
npm run start:dev

# Run tests
npm run test
npm run test:e2e

# Generate Swagger docs (accessible at http://localhost:8000/api/docs)
npm run start:dev
```

---

## 📝 Example Usage in VS Code

1. **Open VS Code** in an empty folder for your backend
2. **Open a new file** (Ctrl+N)
3. **Paste the main generation prompt** from above
4. **Let Copilot generate** the code structure
5. **Save files** as suggested by Copilot
6. **Run the project** and test endpoints

---

## 🔧 Manual Adjustments After Generation

After Copilot generates the code, you may need to:

1. **Verify database connection** string in .env
2. **Adjust CORS origins** to match your Flutter app
3. **Set proper JWT secret** (use strong random string)
4. **Review and adjust** validation rules in DTOs
5. **Test all endpoints** with Postman or Swagger UI
6. **Add custom business logic** specific to your needs
7. **Implement WebSocket** for real-time features (optional)

---

## 📊 Expected Project Structure

```
diabcare-backend/
├── src/
│   ├── auth/
│   │   ├── decorators/
│   │   │   ├── current-user.decorator.ts
│   │   │   └── roles.decorator.ts
│   │   ├── dto/
│   │   │   ├── login.dto.ts
│   │   │   ├── register-patient.dto.ts
│   │   │   ├── register-doctor.dto.ts
│   │   │   └── register-pharmacy.dto.ts
│   │   ├── entities/
│   │   │   ├── user.entity.ts
│   │   │   ├── patient.entity.ts
│   │   │   ├── doctor.entity.ts
│   │   │   └── pharmacy.entity.ts
│   │   ├── guards/
│   │   │   ├── jwt-auth.guard.ts
│   │   │   └── roles.guard.ts
│   │   ├── strategies/
│   │   │   └── jwt.strategy.ts
│   │   ├── auth.controller.ts
│   │   ├── auth.service.ts
│   │   └── auth.module.ts
│   ├── patients/
│   │   ├── dto/
│   │   ├── entities/
│   │   ├── patients.controller.ts
│   │   ├── patients.service.ts
│   │   └── patients.module.ts
│   ├── doctors/
│   │   ├── dto/
│   │   ├── entities/
│   │   ├── doctors.controller.ts
│   │   ├── doctors.service.ts
│   │   └── doctors.module.ts
│   ├── pharmacies/
│   │   ├── dto/
│   │   ├── entities/
│   │   ├── pharmacies.controller.ts
│   │   ├── pharmacies.service.ts
│   │   └── pharmacies.module.ts
│   ├── glucose/
│   │   ├── dto/
│   │   ├── entities/
│   │   │   └── glucose-reading.entity.ts
│   │   ├── glucose.controller.ts
│   │   ├── glucose.service.ts
│   │   └── glucose.module.ts
│   ├── appointments/
│   ├── messages/
│   ├── medication-requests/
│   ├── notifications/
│   ├── common/
│   │   ├── filters/
│   │   │   └── http-exception.filter.ts
│   │   ├── interceptors/
│   │   │   └── transform.interceptor.ts
│   │   └── pipes/
│   │       └── validation.pipe.ts
│   ├── config/
│   │   └── database.config.ts
│   ├── app.controller.ts
│   ├── app.service.ts
│   ├── app.module.ts
│   └── main.ts
├── test/
│   ├── app.e2e-spec.ts
│   └── jest-e2e.json
├── .env.example
├── .env
├── .gitignore
├── nest-cli.json
├── package.json
├── README.md
├── tsconfig.json
└── tsconfig.build.json
```

---

## 🚨 Important Notes

1. **Security**: Change default JWT secret before deployment
2. **Database**: Ensure PostgreSQL is running before starting the app
3. **CORS**: Update allowed origins in main.ts for production
4. **Validation**: All DTOs should have proper validation decorators
5. **Testing**: Run all tests before deploying to production
6. **Documentation**: Swagger UI will be available at `/api/docs`
7. **Base URL**: Flutter app expects API at `http://10.0.2.2:8000` (Android emulator)

---

## 📚 Additional Resources

- [NestJS Documentation](https://docs.nestjs.com)
- [TypeORM Documentation](https://typeorm.io)
- [Passport JWT Strategy](https://www.passportjs.org/packages/passport-jwt/)
- [Class Validator](https://github.com/typestack/class-validator)
- [Swagger/OpenAPI](https://swagger.io/specification/)

---

## ✅ Verification Checklist

After generation, verify:

- [ ] All endpoints respond correctly
- [ ] Authentication works (JWT tokens)
- [ ] Role-based access control works
- [ ] Database entities created
- [ ] Migrations run successfully
- [ ] Swagger documentation accessible
- [ ] Validation errors return proper format
- [ ] Error handling works correctly
- [ ] CORS configured for Flutter app
- [ ] Environment variables loaded
- [ ] Tests pass (unit + e2e)
- [ ] Logging works properly

---

**Ready to use with GitHub Copilot!** Just copy the main prompt and start coding. 🚀

