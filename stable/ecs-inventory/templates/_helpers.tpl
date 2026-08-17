{{/*
Returns the global image registry host override, or an empty string when it isn't set.
*/}}
{{- define "ecsInventory.globalImageRegistryHost" -}}
{{- $global := default dict .Values.global -}}
{{- default "" $global.imageRegistryHost | trimSuffix "/" -}}
{{- end }}

{{/*
Strips the registry host from a string image reference, returning everything after it.
The leading path segment is treated as a registry host when it contains a '.' or a ':', or when it
is 'localhost' - the same rule the docker/OCI reference parsers use. References that don't include a
registry host (eg. 'anchore/ecs-inventory') are returned unchanged.
*/}}
{{- define "ecsInventory.imageWithoutRegistryHost" -}}
{{- $ref := trim . -}}
{{- $parts := splitList "/" $ref -}}
{{- $host := first $parts -}}
{{- if and (gt (len $parts) 1) (or (contains "." $host) (contains ":" $host) (eq $host "localhost")) -}}
{{- join "/" (rest $parts) -}}
{{- else -}}
{{- $ref -}}
{{- end -}}
{{- end }}

{{/*
The image used by the ECS Inventory deployment, with its registry host replaced by
global.imageRegistryHost when that is set.
*/}}
{{- define "ecsInventory.image" -}}
{{- $globalHost := include "ecsInventory.globalImageRegistryHost" . -}}
{{- if $globalHost -}}
{{- printf "%s/%s" $globalHost (include "ecsInventory.imageWithoutRegistryHost" .Values.image) -}}
{{- else -}}
{{- .Values.image | trim -}}
{{- end -}}
{{- end }}

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
