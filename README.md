# ExpenseSnap

ExpenseSnap is an academic receipt and expense management application built with Flutter. It connects to an n8n backend powered by Google Sheets for storage, Gemini for intelligent receipt parsing, and Telegram for automated high-expense alerts.

## Project Architecture & Organization

The codebase follows straightforward Flutter concepts (state management with `setState()`, Material design widgets, and typed models):

```
lib/
├── config.dart                     # App configuration (backend URL and API key)
├── config_local.example.dart       # Safe local secrets template (gitignored)
├── main.dart                       # Entrypoint & bottom navigation shell
├── models/
│   └── receipt.dart                # Receipt & ReceiptList models, ReceiptCategory enum
├── screens/
│   ├── capture_screen.dart         # Capture / pick receipt image (Step 2)
│   ├── review_screen.dart          # Validate and edit receipt details (Step 3)
│   └── history_screen.dart         # Browse monthly expense history (Step 4)
├── services/
│   └── n8n_service.dart            # Dio HTTP service for n8n webhooks
└── theme/
    └── app_theme.dart              # Unified professional design theme
```

## Visual Identity

- **Background:** `#F7F8FA`
- **Main Text:** `#17212F`
- **Primary Accent:** `#0D766E` (Teal)
- **Surfaces:** `#FFFFFF`
- **Borders:** `#DDE4E8`

## Backend Configuration

Backend communication uses n8n webhooks:

1. **Workflow A (Analyze):** `POST /receipts/analyze` (multipart receipt image up to 5 MB)
2. **Workflow B (Save):** `POST /receipts` (JSON receipt data)
3. **Workflow C (History):** `GET /receipts?month=YYYY-MM` (fetch expense list and monthly total)

### Passing Credentials

API authentication requires the `x-api-key` header. Pass the key at compile-time:

```bash
flutter run --dart-define=EXPENSESNAP_API_KEY=your_x_api_key_here
```

For Android Emulator (`http://10.0.2.2:5678/webhook` is configured as default):

```bash
flutter run --dart-define=EXPENSESNAP_API_KEY=your_x_api_key_here --dart-define=EXPENSESNAP_BASE_URL=http://10.0.2.2:5678/webhook
```

Alternatively, copy `lib/config_local.example.dart` to `lib/config_local.dart` (which is gitignored).

## Running Tests & Analysis

```bash
flutter analyze
flutter test
```
