# CI/CD: Ship to TestFlight

This repo ships the iOS app to **TestFlight** automatically with GitHub Actions +
[fastlane](https://fastlane.tools).

- **Authentication** uses an **App Store Connect API key** (no Apple ID / 2FA needed in CI).
- **Code signing** uses **[fastlane match](https://docs.fastlane.tools/actions/match/)**,
  which keeps your certificates and provisioning profiles in a private, encrypted
  git repo. If you already have a match repo from another project, reuse it, one
  repo can hold credentials for many apps.

## Files

| File | Purpose |
| --- | --- |
| `.github/workflows/testflight.yaml` | The CI/CD workflow (manual trigger + on `v*` tags). |
| `ios/Gemfile` | Pins fastlane / cocoapods for reproducible builds. |
| `ios/fastlane/Fastfile` | The `beta` lane: match → build → upload. |
| `ios/fastlane/Appfile` | App identifier + team configuration. |
| `ios/fastlane/Matchfile` | match (signing repo) configuration. |

## What the pipeline does

1. Checks out the repo and sets up Flutter + Ruby.
2. `flutter pub get`.
3. Runs `fastlane beta`, which:
   - creates a temporary CI keychain (`setup_ci`),
   - loads the App Store Connect API key,
   - fetches certificates/profiles with `match` (read-only in CI),
   - picks the next build number (latest TestFlight build + 1),
   - compiles Flutter (`flutter build ios --release --no-codesign`),
   - archives + exports a signed IPA (`build_app`),
   - uploads it to TestFlight (`upload_to_testflight`).

The release notes for the TestFlight build come from `release_notes.txt`
(override with the `TESTFLIGHT_CHANGELOG` env var).

## One-time setup

### 1. Create an App Store Connect API key

App Store Connect → **Users and Access → Integrations → App Store Connect API** →
generate a key with the **App Manager** role. Download the `.p8` (you can only do
this once) and note the **Key ID** and **Issuer ID**.

Base64-encode the key so it can live in a secret:

```bash
base64 -i AuthKey_XXXXXXXXXX.p8 | pbcopy   # macOS
# base64 -w0 AuthKey_XXXXXXXXXX.p8           # Linux
```

### 2. Point match at your signing repo

If you already have a match repo, just reuse its URL and password. Otherwise,
create a new **private** git repo and initialise it once from your Mac:

```bash
cd ios
bundle install
# Generates an App Store distribution cert + profiles for both bundle ids
# and pushes them (encrypted) to MATCH_GIT_URL.
MATCH_GIT_URL="git@github.com:you/certs.git" \
  bundle exec fastlane match appstore
```

This creates profiles for both bundle identifiers used by this app:

- `com.leepo.wonders` (main app)
- `com.leepo.wonders.Wonderous-Widget` (widget extension)

> Using your own identifiers? Set `IOS_APP_IDENTIFIER` /
> `IOS_WIDGET_APP_IDENTIFIER` and `APPLE_TEAM_ID` (see overrides below) and
> register the App IDs + a TestFlight app record first.

### 3. Add GitHub secrets

**Settings → Secrets and variables → Actions → Secrets**

| Secret | Description |
| --- | --- |
| `APP_STORE_CONNECT_API_KEY_ID` | Key ID from step 1. |
| `APP_STORE_CONNECT_API_ISSUER_ID` | Issuer ID from step 1. |
| `APP_STORE_CONNECT_API_KEY_CONTENT` | Base64 of the `.p8` file. |
| `MATCH_GIT_URL` | URL of your private match (certificates) repo. |
| `MATCH_PASSWORD` | Passphrase used to encrypt the match repo. |
| `MATCH_GIT_BASIC_AUTHORIZATION` | Base64 of `username:personal_access_token` for HTTPS access to a private match repo. Omit if it's the same repo / using a token with access. |
| `APPLE_TEAM_ID` | *(optional)* Apple Developer Team ID. Defaults to `R7PC88FD6R`. |

For `MATCH_GIT_BASIC_AUTHORIZATION`:

```bash
echo -n "your-github-username:ghp_yourPAT" | base64
```

### 4. (Optional) Override the app identifiers

If you fork this for your own App Store Connect account, add **Variables**
(not secrets) under **Settings → Secrets and variables → Actions → Variables**:

| Variable | Example |
| --- | --- |
| `IOS_APP_IDENTIFIER` | `com.yourco.traveled` |
| `IOS_WIDGET_APP_IDENTIFIER` | `com.yourco.traveled.Widget` |

…and add `APPLE_TEAM_ID` as a secret. The fastlane config reads all of these
from the environment, so no code changes are required.

## Running it

- **Manually:** Actions tab → **TestFlight** → *Run workflow*. You can pass an
  optional marketing version (e.g. `2.2.3`).
- **On release:** push a tag like `v2.2.3`:

```bash
git tag v2.2.3 && git push origin v2.2.3
```

## Run it locally

```bash
cd ios
bundle install
export APP_STORE_CONNECT_API_KEY_ID=...
export APP_STORE_CONNECT_API_ISSUER_ID=...
export APP_STORE_CONNECT_API_KEY_CONTENT=$(base64 -i AuthKey_*.p8)
export MATCH_GIT_URL=...
export MATCH_PASSWORD=...
bundle exec fastlane beta
```

## Troubleshooting

- **"No profile for type 'IOSAppStore'"** — the profile isn't in the match repo
  yet. Run `bundle exec fastlane match appstore` once from your Mac (not in CI).
- **Build already exists on TestFlight** — the lane auto-bumps to *latest + 1*;
  if you hit this, pass `BUILD_NUMBER` explicitly.
- **Authentication failures** — re-check the three `APP_STORE_CONNECT_API_*`
  secrets; `APP_STORE_CONNECT_API_KEY_CONTENT` must be base64 of the `.p8`.
- **Wrong Xcode / Flutter version** — adjust the `Select Xcode` step and the
  `subosito/flutter-action` channel/version in the workflow.
