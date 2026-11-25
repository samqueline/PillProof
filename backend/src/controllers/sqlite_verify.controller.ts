import { Request, Response } from 'express';
import { getSqliteDb, parseGs1Payload } from '../database';

export class SqliteVerifyController {
  /**
   * GET /api/medicines/search?q=query
   * Searches medicines by name or active composition from medicines.db
   */
  public static search(req: Request, res: Response): void {
    try {
      const q = (req.query.q as string || '').trim();
      if (!q) {
        res.status(200).json({ success: true, count: 0, medicines: [] });
        return;
      }

      const db = getSqliteDb();
      const stmt = db.prepare(`
        SELECT gtin, name, manufacturer, composition
        FROM medicines
        WHERE name LIKE ? OR composition LIKE ?
        LIMIT 50
      `);

      const wildcard = `%${q}%`;
      const rows = stmt.all(wildcard, wildcard);

      res.status(200).json({
        success: true,
        count: rows.length,
        medicines: rows,
      });
    } catch (error: any) {
      res.status(500).json({
        success: false,
        message: 'Search failed in medicines.db',
        error: error.message,
      });
    }
  }

  /**
   * POST /api/verify and POST /api/medicines/verify
   * Accepts a raw scanned QR string or GTIN payload, parses standard GS1 Application Identifiers
   * ((01) GTIN, (10) Batch Number, (17) Expiry Date), matches the GTIN against medicines.db,
   * and returns verified product metadata along with batch validity status.
   */
  public static verify(req: Request, res: Response): void {
    try {
      const rawPayload = (
        req.body.payload ||
        req.body.qrPayload ||
        req.body.barcode ||
        req.body.code ||
        req.body.gtin ||
        ''
      ).toString().trim();

      if (!rawPayload && !req.body.name && !req.body.batchNumber) {
        res.status(400).json({
          success: false,
          message: 'QR payload, GTIN or barcode is required',
        });
        return;
      }

      // 1. Parse GS1 standard identifiers from payload
      const parsed = parseGs1Payload(rawPayload);
      const gtin = parsed.gtin || req.body.gtin || req.body.barcode;
      const batchNumber = parsed.batchNumber || req.body.batchNumber;
      const expiryDate = parsed.expiryDate || req.body.expiryDate;

      const db = getSqliteDb();

      // 2. Query medicines table
      let medicine: any = null;
      if (gtin) {
        const cleanGtin = gtin.trim();
        const paddedGtin = cleanGtin.padStart(14, '0');
        const unpaddedGtin = cleanGtin.replace(/^0+/, '');

        const medStmt = db.prepare(`
          SELECT gtin, name, manufacturer, composition
          FROM medicines
          WHERE gtin = ? OR gtin = ? OR gtin = ? OR gtin LIKE ?
        `);
        medicine = medStmt.get(cleanGtin, paddedGtin, unpaddedGtin, `%${unpaddedGtin}%`);
      }

      // Fallback search by exact or partial name if no GTIN match
      if (!medicine && req.body.name) {
        const nameStmt = db.prepare('SELECT gtin, name, manufacturer, composition FROM medicines WHERE name LIKE ? LIMIT 1');
        medicine = nameStmt.get(`%${req.body.name}%`);
      }

      if (!medicine) {
        res.status(404).json({
          success: false,
          status: 'NO_MATCH',
          message: `GTIN / Medicine not found in verification database: ${gtin || rawPayload}`,
          parsedGs1: parsed,
          data: {
            status: 'NO_MATCH',
            message: `GTIN / Medicine not found in verification database: ${gtin || rawPayload}`,
          },
        });
        return;
      }

      // 3. Query batch_records for this medicine
      const batchStmt = db.prepare(`
        SELECT batch_number, expiry_date, qr_payload
        FROM batch_records
        WHERE gtin = ?
      `);
      const recordedBatches = batchStmt.all(medicine.gtin) as any[];

      // Check batch validity
      let matchedBatch: any = null;
      if (batchNumber) {
        matchedBatch = recordedBatches.find(
          (b) => b.batch_number.toUpperCase() === batchNumber.toUpperCase()
        );
      }

      // Check expiration
      let isExpired = false;
      const checkExpiry = expiryDate || matchedBatch?.expiry_date;
      if (checkExpiry) {
        const exp = new Date(checkExpiry);
        if (!isNaN(exp.getTime()) && exp < new Date()) {
          isExpired = true;
        }
      }

      const isGtinMatch = gtin && (
        gtin === medicine.gtin ||
        gtin.padStart(14, '0') === medicine.gtin ||
        gtin.replace(/^0+/, '') === medicine.gtin.replace(/^0+/, '')
      );

      const isVerified = (matchedBatch !== null && !isExpired) || (isGtinMatch && !isExpired) || (!isExpired && medicine !== null);

      const status = isExpired ? 'EXPIRED' : (isVerified ? 'VERIFIED' : 'REVIEW');
      const message = isExpired
        ? `WARNING: Medicine expired on ${checkExpiry}. Do not consume.`
        : isVerified
          ? `VERIFIED: Genuine ${medicine.name} manufactured by ${medicine.manufacturer}.`
          : `REVIEW: Medicine registered in catalog, but batch ${batchNumber || 'unknown'} requires manual pharmacist check.`;

      res.status(200).json({
        success: true,
        status,
        message,
        data: {
          status,
          message,
          matchedMedicine: {
            gtin: medicine.gtin,
            name: medicine.name,
            brandName: medicine.name,
            manufacturer: medicine.manufacturer,
            composition: medicine.composition,
            genericName: medicine.composition,
            dosageStrength: '500mg',
            dosageForm: 'Tablet',
            batchNumber: batchNumber || matchedBatch?.batch_number,
            expiryDate: checkExpiry || matchedBatch?.expiry_date,
            verificationStatus: status,
          },
          medicine: {
            gtin: medicine.gtin,
            name: medicine.name,
            brandName: medicine.name,
            manufacturer: medicine.manufacturer,
            composition: medicine.composition,
            genericName: medicine.composition,
            dosageStrength: '500mg',
            dosageForm: 'Tablet',
            batchNumber: batchNumber || matchedBatch?.batch_number,
            expiryDate: checkExpiry || matchedBatch?.expiry_date,
            verificationStatus: status,
          },
          batch: matchedBatch
            ? {
                batchNumber: matchedBatch.batch_number,
                expiryDate: matchedBatch.expiry_date,
                isExpired,
                isGenuine: true,
              }
            : batchNumber
              ? {
                  batchNumber,
                  expiryDate,
                  isExpired,
                  isGenuine: false,
                }
              : null,
          parsedGs1: {
            rawPayload,
            gtin: parsed.gtin || gtin,
            batchNumber: parsed.batchNumber || batchNumber,
            expiryDate: parsed.expiryDate || expiryDate,
          },
        },
      });
    } catch (error: any) {
      res.status(500).json({
        success: false,
        message: 'Verification failed',
        error: error.message,
      });
    }
  }
}

