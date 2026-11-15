# Receipts & Payments Manager

RPM is an offline, single-user Flutter desktop application for independent MWK and USD cash ledgers. There is no account, backend, REST API, Firebase, cloud database, analytics, or runtime network service.

## Run from source

Use Flutter **3.38.6 / Dart 3.10.7** or a compatible stable release. Development requires downloading dependencies once; installed release applications do not require Flutter or an internet connection.

```sh
flutter pub get --enforce-lockfile
flutter run -d macos
# On Windows with Visual Studio's Desktop development with C++ workload:
flutter run -d windows
```

Windows targets Windows 10/11 x64. macOS targets 12.0+; Apple Silicon and Intel availability must be checked on the built bundle and tested on the target hardware. A Mac cannot compile the Windows runner; the included Windows CI job builds it on Windows.

## Using RPM

Use **Refresh** in any page header to reload saved records and balances while keeping the current page and filters. Refresh does not reset or delete data.

If the RPM folder or database has been deleted, **Refresh** recreates the folders and an empty database so you can continue using the app. This also works from the startup recovery screen. Deleted transactions require a JSON backup to restore; they are not recovered by creating a new database.

On first launch, choose **Create local ledgers** or restore an RPM JSON backup. Set each opening balance using its pencil button. Add receipts as Cash In / Debit and payments as Cash Out / Credit. Amounts accept up to two decimal places. Opening balances can be negative; transaction amounts must be positive. MWK and USD never share a balance or exchange conversion.

Transactions are ordered by transaction date, then original creation timestamp, then identifier. Same-day transactions retain their original ordering when edited. Each ledger has pagination and horizontal scrolling. Below 1120 logical pixels, the two ledgers stack vertically. Native windows enforce a minimum usable size.

Search covers description, category, amount, currency, and date. The category and inclusive date-range filters apply to table rows. Dashboard totals, closing balances, CSV exports, backups, and row running balances always represent the complete ledgers. A filter notice explains this distinction.

The sidebar opens Overview, Transactions, the separate currency ledgers, read-only category/report views, Backup & Restore, and Settings. Settings contains backup, restore, export, reset, storage details, and keyboard shortcuts. Reset requires typing the exact word `RESET`. Editing transactions, changing opening balances, deleting, restoring, and resetting require explicit confirmation.

| Shortcut | Action |
| --- | --- |
| Cmd/Ctrl + N | New transaction |
| Cmd/Ctrl + F | Focus search |
| Cmd/Ctrl + B | JSON backup |
| Cmd/Ctrl + E | CSV export |
| Cmd/Ctrl + R or F5 | Refresh saved records and balances |

The supplied design uses a dark theme, which is the default. The sun/moon button in Settings retains the previous light-theme option. The sidebar collapses from 224 px to 72 px; narrower desktop windows start with the compact rail.

## Local storage and recovery

```text
Documents/RPM/
  Database/rpm_database.sqlite
  Backups/
  Exports/
```

`path_provider` resolves the user's Documents folder. The macOS app is intentionally distributed outside the App Store without App Sandbox, so it uses the real Documents/RPM directory rather than a container's Documents directory. macOS may ask for Documents access. No networking entitlement is present in the release.

A small non-financial initialization marker and a process lock live in the operating system's Application Support directory. Financial records are never stored in preferences. This separate marker lets RPM detect deletion of the entire RPM folder on the next launch. If both the data folder and the application-support marker are manually deleted, no application can reliably distinguish that state from a first installation.

RPM verifies existing SQLite headers, schema versions, tables, and integrity before opening. Existing files are never silently replaced with a fresh database. A missing, damaged, inaccessible, or unsupported database leads to recovery. When the database is missing, choose **Refresh** to create empty ledgers, or restore a JSON backup to recover saved records. Refresh preserves orphaned SQLite journals under Backups and refuses to replace existing damaged or unsupported databases. Close RPM before manually relocating database files, and keep any `-wal`, `-shm`, and `-journal` files with their database. Refresh after restoring the original files, or use the recovery screen to import a validated JSON backup. Backup recovery preserves old database files under Backups and stages a complete replacement before activating it.

Backups and exports default to their dedicated folders, and a native save dialog allows another destination. Existing destination files are refused; choose a new filename. A verified, flushed JSON safety backup is mandatory before restore or reset. Failure to create or verify it prevents the destructive operation. Restore validates format/version, required fields, currencies, integer amounts, dates, unique IDs, duplicate content, and financial limits. It replaces both ledgers atomically; it does not merge records. Repeating a restore cannot add duplicate records.

CSV includes both currencies in separate sections, opening balances, stable record IDs, and complete running balances. Formula-like text is escaped for spreadsheet safety. Use JSON for restoration; CSV is a reporting format. The supported JSON input/output limit is 256 MB, with at most 100,000 transactions. Values and totals have explicit checked integer limits. If a backup limit is exceeded, restore/reset stops safely.

Keep independent backups on another drive. RPM cannot prevent manual file deletion, disk failure, or access by someone who controls the computer. The local database and backups are not encrypted by RPM; use operating-system disk protection when needed.

## Architecture

- `lib/features/ledger/domain`: money parsing/formatting, validation, chronological ordering, independent summaries and running balances.
- `lib/features/ledger/data`: repository with validated, transactional SQLite operations.
- `lib/core/database.dart`: Drift schema v2, v1→v2 migration, WAL, FULL synchronous commits, foreign keys, busy timeout, and integrity checks. Existing v1 databases get a consistent SQLite safety snapshot before migration.
- `lib/core/storage.dart`: initialization marker, single-process lock, missing-file detection, protected creation, and staged recovery.
- `lib/features/backup`: JSON validation, exclusive file creation, backup verification, safety backups, restore, reset, and CSV.
- `lib/features/ledger/presentation`: desktop dashboard, ledger tables, filters, dialogs, and startup/recovery.
- `lib/app`: Riverpod scopes, state refresh, and light/dark theme.

Business money is stored as integer hundredths, never floating-point currency. Individual amounts are limited to 999,999,999,999.99, and accumulated totals/running balances to 90,000,000,000,000.00. Exact duplicate content is blocked using a normalized fingerprint plus a database uniqueness constraint. The same transaction can be recorded again only when a meaningful field differs, such as a reference in its description.

The Drift generated source is included. After changing the database schema:

```sh
bash tool/generate_database.sh
```

The generator runs in `tool/codegen` to isolate its analyzer requirements from Flutter’s test SDK pins. It uses `--force-jit` for compatibility with this SDK. Versioned schema upgrades must be accompanied by migration tests; never delete an existing database to resolve a schema mismatch.

## Validation

```sh
flutter analyze
dart run test test/core_test.dart --concurrency=1
flutter test --concurrency=1
# Optional screenshots, using isolated test fixtures rather than business data:
flutter test test/widget_test.dart --concurrency=1 --dart-define=RPM_CAPTURE=true
```

Core tests cover both currencies, exact arithmetic, cash in/out, opening balances, editing, deletion, duplicate protection, persistence after close/reopen, migration, backup round trips, atomic replacement, reset, failed safety backups, CSV escaping, missing-file recovery, whole-folder deletion, corrupted-file preservation, and in-session missing-file write protection. Widget tests cover responsive light/dark screens, real transaction entry and search, and reset confirmations.

## Release packaging

```sh
# On macOS (Xcode + CocoaPods):
bash tool/release-macos.sh
# On Windows (Visual Studio C++ workload; Inno Setup 6 for installer):
powershell -ExecutionPolicy Bypass -File tool/release-windows.ps1
```

The scripts run analysis and tests before building. A repository-local `lipo` wrapper verifies each requested architecture separately to accommodate the Xcode 27 verification regression (flutter/flutter#188346); it does not bypass architecture checks. macOS packaging verifies the complete signed bundle and creates a drag-to-Applications DMG. Local ad-hoc signatures are refreshed after incremental Flutter builds; Developer ID signatures are not replaced. Windows packaging copies the app-local x64 MSVC runtime from the installed Visual Studio redistributable directory, then creates a portable ZIP containing the entire Flutter runner bundle, and an Inno Setup installer if its compiler is installed. Do not distribute only `rpm.exe`; its DLLs and data folder are required. Uninstallation does not remove Documents/RPM. CI builds both platform artifacts when this repository is hosted on GitHub.

For public distribution, sign the Windows executable/installer with the publisher's certificate and sign/notarize the macOS app with the publisher's Developer ID. Signing credentials are not included. Locally built unsigned/ad-hoc artifacts are development releases until these steps and target-machine acceptance testing are complete.

The native icon source is `assets/rpm-mark.svg`. `tool/generate_icons.py` regenerates launcher sizes using Pillow (development only).

## Copyright

© 2026 Hudeifa-janagale. All rights reserved.
