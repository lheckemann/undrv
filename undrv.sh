#!/usr/bin/env bash
set -euo pipefail
SOURCE_DIR="$(cd "$(dirname "$0")"; pwd)"

if [[ -e "${output:=undrv-output}" ]]; then
  chmod -R u+w "$output"
  rm -rf "$output"
fi
mkdir "$output"
drv="$1"
nix show-derivation -r "$drv" > $output/drvs.json
nix path-info --json --derivation -r "$drv" | jq 'map({key: .path, value: .}) | from_entries' > $output/paths.json
cd $output
mkdir deps/
IFS=
<drvs.json jq -r 'map(.inputSrcs) | add | unique | .[]' | while read -r storepath; do
    (
    name_in_store="${storepath#/nix/store/}"
    hash="${name_in_store%%-*}"
    name="${name_in_store#*-}"
    mkdir -p "deps/$hash"
    cp -r "$storepath" "deps/$hash/$name"
    ) &
done
until wait -n; [[ $? == 127 ]] ; do : ; done
sleep 0.1

cp "$SOURCE_DIR/undrv.nix" .

cat > default.nix <<EOF
import ./undrv.nix {
  top = "$1";
  depsDir = ./deps;
  lib = import <nixpkgs/lib>;
  drvsJSON = ./drvs.json;
  pathsJSON = ./paths.json;
}
EOF

nix eval \
    --raw \
    --show-trace \
    --debugger \
    --file . \
    drvPath >/dev/null

drv=$(nix eval \
    --raw \
    --show-trace \
    --debugger \
    --file . \
    drvPath)

echo >&2 "Wrote output to $output. Checking if it evaluates to the originally given drv..."
[[ "$1" = "$drv" ]] || nix-diff "$1" "$drv"
