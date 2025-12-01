## ==========================================
## API Gateway Manager Dockerfile (Gradle)
## ==========================================
#
## Stage 1: Build
#FROM gradle:8.5-jdk17 AS build
#
#WORKDIR /app
#
## Copy Gradle wrapper and build files
#COPY gradle gradle
#COPY gradlew .
#COPY settings.gradle .
#COPY build.gradle .
#
## Grant execute permission for gradlew
#RUN chmod +x gradlew
#
## Download dependencies (cache layer)
#RUN ./gradlew dependencies --no-daemon
#
## Copy source code
#COPY src ./src
#
## Build the application
#RUN ./gradlew clean bootJar --no-daemon
#
## Stage 2: Runtime
#FROM eclipse-temurin:17-jre-alpine
#
#WORKDIR /app
#
## Install curl for healthcheck
#RUN apk add --no-cache curl
#
## Copy the built jar from build stage
#COPY --from=build /app/build/libs/*.jar app.jar
#
## Create a non-root user
#RUN addgroup -S spring && adduser -S spring -G spring
#USER spring:spring
#
## Expose port
#EXPOSE 9500
#
## Health check
#HEALTHCHECK --interval=30s --timeout=10s --start-period=60s --retries=3 \
#  CMD curl -f http://localhost:9500/actuator/health || exit 1
#
## Run the application
#ENTRYPOINT ["java", \
#  "-Djava.security.egd=file:/dev/./urandom", \
#  "-Dspring.profiles.active=docker", \
#  "-jar", \
#  "app.jar"]


# TODO: Add healthcheck
# ==========================================
# API Gateway Manager Dockerfile (Gradle)
# ==========================================

# Stage 1: Build
FROM gradle:8.5-jdk17 AS build

WORKDIR /app

# Copy Gradle wrapper and build files
COPY gradle gradle
COPY gradlew .
COPY settings.gradle .
COPY build.gradle .

# Grant execute permission for gradlew
RUN chmod +x gradlew

# Download dependencies (cache layer)
RUN ./gradlew dependencies --no-daemon

# Copy source code
COPY src ./src

# Build the application
RUN ./gradlew clean bootJar --no-daemon

# Stage 2: Runtime
FROM eclipse-temurin:17-jre-alpine

WORKDIR /app

# Install curl for healthcheck
RUN apk add --no-cache curl

# Copy the built jar from build stage
COPY --from=build /app/build/libs/*.jar app.jar

# Create a non-root user
RUN addgroup -S spring && adduser -S spring -G spring
USER spring:spring

# Expose port
EXPOSE 9500

# Health check
HEALTHCHECK --interval=30s --timeout=10s --start-period=60s --retries=3 \
  CMD curl -f http://localhost:9500/actuator/health || exit 1

# FLEXIBLE PROFILE: Can be overridden by env var
# Default to docker for backward compatibility with docker-compose
# Kubernetes deployment will override this via ConfigMap/env
ENV SPRING_PROFILES_ACTIVE=docker

# Run the application
# Profile is controlled by SPRING_PROFILES_ACTIVE env var
ENTRYPOINT ["java", \
  "-Djava.security.egd=file:/dev/./urandom", \
  "-jar", \
  "app.jar"]