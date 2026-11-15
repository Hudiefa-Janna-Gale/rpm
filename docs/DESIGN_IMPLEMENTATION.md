# RPM design implementation

The six supplied JPG exports are the visual references: Financial overview, Transactions, New transaction, Settings, Component library, and Foundations & Flutter contract. No live Figma file or interactive URL was supplied. The exports' text describes the prototype; it is not an instruction to seed or replace financial records.

## Presentation system

- `lib/design/tokens.dart`: supplied dark colors, 4 px spacing rhythm, 40 px controls, 56 px transaction rows, 8 px control corners, 12 px surfaces, 120/80/200 ms interaction durations, and desktop insets.
- `lib/design/widgets`: shared buttons, labeled inputs, checked dropdown options, date picker, expanded/collapsed sidebar, surfaces, headers, banners, empty states and dialog frame.
- `lib/app/theme.dart`: Inter typography, focused/hovered/invalid/disabled inputs, popup menus, tables and calendar styling. Inter is bundled in assets with its OFL license. No font request occurs at runtime.
- `presentation/desktop_actions.dart`: existing repository/file operations are coordinated outside the layout widgets.
- `presentation/transaction_table.dart`: shared chronological ledger and management rows, right-aligned tabular money, menu actions, vertical scrolling, pagination and horizontal scrolling when needed. Monetary columns expand to fit large values.

The four supplied sample screens are implemented first. MWK and USD pages reuse the ledger component. Backup & Restore reuses the settings action rows. Categories and Reports are small, read-only compositions of the existing category names and all-time summaries; no category tables, report models, exchange conversion, or speculative workflows were added.

At 1280 px the expanded rail is 224 px with a 24 px page inset. At 1440 px and above the inset is 32 px. The collapsed rail is 72 px. Windows below 1100 px start compact; users can toggle the rail. Cards and filters wrap, ledgers stack when needed, and tables retain their own scroll region. Keyboard focus is visible; Tab/Enter/Space operate controls and Escape cancels dialogs.

The dark palette is defined by the supplied design. The previous light-theme capability is retained as a compatibility mode in Settings; the references do not define a separate light design.

## Preserved behavior

The database schema, migrations, local storage, backup format, repository, money calculations and data models are unchanged. The UI calls the same local APIs. Existing safeguards remain: explicit edit/delete/opening confirmations, validated restoration, mandatory verified safety backups for restore/reset, and typing RESET before clearing data.

The existing model requires descriptions, so the new form retains that validation and explains it in the helper text. The original cash-in default and stable identifiers/timestamps are preserved. New category names are persisted with a saved transaction; cancelling their dialog does not create records.

The reference's MWK 344.00 payment exists only as an isolated screenshot fixture. Tests use a temporary directory and an in-memory SQLite database. They do not open or modify Documents/RPM.

## Verification

```sh
flutter analyze
flutter test --concurrency=1 --dart-define=RPM_CAPTURE=true
bash tool/release-macos.sh
```

Rendered images are written to `artifacts/design-*.png`. The design tests exercise sample screens, all navigation destinations, collapse/expand, four window sizes, real transaction entry/edit/delete, opening balances, categories, calendar selection, filters, sorting, pagination, temporary-file backup/export/restore, typed reset, failed-backup protection, light compatibility and button interaction states. The existing financial, database and recovery tests remain in the suite.
