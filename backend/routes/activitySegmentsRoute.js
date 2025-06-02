import Express from 'express';
import { getSegmentsByUserId } from '../controller/activitySegmentsController.js';
import  authMiddleware  from '../middleware/authMiddleware.js';
const router = Express.Router();

router.get('/segment/user/:userId', authMiddleware, getSegmentsByUserId);

export default router;