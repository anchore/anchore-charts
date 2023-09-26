{{/*
Common annotations
When calling this template, .component can be included in the context for component specific annotations
{{- include "enterprise.common.annotations" (merge (dict "component" $component) .) }}
*/}}
{{- define "enterprise.common.annotations" -}}
{{- $component := .component -}}
{{- if and (not .nil) (not .Values.annotations) (not (index .Values (print $component)).annotations) }}
  {{- print "{}" }}
{{- else }}
  {{- with .Values.annotations }}
{{ toYaml . }}
  {{- end }}
  {{- if $component }}
    {{- with (index .Values (print $component)).annotations }}
{{ toYaml . }}
    {{- end }}
  {{- end }}
{{- end }}
{{- end -}}


{{/*
Setup a container for the cloudsql proxy to run in all pods when .Values.cloudsql.enabled = true
*/}}
{{- define "enterprise.common.cloudsqlContainer" -}}
- name: cloudsql-proxy
  image: {{ .Values.cloudsql.image }}
  imagePullPolicy: {{ .Values.cloudsql.imagePullPolicy }}
{{- with .Values.containerSecurityContext }}
  securityContext:
    {{ toYaml . | nindent 4 }}
{{- end }}
  command: ["/cloud_sql_proxy"]
  args:
    - "-instances={{ .Values.cloudsql.instance }}=tcp:5432"
  {{- if .Values.cloudsql.extraArgs }}
    {{- range $arg := .Values.cloudsql.extraArgs }}
    - {{ quote $arg }}
    {{- end }}
  {{- end }}
  {{- if .Values.cloudsql.useExistingServiceAcc }}
    - "-credential_file=/var/{{ .Values.cloudsql.serviceAccSecretName }}/{{ .Values.cloudsql.serviceAccJsonName }}"
  volumeMounts:
    - mountPath: "/var/{{ .Values.cloudsql.serviceAccSecretName }}"
      name: {{ .Values.cloudsql.serviceAccSecretName }}
      readOnly: true
{{- end }}
{{- end -}}


{{/*
Setup the common docker-entrypoint command for all Anchore Enterprise containers
*/}}
{{- define "enterprise.common.dockerEntrypoint" -}}
{{ print (include "enterprise.doSourceFile" .) }} /docker-entrypoint.sh anchore-enterprise-manager service start --no-auto-upgrade
{{- end -}}


{{/*
Setup the common envFrom configs
*/}}
{{- define "enterprise.common.envFrom" -}}
- configMapRef:
    name: {{ .Release.Name }}-enterprise-config-env-vars
{{- if not .Values.injectSecretsViaEnv }}
  {{- if .Values.useExistingSecrets }}
- secretRef:
    name: {{ .Values.existingSecretName }}
  {{- else }}
- secretRef:
    name: {{ template "enterprise.fullname" . }}
  {{- end }}
{{- end }}
{{- end -}}


{{/*
Common environment variables
When calling this template, .component can be included in the context for component specific env vars
{{- include "enterprise.common.environment" (merge (dict "component" $component) .) }}
*/}}
{{- define "enterprise.common.environment" -}}
{{- $component := .component -}}
{{- with .Values.extraEnv }}
{{ toYaml . }}
{{- end }}
{{- if $component }}
  {{- with (index .Values (print $component)).extraEnv }}
{{ toYaml . }}
  {{- end }}
- name: ANCHORE_ENDPOINT_HOSTNAME
  {{- if and (eq $component "reports") (eq .api "true") }}
  value: {{ template "enterprise.api.fullname" . }}
  {{- else }}
  value: {{ include (printf "enterprise.%s.fullname" $component) . }}
  {{- end }}
  {{- with (index .Values (print $component)).service }}
- name: ANCHORE_PORT
  value: {{ .port | quote }}
  {{- else }}
- name: ANCHORE_PORT
  value: "null"
  {{- end }}
{{- end }}
- name: ANCHORE_HOST_ID
  valueFrom:
    fieldRef:
      fieldPath: metadata.name
{{- end -}}


{{/*
Setup the common fix permissions init container for all pods using a scratch volume
*/}}
{{- define "enterprise.common.fixPermissionsInitContainer" -}}
- name: mode-fixer
  image: alpine
  securityContext:
    runAsUser: 0
  volumeMounts:
    - name: "anchore-scratch"
      mountPath: {{ .Values.scratchVolume.mountPath }}
  command:
    - sh
    - -c
    - (chmod 0775 {{ .Values.scratchVolume.mountPath }}; chgrp {{ .Values.securityContext.fsGroup }} {{ .Values.scratchVolume.mountPath }} )
{{- end -}}


{{/*
Common labels
When calling this template, .component can be included in the context for component specific labels
{{- include "enterprise.common.labels" (merge (dict "component" $component) .) }}
*/}}
{{- define "enterprise.common.labels" -}}
{{- $component := .component -}}
{{- if $component }}
  {{- with (index .Values (print $component)).labels }}
{{ toYaml . }}
  {{- end }}
{{- end }}
{{- with .Values.labels }}
{{ toYaml . }}
{{- end }}
app.kubernetes.io/name: {{ template "enterprise.fullname" . }}
  {{- with $component }}
app.kubernetes.io/component: {{ . | lower }}
  {{- end }}
app.kubernetes.io/instance: {{ .Release.Name }}
app.kubernetes.io/version: {{ .Chart.AppVersion }}
app.kubernetes.io/part-of: anchore
app.kubernetes.io/managed-by: {{ .Release.Service }}
helm.sh/chart: {{ printf "%s-%s" .Chart.Name .Chart.Version | replace "+" "_" | trunc 63 | trimSuffix "-" }}
{{- end -}}


{{/*
Setup the common liveness probes for all Anchore Enterprise containers
*/}}
{{- define "enterprise.common.livenessProbe" -}}
{{- $component := .component -}}
httpGet:
  path: /health
  port: {{ $component | lower }}
  scheme: {{ include "enterprise.setProtocol" . | upper }}
initialDelaySeconds: {{ .Values.probes.liveness.initialDelaySeconds }}
timeoutSeconds: {{ .Values.probes.liveness.timeoutSeconds }}
periodSeconds: {{ .Values.probes.liveness.periodSeconds }}
failureThreshold: {{ .Values.probes.liveness.failureThreshold }}
successThreshold: {{ .Values.probes.liveness.successThreshold }}
{{- end -}}


{{/*
Return anchore default selector match labels
When calling this template, .component can be included in the context for component specific env vars
{{- include "enterprise.common.matchLabels" (merge (dict "component" $component) .) }}
*/}}
{{- define "enterprise.common.matchLabels" -}}
{{- $component := .component -}}
app.kubernetes.io/name: {{ template "enterprise.fullname" . }}
app.kubernetes.io/component: {{ $component | lower }}
{{- end -}}


{{/*
Setup the common pod spec configs
*/}}
{{- define "enterprise.common.podSpec" -}}
{{- $component := .component -}}
{{- with .Values.securityContext }}
securityContext: {{- toYaml . | nindent 2 }}
{{- end }}
{{- if or .Values.serviceAccountName (index .Values (print $component)).serviceAccountName (eq $component "upgradeJob") }}
serviceAccountName: {{ include "enterprise.serviceAccountName" (merge (dict "component" $component) .) }}
{{- end }}
{{- with .Values.imagePullSecretName }}
imagePullSecrets:
  - name: {{ . }}
{{- end }}
{{- with (index .Values (print $component)).nodeSelector }}
nodeSelector: {{- toYaml . | nindent 2 }}
{{- end }}
{{- with (index .Values (print $component)).affinity }}
affinity: {{- toYaml . | nindent 2 }}
{{- end }}
{{- with (index .Values (print $component)).tolerations }}
tolerations: {{- toYaml . | nindent 2 }}
{{- end }}
{{- end -}}


{{/*
Setup a container for the Anchore Enterprise RBAC Auth for pods that need to authenticate with the API
*/}}
{{- define "enterprise.common.rbacAuthContainer" -}}
- name: rbac-auth
  image: {{ .Values.image }}
  imagePullPolicy: {{ .Values.imagePullPolicy }}
{{- with .Values.containerSecurityContext }}
  securityContext:
    {{ toYaml . | nindent 4 }}
{{- end }}
  command: ["/bin/sh", "-c"]
  args:
    - {{ print (include "enterprise.common.dockerEntrypoint" .) }} rbac_authorizer
  envFrom: {{- include "enterprise.common.envFrom" . | nindent 4 }}
  env: {{- include "enterprise.common.environment" (merge (dict "component" "rbacAuth") .) | nindent 4 }}
  ports:
    - containerPort: 8089
      name: rbac-auth
  volumeMounts: {{- include "enterprise.common.volumeMounts" . | nindent 4 }}
  livenessProbe:
    exec:
      command:
        - curl
        - -f
        - 'localhost:8089/health'
    initialDelaySeconds: {{ .Values.probes.liveness.initialDelaySeconds }}
    timeoutSeconds: {{ .Values.probes.liveness.timeoutSeconds }}
    periodSeconds: {{ .Values.probes.liveness.periodSeconds }}
    failureThreshold: {{ .Values.probes.liveness.failureThreshold }}
    successThreshold: {{ .Values.probes.liveness.successThreshold }}
  readinessProbe:
    exec:
      command:
        - curl
        - -f
        - 'localhost:8089/health'
    timeoutSeconds: {{ .Values.probes.readiness.timeoutSeconds }}
    periodSeconds: {{ .Values.probes.readiness.periodSeconds }}
    failureThreshold: {{ .Values.probes.readiness.failureThreshold }}
    successThreshold: {{ .Values.probes.readiness.successThreshold }}
{{- with .Values.rbacAuth.resources }}
  resources: {{- toYaml . | nindent 4 }}
{{- end }}
{{- end -}}


{{/*
Setup the common readiness probes for all Anchore Enterprise containers
*/}}
{{- define "enterprise.common.readinessProbe" -}}
{{- $component := .component -}}
httpGet:
  path: /health
  port: {{ $component | lower }}
  scheme: {{ include "enterprise.setProtocol" . | upper }}
timeoutSeconds: {{ .Values.probes.readiness.timeoutSeconds }}
periodSeconds: {{ .Values.probes.readiness.periodSeconds }}
failureThreshold: {{ .Values.probes.readiness.failureThreshold }}
successThreshold: {{ .Values.probes.readiness.successThreshold }}
{{- end -}}


{{/*
Setup the common anchore volume mounts
*/}}
{{- define "enterprise.common.volumeMounts" -}}
{{- with .Values.extraVolumeMounts }}
{{ toYaml . }}
{{- end }}
- name: anchore-license
  mountPath: /home/anchore/license.yaml
  subPath: license.yaml
- name: config-volume
  mountPath: /config/config.yaml
  subPath: config.yaml
- name: anchore-scripts
  mountPath: /scripts
{{- if .Values.certStoreSecretName }}
- name: certs
  mountPath: /home/anchore/certs/
  readOnly: true
{{- end }}
{{- end -}}


{{/*
Setup the common anchore volumes
*/}}
{{- define "enterprise.common.volumes" -}}
{{- with .Values.extraVolumes }}
{{ toYaml . }}
{{- end }}
- name: anchore-license
  secret:
    secretName: {{ .Values.licenseSecretName }}
- name: anchore-scripts
  configMap:
    name: {{ .Release.Name }}-enterprise-scripts
    defaultMode: 0755
- name: config-volume
  configMap:
    name: {{ template "enterprise.fullname" . }}
{{- with .Values.certStoreSecretName }}
- name: certs
  secret:
    secretName: {{ . }}
{{- end }}
{{- if .Values.cloudsql.useExistingServiceAcc }}
- name: {{ .Values.cloudsql.serviceAccSecretName }}
  secret:
    secretName: {{ .Values.cloudsql.serviceAccSecretName }}
{{- end }}
{{- end -}}
