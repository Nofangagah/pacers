// service/sendNotification.js
import admin from '../utils/firebase.js'

const sendNotification = async (deviceToken, title, body) => {
  const message = {
    notification: { title, body },
    token: deviceToken,
  };

  try {
    const response = await admin.messaging().send(message);
    console.log('✅ Notifikasi berhasil dikirim:', response);
  } catch (error) {
    console.error('❌ Gagal kirim notifikasi:', error.message);
  }
};

export default sendNotification;