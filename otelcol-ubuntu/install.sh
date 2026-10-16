#!/bin/bash
# Install OpenTelemetry Collector Contrib on Ubuntu 22.04 (runs ON the instance)
# Usage: install.sh <HOSTNAME> <ENV> [OTELCOL_VERSION]   (DD_API_KEY read from stdin)
set -euo pipefail

DD_HOSTNAME="${1:?Usage: install.sh <HOSTNAME> <ENV> [VERSION]}"
DD_ENV="${2:?Usage: install.sh <HOSTNAME> <ENV> [VERSION]}"
OTELCOL_VERSION="${3:-0.149.0}"
read -r DD_API_KEY
# Strip stray characters (e.g. \r from a pasted key) — they make Go reject the DD-API-KEY header
DD_API_KEY="$(printf '%s' "${DD_API_KEY}" | tr -cd '[:alnum:]')"
[[ "${DD_API_KEY}" =~ ^[0-9a-f]{32}$ ]] || { echo "ERROR: DD_API_KEY must be 32 hex characters"; exit 1; }

echo "=== [${DD_HOSTNAME}] Installing otelcol-contrib v${OTELCOL_VERSION} ==="

DEB_URL="https://github.com/open-telemetry/opentelemetry-collector-releases/releases/download/v${OTELCOL_VERSION}/otelcol-contrib_${OTELCOL_VERSION}_linux_amd64.deb"
curl -fsSL -o /tmp/otelcol-contrib.deb "${DEB_URL}"
sudo dpkg -i /tmp/otelcol-contrib.deb
rm -f /tmp/otelcol-contrib.deb

echo "=== Deploying config ==="
sed -e "s/__HOSTNAME__/${DD_HOSTNAME}/g" -e "s/__ENV__/${DD_ENV}/g" /tmp/otelcol-contrib-config.yaml \
  | sudo tee /etc/otelcol-contrib/config.yaml > /dev/null
rm -f /tmp/otelcol-contrib-config.yaml

echo "=== Configuring environment ==="
# Without --config, the collector fails with "at least one config flag must be provided".
sudo tee /etc/otelcol-contrib/otelcol-contrib.conf > /dev/null <<EOF
DD_API_KEY=${DD_API_KEY}
OTELCOL_OPTIONS="--config=/etc/otelcol-contrib/config.yaml"
EOF
sudo chmod 600 /etc/otelcol-contrib/otelcol-contrib.conf

echo "=== Configuring log access and storage ==="
# /var/log/syslog and auth.log are root:adm 0640 on Ubuntu
sudo usermod -aG adm otelcol-contrib
sudo mkdir -p /var/lib/otelcol-contrib/storage
sudo chown otelcol-contrib:otelcol-contrib /var/lib/otelcol-contrib/storage

echo "=== Validating config ==="
sudo -u otelcol-contrib env DD_API_KEY="${DD_API_KEY}" otelcol-contrib validate --config=/etc/otelcol-contrib/config.yaml

echo "=== Starting otelcol-contrib ==="
sudo systemctl daemon-reload
sudo systemctl enable otelcol-contrib
sudo systemctl restart otelcol-contrib
sleep 5

if sudo systemctl is-active --quiet otelcol-contrib; then
  echo "=== [${DD_HOSTNAME}] otelcol-contrib is running ==="
  curl -s http://localhost:13133/; echo
else
  echo "=== [${DD_HOSTNAME}] ERROR: otelcol-contrib failed to start ==="
  sudo journalctl -u otelcol-contrib --no-pager -n 30
  exit 1
fi
