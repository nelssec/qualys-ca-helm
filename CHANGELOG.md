# Changelog

All notable changes to the Qualys Cloud Agent Helm chart will be documented in this file.

The format is based on [Keep a Changelog](https://keepachangelog.com/en/1.0.0/),
and this project adheres to [Semantic Versioning](https://semver.org/spec/v2.0.0.html).

## [2.0.0] - 2025-11-17

### Added
- **Auto-Update Feature**: CronJob that automatically performs rolling restarts of the DaemonSet every 6 hours (configurable)
  - Configurable schedule via `autoUpdate.schedule` parameter
  - Ensures cloud agents automatically pull and use the latest available images
  - RBAC resources (ServiceAccount, Role, RoleBinding) for secure auto-update operations
- **Health Probes**: Liveness and readiness probes for better pod health monitoring
  - Configurable probe settings via `healthChecks` parameters
  - Helps Kubernetes automatically restart unhealthy pods
- **Pod Disruption Budget**: Ensures minimum availability during cluster maintenance and updates
  - Configurable via `podDisruptionBudget` parameters
  - Maintains at least 1 pod available during voluntary disruptions
- **Comprehensive Documentation**: Enhanced README with detailed installation, configuration, and troubleshooting guides
  - Auto-update feature documentation with examples
  - Configuration reference table
  - Troubleshooting section
  - Security considerations

### Changed
- **Image Pull Policy**: Changed from `IfNotPresent` to `Always` to support auto-updates
  - Ensures latest image is pulled when pods restart
- **Tolerations**: Now tolerates all taints by default for complete cluster coverage
  - `NoSchedule` and `NoExecute` effects are tolerated
  - Ensures security agents run on all nodes regardless of taints
- **Chart Version**: Bumped to 2.0.0 to reflect major feature additions
- **Chart Description**: Updated to highlight auto-update support

### Improved
- Resource configuration with better defaults and documentation
- Values file organization with clear comments and sections
- Template structure with new components
- Overall security posture with minimal RBAC permissions

### Technical Details
- Added templates: `cronjob.yaml`, `role.yaml`, `rolebinding.yaml`, `serviceaccount-autoupdate.yaml`, `poddisruptionbudget.yaml`
- Auto-update mechanism uses `kubectl rollout restart` for graceful updates
- CronJob uses lightweight `bitnami/kubectl` image for minimal overhead
- Job history limited to 3 successful and 3 failed runs to prevent resource buildup

## [1.0.0] - 2024-XX-XX

### Added
- Initial release of Qualys Cloud Agent Helm chart
- DaemonSet deployment for node-level agent installation
- ConfigMap for Qualys server URI and log level configuration
- ServiceAccount with basic permissions
- Namespace support with configurable name
- Secret-based credential management
- Resource limits and requests configuration
- Rolling update strategy
- Host PID access for security scanning
- GitHub Actions workflow for chart releases

### Features
- Deploy Qualys Cloud Agent across all worker nodes
- Configurable resource limits
- Support for node selectors and affinity rules
- Custom tolerations support
- Configurable update strategy
