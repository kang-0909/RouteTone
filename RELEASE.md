# Release Guide

This repo is ready for GitHub Releases.

## Publish a Release

1. Update the version in `Resources/AppBundle/Info.plist`
2. Commit and push
3. Create and push a tag:

```bash
git tag v0.1.0
git push origin main --tags
```

The GitHub Actions workflow will:

- build `RouteTone.app`
- zip it
- generate a SHA-256 file
- create a GitHub Release
- upload both assets

## Homebrew

For Homebrew install, use a custom tap repo such as:

```bash
kang-0909/homebrew-tap
```

Then users can install with:

```bash
brew tap kang-0909/tap
brew install --cask routetone
```

Use [`Casks/routetone.rb`](Casks/routetone.rb) as the cask file.  
After each new release:

1. copy the cask into your tap repo
2. update `version`
3. update `sha256`
4. push the tap repo

## Local Test

```bash
./Scripts/package-release.sh v0.1.0
```

This writes the zip and checksum into `dist/`.

## Note

The app is currently unsigned and not notarized, so macOS may show a warning on first launch.
