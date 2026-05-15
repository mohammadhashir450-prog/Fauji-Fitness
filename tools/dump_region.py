from pathlib import Path
p=Path(r'C:\jym_app\lib\screens\registration_screen.dart')
s=p.read_text()
lines=s.splitlines()
for i in range(360,416):
    print(f'{i+1:04d}: {repr(lines[i])}')
