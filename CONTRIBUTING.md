# SR OS Ansible Collection Developer Guide

Thank you for your interest in improving the `nokia.sros` Ansible collection! This guide captures the initial steps and key expectations for code changes, documentation updates, and release management.

## Prerequisites

* Python 3.9 or newer and `pip`
* Docker for running the SR OS container images
* Access to SR OS container images and licenses

## Quick Start

Start with cloning the repo:

```bash
git clone git@github.com:nokia/sros-ansible.git
cd sros-ansible
```

Deploy the lab to support the tests:

```bash
./run.sh deploy-lab
```

Run the automated suite of tests to make sure nothing is missing. This will also prepare a dev environment (you have to make sure the venv with ansible is activated or ansible-playbook is in your path):

```bash
./run.sh test
```

To validate that the code passes Ansible's sanity check, run:

```bash
./run.sh sanity-test
```





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

## Development

### Running the automated checks locally

The `tools/run.sh` helper mirrors the CI workflow and keeps prerequisites in one place:

```bash
python -m venv .venv
source .venv/bin/activate
./tools/run.sh deps
./tools/run.sh sanity
./tools/run.sh build
```

### Integration testing with containerised SR OS releases

Integration tests rely on licensed SR OS container images. Provide the credentials and image that match your lab, then invoke the helper script:

```bash
export SROS_CONTAINER_IMAGE=ghcr.io/nokia/sros-container:23.7.R1
export SROS_LICENSE_FILE=$HOME/.licenses/sros.lic
export SROS_USERNAME=admin
export SROS_PASSWORD=admin
./tools/run.sh integration --targets device_info
```

#### Authenticating to private registries and licensing the container

The Nokia SR OS container hosted on GitHub Container Registry (GHCR) requires credentials and a valid license file.

1. Generate a [personal access token](https://github.com/settings/tokens/new) from your GitHub account with the `read:packages` scope.
2. Log in locally using Docker (replace `<username>` with your GitHub handle):
   ```bash
   echo '<token>' | docker login ghcr.io -u <username> --password-stdin
   ```
   Alternatively, export the following variables before running `tools/run.sh integration` so the helper can authenticate on your behalf:
   ```bash
   export SROS_REGISTRY=ghcr.io
   export SROS_REGISTRY_USERNAME=<username>
   export SROS_REGISTRY_PASSWORD='<token>'
   ```
3. Obtain a SR OS container license file from Nokia support and set `SROS_LICENSE_FILE` to its absolute path.

For GitHub Actions, store the same information as repository secrets so CI can authenticate and mount the license:

| Secret name | Purpose |
|-------------|---------|
| `SROS_REGISTRY` | Registry host, for example `ghcr.io`. |
| `SROS_REGISTRY_USERNAME` | Username used to authenticate to the registry. |
| `SROS_REGISTRY_PASSWORD` | Personal access token with `read:packages`. |
| `SROS_CONTAINER_LICENSE_B64` | Base64-encoded license contents: `base64 -w0 /path/to/sros.lic`. |
| `SROS_USERNAME` *(optional)* | Device username injected into the integration tests (defaults to `admin`). |
| `SROS_PASSWORD` *(optional)* | Device password injected into the integration tests (defaults to `admin`). |

The script downloads the image (performing `docker login` if already configured), exposes SSH on `localhost:2222` and NETCONF on `localhost:2830`, waits for the control plane to boot, and executes `ansible-test integration` against the inventory in `tests/integration`.
Set `SROS_CONTAINER_EXTRA_ARGS="--privileged"` if your SR OS image requires elevated container permissions.

### Releasing

Tagged releases on GitHub automatically build the collection artifact and publish it to Ansible Galaxy by using the
`ANSIBLE_GALAXY_API_KEY` secret. To perform a dry run locally you can execute:

```bash
./tools/run.sh build
ansible-galaxy collection publish dist/nokia-sros-*.tar.gz --api-key <token>
```

Refer to the [CONTRIBUTING](CONTRIBUTING.md) guide for full details on coding conventions, testing expectations, and the release checklist.

## Need help?

Open a discussion or issue in the repository and describe the environment, SR OS version, and exact failure symptoms. The maintainers and community collaborators monitor the queue and will respond as time permits.
