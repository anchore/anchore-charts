{{/*
Create a default fully qualified app name.
We truncate at 63 chars because some Kubernetes name fields are limited to this (by the DNS naming spec).
*/}}

{{- define "enterprise.fullname" -}}
{{- if .Values.global.fullnameOverride }}
  {{- .Values.global.fullnameOverride | trunc 63 | trimSuffix "-" }}
{{- else }}
  {{- $name := default .Chart.Name .Values.global.nameOverride }}
  {{- printf "%s-%s" .Release.Name $name | trunc 63 | trimSuffix "-" }}
{{- end }}
{{- end -}}

{{- define "enterprise.analyzer.fullname" -}}
{{- $name := default .Chart.Name .Values.global.nameOverride -}}
{{- printf "%s-%s-%s" .Release.Name $name "analyzer"| trunc 63 | trimSuffix "-" -}}
{{- end -}}

{{- define "enterprise.api.fullname" -}}
{{- $name := default .Chart.Name .Values.global.nameOverride -}}
{{- printf "%s-%s-%s" .Release.Name $name "api"| trunc 63 | trimSuffix "-" -}}
{{- end -}}

{{- define "enterprise.catalog.fullname" -}}
{{- $name := default .Chart.Name .Values.global.nameOverride -}}
{{- printf "%s-%s-%s" .Release.Name $name "catalog"| trunc 63 | trimSuffix "-" -}}
{{- end -}}

{{- define "enterprise.notifications.fullname" -}}
{{- $name := default .Chart.Name .Values.global.nameOverride -}}
{{- printf "%s-%s-%s" .Release.Name $name "notifications"| trunc 63 | trimSuffix "-" -}}
{{- end -}}

{{- define "enterprise.policyEngine.fullname" -}}
{{- $name := default .Chart.Name .Values.global.nameOverride -}}
{{- printf "%s-%s-%s" .Release.Name $name "policy"| trunc 63 | trimSuffix "-" -}}
{{- end -}}

{{- define "enterprise.reports.fullname" -}}
{{- $name := default .Chart.Name .Values.global.nameOverride -}}
{{- printf "%s-%s-%s" .Release.Name $name "reports"| trunc 63 | trimSuffix "-" -}}
{{- end -}}

{{- define "enterprise.reportsWorker.fullname" -}}
{{- $name := default .Chart.Name .Values.global.nameOverride -}}
{{- printf "%s-%s-%s" .Release.Name $name "reportsworker"| trunc 63 | trimSuffix "-" -}}
{{- end -}}

{{- define "enterprise.simpleQueue.fullname" -}}
{{- $name := default .Chart.Name .Values.global.nameOverride -}}
{{- printf "%s-%s-%s" .Release.Name $name "simplequeue"| trunc 63 | trimSuffix "-" -}}
{{- end -}}

{{- define "enterprise.ui.fullname" -}}
{{- $name := default .Chart.Name .Values.global.nameOverride -}}
{{- printf "%s-%s-%s" .Release.Name $name "ui"| trunc 63 | trimSuffix "-" -}}
{{- end -}}

{{- define "enterprise.upgradeJob.fullname" -}}
{{- $name := default .Chart.Name .Values.global.nameOverride -}}
{{- $forcedRevision := "" -}}
{{- if .Values.upgradeJob.force }}
{{- $forcedRevision = printf "-forced-%s" (randAlphaNum 5 | lower) -}}
{{- end }}
{{- printf "%s-%s-%s-%s%s" .Release.Name $name (.Chart.AppVersion | replace "." "") "upgrade" $forcedRevision| trunc 63 | trimSuffix "-" -}}
{{- end -}}

{{- define "enterprise.osaaMigrationJob.fullname" -}}
{{- $name := default .Chart.Name .Values.global.nameOverride -}}
{{- printf "%s-%s-%s-%s" .Release.Name $name (.Chart.AppVersion | replace "." "") "osaa-migration-job" | trunc 63 | trimSuffix "-" -}}
{{- end -}}

{{- define "enterprise.smokeTest.fullname" -}}
{{- $name := default .Chart.Name .Values.global.nameOverride -}}
{{- printf "%s-%s-%s-%s" .Release.Name $name (.Chart.AppVersion | replace "." "") "smoke-test" | trunc 63 | trimSuffix "-" -}}
{{- end -}}

{{- define "enterprise.feeds.fullname" -}}
{{- if .Values.feeds.fullnameOverride }}
  {{- .Values.feeds.fullnameOverride | trunc 63 | trimSuffix "-" }}
{{- else }}
  {{- $name := default "feeds" .Values.feeds.nameOverride -}}
  {{- printf "%s-%s" .Release.Name $name | trunc 63 | trimSuffix "-" }}
{{- end }}
{{- end -}}

{{- define "postgres.fullname" -}}
{{- printf "%s-%s" .Release.Name "postgresql" | trunc 63 | trimSuffix "-" -}}
{{- end -}}

{{- define "redis.fullname" -}}
{{- printf "%s-%s" .Release.Name "ui-redis" | trunc 63 | trimSuffix "-" -}}
{{- end -}}
