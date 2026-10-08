#!/bin/bash
set -e

python3 << 'PYEOF'
filepath = '/usr/lib/python3.9/site-packages/packstack/plugins/nova_300.py'
with open(filepath, 'r') as f:
    content = f.read()

old = ('            if not hostkey:\n'
       '                continue\n\n'
       '            _, host_key_type, host_key_data = hostkey.split()')
new = ('            if not hostkey:\n'
       '                continue\n'
       '            if hostkey.startswith("#"):\n'
       '                continue\n\n'
       '            _, host_key_type, host_key_data = hostkey.split()')

if old in content:
    content = content.replace(old, new)
    with open(filepath, 'w') as f:
        f.write(content)
    print('Patched')
elif new in content:
    print('Already patched')
PYEOF

touch /root/.nova_300_patched
