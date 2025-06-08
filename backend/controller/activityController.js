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
    // Log body request yang diterima dari client
    console.log('SERVER: Received request body for saveActivity:', JSON.stringify(req.body, null, 2));

    // Hapus 'tracking_mode' dari destructuring
    const { title, type, duration, date, userId, distance, caloriesBurned, path, avr_pace, steps } = req.body;

    function _getDurationBetweenPoints(path, startIndex, endIndex, totalDuration) {
    if (path.length === 0 || startIndex >= path.length || endIndex >= path.length) {
        return 0;
    }
    const totalPoints = path.length;
    const pointsInSegment = endIndex - startIndex + 1;
    return (pointsInSegment / totalPoints) * totalDuration;
}

    // Tambahkan validasi untuk setiap field yang diterima
    if (
        title === undefined || type === undefined || duration === undefined ||
        date === undefined || userId === undefined || distance === undefined ||
        caloriesBurned === undefined || path === undefined || avr_pace === undefined ||
        steps === undefined
    ) {
        console.error('SERVER: Validation Error: All fields are required.');
        return res.status(400).json({ message: 'All fields are required' });
    }

    const validTypes = ['run', 'walk', 'ride'];
    if (!validTypes.includes(type)) {
        console.error(`SERVER: Validation Error: Invalid activity type received: ${type}`);
        return res.status(400).json({ message: 'Invalid activity type' });
    }

    // Pastikan `path` adalah array dan setiap elemen memiliki `lat` dan `lng`
    if (!Array.isArray(path) || path.some(p => typeof p.lat === 'undefined' || typeof p.lng === 'undefined')) {
        console.error('SERVER: Validation Error: Path must be an array of objects with lat and lng properties.');
        return res.status(400).json({ message: 'Invalid path data format' });
    }
    
    console.log(`SERVER: Attempting to save activity for userId: ${userId}`);

    try {
        const user = await Users.findByPk(userId);
        if (!user) {
            console.error(`SERVER: User not found for ID: ${userId}`);
            return res.status(404).json({ message: 'User not found' });
        }
        console.log(`SERVER: User found: ${user.username} (ID: ${user.id})`);

        // Mencoba membuat entri aktivitas baru
        console.log('SERVER: Creating new activity entry in database...');
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
            path: JSON.stringify(path), // Simpan array path sebagai string JSON
            // Hapus 'tracking_mode' di sini
        });
        console.log('SERVER: New activity created successfully:', newActivity.toJSON());

        // --- Segmentasi per 1 KM ---
        if (path.length >= 2 && distance > 0) { // Pastikan ada path dan totalDistance lebih dari 0 untuk mencegah pembagian nol
            console.log('SERVER: Starting activity segmentation...');
            let segments = [];
            let segmentDistanceAccumulator = 0; // Jarak yang terakumulasi dalam segmen saat ini (dalam KM)
            let currentSegmentPoints = []; // Titik-titik untuk segmen saat ini
            let segmentStartTime = 0; // Waktu mulai untuk segmen saat ini

            for (let i = 0; i < path.length; i++) {
                currentSegmentPoints.push(path[i]);

                if (i > 0) {
                    const prev = path[i - 1];
                    const curr = path[i];
                    const d = getDistanceFromLatLonInKm(prev.lat, prev.lng, curr.lat, curr.lng); // Jarak dalam KM
                    segmentDistanceAccumulator += d;
                }

                // Cek jika segmen sudah mencapai 1 KM atau ini adalah titik terakhir
                if (segmentDistanceAccumulator >= 1.0 || i === path.length - 1) {
                    if (currentSegmentPoints.length > 1) { // Pastikan ada setidaknya 2 titik untuk segmen
                        const segmentDuration = Math.round((_getDurationBetweenPoints(path, segmentStartTime, i, duration) / 1000) * duration); // Durasi segmen
                        const pace = segmentDistanceAccumulator > 0 ? parseFloat(((segmentDuration / 60) / segmentDistanceAccumulator).toFixed(2)) : 0; // Pace dalam menit/km

                        console.log(`SERVER: Creating segment ${segments.length + 1}: Distance=${segmentDistanceAccumulator.toFixed(2)} KM, Duration=${segmentDuration}s, Pace=${pace} min/km`);

                        await ActivitySegment.create({
                            activityId: newActivity.id,
                            segment_number: segments.length + 1,
                            distance: parseFloat(segmentDistanceAccumulator.toFixed(2)),
                            duration: segmentDuration,
                            pace,
                            // Anda mungkin ingin menyimpan path segmen juga, tapi ini bisa memperbesar DB
                            // segment_path: JSON.stringify(currentSegmentPoints), 
                        });

                        segments.push({
                            distance: segmentDistanceAccumulator,
                            duration: segmentDuration,
                            pace
                        });

                        // Reset untuk segmen berikutnya
                        segmentDistanceAccumulator = 0;
                        currentSegmentPoints = [path[i]]; // Titik saat ini menjadi titik awal segmen berikutnya
                        segmentStartTime = i; // Titik saat ini menjadi titik awal waktu untuk durasi
                    } else if (i === path.length - 1 && segmentDistanceAccumulator > 0) {
                        // Handle kasus segmen terakhir yang mungkin kurang dari 1km tapi memiliki jarak
                        const segmentDuration = Math.round((_getDurationBetweenPoints(path, segmentStartTime, i, duration) / 1000) * duration);
                        const pace = segmentDistanceAccumulator > 0 ? parseFloat(((segmentDuration / 60) / segmentDistanceAccumulator).toFixed(2)) : 0;

                        console.log(`SERVER: Creating final partial segment ${segments.length + 1}: Distance=${segmentDistanceAccumulator.toFixed(2)} KM, Duration=${segmentDuration}s, Pace=${pace} min/km`);

                        await ActivitySegment.create({
                            activityId: newActivity.id,
                            segment_number: segments.length + 1,
                            distance: parseFloat(segmentDistanceAccumulator.toFixed(2)),
                            duration: segmentDuration,
                            pace,
                        });
                        segments.push({
                            distance: segmentDistanceAccumulator,
                            duration: segmentDuration,
                            pace
                        });
                    }
                }
            }
            console.log('SERVER: Activity segmentation completed.');
        } else {
            console.log('SERVER: Skipping segmentation: Not enough path points or distance is zero.');
        }

        // Kirim respon sukses
        res.status(201).json(newActivity);
        console.log('SERVER: Activity saved and response sent successfully.');

    } catch (error) {
        // Log error lengkap di server
        console.error('SERVER: Error saving activity:', error);
        console.error('SERVER: Error message:', error.message);
        // Pastikan respon error juga JSON yang valid
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
