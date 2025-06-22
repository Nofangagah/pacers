Pacer - Activity Tracking App
Pacer is a mobile application designed to help users track their physical activities, such as running, walking, and cycling. It provides features to record activity details, visualize routes on a map, and view activity history.

Features
Activity Tracking: Record details of your runs, walks, and bike rides including duration, distance, calories burned, steps, and average pace.
GPS Route Mapping: Visualize your activity routes on an interactive map.
Activity History: View a list of all your recorded activities.
Activity Details: See detailed statistics for each activity.
Search and Filter: Easily find specific activities in your history using the search functionality.
Delete Activity: Remove unwanted activities from your history.
User Authentication: Secure user login and registration.
Automatic Token Refresh: Handles expired access tokens by automatically refreshing them to maintain a seamless user experience.
Profile Management: View and manage your user profile.
About Me Section: Learn more about the developer.
Membership Management: Manage Premium and Standard membership plans, including currency conversion and payment scheduling.
Notifications: Receive notifications for saved activities and scheduled payments.
Screenshots
![WhatsApp Image 2025-06-11 at 02 56 55_8582a8a1](https://github.com/user-attachments/assets/34a822da-0e46-4e58-826d-fdb8d94bf33d)
![WhatsApp Image 2025-06-11 at 02 56 55_5b0bef01](https://github.com/user-attachments/assets/83df31a2-2be8-473d-8999-d420021d2fd0)
![WhatsApp Image 2025-06-11 at 03 05 15_a2e6204a](https://github.com/user-attachments/assets/657874c6-f4ff-488c-ac4c-6af1e19570b7)
![WhatsApp Image 2025-06-11 at 02 56 56_4a016a18](https://github.com/user-attachments/assets/0f446caf-3564-4e81-bb5b-748ed5befbdc)
![WhatsApp Image 2025-06-11 at 02 56 56_90e02be6](https://github.com/user-attachments/assets/0a17f612-cb72-41a1-9ee3-877951517e1e)
![WhatsApp Image 2025-06-11 at 02 56 57_06dcc1b2](https://github.com/user-attachments/assets/f990227b-4535-40bb-b443-12dd4e9fe275)
![WhatsApp Image 2025-06-11 at 02 56 56_14b6ca9e](https://github.com/user-attachments/assets/9d4f2be6-82b2-47ad-9d98-1ca9a54301f3)







Technologies Used
Flutter: Mobile application development framework.
Provider: State management for Flutter applications.
http: For making HTTP requests to the backend API.
shared_preferences: For local data storage (e.g., access tokens, user ID, user weight, membership status, scheduled payments).
flutter_map: For displaying interactive maps and drawing activity routes.
latlong2: Geodesy utilities for flutter_map.
intl: For date and time formatting.
timeago: For displaying relative time differences (e.g., "5 minutes ago").
location: For obtaining GPS location data.
pedometer: For tracking step counts.
sensors_plus: For accessing accelerometer data (used for stationary detection).
permission_handler: For requesting location and activity recognition permissions.
timezone: For handling time zones in payment scheduling.
Installation
To get a local copy up and running, follow these simple steps.

Prerequisites
Flutter SDK installed.
Dart SDK installed.
A physical device or an emulator/simulator to run the app.
Steps
Clone the repository:
Bash

git clone [<repository_url>](https://github.com/Nofangagah/pacers.git)
cd pacer
Install dependencies:
Bash

flutter pub get
Run the application:
Bash

flutter run
Project Structure
lib/models/activity_model.dart: Defines the ActivityModel class for structuring activity data.
lib/pages/activity/activity_page.dart: Displays the list of user activities, including search, filter, and delete functionalities.
lib/pages/activity/detail_activity_page.dart: Shows detailed information about a single activity, including its route on a map.
lib/pages/developer/about_me.dart: Contains information about the application's developer.
lib/pages/home_page.dart: The main navigation hub of the application with a BottomNavigationBar.
lib/pages/login_page.dart: Handles user login.
lib/pages/register_page.dart: Handles new user registration.
lib/service/acces_token_helper.dart: Provides a helper function for making authenticated HTTP requests, including automatic token refresh.
lib/constant.dart: Defines application-wide constants, such as the base URL for the API.
lib/user_model.dart: Defines the UserModel class.
lib/pages/konversi/konversi_page.dart: Handles membership management, currency conversion, and payment scheduling.
lib/pages/profilePage/profile_page.dart: Displays the user's profile and related options.
lib/pages/profilePage/edit_profile_page.dart: Allows users to edit their profile details.
lib/pages/running/running_page.dart: The main page for tracking and recording activities.
lib/pages/splash_screen.dart: The initial screen of the application that checks login status.
lib/pages/set_weight.dart: Allows the user to set their weight upon first login or if not set.
lib/pages/kesan_pesan.dart: A static page containing impressions and messages from the developer.
lib/pages/provider/activity_provider.dart: Provider for activity data state management.
API Endpoints
The application interacts with a backend API hosted at https://pacer-130852023885.us-central1.run.app/api.

Contributing
Contributions are what make the open-source community such an amazing place to learn, inspire, and create. Any contributions you make are greatly appreciated.

If you have a suggestion that would make this better, please fork the repo and create a pull request. You can also simply open an issue with the tag "enhancement".
Don't forget to give the project a star! Thanks again!

Fork the Project
Create your Feature Branch (git checkout -b feature/AmazingFeature)
Commit your Changes (git commit -m 'Add some AmazingFeature')
Push to the Branch (git push origin feature/AmazingFeature)
Open a Pull Request
License
Distributed under the MIT License. See LICENSE for more information.

Contact
Nofan Zohrial - nofanzohrial@gmail.com

Project Link: https://github.com/Nofangagah/pacers.git
