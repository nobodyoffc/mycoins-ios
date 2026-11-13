# MyCoins for iOS

The iPhone client of MyCoins. Android (`~/AndroidStudioProjects/mycoins`,
React Native) and Mac (`~/MacApp/MycoinsForMac`, Tauri + React) are the two
existing clients. This one is a fork of the Android repo's React Native code
with the `android/` folder dropped and the `ios/` target finished.

## Where the code lives

- **`src/`, `App.tsx`, `__tests__/`** are the Android app's, almost unchanged.
  `Config/android-source-revision.txt` is the Android commit they were taken
  from. It is a fork, not a reference: an Android fix has to be brought over
  by hand (see below).
- **`ios/MyCoins/`** is the native shell. `AppDelegate.swift` holds the two
  things that exist only here: the privacy cover (iOS's stand-in for
  Android's `FLAG_SECURE`) and excluding Documents, where the keystore lives,
  from iCloud and computer backups (Android's `allowBackup="false"`).
- **`ios/MyCoinsUITests/`** is the walkthrough.
- **`tools/`**: `build.sh`, `walkthrough.sh`, `icon.svg` (the Mac icon made
  full-bleed and square; iOS cuts the corners itself and rejects
  transparency), `add-uitests.rb`.

## What differs from Android

- The Back tab on the Coins page locks the wallet and returns to the login
  screen, as auto-lock does. Android closes the app there; an iOS app cannot
  quit itself (`RootNavigator.tsx`).
- Argon2id runs natively (`ios/MyCoins/MCArgon2.m` over the reference C in
  `ios/MyCoins/Argon2`, the copy Freer for Mac vendors, empty salt allowed).
  The JavaScript one took about a minute on an iPhone 16; this takes about a
  second. `src/crypto/kdf.ts` uses it when it is there and falls back to
  JavaScript, which is what jest runs. `tools/check-argon2.sh` compares the
  two on the Mac, and the `testSecretKey` UI test checks a phrase's FID in
  the app. Run both after touching either.
- Every form is a `ScrollView` with `automaticallyAdjustKeyboardInsets`, and
  the Send password dialog sits in a `KeyboardAvoidingView`. Android resizes
  the window for the keyboard on its own; iOS does not. A new screen with a
  `TextInput` needs the same.
- A pushed screen's title sits beside the back arrow ("‹ Send"), through
  `pushedHeader` in `RootNavigator.tsx`. iOS would centre it, under the
  floating FID chip, and label the arrow with the previous route's name.
- Dragging a form puts the keyboard away (`keyboardDismissMode="on-drag"`):
  the number pad has no Done key and covers the tab bar.
- Settings pads a frame around its scroller for the status bar, not the
  scroller's content, or rows scroll up behind the clock.
- `react-native-view-shot` is 6.x: 4.x does not compile against React Native
  0.85 on iOS.
- The Podfile raises every pod's deployment target to 15.1; Xcode 27 refuses
  less.
- iPhone only (`TARGETED_DEVICE_FAMILY = 1`). The layouts are phone layouts.

## Taken from the Mac app

`Config/mac-source-revision.txt` is the Mac commit these came from.

- `src/utils/scan-parse.ts`: a scanned `bitcoin:…?amount=` or `ethereum:…@1`
  code fills in the amount as well as the address on Send.
- `src/utils/version.ts`: Settings > About reads the version from
  `package.json`. Keep `MARKETING_VERSION` in the Xcode project in step.
- FCH requests go through `fetchWithTimeout`; a balance refresh that finishes
  after the active key changed is discarded; a pending send is only cleared
  by a balance that was fetched successfully.

## Bringing Android changes over

For each file changed on Android since the recorded commit, three-way merge
with `git merge-file` (ours = the file here, base = the Android file at the
recorded commit, theirs = the Android file at the new commit), keep this side
of conflicts around the keyboard, the Back tab and `kdf.ts`, then update
`Config/android-source-revision.txt`. If `package.json` gained a native
module, run `pod install` and build before anything else.

## Languages

English and Simplified Chinese, from the app's own tables in
`src/i18n/strings`; `src/i18n/locale.ts` reads the system language. The
permission prompts are in `ios/MyCoins/Info.plist` (English) and
`ios/MyCoins/zh-Hans.lproj/InfoPlist.strings`.

## Build and check

    tools/build.sh                 # Release simulator build; prints errors and the verdict
    tools/walkthrough.sh <simulator-udid> <shots-dir>
    npm test

The walkthrough is a UI test that removes the app, makes an account, opens a
coin, Send and Receive, and every tab, and saves a screenshot and an element
dump of each — the way to see a layout change on a phone. Run it after
touching a screen. `xcrun simctl list devices` gives a UDID. Give it a simulator nothing
else is using: another app coming to the front mid-run breaks the walk.
Keys has no tab; the walk opens it from the FID chip, as a user does.

The two `*-integration` test suites need an FCH API server at
`localhost:8081` and fail without one. Metro's default port is also 8081, so
on this machine start it with `npm start -- --port 8082`.

Bundle id `com.mycoins.wallet.ios`, team `5768V787GP`, automatic signing.
