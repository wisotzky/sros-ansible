# Contributing

Thank you for your interest in improving the `nokia.sros` Ansible collection! This guide captures the key expectations for code changes, documentation updates, and release management.

## Prerequisites

* Python 3.8 or newer and `pip`
* Docker Engine 20.10+ for running the SR OS container images
* Access to licensed SR OS container images (for example from Nokia's GHCR registry)

## Local development workflow

1. Create a Python virtual environment and install dependencies:
   ```bash
   python -m venv .venv
   source .venv/bin/activate
   ./tools/run.sh deps
   ```
2. Run the static checks and unit validations:
   ```bash
   ./tools/run.sh sanity
   ```
3. Start an SR OS container and execute the integration tests. The helper script pulls the requested image, waits until the control plane is reachable, and executes `ansible-test` automatically:
   ```bash
   export SROS_CONTAINER_IMAGE=ghcr.io/nokia/sros-container:23.7.R1
   export SROS_LICENSE_FILE=$HOME/.licenses/sros.lic
    export SROS_CONTAINER_EXTRA_ARGS="--privileged"
   export SROS_USERNAME=admin
   export SROS_PASSWORD=admin
   ./tools/run.sh integration --targets device_info
   ```
4. Build the distributable collection archive when you are ready to test the Galaxy packaging format:
   ```bash
   ./tools/run.sh build
   ```

### Repository secrets for CI

CI integration tests require credentials for the private SR OS container registry and a base64-encoded license file. Configure the following repository secrets in GitHub before enabling the workflow:

| Secret name | Purpose |
|-------------|---------|
| `SROS_REGISTRY` | Registry host, for example `ghcr.io`. |
| `SROS_REGISTRY_USERNAME` | Account used to authenticate to the registry (typically your GitHub username). |
| `SROS_REGISTRY_PASSWORD` | Personal access token with `read:packages` scope. |
| `SROS_CONTAINER_LICENSE_B64` | Base64-encoded license contents produced with `base64 -w0 /path/to/sros.lic`. |
| `SROS_USERNAME` *(optional)* | Overrides the device username used in integration tests (defaults to `admin`). |
| `SROS_PASSWORD` *(optional)* | Overrides the device password used in integration tests (defaults to `admin`). |

When running tests locally you can reuse the same credentials via environment variables (`SROS_REGISTRY`, `SROS_REGISTRY_USERNAME`, `SROS_REGISTRY_PASSWORD`, `SROS_LICENSE_FILE`) or log in with `docker login` ahead of time.

## Coding standards

* Follow the module and plugin layout used in the [Ansible community collections](https://docs.ansible.com/ansible/latest/dev_guide/developing_modules_general.html).
* Document new modules using the in-file `DOCUMENTATION`, `EXAMPLES`, and `RETURN` blocks.
* Ensure your changes keep the Galaxy metadata (`galaxy.yml`) accurate.
* Update both `CHANGELOG.md` and `README.md` whenever behaviour or dependencies change.

## Commit & pull request expectations

* Prefer small, focused commits that explain **what** and **why**.
* Reference GitHub issues in commit messages or PR descriptions where applicable.
* Every PR must pass the GitHub Actions CI pipeline before it can be merged.
* Add or update tests when fixing bugs or introducing new features. At minimum, extend the integration test suite under `tests/integration/targets`.

## Release process

1. Update `galaxy.yml` with the new semantic version.
2. Add a new entry to `CHANGELOG.md` describing the changes.
3. Tag the release (for example `git tag v1.9.0`) and push the tag to GitHub.
4. Creating a GitHub release automatically triggers the workflow that builds the collection and publishes it to Ansible Galaxy. Ensure the `ANSIBLE_GALAXY_API_KEY` secret is present in the repository settings.

## Need help?

Open a discussion or issue in the repository and describe the environment, SR OS version, and exact failure symptoms. The maintainers and community collaborators monitor the queue and will respond as time permits.
