![NOKIA](media/logo.png)

---

# Ansible Collection - nokia.sros

The [Ansible](https://www.ansible.com) [`nokia.sros` collection](https://galaxy.ansible.com/nokia/sros) provides CLI and [NETCONF](https://www.rfc-editor.org/rfc/rfc6241.html) plugins for Nokia SR OS devices. These plugins act as device drivers to enable the usage of Ansible networking modules including `cli_config` and `cli_command` provided by the `ansible.netcommon` collection. In addition, the collection populates device information and capabilities.

Distribution is via [ansible-galaxy](https://galaxy.ansible.com/).

Please remind, that this project is a Nokia initiated Open-Source initiative under [BSD 3-clause license](./license) to support the adoption of programmable network automation using standard IT tools. We welcome users to become part of our network DevOps community, by helping to provide tutorials, reallife playbook examples, raising issues or feature requests or help with code contributions.

> **NOTES** s
>
> For SRLinux devices including Nokia's data center switches, use our [`nokia.srlinux` collection](https://galaxy.ansible.com/nokia/srlinux).
>
> If you prefer using [OpenConfig gNMI](http://www.openconfig.net/projects/gnmi/gnmi) for building your Ansible network automation pipeline, please use the `nokia.grpc` [collection](https://galaxy.ansible.com/nokia/grpc).

---

## Requirements
* Python 3.9 or newer
* Python libraries:
    * [ansible-pylibssh](https://pypi.org/project/ansible-pylibssh)
    * [jxmlease](https://pypi.org/project/jxmlease)
    * [ncclient](https://pypi.org/project/ncclient)
* Ansible Core 2.13 or newer

## Supported Nokia SR OS versions
Tested with SR OS 25.7

## Installation
Following recipe may be used to build a ready-to-use virtual environment for SR OS Ansible automation.

```bash
python -m venv .venv
source .venv/bin/activate

python -m pip install --upgrade pip
python -m pip install ansible-core ansible-pylibssh jxmlease ncclient

ansible-galaxy collection install ansible.netcommon --force-with-deps
ansible-galaxy collection install nokia.sros --force-with-deps
```

## Usage

To use this collection make sure to set `ansible_network_os=nokia.sros.{mode}` in your host inventory.

Detailed introductionary tutorials for using Ansible with SR OS are available on our [Developer Portal](https://network.developer.nokia.com/sr/learn/sr-os-ansible).

## Playbooks

This GitHub repository contains a set of playbooks, that illustrate the usage of this Ansible collection. The playbooks are to be used for regression testing.

**Classic CLI**

* [sros_classic_cli_command_demo.yml](tests/playbooks/sros_classic_cli_command_demo.yml)
* [sros_classic_cli_config_demo.yml](tests/playbooks/sros_classic_cli_config_demo.yml)
* [sros_classic_cli_backup_restore_demo.yml](tests/playbooks/sros_classic_cli_backup_restore_demo.yml)

**MD-CLI**

* [sros_mdcli_command_demo.yml](tests/playbooks/sros_mdcli_command_demo.yml)
* [sros_mdcli_config_demo.yml](tests/playbooks/sros_mdcli_config_demo.yml)
* [sros_mdcli_backup_restore_demo.yml](tests/playbooks/sros_mdcli_backup_restore_demo.yml)

**NETCONF**

* [sros_nc_state_demo.yml](tests/playbooks/sros_nc_state_demo.yml)

**Device Info**

* [sros_cli_device_info.yml](tests/playbooks/sros_cli_device_info.yml)
* [sros_nc_device_info.yml](tests/playbooks/sros_nc_device_info.yml)

## Modules

The Ansible module `nokia.sros.device_info` returns information about the networking device connected. This module is designed to work with CLI and NETCONF connections.

Example output:

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

## Implementation Details

### CLASSIC MODE

In the case of classic CLI we are relying on the SR OS built-in rollback feature. Therefore it is required that the rollback location is properly configured. For example:

```
     A:Antwerp# file md cf3:/rollbacks
     *A:Antwerp# configure system rollback rollback-location cf3:/rollbacks/config
     INFO: CLI No checkpoints currently exist at the rollback location.
     *A:Antwerp# admin rollback save
     Saving rollback configuration to cf3:/rollbacks/config.rb... OK
     *A:Antwerp#
```

This Ansible collection contains a playbook, on how to enable rollbacks: [sros_classic_cli_commission.yml](tests/playbooks/sros_classic_cli_commission.yml).

Note: Use `nokia.sros.light` for SR OS nodes that don't support rollback or if the use of rollbacks is not desired.


Snapshot/rollback is used the following way:

* A new temporary rollback checkpoint is created at the beginning of every `cli_config` operation.
* If a configuration request runs into an error, the configuration is restored by rolling back to the checkpoint that was created before. This translates to a `rollback-on-error` behavior.
* If the configuration request is successful, the new running configuration is compared against the previous checkpoint. This is needed to support the `change` indicator, but also to populate differences, if the `--diff` option was provided.
* If operator requests to do a dry-run by providing the `--check` option, the change is executed against the running config and reverted to the checkpoint straight away. Following that approach, syntax and semantic checks will be executed - but also we get `change` indication including the list of differences, if `--diff` option was provided.
* At the end of the cli_config operation the checkpoint created will be deleted to keep a clean rollback history.

> **WARNING**
>
> * Be aware, that dry-run is implemented as temporary activation of the configuration with immediate rollback. Users need to consider potential service impact because of this.
> * Rollback-on-error might have side-effects based on the way SR OS has implemented the checkpoint/rollback feature. In its operation for impacted modules (such as BGP within VPRN) it reverts to default configuration (e.g. shutdown) prior to the execution of commands to revert the checkpoint's configuration. Please check the `Basic System Config Guide` for more information.

**RESTRICTIONS:**

* Some platforms might not support checkpoint/rollback
* Changes are always written directly to running
* Operation `replace` is currently not supported
* The oldest rollback checkpoint is removed after plugin operation.

### LIGHT MODE

The use of `nokia.sros.classic` depends on the nodal rollback feature and comes with a set of side-effects as discussed before. In cases where the rollback feature is not supported, for example when using older SR OS releases, or if the use of the rollback is not desired `nokia.sros.light` should be used.

The plugin relies on the prompt change indicator to determine, if there was a change made by cli_config. If a change causes asterisk to appear before prompt, then the task is considered as changed.

**RESTRICTIONS:**

* If there were unsaved changes on a device before running cli_conifg task it will be assumed as changed.
* This plugin does support neither `--diff` mode nor `--check` mode.
