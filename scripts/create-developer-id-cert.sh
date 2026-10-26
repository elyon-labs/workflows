#!/usr/bin/env bash
#
# Mints the Elyon Labs Developer ID Application certificate and stores it in
# the match repository, for Mac apps distributed outside the App Store.
#
# There is one such certificate for the whole team — every Elyon Labs Mac app
# signs with it — so this is run once and then not again until it expires. A
# release only ever reads it back with `match(readonly: true)`; nothing in a
# pipeline should create one.
#
# It lives here rather than in any one app's deployment repository for that
# reason: the certificate is not Arkie's or Lumy's, it is the team's.
#
# Authentication is an Apple ID session rather than an App Store Connect API
# key. That is not a preference: Apple accepts no API key for a Developer ID
# certificate, only the Account Holder's username and password. Expect a 2FA
# prompt. Any API key variables already in the environment are cleared below
# so fastlane cannot quietly pick them up and fail halfway.
#
# Nothing is stored here. The certificate and its private key go to the match
# repository encrypted with MATCH_PASSWORD; losing that passphrase means
# losing the certificate.
#
# Usage: create-developer-id-cert.sh [bundle-identifier]
set -euo pipefail

# The prompts below and fastlane's 2FA challenge both need a terminal on
# stdin. Without one, bash suppresses a read's prompt and the read fails at
# once on EOF, so an unguarded run exits having printed nothing at all.
if ! [[ -t 0 ]]; then
  cat >&2 <<'MSG'
This script needs a terminal: it prompts for credentials, and fastlane will
ask for a 2FA code. Run it directly from Terminal or iTerm rather than
through a tool that captures output.
MSG
  exit 1
fi

ask() {
  local __var="$1" __message="$2" __value
  [[ -n "${!__var:-}" ]] && return 0
  if [[ "${3:-}" == "silent" ]]; then
    read -r -s -p "$__message" __value
    echo
  else
    read -r -p "$__message" __value
  fi
  printf -v "$__var" '%s' "$__value"
}

# The team and its signing repository are the same whichever app is being set
# up; the bundle identifier is not, and has no sensible default.
export FASTLANE_TEAM_ID="${DEVELOPER_PORTAL_TEAM_ID:-RBWS9CUVG4}"
export MATCH_GIT_URL="${MATCH_GIT_URL:-git@github.com:elyon-labs/elyon-labs-signing.git}"
export MATCH_GIT_BRANCH="${MATCH_GIT_BRANCH:-master}"
export MATCH_STORAGE_MODE=git
export MATCH_PLATFORM=macos

# fastlane reaches for these before it considers an Apple ID, and a partial
# set is worse than none.
unset APP_STORE_CONNECT_API_KEY_KEY APP_STORE_CONNECT_API_KEY_KEY_ID \
      APP_STORE_CONNECT_API_KEY_ISSUER_ID FASTLANE_SESSION || true

MATCH_APP_IDENTIFIER="${1:-${APP_IDENTIFIER:-${MATCH_APP_IDENTIFIER:-}}}"
ask MATCH_APP_IDENTIFIER "Bundle identifier (e.g. com.elyon-labs.cs2-rcon-client): "
export MATCH_APP_IDENTIFIER

MATCH_USERNAME="${APPLE_ID:-${MATCH_USERNAME:-}}"
ask MATCH_USERNAME "Apple ID (must be the team's Account Holder): "
export MATCH_USERNAME

ask MATCH_PASSWORD "match passphrase: " silent
export MATCH_PASSWORD

cat <<SUMMARY

  Apple ID    $MATCH_USERNAME
  Team        $FASTLANE_TEAM_ID
  App         $MATCH_APP_IDENTIFIER
  match repo  $MATCH_GIT_URL ($MATCH_GIT_BRANCH)

  This creates a NEW Developer ID Application certificate on the portal.
  Apple caps how many a team may hold at once; if the portal is already at
  the cap, \`fastlane match nuke developer_id\` frees the slots by revoking
  what is there — which invalidates anything signed with it that has not
  been notarised, so look at the existing certificates first:
  https://developer.apple.com/account/resources/certificates

  If the certificate already exists, this fetches it rather than making a
  second one, and installs it into the keychain.

SUMMARY

read -r -p "Continue? [y/N] " confirm
[[ "$confirm" == [yY] ]] || { echo "Nothing done."; exit 1; }

# Run from an empty directory so fastlane reads the configuration above and
# not some Matchfile belonging to whatever project the shell happens to be
# sitting in.
work="$(mktemp -d)"
trap 'rm -rf "$work"' EXIT
cd "$work"

fastlane match developer_id --verbose

echo
echo "==> Signing identities now available:"
security find-identity -v -p codesigning | grep "Developer ID Application" || {
  echo "No Developer ID Application identity found — match reported success but"
  echo "the certificate did not land in the keychain."
  exit 1
}
