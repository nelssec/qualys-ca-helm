cd /Users/anelson/Downloads/qualys_bootstrap/qualys-project/qualys-helm/qualys-ca-helm

# Update the namespace template to check if namespace exists first
cat > charts/qualys-ca/templates/namespace.yaml << 'EOF'
{{- if .Values.namespace.create }}
{{- $existingNamespace := lookup "v1" "Namespace" "" .Values.namespace.name }}
{{- if not $existingNamespace }}
apiVersion: v1
kind: Namespace
metadata:
  name: {{ .Values.namespace.name }}
  labels:
    {{- include "qualys-ca.labels" . | nindent 4 }}
{{- end }}
{{- end }}
EOF

# Also, let's make namespace creation optional by default since many users may have existing namespaces
cat > charts/qualys-ca/values.yaml << 'EOF'
replicaCount: 1

# Namespace configuration
namespace:
  create: false  # Don't create by default, use existing or let user create
  name: "qualys"

image:
  repository: nelssec/qualys-cloud-agent
  tag: "latest"
  pullPolicy: IfNotPresent

config:
  serverUri: "https://qagpublic.qg2.apps.qualys.com/CloudAgent/"
  logLevel: "3"

secrets:
  existingSecret: "qualys-credentials"

nameOverride: ""
fullnameOverride: ""

serviceAccount:
  create: true
  annotations: {}
  name: ""

podAnnotations: {}

podSecurityContext: {}

securityContext:
  privileged: true

resources:
  limits:
    cpu: 500m
    memory: 512Mi
  requests:
    cpu: 250m
    memory: 256Mi

nodeSelector: {}
tolerations: []
affinity: {}

updateStrategy:
  type: RollingUpdate
  rollingUpdate:
    maxUnavailable: 25%

hostNetwork: false
hostPID: true
privileged: false

# Volume mounts for Qualys agent
volumeMounts:
  - name: tmp
    mountPath: /tmp

volumes:
  - name: tmp
    emptyDir: {}
EOF

# Update Chart version
sed -i '' 's/version: 1.0.4/version: 1.0.5/' charts/qualys-ca/Chart.yaml

# Commit and release
git add .
git commit -m "Fix namespace handling - check if exists before creating"
git push origin main

git tag v1.0.5
git push origin v1.0.5
