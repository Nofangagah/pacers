import jwt from "jsonwebtoken";

const authMiddleware = (req, res, next) => {
    try {
        const header = req.headers['authorization'];
        let token;

        if (header && header.startsWith('Bearer ')) {
            token = header.split(' ')[1];
        }

        if (!token) {
            return res.status(401).json({ success: false, message: "Access token not found" });
        }

        jwt.verify(token, process.env.ACCESS_TOKEN_SECRET, (err, decoded) => {
            if (err) return res.status(403).json({ success: false, message: "Invalid access token" });

            req.user = decoded.email; // atau bisa disesuaikan dengan payload token kamu
            next(); // <--- sangat penting
        });
    } catch (error) {
        res.status(500).json({ success: false, message: "Failed to authenticate user", error: error.message });
    }
};

export default authMiddleware;
