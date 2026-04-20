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

{{/*
Resolve the image, replacing "latest" tag with AppVersion for the default upstream image.
Existing customers pinning a specific tag are unaffected.
*/}}
{{- define "anchore-admission-controller.image" -}}
{{- $parts := splitList ":" .Values.image -}}
{{- $repo := first $parts -}}
{{- $tag := last $parts -}}
{{- $defaultRepo := "anchore/kubernetes-admission-controller" -}}
{{- $isDefault := or (eq $repo $defaultRepo) (eq $repo (printf "docker.io/%s" $defaultRepo)) (eq $repo (printf "docker.io/library/%s" $defaultRepo)) -}}
{{- if and $isDefault (or (eq $tag "latest") (eq $tag $repo)) -}}
{{- printf "%s:v%s" $repo .Chart.AppVersion -}}
{{- else -}}
{{- .Values.image -}}
{{- end -}}
{{- end -}}
