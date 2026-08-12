---
layout: page
title: Secure RSMP
permalink: /secure/
parent: Getting Started
nav_order: 4
---

# Using Secure RSMP

The validator can run its existing site and supervisor conformance tests over the `rsmp-secure-v1` transport. Enable it when the equipment under test supports the same Secure RSMP profile and you want the test connection to be end-to-end authenticated and encrypted.

Secure mode changes the transport used by the tests. It does not select different test files, and a successful validator run is not by itself a complete cryptographic conformance assessment. The full profile and protocol details belong to the [Secure RSMP documentation in the `rsmp` gem](https://github.com/rsmp-nordic/rsmp/blob/v1/documentation/configuration.md#secure-rsmp). This page explains how to configure and use that layer with the validator.

## How it works

Before normal RSMP communication starts, the two TCP endpoints use EDHOC to authenticate their provisioned credentials and establish fresh session keys. RSMP messages are then encoded as CBOR and protected with COSE. The normal RSMP connection sequence is unchanged at the application layer: the first protected RSMP message is still `Version`, followed by the remaining startup messages.

The authenticated credential is checked against the RSMP identity and selected Core version. Traffic keys are renewed automatically during a long-lived connection. Every new TCP connection, including a reconnect requested by an isolated validator test, establishes a new secure session.

The setting depends on which side opens the TCP connection:

| Test direction | Validator's local endpoint | Validator setting | Equipment under test |
| --- | --- | --- | --- |
| Testing a site | Supervisor listening for the site | `secure.required: true` | Site initiates with `secure.enabled: true` |
| Testing a supervisor | Site connecting to the supervisor | `secure.enabled: true` | Supervisor listens with `secure.required: true` |

Mode selection is fail closed. A secure connection never falls back to legacy RSMP after a handshake failure. Both endpoints must therefore be configured for secure mode before they connect.

## Credentials

Each endpoint has two files:

| File | Purpose | Handling |
| --- | --- | --- |
| `<id>.private.key` | Local Ed25519 private key | Keep secret; never provision it to the peer |
| `<id>.cred` | Deterministic-CBOR CCS credential containing the identity and public key | Provision it to peers through an authenticated process |

There is no separate `.pub` file and no `public_key` configuration property. Pinning the peer's complete `.cred` file establishes trust in both its identity and public key.

The `rsmp` executable included in the validator bundle can generate a fresh identity. From the validator repository root, generate the identity used by the validator's local endpoint:

```console
% bundle exec rsmp secure generate --out config/private/secure --id supervisor
```

Use `supervisor` when the validator tests a site. When it tests a supervisor, generate a site identity whose subject matches `local_site.site_id`:

```console
% bundle exec rsmp secure generate --out config/private/secure --id RN+SI0001
```

The output directory is created when necessary. Existing credential files are not overwritten unless `--force` is supplied. The `config/private/` directory is ignored by Git and is suitable for local test credentials, but private keys still need appropriate filesystem protection and backup procedures.

Exchange only the credentials:

1. Give the validator endpoint's `.cred` file to the administrator of the equipment under test.
2. Obtain the equipment's `.cred` file through an authenticated channel and place it in the validator's credential directory.
3. Keep each `.private.key` file exclusively at the endpoint that owns it.

The no-argument generator creates stable test-vector identities for repeatable local examples:

```console
% bundle exec rsmp secure generate --out config/simulator/secure
```

These sample private keys are test fixtures. Do not use them with real equipment or in production.

## Testing a site

When testing a site, the validator creates the local supervisor described by `local_supervisor`. Make its listener secure-required, configure the validator supervisor's local identity, and pin the credential for every site that may connect.

The following fragment assumes commands are run from the validator repository root:

```yaml
local_supervisor:
  port: 13111
  ips: all
  max_sites: 1
  secure:
    required: true
    profile: rsmp-secure-v1
    log_decrypted_payloads: true
    private_key: config/private/secure/supervisor.private.key
    credential: config/private/secure/supervisor.cred
  sites:
    RN+SI0001:
      sxls:
        tlc: '1.2.1'
      secure:
        credential: config/private/secure/RN+SI0001.cred
        core_versions: ['3.3.0']

# The remaining validator settings are unchanged.
core_version: 3.3.0
sxls:
  tlc: '1.2.1'
```

The `sites` key must match the `siteId` sent by the equipment. Its credential subject must also identify that site. `core_versions` is optional; when present, it limits which encrypted RSMP Core version the credential is authorized to use.

Configure the site under test to:

- connect to the validator's address and `local_supervisor.port`;
- initiate `rsmp-secure-v1` without legacy fallback;
- use its own matching private key and credential; and
- trust the validator's `supervisor.cred` credential.

See `config/gem_tlc.yaml` for a complete validator configuration.

## Testing a supervisor

When testing a supervisor, the validator creates the local site described by `local_site`. Configure that site to initiate secure connections and pin the credential of the supervisor under test on its endpoint entry.

```yaml
local_site:
  type: tlc
  site_id: RN+SI0001
  supervisors:
    - ip: 127.0.0.1
      port: 13111
      secure:
        id: supervisor
        credential: config/private/secure/supervisor.cred
        core_versions: ['3.3.0']
  secure:
    enabled: true
    profile: rsmp-secure-v1
    log_decrypted_payloads: true
    private_key: config/private/secure/RN+SI0001.private.key
    credential: config/private/secure/RN+SI0001.cred

# The remaining site and validator settings are unchanged.
core_version: 3.3.0
sxls:
  tlc: '1.2.1'
```

The endpoint `secure.id` is the expected supervisor credential subject. If the supervisor's RSMP identity differs from its credential subject, use `secure.supervisor_id` for the expected RSMP identity.

Configure the supervisor under test to:

- listen on the address and port configured under `local_site.supervisors`;
- require `rsmp-secure-v1` without legacy fallback;
- use the private key corresponding to `supervisor.cred`; and
- trust the validator site's `RN+SI0001.cred` credential and authorize the same site ID.

See `config/gem_supervisor.yaml` for a complete validator configuration.

## Using secure auto nodes

Both sides must be configured when using an [auto node]({{ site.baseurl}}{% link pages/auto.md %}):

- `config/gem_tlc.yaml` configures the validator's secure supervisor, while `config/simulator/tlc.yaml` configures the auto site.
- `config/gem_supervisor.yaml` configures the validator's secure site, while `config/simulator/supervisor.yaml` configures the auto supervisor.

The supplied auto-node configurations use conventional credential paths below `config/simulator/secure/`. Generate the local test fixtures there before running them if the files are absent:

```console
% bundle exec rsmp secure generate --out config/simulator/secure
```

Run the site tests with both configurations:

```console
% bundle exec rsmp-validator run test/site \
    --site-config config/gem_tlc.yaml \
    --auto-site-config config/simulator/tlc.yaml
```

Run the supervisor tests similarly:

```console
% bundle exec rsmp-validator run test/supervisor \
    --supervisor-config config/gem_supervisor.yaml \
    --auto-supervisor-config config/simulator/supervisor.yaml
```

## Check the configuration and run tests

Validate credential paths, configuration shape, key-to-credential consistency, credential identities, and other secure settings before starting a test:

```console
% bundle exec rsmp-validator config check config/my_site_validation_config.yaml
```

Then run the normal test path. No secure-specific test-selection option is required:

```console
% bundle exec rsmp-validator run test/site \
    --site-config config/my_site_validation_config.yaml \
    --log
```

With logging enabled, the connection log identifies the secure profile and reports completion of the secure handshake before the normal RSMP messages.

Decrypted Secure RSMP payload logging is a separate local policy and defaults
to off. Set `log_decrypted_payloads: true` in the local endpoint's top-level
`secure` block when application-level payloads are needed for validator
development or diagnostics. The supplied `gem_*` and simulator configurations
set it to `true`. This permits complete decrypted messages in the local archive
and JSON logs; protect those logs and turn the setting off outside the intended
diagnostic environment. Peer credential `secure` blocks do not need the
setting.

Use absolute credential paths if the validator may be launched from different working directories. The relative paths in this page assume it is launched from the repository root, as recommended for other validator commands.

## Troubleshooting

| Symptom | What to check |
| --- | --- |
| `public_key` is a disallowed property | Remove it and configure the peer's complete `.cred` file instead. |
| A private-key or credential file is not found | Check the path and the working directory, or use an absolute path. |
| The local private key does not match the credential | Regenerate or restore the matching pair; do not combine files from different identities. |
| A secure peer credential is missing | Add the site's credential under `local_supervisor.sites.<site-id>.secure`, or the supervisor's credential under the relevant `local_site.supervisors` entry. |
| The authenticated identity is not authorized | Check the credential subject, `siteId`, endpoint `secure.id`, optional `secure.supervisor_id`, and the configured site key. |
| The negotiated Core version is rejected | Remove an unintended `core_versions` restriction or include the Core version being tested. |
| The peer sends plaintext or the handshake times out | Confirm that the initiator uses `secure.enabled: true`, the listener uses `secure.required: true`, and both sides trust the correct peer credential. |


Secure configuration errors are fail-closed. The validator does not silently downgrade the connection or ignore invalid credentials.
