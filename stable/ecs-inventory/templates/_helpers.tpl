{{/*
Returns the global image registry host, with any trailing slash removed.
Defaults to docker.io via values.yaml; the default dict guards a values file that sets
`global:` with nothing under it, which would otherwise be a nil dereference.
*/}}
{{- define "ecsInventory.globalImageRegistryHost" -}}
{{- $global := default dict .Values.global -}}
{{- default "" $global.imageRegistryHost | trimSuffix "/" -}}
{{- end }}

{{/*
Reports whether a string image reference states a registry host of its own.
The leading path segment is a registry host when it contains a '.' or a ':', or when it is
'localhost' - the same rule the docker/OCI reference parsers use, so this always agrees with
what the container runtime does with the same string.
*/}}
{{- define "ecsInventory.imageStatesRegistry" -}}
{{- $parts := splitList "/" (trim .) -}}
{{- $head := first $parts -}}
{{- if and (gt (len $parts) 1) (or (contains "." $head) (contains ":" $head) (eq $head "localhost")) -}}
true
{{- end -}}
{{- end }}

{{/*
Generic image rendering helper.
Accepts: dict "image" <image value> "context" <root context>
Handles dicts with tag or digest, and complete reference strings; fails if incomplete.

An image value that states no registry of its own - a dict without `registry`, or a string
without a registry host - takes one from global.imageRegistryHost. An image value that does
state one keeps it, so a single image can be pointed at a different mirror than the rest.
*/}}
{{- define "ecsInventory.renderImage" -}}
{{- $image := .image }}
{{- $globalHost := include "ecsInventory.globalImageRegistryHost" .context }}
{{- if eq (printf "%T" $image) "string" }}
  {{- $ref := trim $image }}
  {{- if or (include "ecsInventory.imageStatesRegistry" $ref) (not $globalHost) }}
  {{ $ref }}
  {{- else }}
  {{ printf "%s/%s" $globalHost $ref }}
  {{- end }}
{{- else }}
  {{- $registry := default $globalHost $image.registry }}
  {{- if and $image.digest $registry $image.repository }}
  {{ printf "%s/%s@%s" $registry $image.repository $image.digest | trim }}
  {{- else if and $image.tag $registry $image.repository }}
  {{ printf "%s/%s:%s" $registry $image.repository $image.tag | trim }}
  {{- else }}
  {{ fail (printf "Invalid image: must include repository, either tag or digest, and a registry (set it on the image or via global.imageRegistryHost). Got: %#v" $image) }}
  {{- end }}
{{- end }}
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
