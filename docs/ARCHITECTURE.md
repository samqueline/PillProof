# Pill Proof - System Architecture

## Overview
Pill Proof is a mobile-first medicine verification and medication tracking application designed to enhance safety and awareness around pharmaceuticals.

## Architecture Diagram

```
+---------------------------------------------------------------+
|                      Flutter Mobile App                       |
|               (Riverpod + GoRouter + Material 3)              |
+-------------------------------+-------------------------------+
                                |
                                | REST API (JSON / HTTPS)
                                v
+---------------------------------------------------------------+
|                     Node.js / Express API                     |
|            (TypeScript + JWT Auth + Zod Validation)           |
+---------------+-------------------------------+---------------+
                |                               |
                v                               v
+-------------------------------+ +-----------------------------+
|         MongoDB Atlas         | |     Verification Engine     |
| (Users, Medicines,            | | (Batch check, expiry check, |
|  Medications, Intake Events)  | |  limit ceiling monitoring)  |
+-------------------------------+ +-----------------------------+
```

## Layers & Structure

### 1. Frontend (`frontend/`)
- **State Management:** Riverpod (`ProviderScope`, `ConsumerWidget`)
- **Navigation:** `go_router` with declarative routes and auth redirects
- **Design System:** Material 3 with Google Fonts (Inter) and custom medical color palette
- **Networking:** Centralized `ApiClient` backed by `dio` with JWT auth interceptors
- **Secure Storage:** `flutter_secure_storage` for token and session persistence

```
frontend/lib/
├── app/                 # Root widget, GoRouter navigation, Material 3 theme
├── core/                # Constants, network client, secure storage, reusable widgets
├── features/            # Feature modules (auth, dashboard, verification, medications, history)
└── shared/              # Cross-feature models, status badges, and utility extensions
```

### 2. Backend (`backend/`)
- **Runtime:** Node.js (v24 LTS)
- **Framework:** Express.js with TypeScript
- **Database Driver:** Mongoose (MongoDB Atlas)
- **Validation:** Zod schemas for input validation
- **Testing:** Jest + Supertest

```
backend/src/
├── config/              # Environment config and MongoDB Atlas connection
├── controllers/         # Request handling logic
├── middleware/          # JWT authentication and centralized error handling
├── models/              # Mongoose data schemas
├── repositories/        # Database access layer
├── routes/              # Modular Express routing
├── services/            # Verification engine and intake limit rules
├── utils/               # Helper utilities
└── validators/          # Zod validation schemas
```

## Security Best Practices
- **No Hardcoded Secrets:** Credentials, MongoDB connection strings, and JWT secrets are stored exclusively in `.env` files (excluded by `.gitignore`).
- **Authentication:** Stateless JSON Web Tokens (JWT) transmitted via `Authorization: Bearer <token>` headers.
- **Client Storage:** Sensitive authentication tokens are stored in platform keystore/keychain via `flutter_secure_storage`.
