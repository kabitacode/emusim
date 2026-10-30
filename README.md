<img width="300" height="300" alt="logo-emusim" src="https://github.com/user-attachments/assets/3552a2a7-837d-401e-a6c9-7890223addf0" />


# EmuSim

Run, stop and wipe iOS simulators and Android emulators from one window.

## Install

Download `EmuSim.dmg` from [Releases](https://github.com/kabitacode/emusim/releases) and move the app to Applications.

The app isn't notarized, so macOS blocks it the first time. Allow it in System Settings > Privacy & Security, or run:

```sh
xattr -dr com.apple.quarantine /Applications/emusim.app
```

## Requirements

- macOS 15.8+
- Xcode with simulators installed, for iOS
- Android SDK with `emulator` and `platform-tools`, for Android

## Usage

- Run: boots the simulator, or starts the emulator.
- Stop: shuts down the simulator, or kills the emulator.
- Clear: `simctl erase` on iOS, `emulator -wipe-data` on Android. Shut the simulator down first. On Android the emulator starts after wiping.

The list refreshes every 5 seconds.

The Android SDK path is in Settings (Cmd+,). Default is `$ANDROID_HOME`, then `~/Library/Android/sdk`.

## Build

```sh
git clone https://github.com/kabitacode/emusim.git
cd emusim
open emusim.xcodeproj
```

Tested with Xcode 26.2.

The app isn't sandboxed because it runs `xcrun`, `emulator` and `adb`.
