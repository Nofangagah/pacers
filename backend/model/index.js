import User from './usersModel.js';
import Activity from './activityModel.js';
import ActivitySegment from './activitySegmentModel.js';
import db from '../config/database.js';


// User <-> Activity
User.hasMany(Activity, { foreignKey: 'userId', onDelete: 'CASCADE' });
Activity.belongsTo(User, { foreignKey: 'userId' });

// Activity <-> ActivitySegment
Activity.hasMany(ActivitySegment, { foreignKey: 'activityId', onDelete: 'CASCADE' });
ActivitySegment.belongsTo(Activity, { foreignKey: 'activityId' });

export {
  db,
  User,
  Activity,
  ActivitySegment
}