# Markway Release Workflow

## App Repository

Push the Markway app repository with:

- `.github/workflows/release.yml`
- `Apps`
- `Docs`
- `Scripts`
- `Sources`
- `Tests`
- `Vendor/AppleJournalCRDT/tools`
- `.gitignore`
- `Package.swift`
- `Package.resolved`
- `project.yml`
- `README.md`
- `TODO.md`

Do not commit generated folders such as `.build`, `build`, `dist`, `DerivedData`, `xcuserdata`, or `Vendor/AppleJournalCRDT/.build`.

## Required Release Secrets

The workflow can create unsigned DMGs without secrets. For public beta distribution, configure these GitHub repository secrets so releases are Developer ID signed and notarized:

- `APPLE_CERTIFICATE_BASE64`: base64-encoded Developer ID Application `.p12`
- `APPLE_CERTIFICATE_PASSWORD`: password for the `.p12`
- `KEYCHAIN_PASSWORD`: temporary CI keychain password
- `APPLE_TEAM_ID`: Apple Developer Team ID
- `DEVELOPER_ID_APPLICATION`: signing identity, for example `Developer ID Application: Your Name (TEAMID)`
- `APPLE_ID`: Apple ID email used for notarization
- `APPLE_APP_SPECIFIC_PASSWORD`: app-specific password for notarization

Optional Sparkle update secrets:

- `MARKWAY_UPDATE_FEED_URL`
- `MARKWAY_SPARKLE_PUBLIC_ED_KEY`

## Creating A Release

Create and push a tag:

```zsh
git tag v0.1.0
git push origin v0.1.0
```

The workflow builds two draft release artifacts:

- `Markway-v0.1.0-arm64.dmg`
- `Markway-v0.1.0-x86_64.dmg`

The architecture-specific GitHub runners are chosen so the bundled Journal helper is built natively for each Mac family.
