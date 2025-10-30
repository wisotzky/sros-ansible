# SR OS Ansible Collection – Developer & Contributor Guide

Thank you for your interest in improving the **`nokia.sros`** Ansible collection!
This guide explains how to set up your development environment, run tests, and contribute changes — following the [Ansible Community Guidelines](https://docs.ansible.com/ansible/latest/community/contributing.html).

---

## Overview

The `nokia.sros` collection provides network automation support for Nokia **SR OS** devices through **CLI** and **NETCONF** interfaces.
Developers can use the included `run.sh` helper script to simplify local development, containerlab deployment, and regression testing.

---

## Prerequisites

Before contributing, ensure your environment includes:

* **Python 3.9 or newer**
* **Ansible Core 2.13 or newer** (recommended)
* **Docker** for running SR OS container images
* **Access** to SR OS container images and a valid license file
* A Linux, macOS, or BSD-like system with common GNU tools (`bash`, `curl`, `make`, etc.)

---

## Quick Start

### 1. Set up a Python virtual environment

```bash
python -m venv .venv
source .venv/bin/activate
./tools/run.sh deps
```

### 2. Clone the repository

```bash
git clone https://github.com/nokia/sros-ansible.git
cd sros-ansible
```

### 3. Install dependencies

```bash
python -m pip install --upgrade pip

sudo apt-get update
sudo apt-get install -y libssh-dev

pip install -r requirements.txt

ansible-galaxy collection install ansible.netcommon
ansible-galaxy collection install ansible.utils
ansible-galaxy collection install community.general
```

Install [containerlab](https://containerlab.dev):

```bash
bash -c "$(curl -sL https://get.containerlab.dev)"
```

### 4. Prepare images and licenses

Pull `nokia_sros` container image(s) and ensure a valid SR OS license file is available.

### 5. Build and install the collection locally

```bash
ansible-galaxy collection install .
```

### 6. Deploy and test the example lab

```bash
cd tests
chmod +x run.sh
./run.sh deploy
```

### 7. Run all regression tests

```bash
./run.sh run --category all --quiet --all
```

### 8. Clean up when finished

```bash
./run.sh destroy
```

---

## Coding Standards

Follow Ansible and Python best practices:

* Use the standard [Ansible module structure](https://docs.ansible.com/ansible/latest/dev_guide/developing_modules_general.html)
* Include `DOCUMENTATION`, `EXAMPLES`, and `RETURN` blocks in every module
* Keep `galaxy.yml` metadata accurate and up to date
* Update `CHANGELOG.md` and `README.md` for user-visible changes
* Validate your work with:

  * `./run.sh sanity` or `./run.sh test`
  * Linting and style checks
  * Unit and integration test suites

---

## Commit & Pull Request Guidelines

* Write **clear, focused commits** that explain both *what* and *why*
* Reference related issues (e.g. `Fixes #42`)
* Ensure all tests pass before requesting review
* Add or update tests for new features or bug fixes
* Maintain consistent docstrings, examples, and return schemas

A pull request can be merged only when:

* All CI checks pass successfully
* A maintainer approves the change
* The update fits the project’s goals and quality standards

---

## Contributing

We welcome all contributions — from small fixes to major enhancements.
Whether you’re reporting a bug, improving documentation, or extending functionality, we’d love your input.

| Type                          | Where to Start                                                                               |
| ----------------------------- | -------------------------------------------------------------------------------------------- |
| 🐞 **Report a bug**           | [Open an issue](https://github.com/nokia/sros-ansible/issues/new?template=bug_report.yml)    |
| 💡 **Propose an enhancement** | [Start a discussion](https://github.com/nokia/sros-ansible/discussions/new?category=ideas)   |
| 🧩 **Submit code or docs**    | [Create a pull request](https://github.com/nokia/sros-ansible/compare)                       |
| 🧰 **Ask for guidance**       | [Join the Q&A discussions](https://github.com/nokia/sros-ansible/discussions/categories/q-a) |

Before submitting a pull request:

* Run all tests (`./run.sh sanity` or `./run.sh test`)
* Follow [PEP 8](https://peps.python.org/pep-0008/) and Ansible plugin guidelines
* Ensure changes are documented and clearly commented
* Update or add integration tests where relevant

---

## Getting Help

If you encounter problems or need support:

1. **Search existing threads**
   Check [open issues](https://github.com/nokia/sros-ansible/issues) or [ongoing discussions](https://github.com/nokia/sros-ansible/discussions) to see if your topic is already covered.

2. **Open a new issue**
   Include:

   * Your **OS**, **Python**, and **Ansible** versions
   * The **SR OS** version used
   * A concise problem description or error log

3. **Discuss broader ideas**
   Start a conversation under [Ideas & Proposals](https://github.com/nokia/sros-ansible/discussions/categories/ideas) for design suggestions or workflow questions.

The maintainers and community collaborators monitor these channels and respond as time permits.

---

✅ **Tip:**
This workflow is consistent across Linux, macOS, and BSD systems. Only the package-installation commands may vary (for example, use `brew install libssh` on macOS).
