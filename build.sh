# Update values.yaml to include namespace
cat > charts/qualys-ca/values.yaml << 'EOF'
replicaCount: 1

# Namespace configuration
namespace:
  create: true
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

# Create namespace template
cat > charts/qualys-ca/templates/namespace.yaml << 'EOF'
{{- if .Values.namespace.create }}
apiVersion: v1
kind: Namespace
metadata:
  name: {{ .Values.namespace.name }}
  labels:
    {{- include "qualys-ca.labels" . | nindent 4 }}
{{- end }}
EOF

# Update all templates to use the namespace
sed -i '' '/metadata:/a\
  namespace: {{ .Values.namespace.name }}
' charts/qualys-ca/templates/*.yaml

# Update Chart.yaml version
sed -i '' 's/version: 1.0.1/version: 1.0.3/' charts/qualys-ca/Chart.yaml

# Commit and release
git add .
git commit -m "Add namespace support - deploy to qualys namespace"
git push origin main

# Create new release
git tag v1.0.3
git push origin v1.0.3
