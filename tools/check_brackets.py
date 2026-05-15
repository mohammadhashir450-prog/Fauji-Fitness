from pathlib import Path
s=Path(r'C:\jym_app\lib\screens\registration_screen.dart').read_text()
pairs={'(':')','[':']','{':'}'}
stack=[]
for i,ch in enumerate(s,1):
    if ch in pairs:
        stack.append((ch,i))
    elif ch in pairs.values():
        if not stack:
            print('Extra closing',ch,'at',i)
            break
        last,pos=stack.pop()
        if pairs[last]!=ch:
            print('Mismatched',last,'opened at',pos,'closed by',ch,'at',i)
            break
else:
    if stack:
        print('Unclosed tokens:')
        for t,pos in stack[-20:]:
            print(t,'at',pos)
    else:
        print('All balanced')
