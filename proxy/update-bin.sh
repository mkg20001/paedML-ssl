#!/bin/bash

set -e

echo "[*] Einspielen der Aktualisierung..."

MAIN=$(dirname $(dirname $(readlink -f $0)))

apt update
apt dist-upgrade -y

cd "$MAIN"
git pull
bash scripts/update.sh
