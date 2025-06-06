// controllers/userController.js
import Users from '../model/usersModel.js';

const editProfile = async (req, res) => {
  const { id } = req.params;
  const updateFields = req.body;

  try {
    const user = await Users.findByPk(id);
    if (!user) {
      return res.status(404).json({ message: 'User not found' });
    }

    
    if (updateFields.weight !== undefined) {
      if (isNaN(updateFields.weight) || updateFields.weight <= 0) {
        return res.status(400).json({ message: 'Weight must be a positive number' });
      }
    }

    await user.update(updateFields);

    
    res.status(200).json({
      message: 'Profile updated successfully',
      user: {
        id: user.id,
        name: user.name,
        email: user.email,
        weight: user.weight,
        
      },
    });
  } catch (error) {
    res.status(500).json({ message: 'Failed to update profile', error: error.message });
  }
};



const deviceTokenUpdate = async (req, res) => {
     try {
    const { device_token } = req.body;
    const { id } = req.params;

    const user = await Users.findByPk(id);
    if (!user) return res.status(404).json({ message: 'User not found' });

    user.device_token = device_token;
    await user.save();

    res.json({ message: 'Device token saved successfully' });
  } catch (err) {
    res.status(500).json({ message: 'Failed to save device token', error: err.message });
  }
}



export { editProfile, deviceTokenUpdate };

