import { DataTypes } from "sequelize";
import db from "../config/database.js";

const ActivitySegment = db.define("ActivitySegment", {
  segment_number: DataTypes.INTEGER,
  distance: DataTypes.FLOAT,
  duration: DataTypes.INTEGER,
  pace: DataTypes.FLOAT, // e.g., minutes per KM
}, {
  timestamps: true,
});


export default ActivitySegment;
