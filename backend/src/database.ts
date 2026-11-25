import Database from 'better-sqlite3';
import path from 'path';

// Store medicines.db in backend folder
export const sqliteDbPath = path.resolve(__dirname, '../../medicines.db');

let _db: Database.Database | null = null;

export function getSqliteDb(): Database.Database {
  if (!_db) {
    _db = new Database(sqliteDbPath);
    initSqliteTables(_db);
  }
  return _db;
}

export function initSqliteTables(dbInstance?: Database.Database): void {
  const db = dbInstance || getSqliteDb();
  db.exec(`
    CREATE TABLE IF NOT EXISTS medicines (
      gtin TEXT PRIMARY KEY,
      name TEXT NOT NULL,
      manufacturer TEXT,
      composition TEXT
    );

    CREATE TABLE IF NOT EXISTS batch_records (
      id INTEGER PRIMARY KEY AUTOINCREMENT,
      gtin TEXT NOT NULL,
      batch_number TEXT,
      expiry_date TEXT,
      qr_payload TEXT,
      FOREIGN KEY (gtin) REFERENCES medicines(gtin)
    );
  `);
}

/**
 * Intelligent GS1 QR payload parser
 * Parses standard GS1 Application Identifiers:
 * (01) GTIN - 14 digits
 * (10) Batch Number - variable
 * (17) Expiry Date - YYMMDD
 */
export function parseGs1Payload(raw: string): {
  gtin?: string;
  batchNumber?: string;
  expiryDate?: string; // YYYY-MM-DD
} {
  const trimmed = raw.trim();
  let gtin: string | undefined;
  let batchNumber: string | undefined;
  let expiryDate: string | undefined;

  // 1. Try standard (01) ... (10) ... (17) regex
  const gtinMatch = trimmed.match(/\(01\)(\d{14})/);
  if (gtinMatch) {
    gtin = gtinMatch[1];
  }

  const batchMatch = trimmed.match(/\(10\)([^()]+)/);
  if (batchMatch) {
    batchNumber = batchMatch[1].trim();
  }

  const expMatch = trimmed.match(/\(17\)(\d{6})/);
  if (expMatch) {
    const rawExp = expMatch[1];
    const yy = parseInt(rawExp.substring(0, 2), 10);
    const mm = rawExp.substring(2, 4);
    let dd = rawExp.substring(4, 6);
    if (dd === '00') dd = '28';
    const year = yy < 70 ? 2000 + yy : 1900 + yy;
    expiryDate = `${year}-${mm}-${dd}`;
  }

  // 2. Try raw FNC1 / barcode format without parentheses if needed
  if (!gtin && trimmed.startsWith('01') && trimmed.length >= 16) {
    gtin = trimmed.substring(2, 16);
    let rest = trimmed.substring(16);
    if (rest.startsWith('10')) {
      const next17 = rest.indexOf('17');
      if (next17 !== -1) {
        batchNumber = rest.substring(2, next17);
        rest = rest.substring(next17);
      } else {
        batchNumber = rest.substring(2);
        rest = '';
      }
    }
    if (rest.startsWith('17') && rest.length >= 8) {
      const rawExp = rest.substring(2, 8);
      const yy = parseInt(rawExp.substring(0, 2), 10);
      const mm = rawExp.substring(2, 4);
      let dd = rawExp.substring(4, 6);
      if (dd === '00') dd = '28';
      const year = yy < 70 ? 2000 + yy : 1900 + yy;
      expiryDate = `${year}-${mm}-${dd}`;
    }
  }

  // 3. Fallback: if raw string is just 14 digits or GTIN
  if (!gtin && /^\d{12,14}$/.test(trimmed)) {
    gtin = trimmed.padStart(14, '0');
  }

  return { gtin, batchNumber, expiryDate };
}

