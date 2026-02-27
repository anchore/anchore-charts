{{/*
Selector labels
*/}}
{{- define "ecsInventory.selectorLabels" -}}
app.kubernetes.io/name: {{ include "ecsInventory.name" . }}
app.kubernetes.io/instance: {{ .Release.Name }}
{{- end }}

{{/*
Common labels
*/}}
{{- define "ecsInventory.labels" -}}
helm.sh/chart: {{ include "ecsInventory.chart" . }}
{{ include "ecsInventory.selectorLabels" . }}
{{- if .Chart.AppVersion }}
app.kubernetes.io/version: {{ .Chart.AppVersion | quote }}
chart: {{ .Chart.Name }}-{{ .Chart.Version }}
{{- end }}
app.kubernetes.io/managed-by: {{ .Release.Service }}
{{- with .Values.labels }}
{{ toYaml . }}
{{- end }}
app: {{ include "ecsInventory.fullname" . }}
release: {{ .Release.Name }}
heritage: {{ .Release.Service }}
{{- end }}

{{/*
Resolve the image, replacing "latest" tag with AppVersion for the default upstream image.
Existing customers pinning a specific tag are unaffected.
*/}}
{{- define "ecsInventory.image" -}}
{{- $parts := splitList ":" .Values.image -}}
{{- $repo := first $parts -}}
{{- $tag := last $parts -}}
{{- $defaultRepo := "anchore/ecs-inventory" -}}
{{- $isDefault := or (eq $repo $defaultRepo) (eq $repo (printf "docker.io/%s" $defaultRepo)) (eq $repo (printf "docker.io/library/%s" $defaultRepo)) -}}
{{- if and $isDefault (or (eq $tag "latest") (eq $tag $repo)) -}}
{{- printf "%s:v%s" $repo .Chart.AppVersion -}}
{{- else -}}
{{- .Values.image -}}
{{- end -}}
{{- end -}}
