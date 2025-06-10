import cron from 'node-cron';
import sendNotification from '../service/sendNotification.js';
import User from '../model/usersModel.js';
import { Op } from 'sequelize';


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
  // Notifikasi jam 7 pagi
  cron.schedule(
    '0 7 * * *',
    () => {
      sendReminders(
        'Selamat Pagi!',
        'Waktunya memulai hari dengan aktif! Jangan lupa catat aktivitasmu di PACER hari ini.'
      );
    },
    {
      timezone: 'Asia/Jakarta',
    }
  );

  // Notifikasi jam 4 sore
  cron.schedule(
    '0 16 * * *',
    () => {
      sendReminders(
        'Selamat Sore!',
        'Bagaimana aktivitasmu hari ini? Jangan lupa catat di PACER ya!'
      );
    },
    {
      timezone: 'Asia/Jakarta',
    }
  );
};

export default scheduleDailyReminder;