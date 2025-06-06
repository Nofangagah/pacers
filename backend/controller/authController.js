import User from "../model/usersModel.js";
import { OAuth2Client } from "google-auth-library";
import bcrypt from "bcrypt";
import { generateAccessToken, generateRefreshToken } from "../utils/generateTokens.js";
import dotenv from "dotenv";
dotenv.config();

const client = new OAuth2Client(process.env.GOOGLE_CLIENT_ID);



const registerUser = async (req, res) => {
    const allowedKeys = ['name', 'email', 'password'];
    const keys = Object.keys(req.body);
    const invalidKeys = keys.filter((key) => !allowedKeys.includes(key));

    if (invalidKeys.length > 0) {
        return res.status(400).json({
            success: false,
            message: `Invalid fields: ${invalidKeys.join(', ')}`,
        });
    }

    const { name, email, password } = req.body;

    if (!name || typeof name !== 'string' || name.trim() === '') {
        return res.status(400).json({ success: false, message: "Name is required and must be a string" });
    }
    if (!email || typeof email !== 'string' || email.trim() === '') {
        return res.status(400).json({ success: false, message: "Email is required and must be a string" });
    }
    if (!password || typeof password !== 'string' || password.trim() === '') {
        return res.status(400).json({ success: false, message: "Password is required and must be a string" });
    }
    if (password.length < 6) {
        return res.status(400).json({ success: false, message: "Password must be at least 6 characters long" });
    }
    const existingUser = await User.findOne({ where: { email } });
    if (existingUser) {
        return res.status(400).json({ message: 'User already exists' });
    }
    try {
        const hashedPassword = await bcrypt.hash(password, 10);
        const user = await User.create({ name, email, password: hashedPassword });
        res.status(201).json({ success: true, message: "User Registered Successfully", user });
    } catch (error) {
        res.status(500).json({ success: false, message: "Failed to register user", error });
    }
};

const loginUser = async (req, res) => {
    const allowedKeys = ['email', 'password'];
    const keys = Object.keys(req.body);
    const invalidKeys = keys.filter((key) => !allowedKeys.includes(key));
    const { email, password } = req.body;
    if (invalidKeys.length > 0) {
        return res.status(400).json({
            success: false,
            message: `Invalid fields: ${invalidKeys.join(', ')}`,
        });
    }
    if (!email || typeof email !== 'string' || email.trim() === '') {
        return res.status(400).json({ success: false, message: "Email is required and must be a string" });
    }
    if (!password || typeof password !== 'string' || password.trim() === '') {
        return res.status(400).json({ success: false, message: "Password is required and must be a string" });
    }

    try {
        const user = await User.findOne({ where: { email: email } });
        if (user) {
            const userPlain = user.toJSON();
            const { password: _, refresh_token: __, ...SafeUserData } = userPlain;

            const isPasswordmatch = await bcrypt.compare(password, user.password);
            if (isPasswordmatch) {
                const accessToken = generateAccessToken(SafeUserData);
                const refreshToken = generateRefreshToken(SafeUserData);
                await User.update({ refresh_token: refreshToken }, { where: { id: user.id } });

                res.cookie("refreshToken", refreshToken, {
                    httpOnly: true,
                    secure: true,
                    sameSite: "none",
                    maxAge: 7 * 24 * 60 * 60 * 1000
                })
                res.status(200).json({ success: true, message: "User Logged In Successfully", user: SafeUserData, accessToken, refreshToken });
            } else {
                res.status(401).json({ success: false, message: "Invalid email or password" });
            }
        }


    } catch (error) {
        res.status(error.statusCode || 500).json({ success: false, message: "Failed to login user", error });
    }
}

const loginWithGoogle = async (req, res) => {
    const { idToken } = req.body
    try {
        const ticket = await client.verifyIdToken({
            idToken: idToken,
            audience: process.env.GOOGLE_CLIENT_ID
        })
        const payload = ticket.getPayload();
        const { sub: googleId, email, name } = payload;

        let user = await User.findOne({ where: { google_id: googleId } });

        if (!user) {
           
            user = await User.findOne({ where: { email } });

            if (user) {
                
                await user.update({ google_id: googleId });
            } else {
                
                user = await User.create({ name, email, google_id: googleId });
            }
        }

        const userPlain = user.toJSON();
        const { password: _, refresh_token: __, ...SafeUserData } = userPlain;
        const accessToken = generateAccessToken(SafeUserData);
        const refreshToken = generateRefreshToken(SafeUserData);
        await User.update({ refresh_token: refreshToken }, { where: { id: user.id } });
        console.log(SafeUserData);
        res.cookie("refreshToken", refreshToken, {
            httpOnly: true,
            secure: true,
            sameSite: "none",
            maxAge: 7 * 24 * 60 * 60 * 1000
        })
        res.status(200).json({ success: true, message: "User Logged In Successfully", user: SafeUserData, accessToken, refreshToken });

    } catch (error) {
        res.status(error.statusCode || 500).json({ success: false, message: "Failed to login user", error });

    }
}

const logoutUser = async (req, res) => {
    try {
        const refreshToken = req.headers['authorization']?.split(' ')[1];
        if (!refreshToken) return res.status(401).json({ success: false, message: "refresh token not found" });

        const user = await User.findOne({ where: { refresh_token: refreshToken } });
        if (!user.refresh_token) return res.status(401).json({ success: false, message: "user not not found" });

        const userId = user.id
        await User.update({ refresh_token: null }, { where: { id: userId } })
        res.clearCookie("refreshToken");
        res.status(200).json({ success: true, message: "User Logged Out Successfully" });
    } catch (error) {
        res.status(error.statusCode || 500).json({ success: false, message: "Failed to logout user", error });

    }
}

export { registerUser, loginUser, loginWithGoogle, logoutUser }