#!/bin/bash
# Deploy adt-service-a -> service-b -> service-c to jek-my1, jek-my2, jek-cz1 (runs from your laptop)
# Usage: ./deploy.sh        (build first: cd .. && mvn -q clean package -DskipTests)
set -euo pipefail

OTEL_JAVAAGENT_VERSION="2.32.0"
KEY="${HOME}/.ssh/jek_id_ed25519_pem"
# Deploy order: leaf first, so each service's downstream is already up
# name | public IP | service | downstream URL (private IP) | load generator | peer-service mapping
# The mapping names the downstream IP so Datadog shows service-b/service-c, not "blocked-ip-address"
HOSTS=(
  "jek-cz1|<CZ1_PUBLIC_IP>|service-c||no|"
  "jek-my2|<MY2_PUBLIC_IP>|service-b|http://10.0.1.103:8080/api/c|no|10.0.1.103=service-c"
  "jek-my1|<MY1_PUBLIC_IP>|adt-service-a|http://10.0.1.176:8080/api/b|yes|10.0.1.176=service-b"
)

cd "$(dirname "$0")"
AGENT="agent/opentelemetry-javaagent.jar"
if [ ! -f "${AGENT}" ]; then
  mkdir -p agent
  curl -fsSL -o "${AGENT}" "https://github.com/open-telemetry/opentelemetry-java-instrumentation/releases/download/v${OTEL_JAVAAGENT_VERSION}/opentelemetry-javaagent.jar"
fi

for entry in "${HOSTS[@]}"; do
  IFS='|' read -r name ip service downstream loadgen peermap <<< "${entry}"
  jar="../${service}/target/${service}.jar"
  [ -f "${jar}" ] || { echo "ERROR: ${jar} not found — run 'mvn -q clean package -DskipTests' in apps/"; exit 1; }

  echo "######## ${service} -> ${name} (${ip}) ########"
  ssh -i "${KEY}" "ubuntu@${ip}" "mkdir -p /tmp/adt-deploy"
  scp -i "${KEY}" -q "${jar}" "ubuntu@${ip}:/tmp/adt-deploy/app.jar"
  scp -i "${KEY}" -q "${AGENT}" "ubuntu@${ip}:/tmp/adt-deploy/opentelemetry-javaagent.jar"
  scp -i "${KEY}" -q install-app.sh "ubuntu@${ip}:/tmp/adt-deploy/install-app.sh"
  ssh -i "${KEY}" "ubuntu@${ip}" "bash /tmp/adt-deploy/install-app.sh '${service}' '${downstream}' '${loadgen}' '${peermap}'"
done

echo ""
echo "=== End-to-end check from jek-my1 ==="
ssh -i "${KEY}" "ubuntu@<MY1_PUBLIC_IP>" 'curl -s -w " [%{http_code}]\n" http://localhost:8080/api/a'
echo "Datadog: APM > Service Map (env:uat) — adt-service-a -> service-b -> service-c"
