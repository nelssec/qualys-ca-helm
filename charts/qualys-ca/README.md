# Qualys Cloud Agent Helm Chart

Deploy the Qualys Cloud Agent on Kubernetes worker nodes using a bootstrapper model that installs the agent directly on the host.

## Overview

This chart deploys a DaemonSet that runs a bootstrapper container on each Linux node. The bootstrapper detects the host OS and architecture, then installs the appropriate Qualys Cloud Agent package directly on the node.

### Key Features

- **Host Installation** - Agent runs on the node, not in a container
- **Multi-Architecture** - Supports x86_64 and ARM64 nodes
- **Universal OS Support** - Ubuntu, Debian, RHEL, CentOS, Amazon Linux, CoreOS
- **Security Hardened** - NetworkPolicy, minimal RBAC, immutable secrets
- **Idempotent** - Safe to redeploy, restart, or scale

## Prerequisites

- Kubernetes 1.19+
- Helm 3.0+
- Qualys subscription with Activation ID and Customer ID

## Installation

```bash
helm repo add qualys https://nelssec.github.io/qualys-ca-helm
helm repo update

helm install qualys-agent qualys/qualys-ca \
  --namespace qualys \
  --create-namespace \
  --set credentials.activationId="YOUR_ACTIVATION_ID" \
  --set credentials.customerId="YOUR_CUSTOMER_ID" \
  --set config.serverUri="https://qagpublic.qg1.apps.qualys.com/CloudAgent/"
```

### Using an Existing Secret

```bash
kubectl create namespace qualys
kubectl create secret generic qualys-credentials \
  --namespace qualys \
  --from-literal=ACTIVATION_ID="YOUR_ACTIVATION_ID" \
  --from-literal=CUSTOMER_ID="YOUR_CUSTOMER_ID"

helm install qualys-agent qualys/qualys-ca \
  --namespace qualys \
  --set credentials.existingSecret="qualys-credentials" \
  --set config.serverUri="https://qagpublic.qg1.apps.qualys.com/CloudAgent/"
```

## Configuration

### Required Parameters

| Parameter | Description |
|-----------|-------------|
| `credentials.activationId` | Qualys Activation ID (or use `existingSecret`) |
| `credentials.customerId` | Qualys Customer ID (or use `existingSecret`) |
| `config.serverUri` | Qualys platform endpoint URL |

### Optional Parameters

| Parameter | Description | Default |
|-----------|-------------|---------|
| `image.repository` | Container image | `nelssec/qualys-agent-bootstrapper` |
| `image.tag` | Image tag | `v2.0.0` |
| `image.pullPolicy` | Pull policy | `IfNotPresent` |
| `credentials.existingSecret` | Name of existing secret with credentials | `""` |
| `config.logLevel` | Log verbosity (0-5) | `"3"` |
| `namespace.create` | Create the namespace | `true` |
| `namespace.name` | Namespace name | `qualys` |
| `networkPolicy.enabled` | Enable NetworkPolicy | `true` |
| `priorityClassName` | Pod priority class | `system-node-critical` |
| `resources.requests.cpu` | CPU request | `100m` |
| `resources.requests.memory` | Memory request | `128Mi` |
| `resources.limits.cpu` | CPU limit | `500m` |
| `resources.limits.memory` | Memory limit | `512Mi` |
| `nodeSelector` | Node selector | `kubernetes.io/os: linux` |
| `tolerations` | Pod tolerations | Tolerates all taints |
| `affinity` | Pod affinity rules | `{}` |
| `serviceAccount.create` | Create ServiceAccount | `true` |
| `serviceAccount.name` | ServiceAccount name | `""` |
| `serviceAccount.annotations` | ServiceAccount annotations | `{}` |
| `updateStrategy.type` | DaemonSet update strategy | `RollingUpdate` |
| `updateStrategy.rollingUpdate.maxUnavailable` | Max unavailable during update | `25%` |

## Qualys Platform Endpoints

Select the Server URI matching your Qualys platform:

| Region | Server URI |
|--------|------------|
| US Platform 1 | `https://qagpublic.qg1.apps.qualys.com/CloudAgent/` |
| US Platform 2 | `https://qagpublic.qg2.apps.qualys.com/CloudAgent/` |
| US Platform 3 | `https://qagpublic.qg3.apps.qualys.com/CloudAgent/` |
| EU Platform 1 | `https://qagpublic.qg1.apps.qualys.eu/CloudAgent/` |
| EU Platform 2 | `https://qagpublic.qg2.apps.qualys.eu/CloudAgent/` |
| India | `https://qagpublic.qg1.apps.qualys.in/CloudAgent/` |
| Canada | `https://qagpublic.qg1.apps.qualys.ca/CloudAgent/` |
| Australia | `https://qagpublic.qg1.apps.qualys.com.au/CloudAgent/` |

Find your platform at: https://www.qualys.com/platform-identification/

## How It Works

1. DaemonSet deploys a bootstrapper pod on each Linux node
2. Pod detects host OS (Ubuntu, RHEL, etc.) and architecture (x64, ARM64)
3. Selects appropriate package (DEB or RPM)
4. Installs agent on the host using nsenter
5. Configures agent with credentials from Kubernetes secret
6. Starts the agent service and verifies activation
7. Pod sleeps while agent runs on the host

## Security

### Pod Security

- **Privileged**: Required for host installation via nsenter
- **hostPID**: Required for nsenter access to host
- **Capabilities**: Drops ALL, adds only SYS_ADMIN, SYS_CHROOT, SYS_PTRACE
- **ServiceAccount**: Token automount disabled

### Network Security

- **NetworkPolicy**: Restricts egress to HTTPS (443) and DNS (53) only
- **hostNetwork**: Disabled

### Secret Security

- **Immutable Secrets**: Prevents tampering after creation
- **Credentials Protected**: Never logged, config files mode 600

## Verification

```bash
# Check DaemonSet status
kubectl get daemonset -n qualys

# Check pod status
kubectl get pods -n qualys -o wide

# View bootstrapper logs
kubectl logs -n qualys -l app.kubernetes.io/name=qualys-ca

# Check agent status on a node
kubectl exec -n qualys <pod-name> -- \
  nsenter --target 1 --mount --uts --ipc --net --pid -- \
  systemctl status qualys-cloud-agent
```

## Upgrade

```bash
helm repo update
helm upgrade qualys-agent qualys/qualys-ca \
  --namespace qualys \
  --reuse-values
```

## Uninstall

```bash
helm uninstall qualys-agent --namespace qualys
kubectl delete namespace qualys
```

**Note**: Uninstalling the chart does not remove the Qualys agent from nodes. The agent persists on the host.

## Troubleshooting

| Issue | Solution |
|-------|----------|
| Pod pending | Check node selector matches your nodes |
| CrashLoopBackOff | Verify credentials secret exists and has correct keys |
| Agent not activating | Verify Server URI matches your Qualys platform |
| Permission denied | Ensure privileged security context is allowed |

## Support

- **Issues**: https://github.com/nelssec/qualys-ca-helm/issues
- **Qualys Support**: https://www.qualys.com/support/

## License

Apache-2.0
