# MERQ POS UI/UX V2 — Bigasan Owner Edition

This version builds on the existing MERQ POS Flutter project and focuses on fast, practical workflows for Philippine rice retailers.

## Included in this version

1. Faster selling quantities with quick 1 / 2 / 5 / 10 / 25 kg buttons.
2. Cash, GCash, and Utang payment methods.
3. Customer balance / utang tracking with payment recording.
4. Supplier and restock history, including cost per kilogram.
5. Estimated daily profit in the Sales screen.
6. Low-stock dashboard.
7. Shareable text receipts using the device share sheet.
8. Inventory value and business summary cards.
9. Existing QR ordering functionality was intentionally left untouched.
10. More Filipino/Taglish-friendly wording such as Utang, Bayad, Stock, and GCash.

## Notes

- Existing saved sales remain readable. Older sales default to Cash when no payment method was stored.
- Customer and restock data are stored locally using SharedPreferences.
- Receipt sharing uses `share_plus`.
- The project was not built in this environment because Flutter/Dart CLI is not installed here. Run `flutter pub get` and `flutter analyze` / `flutter run` in your Flutter development environment before releasing.
