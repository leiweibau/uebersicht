# Release Notes

Date: 2026-03-05

## Summary
- Modernized and stabilized the app/runtime stack to work reliably with current macOS/Xcode toolchains.
- Fixed desktop widget rendering regressions caused by client/runtime API mismatches.
- Removed obsolete update menu flow (`Check for Updates`) from the app menu.
- Added complete German localization for menu and preferences UI.
- Improved preferences layout sizing/alignment for longer localized labels.
- Cleaned non-build artifacts from the workspace (removed temporary screenshot files).

## Technical Changes
- Hardened internal request/proxy handling to avoid forbidden-origin behavior and restore local API access from widgets.
- Fixed client-side async request handling that caused runtime errors (`...timeout` on undefined) and prevented widgets from loading.
- Refactored menu insertion logic to avoid reliance on removed update menu entry.
- Added localization resources and wiring in Xcode project for `de` language assets.
- Added runtime localization pass in preferences controller to ensure UI labels are localized consistently.

## Subcomponent Version Updates
- CocoaPods:
  - `SocketRocket` -> `0.5.1`
  - `CocoaPods` toolchain lock -> `1.16.2`
- Server/runtime dependencies (selected):
  - `superagent` -> `^10.3.0`
  - `react` -> `^19.2.4`
  - `react-dom` -> `^19.2.4`
  - `redux` -> `^5.0.1`
  - `browserify` -> `^17.0.1`
  - `@babel/core` -> `^7.29.0`
  - `@babel/preset-env` -> `^7.29.0`

## Build/Release Artifact
- Built successfully with:
  - `xcodebuild -workspace Uebersicht.xcworkspace -scheme Uebersicht -configuration Release CODE_SIGNING_ALLOWED=NO CODE_SIGNING_REQUIRED=NO build`
- Release package generated:
  - `release/Uebersicht-1.6.0-2026-03-05.zip`
