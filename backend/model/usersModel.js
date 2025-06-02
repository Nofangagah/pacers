import { DataTypes } from "sequelize";
import db from "../config/database.js";

const User = db.define("User", {
  name: DataTypes.STRING,
  email: { type: DataTypes.STRING, unique: true },
  password: DataTypes.STRING,
  google_id: DataTypes.STRING,
  refresh_token: DataTypes.TEXT,
  device_token: DataTypes.TEXT,
  weight: { type: DataTypes.FLOAT, allowNull: true }, 
}, {
  timestamps: true
  }
);

export default User;
