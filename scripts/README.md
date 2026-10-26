# scripts

Automation that belongs to the organisation rather than to any one project,
and that is run by hand rather than by a pipeline.

The rest of this repository is reusable GitHub Actions workflows. These are
not that: they are things done once, from a laptop, usually because Apple or
GitHub will not accept a machine credential for them.

## `create-developer-id-cert.sh`

Mints the Developer ID Application certificate that Elyon Labs Mac apps
distributed outside the App Store are signed with, and stores it in the
`elyon-labs-signing` match repository.

```sh
./scripts/create-developer-id-cert.sh com.elyon-labs.cs2-rcon-client
```

There is one certificate for the whole team, so this is run once and then not
again until it expires — a release reads it back with `match(readonly: true)`
and never creates one. Two things make it manual rather than a workflow:
Apple only accepts the Account Holder's username and password for a Developer
ID certificate, never an API key, and it caps how many a team may hold at
once, so creating them automatically is a way to run out.

It needs a terminal, for the prompts and for the 2FA challenge, and the match
passphrase. Everything else it either defaults or asks for.
