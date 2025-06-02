import { DataTypes } from "sequelize";
import db from "../config/database.js";


const Activity = db.define("Activity", {
  
  title: DataTypes.STRING,
  type: DataTypes.ENUM('run', 'walk', 'ride'), // e.g., run, walk, ride
  distance: DataTypes.FLOAT, // in KM
  duration: DataTypes.INTEGER, // in seconds
  date: DataTypes.DATE,
  userId:DataTypes.INTEGER, // Foreign key to Users table
  caloriesBurned: DataTypes.INTEGER, // Calories burned during the activity
  path: DataTypes.TEXT
}, {
  timestamps: true,
});



export default Activity;
