import axios from 'axios';
import path from 'path';
import { getSqliteDb, initSqliteTables, sqliteDbPath } from '../src/database';

// Helper to generate a valid 14-digit GTIN
function generateGtin(seedIndex: number): string {
  const base = (890123000000 + seedIndex).toString().padStart(12, '0');
  const withoutCheck = `0${base}`; // 13 digits
  let sum = 0;
  for (let i = 0; i < withoutCheck.length; i++) {
    let digit = parseInt(withoutCheck[withoutCheck.length - 1 - i], 10);
    if (i % 2 === 0) digit *= 3;
    sum += digit;
  }
  const check = (10 - (sum % 10)) % 10;
  return `${withoutCheck}${check}`;
}

// Build standard GS1 QR payload: (01)GTIN(10)BATCH(17)YYMMDD
function makeQrPayload(gtin: string, batch: string, expiry: Date): string {
  const yy = expiry.getFullYear() % 100;
  const mm = (expiry.getMonth() + 1).toString().padStart(2, '0');
  const dd = expiry.getDate().toString().padStart(2, '0');
  return `(01)${gtin}(10)${batch}(17)${yy}${mm}${dd}`;
}

const DEFAULT_MANUFACTURERS = [
  'Sun Pharmaceutical Industries Ltd',
  'Cipla Ltd',
  'Dr. Reddy\'s Laboratories',
  'Lupin Ltd',
  'Torrent Pharmaceuticals Ltd',
  'Alkem Laboratories Ltd',
  'Abbott India Ltd',
  'Mankind Pharma Ltd',
  'Zydus Lifesciences Ltd'
];

async function importMedicines() {
  console.log('🚀 Starting medicine dataset ingestion from dmedhi/indian-medicines...');
  
  const db = getSqliteDb();
  initSqliteTables(db);

  const insertMed = db.prepare(`
    INSERT OR REPLACE INTO medicines (gtin, name, manufacturer, composition)
    VALUES (@gtin, @name, @manufacturer, @composition);
  `);

  const insertBatch = db.prepare(`
    INSERT INTO batch_records (gtin, batch_number, expiry_date, qr_payload)
    VALUES (@gtin, @batch_number, @expiry_date, @qr_payload);
  `);

  let totalImported = 0;
  const totalBatches = 5; // 500 rows (100 rows per request)
  const now = new Date();

  // Clear existing mock data if desired or keep
  db.exec('DELETE FROM batch_records; DELETE FROM medicines;');

  for (let batchIdx = 0; batchIdx < totalBatches; batchIdx++) {
    const offset = batchIdx * 100;
    const url = `https://datasets-server.huggingface.co/rows?dataset=dmedhi%2Findian-medicines&config=default&split=train&offset=${offset}&length=100`;

    try {
      console.log(`📡 Fetching records offset ${offset} to ${offset + 100}...`);
      const response = await axios.get(url, { timeout: 15000 });
      const rows = response.data?.rows || [];

      if (!rows.length) {
        console.log('No more records returned from HuggingFace dataset server.');
        break;
      }

      const tx = db.transaction(() => {
        for (let i = 0; i < rows.length; i++) {
          const rowData = rows[i]?.row || {};
          const name = (rowData.name || `Medicine ${totalImported + 1}`).trim();
          const composition = (rowData.composition || 'Active Pharmaceutical Ingredient').trim();
          const manufacturer = rowData.manufacturer || DEFAULT_MANUFACTURERS[totalImported % DEFAULT_MANUFACTURERS.length];
          const gtin = generateGtin(totalImported + 1);

          insertMed.run({
            gtin,
            name,
            manufacturer,
            composition,
          });

          // Generate 2 mock batch records with GS1 QR payload
          // Batch 1: Valid future expiry
          const validExpiry = new Date(now.getFullYear() + 2, (now.getMonth() + 6) % 12, 28);
          const batchNo1 = `B${1000 + (totalImported % 9000)}`;
          const payload1 = makeQrPayload(gtin, batchNo1, validExpiry);
          insertBatch.run({
            gtin,
            batch_number: batchNo1,
            expiry_date: validExpiry.toISOString().split('T')[0],
            qr_payload: payload1,
          });

          // Batch 2: Different batch number
          const validExpiry2 = new Date(now.getFullYear() + 1, (now.getMonth() + 3) % 12, 15);
          const batchNo2 = `B${2000 + (totalImported % 8000)}`;
          const payload2 = makeQrPayload(gtin, batchNo2, validExpiry2);
          insertBatch.run({
            gtin,
            batch_number: batchNo2,
            expiry_date: validExpiry2.toISOString().split('T')[0],
            qr_payload: payload2,
          });

          totalImported++;
        }
      });

      tx();
      console.log(`✅ Stored ${rows.length} rows (total: ${totalImported}) into SQLite database`);
    } catch (err: any) {
      console.error(`⚠️ Error fetching batch ${batchIdx}: ${err.message}`);
      break;
    }
  }

  // Add standard demo medicines for easy verification testing
  const demoMedicines = [
    {
      gtin: '08901234567890',
      name: 'Amoxicillin 500mg Trihydrate Capsules',
      manufacturer: 'Sun Pharmaceutical Industries Ltd',
      composition: 'Amoxicillin Trihydrate IP 500mg',
      batch: 'B2045',
      expiry: '2027-12-31'
    },
    {
      gtin: '08909876543210',
      name: 'Azithromycin 500mg Tablets IP',
      manufacturer: 'Cipla Ltd',
      composition: 'Azithromycin Dihydrate IP 500mg',
      batch: 'AZ4091',
      expiry: '2026-11-30'
    },
    {
      gtin: '08905555444433',
      name: 'Paracetamol 650mg Dolo Tablets',
      manufacturer: 'Micro Labs Ltd',
      composition: 'Paracetamol IP 650mg',
      batch: 'DL9912',
      expiry: '2028-06-30'
    }
  ];

  for (const demo of demoMedicines) {
    insertMed.run({
      gtin: demo.gtin,
      name: demo.name,
      manufacturer: demo.manufacturer,
      composition: demo.composition,
    });
    const expDate = new Date(demo.expiry);
    const payload = makeQrPayload(demo.gtin, demo.batch, expDate);
    insertBatch.run({
      gtin: demo.gtin,
      batch_number: demo.batch,
      expiry_date: demo.expiry,
      qr_payload: payload,
    });
  }

  console.log(`🎉 Finished ingestion! Total medicines in SQLite (${sqliteDbPath}): ${totalImported + demoMedicines.length}`);
}

importMedicines().catch((e) => {
  console.error('Fatal error in import script:', e);
  process.exit(1);
});
