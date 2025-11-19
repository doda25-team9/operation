# Operation -- Running the Full SMS Checker Application

This repository contains the runtime configuration for the full SMS Checker system:

- `app` (Java frontend/backend service)
- `model-service` (Python ML model API)

Using **Docker Compose**, you can start both components with one command.
This README contains all instructions required for a new user to run the final integrated application.

## Repository Structure

These are all related repositories:

- [app](https://github.com/doda25-team9/app) — frontend/backend Java application
- [model-service](https://github.com/doda25-team9/model-service) — ML API
- [lib-version](https://github.com/doda25-team9/lib-version) — shared version library
- [operation](https://github.com/doda25-team9/operation) — this repository

This repository (`operation`) contains:

```
operation/
    - docker-compose.yml
    - .env
    - README.md      (this file)
```

## Prerequisites

Before running anything, make sure you have:

- Docker
- Docker Compose
- Cloned all four repositories into a single folder:

```
your-folder/
    app/
    model-service/
    lib-version/
    operation/
```

- Trained model files are present.

The **model-service** requires trained `.joblib` files:

```
model.joblib
preprocessor.joblib
preprocessed_data.joblib
misclassified_msgs.txt
accuracy_scores.png
```

If you don't have these output files yet, follow the training instructions in `model-service/README.md`.

Once you have done that, you should have a folder called `model-service/output/`. Copy that output folder into `operation/output/`.

## Configuration (.env)

The compose setup uses a `.env` file:

```
APP_PORT=8080
MODEL_PORT=8081
APP_IMAGE=ghcr.io/doda25-team9/app:latest
MODEL_IMAGE=ghcr.io/doda25-team9/model-service:latest
```

You can change ports or image versions here.

## Running the Full Application

Navigate to **operation**:

```
cd operation
docker compose pull
docker compose up
```

This starts:

- `app` (exposed externally)
- `model-service` (internal only, so not exposed to host)

### Check if the application is running

Open:
http://localhost:8080/sms
or replace 8080 in the link above with the app port you find in the .env file

If you see the SMS Checker interface, can submit messages and get a model agreement/disagreement message back after pressing _Check_, everything works.

## Useful Docker Compose Commands

| Action                               | Command                      | Description                            |
| ------------------------------------ | ---------------------------- | -------------------------------------- |
| **Start everything**                 | `docker compose up`          | Starts all services (shows logs)       |
| **Start in background**              | `docker compose up -d`       | Runs services in detached mode         |
| **Stop all running services**        | `docker compose down`        | Stops and removes containers, networks |
| **Rebuild images**                   | `docker compose up --build`  | Rebuilds images before starting        |
| **View logs**                        | `docker compose logs`        | Shows combined logs from all services  |
| **View logs for a specific service** | `docker compose logs app`    | Shows logs only for the app            |
| **Restart one service**              | `docker compose restart app` | Restarts only the app service          |
