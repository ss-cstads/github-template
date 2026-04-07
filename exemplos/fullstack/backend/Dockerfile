# ==============================================================================
# Dockerfile — Backend Spring Boot
#
# Hardening aplicado:
#   - Multi-stage build: imagem final contem apenas JRE + .jar
#   - Usuario nao-root: roda como "spring" (sem privilegios)
#   - .jar somente leitura (444): impede modificacao em runtime
#   - JVM container-aware: respeita limites de memoria do cgroup
#   - Imagem Alpine: superficie de ataque minima
#   - HEALTHCHECK: Docker monitora saude do container
# ==============================================================================

# --- Build ---
FROM maven:3.9-eclipse-temurin-21-alpine AS build
WORKDIR /app

COPY pom.xml .
RUN mvn dependency:go-offline -B

COPY src ./src
RUN mvn package -DskipTests -B

# --- Runtime ---
FROM eclipse-temurin:21-jre-alpine
WORKDIR /app

RUN addgroup -S spring && adduser -S spring -G spring

COPY --from=build --chown=spring:spring --chmod=444 /app/target/*.jar app.jar

USER spring:spring

EXPOSE 8080

HEALTHCHECK --interval=15s --timeout=3s --start-period=30s --retries=3 \
  CMD wget -qO- http://localhost:8080/actuator/health || exit 1

ENTRYPOINT ["java", \
  "-XX:+UseContainerSupport", \
  "-XX:MaxRAMPercentage=75.0", \
  "-Djava.security.egd=file:/dev/./urandom", \
  "-jar", "app.jar"]
