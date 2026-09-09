# OfficeSplit

A Splitwise-style expense splitter: persistent **groups** and **friends**
with a running balance across every expense over time — not a one-off
bill split.

## How it works

- **Groups** — start a group (e.g. "Office"), add people, and log expenses
  against it. The group screen shows who owes you and who you owe, updated
  live as expenses and payments are added.
- **Friends** — every friend has a running balance aggregated across every
  group and direct expense you share with them.
- **Add an expense** — description, amount, category, who paid, and how to
  split it:
  - **Equal** — split evenly among selected people
  - **Unequal** — type an exact amount per person
  - **%** — type a percentage per person
  - **Items** — itemize what was ordered and assign each item to whoever
    ordered it (shared items split evenly between assignees)
- **Settle up** — records a payment between two people; in a group, it
  suggests the fewest possible payments needed to zero out every balance
  (the classic debt-simplification algorithm).
- **Activity** — a chronological feed of every expense and payment across
  all your groups and friends.

Everything is stored on-device only — there's no account or sync, so
balances are per-install (matching how the earlier per-bill splitter
worked, just persistent across many expenses instead of one bill).

## Development

```bash
flutter pub get
flutter run
```

## Building the APK

A GitHub Actions workflow (`.github/workflows/build-apk.yml`) builds a
release APK per CPU architecture on every push and uploads them as a
workflow artifact named `officesplit-release-apk` (and as release assets).
Use `app-arm64-v8a-release.apk` for virtually any phone from the last
several years. You can also build locally:

```bash
flutter build apk --release --split-per-abi
# output: build/app/outputs/flutter-apk/app-<abi>-release.apk
```
