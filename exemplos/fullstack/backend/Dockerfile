# ==============================================================================
# Multi-stage build: Maven (compilacao) + JRE (runtime)
#
# Boas praticas aplicadas:
#   - Multi-stage build: imagem final contem apenas o JRE e o .jar
#   - Usuario nao-root: a aplicacao roda como "spring" (sem privilegios)
#   - Limites de memoria JVM: evita consumo excessivo no cluster
#   - Sem shell de debug: imagem baseada em Alpine (superficie minima)
#   - Cache de dependencias: camada do pom.xml separada do codigo-fonte
# ==============================================================================

# --- Stage 1: Build ---
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

# Criar usuario nao-root para executar a aplicacao
RUN addgroup -S spring && adduser -S spring -G spring

# Copiar apenas o .jar compilado (nada de codigo-fonte na imagem final)
COPY --from=build --chown=spring:spring /app/target/*.jar app.jar

# Trocar para usuario sem privilegios
USER spring:spring

EXPOSE 8080

# Limitar memoria da JVM para respeitar os recursos do cluster
ENTRYPOINT ["java", "-Xmx384m", "-Xms256m", "-jar", "app.jar"]
