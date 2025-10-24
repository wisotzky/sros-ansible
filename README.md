![NOKIA](media/logo.png)
# Ansible Collection - nokia.sros

***

This [collection](https://galaxy.ansible.com/nokia/sros) provides automation for Nokia SR OS devices using Ansible by Red Hat.
It ships the same device plugins that power the official [nokia.srlinux collection](https://github.com/nokia/srlinux-ansible-collection)
and follows the same testing and release processes.

## Project resources

* [Changelog](CHANGELOG.md)
* [Contribution guide](CONTRIBUTING.md)
* [GitHub Actions workflows](.github/workflows)

## Installation
Distribution is via [ansible-galaxy](https://galaxy.ansible.com/).

Make sure you have the Ansible [netcommon](https://galaxy.ansible.com/ansible/netcommon) collection installed:
```bash
ansible-galaxy collection install ansible.netcommon
```

Install the Python dependencies used by this collection to enable NETCONF
support and SSH optimisations:
```bash
pip install -r requirements.txt
```

To install this collection, please use the following command:
```bash
ansible-galaxy collection install nokia.sros
```

If you have already installed a previous version, you can upgrade to the latest version of this collection by adding the `--force-with-deps` option:
```bash
ansible-galaxy collection install nokia.sros --force-with-deps
```

## Usage
To use this collection make sure to set `ansible_network_os=nokia.sros.{mode}` in your host inventory.

## Requirements
* ansible-core 2.13 or newer
* Python 3.8 or newer on the Ansible control node
* Python libraries: [ansible-pylibssh](https://pypi.org/project/ansible-pylibssh/), [jxmlease](https://pypi.org/project/jxmlease/), [ncclient](https://pypi.org/project/ncclient/)
* Docker Engine 20.10 or newer (for the containerised test harness)

## Supported Nokia SR OS versions
Tested with SR OS 19.5, 19.7, 19.10 and 20.5

## Playbooks
### Classic CLI
* [sros_classic_cli_command_demo.yml](playbooks/sros_classic_cli_command_demo.yml)
* [sros_classic_cli_config_demo.yml](playbooks/sros_classic_cli_config_demo.yml)
* [sros_classic_cli_backup_restore_demo.yml](playbooks/sros_classic_cli_backup_restore_demo.yml)
### MD-CLI
* [sros_mdcli_command_demo.yml](playbooks/sros_mdcli_command_demo.yml)
* [sros_mdcli_config_demo.yml](playbooks/sros_mdcli_config_demo.yml)
* [sros_mdcli_backup_restore_demo.yml](playbooks/sros_mdcli_backup_restore_demo.yml)
### NETCONF
* [sros_nc_state_demo.yml](playbooks/sros_nc_state_demo.yml)
### Device information
* [sros_cli_device_info.yml](playbooks/sros_cli_device_info.yml)
* [sros_nc_device_info.yml](playbooks/sros_nc_device_info.yml)

## Modules
The Ansible module `nokia.sros.device_info` returns information about the networking device connected. This module is designed to work with CLI and NETCONF connections.
Example result:
```yaml
  output:
    network_os: "nokia.sros.classic"
    network_os_hostname: "Antwerp"
    network_os_model: "7750 SR-12"
    network_os_platform: "Nokia 7x50"
    network_os_version: "B-19.5.R2"
    sros_config_mode: "classic"
```

## Roles
None

## Plugins
|     Network OS      | terminal | cliconf | netconf |
|---------------------|:--------:|:-------:|:-------:|
| nokia.sros.md       |     Y    |    Y    |    Y    |
| nokia.sros.classic  |     Y    |    Y    |    -    |
| nokia.sros.light    |     Y    |    Y    |    -    |


### CLASSIC MODE
In the case of classic CLI we are relying on the built-in rollback feature.
Therefore it is required that the rollback location is properly configured.
For example:
```
     A:Antwerp# file md cf3:/rollbacks
     *A:Antwerp# configure system rollback rollback-location cf3:/rollbacks/config
     INFO: CLI No checkpoints currently exist at the rollback location.
     *A:Antwerp# admin rollback save
     Saving rollback configuration to cf3:/rollbacks/config.rb... OK
     *A:Antwerp#
```

This Ansible collection also contains a playbook, on how to enable rollbacks:
[sros_classic_cli_commission.yml](playbooks/sros_classic_cli_commission.yml).

Note: Use `nokia.sros.light` for SR OS nodes that don't support rollback or if the use of the
rollback is not desired.


Snapshot/rollback is used the following way:
* A new temporary rollback checkpoint is created at the beginning of every
  cli_config operation.
* If a configuration request runs into an error, the configuration is restored
  by rolling back to the checkpoint that was created before. This actually
  translates to a rollback-on-error behavior.
* If the configuration request is successful, the new running configuration is
  compared against the previous checkpoint using the underlying nodal feature.
  This is needed to provide the `change` indicator, but also to provide the
  actual differences, if the `--diff` option is used.
* If operator requests to do a dry-run by providing the `--check` option,
  the change is executed against the running config and reverted to the
  checkpoint straight away. Following that approach, syntax and
  semantic checks will be executed - but also we get `change` indication
  including the list of differences, if `--diff` option was provided.
* At the end of the cli_config operation the checkpoint created will be
  deleted to keep a clean rollback history.

WARNING:
* Be aware, that dry-run is implemented as temporary activation of the
  new configuration with immediate rollback. Users need to consider potential
  service impact because of this.
* Rollback-on-error might have side-effects based on the way SR OS has implemented
  the checkpoint/rollback feature. In its operation for impacted modules (such
  as BGP within VPRN) it reverts to default configuration (e.g. shutdown) prior
  to the execution of commands to revert the checkpoint's configuration. Please
  check the `Basic System Config Guide` for more information.

RESTRICTIONS:
* Some platforms might not support checkpoint/rollback
* Changes are always written directly to running
* Operation `replace` is currently not supported
* The oldest rollback checkpoint is removed after plugin operation.


### LIGHT MODE
The use of `nokia.sros.classic` depends on the nodal rollback feature and comes with
a set of side-effects as discussed before. In cases where the rollback feature is not
supported, for example when using older SR OS releases, or if the use of the rollback
is not desired `nokia.sros.light` should be used.

The plugin relies
on the prompt change indicator to determine, if there was a change made by cli_config.
If a change causes asterisk to appear before prompt, then the task is considered as changed.

RESTRICTIONS:
* If there were unsaved changes on a device before running cli_conifg task it will be assumed as changed.
* This plugin does support neither `--diff` mode nor `--check` mode.

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
