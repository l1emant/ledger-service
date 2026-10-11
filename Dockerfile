# ---------- build stage ----------
FROM maven:3.9-eclipse-temurin-25 AS build

WORKDIR /app

COPY pom.xml .
RUN mvn -B dependency:go-offline

COPY src ./src
RUN mvn -B clean package -DskipTests

# ---------- runtime stage ----------
FROM eclipse-temurin:25-jre-alpine

RUN addgroup -S app && adduser -S app -G app

WORKDIR /app

COPY --from=build /app/target/*.jar app.jar

RUN chown -R app:app /app
USER app

EXPOSE 8080

ENV JAVA_OPTS="-XX:MaxRAMPercentage=70 -XX:+UseG1GC -XX:+ExitOnOutOfMemoryError"

HEALTHCHECK --interval=30s --timeout=3s --start-period=40s --retries=3 \
  CMD wget -qO- http://localhost:8080/actuator/health || exit 1

ENTRYPOINT ["sh", "-c", "exec java $JAVA_OPTS -jar app.jar"]
