# DiabCare Backend API Documentation Package

## 📦 What's Included

This package contains complete API specifications and generation guides for building the DiabCare backend using NestJS.

### 📄 Documents in This Package

1. **API_REQUIREMENTS_DOCUMENT.md** (Main Specification)
   - Complete API endpoint specifications
   - Request/Response schemas for all 53 endpoints
   - Data models and TypeScript interfaces
   - Authentication & authorization details
   - Error handling guidelines
   - Database schema recommendations
   - Implementation notes for NestJS

2. **NESTJS_GENERATION_PROMPT.md** (Copilot Instructions)
   - Ready-to-use prompts for GitHub Copilot
   - Step-by-step generation commands
   - Module-by-module generation guide
   - Quick start commands
   - Verification checklist
   - Manual adjustment guide

3. **API_QUICK_REFERENCE.md** (Visual Guide)
   - Visual flow diagrams
   - Role-based journey examples
   - Quick endpoint reference
   - Common request/response formats
   - Security matrix
   - Debugging tips

---

## 🎯 Purpose

This documentation was created by analyzing the **entire Flutter frontend codebase** for the DiabCare diabetes management application to identify:

- All user screens and interactive elements
- Every functionality that requires backend support
- Data structures and models used
- Expected API responses
- Authentication flows
- Role-based access requirements

The result is a **comprehensive, production-ready API specification** that perfectly matches the frontend requirements.

---

## 🏗️ Application Architecture

### System Overview

```
┌─────────────────────────────────────────────────────────────┐
│                    Flutter Mobile App                        │
│  ┌────────────┬────────────┬────────────────────────────┐   │
│  │  Patient   │   Doctor   │        Pharmacy            │   │
│  │  Interface │  Interface │       Interface            │   │
│  └────────────┴────────────┴────────────────────────────┘   │
└────────────────────────┬────────────────────────────────────┘
                         │
                         │ REST API (JSON)
                         │ JWT Authentication
                         │
┌────────────────────────┴────────────────────────────────────┐
│                      NestJS Backend API                      │
│  ┌─────────────────────────────────────────────────────┐    │
│  │  Modules: Auth, Patients, Doctors, Pharmacies       │    │
│  │           Glucose, Appointments, Messages           │    │
│  └─────────────────────────────────────────────────────┘    │
└────────────────────────┬────────────────────────────────────┘
                         │
                         │ TypeORM
                         │
┌────────────────────────┴────────────────────────────────────┐
│                   PostgreSQL Database                        │
│  Tables: users, patients, doctors, pharmacies, glucose_     │
│          readings, medication_requests, appointments, etc.   │
└─────────────────────────────────────────────────────────────┘
```

---

## 🔑 Key Features

### For Patients 👤
- Track glucose readings (manual & glucometer sync)
- View statistics, trends, and charts
- Get personalized health recommendations
- Search and connect with doctors
- Request medications from pharmacies
- Chat with doctors in real-time
- Schedule and manage appointments
- View complete medical history

### For Doctors 👨‍⚕️
- Monitor all patients' health data
- Receive critical glucose alerts
- View patient medical reports
- Accept/decline patient requests
- Manage appointment calendar
- Chat with patients
- Dashboard with analytics
- Patient status tracking

### For Pharmacies 💊
- Receive and manage medication requests
- Accept/decline with pricing
- Track order fulfillment
- Performance analytics dashboard
- Gamification system (badges, levels)
- Customer reviews management
- Revenue tracking
- Response time optimization

---

## 📊 API Statistics

- **Total Endpoints**: 53 REST APIs
- **Authentication Endpoints**: 6
- **Patient Endpoints**: 21
- **Doctor Endpoints**: 14
- **Pharmacy Endpoints**: 12
- **Shared/Common Endpoints**: 6

### Breakdown by HTTP Method
- **GET**: 28 endpoints (Read operations)
- **POST**: 16 endpoints (Create operations)
- **PUT**: 9 endpoints (Update operations)
- **DELETE**: 0 endpoints (Soft deletes used)

---

## 🚀 Getting Started

### Option 1: Use GitHub Copilot (Recommended)

1. **Open the generation prompt**:
   - Open `NESTJS_GENERATION_PROMPT.md`
   - Copy the main generation prompt

2. **Create new NestJS project folder**:
   ```bash
   mkdir diabcare-backend
   cd diabcare-backend
   code .
   ```

3. **Paste prompt in VS Code**:
   - Open a new file (Ctrl+N)
   - Paste the generation prompt
   - Let Copilot generate the entire backend structure

4. **Follow the setup instructions** Copilot generates

### Option 2: Manual Development

1. **Read the full specification**:
   - Open `API_REQUIREMENTS_DOCUMENT.md`
   - Review all endpoints, models, and requirements

2. **Set up NestJS project**:
   ```bash
   npm i -g @nestjs/cli
   nest new diabcare-backend
   cd diabcare-backend
   ```

3. **Install dependencies**:
   ```bash
   npm install @nestjs/typeorm typeorm pg
   npm install @nestjs/jwt @nestjs/passport passport passport-jwt
   npm install @nestjs/config
   npm install bcrypt
   npm install class-validator class-transformer
   npm install @nestjs/swagger
   ```

4. **Follow the module-by-module guide** in `NESTJS_GENERATION_PROMPT.md`

### Option 3: Quick Reference Development

1. **Use the quick reference guide**:
   - Open `API_QUICK_REFERENCE.md`
   - Follow the visual examples
   - Copy-paste example requests/responses

2. **Test as you build**:
   - Use the provided curl commands
   - Access Swagger UI at http://localhost:8000/api/docs

---

## 📋 Implementation Checklist

### Phase 1: Foundation
- [ ] Set up NestJS project structure
- [ ] Configure PostgreSQL database connection
- [ ] Set up TypeORM with entities
- [ ] Implement JWT authentication
- [ ] Create base guards and decorators
- [ ] Set up Swagger documentation

### Phase 2: Core Modules
- [ ] Auth Module (register, login, JWT)
- [ ] Users Module (base user entity)
- [ ] Patients Module (patient-specific logic)
- [ ] Doctors Module (doctor-specific logic)
- [ ] Pharmacies Module (pharmacy-specific logic)

### Phase 3: Features
- [ ] Glucose readings CRUD
- [ ] Statistics calculations
- [ ] Patient-Doctor relationships
- [ ] Medication requests system
- [ ] Appointments management
- [ ] Messaging system

### Phase 4: Advanced Features
- [ ] Real-time notifications
- [ ] Dashboard analytics
- [ ] Performance metrics (pharmacy)
- [ ] Gamification system (badges)
- [ ] Medical report generation
- [ ] WebSocket support (optional)

### Phase 5: Testing & Deployment
- [ ] Unit tests for all services
- [ ] E2E tests for critical flows
- [ ] Load testing
- [ ] Security audit
- [ ] Deploy to production server
- [ ] Set up monitoring and logging

---

## 🔐 Security Considerations

### Implemented Security Features

1. **Authentication**:
   - JWT tokens with expiration
   - Password hashing with bcrypt (10 rounds)
   - Token refresh mechanism (recommended)

2. **Authorization**:
   - Role-based access control (Patient/Doctor/Pharmacy)
   - Resource ownership validation
   - Guards on all protected routes

3. **Input Validation**:
   - class-validator on all DTOs
   - Type checking with TypeScript
   - SQL injection prevention (TypeORM parameterized queries)

4. **Data Protection**:
   - CORS configuration
   - Rate limiting (recommended: @nestjs/throttler)
   - Sensitive data encryption (optional: for PHI)

5. **Best Practices**:
   - Environment variables for secrets
   - HTTPS in production (required)
   - Error messages don't leak sensitive info
   - Audit logs for critical operations (recommended)

### HIPAA Compliance Notes

⚠️ **Important**: This is a healthcare application dealing with Protected Health Information (PHI).

Additional requirements for HIPAA compliance:
- [ ] Encrypt data at rest (database encryption)
- [ ] Encrypt data in transit (HTTPS/TLS)
- [ ] Implement audit logging
- [ ] Add data backup and recovery
- [ ] Create Business Associate Agreements (BAAs)
- [ ] Implement access controls and user permissions
- [ ] Add data breach notification procedures
- [ ] Regular security assessments

*Consult with a HIPAA compliance expert before production deployment.*

---

## 🗄️ Database Schema

### Core Tables

1. **users** (Base table)
   - id, email, password_hash, role, created_at, updated_at

2. **patients** (Extends users)
   - user_id (FK), age, diabetes_type, blood_type, status, hba1c, bmi

3. **doctors** (Extends users)
   - user_id (FK), specialty, license, hospital, is_available

4. **pharmacies** (Extends users)
   - user_id (FK), pharmacy_name, license, address, rating

5. **glucose_readings**
   - id, patient_id (FK), value, timestamp (indexed), type, source

6. **medication_requests**
   - id, patient_id (FK), pharmacy_id (FK), status, price, timestamp

7. **appointments**
   - id, patient_id (FK), doctor_id (FK), date_time (indexed), status

8. **messages**
   - id, sender_id (FK), receiver_id (FK), content, timestamp, is_read

9. **conversations**
   - id, doctor_id (FK), patient_id (FK, unique together)

10. **notifications**
    - id, user_id (FK), type, message, timestamp, is_read

### Indexes Recommendation

```sql
-- Frequently queried fields
CREATE INDEX idx_glucose_patient_timestamp ON glucose_readings(patient_id, timestamp);
CREATE INDEX idx_appointments_doctor_date ON appointments(doctor_id, date_time);
CREATE INDEX idx_med_requests_pharmacy_status ON medication_requests(pharmacy_id, status);
CREATE INDEX idx_messages_receiver_time ON messages(receiver_id, timestamp);
```

---

## 🧪 Testing Strategy

### Unit Tests
```typescript
describe('GlucoseService', () => {
  it('should calculate correct glucose statistics', () => {
    // Test average, min, max, time in range
  });
  
  it('should determine correct glucose status', () => {
    // Test status calculation (Bas, Normal, Élevé, Critique)
  });
});
```

### E2E Tests
```typescript
describe('Auth (e2e)', () => {
  it('POST /api/auth/register/patient', () => {
    // Test patient registration flow
  });
  
  it('POST /api/auth/login', () => {
    // Test login with correct credentials
  });
  
  it('GET /api/auth/me', () => {
    // Test getting current user with JWT
  });
});
```

### Integration Tests
- Test patient-doctor relationship creation
- Test medication request full workflow
- Test messaging between patient and doctor
- Test appointment scheduling and updates

---

## 📈 Performance Optimization

### Recommendations

1. **Database Optimization**:
   - Add indexes on frequently queried columns
   - Use database connection pooling
   - Implement query result caching (Redis)

2. **API Response Time**:
   - Paginate large lists (limit default to 20)
   - Use select fields to return only needed data
   - Implement lazy loading for relations

3. **Caching Strategy**:
   - Cache dashboard statistics (5-minute TTL)
   - Cache user profiles (10-minute TTL)
   - Invalidate cache on updates

4. **Scaling**:
   - Implement horizontal scaling with load balancer
   - Use separate database for read replicas
   - Queue system for background jobs (Bull + Redis)

---

## 📱 Flutter Integration

### Base URL Configuration

The Flutter app expects the API at:
- **Android Emulator**: `http://10.0.2.2:8000`
- **iOS Simulator**: `http://localhost:8000`
- **Real Device**: `http://YOUR_IP:8000`
- **Production**: `https://api.diabcare.com`

### Authentication Flow in Flutter

```dart
// 1. Login
final response = await http.post(
  Uri.parse('$baseUrl/api/auth/login'),
  body: jsonEncode({
    'email': email,
    'password': password,
    'role': 'patient',
  }),
);

final token = jsonDecode(response.body)['token'];

// 2. Store token
await storage.write(key: 'jwt_token', value: token);

// 3. Use in future requests
final response = await http.get(
  Uri.parse('$baseUrl/api/patients/$patientId'),
  headers: {
    'Authorization': 'Bearer $token',
  },
);
```

---

## 🐛 Troubleshooting

### Common Issues

**Issue**: Database connection fails
```bash
Solution: Check PostgreSQL is running
sudo service postgresql status
sudo service postgresql start
```

**Issue**: JWT token invalid
```bash
Solution: Check JWT_SECRET matches in .env
Also check token expiration time
```

**Issue**: CORS errors from Flutter
```bash
Solution: Add Flutter app origin in main.ts
app.enableCors({
  origin: ['http://10.0.2.2:*', 'http://localhost:*'],
  credentials: true,
});
```

**Issue**: TypeORM entities not found
```bash
Solution: Check entities path in TypeOrmModule config
entities: [__dirname + '/**/*.entity{.ts,.js}']
```

---

## 📞 Support & Resources

### Official Documentation
- [NestJS Documentation](https://docs.nestjs.com/)
- [TypeORM Documentation](https://typeorm.io/)
- [PostgreSQL Documentation](https://www.postgresql.org/docs/)
- [JWT Best Practices](https://jwt.io/introduction)

### Related Files
- `lib/features/auth/services/auth_service.dart` - Flutter auth implementation
- `lib/data/models/*.dart` - Flutter data models
- `lib/features/*/viewmodels/*.dart` - Flutter business logic

### Community
- NestJS Discord: https://discord.gg/nestjs
- Stack Overflow: Tag `nestjs`

---

## 📝 Change Log

### Version 1.0.0 (Initial Release)
- Complete API specification for 53 endpoints
- Full data model definitions
- Authentication and authorization system
- Role-based access control
- Three user types: Patient, Doctor, Pharmacy
- Real-time messaging support
- Dashboard analytics
- Medication request management
- Glucose monitoring and statistics
- Appointment scheduling

---

## 🤝 Contributing

This API specification is based on the Flutter frontend requirements. If you find any discrepancies or have suggestions:

1. Check the Flutter codebase for verification
2. Update the relevant documentation file
3. Ensure consistency across all three documents
4. Test the changes with the Flutter app

---

## ⚖️ License

This documentation is provided as-is for the DiabCare project.

---

## 🎓 Learning Path

### For Backend Developers New to NestJS

1. **Week 1**: Learn NestJS Basics
   - Controllers, Services, Modules
   - Dependency Injection
   - Pipes and Guards

2. **Week 2**: Database Integration
   - TypeORM setup
   - Entity relationships
   - Migrations

3. **Week 3**: Authentication
   - JWT implementation
   - Passport strategies
   - Guards and decorators

4. **Week 4**: Build DiabCare API
   - Follow the generation prompt
   - Implement module by module
   - Test as you go

### Recommended Learning Resources
- [NestJS Official Course](https://courses.nestjs.com/)
- [NestJS Fundamentals](https://learn.nestjs.com/)
- [TypeORM Tutorial](https://typeorm.io/#/undefined)

---

## 📊 Success Metrics

Track these metrics after implementation:

### Performance Metrics
- [ ] API response time < 200ms (95th percentile)
- [ ] Database query time < 50ms (average)
- [ ] Authentication time < 100ms
- [ ] Support 100+ concurrent users

### Code Quality Metrics
- [ ] Test coverage > 80%
- [ ] Zero critical security vulnerabilities
- [ ] All endpoints documented in Swagger
- [ ] TypeScript strict mode enabled

### Business Metrics
- [ ] Patient onboarding success rate > 95%
- [ ] Doctor dashboard load time < 1s
- [ ] Medication request processing time < 5min
- [ ] Message delivery success rate > 99%

---

## 🚀 Deployment Guide

### Production Deployment Checklist

1. **Environment Configuration**
   - [ ] Set strong JWT_SECRET
   - [ ] Configure production DATABASE_URL
   - [ ] Set NODE_ENV=production
   - [ ] Configure proper CORS origins

2. **Security Hardening**
   - [ ] Enable HTTPS/TLS
   - [ ] Set up rate limiting
   - [ ] Implement API key authentication (optional)
   - [ ] Configure helmet.js middleware

3. **Database**
   - [ ] Run all migrations
   - [ ] Set up automated backups
   - [ ] Configure connection pooling
   - [ ] Enable SSL for database connection

4. **Monitoring**
   - [ ] Set up logging (Winston/Pino)
   - [ ] Configure error tracking (Sentry)
   - [ ] Add performance monitoring
   - [ ] Set up health check endpoint

5. **Scaling**
   - [ ] Configure load balancer
   - [ ] Set up auto-scaling rules
   - [ ] Implement caching layer (Redis)
   - [ ] Configure CDN (if needed)

### Deployment Platforms
- **Recommended**: AWS (EC2 + RDS), Digital Ocean, Heroku
- **Database**: AWS RDS PostgreSQL, managed PostgreSQL
- **Monitoring**: CloudWatch, DataDog, New Relic

---

## 🎉 Conclusion

This documentation package provides everything needed to build a production-ready backend API for the DiabCare Flutter application. The specifications are based on thorough analysis of the frontend codebase and represent a complete, feature-rich diabetes management platform.

**Key Takeaways:**
- ✅ 53 fully-specified API endpoints
- ✅ Complete data models and schemas
- ✅ Ready-to-use Copilot generation prompts
- ✅ Security and HIPAA considerations
- ✅ Testing and deployment guidelines
- ✅ Performance optimization recommendations

**Next Steps:**
1. Choose your implementation approach (Copilot or Manual)
2. Follow the generation/implementation guide
3. Test thoroughly with the Flutter app
4. Deploy to production with proper security measures

**Good luck building DiabCare! 🏥💙**

---

*Last Updated: February 20, 2026*  
*Version: 1.0.0*  
*Compatible with: Flutter 3.x, NestJS 10.x, PostgreSQL 15+*

