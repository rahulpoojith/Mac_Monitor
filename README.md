# Mac Monitor

A native macOS menu-bar utility with a live dashboard for CPU, RAM, storage, temperature, network, battery, thermal pressure, uptime, and process indicators.

## Installation Status

A ready-to-download installer is not available yet. This repository currently contains the app's source code, so the steps below require Terminal, Git, and the Swift 6 toolchain. They are intended for developers, not as a simple install for general users.

A user-friendly release would provide a signed and notarized `.dmg`: download it, open it, drag **Mac Monitor** to **Applications**, then launch it. The app does not have that release package yet. Signing and notarization require Apple Developer distribution setup.

## Build from Source

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

The build script compiles the app and generates its icon. The dashboard and menu-bar panel refresh every three seconds; use the Refresh button or Command-R for an immediate update.

To copy the built app into Applications:

```sh
ditto dist/MacTempChecker.app "/Applications/Mac Monitor.app"
open "/Applications/Mac Monitor.app"
```

To launch it automatically after sign-in, add **Mac Monitor** under **System Settings → General → Login Items**.

This project builds an unsigned, non-notarized app locally. If macOS blocks the first launch, only bypass the warning if you trust the source you cloned: Control-click the app in Finder, choose **Open**, and confirm.

For development, run the executable directly with `swift run` from the repository root.

## Temperature

macOS does not provide CPU temperature through a stable public API. You can try the optional helper:

```sh
brew install osx-cpu-temp
```

Sensor availability depends on the Mac. On this Apple-silicon Mac, the helper reports `0.0°C`, which the app treats as unavailable rather than showing a false CPU reading. When no CPU sensor is available, the dashboard shows the AppleSmartBattery temperature if macOS exposes it, labeled as a battery reading. The app also reports macOS thermal pressure.

## Security monitoring limits

The process monitor checks running process names against a small list of known crypto-mining and remote-access tools. A match is a review prompt, not proof of malware; many remote-access apps are legitimate. No match does not mean the Mac is virus-free. This app does not scan files, inspect process behavior, stop processes, or replace macOS XProtect or a dedicated antivirus product. macOS's built-in protections should remain enabled and up to date.
