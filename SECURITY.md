# Security

## Scope

MuPiBox Control communicates with a user-selected MuPiBox on the local network.

## Rules

- Never commit Apple signing secrets, certificates, provisioning profiles, passwords or API tokens.
- Treat all API responses as untrusted input and decode them defensively.
- Use the server's actual admin authentication/session flow for future configuration functions.
- Do not bypass admin authentication by adding hidden/alternate mobile-only server paths.
- Store future credentials/session secrets in Keychain, not UserDefaults.
- Keep manual device addresses editable/removable.
- Do not globally disable App Transport Security; local-network exceptions should stay narrowly scoped.

Security issues should be reported privately to the repository owner rather than posted with exploit details in a public issue.
