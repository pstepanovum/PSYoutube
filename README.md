# PSYoutube
**YouTube that respects your time.**\
`Version v0.1.0` | `Tested on YouTube 21.40.5`

PSYoutube is an iOS tweak for the YouTube app: background playback with the screen locked, no ads, and automatic skipping of sponsor segments with [SponsorBlock](https://sponsor.ajay.app). The recommendation feed and the Shorts feed are gone too, so YouTube is for the videos you came for.

Sister projects: [PSInstagram](https://github.com/pstepanovum/PSInstagram), [PSLinkedIn](https://github.com/pstepanovum/PSLinkedIn) and [PSSoundcloud](https://github.com/pstepanovum/PSSoundcloud), the same idea for other apps.

---

## What you get
- **Background playback**: audio keeps playing when you leave the app or lock the screen
- **No ads**: video ads are never loaded, and promoted items are removed from feeds
- **SponsorBlock**: sponsor segments, self-promotion and "like and subscribe" reminders are skipped automatically (intros, outros, previews, filler and non-music sections can be turned on too). A small notice shows what was skipped, and each segment is skipped once per video, so you can rewind into it
- **Privacy-friendly lookups**: only the first 4 characters of the video ID's SHA-256 hash are sent to SponsorBlock
- **No Home feed**: the Home tab is removed and the app opens on Subscriptions
- **No Shorts feed**: the Shorts tab and shelves are removed. A Short you open from a link still plays, but you can't scroll to the next one
- **No rabbit holes**: no list of recommended videos under the one you're watching (the description and comments stay), recommended videos don't autoplay when a video ends (playlists still continue), end screen cards are hidden, and nothing shows under the search bar until you type
- **No upsells or upload button**: "Get Premium" buttons, Premium promo bars and the + (upload) button are hidden
- **Google sign-in works** on a re-signed install
- **Settings that don't slip**: strict defaults, backed up to the iOS keychain and restored after a reinstall

## Opening the settings
- **You → Settings → PSYoutube**, or
- Hold **four fingers** anywhere on the screen for a second

## Installing
PSYoutube is sideloaded: you inject it into a decrypted YouTube IPA and sign that with your own certificate. It gets its own bundle ID (`com.pstepanovum.psyoutube`), so it installs next to the official YouTube app.

### Prerequisites
- Xcode with the command-line tools, and [Homebrew](https://brew.sh)
- [Theos](https://theos.dev/docs/installation) with the iOS 16.2 SDK in `~/theos/sdks` ([SDKs](https://github.com/xybp888/iOS-SDKs))
- [cyan](https://github.com/asdfzxcvbn/pyzule-rw) and [zsign](https://github.com/zhlynn/zsign)
- A decrypted YouTube IPA

> [!NOTE]
> Newer Theos versions ship a Logos change that breaks `%orig` inside macros. Pin Logos to the last working commit:
> ```sh
> cd ~/theos/vendor/logos && git checkout a62370066a97e36d59b200a9fa10c5091f5e8972
> ```

### Setup
```sh
git clone --recurse-submodules https://github.com/pstepanovum/PSYoutube
cd PSYoutube
mkdir -p packages certs
```
Then add:
- `packages/com.google.ios.youtube.ipa`: the decrypted YouTube IPA
- `certs/dev.p12`: your signing certificate
- `certs/dev.mobileprovision`: its provisioning profile
- `certs/p12-password`: the certificate password

`packages/` and `certs/` are ignored by git.

### Build, sign and install
With your iPhone connected:
```sh
./dev.sh              # build, sign and install
./dev.sh --clean      # full rebuild first
./dev.sh --no-install # only create packages/PSYoutube-signed.ipa
BUNDLE_ID=com.example.youtube ./dev.sh   # use a different bundle ID
```

`dev.sh` signs with a minimal set of entitlements taken from your profile, because some reseller profiles contain malformed wildcard entitlements that crash apps.

## Known limitations
- **Updating over an existing install can fail**, in which case `dev.sh` reinstalls it. Your PSYoutube settings come back from the keychain, but you may need to sign in to YouTube again.
- **Some Premium offers can still show**, such as the "Try YouTube Premium" row on the You page.
- **App extensions are removed** (share sheet, widgets, rich notifications).
- **Use at your own risk.** Modified clients are against YouTube's terms of service.

## Credits
- [YouTubeHeader](https://github.com/PoomSmart/YouTubeHeader) by PoomSmart (MIT): headers for the YouTube app's classes
- [SponsorBlock](https://sponsor.ajay.app) by Ajay Ramachandran and contributors: segment data, licensed under [CC BY-NC-SA 4.0](https://creativecommons.org/licenses/by-nc-sa/4.0/)
- The settings screen and sideloading fixes come from [PSInstagram](https://github.com/pstepanovum/PSInstagram), a fork of [SCInsta](https://github.com/SoCuul/SCInsta) by SoCuul. See [NOTICE](NOTICE).

Bundled libraries:
- [FLEXing](https://github.com/SoCuul/FLEXing) / [FLEX](https://github.com/FLEXTool/FLEX): in-app debugging
- [fishhook](https://github.com/facebook/fishhook): symbol rebinding for the keychain fixes

## License
[GNU General Public License v3.0](LICENSE)
