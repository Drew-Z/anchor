# Technical Model Acceptance Record

This is the sanitized technical acceptance record for the signed formal-ID
candidate `1.0.0+2005`. It contains no API key, response text, request ID,
private device identifier, or user data.

## Artifact

- Product: `Anchor Learning / 锚学`
- Candidate version: `1.0.0+2005`
- Flutter build number: `2005`
- Arm64 split APK manifest versionCode: `4005`
- APK: `build/app/outputs/flutter-apk/app-arm64-v8a-release.apk`
- APK bytes: `26,272,915`
- APK SHA-256: `74dcfb95cd9c123b51d9b35678ffd0153d23654bf6a5597de1070880d667207b`
- Signing: Anchor Learning release certificate, APK Signature Scheme v2 verified
- Certificate SHA-256: `7efa706af7e897411aac4a240c98be3cc2f672c82c90f55a515d7db30ab9fd35`
- ABI: `arm64-v8a`

## Runtime

- Device class: physical Arm64 Android device
- Device model: OnePlus PGP110
- Android API: `35`
- Device smoke: install, cold start, process liveness, and PID-filtered log scan passed
- Log error matches: `0`

## Exact Profile

- Provider id: `custom_grok_primary`
- Sanitized endpoint: `https://api.maoyulin.xyz/v1`
- Protocol: `chat_completions`
- Requested model: `grok-4.6`
- Gateway model: `grok-4.6`
- Credential scope: participant-owned for this technical run; not recorded as a controlled release credential
- Profile fingerprint: `a8cfa8bca5eb59e87a45da8e63dd60244493a5392d451a4c15c7db8206ece4c4`

The fingerprint is SHA-256 of the canonical string
`custom_grok_primary|https://api.maoyulin.xyz/v1|grok-4.6|chat_completions`.

## Fixed Matrix

The signed App's normal Dart/Dio path completed all five fixed tasks:

| Case | Result |
| --- | --- |
| Structured JSON | passed |
| Chinese regulated verse | passed |
| Dart function and two fixed examples | passed |
| Claim and citation binding | passed |
| Evidence-insufficient refusal | passed |

- Overall result: `5/5 passed`
- Wall-clock time shown by App: `117.3 seconds`
- Total tokens shown by App: `8,325`
- Cost: not recorded because no verifiable public unit price was available
- Acceptance observation time: `2026-08-26T02:05:03.5800330Z`

An earlier attempt while the device had no network was superseded by this
successful connected run. The earlier gateway credential wording must not be
used as evidence that the credential itself was invalid.

## Release Boundary

This record binds the technical five-task result to the exact signed release
APK. The API key was removed from device secure storage after evidence capture.
It does not prove controlled-credential governance, assign a data-processing
owner, or complete the ten-person cohort. Readiness remains `HOLD` until those
external records exist.
