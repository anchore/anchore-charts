{{/*
Expand the name of the chart.
*/}}
{{- define "name" -}}
{{- default .Chart.Name .Values.nameOverride | trunc 63 | trimSuffix "-" -}}
{{- end -}}

{{/*
Create a default fully qualified app name.
We truncate at 63 chars because some Kubernetes name fields are limited to this (by the DNS naming spec).
*/}}
{{- define "enterprise.fullname" -}}
{{- if .Values.fullnameOverride }}
{{- .Values.fullnameOverride | trunc 63 | trimSuffix "-" }}
{{- else }}
{{- $name := default .Chart.Name .Values.nameOverride }}
{{- if contains $name .Release.Name }}
{{- .Release.Name | trunc 63 | trimSuffix "-" }}
{{- else }}
{{- printf "%s-%s" .Release.Name $name | trunc 63 | trimSuffix "-" }}
{{- end }}
{{- end }}
{{- end -}}

{{- define "enterprise.analyzer.fullname" -}}
{{- $name := default .Chart.Name .Values.nameOverride -}}
{{- printf "%s-%s-%s" .Release.Name $name "analyzer"| trunc 63 | trimSuffix "-" -}}
{{- end -}}

{{- define "enterprise.catalog.fullname" -}}
{{- $name := default .Chart.Name .Values.nameOverride -}}
{{- printf "%s-%s-%s" .Release.Name $name "catalog"| trunc 63 | trimSuffix "-" -}}
{{- end -}}

{{- define "enterprise.api.fullname" -}}
{{- $name := default .Chart.Name .Values.nameOverride -}}
{{- printf "%s-%s-%s" .Release.Name $name "api"| trunc 63 | trimSuffix "-" -}}
{{- end -}}

{{- define "enterprise.policy-engine.fullname" -}}
{{- $name := default .Chart.Name .Values.nameOverride -}}
{{- printf "%s-%s-%s" .Release.Name $name "policy"| trunc 63 | trimSuffix "-" -}}
{{- end -}}

{{- define "enterprise.simplequeue.fullname" -}}
{{- $name := default .Chart.Name .Values.nameOverride -}}
{{- printf "%s-%s-%s" .Release.Name $name "simplequeue"| trunc 63 | trimSuffix "-" -}}
{{- end -}}

{{- define "enterprise.ui.fullname" -}}
{{- $name := default .Chart.Name .Values.nameOverride -}}
{{- printf "%s-%s-%s" .Release.Name $name "ui"| trunc 63 | trimSuffix "-" -}}
{{- end -}}

{{- define "enterprise.feeds.fullname" -}}
{{- $name := default .Chart.Name .Values.nameOverride -}}
{{- printf "%s-%s-%s" .Release.Name $name "feeds"| trunc 63 | trimSuffix "-" -}}
{{- end -}}

{{- define "enterprise.reports.fullname" -}}
{{- $name := default .Chart.Name .Values.nameOverride -}}
{{- printf "%s-%s-%s" .Release.Name $name "reports"| trunc 63 | trimSuffix "-" -}}
{{- end -}}

{{- define "enterprise.notifications.fullname" -}}
{{- $name := default .Chart.Name .Values.nameOverride -}}
{{- printf "%s-%s-%s" .Release.Name $name "notifications"| trunc 63 | trimSuffix "-" -}}
{{- end -}}

{{- define "postgres.fullname" -}}
{{- printf "%s-%s" .Release.Name "postgresql" | trunc 63 | trimSuffix "-" -}}
{{- end -}}

{{- define "postgres.enterprise-feeds-db.fullname" -}}
{{- printf "%s-%s" .Release.Name "feeds-db" | trunc 63 | trimSuffix "-" -}}
{{- end -}}

{{- define "redis.fullname" -}}
{{- printf "%s-%s" .Release.Name "ui-redis" | trunc 63 | trimSuffix "-" -}}
{{- end -}}

{{/*
Create chart name and version as used by the chart label.
*/}}
{{- define "enterprise.chart" -}}
{{- printf "%s-%s" .Chart.Name .Chart.Version | replace "+" "_" | trunc 63 | trimSuffix "-" }}
{{- end -}}

{{/*
Common labels
When calling this template, .component can be included in the context for component specific labels
{{- include "enterprise.labels" (merge (dict "component" $component) .) }}
*/}}
{{- define "enterprise.labels" -}}
{{- $component := .component }}
app.kubernetes.io/name: {{ template "enterprise.fullname" . }}
{{- if $component }}
app.kubernetes.io/component: {{ $component }}
{{- end }}
app.kubernetes.io/instance: {{ .Release.Name }}
app.kubernetes.io/version: {{ .Chart.AppVersion | quote }}
app.kubernetes.io/part-of: "Anchore Enterprise"
app.kubernetes.io/managed-by: {{ .Release.Service }}
helm.sh/chart: {{ template "enterprise.chart" . }}
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
Common annotations
When calling this template, .component can be included in the context for component specific annotations
{{- include "enterprise.annotations" (merge (dict "component" $component) .) }}
*/}}
{{- define "enterprise.annotations" -}}
{{- $component := .component -}}
{{- with .Values.annotations }}
{{ toYaml . }}
{{- end }}
{{- if $component }}
{{- with (index .Values (print $component)).annotations }}
{{ toYaml . }}
{{- end }}
{{- end }}
{{- end -}}

{{/*
Common environment variables
When calling this template, .component can be included in the context for component specific env vars
{{- include "enterprise.environment" (merge (dict "component" $component) .) }}
*/}}
{{- define "enterprise.environment" -}}
{{- $component := .component -}}
{{- with .Values.extraEnv }}
{{ toYaml . }}
{{- end }}
{{- if $component }}
{{- with (index .Values (print $component)).extraEnv }}
{{ toYaml . }}
{{- end }}
{{- end }}
{{- end -}}

{{/*
Return Anchore default admin password
*/}}
{{- define "enterprise.defaultAdminPassword" -}}
{{- if .Values.defaultAdminPassword }}
    {{- .Values.defaultAdminPassword -}}
{{- else -}}
    {{- randAlphaNum 32 -}}
{{- end -}}
{{- end -}}

{{/*
Create database hostname string from supplied values file. Used for the ui ANCHORE_APPDB_URI environment variable secret
*/}}
{{- define "enterprise.db-hostname" }}
  {{- if and (index .Values "postgresql" "externalEndpoint") (not (index .Values "postgresql" "enabled")) }}
    {{- print ( index .Values "postgresql" "externalEndpoint" ) }}
  {{- else if and (index .Values "cloudsql" "enabled") (not (index .Values "postgresql" "enabled")) }}
    {{- print "localhost:5432" }}
  {{- else }}
    {{- $db_host := include "postgres.fullname" . }}
    {{- printf "%s:5432" $db_host -}}
  {{- end }}
{{- end -}}