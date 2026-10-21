# Mac Monitor

A native macOS menu-bar utility with a live dashboard for CPU, RAM, storage, temperature, network, battery, thermal pressure, uptime, and process indicators.

## Install on Apple Silicon

Download the [MacMonitor-1.0-arm64.dmg release](https://github.com/rahulpoojith/Mac_Monitor/releases/download/v1.0.0/MacMonitor-1.0-arm64.dmg). This build requires macOS 13 or newer and an Apple-silicon Mac. You do not need to clone the repository or use Terminal.

1. Open the downloaded `.dmg` file.
2. In the window that appears, drag **Mac Monitor.app** onto the **Applications** shortcut.
3. Open **Applications** in Finder and launch **Mac Monitor**.

This release is unsigned and not notarized, so macOS may show a security warning. Only proceed if you trust this project. If you choose to open it, Control-click **Mac Monitor** in Applications, choose **Open**, and confirm the prompt.

To start Mac Monitor automatically after sign-in, add it under **System Settings → General → Login Items**.

## Build from Source (Developers)

You need macOS 13 or newer, Git, and the Swift 6 toolchain. Install Apple's command-line developer tools if Swift is not already available:

```sh
xcode-select --install
```

Clone the repository and build the standalone app bundle:

```sh
git clone https://github.com/rahulpoojith/Mac_Monitor.git
cd Mac_Monitor
./scripts/build-app.sh
open dist/MacTempChecker.app
```

To create a drag-to-Applications DMG locally, run:

```sh
./scripts/build-dmg.sh
```

The DMG is written to `dist/MacMonitor-1.0-<architecture>.dmg`. Local builds are unsigned and not notarized.

The build script compiles the app and generates its icon. The dashboard and menu-bar panel refresh every three seconds; use the Refresh button or Command-R for an immediate update.

For development, run the executable directly with `swift run` from the repository root.

## Temperature

macOS does not provide CPU temperature through a stable public API. You can try the optional helper:

```sh
brew install osx-cpu-temp
```

Sensor availability depends on the Mac. On this Apple-silicon Mac, the helper reports `0.0°C`, which the app treats as unavailable rather than showing a false CPU reading. When no CPU sensor is available, the dashboard shows the AppleSmartBattery temperature if macOS exposes it, labeled as a battery reading. The app also reports macOS thermal pressure.

## Security monitoring limits

The process monitor checks running process names against a small list of known crypto-mining and remote-access tools. A match is a review prompt, not proof of malware; many remote-access apps are legitimate. No match does not mean the Mac is virus-free. This app does not scan files, inspect process behavior, stop processes, or replace macOS XProtect or a dedicated antivirus product. macOS's built-in protections should remain enabled and up to date.
