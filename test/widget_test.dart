import 'dart:io';
import 'dart:ui' as ui;
import 'package:drift/drift.dart' show driftRuntimeOptions;
import 'package:drift/native.dart';
import 'package:file_selector_platform_interface/file_selector_platform_interface.dart';
import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:rpm/app/providers.dart';
import 'package:rpm/app/theme.dart';
import 'package:rpm/core/database.dart';
import 'package:rpm/core/storage.dart';
import 'package:rpm/design/widgets/button.dart';
import 'package:rpm/design/widgets/fields.dart';
import 'package:rpm/design/tokens.dart';
import 'package:rpm/design/widgets/sidebar.dart';
import 'package:rpm/features/backup/backup_service.dart';
import 'package:rpm/features/ledger/data/ledger_repository.dart';
import 'package:rpm/features/ledger/domain/ledger.dart';
import 'package:rpm/features/ledger/presentation/desktop_screen.dart';
import 'package:rpm/features/ledger/presentation/startup.dart';
import 'cases/ledger_cases.dart' show entry;

class _RefreshRepository extends LedgerRepository {
  bool failLoad = false;
  _RefreshRepository(super.database);
  @override
  Future<LedgerSnapshot> load() async {
    if (failLoad) {
      throw StateError('Saved records could not be read. Please retry.');
    }
    return super.load();
  }
}

class _Picker extends FileSelectorPlatform {
  String? savePath, openPath;
  SaveDialogOptions? lastSaveOptions;
  @override
  Future<FileSaveLocation?> getSaveLocation({
    List<XTypeGroup>? acceptedTypeGroups,
    SaveDialogOptions options = const SaveDialogOptions(),
  }) async {
    lastSaveOptions = options;
    return savePath == null ? null : FileSaveLocation(savePath!);
  }

  @override
  Future<XFile?> openFile({
    List<XTypeGroup>? acceptedTypeGroups,
    String? initialDirectory,
    String? confirmButtonText,
  }) async => openPath == null ? null : XFile(openPath!);
}

class _ThemeShell extends ConsumerWidget {
  final Widget child;
  final Brightness? forced;
  const _ThemeShell({required this.child, this.forced});
  @override
  Widget build(BuildContext context, WidgetRef ref) => MaterialApp(
    debugShowCheckedModeBanner: false,
    theme: rpmTheme(Brightness.light),
    darkTheme: rpmTheme(Brightness.dark),
    themeMode: forced == null
        ? ref.watch(themeProvider)
        : forced == Brightness.dark
        ? ThemeMode.dark
        : ThemeMode.light,
    home: child,
  );
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  driftRuntimeOptions.dontWarnAboutMultipleDatabases = true;
  setUpAll(() async {
    final font = FontLoader('Inter')
      ..addFont(rootBundle.load('assets/fonts/Inter.ttf'));
    await font.load();
    final icons = FontLoader('MaterialIcons')
      ..addFont(rootBundle.load('fonts/MaterialIcons-Regular.otf'));
    await icons.load();
  });
  late RpmDatabase db;
  late LedgerRepository repo;
  late Directory temp;
  late AppStorage storage;
  late _Picker picker;
  late FileSelectorPlatform originalPicker;
  final captureKey = GlobalKey();
  var mounts = 0;
  setUp(() async {
    temp = await Directory.systemTemp.createTemp('rpm-design-test-');
    storage = AppStorage(
      root: Directory('${temp.path}/RPM'),
      support: Directory('${temp.path}/Support'),
    );
    await storage.backups.create(recursive: true);
    await storage.exports.create(recursive: true);
    db = RpmDatabase(NativeDatabase.memory());
    repo = LedgerRepository(db);
    await repo.load();
    originalPicker = FileSelectorPlatform.instance;
    picker = _Picker();
    FileSelectorPlatform.instance = picker;
  });
  tearDown(() async {
    FileSelectorPlatform.instance = originalPicker;
    await db.close();
    await temp.delete(recursive: true);
  });
  Finder button(String label) => find.widgetWithText(RpmButton, label);
  Future<void> mount(
    WidgetTester tester, {
    Size size = const Size(1440, 900),
    Brightness? brightness,
  }) async {
    tester.view.physicalSize = size;
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
    await tester.pumpWidget(
      ProviderScope(
        child: RepaintBoundary(
          key: captureKey,
          child: _ThemeShell(
            forced: brightness,
            child: ProviderScope(
              overrides: [
                storageProvider.overrideWithValue(storage),
                repositoryProvider.overrideWithValue(repo),
              ],
              child: DesktopScreen(
                key: ValueKey(++mounts),
                onRecover: () async {},
              ),
            ),
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();
  }

  Future<void> navigate(WidgetTester tester, String label) async {
    await tester.tap(find.text(label).first);
    await tester.pumpAndSettle();
  }

  Future<void> capture(WidgetTester tester, String name) async {
    if (!const bool.fromEnvironment('RPM_CAPTURE')) return;
    await tester.runAsync(() async {
      final boundary =
          captureKey.currentContext!.findRenderObject()!
              as RenderRepaintBoundary;
      final image = await boundary.toImage();
      final bytes = await image.toByteData(format: ui.ImageByteFormat.png);
      final file = File('artifacts/design-$name.png');
      await file.parent.create(recursive: true);
      await file.writeAsBytes(bytes!.buffer.asUint8List());
      image.dispose();
    });
  }

  Future<void> finishIO(
    WidgetTester tester,
    Future<bool> Function() condition,
  ) async {
    // Pump the fake UI clock between real filesystem completions.
    for (var i = 0; i < 200; i++) {
      await tester.runAsync(
        () => Future<void>.delayed(const Duration(milliseconds: 10)),
      );
      await tester.pump(const Duration(milliseconds: 20));
      if (find.text('Working with local files…').evaluate().isEmpty) {
        expect(await tester.runAsync(condition), true);
        await tester.pumpAndSettle();
        return;
      }
    }
    fail('The file operation did not finish.');
  }

  Future<void> fillEntry(
    WidgetTester tester, {
    String amount = '123.45',
    String description = 'Desk receipt',
  }) async {
    await tester.enterText(
      find.descendant(
        of: find.byKey(const Key('entry-amount')),
        matching: find.byType(TextFormField),
      ),
      amount,
    );
    await tester.enterText(
      find.descendant(
        of: find.byKey(const Key('entry-description')),
        matching: find.byType(TextFormField),
      ),
      description,
    );
    await tester.pumpAndSettle();
  }

  testWidgets('provided sample screens render from a real isolated ledger', (
    tester,
  ) async {
    await repo.save(
      entry(
        amount: 34400,
        kind: EntryKind.cashOut,
        description: 'dsad',
        date: '2026-11-15',
      ),
    );
    await mount(tester);
    expect(find.text('MWK Ledger'), findsNWidgets(2)); // sidebar + ledger
    expect(find.text('USD Ledger'), findsNWidgets(2));
    expect(tester.getSize(find.byKey(const Key('rpm-sidebar'))).width, 224);
    expect((await repo.load()).summary(Currency.mwk).closing, -34400);
    expect(tester.takeException(), isNull);
    await capture(tester, '01-overview');
    await navigate(tester, 'Transactions');
    expect(find.text('dsad'), findsOneWidget);
    expect(find.text('Newest first'), findsOneWidget);
    expect(tester.takeException(), isNull);
    await capture(tester, '02-transactions');
    await tester.tap(button('New transaction'));
    await tester.pumpAndSettle();
    expect(
      tester.widget<RpmButton>(button('Save transaction')).onPressed,
      isNull,
    );
    expect(tester.takeException(), isNull);
    await capture(tester, '03-new-transaction');
    await tester.tap(button('Cancel'));
    await tester.pumpAndSettle();
    await navigate(tester, 'Settings');
    expect(find.text('Local storage'), findsOneWidget);
    expect(tester.takeException(), isNull);
    await capture(tester, '04-settings');
  });

  testWidgets(
    'sidebar collapses to 72 pixels and every destination opens a working view',
    (tester) async {
      await repo.save(entry());
      await mount(tester);
      await tester.tap(find.byKey(const Key('sidebar-toggle')));
      await tester.pumpAndSettle();
      expect(tester.getSize(find.byKey(const Key('rpm-sidebar'))).width, 72);
      await capture(tester, 'collapsed');
      for (final destination in RpmDestination.values) {
        await tester.tap(find.byTooltip(destination.label));
        await tester.pumpAndSettle();
        expect(tester.takeException(), isNull, reason: destination.label);
      }
      await tester.tap(find.byKey(const Key('sidebar-toggle')));
      await tester.pumpAndSettle();
      expect(tester.getSize(find.byKey(const Key('rpm-sidebar'))).width, 224);
    },
  );

  testWidgets(
    'desktop layouts resize without overflow at all supplied breakpoints and 800px',
    (tester) async {
      await repo.save(entry());
      for (final size in [
        const Size(1280, 800),
        const Size(1440, 900),
        const Size(1920, 1080),
        const Size(800, 600),
      ]) {
        await mount(tester, size: size);
        for (final label in ['Overview', 'Transactions', 'Settings']) {
          if (size.width < 1100) {
            await tester.tap(find.byTooltip(label));
            await tester.pumpAndSettle();
          } else {
            await navigate(tester, label);
          }
          expect(tester.takeException(), isNull, reason: '$size $label');
        }
        await tester.tap(
          size.width < 1100
              ? find.byTooltip('Overview')
              : find.text('Overview').first,
        );
        await tester.pumpAndSettle();
        await tester.tap(button('New transaction'));
        await tester.pumpAndSettle();
        expect(tester.takeException(), isNull, reason: '$size modal');
        await tester.tap(button('Cancel'));
        await tester.pumpAndSettle();
        if (size.width == 1280) await capture(tester, '1280');
      }
    },
  );

  testWidgets(
    'negative amounts remain invalid and successful entry persists to the selected ledger',
    (tester) async {
      await mount(tester);
      await tester.tap(button('New transaction'));
      await tester.pumpAndSettle();
      await fillEntry(tester, amount: '-123.45');
      expect(
        tester.widget<RpmButton>(button('Save transaction')).onPressed,
        isNull,
      );
      expect((await repo.load()).entries, isEmpty);
      await fillEntry(tester);
      await tester.tap(button('Save transaction'));
      await tester.pumpAndSettle();
      final data = await repo.load();
      expect(data.entries.single.amount, 12345);
      expect(data.entries.single.currency, Currency.mwk);
      expect(find.text('Transaction saved'), findsOneWidget);
      expect(find.text('Desk receipt'), findsOneWidget);
      await tester.enterText(
        find.descendant(
          of: find.byKey(const Key('transaction-search')),
          matching: find.byType(TextFormField),
        ),
        'no matching receipt',
      );
      await tester.pumpAndSettle();
      expect(find.text('Desk receipt'), findsNothing);
      expect(find.text('No matching transactions'), findsOneWidget);
      expect(tester.takeException(), isNull);
    },
  );

  testWidgets(
    'editing and deleting use confirmations and recalculate actual stored balances',
    (tester) async {
      final e = entry(description: 'Original receipt', amount: 10000);
      await repo.save(e);
      await mount(tester);
      await navigate(tester, 'Transactions');
      await tester.tap(find.text('Original receipt'));
      await tester.pumpAndSettle();
      await fillEntry(tester, amount: '200.00', description: 'Edited receipt');
      await tester.tap(button('Save changes'));
      await tester.pumpAndSettle();
      expect(find.text('Save changes to this transaction?'), findsOneWidget);
      await tester.tap(button('Save changes').last);
      await tester.pumpAndSettle();
      expect((await repo.load()).summary(Currency.mwk).closing, 20000);
      await tester.tap(find.byTooltip('Transaction actions'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Delete transaction'));
      await tester.pumpAndSettle();
      await tester.tap(button('Cancel'));
      await tester.pumpAndSettle();
      expect((await repo.load()).entries.length, 1);
      await tester.tap(find.byTooltip('Transaction actions'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Delete transaction'));
      await tester.pumpAndSettle();
      await tester.tap(button('Delete transaction'));
      await tester.pumpAndSettle();
      expect((await repo.load()).entries, isEmpty);
      expect((await repo.load()).summary(Currency.mwk).closing, 0);
    },
  );

  testWidgets(
    'opening balance editor preserves the existing confirmation and repository operation',
    (tester) async {
      await mount(tester);
      await tester.tap(find.byTooltip('Edit MWK opening balance'));
      await tester.pumpAndSettle();
      await tester.enterText(find.byType(TextFormField).last, '321.99');
      await tester.tap(button('Update balance'));
      await tester.pumpAndSettle();
      await tester.tap(button('Change balance'));
      await tester.pumpAndSettle();
      expect((await repo.load()).openings[Currency.mwk], 32199);
      expect((await repo.load()).openings[Currency.usd], 0);
    },
  );

  testWidgets(
    'native backup and CSV actions create real files in selected destinations',
    (tester) async {
      await repo.save(entry());
      await mount(tester);
      final backup = File('${temp.path}/chosen-backup.json');
      picker.savePath = backup.path;
      await tester.tap(button('Backup'));
      await tester.pump();
      await finishIO(tester, backup.exists);
      expect(
        (await tester.runAsync(() => BackupCodec.read(backup)))!.entries.length,
        1,
      );
      expect(picker.lastSaveOptions!.initialDirectory, storage.backups.path);
      final csv = File('${temp.path}/chosen-export.csv');
      picker.savePath = csv.path;
      await tester.tap(button('Export CSV'));
      await tester.pump();
      await finishIO(tester, csv.exists);
      expect(await tester.runAsync(csv.readAsString), contains('"MWK"'));
      expect(await tester.runAsync(csv.readAsString), contains('"USD"'));
      expect(tester.takeException(), isNull);
    },
  );

  testWidgets(
    'restore action validates, confirms, backs up, then replaces stored records',
    (tester) async {
      await repo.save(entry(description: 'Original'));
      final replacement = LedgerSnapshot(
        openings: {Currency.mwk: 123, Currency.usd: 456},
        entries: [entry(currency: Currency.usd, description: 'Restored')],
      );
      final file = File('${temp.path}/restore.json');
      await tester.runAsync(
        () => file.writeAsString(BackupCodec.encode(replacement)),
      );
      picker.openPath = file.path;
      await mount(tester);
      await navigate(tester, 'Settings');
      await tester.tap(button('Restore backup'));
      await tester.pump();
      for (
        var i = 0;
        i < 100 &&
            find.text('Replace ledgers with this backup?').evaluate().isEmpty;
        i++
      ) {
        await tester.runAsync(
          () => Future<void>.delayed(const Duration(milliseconds: 10)),
        );
        await tester.pump(const Duration(milliseconds: 20));
      }
      expect(find.text('Replace ledgers with this backup?'), findsOneWidget);
      await tester.tap(button('Restore and replace'));
      await tester.pump();
      await finishIO(
        tester,
        () async =>
            (await repo.load()).entries.single.description == 'Restored',
      );
      expect((await repo.load()).openings, replacement.openings);
      final backups = (await tester.runAsync(
        () => storage.backups.list().toList(),
      ))!;
      expect(backups.length, 1);
      expect(
        (await tester.runAsync(
          () => BackupCodec.read(File(backups.single.path)),
        ))!.entries.single.description,
        'Original',
      );
    },
  );

  testWidgets(
    'reset requires exact RESET and creates a verified safety backup before clearing',
    (tester) async {
      await repo.save(entry());
      await mount(tester);
      await navigate(tester, 'Settings');
      await tester.tap(button('Reset data'));
      await tester.pumpAndSettle();
      expect(
        tester.widget<RpmButton>(button('Reset all data')).onPressed,
        isNull,
      );
      await tester.enterText(find.byType(TextFormField).last, 'reset');
      await tester.pump();
      expect(
        tester.widget<RpmButton>(button('Reset all data')).onPressed,
        isNull,
      );
      await tester.sendKeyEvent(LogicalKeyboardKey.enter);
      await tester.pump();
      expect((await repo.load()).entries.length, 1);
      await tester.enterText(find.byType(TextFormField).last, 'RESET');
      await tester.pump();
      await tester.tap(button('Reset all data'));
      await tester.pump();
      await finishIO(tester, () async => (await repo.load()).entries.isEmpty);
      final backups = (await tester.runAsync(
        () => storage.backups.list().toList(),
      ))!;
      expect(
        (await tester.runAsync(
          () => BackupCodec.read(File(backups.single.path)),
        ))!.entries.length,
        1,
      );
      expect(tester.takeException(), isNull);
    },
  );

  testWidgets(
    'cancelled export and invalid restore leave the current ledger intact',
    (tester) async {
      await repo.save(entry());
      await mount(tester);
      await tester.tap(button('Export CSV'));
      await tester.pumpAndSettle();
      expect((await repo.load()).entries.length, 1);
      final bad = File('${temp.path}/invalid.json');
      await tester.runAsync(() => bad.writeAsString('{ invalid'));
      picker.openPath = bad.path;
      await navigate(tester, 'Settings');
      await tester.tap(button('Restore backup'));
      await tester.pump();
      await finishIO(tester, () async => true);
      expect(find.text('Could not complete action'), findsOneWidget);
      expect((await repo.load()).entries.length, 1);
    },
  );

  testWidgets(
    'keyboard shortcuts, light compatibility and button hover/focus work',
    (tester) async {
      await mount(tester);
      final gesture = await tester.createGesture(kind: PointerDeviceKind.mouse);
      await gesture.addPointer(location: const Offset(1, 1));
      await gesture.moveTo(tester.getCenter(button('New transaction')));
      await tester.pump(const Duration(milliseconds: 150));
      expect(tester.takeException(), isNull);
      await gesture.removePointer();
      await tester.sendKeyDownEvent(
        Platform.isMacOS
            ? LogicalKeyboardKey.metaLeft
            : LogicalKeyboardKey.controlLeft,
      );
      await tester.sendKeyEvent(LogicalKeyboardKey.keyN);
      await tester.sendKeyUpEvent(
        Platform.isMacOS
            ? LogicalKeyboardKey.metaLeft
            : LogicalKeyboardKey.controlLeft,
      );
      await tester.pumpAndSettle();
      expect(button('Save transaction'), findsOneWidget);
      await tester.sendKeyEvent(LogicalKeyboardKey.escape);
      await tester.pumpAndSettle();
      expect(button('Save transaction'), findsNothing);
      await navigate(tester, 'Settings');
      await tester.tap(find.byTooltip('Change appearance'));
      await tester.pumpAndSettle();
      expect(
        Theme.of(tester.element(find.text('Local storage'))).brightness,
        Brightness.light,
      );
      await capture(tester, 'light-compatibility');
    },
  );
  testWidgets(
    'currency, type, custom category and calendar selection save their actual values',
    (tester) async {
      await mount(tester);
      await tester.tap(button('New transaction'));
      await tester.pumpAndSettle();
      await tester.tap(find.byType(RpmSelect<Currency>));
      await tester.pumpAndSettle();
      await tester.tap(find.text('USD · US Dollar').last);
      await tester.pumpAndSettle();
      await tester.tap(find.byType(RpmSelect<EntryKind>));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Cash out · Payment').last);
      await tester.pumpAndSettle();
      await tester.tap(
        find.byWidgetPredicate(
          (w) => w is RpmSelect<String> && w.label == 'Category *',
        ),
      );
      await tester.pumpAndSettle();
      await tester.tap(find.text('Add category…').last);
      await tester.pumpAndSettle();
      await tester.tap(button('Cancel').last);
      await tester.pumpAndSettle();
      expect(
        tester
            .widget<RpmSelect<String>>(
              find.byWidgetPredicate(
                (w) => w is RpmSelect<String> && w.label == 'Category *',
              ),
            )
            .value,
        'General',
      );
      await tester.tap(
        find.byWidgetPredicate(
          (w) => w is RpmSelect<String> && w.label == 'Category *',
        ),
      );
      await tester.pumpAndSettle();
      await tester.tap(find.text('Add category…').last);
      await tester.pumpAndSettle();
      await tester.enterText(find.byType(TextFormField).last, 'Travel');
      await tester.pumpAndSettle();
      await tester.tap(button('Use category'));
      await tester.pumpAndSettle();
      await tester.tap(
        find.byWidgetPredicate((w) => w is RpmButton && w.alignStart),
      );
      await tester.pumpAndSettle();
      tester
          .widget<CalendarDatePicker>(find.byType(CalendarDatePicker))
          .onDateChanged(DateTime(2026, 11, 14));
      await tester.pumpAndSettle();
      await fillEntry(tester, amount: '275.00', description: 'Transport cash');
      await tester.tap(button('Save transaction'));
      await tester.pumpAndSettle();
      final data = await repo.load();
      expect(data.entries.single.currency, Currency.usd);
      expect(data.entries.single.kind, EntryKind.cashOut);
      expect(data.entries.single.category, 'Travel');
      expect(data.entries.single.date, '2026-11-14');
      expect(data.summary(Currency.usd).closing, -27500);
      expect(data.summary(Currency.mwk).closing, 0);
    },
  );

  testWidgets(
    'transaction filters, sort and pagination operate on saved records',
    (tester) async {
      for (var i = 0; i < 12; i++) {
        final e = entry(
          currency: i < 6 ? Currency.mwk : Currency.usd,
          kind: i.isEven ? EntryKind.cashIn : EntryKind.cashOut,
          amount: 100 + i,
          date: i < 6 ? '2026-11-14' : '2026-11-15',
          description: 'Record $i',
        );
        await repo.save(
          LedgerEntry.fromJson({
            ...e.toJson(),
            'category': i < 6 ? 'Sales' : 'Office',
          }),
        );
      }
      await mount(tester);
      await navigate(tester, 'Transactions');
      expect(find.text('1–10 of 12 transactions'), findsOneWidget);
      await tester.tap(find.byTooltip('Next page'));
      await tester.pumpAndSettle();
      expect(find.text('11–12 of 12 transactions'), findsOneWidget);
      await tester.tap(find.byType(RpmSelect<int>));
      await tester.pumpAndSettle();
      await tester.tap(find.text('25').last);
      await tester.pumpAndSettle();
      expect(find.text('1–12 of 12 transactions'), findsOneWidget);
      final currencyFilter = find.byWidgetPredicate(
        (w) => w is RpmSelect<String> && w.options.containsKey('USD'),
      );
      await tester.tap(currencyFilter);
      await tester.pumpAndSettle();
      await tester.tap(find.text('USD').last);
      await tester.pumpAndSettle();
      expect(find.text('1–6 of 6 transactions'), findsOneWidget);
      expect(find.text('Record 0'), findsNothing);
      final typeFilter = find.byWidgetPredicate(
        (w) => w is RpmSelect<String> && w.options.containsKey('cashOut'),
      );
      await tester.tap(typeFilter);
      await tester.pumpAndSettle();
      await tester.tap(find.text('Cash out').last);
      await tester.pumpAndSettle();
      expect(find.text('1–3 of 3 transactions'), findsOneWidget);
      await tester.tap(button('Clear filters'));
      await tester.pumpAndSettle();
      await tester.tap(find.byType(RpmSelect<bool>));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Oldest first').last);
      await tester.pumpAndSettle();
      expect(
        tester.getTopLeft(find.text('Record 0')).dy,
        lessThan(tester.getTopLeft(find.text('Record 6')).dy),
      );
      expect(tester.takeException(), isNull);
    },
  );

  testWidgets(
    'failed automatic backup leaves records intact and reports an error',
    (tester) async {
      await repo.save(entry());
      await tester.runAsync(() async {
        await storage.backups.delete();
        await File(storage.backups.path).writeAsString('blocked directory');
      });
      await mount(tester);
      await navigate(tester, 'Settings');
      await tester.tap(button('Reset data'));
      await tester.pumpAndSettle();
      await tester.enterText(find.byType(TextFormField).last, 'RESET');
      await tester.pump();
      await tester.tap(button('Reset all data'));
      await tester.pump();
      await finishIO(
        tester,
        () async => (await repo.load()).entries.length == 1,
      );
      expect(find.text('Could not complete action'), findsOneWidget);
      expect((await repo.load()).entries.length, 1);
    },
  );

  testWidgets(
    'button focus, hover, pressed and disabled states follow the component contract',
    (tester) async {
      var calls = 0;
      await tester.pumpWidget(
        MaterialApp(
          theme: rpmTheme(Brightness.dark),
          home: Scaffold(
            body: Row(
              children: [
                RpmButton(
                  label: 'Action',
                  variant: RpmButtonVariant.primary,
                  onPressed: () => calls++,
                ),
                const RpmButton(label: 'Disabled', onPressed: null),
              ],
            ),
          ),
        ),
      );
      final control = tester.widget<TextButton>(
        find.descendant(
          of: button('Action'),
          matching: find.byType(TextButton),
        ),
      );
      await tester.sendKeyEvent(LogicalKeyboardKey.tab);
      await tester.pumpAndSettle();
      expect(control.statesController!.value, contains(WidgetState.focused));
      await tester.sendKeyEvent(LogicalKeyboardKey.enter);
      await tester.pumpAndSettle();
      expect(calls, 1);
      final pointer = await tester.createGesture(kind: PointerDeviceKind.mouse);
      await pointer.addPointer();
      await pointer.moveTo(tester.getCenter(button('Action')));
      await tester.pump(RpmTokens.hoverDuration);
      expect(control.statesController!.value, contains(WidgetState.hovered));
      await pointer.down(tester.getCenter(button('Action')));
      await tester.pump(const Duration(milliseconds: 150));
      expect(control.statesController!.value, contains(WidgetState.pressed));
      await pointer.up();
      await pointer.removePointer();
      await tester.pumpAndSettle();
      await tester.tap(button('Disabled'));
      await tester.pumpAndSettle();
      expect(calls, 2);
      expect(tester.takeException(), isNull);
    },
  );
  testWidgets(
    'Refresh button and shortcuts reload saved records without clearing the current view or filters',
    (tester) async {
      await repo.save(entry(description: 'Receipt original', amount: 10000));
      await repo.setOpening(Currency.usd, 12345);
      await mount(tester);
      await navigate(tester, 'Transactions');
      final searchField = find.descendant(
        of: find.byKey(const Key('transaction-search')),
        matching: find.byType(TextFormField),
      );
      await tester.enterText(searchField, 'Receipt');
      await tester.pumpAndSettle();
      await repo.save(entry(description: 'Receipt imported', amount: 20000));
      await tester.pumpAndSettle();
      expect(find.text('Receipt imported'), findsNothing);
      await tester.tap(button('Refresh'));
      await tester.pumpAndSettle();
      expect(find.text('Receipt imported'), findsOneWidget);
      expect(find.text('Data refreshed'), findsOneWidget);
      expect(
        tester.widget<TextFormField>(searchField).controller!.text,
        'Receipt',
      );
      expect(
        find.text('Every receipt and payment, in one place.'),
        findsOneWidget,
      );
      await repo.save(entry(description: 'Receipt via F5', amount: 40000));
      await tester.sendKeyEvent(LogicalKeyboardKey.f5);
      await tester.pumpAndSettle();
      expect(find.text('Receipt via F5'), findsOneWidget);
      await repo.save(
        entry(description: 'Receipt via shortcut', amount: 80000),
      );
      final modifier = Platform.isMacOS
          ? LogicalKeyboardKey.metaLeft
          : LogicalKeyboardKey.controlLeft;
      await tester.sendKeyDownEvent(modifier);
      await tester.sendKeyEvent(LogicalKeyboardKey.keyR);
      await tester.sendKeyUpEvent(modifier);
      await tester.pumpAndSettle();
      expect(find.text('Receipt via shortcut'), findsOneWidget);
      expect(
        tester.widget<TextFormField>(searchField).controller!.text,
        'Receipt',
      );
      final snapshot = await repo.load();
      expect(snapshot.entries.length, 4);
      expect(snapshot.summary(Currency.mwk).closing, 150000);
      expect(snapshot.summary(Currency.usd).closing, 12345);
      expect(tester.takeException(), isNull);
    },
  );

  testWidgets(
    'a failed refresh reports an error and retry preserves saved financial records',
    (tester) async {
      final controlled = _RefreshRepository(db);
      repo = controlled;
      final original = entry(description: 'Saved receipt');
      await repo.save(original);
      await mount(tester);
      controlled.failLoad = true;
      await tester.tap(button('Refresh'));
      await tester.pumpAndSettle();
      expect(find.text('Could not complete action'), findsOneWidget);
      expect(find.text('Could not load transactions'), findsOneWidget);
      expect(find.text('Data refreshed'), findsNothing);
      controlled.failLoad = false;
      expect((await repo.load()).entries.single.toJson(), original.toJson());
      await tester.tap(button('Try again'));
      await tester.pumpAndSettle();
      expect(find.text('Saved receipt'), findsOneWidget);
      expect(find.text('Data refreshed'), findsOneWidget);
      expect(tester.takeException(), isNull);
    },
  );

  testWidgets(
    'Refresh recreates missing storage from the startup screen and after deleting the open folder',
    (tester) async {
      tester.view.physicalSize = const Size(1440, 900);
      tester.view.devicePixelRatio = 1;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);
      await tester.pumpWidget(
        ProviderScope(
          child: _ThemeShell(
            child: StartupScreen(storageFactory: () async => storage),
          ),
        ),
      );
      Future<void> settleUntil(bool Function() done) async {
        for (var i = 0; i < 200; i++) {
          await tester.runAsync(
            () => Future<void>.delayed(const Duration(milliseconds: 10)),
          );
          await tester.pump(const Duration(milliseconds: 20));
          if (done()) {
            await tester.pumpAndSettle();
            return;
          }
        }
        fail('Storage refresh did not finish.');
      }

      await settleUntil(() => find.text('Refresh').evaluate().isNotEmpty);
      expect(find.text('Let’s recover your ledgers.'), findsOneWidget);
      await tester.tap(find.text('Refresh'));
      await settleUntil(
        () => find.text('Financial overview').evaluate().isNotEmpty,
      );
      final container = ProviderScope.containerOf(
        tester.element(find.byType(DesktopScreen)),
      );
      final first = container.read(repositoryProvider);
      await tester.runAsync(
        () => first.save(entry(description: 'Before deletion')),
      );
      await tester.tap(button('Refresh'));
      await settleUntil(
        () => find.text('Before deletion').evaluate().isNotEmpty,
      );
      await tester.runAsync(() => storage.root.delete(recursive: true));
      await tester.tap(button('Refresh'));
      await settleUntil(
        () =>
            find.text('Financial overview').evaluate().isNotEmpty &&
            find.text('Before deletion').evaluate().isEmpty,
      );
      final fresh = ProviderScope.containerOf(
        tester.element(find.byType(DesktopScreen)),
      ).read(repositoryProvider);
      expect(await tester.runAsync(() => storage.databaseFile.exists()), true);
      expect((await tester.runAsync(fresh.load))!.entries, isEmpty);
      await tester.runAsync(
        () => fresh.save(entry(description: 'After recreation')),
      );
      await tester.tap(button('Refresh'));
      await settleUntil(
        () => find.text('After recreation').evaluate().isNotEmpty,
      );
      expect(tester.takeException(), isNull);
      await tester.runAsync(storage.close);
      await tester.pumpWidget(const SizedBox());
    },
  );
}
