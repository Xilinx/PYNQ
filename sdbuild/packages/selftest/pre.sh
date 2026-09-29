#! /bin/bash

target=$1
script_dir="$( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd )"
dest=/usr/local/share/pynq-selftest

sudo install -d -m 0755 "$target$dest/lib"
sudo install -d -m 0755 "$target$dest/tests/bash"
sudo install -d -m 0755 "$target$dest/tests/python"
sudo install -d -m 0755 "$target$dest/manifests"

sudo install -D -m 0755 "$script_dir/pynq-selftest" "$target/usr/local/bin/pynq-selftest"
sudo install -D -m 0644 "$script_dir/README.md" "$target/usr/local/share/doc/pynq-selftest/README.md"

for f in "$script_dir/lib/"*; do
    mode=0644
    [[ ${f##*/} == *.sh ]] && mode=0755
    [[ ${f##*/} == orchestrator.py ]] && mode=0755
    sudo install -D -m "$mode" "$f" "$target$dest/lib/${f##*/}"
done

for f in "$script_dir/tests/bash/"*.sh; do
    [[ -e $f ]] || continue
    sudo install -D -m 0755 "$f" "$target$dest/tests/bash/${f##*/}"
done

for f in "$script_dir/tests/python/"*.py; do
    [[ -e $f ]] || continue
    sudo install -D -m 0644 "$f" "$target$dest/tests/python/${f##*/}"
done

for f in "$script_dir/manifests/"*.json; do
    [[ -e $f ]] || continue
    sudo install -D -m 0644 "$f" "$target$dest/manifests/${f##*/}"
done

if [[ -n ${PYNQ_BOARDDIR:-} && -f $PYNQ_BOARDDIR/selftest.json ]]; then
    board=${PYNQ_BOARD:-$(basename "$PYNQ_BOARDDIR")}
    sudo install -D -m 0644 "$PYNQ_BOARDDIR/selftest.json" "$target$dest/manifests/${board}.json"
fi
