import Express from 'express';
import {editProfile, deviceTokenUpdate} from '../controller/userController.js';

import authMiddleware from '../middleware/authMiddleware.js';
const router = Express.Router();

// PUT: Edit user profile
router.patch('/editProfile/:id', authMiddleware, editProfile);
router.patch('/deviceTokenUpdate/:id', authMiddleware, deviceTokenUpdate);


export default router;