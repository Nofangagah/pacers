import cron from 'node-cron';
import sendNotification from '../service/sendNotification.js';
import User from '../model/usersModel.js';
import { Op } from 'sequelize';

// Fungsi umum untuk kirim notifikasi
const sendReminders = async (title, message) => {
  console.log(`🚀 Mengirim notifikasi: ${title}`);

  try {
    const users = await User.findAll({
      where: {
        device_token: { [Op.ne]: null },
      },
    });

    for (const user of users) {
      try {
        await sendNotification(user.device_token, title, message);
        console.log(`✅ Notifikasi terkirim ke user ID: ${user.id}`);
      } catch (notifErr) {
        console.error(`❌ Gagal kirim ke user ${user.id}: ${notifErr.message}`);
      }
    }
  } catch (err) {
    console.error('❌ Gagal mengambil daftar user:', err.message);
  }
};

const scheduleDailyReminder = () => {
  cron.schedule(
  '*/1 * * * *', 
  () => {
    sendReminders(
      'Notifikasi rutin tiap 1 menit',
      'Ingat untuk tetap aktif dan catat aktivitasmu di PACER!'
    );
  },
  {
    timezone: 'Asia/Jakarta',
  }
);
};

export default scheduleDailyReminder;
