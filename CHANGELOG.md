# Changelog

All notable changes to this project will be documented in this file.

The format is based on [Keep a Changelog](https://keepachangelog.com/en/1.1.0/) and this project adheres to [Semantic Versioning](https://semver.org/spec/v2.0.0.html).

## [Unreleased]
### Added
- Container-driven integration test harness and GitHub workflow alignment with the `nokia.srlinux` collection.
- `tools/run.sh` helper that provisions a SR OS container and runs ansible-test locally.
- Contribution guidelines and a changelog to make community collaboration easier.

### Changed
- Updated sample inventories and documentation to focus on containerised lab environments.

### Fixed
- Removed stale IP addresses from example inventories to avoid accidental production access.

## [1.8.0]
### Added
- Initial alignment with the Nokia SR OS network automation content published on Ansible Galaxy.
- Example playbooks for classic CLI, MD-CLI, and NETCONF automation workflows.

[Unreleased]: https://github.com/nokia/sros-ansible/compare/v1.8.0...HEAD
[1.8.0]: https://github.com/nokia/sros-ansible/releases/tag/v1.8.0
