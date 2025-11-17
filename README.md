# Qualys Cloud Agent Helm Chart

[![Artifact Hub](https://img.shields.io/endpoint?url=https://artifacthub.io/badge/repository/qualys-ca)](https://artifacthub.io/packages/search?repo=qualys-ca)

This Helm chart deploys the Qualys Cloud Agent as a DaemonSet on Kubernetes clusters for continuous security vulnerability scanning and compliance monitoring.

## Features

- **Automatic Updates**: Built-in CronJob automatically restarts the DaemonSet to pull the latest cloud agent images
- **Health Monitoring**: Liveness and readiness probes ensure agent availability
- **High Availability**: Pod Disruption Budget maintains coverage during cluster maintenance
- **Security**: Runs in dedicated namespace with proper RBAC permissions
- **Flexible Configuration**: Comprehensive values for customization
- **Rolling Updates**: Zero-downtime updates with configurable rolling strategy

## Prerequisites

- Kubernetes 1.19+
- Helm 3.0+
- Qualys subscription with activation ID and customer ID

## Installation

### 1. Create the Qualys credentials secret

```bash
kubectl create namespace qualys

kubectl create secret generic qualys-credentials \
  --from-literal=activationId=YOUR_ACTIVATION_ID \
  --from-literal=customerId=YOUR_CUSTOMER_ID \
  -n qualys
```

### 2. Install the Helm chart

```bash
# Add the Helm repository (if published)
helm repo add qualys-ca https://nelssec.github.io/qualys-ca-helm
helm repo update

# Install the chart
helm install qualys-ca qualys-ca/qualys-ca -n qualys
```

Or install directly from source:

```bash
git clone https://github.com/nelssec/qualys-ca-helm.git
cd qualys-ca-helm
helm install qualys-ca ./charts/qualys-ca -n qualys
```

### 3. Verify the installation

```bash
kubectl get daemonset -n qualys
kubectl get pods -n qualys
kubectl get cronjob -n qualys
```

## Auto-Update Feature

The chart includes an automated update mechanism that ensures your cloud agents are always running the latest version.

### How It Works

1. **Image Pull Policy**: Set to `Always` to ensure Kubernetes pulls the latest image when pods restart
2. **Scheduled CronJob**: Runs every 6 hours (configurable) to perform rolling restarts
3. **Rolling Restart**: Triggers `kubectl rollout restart` on the DaemonSet
4. **Graceful Updates**: Respects Pod Disruption Budget and rolling update strategy

### Configuration

```yaml
autoUpdate:
  enabled: true                           # Enable/disable auto-updates
  schedule: "0 */6 * * *"                # Cron schedule (every 6 hours)
  successfulJobsHistoryLimit: 3          # Keep last 3 successful jobs
  failedJobsHistoryLimit: 3              # Keep last 3 failed jobs
```

### Monitoring Auto-Updates

```bash
# Check CronJob status
kubectl get cronjob -n qualys

# View recent auto-update jobs
kubectl get jobs -n qualys

# Check logs from the latest job
kubectl logs -n qualys job/qualys-ca-auto-update-<timestamp>

# Watch DaemonSet rollout
kubectl rollout status daemonset/qualys-ca -n qualys
```

### Custom Update Schedule

Update the schedule using standard cron syntax:

```bash
# Update every 12 hours
helm upgrade qualys-ca ./charts/qualys-ca \
  --set autoUpdate.schedule="0 */12 * * *" \
  -n qualys

# Update daily at 2 AM
helm upgrade qualys-ca ./charts/qualys-ca \
  --set autoUpdate.schedule="0 2 * * *" \
  -n qualys

# Disable auto-updates
helm upgrade qualys-ca ./charts/qualys-ca \
  --set autoUpdate.enabled=false \
  -n qualys
```

## Configuration

The following table lists the configurable parameters of the Qualys Cloud Agent chart.

### Image Configuration

| Parameter | Description | Default |
|-----------|-------------|---------|
| `image.repository` | Image repository | `nelssec/qualys-cloud-agent` |
| `image.tag` | Image tag | `latest` |
| `image.pullPolicy` | Image pull policy | `Always` |

### Namespace Configuration

| Parameter | Description | Default |
|-----------|-------------|---------|
| `namespace.create` | Create namespace | `true` |
| `namespace.name` | Namespace name | `qualys` |

### Qualys Configuration

| Parameter | Description | Default |
|-----------|-------------|---------|
| `config.serverUri` | Qualys server URI | `https://qagpublic.qg2.apps.qualys.com/CloudAgent/` |
| `config.logLevel` | Agent log level | `3` |
| `secrets.existingSecret` | Name of existing secret with credentials | `qualys-credentials` |

### Auto-Update Configuration

| Parameter | Description | Default |
|-----------|-------------|---------|
| `autoUpdate.enabled` | Enable automatic updates | `true` |
| `autoUpdate.schedule` | Cron schedule for updates | `0 */6 * * *` |
| `autoUpdate.successfulJobsHistoryLimit` | Successful jobs history | `3` |
| `autoUpdate.failedJobsHistoryLimit` | Failed jobs history | `3` |
| `autoUpdate.restartPolicy` | Job restart policy | `OnFailure` |

### Health Checks

| Parameter | Description | Default |
|-----------|-------------|---------|
| `healthChecks.enabled` | Enable health probes | `true` |
| `healthChecks.liveness.initialDelaySeconds` | Liveness initial delay | `60` |
| `healthChecks.liveness.periodSeconds` | Liveness check period | `30` |
| `healthChecks.readiness.initialDelaySeconds` | Readiness initial delay | `30` |
| `healthChecks.readiness.periodSeconds` | Readiness check period | `10` |

### Resources

| Parameter | Description | Default |
|-----------|-------------|---------|
| `resources.limits.cpu` | CPU limit | `500m` |
| `resources.limits.memory` | Memory limit | `512Mi` |
| `resources.requests.cpu` | CPU request | `250m` |
| `resources.requests.memory` | Memory request | `256Mi` |

### Update Strategy

| Parameter | Description | Default |
|-----------|-------------|---------|
| `updateStrategy.type` | Update strategy type | `RollingUpdate` |
| `updateStrategy.rollingUpdate.maxUnavailable` | Max unavailable pods | `25%` |

### Pod Disruption Budget

| Parameter | Description | Default |
|-----------|-------------|---------|
| `podDisruptionBudget.enabled` | Enable PDB | `true` |
| `podDisruptionBudget.minAvailable` | Minimum available pods | `1` |

### Other

| Parameter | Description | Default |
|-----------|-------------|---------|
| `hostPID` | Use host PID namespace | `true` |
| `hostNetwork` | Use host network | `false` |
| `tolerations` | Pod tolerations | Tolerates all taints |
| `nodeSelector` | Node selector | `{}` |
| `affinity` | Pod affinity | `{}` |

## Upgrading

### Upgrading the Chart

```bash
helm upgrade qualys-ca ./charts/qualys-ca -n qualys
```

### Upgrading with Custom Values

```bash
helm upgrade qualys-ca ./charts/qualys-ca -n qualys -f custom-values.yaml
```

## Uninstallation

```bash
helm uninstall qualys-ca -n qualys

# Optionally delete the namespace
kubectl delete namespace qualys
```

## Troubleshooting

### Check Pod Status

```bash
kubectl get pods -n qualys -o wide
kubectl describe pod <pod-name> -n qualys
```

### View Pod Logs

```bash
kubectl logs -n qualys <pod-name>
kubectl logs -n qualys <pod-name> --previous  # Previous container logs
```

### Check DaemonSet Status

```bash
kubectl get daemonset -n qualys
kubectl describe daemonset qualys-ca -n qualys
```

### Verify Credentials Secret

```bash
kubectl get secret qualys-credentials -n qualys
kubectl describe secret qualys-credentials -n qualys
```

### Manual Image Update

If you need to manually trigger an update:

```bash
kubectl rollout restart daemonset/qualys-ca -n qualys
kubectl rollout status daemonset/qualys-ca -n qualys
```

### Check Auto-Update CronJob

```bash
# View CronJob configuration
kubectl get cronjob qualys-ca-auto-update -n qualys -o yaml

# Manually trigger the CronJob
kubectl create job --from=cronjob/qualys-ca-auto-update manual-update -n qualys

# View job logs
kubectl logs -n qualys job/manual-update
```

## Security Considerations

- The agent requires `privileged: true` to perform security scans
- The agent uses `hostPID: true` to access host processes
- Credentials are stored in Kubernetes secrets
- RBAC is configured with minimal required permissions
- The auto-update service account only has permissions to restart the DaemonSet

## Support

For issues and questions:
- GitHub Issues: https://github.com/nelssec/qualys-ca-helm/issues
- Qualys Support: https://www.qualys.com/support/

## License

Apache-2.0

## Maintainers

- Andrew Nelson (anelson@qualys.com)
