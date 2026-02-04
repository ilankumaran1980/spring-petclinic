# Stage 1: Build the application using Maven
# Using the AWS Public ECR mirror to avoid Docker Hub rate limits
FROM public.ecr.aws/docker/library/eclipse-temurin:17-jdk-jammy AS build

# Set the working directory inside the container
WORKDIR /app

# Copy the Maven wrapper and pom.xml first to leverage Docker cache
# This avoids re-downloading dependencies if only your code changes
COPY .mvn/ .mvn
COPY mvnw pom.xml ./
RUN ./mvnw dependency:resolve

# Copy the source code and build the final JAR file
COPY src ./src
RUN ./mvnw package -DskipTests

# Stage 2: Create the final production image
# Use a smaller JRE (Runtime) image for better security and smaller size
FROM public.ecr.aws/docker/library/eclipse-temurin:17-jre-jammy

WORKDIR /app

# Copy only the compiled .jar file from the 'build' stage
# The wildcard *.jar handles different version numbers in the filename
COPY --from=build /app/target/*.jar app.jar

# Expose the default Spring Boot port
EXPOSE 8080

# Command to run the application
ENTRYPOINT ["java", "-jar", "app.jar"]
