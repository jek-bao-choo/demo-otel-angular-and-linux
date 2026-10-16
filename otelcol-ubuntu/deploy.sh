#!/bin/bash
# Deploy otelcol-contrib to jek-my1, jek-my2, jek-cz1 (runs from your laptop)
# Usage: ./deploy.sh            (prompts for DD_API_KEY if not already exported)
set -euo pipefail

ENV_TAG="uat"
KEY="${HOME}/.ssh/jek_id_ed25519_pem"
HOSTS=(
  "jek-my1 <MY1_PUBLIC_IP>"
  "jek-my2 <MY2_PUBLIC_IP>"
  "jek-cz1 <CZ1_PUBLIC_IP>"
)

cd "$(dirname "$0")"
if [ -z "${DD_API_KEY:-}" ]; then
  read -rsp "DD_API_KEY: " DD_API_KEY; echo
fi

for entry in "${HOSTS[@]}"; do
  read -r name ip <<< "${entry}"
  echo "######## ${name} (${ip}) ########"
  scp -i "${KEY}" -q config.yaml "ubuntu@${ip}:/tmp/otelcol-contrib-config.yaml"
  scp -i "${KEY}" -q install.sh "ubuntu@${ip}:/tmp/install-otelcol.sh"
  # API key goes over stdin so it never appears in the remote process list
  echo "${DD_API_KEY}" | ssh -i "${KEY}" "ubuntu@${ip}" \
    "bash /tmp/install-otelcol.sh ${name} ${ENV_TAG} && rm -f /tmp/install-otelcol.sh"
done

echo "Done. In Datadog check Infrastructure > Host Map for env:${ENV_TAG}."
