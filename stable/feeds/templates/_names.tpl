{{/*
Create a default fully qualified app name.
We truncate at 63 chars because some Kubernetes name fields are limited to this (by the DNS naming spec).
If release name contains chart name it will be used as a full name.
*/}}

{{- define "feeds.fullname" -}}
{{- if .Values.fullnameOverride }}
  {{- .Values.fullnameOverride | trunc 63 | trimSuffix "-" }}
{{- else }}
  {{- $name := default .Chart.Name .Values.nameOverride }}
  {{- printf "%s-%s" .Release.Name $name | trunc 63 | trimSuffix "-" }}
{{- end }}
{{- end }}

{{- define "feeds.upgradeJob.fullname" -}}
{{- $name := default .Chart.Name .Values.nameOverride }}
{{- $forcedRevision := "" -}}
{{- if .Values.feedsUpgradeJob.force }}
{{- $forcedRevision = printf "-forced-%s" (randAlphaNum 5 | lower) -}}
{{- end }}
{{- printf "%s-%s-%s-%s%s" .Release.Name $name (.Chart.AppVersion | replace "." "") "upgrade" $forcedRevision | trunc 63 | trimSuffix "-" }}
{{- end -}}

{{- define "feeds-db.fullname" -}}
{{- printf "%s-%s" .Release.Name "feeds-db" | trunc 63 | trimSuffix "-" }}
{{- end -}}

{{- define "gem-db.fullname" -}}
{{- printf "%s-%s" .Release.Name "gem-db" | trunc 63 | trimSuffix "-" }}
{{- end -}}
