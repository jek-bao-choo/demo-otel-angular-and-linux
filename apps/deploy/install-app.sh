#!/bin/bash
# Install one Spring Boot service with the OpenTelemetry Java agent (runs ON the instance)
# Usage: install-app.sh <SERVICE_NAME> [DOWNSTREAM_URL] [LOADGEN=yes|no] [PEER_SERVICE_MAPPING]
#   PEER_SERVICE_MAPPING: <ip>=<service>[,...] — sets peer.service on outgoing calls so Datadog
#   names the dependency instead of showing "blocked-ip-address" for IP destinations
# Expects /tmp/adt-deploy/app.jar and /tmp/adt-deploy/opentelemetry-javaagent.jar
set -euo pipefail

SERVICE_NAME="${1:?Usage: install-app.sh <SERVICE_NAME> [DOWNSTREAM_URL] [LOADGEN] [PEER_SERVICE_MAPPING]}"
DOWNSTREAM_URL="${2:-}"
LOADGEN="${3:-no}"
PEER_SERVICE_MAPPING="${4:-}"
SRC=/tmp/adt-deploy

echo "=== [${SERVICE_NAME}] Installing Java 17 ==="
if ! command -v java >/dev/null; then
  sudo apt-get update -qq
  sudo DEBIAN_FRONTEND=noninteractive apt-get install -y -qq openjdk-17-jre-headless
fi
java -version 2>&1 | head -1

echo "=== Placing app and agent in /opt/app ==="
id app >/dev/null 2>&1 || sudo useradd --system --no-create-home --shell /usr/sbin/nologin app
sudo mkdir -p /opt/app /var/log/app
sudo install -m 0644 "${SRC}/app.jar" /opt/app/app.jar
sudo install -m 0644 "${SRC}/opentelemetry-javaagent.jar" /opt/app/opentelemetry-javaagent.jar
sudo chown -R app:app /opt/app /var/log/app

echo "=== Writing app.service ==="
# stdout goes to a local file (not syslog) so the collector's filelog/system receiver
# doesn't ship a second copy — app logs reach Datadog via the agent's OTLP log export
sudo tee /etc/systemd/system/app.service > /dev/null <<EOF
[Unit]
Description=${SERVICE_NAME} (Spring Boot + OpenTelemetry Java agent)
After=network-online.target otelcol-contrib.service
Wants=network-online.target

[Service]
User=app
Environment=OTEL_SERVICE_NAME=${SERVICE_NAME}
Environment=OTEL_EXPORTER_OTLP_ENDPOINT=http://localhost:4318
Environment=OTEL_EXPORTER_OTLP_PROTOCOL=http/protobuf
Environment=OTEL_RESOURCE_ATTRIBUTES=deployment.environment.name=uat,service.version=1.0.0
Environment=OTEL_TRACES_EXPORTER=otlp
Environment=OTEL_METRICS_EXPORTER=otlp
Environment=OTEL_LOGS_EXPORTER=otlp
Environment=PORT=8080
Environment=DOWNSTREAM_URL=${DOWNSTREAM_URL}
Environment=OTEL_INSTRUMENTATION_COMMON_PEER_SERVICE_MAPPING=${PEER_SERVICE_MAPPING}
ExecStart=/usr/bin/java -javaagent:/opt/app/opentelemetry-javaagent.jar -jar /opt/app/app.jar
StandardOutput=append:/var/log/app/app.log
StandardError=append:/var/log/app/app.log
Restart=on-failure
RestartSec=5

[Install]
WantedBy=multi-user.target
EOF

sudo systemctl daemon-reload
sudo systemctl enable app.service
sudo systemctl restart app.service

echo "=== Waiting for /actuator/health ==="
for i in $(seq 1 60); do
  if curl -sf http://localhost:8080/actuator/health >/dev/null; then
    echo "=== [${SERVICE_NAME}] healthy after ${i}s ==="
    break
  fi
  sleep 1
done
if ! curl -sf http://localhost:8080/actuator/health >/dev/null; then
  echo "=== [${SERVICE_NAME}] ERROR: not healthy after 60s ==="
  sudo tail -n 40 /var/log/app/app.log
  exit 1
fi

if [ "${LOADGEN}" = "yes" ]; then
  echo "=== Enabling load generator (GET /api/a every 5s) ==="
  sudo tee /etc/systemd/system/adt-loadgen.service > /dev/null <<'EOF'
[Unit]
Description=Load generator for adt-service-a
After=app.service
Requires=app.service

[Service]
User=app
ExecStart=/bin/bash -c 'while true; do curl -s -o /dev/null -m 10 http://localhost:8080/api/a; sleep 5; done'
Restart=always

[Install]
WantedBy=multi-user.target
EOF
  sudo systemctl daemon-reload
  sudo systemctl enable adt-loadgen.service
  sudo systemctl restart adt-loadgen.service
fi

rm -rf "${SRC}"
echo "=== [${SERVICE_NAME}] Installation complete ==="
