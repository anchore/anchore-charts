{{/*
Returns the global image registry host, with any trailing slash removed.
Defaults to docker.io via values.yaml; the default dict guards a values file that sets
`global:` with nothing under it, which would otherwise be a nil dereference.
*/}}
{{- define "anchore-admission-controller.globalImageRegistryHost" -}}
{{- $global := default dict .Values.global -}}
{{- default "" $global.imageRegistryHost | trimSuffix "/" -}}
{{- end }}

{{/*
Reports whether a string image reference states a registry host of its own.
The leading path segment is a registry host when it contains a '.' or a ':', or when it is
'localhost' - the same rule the docker/OCI reference parsers use, so this always agrees with
what the container runtime does with the same string.
*/}}
{{- define "anchore-admission-controller.imageStatesRegistry" -}}
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
{{- define "anchore-admission-controller.renderImage" -}}
{{- $image := .image }}
{{- $globalHost := include "anchore-admission-controller.globalImageRegistryHost" .context }}
{{- if eq (printf "%T" $image) "string" }}
  {{- $ref := trim $image }}
  {{- if or (include "anchore-admission-controller.imageStatesRegistry" $ref) (not $globalHost) }}
  {{ $ref }}
  {{- else }}
  {{ printf "%s/%s" $globalHost $ref }}
  {{- end }}
{{- else }}
  {{- $registry := trimSuffix "/" (default $globalHost $image.registry) }}
  {{- if and $image.digest $registry $image.repository }}
  {{ printf "%s/%s@%s" $registry $image.repository $image.digest | trim }}
  {{- else if and $image.tag $registry $image.repository }}
  {{ printf "%s/%s:%s" $registry $image.repository $image.tag | trim }}
  {{- else }}
  {{ fail (printf "Invalid image: must include repository, either tag or digest, and a registry (set it on the image or via global.imageRegistryHost). Got: %#v" $image) }}
  {{- end }}
{{- end }}
{{- end }}

{{/* vim: set filetype=mustache: */}}
{{/*
Expand the name of the chart.
*/}}
{{- define "anchore-admission-controller.name" -}}
{{- default .Chart.Name .Values.nameOverride | trunc 63 | trimSuffix "-" -}}
{{- end -}}

{{/*
Create a default fully qualified app name.
We truncate at 63 chars because some Kubernetes name fields are limited to this (by the DNS naming spec).
*/}}
{{- define "anchore-admission-controller.fullname" -}}
{{- $name := default .Chart.Name .Values.nameOverride -}}
{{- default (printf "%s-%s" .Release.Name $name | trunc 63 | trimSuffix "-") .Values.fullnameOverride -}}
{{- end -}}

{{/*
Create chart name and version as used by the chart label.
*/}}
{{- define "anchore-admission-controller.chart" -}}
{{- printf "%s-%s" .Chart.Name .Chart.Version | replace "+" "_" | trunc 63 | trimSuffix "-" -}}
{{- end -}}

{{/*
Common labels
*/}}
{{- define "anchore-admission-controller.labels" -}}
app.kubernetes.io/name: {{ include "anchore-admission-controller.name" . }}
helm.sh/chart: {{ include "anchore-admission-controller.chart" . }}
app.kubernetes.io/instance: {{ .Release.Name }}
{{- with .Values.extraLabels}}
{{ toYaml . }}
{{- end }}
{{- if .Chart.AppVersion }}
app.kubernetes.io/version: {{ .Chart.AppVersion | quote }}
{{- end }}
app.kubernetes.io/managed-by: {{ .Release.Service }}
{{- end -}}
