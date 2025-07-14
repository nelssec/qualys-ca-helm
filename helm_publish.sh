mkdir -p qualys-ca-helm
cd qualys-ca-helm

mkdir -p .github/workflows
mkdir -p .artifacthub
mkdir -p charts/qualys-ca/templates
mkdir -p charts/qualys-ca/charts

cat > .github/workflows/release.yml << 'EOF'
name: Release Charts

on:
  push:
    tags:
      - 'v*'

jobs:
  release:
    runs-on: ubuntu-latest
    steps:
      - name: Checkout
        uses: actions/checkout@v4
        with:
          fetch-depth: 0

      - name: Configure Git
        run: |
          git config user.name "$GITHUB_ACTOR"
          git config user.email "$GITHUB_ACTOR@users.noreply.github.com"

      - name: Install Helm
        uses: azure/setup-helm@v3

      - name: Run chart-releaser
        uses: helm/chart-releaser-action@v1.6.0
        env:
          CR_TOKEN: "${{ secrets.GITHUB_TOKEN }}"
EOF

cat > .github/workflows/lint-test.yml << 'EOF'
name: Lint and Test Charts

on:
  pull_request:
  push:
    branches:
      - main

jobs:
  lint-test:
    runs-on: ubuntu-latest
    steps:
      - name: Checkout
        uses: actions/checkout@v4
        with:
          fetch-depth: 0

      - name: Set up Helm
        uses: azure/setup-helm@v3

      - name: Set up Python
        uses: actions/setup-python@v4
        with:
          python-version: '3.x'

      - name: Set up chart-testing
        uses: helm/chart-testing-action@v2.6.1

      - name: Run chart-testing (list)
        run: ct list --target-branch ${{ github.event.repository.default_branch }}

      - name: Run chart-testing (lint)
        run: ct lint --target-branch ${{ github.event.repository.default_branch }}
EOF

cat > .artifacthub/config.yml << 'EOF'
repositoryID: qualys-ca
owners:
  - name: Andrew Nelson
    email: anelson@qualys.com
EOF

cat > charts/qualys-ca/Chart.yaml << 'EOF'
apiVersion: v2
name: qualys-ca
description: Qualys Cloud Agent for Kubernetes
type: application
version: 1.0.0
appVersion: "6.1.0-25"
keywords:
  - qualys
  - security
  - vulnerability
  - scanning
home: https://github.com/nelssec/qualys-ca-helm
sources:
  - https://github.com/nelssec/qualys-ca-helm
maintainers:
  - name: Andrew Nelson
    email: anelson@qualys.com
annotations:
  category: Security
  licenses: Apache-2.0
EOF

cat > charts/qualys-ca/values.yaml << 'EOF'
replicaCount: 1

image:
  repository: qualys/qualys-cloud-agent
  tag: "1.0.0"
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

podSecurityContext:
  runAsNonRoot: true
  runAsUser: 1000
  fsGroup: 1000

securityContext:
  allowPrivilegeEscalation: false
  capabilities:
    drop:
    - ALL
  readOnlyRootFilesystem: true
  runAsNonRoot: true
  runAsUser: 1000

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
hostPID: false
privileged: false
EOF

cat > charts/qualys-ca/templates/configmap.yaml << 'EOF'
apiVersion: v1
kind: ConfigMap
metadata:
  name: {{ include "qualys-ca.fullname" . }}-config
  labels:
    {{- include "qualys-ca.labels" . | nindent 4 }}
data:
  QUALYS_SERVER_URI: {{ .Values.config.serverUri | quote }}
  LOG_LEVEL: {{ .Values.config.logLevel | quote }}
EOF

cat > charts/qualys-ca/templates/daemonset.yaml << 'EOF'
apiVersion: apps/v1
kind: DaemonSet
metadata:
  name: {{ include "qualys-ca.fullname" . }}
  labels:
    {{- include "qualys-ca.labels" . | nindent 4 }}
spec:
  selector:
    matchLabels:
      {{- include "qualys-ca.selectorLabels" . | nindent 6 }}
  updateStrategy:
    {{- toYaml .Values.updateStrategy | nindent 4 }}
  template:
    metadata:
      {{- with .Values.podAnnotations }}
      annotations:
        {{- toYaml . | nindent 8 }}
      {{- end }}
      labels:
        {{- include "qualys-ca.selectorLabels" . | nindent 8 }}
    spec:
      serviceAccountName: {{ include "qualys-ca.serviceAccountName" . }}
      securityContext:
        {{- toYaml .Values.podSecurityContext | nindent 8 }}
      containers:
        - name: {{ .Chart.Name }}
          securityContext:
            {{- toYaml .Values.securityContext | nindent 12 }}
          image: "{{ .Values.image.repository }}:{{ .Values.image.tag | default .Chart.AppVersion }}"
          imagePullPolicy: {{ .Values.image.pullPolicy }}
          env:
            - name: ACTIVATIONID
              valueFrom:
                secretKeyRef:
                  name: {{ .Values.secrets.existingSecret }}
                  key: activationId
            - name: CUSTOMERID
              valueFrom:
                secretKeyRef:
                  name: {{ .Values.secrets.existingSecret }}
                  key: customerId
          envFrom:
            - configMapRef:
                name: {{ include "qualys-ca.fullname" . }}-config
          resources:
            {{- toYaml .Values.resources | nindent 12 }}
          volumeMounts:
            - name: tmp
              mountPath: /tmp
      volumes:
        - name: tmp
          emptyDir: {}
      {{- with .Values.nodeSelector }}
      nodeSelector:
        {{- toYaml . | nindent 8 }}
      {{- end }}
      {{- with .Values.affinity }}
      affinity:
        {{- toYaml . | nindent 8 }}
      {{- end }}
      {{- with .Values.tolerations }}
      tolerations:
        {{- toYaml . | nindent 8 }}
      {{- end }}
      hostNetwork: {{ .Values.hostNetwork }}
      hostPID: {{ .Values.hostPID }}
EOF

cat > charts/qualys-ca/templates/_helpers.tpl << 'EOF'
{{- define "qualys-ca.name" -}}
{{- default .Chart.Name .Values.nameOverride | trunc 63 | trimSuffix "-" }}
{{- end }}

{{- define "qualys-ca.fullname" -}}
{{- if .Values.fullnameOverride }}
{{- .Values.fullnameOverride | trunc 63 | trimSuffix "-" }}
{{- else }}
{{- $name := default .Chart.Name .Values.nameOverride }}
{{- if contains $name .Release.Name }}
{{- .Release.Name | trunc 63 | trimSuffix "-" }}
{{- else }}
{{- printf "%s-%s" .Release.Name $name | trunc 63 | trimSuffix "-" }}
{{- end }}
{{- end }}
{{- end }}

{{- define "qualys-ca.chart" -}}
{{- printf "%s-%s" .Chart.Name .Chart.Version | replace "+" "_" | trunc 63 | trimSuffix "-" }}
{{- end }}

{{- define "qualys-ca.labels" -}}
helm.sh/chart: {{ include "qualys-ca.chart" . }}
{{ include "qualys-ca.selectorLabels" . }}
{{- if .Chart.AppVersion }}
app.kubernetes.io/version: {{ .Chart.AppVersion | quote }}
{{- end }}
app.kubernetes.io/managed-by: {{ .Release.Service }}
{{- end }}

{{- define "qualys-ca.selectorLabels" -}}
app.kubernetes.io/name: {{ include "qualys-ca.name" . }}
app.kubernetes.io/instance: {{ .Release.Name }}
{{- end }}

{{- define "qualys-ca.serviceAccountName" -}}
{{- if .Values.serviceAccount.create }}
{{- default (include "qualys-ca.fullname" .) .Values.serviceAccount.name }}
{{- else }}
{{- default "default" .Values.serviceAccount.name }}
{{- end }}
{{- end }}
EOF

cat > charts/qualys-ca/templates/serviceaccount.yaml << 'EOF'
{{- if .Values.serviceAccount.create -}}
apiVersion: v1
kind: ServiceAccount
metadata:
  name: {{ include "qualys-ca.serviceAccountName" . }}
  labels:
    {{- include "qualys-ca.labels" . | nindent 4 }}
  {{- with .Values.serviceAccount.annotations }}
  annotations:
    {{- toYaml . | nindent 4 }}
  {{- end }}
{{- end }}
EOF

cat > charts/qualys-ca/README.md << 'EOF'
# Qualys-CA

Qualys Cloud Agent Helm chart for Kubernetes.

## Installation

```bash
helm repo add nelssec https://nelssec.github.io/qualys-ca-helm
helm repo update
