# ==============================================================================
# Dockerfile — Java (Spring Boot, Quarkus, etc.)
#
# Boas praticas aplicadas:
#   - Multi-stage build: Maven compila, imagem final so tem o JRE + .jar
#   - Usuario nao-root: aplicacao roda como "spring" (sem privilegios)
#   - Cache de camadas: pom.xml copiado antes do codigo (acelera rebuilds)
#   - Limites de memoria JVM: evita consumo excessivo no cluster
#   - Imagem Alpine: superficie de ataque minima (~100MB)
# ==============================================================================

# --- Stage 1: Build com Maven ---
FROM maven:3.9-eclipse-temurin-21-alpine AS build
WORKDIR /app

# Copiar apenas o pom.xml primeiro (cache de dependencias)
COPY pom.xml .
RUN mvn dependency:go-offline -B

# Copiar codigo-fonte e compilar
COPY src ./src
RUN mvn package -DskipTests -B

# --- Stage 2: Runtime ---
FROM eclipse-temurin:21-jre-alpine
WORKDIR /app

# Criar usuario sem privilegios
RUN addgroup -S spring && adduser -S spring -G spring

# Copiar apenas o .jar compilado
COPY --from=build --chown=spring:spring /app/target/*.jar app.jar

USER spring:spring

# Porta onde a aplicacao escuta (deve bater com job.nomad.hcl)
EXPOSE 8080

# Limitar memoria da JVM para respeitar os recursos do cluster
ENTRYPOINT ["java", "-Xmx384m", "-Xms256m", "-jar", "app.jar"]
