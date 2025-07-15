# Check what the sed command did to the templates
cat charts/qualys-ca/templates/daemonset.yaml | head -10

# Let's revert to v1.0.2 and manually add namespace support
git checkout v1.0.2

# Manually update each template with proper namespace placement
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

# Update daemonset.yaml manually with proper indentation
cat > charts/qualys-ca/templates/daemonset.yaml << 'EOF'
apiVersion: apps/v1
kind: DaemonSet
metadata:
  name: {{ include "qualys-ca.fullname" . }}
  namespace: {{ .Values.namespace.name }}
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
      hostPID: {{ .Values.hostPID }}
      restartPolicy: Always
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
            {{- toYaml .Values.volumeMounts | nindent 12 }}
      volumes:
        {{- toYaml .Values.volumes | nindent 8 }}
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
EOF

# Update other templates manually...
# Update configmap.yaml
sed -i '' 's/metadata:/metadata:\
  namespace: {{ .Values.namespace.name }}/' charts/qualys-ca/templates/configmap.yaml

# Update serviceaccount.yaml  
sed -i '' 's/metadata:/metadata:\
  namespace: {{ .Values.namespace.name }}/' charts/qualys-ca/templates/serviceaccount.yaml

# Add namespace config to values.yaml
cat >> charts/qualys-ca/values.yaml << 'EOF'

# Namespace configuration
namespace:
  create: true
  name: "qualys"
EOF

# Bump version and commit
sed -i '' 's/version: 1.0.2/version: 1.0.4/' charts/qualys-ca/Chart.yaml

git add .
git commit -m "Add namespace support with proper YAML formatting"
git push origin main

git tag v1.0.4
git push origin v1.0.4
