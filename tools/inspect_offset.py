from pathlib import Path
p=Path(r'C:\jym_app\lib\screens\registration_screen.dart')
s=p.read_text()
o=16400
start=max(0,o-30)
end=min(len(s),o+30)
print('len',len(s))
print('context:', repr(s[start:end]))
# show line numbers around the offset
lines=s.splitlines()
for i in range(max(0,lines.index([l for l in lines if 'Widget _buildPasswordField' in l][0])-5), min(len(lines), lines.index([l for l in lines if 'Widget _buildPasswordField' in l][0])+10)):
    print(i+1, lines[i])
