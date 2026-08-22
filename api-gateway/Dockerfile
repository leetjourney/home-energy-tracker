# syntax=docker/dockerfile:1.4
FROM eclipse-temurin:21-jre

RUN addgroup --system spring && adduser --system --ingroup spring spring

WORKDIR /app
COPY target/*.jar /app/app.jar
RUN chown spring:spring /app/app.jar

USER spring
EXPOSE 9000
ENTRYPOINT ["java", "-jar", "/app/app.jar"]
