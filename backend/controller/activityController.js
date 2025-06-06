import Activity from '../model/activityModel.js';
import ActivitySegment from '../model/activitySegmentModel.js';
import Users from '../model/usersModel.js';

// GET all activities (with user and segments)
const getAllActivities = async (req, res) => {
    try {
        const activities = await Activity.findAll({
            include: [
                {
                    model: Users,
                    attributes: ['name', 'email'],
                },
                {
                    model: ActivitySegment,
                    attributes: ['segment_number', 'distance', 'duration', 'pace'],
                    order: [['segment_number', 'ASC']],
                }
            ]
        });

        const parsedActivities = activities.map(activity => {
            const act = activity.toJSON();
            return {
                ...act,
                path: act.path ? JSON.parse(act.path) : [],
            };
        });

        res.status(200).json(parsedActivities);
    } catch (error) {
        res.status(500).json({ message: 'Error fetching activities', error: error.message });
    }
};

// GET activities for a specific user
const getUserActivities = async (req, res) => {
    const userId = req.params.id;
    try {
        const activities = await Activity.findAll({
            where: { userId },
            include: [
                {
                    model: Users,
                    attributes: ['name', 'email'],
                },
                {
                    model: ActivitySegment,
                    attributes: ['segment_number', 'distance', 'duration', 'pace'],
                    order: [['segment_number', 'ASC']],
                }
            ],
        });

        if (activities.length === 0) {
            return res.status(200).json([]);
        }

        const parsedActivities = activities.map(activity => {
            const act = activity.toJSON();
            return {
                ...act,
                path: act.path ? JSON.parse(act.path) : [],
            };
        });

        res.status(200).json(parsedActivities);
    } catch (error) {
        res.status(500).json({ message: 'Error fetching user activities', error: error.message });
    }
};

// GET single activity by ID
const getActivityById = async (req, res) => {
    const activityId = req.params.id;
    try {
        const activity = await Activity.findByPk(activityId, {
            include: [
                {
                    model: Users,
                    attributes: ['name', 'email'],
                },
                {
                    model: ActivitySegment,
                    attributes: ['segment_number', 'distance', 'duration', 'pace'],
                    order: [['segment_number', 'ASC']],
                }
            ],
        });

        if (!activity) {
            return res.status(404).json({ message: 'Activity not found' });
        }

        const parsedActivity = {
            ...activity.toJSON(),
            path: activity.path ? JSON.parse(activity.path) : [],
        };

        res.status(200).json(parsedActivity);
    } catch (error) {
        res.status(500).json({ message: 'Error fetching activity', error: error.message });
    }
};

// POST new activity with optional segments
// POST new activity with auto segment per 1km
const saveActivity = async (req, res) => {
    const { title, type, duration, date, userId, distance, caloriesBurned, path, avr_pace, steps } = req.body;

    try {
        const validTypes = ['run', 'walk', 'ride'];
        if (!validTypes.includes(type)) {
            return res.status(400).json({ message: 'Invalid activity type' });
        }

        if (!title || !type || !duration || !date || !userId || !distance || !caloriesBurned || !path|| !avr_pace || !steps) {
            return res.status(400).json({ message: 'All fields are required' });
        }

        const user = await Users.findByPk(userId);
        if (!user) {
            return res.status(404).json({ message: 'User not found' });
        }

        const newActivity = await Activity.create({
            title,
            type,
            duration,
            date,
            userId,
            distance,
            caloriesBurned,
            avr_pace,
            steps,
            path: JSON.stringify(path),
        });

        // Auto segmentasi per 1 KM jika path cukup
        if (path.length >= 2) {
            let segments = [];
            let segmentDistance = 0;
            let totalDistance = 0;
            const totalDuration = duration;
            let segmentStartIndex = 0;

            for (let i = 1; i < path.length; i++) {
                const prev = path[i - 1];
                const curr = path[i];

                const d = getDistanceFromLatLonInKm(prev.lat, prev.lng, curr.lat, curr.lng);
                segmentDistance += d;
                totalDistance += d;

                if (segmentDistance >= 1.0) {
                    const segmentRatio = segmentDistance / distance;
                    const segmentDuration = Math.round(segmentRatio * totalDuration);
                    const pace = parseFloat(((segmentDuration / 60) / segmentDistance).toFixed(2));

                    await ActivitySegment.create({
                        activityId: newActivity.id,
                        segment_number: segments.length + 1,
                        distance: parseFloat(segmentDistance.toFixed(2)),
                        duration: segmentDuration,
                        pace,
                    });

                    segments.push(segmentDistance);

                    // Reset segment distance
                    segmentDistance = 0;

                    // Start next segment from current point
                    segmentStartIndex = i;
                }
            }

            // Simpan segmen terakhir jika ada sisa
            if (segmentDistance > 0.1) {
                const segmentRatio = segmentDistance / distance;
                const segmentDuration = Math.round(segmentRatio * totalDuration);
                const pace = parseFloat(((segmentDuration / 60) / segmentDistance).toFixed(2));

                await ActivitySegment.create({
                    activityId: newActivity.id,
                    segment_number: segments.length + 1,
                    distance: parseFloat(segmentDistance.toFixed(2)),
                    duration: segmentDuration,
                    pace,
                });
            }
        }

        res.status(201).json(newActivity);
    } catch (error) {
        res.status(500).json({ message: 'Error saving activity', error: error.message });
    }
};

// Fungsi hitung jarak antar titik GPS (Haversine formula)
function getDistanceFromLatLonInKm(lat1, lon1, lat2, lon2) {
    const R = 6371;
    const dLat = deg2rad(lat2 - lat1);
    const dLon = deg2rad(lon2 - lon1);
    const a =
        Math.sin(dLat / 2) * Math.sin(dLat / 2) +
        Math.cos(deg2rad(lat1)) * Math.cos(deg2rad(lat2)) *
        Math.sin(dLon / 2) * Math.sin(dLon / 2);
    const c = 2 * Math.atan2(Math.sqrt(a), Math.sqrt(1 - a));
    return R * c;
}

function deg2rad(deg) {
    return deg * (Math.PI / 180);
}


export {
    getAllActivities,
    getUserActivities,
    getActivityById,
    saveActivity,
};
