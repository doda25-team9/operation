## Assignment 1 - Version, Release & Containerization

### Links to all Repositories:

- model-service: https://github.com/doda25-team9/model-service/tree/a1
- app: https://github.com/doda25-team9/app/tree/a1
- lib-version: https://github.com/doda25-team9/lib-version/tree/a1
- operation: https://github.com/doda25-team9/operation/tree/a1

### Finished Features and Where to Find Them:

#### Fully implemented (at least the basic requirements):

- F1: [lib-version/src/main/java/com/doda25/team9/libversion/VersionUtil.java at a1 · doda25-team9/lib-version](https://github.com/doda25-team9/lib-version/blob/a1/src/main/java/com/doda25/team9/libversion/VersionUtil.java)

- F2: [lib-version/.github/workflows/release.yml at a1 · doda25-team9/lib-version](https://github.com/doda25-team9/lib-version/blob/a1/.github/workflows/release.yml)

- F3:

  - [model-service/Dockerfile at a1 · doda25-team9/model-service](https://github.com/doda25-team9/model-service/blob/a1/Dockerfile)
  - [app/Dockerfile at a1 · doda25-team9/app](https://github.com/doda25-team9/app/blob/a1/Dockerfile)

- F4: Please follow README instructions [doda25-team9/app at a1](https://github.com/doda25-team9/app/tree/a1?tab=readme-ov-file#multi-architecture-support-f4)

- F5: [app/Dockerfile at a1 · doda25-team9/app](https://github.com/doda25-team9/app/blob/a1/Dockerfile)

- F6: In both repos, please read the README instructions

  - [app/Dockerfile at a1 · doda25-team9/app](https://github.com/doda25-team9/app/blob/a1/Dockerfile)
  - [model-service/Dockerfile at a1 · doda25-team9/model-service](https://github.com/doda25-team9/model-service/blob/a1/Dockerfile)

- F7: Please read the README instructions

  - [operation/docker-compose.yml at a1 · doda25-team9/operation](https://github.com/doda25-team9/operation/blob/a1/docker-compose.yml)
  - [README](https://github.com/doda25-team9/operation/blob/a1/README.md)

- F8: `release.yml` file in both repos, please read README for more information

  - [model-service/.github/workflows at a1 · doda25-team9/model-service](https://github.com/doda25-team9/model-service/tree/a1/.github/workflows)
  - [app/.github/workflows at a1 · doda25-team9/app](https://github.com/doda25-team9/app/tree/a1/.github/workflows)

- F9:

  - [model-service/ at a1 · doda25-team9/model-service](https://github.com/doda25-team9/model-service/tree/a1#automated-container-image-releases-f9)
  - [model-service/.github/workflows/train_release_model.yml at a1 · doda25-team9/model-service](https://github.com/doda25-team9/model-service/blob/a1/.github/workflows/train_release_model.yml)

- F10: [model-service/Dockerfile at a1 · doda25-team9/model-service](https://github.com/doda25-team9/model-service/blob/a1/Dockerfile)

#### Partially implemented:

- F11: The workflow does not yet correctly push the version update to main after the release
  - [lib-version/.github/workflows/pre-release.yml at a1 · doda25-team9/lib-version](https://github.com/doda25-team9/lib-version/blob/a1/.github/workflows/pre-release.yml)
  - [lib-version/.github/workflows/release.yml at a1 · doda25-team9/lib-version](https://github.com/doda25-team9/lib-version/blob/a1/.github/workflows/release.yml)
