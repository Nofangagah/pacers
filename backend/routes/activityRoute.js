import Express from 'express';
import { getAllActivities, getUserActivities, saveActivity, getActivityById, deleteActivity } from '../controller/activityController.js';
import  authMiddleware  from '../middleware/authMiddleware.js';
const router = Express.Router();

// GET all activities
router.get('/', authMiddleware, getAllActivities);
// GET user-specific activities
router.get('/user/:id', authMiddleware, getUserActivities);
// POST: Save new activity
router.post('/saveActivity', authMiddleware, saveActivity);
// GET single activity by ID
router.get('/:id', authMiddleware, getActivityById);

router.delete('/:id', authMiddleware, deleteActivity);


export default router;