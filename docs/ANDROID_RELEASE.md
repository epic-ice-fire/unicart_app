# Publishing UniCart on Google Play

Everything in the repo is ready. These are the steps only you can do (they need
your identity, your payment card and your signing key).

## 1. Create the Play developer account (once)
1. Go to https://play.google.com/console and sign up. One-time fee: **US$25**.
2. Choose **Personal** (or **Organization** if you have a registered company; organizations skip the 14-day test below, but need a D-U-N-S number).
3. Verify your identity (ID + phone). This can take a few days.

## 2. Create your signing key (once, keep it safe)
Run this on any computer with Java installed (Android Studio includes it):

```bash
keytool -genkeypair -v -keystore upload-keystore.jks -storetype JKS \
  -keyalg RSA -keysize 2048 -validity 10000 -alias upload
```

Remember the passwords you choose. **Back up `upload-keystore.jks` somewhere
safe (not in GitHub).** If you lose it you can still recover through Google
("Play App Signing" lets Google reset the upload key), but it is a hassle.

Turn the file into text for GitHub:

```bash
base64 -w0 upload-keystore.jks     # Linux / Git Bash on Windows
# PowerShell:  [Convert]::ToBase64String([IO.File]::ReadAllBytes("upload-keystore.jks"))
```

## 3. Add four secrets to GitHub
Repo -> Settings -> Secrets and variables -> Actions -> New repository secret:

| Name | Value |
| --- | --- |
| `ANDROID_KEYSTORE_BASE64` | the long base64 text from step 2 |
| `ANDROID_KEYSTORE_PASSWORD` | the keystore password |
| `ANDROID_KEY_ALIAS` | `upload` |
| `ANDROID_KEY_PASSWORD` | the key password |

## 4. Build the signed bundle
Repo -> Actions -> **Build UniCart Play Store bundle** -> Run workflow.
When it finishes, download the artifact `unicart-play-store-aab` and unzip it:
`app-release.aab` is the file Google Play wants.

For later updates: raise the number after the `+` in `pubspec.yaml`
(`version: 1.0.0+1` -> `1.0.1+2`). **Every upload needs a higher build number.**

## 5. Create the app in Play Console
1. **Create app**: name *UniCart*, default language English, App, Free.
2. Complete **App content** (all sections must be green):
   - **Privacy policy URL**: host `docs/PRIVACY_POLICY.md` as a public web page (for example a GitHub Pages page or a page on your site) and paste the link. Have it reviewed first; it is a draft.
   - **App access**: the app needs a login, so give Google a **working test account** (an email and password, already verified so reviewers can see the lobby). Create it in the app first.
   - **Ads**: No.
   - **Content rating**: fill the questionnaire (no violence, no user-generated media; it is a shopping app).
   - **Target audience**: 18+ (or 13+ if you prefer; do not select "children").
   - **Data safety**: see the table below.
   - **Financial features / payments**: you sell physical goods through Flutterwave, so you do not need Google Play Billing.
   - **Account deletion**: the app has a "Delete my account" button, and your privacy policy states how deletion works. In the Data safety form, paste the web link to the deletion instructions (the same policy page, section "Deleting your data").
3. **Store listing**: use the files in `docs/play-store/`
   - App icon: `icon-512.png`
   - Feature graphic: `feature-graphic-1024x500.png`
   - Phone screenshots: take **at least 2** (ideally 4 to 8) on your phone, for example the login screen, the lobby and the items list.
   - Short description (80 chars): *Join campus group buys, pay once, and track every batch.*
   - Full description: explain how a lobby works (join, add items, hit the target, batch ships), and mention Temu and SHEIN as example stores only in plain text.

### Data safety answers (match the privacy policy)
| Data | Collected | Shared | Why |
| --- | --- | --- | --- |
| Email address | Yes | No | Account, verification, receipts |
| Phone number | Yes | No | Delivery contact |
| Name | No | | |
| Purchase history | Yes | No | Items and payments in your lobby |
| Payment info | No (card details go straight to Flutterwave) | | |
| App activity / campus choice | Yes | No | Analytics |
| Device or other IDs | No | | |
Data is encrypted in transit (HTTPS). Users can request deletion.

## 6. Test, then go live
Because your developer account is new (created after 13 Nov 2023) Google
requires a **closed test** first:
1. Play Console -> Testing -> **Closed testing** -> create a track -> upload `app-release.aab`.
2. Add **at least 12 testers** (their Gmail addresses; classmates are ideal) and share the opt-in link.
3. The 12 testers must stay opted in for **14 days in a row**.
4. Then click **Apply for production** on the dashboard and answer the short form (what testers said, what you fixed).
5. Review usually takes up to ~7 days. After approval, create a **Production** release with the same bundle.

Rule of thumb: plan on **about 3 weeks** from account creation to the app being live.

## Notes
- **Application ID** `com.unicart.app` becomes permanent after your first upload.
- The app targets Android 16 (API 36) as Google now requires for new apps.
- Payments open Flutterwave in the phone's browser. After paying, the app refreshes the status automatically when the user comes back to it.
- Debug builds talk to `http://localhost:8000`; release builds use the live API.
