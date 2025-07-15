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

# Commit and release
git add .
git commit -m "Update security context to match working Qualys requirements"
git push origin main

# Create new release
git tag v1.0.2
git push origin v1.0.2
