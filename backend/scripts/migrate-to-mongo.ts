import Database from 'better-sqlite3';
import path from 'path';
import mongoose from 'mongoose';
import dotenv from 'dotenv';
import { Medicine } from '../src/models/medicine.model';
import { BatchRecord } from '../src/models/batchRecord';

dotenv.config();

const sqlitePath = path.resolve(__dirname, '../../medicines.db');

async function migrate() {
  const uri = process.env.MONGO_URI;
  if (!uri) {
    console.error('❌ Error: MONGO_URI is not set in backend/.env');
    console.error('👉 Please check backend/.env and provide your MongoDB connection string.');
    process.exit(1);
  }

  console.log('📡 Connecting to MongoDB Cloud...');
  await mongoose.connect(uri);
  console.log('✅ Connected to MongoDB Cloud');

  const db = new Database(sqlitePath);

  // 1. Fetch medicines from SQLite
  const meds = db.prepare('SELECT gtin, name, manufacturer, composition FROM medicines').all() as any[];
  const batches = db.prepare('SELECT gtin, batch_number, expiry_date, qr_payload FROM batch_records').all() as any[];

  console.log(`📦 Found ${meds.length} medicines and ${batches.length} batch records in SQLite`);

  // Index batches by gtin for quick lookup
  const batchesByGtin = new Map<string, any[]>();
  for (const b of batches) {
    const list = batchesByGtin.get(b.gtin) || [];
    list.push(b);
    batchesByGtin.set(b.gtin, list);
  }

  // 2. Prepare Medicine docs for MongoDB
  const medicineDocs = [];
  for (const m of meds) {
    const medBatches = batchesByGtin.get(m.gtin) || [];
    const firstBatch = medBatches[0];
    const expDate = firstBatch?.expiry_date ? new Date(firstBatch.expiry_date) : new Date(Date.now() + 365 * 24 * 3600 * 1000);

    medicineDocs.push({
      name: m.name,
      genericName: m.composition || m.name,
      manufacturer: m.manufacturer || 'Standard Pharma',
      batchNumber: firstBatch?.batch_number || 'B1001',
      barcode: m.gtin,
      expiryDate: expDate,
      strength: '500mg',
      dosageForm: m.name.toLowerCase().includes('syrup') ? 'syrup' : m.name.toLowerCase().includes('injection') ? 'injection' : 'tablet',
      status: 'verified',
      source: 'dmedhi/indian-medicines'
    });
  }

  // 3. Insert or update in MongoDB (batch chunking for reliability)
  const chunkSize = 250;
  for (let i = 0; i < medicineDocs.length; i += chunkSize) {
    const chunk = medicineDocs.slice(i, i + chunkSize);
    await Medicine.bulkWrite(
      chunk.map((doc) => ({
        updateOne: {
          filter: { barcode: doc.barcode },
          update: { $set: doc },
          upsert: true,
        },
      }))
    );
  }
  console.log(`✅ Uploaded/Synced ${medicineDocs.length} medicines into MongoDB 'medicines' collection!`);

  // 4. Migrate BatchRecord documents
  const batchDocs = batches.map((b) => ({
    gtin: b.gtin,
    batchNumber: b.batch_number,
    expiryDate: b.expiry_date,
    qrPayload: b.qr_payload,
  }));

  for (let i = 0; i < batchDocs.length; i += chunkSize) {
    const chunk = batchDocs.slice(i, i + chunkSize);
    await BatchRecord.bulkWrite(
      chunk.map((doc) => ({
        updateOne: {
          filter: { gtin: doc.gtin, batchNumber: doc.batchNumber },
          update: { $set: doc },
          upsert: true,
        },
      }))
    );
  }
  console.log(`✅ Uploaded/Synced ${batchDocs.length} batch records into MongoDB 'batchrecords' collection!`);

  db.close();
  await mongoose.disconnect();
  console.log('🎉 MongoDB Cloud migration completed successfully!');
}

migrate().catch((err) => {
  console.error('❌ Migration failed:', err);
  process.exit(1);
});
