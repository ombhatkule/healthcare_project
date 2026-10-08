# HealthCare AI

An AI-Powered Personalized Healthcare Management System built with Flutter (Material 3), Firebase, and Flask.

## Tech Stack

- **Frontend**: Flutter, Dart, Material 3
- **Backend**: Python Flask (REST APIs)
- **Auth & DB**: Firebase Authentication, Cloud Firestore
- **ML**: Scikit-learn (disease prediction)
- **AI**: Groq API (healthcare assistant)

## Project Structure

```
lib/
├── main.dart                 # Entry point + Firebase init + DI providers
├── config/                   # App routing + configuration/.env loading
├── core/
│   ├── constants/            # Colors, sizes, strings, assets, decorations
│   ├── errors/               # Exceptions & failures
│   ├── theme/                # Material 3 theme
│   └── utils/                # Shared helpers
├── features/                 # One folder per module (feature-first)
│   ├── auth/                 # Firebase authentication (Phase 2)
│   ├── splash/               # Splash screen
│   ├── home/                 # Dashboard
│   └── ...                   # Future modules
└── shared/                   # Reusable models, services, widgets, enums
```

## Firebase Setup (required before running)

The app uses Firebase Authentication. You must configure your Firebase project:

### 1. Create a Firebase project
Go to the [Firebase Console](https://console.firebase.google.com) and create a project.

### 2. Enable Email/Password authentication
In the console: Build → Authentication → Sign-in method → enable **Email/Password**.

### 3. Configure your app

**Web:**
1. Add a web app to your Firebase project.
2. Copy your config values into `assets/env/.env` (copy from `.env.example`).
3. Never commit `.env` (it is git-ignored).

**Android:**
1. Add an Android app (package id `com.healthcareapp.healthcare_app`).
2. Download `google-services.json` and place it in `android/app/`.

**iOS:**
1. Add an iOS app (bundle id matching).
2. Download `GoogleService-Info.plist` and add it to `ios/Runner/` via Xcode.

## Run

```bash
flutter pub get
flutter run
```

## Verify

```bash
flutter analyze      # No issues
flutter test         # All tests pass
flutter build web    # Compiles
```

## Disclaimer

This application provides informational and decision-support features only and does **not** replace professional medical advice or diagnosis.
