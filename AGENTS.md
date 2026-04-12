# AGENTS.md — Guidance for automated coding/operational agents

Purpose: Give AI agents the minimal, actionable knowledge to build, run, and inspect the Home Energy Tracker microservices.

Quick plan for agents
- Bring up infra (MySQL, Kafka, InfluxDB, Mailpit, Kafka UI, Keycloak, Prometheus, Grafana)
- Build or run a single service locally
- Exercise the ingestion → usage → alert pipeline and verify side-effects

Quick start (infra)
- From repo root: `docker compose up -d` (uses `docker-compose.yml`)
- Stop: `docker compose down`
- If DB issues occur: remove/recreate volumes or re-run `docker/mysql/init.sql`

Build / run a service
- Build: `cd <service> && ./mvnw package` (each microservice has its own Maven wrapper)
- Run artifact: `java -jar target/<artifact>.jar` or `./mvnw spring-boot:run`

Architecture & key components
- Microservices (top-level dirs): `alert-service`, `api-gateway`, `device-service`, `ingestion-service`, `insight-service`, `usage-service`, `user-service`.
- Stack: **Spring Boot 4** + **Java 21** for most services; **`insight-service`** uses **Spring Boot 3.5** with **Spring AI** (Ollama). **Spring Cloud 2025.1.0** on the gateway (Gateway Server WebMVC, Resilience4j circuit breakers). No Spring Cloud Config Server in this repo—config is per-service `application.properties`.
- Important infra files: `docker-compose.yml`, `docker/mysql/init.sql`, `docker/prometheus/prometheus.yml`, `docker/grafana/provisioning/`, `docker/kafka_data/`, `influxdb_data/`.
- Human-oriented architecture diagrams: `diagrams/*.png` (see top-level `README.md`).

Critical integration points & dataflows (explicit)
- Ingestion → Kafka → Usage → InfluxDB & Alerts → Alerting consumer
  - Topic `energy-usage`: produced by `ingestion-service` (`ingestion-service/src/main/java/com/leetjourney/ingestion_service/service/IngestionService.java`) and consumed by `usage-service` (`usage-service/src/main/java/com/leetjourney/usage_service/service/UsageService.java`).
  - Topic `energy-alerts`: produced by `usage-service` (aggregation/threshold logic) and consumed by `alert-service` (`alert-service/src/main/java/com/leetjourney/alert_service/service/AlertService.java`).
- InfluxDB usage: `usage-service/src/main/java/com/leetjourney/usage_service/config/InfluxDBConfig.java` and writes/queries in `UsageService.java`.
- MySQL: DB name `home_energy_tracker`, init in `docker/mysql/init.sql`; JDBC URLs appear in services' `src/main/resources/application.properties`. Keycloak uses a separate MySQL instance in Compose (`keycloak-db`).

API Gateway (routing & security)
- Gateway port **9000**; routes under `/api/v1/...` proxy to localhost backends with **circuit breakers** (see `api-gateway/src/main/java/com/leetjourney/api_gateway/route/*.java`).
- **OAuth2 Resource Server** (JWT): most paths require a valid token; **permitAll** list is in `api-gateway/src/main/resources/application.properties` (`security.excluded.urls`—actuator, swagger, api-docs). **`/api/v1/ingestion/**` is not excluded**—calls through the gateway typically need a **Bearer** token from Keycloak (`http://localhost:8091`). For quick unauthenticated pipeline tests, **POST directly to ingestion-service on port 8082** (service has no Spring Security).

Observability & useful endpoints
- Kafka UI: http://localhost:8070 (inspect topics and messages)
- Mailpit (SMTP/web): SMTP **1025**, web UI http://localhost:8025 (outgoing email from `alert-service`)
- InfluxDB (UI/API): http://localhost:8072 (org/bucket/token from `docker-compose.yml` env vars, e.g. bucket `usage-bucket`)
- Keycloak: http://localhost:8091 (admin / admin per Compose; realm import under `docker/keycloak/realms/`)
- Prometheus: http://localhost:9090 — scrapes Spring apps at `/actuator/prometheus` on **host** via `host.docker.internal` (see `docker/prometheus/prometheus.yml`). Run microservices **on the host** with default ports for metrics to appear in Prometheus.
- Grafana: http://localhost:3000 (admin / admin)
- Service ports (defaults in `application.properties`):
  - `user-service` **8080**, `device-service` **8081**, `ingestion-service` **8082**, `usage-service` **8083**, `alert-service` **8084**, `insight-service` **8085**, `api-gateway` **9000**

Example agent actions (curl + checks)
- Post a test event (Kafka traffic; **direct to ingestion**, no JWT):
  - `curl -X POST http://localhost:8082/api/v1/ingestion -H 'Content-Type: application/json' -d '{"deviceId":"dev-1","timestamp":"2026-01-01T12:00:00Z","watts":1200}'`
- Through the **gateway** (requires JWT): `http://localhost:9000/api/v1/ingestion` with `Authorization: Bearer <token>`.
- Verify `usage-service` consumed and wrote to InfluxDB: check `usage-service` logs and query the Influx bucket via HTTP API; also check scheduled aggregation logs (scheduler in `UsageService.java`).
- Force alert: craft a high `watts` payload and confirm Mailpit received an email (web UI at **8025**).

Agent runbook checks (short)
- Confirm ports reachable: **3306** (MySQL), **9094** (Kafka external), **8072** (Influx), **8025** (Mailpit), **8070** (Kafka UI), **8091** (Keycloak), **9090** (Prometheus), **3000** (Grafana)
- Confirm Kafka topics exist and show message flow (Kafka UI or service logs)
- Confirm Influx writes by querying the bucket referenced in `docker-compose.yml` envs
- Check service logs: `docker compose logs <container>` or run the JAR locally and capture stdout

Project-specific conventions
- Maven wrapper present in each service — prefer `./mvnw`.
- Package names use underscores: e.g. `com.leetjourney.ingestion_service` (see each service `HELP.md` which documents this change).
- Kafka bootstrap server for **host-based** service runs: **`localhost:9094`** (external advertised listener in `docker-compose.yml`). Services' `application.properties` should use this when not on the Docker network.
- JSON type mapping for Kafka consumers is configured in service properties (look for `spring.kafka.consumer.properties.spring.json.type.mapping`).

Files to reference when automating (examples)
- `docker-compose.yml` — infra and envs
- `docker/mysql/init.sql` — DB bootstrap
- `docker/prometheus/prometheus.yml` — Prometheus scrape targets
- `ingestion-service/src/main/java/com/leetjourney/ingestion_service/controller/IngestionController.java`
- `ingestion-service/src/main/java/com/leetjourney/ingestion_service/service/IngestionService.java`
- `usage-service/src/main/java/com/leetjourney/usage_service/service/UsageService.java`
- `usage-service/src/main/java/com/leetjourney/usage_service/config/InfluxDBConfig.java`
- `alert-service/src/main/java/com/leetjourney/alert_service/service/AlertService.java`
- `api-gateway/src/main/java/com/leetjourney/api_gateway/route/UserServiceRoutes.java` (and sibling route classes)
- `api-gateway/src/main/java/com/leetjourney/api_gateway/config/SecurityConfig.java`

Notes
- Java version: use **JDK 21** (declared in each module POM).
- The top-level `README.md` and each service `HELP.md` contain additional module-specific hints.

End of AGENTS.md
