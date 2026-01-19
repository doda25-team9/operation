# Assignment 1: Local Docker Setup

This guide explains how to run the **SMS Checker** application locally using Docker Compose. This method is used for **Assignment 1** and for quick local development without the overhead of Kubernetes.

## Prerequisites

WHAT KONNA SAID

---

## Configuration

The Docker Compose setup is controlled by a `.env` file located in the root of the `operation` repository.

**Default Configuration:**
```
APP_PORT=8080
MODEL_PORT=8081
APP_IMAGE=ghcr.io/doda25-team9/app:latest
MODEL_IMAGE=ghcr.io/doda25-team9/model-service:latest
```

#### Variable overview:
- `APP_PORT`:
  Port on the host machine where the web application will be exposed. After startup, the app is accessible at:
  `http://localhost:<APP_PORT>/sms`

- `MODEL_PORT`:
  Internal port used by the model-service container.
  The app communicates with the model-service over the Docker network using this port.

- `APP_IMAGE`:
  Docker image for web application.
  You can change this to a specific version tag (e.g.: `:0.1.0`) instead of `:latest` if needed.

- `MODEL_IMAGE`:
  Docker image for the model-service.
  You can change this to a specific version tag (e.g.: `:0.1.0`) instead of `:latest` if needed.

You can adjust ports or change image versions by editing this file before running `docker compose up`.

### Running the Full Application

Please follow these steps to start the application:

```
cd operation
docker compose pull
docker compose up
```

This starts:

- `app` (exposed externally)
- `model-service` (internal only, so not exposed to host)

You can access the web application in your browser [http://localhost:8080/sms](http://localhost:8080/sms). 
Alternatively, if you have specified a different `APP_PORT` in your `.env`, replace `8080` with that port.

### Useful Docker Compose Commands

| Action                               | Command                      | Description                            |
| ------------------------------------ | ---------------------------- | -------------------------------------- |
| **Start everything**                 | `docker compose up`          | Starts all services (shows logs)       |
| **Start in background**              | `docker compose up -d`       | Runs services in detached mode         |
| **Stop all running services**        | `docker compose down`        | Stops and removes containers, networks |
| **Rebuild images**                   | `docker compose up --build`  | Rebuilds images before starting        |
| **View logs**                        | `docker compose logs`        | Shows combined logs from all services  |
| **View logs for a specific service** | `docker compose logs app`    | Shows logs only for the app            |
| **Restart one service**              | `docker compose restart app` | Restarts only the app service          |
