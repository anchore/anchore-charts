{{/*
Common annotations
*/}}
{{- define "feeds.common.annotations" -}}
{{- $component := .component -}}
{{- if and (not .nil) (not .Values.annotations) (not (index .Values (print $component)).annotations) }}
  {{- print "{}" }}
{{- else }}
  {{- with .Values.annotations }}
    {{- toYaml . }}
  {{- end }}
  {{- if $component }}
    {{- with (index .Values (print $component)).annotations }}
{{ toYaml . }}
    {{- end }}
  {{- end }}
{{- end }}
{{- end -}}

{{/*
Service annotations
*/}}
{{- define "feeds.service.annotations" -}}
{{- if and (not .nil) (not .Values.service.annotations) (not .Values.annotations) }}
  {{- print "{}" }}
{{- else }}
  {{- with .Values.service.annotations }}
{{ toYaml . }}
  {{- end }}
  {{- with .Values.annotations }}
{{ toYaml . }}
  {{- end }}
{{- end }}
{{- end -}}

{{/*
Setup a container for the cloudsql proxy to run in all pods when .Values.cloudsql.enabled = true
*/}}
{{- define "feeds.common.cloudsqlContainer" -}}
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
    - mountPath: /var/{{ .Values.cloudsql.serviceAccSecretName }}
      name: {{ .Values.cloudsql.serviceAccSecretName }}
      readOnly: true
{{- end }}
{{- end -}}

{{/*
Common environment variables
*/}}
{{- define "feeds.common.environment" -}}
{{- with .Values.extraEnv }}
  {{- toYaml . }}
{{- end }}
- name: ANCHORE_HOST_ID
  valueFrom:
    fieldRef:
      fieldPath: metadata.name
- name: ANCHORE_ENDPOINT_HOSTNAME
  value: {{ template "feeds.fullname" . }}.{{ .Release.Namespace }}.svc.cluster.local
- name: ANCHORE_PORT
  value: {{ .Values.service.port | quote }}
{{- end -}}

{{/*
Common labels
*/}}
{{- define "feeds.common.labels" -}}
{{- $component := .component -}}
app.kubernetes.io/name: {{ template "feeds.fullname" . }}
app.kubernetes.io/component: feeds
app.kubernetes.io/instance: {{ .Release.Name }}
app.kubernetes.io/version: {{ .Chart.AppVersion }}
app.kubernetes.io/part-of: anchore
app.kubernetes.io/managed-by: {{ .Release.Service }}
helm.sh/chart: {{ printf "%s-%s" .Chart.Name .Chart.Version | replace "+" "_" | trunc 63 | trimSuffix "-" }}
{{- with .Values.labels }}
{{ toYaml . }}
{{- end }}
{{- if $component }}
  {{- with (index .Values (print $component)).labels }}
{{ toYaml . }}
  {{- end }}
{{- end }}
{{- end -}}

{{/*
Return anchore default selector match labels
*/}}
{{- define "feeds.common.matchLabels" -}}
app.kubernetes.io/name: {{ template "feeds.fullname" . }}
app.kubernetes.io/component: feeds
{{- end -}}
