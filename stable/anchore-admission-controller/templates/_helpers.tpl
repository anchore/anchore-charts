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
Returns the global image registry host override, or an empty string when it isn't set.
*/}}
{{- define "anchore-admission-controller.globalImageRegistryHost" -}}
{{- $global := default dict .Values.global -}}
{{- default "" $global.imageRegistryHost | trimSuffix "/" -}}
{{- end -}}

{{/*
Strips the registry host from a string image reference, returning everything after it.
The leading path segment is treated as a registry host when it contains a '.' or a ':', or when it
is 'localhost' - the same rule the docker/OCI reference parsers use. References that don't include a
registry host (eg. 'anchore/kubernetes-admission-controller') are returned unchanged.
*/}}
{{- define "anchore-admission-controller.imageWithoutRegistryHost" -}}
{{- $ref := trim . -}}
{{- $parts := splitList "/" $ref -}}
{{- $host := first $parts -}}
{{- if and (gt (len $parts) 1) (or (contains "." $host) (contains ":" $host) (eq $host "localhost")) -}}
{{- join "/" (rest $parts) -}}
{{- else -}}
{{- $ref -}}
{{- end -}}
{{- end -}}

{{/*
Renders an image reference with its registry host replaced by global.imageRegistryHost when that is
set. Accepts: dict "image" <image value> "context" <root context>
*/}}
{{- define "anchore-admission-controller.renderImage" -}}
{{- $globalHost := include "anchore-admission-controller.globalImageRegistryHost" .context -}}
{{- if $globalHost -}}
{{- printf "%s/%s" $globalHost (include "anchore-admission-controller.imageWithoutRegistryHost" .image) -}}
{{- else -}}
{{- .image | trim -}}
{{- end -}}
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
