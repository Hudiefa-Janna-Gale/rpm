import 'dart:io';

Future<void> main(List<String> args) async {
  final file = await File(args.single).open(mode: FileMode.append);
  try {
    await file.lock(FileLock.exclusive);
    stdout.write('available');
    await file.unlock();
  } on FileSystemException {
    stdout.write('locked');
  } finally {
    await file.close();
  }
}
