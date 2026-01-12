FROM maven:3.9.5-eclipse-temurin-21 AS builder
WORKDIR /workspace

# Copiar pom y fuentes
COPY pom.xml .
COPY src ./src

# Construir el JAR (omitiendo tests para velocidad)
RUN mvn -B -DskipTests package

FROM eclipse-temurin:21-jre
WORKDIR /app

# Copiar artefacto construido
COPY --from=builder /workspace/target/*.jar app.jar

EXPOSE 8080
ENTRYPOINT ["java","-jar","/app/app.jar"]
