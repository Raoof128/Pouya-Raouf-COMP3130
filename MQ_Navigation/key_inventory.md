# Translation Key Inventory

## Source
- Web: `locales/<lang>/translations.json` (flat JSON, 300+ keys per locale)
- Flutter: `lib/app/l10n/app_<lang>.arb` (ARB format with `@@locale` header)

## Supported Locales (35)

| Code | Language | RTL | Status |
|------|----------|-----|--------|
| en | English | No | Template (done) |
| ar | Arabic | **Yes** | Converted |
| fa | Persian (Farsi) | **Yes** | Converted |
| he | Hebrew | **Yes** | Converted |
| ur | Urdu | **Yes** | Converted |
| bn | Bengali | No | Converted |
| cs | Czech | No | Converted |
| da | Danish | No | Converted |
| de | German | No | Converted |
| el | Greek | No | Converted |
| es | Spanish | No | Converted |
| fi | Finnish | No | Converted |
| fr | French | No | Converted |
| hi | Hindi | No | Converted |
| hu | Hungarian | No | Converted |
| id | Indonesian | No | Converted |
| it | Italian | No | Converted |
| ja | Japanese | No | Converted |
| ko | Korean | No | Converted |
| ms | Malay | No | Converted |
| ne | Nepali | No | Converted |
| nl | Dutch | No | Converted |
| no | Norwegian | No | Converted |
| pl | Polish | No | Converted |
| pt | Portuguese | No | Converted |
| ro | Romanian | No | Converted |
| ru | Russian | No | Converted |
| si | Sinhala | No | Converted |
| sv | Swedish | No | Converted |
| ta | Tamil | No | Converted |
| th | Thai | No | Converted |
| tr | Turkish | No | Converted |
| uk | Ukrainian | No | Converted |
| vi | Vietnamese | No | Converted |
| zh | Chinese | No | Converted |

## Conversion Process
Run `dart tools/convert_i18n.dart` to convert all JSON files to ARB format.

## Key Naming Convention
Web JSON keys are camelCase (e.g. `todoList`, `addTodo`). ARB keys use the same convention.
Keys containing dots or special characters are flattened (e.g. `auth.login` → `authLogin`).
