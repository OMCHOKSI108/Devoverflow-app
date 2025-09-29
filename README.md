# DevOverflow

DevOverflow is a mobile application designed for developers to ask and answer technical questions, share knowledge, and engage with a community. Built using Flutter, it provides a platform similar to Stack Overflow, enabling users to post questions, provide answers, bookmark content, and participate in gamification features.

## Features

- User authentication and profile management
- Question and answer posting with rich text support
- Voting system for questions and answers
- Bookmarking questions for later reference
- Friend connections and user discovery
- Notifications for updates and interactions
- Leaderboard and gamification with reputation points
- Search functionality for questions and users
- Chat history and AI chatbot integration
- Password reset and email verification

## Prerequisites

- Flutter SDK (version 3.8.1 or later)
- Dart SDK (included with Flutter)
- Android Studio or Xcode for mobile development
- A connected device or emulator for testing

## Installation

1. Clone the repository:
   ```
   git clone <repository-url>
   cd devoverflow
   ```

2. Install dependencies:
   ```
   flutter pub get
   ```

3. Set up environment variables:
   - Create a `.env` file in the root directory
   - Add necessary API endpoints and configuration keys as per the API documentation

## Running the Application

1. Ensure a device or emulator is connected and available.

2. Run the application:
   ```
   flutter run
   ```

3. The app will build and launch on the connected device.

## Project Structure

- `lib/`: Contains the main application code
  - `main.dart`: Entry point of the application
  - `homescreen.dart`: Main home screen
  - `questions.dart`: Question listing and management
  - `profile.dart`: User profile management
  - `api_service.dart`: API communication layer
- `android/`: Android-specific configuration
- `ios/`: iOS-specific configuration
- `docs/`: Documentation files including API specifications

## API Integration

The application integrates with a backend API for data management. Refer to `API_DOCS.md` for detailed endpoint documentation and usage examples.

## Team Members

- **OM CHOKSI** (23AIML010) - [GitHub: omchoksi108](https://github.com/omchoksi108)
- **DEV PATEL** (23AIML047) - [GitHub: devpatel0005](https://github.com/devpatel0005)

## License

This project is for educational purposes as part of the Mobile Application Development course.
