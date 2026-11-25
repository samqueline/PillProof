# Pill Proof REST API Documentation

Base URL: `http://localhost:5000/api` (also compatible with `/api/v1`)

---

## 1. System & Health

### `GET /health`
Returns system status, service name, and database connection state.

- **Authentication:** None
- **Response (200 OK):**
```json
{
  "success": true,
  "message": "Pill Proof API is operational",
  "timestamp": "2026-10-28T06:36:24.620Z",
  "service": "pill-proof-backend",
  "database": "connected"
}
```

---

## 2. Authentication API

### `POST /auth/register`
Creates a new user account, securely hashes passwords using bcrypt salt rounds, and issues a JWT token.

- **Authentication:** None
- **Request Body:**
```json
{
  "name": "Jane Doe",
  "email": "jane@example.com",
  "password": "Password123!"
}
```
- **Response (201 Created):**
```json
{
  "success": true,
  "message": "User registered successfully",
  "token": "eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9...",
  "user": {
    "id": "6724b1c8a149b5c2194b912a",
    "name": "Jane Doe",
    "email": "jane@example.com",
    "role": "user",
    "createdAt": "2026-10-28T06:40:00.000Z"
  }
}
```

### `POST /auth/login`
Authenticates credentials and returns a signed JWT token.

- **Authentication:** None
- **Request Body:**
```json
{
  "email": "jane@example.com",
  "password": "Password123!"
}
```
- **Response (200 OK):**
```json
{
  "success": true,
  "message": "Login successful",
  "token": "eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9...",
  "user": {
    "id": "6724b1c8a149b5c2194b912a",
    "name": "Jane Doe",
    "email": "jane@example.com",
    "role": "user"
  }
}
```

### `GET /auth/me`
Retrieves authenticated user profile.

- **Authentication:** Bearer JWT required
- **Response (200 OK):**
```json
{
  "success": true,
  "user": {
    "id": "6724b1c8a149b5c2194b912a",
    "name": "Jane Doe",
    "email": "jane@example.com",
    "role": "user"
  }
}
```

---

## 3. Medicine & Verification API

### `POST /medicines/verify`
Deterministic medicine verification engine executing Level 1, Level 2, Level 3 partial matching, and authoritative expiry verification.

- **Authentication:** Optional (authenticated userId stored in audit log if provided)
- **Request Body:**
```json
{
  "barcode": "8901234567890",
  "name": "Amoxicillin 500mg",
  "batchNumber": "AMX-2026-X1",
  "manufacturer": "GSK Pharmaceuticals",
  "expiryDate": "2027-12-31"
}
```
- **Response (200 OK - VERIFIED):**
```json
{
  "success": true,
  "data": {
    "status": "VERIFIED",
    "message": "Medicine details match a verified Pill Proof record.",
    "matchedMedicine": {
      "_id": "6724b1c8a149b5c2194b912b",
      "name": "Amoxicillin 500mg",
      "genericName": "Amoxicillin Trihydrate",
      "manufacturer": "GSK Pharmaceuticals",
      "batchNumber": "AMX-2026-X1",
      "barcode": "8901234567890",
      "expiryDate": "2027-12-31T00:00:00.000Z",
      "strength": "500 mg",
      "dosageForm": "Capsule",
      "status": "verified"
    },
    "logId": "6724b1c8a149b5c2194b912c"
  }
}
```
- **Response (200 OK - EXPIRED):**
```json
{
  "success": true,
  "data": {
    "status": "EXPIRED",
    "message": "Medicine expired on 2024-01-01. Do not consume expired medication."
  }
}
```
- **Response (200 OK - NO_MATCH):**
```json
{
  "success": true,
  "data": {
    "status": "NO_MATCH",
    "message": "No matching verified record was found."
  }
}
```

### `GET /medicines/search?q={query}`
Searches verified medicines catalog by name, generic name, barcode, or batch number.

- **Authentication:** None
- **Response (200 OK):**
```json
{
  "success": true,
  "count": 1,
  "medicines": [...]
}
```

### `GET /medicines`
Lists up to 100 verified medicine records.

### `POST /medicines/seed`
Seeds demo medicine catalog if database is unseeded.

### `GET /verification/history`
Retrieves audit logs of past medicine verification queries performed by the user.

- **Authentication:** Bearer JWT required
- **Response (200 OK):**
```json
{
  "success": true,
  "count": 2,
  "history": [...]
}
```

---

## 4. Medication Management API

### `POST /medications`
Registers a prescribed medication schedule with user-defined intake limits.

- **Authentication:** Bearer JWT required
- **Request Body:**
```json
{
  "medicineName": "Amoxicillin 500mg",
  "dosage": "1 capsule",
  "frequency": "Three times daily",
  "times": ["08:00", "14:00", "20:00"],
  "prescribedLimit": 3,
  "startDate": "2026-10-28",
  "notes": "Take after meals"
}
```
- **Response (201 Created):**
```json
{
  "success": true,
  "message": "Medication created successfully",
  "medication": {
    "_id": "6724b1c8a149b5c2194b912d",
    "medicineName": "Amoxicillin 500mg",
    "prescribedLimit": 3,
    "active": true
  }
}
```

### `GET /medications`
Retrieves active user medications.

### `GET /medications/:id`
Retrieves single medication details.

### `PATCH /medications/:id`
Updates medication schedule, dosage, or limit.

### `DELETE /medications/:id`
Deactivates medication schedule.

---

## 5. Intake Tracking & Limit Engine API

### `POST /medications/:id/intake`
Logs an intake dose and calculates daily consumption against the user-configured prescribed limit.

- **Authentication:** Bearer JWT required
- **Request Body:**
```json
{
  "quantity": 1,
  "source": "manual",
  "takenAt": "2026-10-28T07:30:00.000Z"
}
```
- **Response (201 Created - WITHIN_LIMIT):**
```json
{
  "success": true,
  "data": {
    "status": "WITHIN_LIMIT",
    "dailyIntake": 1,
    "prescribedLimit": 3,
    "message": "Intake recorded within your prescribed limit.",
    "intakeEvent": { ... }
  }
}
```
- **Response (201 Created - LIMIT_REACHED):**
```json
{
  "success": true,
  "data": {
    "status": "LIMIT_REACHED",
    "dailyIntake": 3,
    "prescribedLimit": 3,
    "message": "Awareness Notice: Daily recorded intake has reached your configured prescribed limit."
  }
}
```
- **Response (201 Created - LIMIT_EXCEEDED):**
```json
{
  "success": true,
  "data": {
    "status": "LIMIT_EXCEEDED",
    "dailyIntake": 4,
    "prescribedLimit": 3,
    "message": "Awareness Alert: Daily recorded intake exceeds your configured prescribed limit."
  }
}
```

### `GET /intake/today`
Returns daily intake counts and statuses for all active medications.

### `GET /intake/history`
Returns chronological intake event log. Filterable with `?limit=50&medicationId=...`.
