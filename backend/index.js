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
const port = process.env.PORT|| 8080;

app.use(cors());
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
    console.log("Database synced");
    console.log("table created");
}).catch((error) => {
    console.error("Error syncing database:", error);
});

app.use('/', (req, res) => {
    res.send('Hello World!');
});



app.listen(port,() => {
    console.log(`Server running on port ${port}`);
});