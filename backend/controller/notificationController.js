import User from '../model/usersModel.js';
import sendNotification from '../service/sendNotification.js';

const sendNotificationToUser = async (req, res) => {
 try {
    const user = await User.findByPk(req.params.id);

    if (!user || !user.device_token) {
      return res.status(404).json({ message: 'User or device token not found' });
    }

    await sendNotification(
      user.device_token,
      'Ayo Olahraga Hari Ini!',
      'Jangan lupa catat aktivitasmu di aplikasi PACER 💪'
    );

    res.json({ message: 'Reminder sent successfully' });
  } catch (err) {
    console.error(err);
    res.status(500).json({ message: 'Failed to send notification' });
  }

}

const sendNotificationToAllUsers = async (req, res) => {
  try {
    const users = await User.findAll({
      where: { device_token: { [Op.ne]: null } }, 
    });

    let success = 0;
    let failed = 0;

    for (const user of users) {
      try {
        await sendNotification(
          user.device_token,
          'Waktunya Olahraga!',
          'Ayo catat aktivitasmu hari ini di PACER 💪'
        );
        success++;
      } catch (err) {
        console.error(`❌ Gagal kirim ke user ${user.id}`, err);
        failed++;
      }
    }

    res.json({
      message: `Notifikasi terkirim`,
      success,
      failed,
    });
  } catch (err) {
    res.status(500).json({ message: 'Gagal kirim notifikasi massal', error: err.message });
  }
};

export { sendNotificationToAllUsers, sendNotificationToUser} 