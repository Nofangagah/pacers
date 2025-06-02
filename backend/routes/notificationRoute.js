import Express from 'express';
import   { sendNotificationToUser, sendNotificationToAllUsers}  from '../controller/notificationController.js';
import authMiddleware from '../middleware/authMiddleware.js';
const router = Express.Router();

router.post('/sendNotification/:id', authMiddleware, sendNotificationToUser);
router.post('/sendNotificationToAll', authMiddleware, sendNotificationToAllUsers);

export default router;