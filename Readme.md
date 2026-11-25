# Pill Proof

## AI Agent Development Specification

> **Project:** Pill Proof
> **Team:** TechNitro
> **Event:** ENVISION '26
> **Product:** Mobile-first medicine verification + medication intake awareness application
> **Primary stack:** Flutter + Dart + MongoDB Atlas + Node.js/TypeScript backend

---

## Repository Quickstart & Architecture Guide

### System Architecture
Pill Proof consists of a **Flutter mobile application** (Riverpod, GoRouter, Material 3) connecting to a **Node.js/Express TypeScript REST API** with a **MongoDB Atlas** persistence layer:

```
[Flutter Mobile App (frontend/)] <--- REST API (JSON/JWT) ---> [Express TypeScript API (backend/)] <---> [MongoDB Atlas (pill_proof)]
```
Detailed architecture documentation is available in [docs/ARCHITECTURE.md](docs/ARCHITECTURE.md).

### Prerequisites
- **Flutter SDK:** >= 3.47.5 (Channel stable)
- **Dart SDK:** >= 3.13.4
- **Node.js:** >= 20.0.0 (v24 LTS installed)
- **npm:** >= 10.0.0
- **Git:** >= 2.50.0
- **MongoDB Atlas:** Free cluster or local MongoDB instance

---

### Setup & Running

#### 1. Backend Setup
```bash
# Navigate to backend directory
cd backend

# Install dependencies
npm install

# Configure environment variables
cp .env.example .env
# Edit .env and supply your MONGODB_URI and JWT_SECRET

# Run automated tests
npm test

# Start the development server (with hot reload via tsx)
npm run dev

# Health check endpoint
# GET http://localhost:5000/api/health
```

#### 2. Mobile App (Flutter) Setup
```bash
# Navigate to frontend directory
cd frontend

# Get Flutter dependencies
flutter pub get

# Configure environment variables
cp .env.example .env

# Run static analysis and widget tests
flutter analyze
flutter test

# Run the Flutter app on connected device / emulator / web
flutter run
# Or specifically for Chrome / Web during development:
flutter run -d chrome
```

---

### Development Workflow
1. **Never commit secrets:** `.env` files are ignored by root `.gitignore`. Never hardcode API keys or MongoDB passwords in source code.
2. **Branching & Commits:** Create feature branches for verification logic, intake monitoring, and UI components.
3. **Automated Verification:** Before submitting pull requests, run:
   - Backend: `npm test` and `npm run build`
   - Frontend: `flutter analyze` and `flutter test`

---

You are an autonomous software-development agent.

Your responsibility is to **design, implement, test, debug, and document the complete Pill Proof application** described in this README.

Do not stop after generating boilerplate.

Do not only create UI mockups.

Do not leave major functionality as TODOs.

Build a functional end-to-end prototype that can:

1. Register/login users.
2. Add medicines.
3. Scan or manually enter medicine information.
4. Search the verified medicine database.
5. Display a verification/status result.
6. Record prescribed medication information.
7. Track intake events.
8. Maintain medication history.
9. Detect when recorded intake reaches/exceeds the user-entered prescribed limit.
10. Generate local reminders/awareness alerts.
11. Allow users/caregivers to manage medications.
12. Persist data securely in MongoDB Atlas through a backend API.
13. Work on Android.
14. Have a polished, presentation-ready UI.
15. Include sample/demo medicine data so the application can be demonstrated without external pharmaceutical integrations.

If a requirement is ambiguous, choose the safest, simplest, maintainable implementation that satisfies the product goal and document the decision.

---

# 2. PRODUCT OVERVIEW

Pill Proof is a mobile application designed to provide an additional layer of awareness around medicines.

The application combines two related workflows:

### A. Medicine Verification

The user enters or scans medicine details such as:

* Medicine name
* Batch number
* Expiry date
* Barcode
* Manufacturer

The application compares those details against a **verified medicine dataset** maintained by the application/backend.

The result should clearly communicate whether the submitted information:

* Matches a verified record
* Requires review
* Does not match a known record
* Has expired

### B. Medication Intake Monitoring

The user can create a medication record containing:

* Medicine
* Prescribed dosage
* Maximum prescribed intake
* Schedule
* Frequency
* Start date
* End date
* Optional notes

The application records each intake event.

It maintains a history and compares recorded intake against the user-entered prescribed limit.

If the recorded intake reaches or exceeds the configured limit, the application displays an awareness warning.

---

# 3. SAFETY POSITIONING

Pill Proof is an **awareness and information application**.

It is NOT:

* A doctor
* A diagnostic system
* A pharmaceutical authentication laboratory
* A substitute for professional medical advice
* A system that independently determines whether a medicine is medically safe for a particular person

Never claim:

> "This medicine is definitely genuine."

Instead use language such as:

> "Verified against the available Pill Proof database."

or:

> "No matching verified record was found."

Likewise, intake warnings must be based on the **limits entered by the user/caregiver**, not on the application inventing medical dosage recommendations.

Example:

```text
Recorded intake has reached the limit entered for this medication.

Do not take additional medication based solely on this app.
Follow the instructions provided by your healthcare professional.
```

---

# 4. CORE USER FLOW

The primary application flow is:

```text
Launch
  ↓
Onboarding
  ↓
Login / Register
  ↓
Dashboard
  ├── Verify Medicine
  ├── My Medicines
  ├── Today's Intake
  ├── History
  └── Profile
```

Verification flow:

```text
Dashboard
   ↓
Verify Medicine
   ↓
Scan Barcode
   OR
Enter Details Manually
   ↓
Search Backend
   ↓
Verification Engine
   ↓
Result
   ├── Verified Match
   ├── Review Required
   ├── No Match
   └── Expired
```

Medication flow:

```text
Dashboard
   ↓
Add Medication
   ↓
Medicine details
   ↓
Prescription / intake configuration
   ↓
Save
   ↓
Medication Dashboard
   ↓
Log Intake
   ↓
Update Daily Count
   ↓
Check Configured Limit
   ↓
Normal / Warning
```

---

# 5. REQUIRED TECHNOLOGY STACK

## Frontend

Use:

```text
Flutter
Dart
```

Target:

```text
Android
```

Structure the application so iOS can be supported later.

---

# 6. FLUTTER PACKAGES

Use stable, actively maintained packages where appropriate.

Preferred packages:

### State Management

```yaml
flutter_riverpod
```

Use Riverpod for:

* Application state
* Authentication state
* Medicine state
* Verification state
* Medication state
* Intake state

Do not put business logic directly inside widgets.

---

### Navigation

Use:

```yaml
go_router
```

Routes should support authentication guards.

Example:

```text
/login
/register
/onboarding
/home
/verify
/verify/result
/medications
/medications/add
/medications/:id
/history
/profile
/settings
```

---

### HTTP

Use:

```yaml
dio
```

Create a centralized API client.

Do not make raw HTTP requests directly from widgets.

---

### Secure Storage

Use:

```yaml
flutter_secure_storage
```

Store authentication/session information securely.

Never store database passwords in Flutter.

Never store MongoDB credentials inside the application.

---

### Barcode Scanning

Use a maintained Flutter barcode scanning package such as:

```yaml
mobile_scanner
```

The scanner should support common medicine packaging barcode formats where possible.

The scanner must gracefully fall back to manual entry.

---

### Local Notifications

Use:

```yaml
flutter_local_notifications
```

Use it for medication schedule reminders and awareness notifications.

---

### Local Persistence

Use one lightweight local storage solution such as:

```yaml
shared_preferences
```

for simple preferences.

For offline medication/intake caching, prefer:

```yaml
drift
```

or another structured local database if needed.

Do not introduce a complex local database unless the implementation requires it.

---

### Date/Time

Use Dart's standard date/time APIs first.

Add:

```yaml
timezone
```

if required for reliable scheduled notifications.

---

### Networking / Connectivity

Optionally use:

```yaml
connectivity_plus
```

to detect network state and show useful offline/online UI.

---

### UI

Use Flutter Material 3.

Do not add a giant UI framework unnecessarily.

---

# 7. BACKEND

Use:

```text
Node.js
TypeScript
Express.js
```

Recommended structure:

```text
backend/
├── src/
│   ├── config/
│   ├── controllers/
│   ├── middleware/
│   ├── models/
│   ├── routes/
│   ├── services/
│   ├── repositories/
│   ├── utils/
│   ├── validators/
│   └── server.ts
├── tests/
├── .env.example
├── package.json
├── tsconfig.json
└── README.md
```

The backend is responsible for:

* Authentication
* Authorization
* Medicine verification
* Medicine records
* User medication records
* Intake records
* Verification logic
* Input validation
* Database access
* API security

---

# 8. DATABASE

Use:

```text
MongoDB Atlas
```

Database:

```text
pill_proof
```

Suggested collections:

```text
users
medicines
medications
intake_events
verification_logs
```

---

# 9. DATABASE SCHEMAS

## users

Example:

```json
{
  "_id": "ObjectId",
  "name": "User Name",
  "email": "user@example.com",
  "passwordHash": "...",
  "role": "user",
  "createdAt": "Date",
  "updatedAt": "Date"
}
```

Roles:

```text
user
caregiver
admin
```

Do not expose passwordHash to Flutter.

---

# 10. VERIFIED MEDICINE SCHEMA

Collection:

```text
medicines
```

Example:

```json
{
  "_id": "ObjectId",
  "name": "Example Medicine",
  "genericName": "Example Generic",
  "manufacturer": "Example Pharma",
  "batchNumber": "ABC123",
  "barcode": "8901234567890",
  "expiryDate": "2027-12-31",
  "strength": "500 mg",
  "dosageForm": "Tablet",
  "status": "verified",
  "source": "Pill Proof Verified Dataset",
  "createdAt": "Date",
  "updatedAt": "Date"
}
```

Possible status:

```text
verified
review
inactive
```

---

# 11. MEDICATION SCHEMA

This represents a medicine that a user is personally tracking.

```json
{
  "_id": "ObjectId",
  "userId": "ObjectId",
  "medicineId": "ObjectId",
  "medicineName": "Example Medicine",
  "dosage": "1 tablet",
  "frequency": "twice_daily",
  "times": [
    "09:00",
    "21:00"
  ],
  "prescribedLimit": 2,
  "startDate": "2026-10-01",
  "endDate": "2026-10-10",
  "notes": "",
  "active": true,
  "createdAt": "Date",
  "updatedAt": "Date"
}
```

The application must never invent the prescribed limit.

The user/caregiver enters it.

---

# 12. INTAKE EVENT SCHEMA

```json
{
  "_id": "ObjectId",
  "userId": "ObjectId",
  "medicationId": "ObjectId",
  "quantity": 1,
  "takenAt": "Date",
  "scheduledTime": "09:00",
  "source": "manual",
  "createdAt": "Date"
}
```

Possible source values:

```text
manual
reminder
```

---

# 13. VERIFICATION LOG

Store verification attempts for analytics and user history.

```json
{
  "_id": "ObjectId",
  "userId": "ObjectId",
  "medicineInput": {
    "name": "Example",
    "batchNumber": "ABC123",
    "barcode": "8901234567890",
    "manufacturer": "Example Pharma",
    "expiryDate": "2027-12-31"
  },
  "result": "verified",
  "matchedMedicineId": "ObjectId",
  "createdAt": "Date"
}
```

Do not store unnecessary sensitive information.

---

# 14. VERIFICATION ENGINE

The backend should implement deterministic verification.

Input:

```text
medicine name
batch number
barcode
manufacturer
expiry date
```

Matching priority:

### Level 1

Exact barcode match.

### Level 2

Exact combination:

```text
medicine name
+
batch number
+
manufacturer
```

### Level 3

Partial search.

Partial search should result in:

```text
REVIEW
```

rather than falsely declaring a medicine verified.

---

# 15. VERIFICATION RESULT TYPES

The API should return one of:

```text
VERIFIED
REVIEW
NO_MATCH
EXPIRED
```

Example:

```json
{
  "status": "VERIFIED",
  "message": "Medicine details match a verified Pill Proof record.",
  "medicine": {
    "name": "Example Medicine",
    "manufacturer": "Example Pharma",
    "batchNumber": "ABC123",
    "expiryDate": "2027-12-31"
  }
}
```

For no match:

```json
{
  "status": "NO_MATCH",
  "message": "No matching verified record was found."
}
```

Do not label this as definitively counterfeit.

Use:

> "No matching verified record was found."

---

# 16. EXPIRY CHECK

If:

```text
expiryDate < currentDate
```

return:

```text
EXPIRED
```

Expiry must be evaluated on the backend.

The Flutter client may also display local validation, but backend validation is authoritative.

---

# 17. INTAKE LIMIT ENGINE

For every intake event:

```text
dailyIntake =
sum(quantity)
for medication
for current calendar day
```

Compare:

```text
dailyIntake >= prescribedLimit
```

If true:

```text
LIMIT_REACHED
```

If:

```text
dailyIntake > prescribedLimit
```

return:

```text
LIMIT_EXCEEDED
```

Otherwise:

```text
WITHIN_LIMIT
```

Example response:

```json
{
  "status": "LIMIT_REACHED",
  "dailyIntake": 2,
  "prescribedLimit": 2
}
```

---

# 18. IMPORTANT INTAKE SAFETY RULE

Do not calculate or recommend medical dosage.

The application only compares:

```text
recorded intake
```

against:

```text
user/caregiver-entered prescribed limit
```

The app must never say:

> "You can safely take another tablet."

Instead say:

> "The configured intake limit has been reached. Follow your healthcare professional's instructions."

---

# 19. REST API

Base URL:

```text
/api/v1
```

---

## Authentication

### POST

```text
/auth/register
```

### POST

```text
/auth/login
```

### GET

```text
/auth/me
```

---

# 20. MEDICINE API

### POST

```text
/medicines/verify
```

Request:

```json
{
  "name": "Example Medicine",
  "batchNumber": "ABC123",
  "barcode": "8901234567890",
  "manufacturer": "Example Pharma",
  "expiryDate": "2027-12-31"
}
```

### GET

```text
/medicines/search?q=example
```

---

# 21. MEDICATION API

### GET

```text
/medications
```

### POST

```text
/medications
```

### GET

```text
/medications/:id
```

### PATCH

```text
/medications/:id
```

### DELETE

```text
/medications/:id
```

---

# 22. INTAKE API

### POST

```text
/medications/:id/intake
```

### GET

```text
/medications/:id/intake
```

### GET

```text
/intake/today
```

### GET

```text
/intake/history
```

---

# 23. VERIFICATION HISTORY

### GET

```text
/verification/history
```

---

# 24. API SECURITY

Implement:

* JWT authentication
* Password hashing using Argon2 or bcrypt
* Request validation
* Rate limiting
* CORS
* Helmet
* Proper HTTP status codes
* Centralized error handling
* Environment variables
* MongoDB connection pooling

Never hardcode:

```text
JWT_SECRET
MONGODB_URI
database passwords
API keys
```

---

# 25. ENVIRONMENT VARIABLES

Backend `.env.example`:

```env
NODE_ENV=development
PORT=5000

MONGODB_URI=mongodb+srv://...
MONGODB_DATABASE=pill_proof

JWT_SECRET=replace_this
JWT_EXPIRES_IN=7d

CORS_ORIGIN=*
```

Flutter should have its own environment configuration.

Never commit real credentials.

---

# 26. FLUTTER PROJECT STRUCTURE

Use feature-based architecture.

```text
lib/
├── main.dart
│
├── app/
│   ├── app.dart
│   ├── router.dart
│   └── theme.dart
│
├── core/
│   ├── constants/
│   ├── errors/
│   ├── network/
│   ├── storage/
│   ├── utils/
│   └── widgets/
│
├── features/
│   ├── auth/
│   │   ├── data/
│   │   ├── domain/
│   │   └── presentation/
│   │
│   ├── dashboard/
│   │
│   ├── verification/
│   │
│   ├── medications/
│   │
│   ├── intake/
│   │
│   ├── history/
│   │
│   └── profile/
│
└── shared/
    ├── models/
    ├── widgets/
    └── extensions/
```

Follow separation of concerns.

Widgets should not contain API/database logic.

---

# 27. REQUIRED SCREENS

## 1. Splash Screen

Display:

```text
PILL PROOF

Know before you take.
```

Then determine authentication state.

---

# 28. ONBOARDING

Three simple pages:

### Page 1

```text
Verify Medicines
Check medicine details against the available verified dataset.
```

### Page 2

```text
Track Intake
Keep a simple record of your medication intake.
```

### Page 3

```text
Stay Aware
Receive reminders and awareness alerts.
```

---

# 29. LOGIN

Fields:

```text
Email
Password
```

Actions:

```text
Login
Create account
```

Add basic validation.

---

# 30. REGISTER

Fields:

```text
Name
Email
Password
Confirm password
```

Do not collect unnecessary personal information.

---

# 31. DASHBOARD

The dashboard is the primary screen.

Display:

```text
Good morning, <name>

Today's medication
------------------
Medicine A
09:00
[Mark Taken]

Medicine B
21:00
[Mark Taken]

------------------

[ Verify Medicine ]

[ Add Medication ]

Today's intake
2 / 4
```

Also show:

```text
Recent verification
```

and:

```text
Awareness alerts
```

---

# 32. VERIFY MEDICINE SCREEN

Provide two options:

```text
[ Scan Barcode ]

[ Enter Manually ]
```

Manual form:

```text
Medicine Name
Batch Number
Barcode
Manufacturer
Expiry Date
```

All fields should not necessarily be mandatory.

Barcode should be optional when the user is manually entering data.

---

# 33. BARCODE SCANNER

Use the camera scanner.

When a barcode is detected:

```text
barcode → medicine verification form
```

Pre-fill the barcode.

Do not automatically claim that the barcode means the medicine is genuine.

The barcode is simply an input to the verification system.

---

# 34. VERIFICATION RESULT SCREEN

Use strong visual hierarchy.

### Verified

```text
✓ MATCH FOUND

This medicine matches a verified Pill Proof record.

Medicine:
Example Medicine

Manufacturer:
Example Pharma

Batch:
ABC123

Expiry:
2027-12-31
```

### Review

```text
⚠ REVIEW REQUIRED

The available information is not sufficient for a confident match.

Please verify the packaging details and consult a pharmacist or healthcare professional if concerned.
```

### No Match

```text
? NO MATCH FOUND

No matching verified record was found in the current Pill Proof database.
```

### Expired

```text
! EXPIRED

The recorded expiry date has passed.
```

---

# 35. MEDICATION LIST

Display cards:

```text
Medicine name
Dosage
Next scheduled time
Today's intake
Limit
```

Example:

```text
Paracetamol
1 tablet
Next: 9:00 PM

Today's intake
1 / 2

[Log Intake]
```

---

# 36. ADD MEDICATION

Fields:

```text
Medicine
Dosage
Frequency
Schedule
Prescribed daily limit
Start date
End date
Notes
```

Frequency options:

```text
Once daily
Twice daily
Three times daily
Custom
```

Do not provide medically generated dosage suggestions.

---

# 37. LOG INTAKE

When the user taps:

```text
Log Intake
```

show:

```text
Medicine
Quantity
Time
Confirm
```

After confirmation:

```text
POST /medications/:id/intake
```

Backend evaluates the configured limit.

---

# 38. LIMIT ALERT

If limit reached:

Display:

```text
Intake limit reached

You have reached the intake limit configured for this medication.

Follow your healthcare professional's instructions before taking additional medication.
```

If exceeded:

```text
Intake limit exceeded

The recorded intake is above the configured limit.

Do not use this app as a substitute for medical advice. Contact a healthcare professional if you are concerned.
```

Do not use alarming or sensational language.

---

# 39. HISTORY SCREEN

Provide:

### Intake History

```text
October 7

Example Medicine
09:02
1 tablet

Example Medicine
21:01
1 tablet
```

### Verification History

```text
Example Medicine
Verified
October 7
```

Allow filtering by:

```text
Medicine
Date
Status
```

---

# 40. PROFILE

Show:

```text
Name
Email
Account type
```

Actions:

```text
Edit profile
Notification settings
Logout
```

---

# 41. DESIGN SYSTEM

Use a clean healthcare-inspired Material 3 design.

Visual principles:

* Clean
* Trustworthy
* Minimal
* Accessible
* Large touch targets
* Strong status indicators
* Clear typography
* Avoid excessive animations

Use a consistent design token system:

```text
primary
secondary
success
warning
error
surface
background
text
```

Do not scatter arbitrary colors throughout widgets.

---

# 42. ACCESSIBILITY

Support:

* Large text
* Semantic labels
* Screen readers
* High contrast
* Minimum comfortable touch targets
* Clear error messages
* No information conveyed by color alone

For example:

Do not show only:

```text
RED
```

Show:

```text
⚠ Review Required
```

---

# 43. OFFLINE BEHAVIOR

The application should gracefully handle loss of connectivity.

If verification cannot reach the backend:

```text
Unable to verify right now.

Please check your internet connection and try again.
```

Never display:

```text
Verified
```

when the server verification has not actually occurred.

Medication history may be cached locally if implemented.

Any offline intake event must be synchronized carefully when connectivity returns.

Avoid duplicate intake events.

---

# 44. SAMPLE DATA

The application must include a development/demo seed mechanism.

Create at least 5 fictional/demo medicine records.

Example:

```text
Demo Medicine A
Demo Medicine B
Demo Medicine C
Demo Medicine D
Demo Medicine E
```

Use clearly fictional/demo data.

Do not imply that demo records are official pharmaceutical records.

The demo environment should make it easy for judges to test:

### Test 1

Verified medicine.

### Test 2

Unknown medicine.

### Test 3

Expired medicine.

### Test 4

Intake within configured limit.

### Test 5

Intake at configured limit.

### Test 6

Intake above configured limit.

---

# 45. ADMIN / DATA MANAGEMENT

Implement a basic admin capability if practical.

Admin should be able to:

```text
Create medicine record
Edit medicine record
Deactivate medicine record
Search medicine records
```

Protect admin endpoints with:

```text
role === admin
```

Do not expose admin functionality to normal users.

If a full admin UI would significantly delay the mobile MVP, implement secure backend admin endpoints plus a seed script first.

---

# 46. VALIDATION

Flutter validation:

```text
Required fields
Email format
Password strength
Date validity
Positive quantities
Positive prescribed limits
```

Backend validation is mandatory as well.

Never trust client-side validation.

Use a schema validation library such as:

```text
Zod
```

on the Node.js backend.

---

# 47. ERROR HANDLING

Backend errors should follow a consistent format.

Example:

```json
{
  "success": false,
  "error": {
    "code": "MEDICINE_NOT_FOUND",
    "message": "No matching medicine record was found."
  }
}
```

Success:

```json
{
  "success": true,
  "data": {}
}
```

Flutter should convert API errors into user-friendly messages.

Never show raw stack traces to users.

---

# 48. LOGGING

Backend:

Use structured logging.

Log:

* Request method
* Route
* Response status
* Request duration
* Error code

Do NOT log:

* Passwords
* JWTs
* Database credentials
* Sensitive personal information

---

# 49. TESTING

The agent must create tests.

## Backend unit tests

Test:

```text
Verification matching
Expiry logic
Intake limit logic
Authentication
Authorization
Validation
```

## Backend integration tests

Test:

```text
Register
Login
Add medication
Verify medicine
Log intake
Retrieve history
```

## Flutter tests

At minimum:

```text
Verification result rendering
Medication creation validation
Intake state
Authentication state
Navigation guards
```

---

# 50. ACCEPTANCE TESTS

The implementation is NOT complete until these scenarios work.

## Scenario 1 — Register

```text
Open app
→ Register
→ Account created
→ Logged in
→ Dashboard
```

## Scenario 2 — Login

```text
Logout
→ Login
→ Dashboard
```

## Scenario 3 — Verify

```text
Dashboard
→ Verify Medicine
→ Enter demo medicine details
→ Verify
→ VERIFIED result
```

## Scenario 4 — Unknown medicine

```text
Enter unknown details
→ Verify
→ NO MATCH FOUND
```

## Scenario 5 — Expired medicine

```text
Enter expired demo medicine
→ Verify
→ EXPIRED
```

## Scenario 6 — Add medication

```text
Dashboard
→ Add Medication
→ Configure medication
→ Save
→ Medication appears in list
```

## Scenario 7 — Intake

```text
Medication
→ Log Intake
→ Intake count increases
→ History updates
```

## Scenario 8 — Limit

```text
Configure limit = 2
→ Log intake 1
→ Log intake 2
→ LIMIT_REACHED
```

## Scenario 9 — Exceeded

```text
Configure limit = 2
→ Log 3 total units
→ LIMIT_EXCEEDED
```

---

# 51. SECURITY RULES

NEVER:

```text
Connect Flutter directly to MongoDB using credentials.
```

NEVER:

```text
Put MongoDB URI in Flutter.
```

NEVER:

```text
Commit .env files.
```

NEVER:

```text
Hardcode JWT secrets.
```

NEVER:

```text
Trust userId supplied by the client.
```

Always obtain authenticated user identity from the validated JWT.

---

# 52. MONGODB INDEXES

Create indexes for frequently queried fields.

At minimum consider:

```text
users.email
medicines.barcode
medicines.batchNumber
medicines.name
medications.userId
intake_events.userId
intake_events.medicationId
intake_events.takenAt
verification_logs.userId
```

Use compound indexes where query patterns justify them.

Do not create unnecessary indexes.

---

# 53. API DOCUMENTATION

Create:

```text
/docs/API.md
```

Document:

* Endpoint
* HTTP method
* Authentication requirement
* Request body
* Response
* Errors
* Example requests

Optionally generate an OpenAPI specification.

---

# 54. PROJECT DOCUMENTATION

Root structure:

```text
/
├── README.md
├── frontend/
├── backend/
├── docs/
│   ├── API.md
│   ├── ARCHITECTURE.md
│   └── DEMO.md
└── docker-compose.yml
```

If Docker is useful for local backend development, provide it.

MongoDB itself should use Atlas for the actual project database.

---

# 55. DEVELOPMENT COMMANDS

The final README must document commands similar to:

## Flutter

```bash
cd frontend

flutter pub get

flutter analyze

flutter test

flutter run
```

## Backend

```bash
cd backend

npm install

npm run dev

npm test

npm run build
```

## Seed database

```bash
npm run seed
```

The exact commands may be adjusted to the implementation.

---

# 56. DOCKER

If Docker is used:

```text
backend
```

may be containerized.

Do not create a local MongoDB dependency if the project requirement is MongoDB Atlas.

---

# 57. ENVIRONMENT SETUP

Create:

```text
backend/.env.example
frontend/.env.example
```

The README must explain exactly which variables are required.

Never put real secrets into Git.

Add:

```text
.env
.env.*
!.env.example
```

appropriately to `.gitignore`.

---

# 58. GITIGNORE

Include:

```text
.env
.env.*
!.env.example

node_modules/
.dart_tool/
build/
.flutter-plugins
.flutter-plugins-dependencies
.idea/
.vscode/
*.log
```

Adjust for the generated project.

---

# 59. ARCHITECTURE

Use:

```text
                ┌──────────────────────┐
                │      Flutter App     │
                │                      │
                │ UI                   │
                │ Riverpod             │
                │ Services             │
                │ Local Storage         │
                └──────────┬───────────┘
                           │ HTTPS
                           ▼
                ┌──────────────────────┐
                │   Node.js API        │
                │   TypeScript         │
                │                      │
                │ Auth                 │
                │ Verification Engine  │
                │ Medication Service   │
                │ Intake Service       │
                │ Validation           │
                └──────────┬───────────┘
                           │
                           │ MongoDB Driver
                           ▼
                ┌──────────────────────┐
                │    MongoDB Atlas     │
                │                      │
                │ users                │
                │ medicines            │
                │ medications          │
                │ intake_events        │
                │ verification_logs    │
                └──────────────────────┘
```

---

# 60. SEPARATION OF RESPONSIBILITIES

Flutter:

```text
UI
User interaction
Local state
Local notifications
Camera/barcode
API communication
```

Backend:

```text
Authentication
Authorization
Validation
Verification
Business rules
Intake calculations
Database operations
```

MongoDB:

```text
Persistent application data
```

---

# 61. DO NOT OVERENGINEER

This is a student project and prototype.

Do NOT introduce:

* Microservices
* Kubernetes
* GraphQL
* Event buses
* Complex distributed systems
* AI models where deterministic logic is sufficient
* Unnecessary cloud infrastructure

Keep the architecture:

```text
Flutter
    ↓
REST API
    ↓
Node.js
    ↓
MongoDB Atlas
```

Simple, maintainable, demonstrable.

---

# 62. AI / ML

Do not introduce AI merely for marketing.

The initial verification engine must be deterministic.

Possible future enhancements:

```text
OCR
Image-based packaging analysis
Anomaly detection
Medicine image recognition
Natural-language assistant
```

These are future features and are NOT required for the MVP.

---

# 63. OCR

OCR may be added as an enhancement.

If implemented, use it only to extract:

```text
medicine name
batch number
expiry date
manufacturer
```

OCR output must always be editable by the user before verification.

Never assume OCR is correct.

---

# 64. NOTIFICATION SYSTEM

Schedule local notifications based on medication schedules.

Example:

```text
Medication Reminder

It is time for your scheduled medication.

Open Pill Proof to record your intake.
```

After intake:

```text
Intake recorded.
```

When configured limit is reached:

```text
Awareness Alert

The configured intake limit has been reached.
```

Do not create notifications that prescribe additional medication.

---

# 65. UI STATES

Every network-dependent screen must support:

```text
Loading
Success
Empty
Error
Retry
Offline
```

Never leave the user looking at a blank screen.

---

# 66. EMPTY STATES

Example:

```text
No medications yet.

Add a medication to start tracking your intake.
```

Verification:

```text
No verification history yet.

Verify a medicine to see your results here.
```

---

# 67. PERFORMANCE

The app should:

* Avoid unnecessary rebuilds
* Paginate long histories
* Debounce search
* Avoid repeated API calls
* Cache appropriate data
* Dispose controllers correctly
* Handle camera resources correctly

---

# 68. RESPONSIVENESS

Design primarily for mobile.

Support:

```text
small Android phones
large Android phones
tablet layouts where practical
```

Avoid hardcoded screen dimensions.

---

# 69. DEMO MODE

Implement a development/demo mode if useful.

It should allow judges to quickly demonstrate:

```text
Verified
Review
No Match
Expired
Within Limit
Limit Reached
Limit Exceeded
```

Do not make demo mode bypass real security in production.

---

# 70. IMPLEMENTATION ORDER

The autonomous agent should implement in this order:

### Phase 1

Project setup

```text
Flutter project
Node.js backend
TypeScript
MongoDB Atlas connection
Environment configuration
Git configuration
```

### Phase 2

Backend foundation

```text
Express
MongoDB
Models
Validation
Error handling
Authentication
JWT
```

### Phase 3

Medicine verification

```text
Medicine model
Seed data
Verification engine
Verification API
Verification history
```

### Phase 4

Flutter authentication

```text
Onboarding
Login
Register
Auth state
Routing
```

### Phase 5

Dashboard

```text
Dashboard
Medication summary
Verification shortcut
Recent history
```

### Phase 6

Medication tracking

```text
Medication model
Add medication
Medication list
Medication details
Intake logging
```

### Phase 7

Notifications

```text
Local notifications
Medication reminders
Limit alerts
```

### Phase 8

Barcode scanning

```text
Camera
Barcode extraction
Verification integration
```

### Phase 9

History

```text
Intake history
Verification history
Filtering
```

### Phase 10

Testing

```text
Unit tests
Integration tests
Flutter tests
Acceptance tests
```

### Phase 11

Polishing

```text
Animations
Loading states
Error states
Accessibility
Empty states
UI consistency
```

### Phase 12

Documentation

```text
API documentation
Architecture documentation
Setup documentation
Demo guide
```

---

# 71. DEFINITION OF DONE

The project is complete only when:

* [ ] Flutter app builds successfully.
* [ ] Backend builds successfully.
* [ ] MongoDB Atlas connection works.
* [ ] User registration works.
* [ ] User login works.
* [ ] JWT authentication works.
* [ ] Protected routes work.
* [ ] Medicine verification works.
* [ ] Barcode scanning works.
* [ ] Manual medicine entry works.
* [ ] Verification history works.
* [ ] Medication creation works.
* [ ] Medication editing works.
* [ ] Medication deletion/deactivation works.
* [ ] Intake logging works.
* [ ] Intake history works.
* [ ] Configured limit detection works.
* [ ] Local notifications work.
* [ ] Expiry detection works.
* [ ] Demo seed data works.
* [ ] Error states work.
* [ ] Offline/network failure states work.
* [ ] Backend validation works.
* [ ] Flutter validation works.
* [ ] Unit tests exist.
* [ ] Integration tests exist.
* [ ] Flutter tests exist.
* [ ] No secrets are committed.
* [ ] No MongoDB credentials exist in Flutter.
* [ ] API documentation exists.
* [ ] Setup documentation exists.
* [ ] Demo instructions exist.
* [ ] `flutter analyze` passes.
* [ ] Flutter tests pass.
* [ ] Backend tests pass.
* [ ] Production build can be generated.

---

# 72. AGENT OPERATING RULES

When working on this repository:

## Rule 1

Inspect the existing repository before modifying it.

Do not overwrite an existing implementation blindly.

## Rule 2

Run the project before making major assumptions.

## Rule 3

After implementing a feature:

```text
Implement
→ Analyze
→ Test
→ Fix
→ Re-test
```

## Rule 4

If a dependency is deprecated or incompatible, choose a maintained alternative and document the decision.

## Rule 5

Never expose secrets.

## Rule 6

Never bypass authentication merely to make a feature work.

## Rule 7

Never mark a medicine as definitively genuine based solely on a partial match.

## Rule 8

Never generate medical dosage recommendations.

## Rule 9

Do not replace backend validation with Flutter validation.

## Rule 10

Do not stop at a UI prototype.

Every important UI feature must connect to the backend and persistent data.

---

# 73. EXPECTED FINAL REPOSITORY

The final repository should approximately look like:

```text
pill-proof/
│
├── README.md
├── .gitignore
│
├── frontend/
│   ├── android/
│   ├── ios/
│   ├── lib/
│   ├── test/
│   ├── pubspec.yaml
│   └── .env.example
│
├── backend/
│   ├── src/
│   ├── tests/
│   ├── package.json
│   ├── tsconfig.json
│   └── .env.example
│
├── docs/
│   ├── API.md
│   ├── ARCHITECTURE.md
│   └── DEMO.md
│
└── scripts/
```

---

# 74. FINAL PRODUCT GOAL

The finished application should allow a judge to install the Android application and immediately understand:

> **Pill Proof helps users check medicine details against an available verified dataset and keep an awareness-oriented record of medication intake.**

The entire experience should feel like a real product rather than a collection of disconnected demo screens.

The primary demo should be:

```text
LOGIN
  ↓
DASHBOARD
  ↓
SCAN / ENTER MEDICINE
  ↓
VERIFICATION RESULT
  ↓
ADD MEDICATION
  ↓
SET INTAKE SCHEDULE + USER-ENTERED LIMIT
  ↓
LOG INTAKE
  ↓
VIEW HISTORY
  ↓
REACH CONFIGURED LIMIT
  ↓
AWARENESS ALERT
```

---

# 75. AGENT'S FIRST TASK

Before implementing features:

1. Inspect the repository.
2. Determine whether Flutter and backend projects already exist.
3. Create the project structure if missing.
4. Verify installed Flutter/Dart/Node versions.
5. Create the MongoDB Atlas connection configuration.
6. Create `.env.example` files.
7. Initialize the backend.
8. Initialize the Flutter application.
9. Implement the database models.
10. Implement authentication.
11. Implement the medicine verification workflow.
12. Implement medication/intake tracking.
13. Implement the UI.
14. Add tests.
15. Run the complete acceptance-test checklist.
16. Fix all failures.
17. Update documentation.
18. Leave the repository in a buildable, runnable state.

Do not ask the user to implement individual pieces unless an external credential, account permission, or physical device action is genuinely required.

If credentials are required, create the correct configuration placeholders and explain exactly what value the user must provide.

---

# 76. SUCCESS CRITERION

The agent has succeeded when a fresh developer can clone the repository, follow the documented setup instructions, configure MongoDB Atlas environment variables, run the backend, run the Flutter application, register a user, verify demo medicines, add a medication, log intake, receive the configured warning, and inspect the resulting history.

**Build the complete working product, not merely the architecture.**




  
  