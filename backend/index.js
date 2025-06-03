import  Express  from "express";
import cors from "cors";
import cookieParser from "cookie-parser";
import dotenv from "dotenv";
dotenv.config();
import { db } from "./model/index.js";
import authRoute from "./routes/authRoute.js";
import activityRoute from "./routes/activityRoute.js";
import activitySegmentsRoute from "./routes/activitySegmentsRoute.js";
import userRoute from "./routes/userRoute.js";
import scheduleDailyReminder from "./cron/dailyReminder.js";
import notificationRoute from "./routes/notificationRoute.js";

const app = Express();
console.log("Step 1: Starting app setup");
const port = process.env.PORT|| 8080;

app.use(cors());
console.log("Step 2: Middleware registered");
app.use(cookieParser());
app.use(Express.json());
app.use(Express.urlencoded({ extended: true }));
app.use("/api/user", userRoute);
app.use("/api/auth", authRoute);
app.use("/api/activity", activityRoute);
app.use("/api/activity-segments", activitySegmentsRoute);
app.use("/api/notif",  notificationRoute);
scheduleDailyReminder(); 
db.sync().then(() => {
    console.log("Step 3: DB synced");
}).catch((error) => {
    console.error("Step 3 Error syncing database:", error);
});

console.log("PORT:", process.env.PORT);


app.use('/', (req, res) => {
    res.send('Hello World!');
});

app.listen(port, "0.0.0.0", () => {
    console.log(`Step 4: Server running on port ${port}`);
});