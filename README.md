# AmutBar Cargo

معرفی پروژه

## Features
- OTP Login
- Identity Verification
- Cargo Owner Profile
- Create Load
- Search City
- Search Cargo Type
- Vehicle Types
- My Loads
- Close Load
- Support Tickets
- Banner System
- Notifications
- App Update Check

## Tech Stack
- Flutter
- Dart
- Dio
- GoRouter
- Secure Storage

## Project Structure

lib/
  core/
  features/
    auth/
    dashboard/
    loads/
    onboarding/
    profile/

## API Configuration

API_BASE_URL

## Development

flutter pub get
flutter analyze
flutter test

## Run
flutter run \
  --dart-define=API_BASE_URL=https://amutapp.com/amutadmin

flutter run

## Production Build

flutter build apk --release
flutter build appbundle --release

## Release Signing
flutter build appbundle --release \
  --dart-define=API_BASE_URL=https://amutapp.com/amutadmin
  
توضیح key.properties

## API / Backend

توضیح ارتباط با amutapp.com

## Android Package

com.amutapp.cargo.amutbar_cargo

## Status

Android: Supported
iOS: Supported
Web: Not officially supported

## License / Copyright

## 