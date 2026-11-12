# MyCoins for iOS

MyCoins for iPhone: a multi-coin wallet for FCH, BTC, DOGE, ETH and ERC-20
tokens (USDT, USDC), with password-encrypted keys kept on the device.

This is the third MyCoins client, beside [MyCoins for Android](https://github.com/nobodyoffc/MyCoins)
and [MyCoins for macOS](https://github.com/nobodyoffc/MycoinsForMac). It is the
Android app's React Native code with an iOS target, plus a few things taken
from the Mac app.

## Building

Needs Xcode 16 or later, Node 22.11 or later and CocoaPods.

    npm install
    cd ios && pod install && cd ..
    tools/build.sh                 # simulator build, JavaScript bundled in

Or open `ios/MyCoins.xcworkspace` in Xcode. A Debug build loads its JavaScript
from Metro (`npm start`); a Release build carries it.

    npm test                       # crypto, keystore and transaction tests

`CLAUDE.md` describes how the project is organised and how it follows the
Android app.
