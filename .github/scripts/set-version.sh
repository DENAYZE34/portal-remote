#!/usr/bin/env bash
set -e
v="1.5.$1"
sed -i "s/^version = \"1.5.0\"/version = \"$v\"/" Cargo.toml
python3 - "$v" <<'PY'
import re,sys
v=sys.argv[1]
s=open('Cargo.lock',encoding='utf8',newline='').read()
n=re.sub(r"(name = \"rustdesk\"\r?\nversion = \")1\.5\.0\"", lambda m:m.group(1)+v+"\"", s, count=1)
assert n!=s, "lock not patched"
open('Cargo.lock','w',encoding='utf8',newline='').write(n)
PY
grep -m1 '^version' Cargo.toml
