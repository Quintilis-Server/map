# Multi-stage build for Map service
# Stage 1: Build stage
FROM maven:3.9-eclipse-temurin-25-noble AS build

WORKDIR /workspace

# Copy common module first for better layer caching
COPY common ./common
COPY map/pom.xml ./map/
COPY map/.mvn ./map/.mvn
COPY map/mvnw ./map/

# Copy map source
COPY map/src ./map/src

# Build the application
WORKDIR /workspace/map
RUN mvn clean package -DskipTests


# Stage 2: Runtime stage
FROM eclipse-temurin:25-jre-noble

WORKDIR /app

# Create a non-root user
RUN groupadd -r appuser && useradd -r -g appuser appuser

# Copy the built jar from build stage
COPY --from=build /workspace/map/target/*.jar app.jar

# Change ownership
RUN chown -R appuser:appuser /app

# Switch to non-root user
USER appuser

# Expose the application port
EXPOSE 8080

# Set JVM options for container environment
ENV JAVA_OPTS="-XX:+UseContainerSupport -XX:MaxRAMPercentage=75.0"

# Run the application
ENTRYPOINT ["sh", "-c", "java $JAVA_OPTS -jar app.jar"]
