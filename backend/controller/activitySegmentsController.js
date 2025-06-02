import ActivitySegment from '../model/activitySegmentModel.js';
import Activity from '../model/activityModel.js';

// GET all segments for a user (through Activity's userId)
const getSegmentsByUserId = async (req, res) => {
  const userId = req.params.userId;
  try {
    const segments = await ActivitySegment.findAll({
      include: {
        model: Activity,
        where: { userId },
        attributes: ['id', 'title', 'type'],
      },
      order: [['segment_number', 'ASC']]
    });

    if (segments.length === 0) {
      return res.status(404).json({ message: 'No segments found for this user' });
    }

    res.status(200).json(segments);
  } catch (error) {
    res.status(500).json({ message: 'Error fetching segments for user', error: error.message });
  }
};

export { getSegmentsByUserId };
