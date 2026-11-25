# Pill Proof Backend

REST API backend for the Pill Proof medicine verification and medication tracking mobile application.

## Tech Stack
- **Runtime:** Node.js (v20+ / LTS)
- **Language:** TypeScript
- **Framework:** Express.js
- **Database:** MongoDB Atlas (via Mongoose)
- **Validation:** Zod
- **Testing:** Jest + Supertest

## Directory Structure
```
backend/
├── src/
│   ├── config/          # Environment and database configuration
│   ├── controllers/     # Request controllers
│   ├── middleware/      # Auth (JWT) and error handling middleware
│   ├── models/          # Mongoose data models
│   ├── repositories/    # Data access layer
│   ├── routes/          # Express route definitions
│   ├── services/        # Business logic (verification engine, intake engine)
│   ├── utils/           # Utility helpers
│   ├── validators/      # Zod request schemas
│   ├── app.ts           # Express app setup
│   └── server.ts        # Server entry point
├── tests/               # Integration and unit tests
├── .env.example         # Environment template
├── package.json
└── tsconfig.json
```

## Setup & Running
1. Install dependencies:
   ```bash
   npm install
   ```
2. Copy `.env.example` to `.env`:
   ```bash
   cp .env.example .env
   ```
3. Set your MongoDB Atlas connection string in `.env`.
4. Run in development mode:
   ```bash
   npm run dev
   ```
5. Run tests:
   ```bash
   npm test
   ```
6. Build for production:
   ```bash
   npm run build
   npm start
   ```
