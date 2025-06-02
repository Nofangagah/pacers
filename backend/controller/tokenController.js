import User from '../model/usersModel.js';
import jwt from 'jsonwebtoken';
import { generateAccessToken } from '../utils/generateTokens.js';

const getAccesToken = async (req, res) => {
  try {
    const authHeader = req.headers['authorization'];
    const refreshToken = authHeader && authHeader.split(' ')[1];
    if (!refreshToken) return res.status(401).json({ success: false, message: "refresh token not found" });

    const user = await User.findOne({ where: { refresh_token: refreshToken } });
    if (!user || !user.refresh_token) return res.status(401).json({ success: false, message: "refresh token not valid in DB" });

    jwt.verify(refreshToken, process.env.REFRESH_TOKEN_SECRET, (err, decoded) => {
      if (err) return res.status(403).json({ success: false, message: "Invalid refresh token" });

      const userPlain = user.toJSON();
      const { password: _, refresh_token: __, ...SafeUserData } = userPlain;
      const accessToken = generateAccessToken(SafeUserData);

      res.status(200).json({ success: true, message: "Access token generated", accessToken });
    });
  } catch (error) {
    return res.status(error.statusCode || 500).json({ success: false, message: "Failed to generate access token", error });
  }
};

export { getAccesToken }