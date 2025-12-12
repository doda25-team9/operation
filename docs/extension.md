# Extension Proposal: Mandatory Automated Pull Request Checks

This file contains the Extension Proposal of our project.

### 1. The Shortcoming: Unreliable Manual Verification
**Related Assignment:** Assignment 3 (Deployment), Assignment 1 (Containerization), & Contribution Process

Currently, our project uses a Pull Request (PR) workflow across all our repositories (`operations`, `app`, `model-service`, `lib-version`). However, the verification process is entirely manual. When a team member opens a PR, we rely on another person to review the code visually or try to run it on their local machine.

This is a critical shortcoming because it leads to **"works on my machine"** problems. During the peer reviews for our previous assignments, we received feedback that our deployment scripts failed on other students' clusters, even though they worked perfectly on our local setups. This happens because our local environments might have specific configurations (like cached Docker layers or different tool versions) that hide errors.

Without automated checks, we frequently risk merging broken code into the `main` branch. For example, a syntax error in the `app` code or a typo in the `operations` configuration will break the automated release pipelines (from Assignment 1) and the deployment (Assignment 3) for everyone.

### 2. Proposed Extension: Automated Validation Pipelines

To fix this, we propose implementing **Mandatory Automated Validation** for all repositories.

We will replace manual verification with automated pipelines using **GitHub Actions**. We will enforce this using **GitHub Branch Protection Rules**, which will physically disable the "Merge" button until the specific checks for that repository pass.

**Project Refactoring**

We will create a new workflow file (`.github/workflows/verify-pr.yml`) in each repository with checks tailored to the specific content:

1.  **Operations Repository (Infrastructure):**
    * **Helm Lint:** Runs `helm lint` to catch basic syntax errors in our charts.
    * **Schema Validation (Dry Run):** Runs `helm template . | kubeconform`. This renders our templates and validates the output against the official Kubernetes schema. It catches complex errors (like using strings for integer fields) that humans often miss.

2.  **App & Model-Service (Application Code):**
    * **Style Check (Linting):** Runs a linter (like `flake8` for Python or `Checkstyle` for Java). This ensures code format is consistent without us having to argue about it in comments.
    * **Docker Build (Dry Run):** Runs `docker build .` (without pushing). This guarantees that the `Dockerfile` is valid and the application creates a container successfully. This prevents us from merging code that breaks the automated release pipeline later.

3.  **Lib-Version (Library):**
    * **Compilation Check:** Runs `mvn compile`. This proves the code is syntactically correct and can be packaged, ensuring the library is actually buildable before we try to release it.

### 3. Implementation Plan (1-5 Days Effort)

This extension is non-trivial because it requires configuring CI environments for multiple repositories and tools.

* **Day 1 (Operations):** Install `helm` and `kubeconform` in the CI runner. Create the workflow to lint and validate the Kubernetes manifests.
* **Day 2 (Code Repos):** Configure the Docker build steps for `app` and `model-service`. Add the `mvn compile` step for `lib-version`.
* **Day 3 (Linting):** Add the linter configurations (e.g., `.flake8`) to the repositories and add the linting steps to the workflows.
* **Day 4 (Enforcement):** Go into the GitHub settings for the `main` branch on **all four repositories**. Enable "Require status checks to pass before merging" and select the specific jobs we created.

### 4. Expected Outcome & Experiment

**Outcome:**
The expected outcome is a guaranteed stable `main` branch across the entire project. We expect to minimize the peer review issues where projects fail on other machines, because the CI pipeline acts as a "neutral third party" that verifies every change. It improves our contribution process by catching typos, compilation errors, and broken Dockerfiles immediately.

**Experiment (Verification):**
We can verify this design with a **"Rejection" Experiment**:

1.  **Hypothesis:** The automated pipelines will catch errors in both code and configuration that a human might miss.
2.  **Experiment Steps:**
    * **Case A (Operations):** Open a PR in `operations` where a numeric value in `values.yaml` is changed to a string (invalid K8s schema).
    * **Case B (Model-Service):** Open a PR in `model-service` with a valid Python script but a broken `Dockerfile` (e.g., referencing a non-existent base image).
3.  **Success Metric:** In our current process, these might be merged if the reviewer is tired, not 100% focused, or if they somehow have an old setup running that they test the new PR with. In the new system, **Case A** must fail the `kubeconform` check, and **Case B** must fail the `docker build` check. In both cases, the PR merge button must be disabled automatically.

### 5. Reflection

**Assumptions & Downsides:** 
* **Wait Time:** Running these checks on every Pull Request will increase the time before we are able to merge. Since some of the assignments were designed to have tasks that depend on each other, it was crucial for our process that we work fast so we do not block the next person that will work. With the added waiting time for pipelines to run, it might be harder for everyone to start their tasks on time.
* **Lack of Tests:** We currently do not have a series of test to make sure the previous assignments still work fine when we merge some new functionality. Since we don't have these set in place, this added pipeline can still oversee specific features from either older or newer assignments, which does not entirely get rid of the peer issues when running our code.

### 6. References

* **Continuous Integration:** Martin Fowler explains that a key part of Release Engineering is "Self-Testing Code." He argues that the system must detect regressions automatically on every commit, rather than relying on humans.
    * *Source:* Fowler, M. (2006). *Continuous Integration*. [Link](https://martinfowler.com/articles/continuousIntegration.html)
* **Automated Review:** Google's engineering guide states that "automated tasks should be done by automation." Things like formatting and basic correctness should be checked by scripts (presubmits) so humans can focus on the actual logic.
    * *Source:* Google Engineering Practices Documentation. *The Standard of Code Review*. [Link](https://google.github.io/eng-practices/review/reviewer/standard.html)
* **Validating Kubernetes Manifests:** DevOps discussions highlight that relying on `kubectl apply` to find errors is too late. Using schema validators like `kubeconform` in the CI pipeline is the standard way to prevent "configuration drift."
    * *Source:* StackOverflow Discussion. *Possible to do a "dry run" validation of files?* [Link](https://stackoverflow.com/questions/32128936/possible-to-do-a-dry-run-validation-of-files/78071020#78071020)
* **Shift-Left Security:** OWASP recommends adding checks as early as possible (in the PR). By adding these checks now, we prevent broken configurations from ever reaching our production branch.
    * *Source:* OWASP. *DevSecOps Guideline*. [Link](https://owasp.org/www-project-devsecops-guideline/latest/00a-Overview)