# OfficeSplit

Split a shared bill (office lunch, snacks, anything) by what each person
actually ordered — not an equal split.

## How it works

1. **People** — add everyone who was there and mark who paid the bill.
2. **Items** — add each ordered item with its price and tap who it belongs
   to (an item can be assigned to more than one person, split evenly
   between them).
3. **Charges** — add tax %, tip %, or any other flat charges (delivery,
   packaging). These are spread across everyone in proportion to what they
   ordered.
4. **Summary** — see exactly who owes the payer, save the split to history,
   or share a formatted breakdown via WhatsApp/SMS/email.

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
