import admin from 'firebase-admin';
import { readFile } from 'fs/promises';
import { fileURLToPath } from 'url';
import { dirname, resolve } from 'path';

// Path ke file JSON (otomatis absolute)
const __filename = fileURLToPath(import.meta.url);
const __dirname = dirname(__filename);
const jsonPath = resolve(__dirname, '../pacer.json');

// Baca file JSON secara manual
const jsonString = await readFile(jsonPath, 'utf-8');
const serviceAccount = JSON.parse(jsonString);

// Inisialisasi Firebase Admin SDK
admin.initializeApp({
  credential: admin.credential.cert(serviceAccount),
});

export default admin;
