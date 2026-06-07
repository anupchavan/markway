# Markway Beta Release Notes

## Distribution

Markway should ship first as a Developer ID signed and notarized macOS app outside the Mac App Store. The app needs user-granted Full Disk Access to read Apple service stores, and it also installs a user LaunchAgent for the background bridge. That shape is much better suited to direct distribution than App Store review.

Beta builds can be free and public. Later paid builds can still keep the code public: charge for the signed, notarized app, automatic updates, and support/license convenience rather than hiding the source.

## Background Agent

The app writes this user LaunchAgent when a vault is selected:

```text
~/Library/LaunchAgents/com.anupchavan.markway.agent.plist
```

The agent runs:

```text
Markway.app/Contents/Helpers/markway agent run --vault <vault> --journal-tool <bundled journal_text>
```

Logs go to:

```text
~/Library/Logs/Markway/agent.log
~/Library/Logs/Markway/agent.err
```

The agent watches the private bridge request directory and the Apple Journal group container. It does not create a socket or listen on the network.

## Updates

Sparkle is linked into the app and starts only when both update settings are present in the bundle:

```text
SUFeedURL
SUPublicEDKey
```

Debug builds leave those values empty. For release builds, provide them through build settings:

```text
MARKWAY_UPDATE_FEED_URL=https://example.com/markway/appcast.xml
MARKWAY_SPARKLE_PUBLIC_ED_KEY=<public EdDSA key>
```

Keep the Sparkle private key outside the repository and outside CI logs. Use it only when signing update archives and generating the appcast.

## Release Checklist

1. Bump `MARKETING_VERSION` and `CURRENT_PROJECT_VERSION`.
2. Build Release with Developer ID signing and Hardened Runtime.
3. Archive the app into a DMG or zip.
4. Notarize and staple the distributed artifact.
5. Generate/update the Sparkle appcast with the private EdDSA key.
6. Publish the artifact and appcast.
7. Install the release build on a clean macOS user account and confirm:
   - first launch saves a vault,
   - LaunchAgent is loaded,
   - Full Disk Access instructions are clear,
   - Obsidian plugin push/pull still works,
   - update check sees the appcast.
