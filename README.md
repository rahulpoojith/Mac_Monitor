# Mac Monitor

A native macOS menu-bar utility with a live dashboard for CPU, RAM, storage, temperature, network, battery, thermal pressure, uptime, and process indicators.

## Run

From this folder, run:

```sh
swift run
```

The dashboard and menu-bar summary update every three seconds. Use the Refresh button or Command-R to request an immediate update.

## Run outside VS Code

Build a standalone macOS app bundle:

```sh
./scripts/build-app.sh
open dist/MacTempChecker.app
```

The build script generates and embeds the Mac Monitor app icon.

After it opens, you can close VS Code. To start it automatically when you sign in, add **Mac Monitor** under **System Settings → General → Login Items**. You can move `dist/MacTempChecker.app` to your Applications folder if you want it installed there.

## Temperature

macOS does not provide CPU temperature through a stable public API. You can try the optional helper:

```sh
brew install osx-cpu-temp
```

Sensor availability depends on the Mac. On this Apple-silicon Mac, the helper reports `0.0°C`, which the app treats as unavailable rather than showing a false CPU reading. When no CPU sensor is available, the dashboard shows the AppleSmartBattery temperature if macOS exposes it, labeled as a battery reading. The app also reports macOS thermal pressure.

## Security monitoring limits

The process monitor checks running process names against a small list of known crypto-mining and remote-access tools. A match is a review prompt, not proof of malware; many remote-access apps are legitimate. No match does not mean the Mac is virus-free. This app does not scan files, inspect process behavior, stop processes, or replace macOS XProtect or a dedicated antivirus product. macOS's built-in protections should remain enabled and up to date.
