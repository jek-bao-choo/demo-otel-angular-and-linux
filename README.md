# demo-otel-angular-and-linux

End-to-end OpenTelemetry demo sending data to Datadog:

Browser (Angular + Datadog RUM) → `adt-service-a` → `service-b` → `service-c` (Spring Boot + OpenTelemetry Java agent), running on Ubuntu EC2 hosts that each run `otelcol-contrib`.

| Path | Contents |
|---|---|
| `apps/web` | Angular front end (built bundle is served by `adt-service-a`) |
| `apps/adt-service-a`, `apps/service-b`, `apps/service-c` | Java services (`mvn clean package` from `apps/`) |
| `apps/deploy` | Deploys the services and the OTel Java agent to the hosts |
| `otelcol-ubuntu` | OpenTelemetry Collector Contrib config and install/deploy scripts |
| `terraform-ubuntu` | Terraform for the EC2 hosts |
| `docs` | Demo slides (HTML) and PPTX build scripts |

## Placeholders to fill in

- `<RUM_APPLICATION_ID>`, `<RUM_CLIENT_TOKEN>`, `<RUM_REMOTE_CONFIG_ID>`: `apps/web/src/main.ts`, then rebuild the web bundle
- `<MY1_PUBLIC_IP>`, `<MY2_PUBLIC_IP>`, `<CZ1_PUBLIC_IP>`: `apps/deploy/deploy.sh`, `otelcol-ubuntu/deploy.sh` (from `terraform output`)
- `DD_API_KEY`: export it, or enter it when `otelcol-ubuntu/deploy.sh` prompts
- `DD_PPTX_TEMPLATE`: path to the Datadog presentation template, used by `docs/build_pptx_ddtemplate.py`
