# Jenkins Pipeline – GeneXus Java Application Deployment with Docker and Google Cloud

## Overview

This project implements a **CI/CD pipeline using Jenkins** to build, deploy, and publish a **GeneXus-generated Java application**.

The pipeline prepares the deployment artifacts, builds a Docker image on a remote Linux server, deploys the application inside a Docker container, and pushes the image to **Google Cloud Artifact Registry**.

---

## High-Level Workflow

1. Jenkins executes the pipeline defined in the `Jenkinsfile`.
2. Deployment content is prepared and copied to the remote server.
3. A Docker image is built on the remote server.
4. The application is deployed using Docker Compose.
5. Old Docker images are removed to free disk space.
6. The Docker image is pushed to Google Cloud Artifact Registry.

---

## Technologies Used

- Jenkins – CI/CD automation and orchestration
- GeneXus – Low-code platform generating the Java application
- Java / Apache Tomcat – Application runtime
- Docker – Application containerization
- Docker Compose – Container orchestration
- Bash & Batch scripts – Automation
- SSH / SCP – Secure remote server access
- Google Cloud Artifact Registry – Container image storage
- gcloud CLI – Google Cloud authentication

---

## Project Structure

Pipeline_Jenkins_GeneXus_Java_Docker_Google_Cloud/
- Jenkinsfile
- bat/
- sh/
- docker/
- README.md

---

## Pipeline Steps

### 1. Prepare Docker Deployment Content
Copies the WAR file, Docker configuration, and scripts to the remote server.

### 2. Build Docker Image
Builds the Docker image on the remote server using Docker.

### 3. Deploy Docker Image
Stops running containers and starts the new version using Docker Compose.

### 4. Cleanup Old Docker Images
Keeps only the most recent images to optimize disk usage.

### 5. Push Docker Image to Google Cloud
Authenticates and pushes the image to Artifact Registry.

---

## Security Considerations

- Credentials are managed using Jenkins Credentials
- SSH key-based authentication is used
- Google Cloud access is controlled via Service Accounts

---

## Conclusion

This pipeline provides an automated and enterprise-ready solution for deploying GeneXus Java applications using Docker and Google Cloud.
