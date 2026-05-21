# COC Card - Flutter Project

## Build Rules

- After every successful `flutter build apk --release`, copy the APK to the project root as `coccard.apk`:
  ```
  cp build/app/outputs/flutter-apk/app-release.apk coccard.apk
  ```

## Project Overview

- Flutter app for Call of Cthulhu (COC) TRPG character sheet management
- State management: Provider + SharedPreferences
- Android signing: `android/app/release.jks` (alias: coccard)
