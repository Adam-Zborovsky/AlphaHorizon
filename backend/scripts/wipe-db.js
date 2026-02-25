const mongoose = require('mongoose');
const env = require('../src/config/env');

async function wipeDatabase() {
  try {
    console.log('--- ALPHA HORIZON DATA WIPE INITIATED ---');
    console.log(`Connecting to: ${env.MONGODB_URI}`);
    
    await mongoose.connect(env.MONGODB_URI);
    console.log('Connected to MongoDB.');

    const collections = await mongoose.connection.db.collections();
    
    for (let collection of collections) {
      console.log(`Clearing collection: ${collection.collectionName}`);
      await collection.deleteMany({});
    }

    console.log('--- ALL COLLECTIONS PURGED SUCCESSFULLY ---');
    process.exit(0);
  } catch (err) {
    console.error('Error during data wipe:', err);
    process.exit(1);
  }
}

wipeDatabase();
