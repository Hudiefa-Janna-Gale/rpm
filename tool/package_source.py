"""Create a clean source archive without local caches, binaries, or user data."""
from pathlib import Path
import hashlib
import zipfile

root = Path(__file__).resolve().parents[1]
output = root / 'dist' / 'RPM-Source.zip'
output.parent.mkdir(exist_ok=True)
roots = ['lib', 'macos', 'windows', 'test', 'tool', 'packaging', 'assets', 'docs', '.github']
ignored = {'.dart_tool', 'Pods', 'ephemeral', '__pycache__', '.symlinks', 'build'}
files = [root / name for name in ['README.md', 'COPYRIGHT', 'VALIDATION.md', 'pubspec.yaml', 'pubspec.lock', 'analysis_options.yaml', '.gitignore', '.metadata']]
for name in roots:
    for path in (root / name).rglob('*'):
        relative = path.relative_to(root)
        if not path.is_file() or any(part in ignored for part in relative.parts):
            continue
        if relative.parts[:3] == ('tool', 'codegen', 'lib'):
            continue
        files.append(path)
with zipfile.ZipFile(output, 'w', zipfile.ZIP_DEFLATED) as archive:
    for path in sorted(files):
        if path.exists():
            archive.write(path, 'RPM-Source/' + path.relative_to(root).as_posix())
    if archive.testzip() is not None:
        raise RuntimeError('Source archive integrity check failed')
checksum = hashlib.sha256(output.read_bytes()).hexdigest()
output.with_suffix('.zip.sha256').write_text(f'{checksum}  {output.name}\n')
print(output)
