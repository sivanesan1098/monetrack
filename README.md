# Monetrack

Monetrack is a secure, offline-first money tracker app built with Flutter. It features encrypted local storage, automatic transaction parsing, and robust reporting.

## Features

- **Offline-First**: All data is stored locally on your device.
- **Secure**: Database is encrypted using SQLCipher.
- **Auto-Import (Android)**: Parses transaction SMS/Notifications (Logic implemented, needs platform channel integration).
- **Reports**: Interactive charts for expenses and income.
- **Cross-Platform**: Runs on Android and iOS.

## Getting Started

### Prerequisites
- Flutter SDK (3.0+)
- Android Studio / Xcode
- Android Device (Android 11+) for wireless debugging

### Setup

1. **Clone the repository**:
   ```bash
   git clone https://github.com/yourusername/monetrack.git
   cd monetrack
   ```

2. **Install dependencies**:
   ```bash
   flutter pub get
   ```

3. **Run the app**:
   ```bash
   flutter run
   ```

## Wireless Debugging (Android)

To run on a physical Android device wirelessly:

1. Enable **Developer Options** and **Wireless Debugging** on your phone.
2. Pair your device:
   ```bash
   adb pair IP_ADDRESS:PORT
   ```
3. Connect to your device:
   ```bash
   adb connect IP_ADDRESS:PORT
   ```
4. Run the app:
   ```bash
   flutter run
   ```

## Architecture

This project follows **Clean Architecture**:
- `lib/domain`: Entities and business logic.
- `lib/data`: Repositories and data sources.
- `lib/presentation`: UI and state management (Riverpod).

## Testing

Run unit tests:
```bash
flutter test
```
