<p align="center">
  <img src="Resources/AppBundle/READMEIcon.png" alt="RouteTone icon" width="168" />
</p>

<h1 align="center">RouteTone</h1>

<p align="center">
  Keep your MacBook on the right speaker and microphone.
</p>

[中文说明](README.zh-CN.md)

RouteTone fixes one of the most annoying MacBook audio problems: macOS keeps switching to the wrong speaker or microphone when you connect AirPods, monitors, docks, or USB devices.

RouteTone watches those changes and switches macOS back to the highest-priority device you chose.

<p align="center">
  <img src="docs/images/menu-bar-panel.png" alt="RouteTone menu bar panel" width="330" />
</p>


<p align="center">
  Quickly check the current input/output route and toggle auto-switching from the menu bar.
</p>
<p align="center">
  <img src="docs/images/settings-window.png" alt="RouteTone settings window" width="560" />
</p>


<p align="center">
  Set separate priority lists for output and input, then let RouteTone keep macOS on the right devices automatically.
</p>

## What It Does

- Separate priority lists for output and input
- Automatically picks the highest-priority available device
- Lets you drag to reorder devices in Settings
- Works from the menu bar

## Install

### Homebrew

```bash
brew tap kang-0909/tap
brew install --cask routetone
```

### Download

Download the latest release from GitHub, unzip it, and move `RouteTone.app` to `/Applications`.

## Use

1. Open `App Settings`.
2. Drag your preferred output devices into order.
3. Drag your preferred input devices into order.
4. Leave `Auto-switch Input` and `Auto-switch Output` enabled.

When macOS switches to the wrong device, RouteTone switches it back.

## Build

```bash
swift build
./Scripts/build-app.sh
open dist/RouteTone.app
```

## Release

This repo includes a GitHub Release workflow and a Homebrew cask template.

- Release guide: [`RELEASE.md`](RELEASE.md)
- Homebrew cask: [`Casks/routetone.rb`](Casks/routetone.rb)
