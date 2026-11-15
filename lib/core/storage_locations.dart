import 'dart:io';
import 'package:path/path.dart' as p;
import 'package:path_provider/path_provider.dart';
import 'storage.dart';

Future<AppStorage> defaultStorage() async => AppStorage(
  root: Directory(
    p.join((await getApplicationDocumentsDirectory()).path, 'RPM'),
  ),
  support: await getApplicationSupportDirectory(),
);
