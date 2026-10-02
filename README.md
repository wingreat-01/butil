# Bigasan POS

A mobile-first Flutter POS starter for a rice retailer / bigasan store in a Philippine market.

## Features
- Rice product catalog with varieties such as Regular Milled, Dinorado, Jasmine and Premium.
- Sell by kilogram or sack.
- Cart with quantity controls.
- Quick cash tender buttons and automatic change calculation.
- Low-stock warnings.
- Inventory restocking and stock deduction.
- Stock cost per kg and estimated inventory value.
- Daily sales dashboard and simple sales report.
- Transaction history.
- Receipt preview after checkout.
- Local persistence using SharedPreferences.
- Offline-first local data structure, so the prototype can continue working without internet.

## Merq patterns reused/adapted
This project intentionally follows several patterns from the supplied Merq `lib.zip`:
- Product catalog + category filtering.
- Cart state separated from UI.
- Checkout modal with cash/change calculation.
- Product stock + low-stock threshold.
- Inventory movement concept.
- Transaction history.
- Sales report with revenue/items/transactions.
- Receipt preview.
- Search/filtering.
- Dark/light-friendly Material UI structure.

## Bigasan-specific decisions
- Rice is represented in kilograms for the simplest POS workflow.
- A sack can be sold using a configurable "kg per sack" value.
- Selling a sack deducts the equivalent kilogram stock.
- Example: a 50 kg sack sale deducts 50 kg from inventory.
- Stock is stored locally for this starter; Supabase/backend can be added later.

## Run
1. Install Flutter.
2. Extract this ZIP.
3. Run:
   flutter pub get
   flutter run

The starter intentionally avoids Supabase so you can immediately test the UI and business flow.
