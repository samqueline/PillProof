import { connectDatabase, disconnectDatabase } from '../config/database';
import { VerificationService } from '../services/verification.service';

const runSeed = async () => {
  console.log('[Seed] Starting database seed process...');
  await connectDatabase();

  const result = await VerificationService.seedDemoMedicines();
  console.log(`[Seed] Result: ${result.seeded ? 'Seeded ' + result.count + ' medicines' : 'Already seeded with ' + result.count + ' medicines'}.`);

  await disconnectDatabase();
  console.log('[Seed] Finished successfully.');
  process.exit(0);
};

runSeed().catch((error) => {
  console.error('[Seed] Error during seeding:', error);
  process.exit(1);
});
