# Pocket Save Editor

Pocket Save Editor is a Flutter app for viewing and editing Pokémon Crystal save files. It currently shows the party, PC boxes, and bag items, and supports editing Pokémon details before exporting a validated save.

## Development

Install Flutter, then run these commands from the project folder:

```sh
flutter pub get
flutter analyze
flutter test
```

Tests build a deterministic synthetic save in memory; no personal save file is needed. They cover save parsing, Pokémon edits, checksums, inventory, and export behavior.

## Testing on iPhone

Install Xcode and an iOS Simulator runtime, then run:

```sh
flutter doctor
open -a Simulator
flutter devices
flutter run -d ios
```

The simulator build can be used for development without App Store signing. Installing on a physical iPhone or distributing builds requires Apple signing setup.

While Xcode downloads, a temporary web preview can be opened on an iPhone connected to the same Wi-Fi:

```sh
flutter run -d web-server --web-hostname=0.0.0.0 --web-port=8080
```

Open the address printed by Flutter using the Mac's local network IP and port `8080`. This previews responsive screens in Safari, but it is not a native iOS build.

## Release preparation

The app does not bundle save files. Automated tests use generated fictional data. Review upstream attribution and redistribution terms for Pokémon-related data and artwork before creating distributable builds. The repository does not yet declare a software license.

For iPhone beta testing, create an Apple Developer Program account and upload a signed build to App Store Connect for TestFlight. The checked-in iOS bundle identifier and app icons are still development defaults.
