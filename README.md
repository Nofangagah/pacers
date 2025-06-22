# 🏃‍♂️ Pacer - Activity Tracking App

**Pacer** is a mobile application designed to help users track their physical activities, such as running, walking, and cycling. It records activity details, displays routes on a map, and provides an activity history for user review.

---

## ✨ Features

- 📍 **Activity Tracking**: Record duration, distance, calories burned, step count, and average pace.
- 🗺️ **GPS Route Mapping**: Visualize activity routes on an interactive map.
- 📖 **Activity History**: View a list of all recorded activities.
- 📊 **Activity Details**: Access comprehensive statistics for each activity.
- 🔍 **Search & Filter**: Quickly find specific activities using search and filter features.
- 🗑️ **Delete Activity**: Remove unwanted activities from history.
- 🔐 **User Authentication**: Secure registration and login system.
- ♻️ **Automatic Token Refresh**: Handles token expiration and maintains seamless authentication.
- 👤 **Profile Management**: View and manage user profile details.
- ℹ️ **About Me**: Information about the developer.
- 💎 **Membership Management**: Manage Standard and Premium plans with currency conversion and payment scheduling.
- 🔔 **Notifications**: Receive notifications for saved activities and upcoming scheduled payments.

---

## 📱 Screenshots

| | |
|---|---|
| ![Login Page](https://github.com/user-attachments/assets/34a822da-0e46-4e58-826d-fdb8d94bf33d) | ![Register Page](https://github.com/user-attachments/assets/83df31a2-2be8-473d-8999-d420021d2fd0) |
| ![Home Page](https://github.com/user-attachments/assets/657874c6-f4ff-488c-ac4c-6af1e19570b7) | ![Activity List Page](https://github.com/user-attachments/assets/0f446caf-3564-4e81-bb5b-748ed5befbdc) |
| ![Activity Detail Page](https://github.com/user-attachments/assets/0a17f612-cb72-41a1-9ee3-877951517e1e) | ![Profile Page](https://github.com/user-attachments/assets/f990227b-4535-40bb-b443-12dd4e9fe275) |
| ![Membership Page](https://github.com/user-attachments/assets/9d4f2be6-82b2-47ad-9d98-1ca9a54301f3) | |

---

## 🛠️ Technologies Used

- **Flutter** – Mobile application framework.
- **Provider** – State management.
- **http** – API communication.
- **shared_preferences** – Local storage for access tokens, user data, etc..
- **flutter_map** – Displaying maps and drawing routes.
- **latlong2** – Geolocation utilities.
- **intl** – Date and time formatting.
- **timeago** – Relative time formatting (e.g., "5 minutes ago").
- **location** – Access GPS location data.
- **pedometer** – Track step counts.
- **sensors_plus** – Read device sensor data for stationary detection.
- **permission_handler** – Request necessary permissions.
- **timezone** – Manage timezone-based scheduling.

---

## 🚀 Installation

### 📋 Prerequisites

- Flutter SDK
- Dart SDK
- A physical device or emulator

### ⚙️ Setup Steps

1.  **Clone the Repository**
    ```bash
    git clone [https://github.com/Nofangagah/pacers.git](https://github.com/Nofangagah/pacers.git)
    cd pacers
    ```
2.  **Install Dependencies**
    ```bash
    flutter pub get
    ```
3.  **Run the Application**
    ```bash
    flutter run
    ```

---

## 📂 Project Structure

* `lib/models/activity_model.dart`: Defines the `ActivityModel` class for structuring activity data.
* `lib/pages/activity/activity_page.dart`: Displays the list of user activities, including search, filter, and delete functionalities.
* `lib/pages/activity/detail_activity_page.dart`: Shows detailed information about a single activity, including its route on a map.
* `lib/pages/developer/about_me.dart`: Contains information about the application's developer.
* `lib/pages/home_page.dart`: The main navigation hub of the application with a `BottomNavigationBar`.
* `lib/pages/login_page.dart`: Handles user login.
* `lib/pages/register_page.dart`: Handles new user registration.
* `lib/service/acces_token_helper.dart`: Provides a helper function for making authenticated HTTP requests, including automatic token refresh.
* `lib/constant.dart`: Defines application-wide constants, such as the base URL for the API.
* `lib/user_model.dart`: Defines the `UserModel` class.
* `lib/pages/konversi/konversi_page.dart`: Handles membership management, currency conversion, and payment scheduling.
* `lib/pages/profilePage/profile_page.dart`: Displays the user's profile and related options.
* `lib/pages/profilePage/edit_profile_page.dart`: Allows users to edit their profile details.
* `lib/pages/running/running_page.dart`: The main page for tracking and recording activities.
* `lib/pages/splash_screen.dart`: The initial screen of the application that checks login status.
* `lib/pages/set_weight.dart`: Allows the user to set their weight upon first login or if not set.
* `lib/pages/kesan_pesan.dart`: A static page containing impressions and messages from the developer.
* `lib/pages/provider/activity_provider.dart`: Provider for activity data state management.

---

## 🌐 API Endpoints

The application interacts with a backend API hosted at `https://pacer-130852023885.us-central1.run.app/api`.

---

## 🤝 Contributing

Contributions are what make the open-source community such an amazing place to learn, inspire, and create. Any contributions you make are **greatly appreciated**.

If you have a suggestion that would make this better, please fork the repo and create a pull request. You can also simply open an issue with the tag "enhancement".
Don't forget to give the project a star! Thanks again!

1.  Fork the Project
2.  Create your Feature Branch (`git checkout -b feature/AmazingFeature`)
3.  Commit your Changes (`git commit -m 'Add some AmazingFeature'`)
4.  Push to the Branch (`git push origin feature/AmazingFeature`)
5.  Open a Pull Request

---

## 📄 License

Distributed under the MIT License. See `LICENSE` for more information.

---

## 📧 Contact

Nofan Zohrial - nofanzohrial@gmail.com

Project Link: [https://github.com/Nofangagah/pacers.git](https://github.com/Nofangagah/pacers.git)
