#!/bin/bash
set -euo pipefail
cd "$(dirname "$0")/.."
mkdir -p tool/codegen/lib
cp lib/core/database.dart tool/codegen/lib/database.dart
(cd tool/codegen && dart pub get && dart run build_runner build --force-jit)
cp tool/codegen/lib/database.g.dart lib/core/database.g.dart
dart format lib/core/database.g.dart
