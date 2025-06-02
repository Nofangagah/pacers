import Express from "express";
import { registerUser, loginUser, loginWithGoogle, logoutUser } from "../controller/authController.js";
import { getAccesToken } from "../controller/tokenController.js";

const router = Express.Router();

router.post("/register", registerUser);
router.post("/login", loginUser);
router.get("/token", getAccesToken);
router.post("/login-google", loginWithGoogle);
router.post("/logout", logoutUser);

export default router;