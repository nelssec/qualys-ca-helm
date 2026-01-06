# Changelog

All notable changes to the Qualys Cloud Agent Helm chart will be documented in this file.

The format is based on [Keep a Changelog](https://keepachangelog.com/en/1.0.0/),
and this project adheres to [Semantic Versioning](https://semver.org/spec/v2.0.0.html).

## [3.1.0] - 2026-01-06

### Added
- **Proxy Support**: Full proxy configuration for enterprise environments
  - `proxy.qualysHttpsProxy` - Proxy for Qualys platform traffic only
  - `proxy.httpsProxy` - System-wide HTTPS proxy
  - `proxy.proxyFailOpen` - Attempt direct connection on proxy failure
  - `proxy.qualysProxyOrder` - Sequential or random proxy selection
  - `proxy.caCertBundle` - Custom CA certificate for proxy SSL/TLS
- **Logging Settings**: Extended logging configuration
  - `config.logFileDir` - Custom log directory
  - `config.logDestType` - File or syslog output
  - `config.logCompression` - Log compression on rollover
- **Performance Settings**: Agent behavior tuning
  - `config.cmdMaxTimeOut` - Command execution timeout
  - `config.processPriority` - Linux nice value
  - `config.scanDelayVM` / `config.scanDelayPC` - Scan delays
  - `config.maxRandomScanIntervalVM` / `config.maxRandomScanIntervalPC` - Random scan intervals
- **Permission Settings**: Privilege escalation options
  - `config.useSudo` - Run commands with sudo
  - `config.sudoCommand` - Custom sudo command (e.g., pbrun)
  - `config.user` / `config.group` - Daemon user/group
- **Other Settings**: Additional agent options
  - `config.useAuditDispatcher` - FIM with auditd integration
  - `config.hostIdSearchDir` - Host ID file location

### Changed
- **Image**: Updated to `nelssec/qualys-agent-bootstrapper:v2.1.0`
- **Base OS**: Ubuntu 22.04 (unpinned for automatic security updates)
- **Templates**: ConfigMap, Secret, and DaemonSet updated to pass all new environment variables

## [3.0.0] - 2024-12-31

### Changed
- **Architecture**: Switched to bootstrapper model - installs agent on host nodes instead of running in container
- **Image**: Now uses `nelssec/qualys-agent-bootstrapper:v2.0.0`
- **Installation Method**: Uses nsenter to install packages directly on host

### Added
- **Multi-Architecture**: Supports both x86_64 and ARM64 nodes
- **NetworkPolicy**: Egress restricted to HTTPS (443) and DNS (53) only
- **Pod Security Standards**: Namespace labels for privileged PSS enforcement
- **Secret Template**: Can now create secrets via Helm values or use existing secrets
- **RBAC**: ClusterRole and ClusterRoleBinding for node/pod read access
- **Priority Class**: Uses `system-node-critical` for security agent reliability
- **hostPID**: Enabled for nsenter host access

### Removed
- **CronJob Auto-Update**: No longer needed - agent updates via new image builds
- **PodDisruptionBudget**: Simplified deployment model
- **Auto-Update ServiceAccount**: Removed with CronJob
- **PodSecurityPolicy**: Deprecated in K8s 1.21+, removed dead config

### Security (CIS Benchmark Hardening)
- **Capabilities**: Drops ALL, adds only SYS_ADMIN, SYS_CHROOT, SYS_PTRACE
- **ServiceAccount**: `automountServiceAccountToken: false` on both SA and Pod
- **Secrets**: Marked as immutable to prevent tampering
- **hostNetwork**: Explicitly set to false
- **readOnlyRootFilesystem**: Explicitly documented (false required for installation)
- Credentials never logged (redacted output)
- Config files set to mode 600
- Minimal host mounts (not full filesystem)

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
