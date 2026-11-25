# Pill Proof — Hackathon Demo & Testing Guide

> **Event:** ENVISION '26  
> **Team:** TechNitro  
> **Goal:** Fast, reliable demonstration of medicine verification and medication intake monitoring.

---

## 🚀 Quick Setup (2 Minutes)

1. **Backend:**
   ```bash
   cd backend
   npm run dev
   # Verify at: http://localhost:5000/api/health
   ```
2. **Frontend:**
   ```bash
   cd frontend
   flutter run -d chrome --web-port 3000
   # Open in browser: http://localhost:3000
   ```

---

## 🧪 Demonstration Scenarios

### Scenario 1: User Registration & Onboarding
1. Open [http://localhost:3000](http://localhost:3000).
2. Tap **"Sign Up"** on the login screen.
3. Enter:
   - **Name:** `Dr. Alex Morgan`
   - **Email:** `demo@pillproof.com`
   - **Password:** `Password123!`
4. Tap **"Create Account"**.
5. You are redirected to the Dashboard with your personalized greeting.

---

### Scenario 2: Medicine Verification (Levels 1, 2, 3 & Expiry)

Tap **"Verify Medicine"** on the Dashboard:

#### A. Level 1: Verified Barcode Match
- **Click demo button:** `Amoxicillin`
- Barcode `8901234567890` is pre-filled.
- Tap **"Verify Medicine"**.
- **Expected:** Green **MATCH FOUND / VERIFIED** banner, displaying GSK Pharmaceuticals, batch AMX-2026-X1, expiry 2027.

#### B. Expiry Safety Test
- **Click demo button:** `Expired Ibuprofen`
- Pre-fills barcode `8901234567895`.
- Tap **"Verify Medicine"**.
- **Expected:** Red **EXPIRED** alert warning: *"The entered expiration date has passed. Do not consume expired medicine."*

#### C. Review Recommended
- **Click demo button:** `Atorvastatin`
- Pre-fills barcode `8901234567896`.
- Tap **"Verify Medicine"**.
- **Expected:** Amber **REVIEW REQUIRED** notice advising caution.

#### D. No Match Found
- Enter an unregistered barcode, e.g. `9999999999999`.
- Tap **"Verify Medicine"**.
- **Expected:** Blue **NO MATCH FOUND** badge: *"No matching verified record was found."*

---

### Scenario 3: Medication Intake & Limit Engine

From the Dashboard:

1. Tap **"Add Medication"**.
2. Enter:
   - **Medicine Name:** `Paracetamol 650mg`
   - **Dosage:** `1 tablet`
   - **Daily Prescribed Limit:** `2`
   - **Times:** `08:00, 20:00`
3. Tap **"Save Medication"**.
4. The medication card appears under **"Today's Schedule"** showing `0 / 2 doses recorded`.

#### Testing the Limit Thresholds:
* **Log Dose 1:** Tap **"Take Dose"** (or **"Log Intake"**).
  * Status: **Within Limit** (`1 / 2`).
* **Log Dose 2:** Tap **"Take Dose"**.
  * Status: **Limit Reached** (`2 / 2`).
  * Banner turns Amber with Awareness Notice: *"Configured intake limit has been reached."*
* **Log Dose 3:** Tap **"Take Dose"**.
  * Status: **Limit Exceeded** (`3 / 2`).
  * Banner turns Red with Alert: *"Daily recorded intake exceeds your configured prescribed limit."*

---

### Scenario 4: Intake & Verification History
1. Tap the **History** icon in the Dashboard top bar.
2. View chronological intake timestamps, recorded quantities, and limit statuses.
