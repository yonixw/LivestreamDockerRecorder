#!/bin/bash
set -e # fail on any

# Install nodejs google tool zx
echo "[*] Looking for zx" 
which zx || npm install -g zx

export CONFIG_FILE=${CONFIG_FILE:-config.yaml}
if [ ! -f "$CONFIG_FILE" ]; then
    echo "[ERR] Config file not found, set with CONFIG_FILE, in: \$CONFIG_FILE\""
    exit 1
fi

cat "$CONFIG_FILE" | zx --install --eval '
    import fs from "fs"
    import YAML from "yaml"
    const yaml_file = fs.readFileSync($.env.CONFIG_FILE, "utf8")
    console.log(YAML.parse(yaml_file))
'