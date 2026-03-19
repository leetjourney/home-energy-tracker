# AGENTS.md — Guidance for automated coding/operational agents

Purpose: Give AI agents the minimal, actionable knowledge to build, run, and inspect the Home Energy Tracker microservices.

Quick plan for agents
- Bring up infra (MySQL, Kafka, InfluxDB, Mailpit)
- Build or run a single service locally
- Exercise the ingestion -> usage -> alert pipeline and verify side-effects

Quick start (infra)
- From repo root: `docker compose up -d` (uses `docker-compose.yml`)
- Stop: `docker compose down`
- If DB issues occur: remove/recreate volumes or re-run `docker/mysql/init.sql`

Build / run a service
- Build: `cd <service> && ./mvnw package` (each microservice has its own Maven wrapper)
- Run artifact: `java -jar target/<artifact>.jar` or `./mvnw spring-boot:run`

Architecture & key components
- Microservices (top-level dirs): `alert-service`, `api-gateway`, `device-service`, `ingestion-service`, `insight-service`, `usage-service`, `user-service`.
- Important infra files: `docker-compose.yml`, `docker/mysql/init.sql`, `docker/kafka_data/`, `influxdb_data/`.

Critical integration points & dataflows (explicit)
- Ingestion -> Kafka -> Usage -> InfluxDB & Alerts -> Alerting consumer
  - Topic `energy-usage`: produced by `ingestion-service` (see `ingestion-service/src/main/java/.../IngestionService.java`) and consumed by `usage-service` (`usage-service/src/main/java/.../UsageService.java`).
  - Topic `energy-alerts`: produced by `usage-service` (aggregation/threshold logic) and consumed by `alert-service` (`alert-service/src/main/java/.../AlertService.java`).
- InfluxDB usage: `usage-service/src/main/java/.../InfluxDBConfig.java` and writes/queries in `UsageService.java`.
- MySQL: DB name `home_energy_tracker`, init in `docker/mysql/init.sql`; JDBC URLs appear in services' `src/main/resources/application.properties`.

Observability & useful endpoints
- Kafka UI: http://localhost:8070 (inspect topics and messages)
- Mailpit (SMTP/web): SMTP 1025, web UI http://localhost:8025 (outgoing email from `alert-service`)
- Influx (API): http://localhost:8072 (configured via docker-compose env vars)
- Service ports (common defaults in application.properties):
  - `user-service` 8080, `device-service` 8081, `ingestion-service` 8082, `usage-service` 8083, `alert-service` 8084, `insight-service` 8085, `api-gateway` 9000

Example agent actions (curl + checks)
- Post a test event (will create Kafka traffic):
  - `curl -X POST http://localhost:8082/api/v1/ingestion -H 'Content-Type: application/json' -d '{"deviceId":"dev-1","timestamp":"2025-01-01T12:00:00Z","watts":1200}'`
- Verify usage-service consumed and wrote to InfluxDB: check `usage-service` logs and query Influx bucket via HTTP API; also check scheduled aggregation logs (see scheduler in `UsageService.java`).
- Force alert: craft a high `watts` payload and confirm Mailpit received an email (web UI at 8025).

Agent runbook checks (short)
- Confirm ports reachable: tcp/3306, tcp/9094, tcp/8072, tcp/8025
- Confirm Kafka topics exist and show message flow (kafka-ui or service logs)
- Confirm Influx writes by querying the bucket referenced in `docker-compose.yml` envs
- Check service logs: `docker compose logs <container>` or run the JAR locally and capture stdout

Project-specific conventions
- Maven wrapper present in each service — prefer `./mvnw`.
- Package names use underscores: e.g. `com.leetjourney.ingestion_service` (see each service `HELP.md` which documents this change).
- Kafka bootstrap server for host-based runs: `localhost:9094` (external advertised listener in `docker-compose.yml`). Services' `application.properties` use this address.
- JSON type mapping for Kafka consumers is configured in service properties (look for `spring.kafka.consumer.properties.spring.json.type.mapping`).

Files to reference when automating (examples)
- `docker-compose.yml` — infra and envs
- `docker/mysql/init.sql` — DB bootstrap
- `ingestion-service/src/main/java/com/leetjourney/ingestion_service/controller/IngestionController.java`
- `ingestion-service/src/main/java/com/leetjourney/ingestion_service/service/IngestionService.java`
- `usage-service/src/main/java/com/leetjourney/usage_service/service/UsageService.java`
- `usage-service/src/main/java/com/leetjourney/usage_service/config/InfluxDBConfig.java`
- `alert-service/src/main/java/com/leetjourney/alert_service/service/AlertService.java`

Notes
- Java version: poms target recent Java (ensure JDK 21 or as declared in each module POM).
- The README and each service `HELP.md` contain additional module-specific hints discovered when the project was built.

End of AGENTS.md

