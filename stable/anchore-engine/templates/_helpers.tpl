{{/* vim: set filetype=mustache: */}}
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
{{- define "anchore-engine.fullname" -}}
{{- $name := default .Chart.Name .Values.nameOverride -}}
{{- default (printf "%s-%s" .Release.Name $name | trunc 63 | trimSuffix "-") .Values.fullnameOverride -}}
{{- end -}}

{{/*
Create a default fully qualified app name.
We truncate at 63 chars because some Kubernetes name fields are limited to this (by the DNS naming spec).
*/}}
{{- define "anchore-engine.analyzer.fullname" -}}
{{- $name := default .Chart.Name .Values.nameOverride -}}
{{- printf "%s-%s-%s" .Release.Name $name "analyzer"| trunc 63 | trimSuffix "-" -}}
{{- end -}}

{{/*
Set the appropriate kubernetes service name.
We truncate at 63 chars because some Kubernetes name fields are limited to this (by the DNS naming spec).
*/}}
{{- define "anchore-engine.analyzer.serviceName" -}}
{{- if .Values.anchoreAnalyzer.service.name }}
    {{- print .Values.anchoreAnalyzer.service.name | trunc 63 | trimSuffix "-" -}}
{{- else -}}
    {{- include "anchore-engine.analyzer.fullname" . -}}
{{- end -}}
{{- end -}}

{{/*
Set the appropriate kubernetes service account name.
We truncate at 63 chars because some Kubernetes name fields are limited to this (by the DNS naming spec).
*/}}
{{- define "anchore-engine.analyzer.serviceAccountName" -}}
{{- if .Values.anchoreAnalyzer.serviceAccountName }}
    {{- print .Values.anchoreAnalyzer.serviceAccountName | trunc 63 | trimSuffix "-" -}}
{{- else if .Values.anchoreGlobal.serviceAccountName -}}
    {{- print .Values.anchoreGlobal.serviceAccountName | trunc 63 | trimSuffix "-" -}}
{{- end -}}
{{- end -}}

{{/*
Create a default fully qualified app name.
We truncate at 63 chars because some Kubernetes name fields are limited to this (by the DNS naming spec).
*/}}
{{- define "anchore-engine.catalog.fullname" -}}
{{- $name := default .Chart.Name .Values.nameOverride -}}
{{- printf "%s-%s-%s" .Release.Name $name "catalog"| trunc 63 | trimSuffix "-" -}}
{{- end -}}

{{/*
Set the appropriate kubernetes service name.
We truncate at 63 chars because some Kubernetes name fields are limited to this (by the DNS naming spec).
*/}}
{{- define "anchore-engine.catalog.serviceName" -}}
{{- if .Values.anchoreCatalog.service.name }}
    {{- print .Values.anchoreCatalog.service.name | trunc 63 | trimSuffix "-" -}}
{{- else -}}
    {{- include "anchore-engine.catalog.fullname" . -}}
{{- end -}}
{{- end -}}

{{/*
Set the appropriate kubernetes service account name.
We truncate at 63 chars because some Kubernetes name fields are limited to this (by the DNS naming spec).
*/}}
{{- define "anchore-engine.catalog.serviceAccountName" -}}
{{- if .Values.anchoreCatalog.serviceAccountName }}
    {{- print .Values.anchoreCatalog.serviceAccountName | trunc 63 | trimSuffix "-" -}}
{{- else if .Values.anchoreGlobal.serviceAccountName -}}
    {{- print .Values.anchoreGlobal.serviceAccountName | trunc 63 | trimSuffix "-" -}}
{{- end -}}
{{- end -}}

{{/*
Create a default fully qualified app name.
We truncate at 63 chars because some Kubernetes name fields are limited to this (by the DNS naming spec).
*/}}
{{- define "anchore-engine.api.fullname" -}}
{{- $name := default .Chart.Name .Values.nameOverride -}}
{{- printf "%s-%s-%s" .Release.Name $name "api"| trunc 63 | trimSuffix "-" -}}
{{- end -}}

{{/*
Set the appropriate kubernetes service name.
We truncate at 63 chars because some Kubernetes name fields are limited to this (by the DNS naming spec).
*/}}
{{- define "anchore-engine.api.serviceName" -}}
{{- if .Values.anchoreApi.service.name }}
    {{- print .Values.anchoreApi.service.name | trunc 63 | trimSuffix "-" -}}
{{- else -}}
    {{- include "anchore-engine.api.fullname" . -}}
{{- end -}}
{{- end -}}

{{/*
Set the appropriate kubernetes service account name.
We truncate at 63 chars because some Kubernetes name fields are limited to this (by the DNS naming spec).
*/}}
{{- define "anchore-engine.api.serviceAccountName" -}}
{{- if .Values.anchoreApi.serviceAccountName }}
    {{- print .Values.anchoreApi.serviceAccountName | trunc 63 | trimSuffix "-" -}}
{{- else if .Values.anchoreGlobal.serviceAccountName -}}
    {{- print .Values.anchoreGlobal.serviceAccountName | trunc 63 | trimSuffix "-" -}}
{{- end -}}
{{- end -}}

{{/*
Create a default fully qualified app name.
We truncate at 63 chars because some Kubernetes name fields are limited to this (by the DNS naming spec).
*/}}
{{- define "anchore-engine.policy-engine.fullname" -}}
{{- $name := default .Chart.Name .Values.nameOverride -}}
{{- printf "%s-%s-%s" .Release.Name $name "policy"| trunc 63 | trimSuffix "-" -}}
{{- end -}}

{{/*
Set the appropriate kubernetes service name.
We truncate at 63 chars because some Kubernetes name fields are limited to this (by the DNS naming spec).
*/}}
{{- define "anchore-engine.policy-engine.serviceName" -}}
{{- if .Values.anchorePolicyEngine.service.name }}
    {{- print .Values.anchorePolicyEngine.service.name | trunc 63 | trimSuffix "-" -}}
{{- else -}}
    {{- include "anchore-engine.policy-engine.fullname" . -}}
{{- end -}}
{{- end -}}

{{/*
Set the appropriate kubernetes service account name.
We truncate at 63 chars because some Kubernetes name fields are limited to this (by the DNS naming spec).
*/}}
{{- define "anchore-engine.policy-engine.serviceAccountName" -}}
{{- if .Values.anchorePolicyEngine.serviceAccountName }}
    {{- print .Values.anchorePolicyEngine.serviceAccountName | trunc 63 | trimSuffix "-" -}}
{{- else if .Values.anchoreGlobal.serviceAccountName -}}
    {{- print .Values.anchoreGlobal.serviceAccountName | trunc 63 | trimSuffix "-" -}}
{{- end -}}
{{- end -}}

{{/*
Create a default fully qualified app name.
We truncate at 63 chars because some Kubernetes name fields are limited to this (by the DNS naming spec).
*/}}
{{- define "anchore-engine.simplequeue.fullname" -}}
{{- $name := default .Chart.Name .Values.nameOverride -}}
{{- printf "%s-%s-%s" .Release.Name $name "simplequeue"| trunc 63 | trimSuffix "-" -}}
{{- end -}}

{{/*
Set the appropriate kubernetes service name.
We truncate at 63 chars because some Kubernetes name fields are limited to this (by the DNS naming spec).
*/}}
{{- define "anchore-engine.simplequeue.serviceName" -}}
{{- if .Values.anchoreSimpleQueue.service.name }}
    {{- print .Values.anchoreSimpleQueue.service.name | trunc 63 | trimSuffix "-" -}}
{{- else -}}
    {{- include "anchore-engine.simplequeue.fullname" . -}}
{{- end -}}
{{- end -}}

{{/*
Set the appropriate kubernetes service account name.
We truncate at 63 chars because some Kubernetes name fields are limited to this (by the DNS naming spec).
*/}}
{{- define "anchore-engine.simplequeue.serviceAccountName" -}}
{{- if .Values.anchoreSimpleQueue.serviceAccountName }}
    {{- print .Values.anchoreSimpleQueue.serviceAccountName | trunc 63 | trimSuffix "-" -}}
{{- else if .Values.anchoreGlobal.serviceAccountName -}}
    {{- print .Values.anchoreGlobal.serviceAccountName | trunc 63 | trimSuffix "-" -}}
{{- end -}}
{{- end -}}

{{/*
Create a default fully qualified app name.
We truncate at 63 chars because some Kubernetes name fields are limited to this (by the DNS naming spec).
*/}}
{{- define "anchore-engine.enterprise.fullname" -}}
{{- $name := default .Chart.Name .Values.nameOverride -}}
{{- printf "%s-%s-%s" .Release.Name $name "enterprise"| trunc 63 | trimSuffix "-" -}}
{{- end -}}

{{/*
Create a default fully qualified app name.
We truncate at 63 chars because some Kubernetes name fields are limited to this (by the DNS naming spec).
*/}}
{{- define "anchore-engine.enterprise-ui.fullname" -}}
{{- $name := default .Chart.Name .Values.nameOverride -}}
{{- printf "%s-%s-%s" .Release.Name $name "enterprise-ui"| trunc 63 | trimSuffix "-" -}}
{{- end -}}

{{/*
Set the appropriate kubernetes service name.
We truncate at 63 chars because some Kubernetes name fields are limited to this (by the DNS naming spec).
*/}}
{{- define "anchore-engine.enterprise-ui.serviceName" -}}
{{- if .Values.anchoreEnterpriseUi.service.name }}
    {{- print .Values.anchoreEnterpriseUi.service.name | trunc 63 | trimSuffix "-" -}}
{{- else -}}
    {{- include "anchore-engine.enterprise-ui.fullname" . -}}
{{- end -}}
{{- end -}}

{{/*
Set the appropriate kubernetes service account name.
We truncate at 63 chars because some Kubernetes name fields are limited to this (by the DNS naming spec).
*/}}
{{- define "anchore-engine.enterprise-ui.serviceAccountName" -}}
{{- if .Values.anchoreEnterpriseUi.serviceAccountName }}
    {{- print .Values.anchoreEnterpriseUi.serviceAccountName | trunc 63 | trimSuffix "-" -}}
{{- else if .Values.anchoreGlobal.serviceAccountName -}}
    {{- print .Values.anchoreGlobal.serviceAccountName | trunc 63 | trimSuffix "-" -}}
{{- end -}}
{{- end -}}

{{/*
Create a default fully qualified app name.
We truncate at 63 chars because some Kubernetes name fields are limited to this (by the DNS naming spec).
*/}}
{{- define "anchore-engine.enterprise-feeds.fullname" -}}
{{- $name := default .Chart.Name .Values.nameOverride -}}
{{- printf "%s-%s-%s" .Release.Name $name "enterprise-feeds"| trunc 63 | trimSuffix "-" -}}
{{- end -}}

{{/*
Set the appropriate kubernetes service name.
We truncate at 63 chars because some Kubernetes name fields are limited to this (by the DNS naming spec).
*/}}
{{- define "anchore-engine.enterprise-feeds.serviceName" -}}
{{- if .Values.anchoreEnterpriseFeeds.service.name }}
    {{- print .Values.anchoreEnterpriseFeeds.service.name | trunc 63 | trimSuffix "-" -}}
{{- else -}}
    {{- include "anchore-engine.enterprise-feeds.fullname" . -}}
{{- end -}}
{{- end -}}

{{/*
Set the appropriate kubernetes service account name.
We truncate at 63 chars because some Kubernetes name fields are limited to this (by the DNS naming spec).
*/}}
{{- define "anchore-engine.enterprise-feeds.serviceAccountName" -}}
{{- if .Values.anchoreEnterpriseFeeds.serviceAccountName }}
    {{- print .Values.anchoreEnterpriseFeeds.serviceAccountName | trunc 63 | trimSuffix "-" -}}
{{- else if .Values.anchoreGlobal.serviceAccountName -}}
    {{- print .Values.anchoreGlobal.serviceAccountName | trunc 63 | trimSuffix "-" -}}
{{- end -}}
{{- end -}}

{{/*
Create a default fully qualified app name.
We truncate at 63 chars because some Kubernetes name fields are limited to this (by the DNS naming spec).
*/}}
{{- define "anchore-engine.enterprise-reports.fullname" -}}
{{- $name := default .Chart.Name .Values.nameOverride -}}
{{- printf "%s-%s-%s" .Release.Name $name "enterprise-reports"| trunc 63 | trimSuffix "-" -}}
{{- end -}}

{{/*
Set the appropriate kubernetes service name.
We truncate at 63 chars because some Kubernetes name fields are limited to this (by the DNS naming spec).
*/}}
{{- define "anchore-engine.enterprise-reports.serviceName" -}}
{{- if .Values.anchoreEnterpriseReports.service.name }}
    {{- print .Values.anchoreEnterpriseReports.service.name | trunc 63 | trimSuffix "-" -}}
{{- else -}}
    {{- include "anchore-engine.enterprise-reports.fullname" . -}}
{{- end -}}
{{- end -}}

{{/*
Set the appropriate kubernetes service account name.
We truncate at 63 chars because some Kubernetes name fields are limited to this (by the DNS naming spec).
*/}}
{{- define "anchore-engine.enterprise-reports.serviceAccountName" -}}
{{- if .Values.anchoreEnterpriseReports.serviceAccountName }}
    {{- print .Values.anchoreEnterpriseReports.serviceAccountName | trunc 63 | trimSuffix "-" -}}
{{- else if .Values.anchoreGlobal.serviceAccountName -}}
    {{- print .Values.anchoreGlobal.serviceAccountName | trunc 63 | trimSuffix "-" -}}
{{- end -}}
{{- end -}}

{{/*
Create a default fully qualified app name.
We truncate at 63 chars because some Kubernetes name fields are limited to this (by the DNS naming spec).
*/}}
{{- define "anchore-engine.enterprise-notifications.fullname" -}}
{{- $name := default .Chart.Name .Values.nameOverride -}}
{{- printf "%s-%s-%s" .Release.Name $name "enterprise-notifications"| trunc 63 | trimSuffix "-" -}}
{{- end -}}

{{/*
Set the appropriate kubernetes service name.
We truncate at 63 chars because some Kubernetes name fields are limited to this (by the DNS naming spec).
*/}}
{{- define "anchore-engine.enterprise-notifications.serviceName" -}}
{{- if .Values.anchoreEnterpriseNotifications.service.name }}
    {{- print .Values.anchoreEnterpriseNotifications.service.name | trunc 63 | trimSuffix "-" -}}
{{- else -}}
    {{- include "anchore-engine.enterprise-notifications.fullname" . -}}
{{- end -}}
{{- end -}}

{{/*
Set the appropriate kubernetes service account name.
We truncate at 63 chars because some Kubernetes name fields are limited to this (by the DNS naming spec).
*/}}
{{- define "anchore-engine.enterprise-notifications.serviceAccountName" -}}
{{- if .Values.anchoreEnterpriseNotifications.serviceAccountName }}
    {{- print .Values.anchoreEnterpriseNotifications.serviceAccountName | trunc 63 | trimSuffix "-" -}}
{{- else if .Values.anchoreGlobal.serviceAccountName -}}
    {{- print .Values.anchoreGlobal.serviceAccountName | trunc 63 | trimSuffix "-" -}}
{{- end -}}
{{- end -}}

{{/*
Create a default fully qualified app name.
We truncate at 63 chars because some Kubernetes name fields are limited to this (by the DNS naming spec).
*/}}
{{- define "anchore-engine.enterprise-rbac.fullname" -}}
{{- $name := default .Chart.Name .Values.nameOverride -}}
{{- printf "%s-%s-%s" .Release.Name $name "enterprise-rbac"| trunc 63 | trimSuffix "-" -}}
{{- end -}}

{{/*
Set the appropriate kubernetes service name.
We truncate at 63 chars because some Kubernetes name fields are limited to this (by the DNS naming spec).
*/}}
{{- define "anchore-engine.enterprise-rbac.serviceName" -}}
{{- if .Values.anchoreEnterpriseRbac.service.name }}
    {{- print .Values.anchoreEnterpriseRbac.service.name | trunc 63 | trimSuffix "-" -}}
{{- else -}}
    {{- include "anchore-engine.enterprise-rbac.fullname" . -}}
{{- end -}}
{{- end -}}

{{/*
Set the appropriate kubernetes service account name.
We truncate at 63 chars because some Kubernetes name fields are limited to this (by the DNS naming spec).
*/}}
{{- define "anchore-engine.enterprise-rbac.serviceAccountName" -}}
{{- if .Values.anchoreEnterpriseRbac.serviceAccountName }}
    {{- print .Values.anchoreEnterpriseRbac.serviceAccountName | trunc 63 | trimSuffix "-" -}}
{{- else if .Values.anchoreGlobal.serviceAccountName -}}
    {{- print .Values.anchoreGlobal.serviceAccountName | trunc 63 | trimSuffix "-" -}}
{{- end -}}
{{- end -}}

{{/*
Create a default fully qualified dependency name for the db.
We truncate at 63 chars because some Kubernetes name fields are limited to this (by the DNS naming spec).
*/}}
{{- define "postgres.fullname" -}}
{{- printf "%s-%s" .Release.Name "postgresql" | trunc 63 | trimSuffix "-" -}}
{{- end -}}

{{/*
Create a default fully qualified dependency name for the feeds db.
We truncate at 63 chars because some Kubernetes name fields are limited to this (by the DNS naming spec).
*/}}
{{- define "postgres.anchore-feeds-db.fullname" -}}
{{- printf "%s-%s" .Release.Name "anchore-feeds-db" | trunc 63 | trimSuffix "-" -}}
{{- end -}}

{{/*
Create a default fully qualified dependency name for the feeds gem db.
We truncate at 63 chars because some Kubernetes name fields are limited to this (by the DNS naming spec).
*/}}
{{- define "postgres.anchore-feeds-gem-db.fullname" -}}
{{- printf "%s-%s" .Release.Name "anchore-feeds-gem-db" | trunc 63 | trimSuffix "-" -}}
{{- end -}}

{{/*
Create a default fully qualified dependency name for the db.
We truncate at 63 chars because some Kubernetes name fields are limited to this (by the DNS naming spec).
*/}}
{{- define "redis.fullname" -}}
{{- printf "%s-%s" .Release.Name "ui-redis" | trunc 63 | trimSuffix "-" -}}
{{- end -}}

{{/*
Return Anchore Engine default admin password
*/}}
{{- define "anchore-engine.defaultAdminPassword" -}}
{{- if .Values.anchoreGlobal.defaultAdminPassword }}
    {{- .Values.anchoreGlobal.defaultAdminPassword -}}
{{- else -}}
    {{- randAlphaNum 32 -}}
{{- end -}}
{{- end -}}

{{/*
Create feeds database hostname string from supplied values file. Used for setting the ANCHORE_FEEDS_DB_HOST env var in the Feeds secret.
*/}}
{{- define "feeds-db-hostname" }}
  {{- if and (index .Values "anchore-feeds-db" "externalEndpoint") (not (index .Values "anchore-feeds-db" "enabled")) }}
    {{- print ( index .Values "anchore-feeds-db" "externalEndpoint" ) }}
  {{- else if and (index .Values "cloudsql" "enabled") (not (index .Values "anchore-feeds-db" "enabled")) }}
    {{- print "localhost:5432" }}
  {{- else }}
    {{- $db_host := include "postgres.anchore-feeds-db.fullname" . }}
    {{- printf "%s:5432" $db_host -}}
  {{- end }}
{{- end }}

{{/*
Create database hostname string from supplied values file. Used for setting the ANCHORE_DB_HOST env var in the UI & Engine secret.
*/}}
{{- define "db-hostname" }}
  {{- if and (index .Values "postgresql" "externalEndpoint") (not (index .Values "postgresql" "enabled")) }}
    {{- print ( index .Values "postgresql" "externalEndpoint" ) }}
  {{- else if and (index .Values "cloudsql" "enabled") (not (index .Values "postgresql" "enabled")) }}
    {{- print "localhost:5432" }}
  {{- else }}
    {{- $db_host := include "postgres.fullname" . }}
    {{- printf "%s:5432" $db_host -}}
  {{- end }}
{{- end }}

{{/*
Allows sourcing of a specified file in the entrypoint of all containers when .Values.anchoreGlobal.doSourceAtEntry.enabled=true
*/}}
{{- define "doSourceFile" }}
{{- if .Values.anchoreGlobal.doSourceAtEntry.enabled }}
    {{- printf "source %v;" .Values.anchoreGlobal.doSourceAtEntry.filePath }}
{{- end }}
{{- end }}

{{/*
Upon upgrades, checks if .Values.existingSecret=true and fails the upgrade if .Values.useExistingSecret is not set.
*/}}
{{- define "checkUpgradeForExistingSecret" }}
{{- if and .Release.IsUpgrade .Values.anchoreGlobal.existingSecret (not .Values.anchoreGlobal.useExistingSecrets) }}
    {{- fail "As of chart v1.21.0 `.Values.anchoreGlobal.existingSecret` is no longer a valid configuration value. See the chart README for more instructions on configuring existing secrets - https://github.com/anchore/anchore-charts/blob/main/stable/anchore-engine/README.md#chart-version-1210" }}
{{- end }}
{{- end }}

{{/*
Upon upgrade, check if user is upgrading to chart v1.22.0+ (Enterprise v4.4.0). If they are, ensure that they are
upgrading from Enterprise 4.2.0 or higher and error out if they're upgrading from an older version.
*/}}
{{- define "checkUpgradeCompatibility" }}
{{- if and .Release.IsUpgrade (regexMatch "1.22.[0-9]+" .Chart.Version) }}
    {{- $apiDeployment := (lookup "apps/v1" "Deployment" .Release.Namespace (include "anchore-engine.api.fullname" .)) }}
    {{- if $apiDeployment }}
        {{- $apiDeploymentContainers := $apiDeployment.spec.template.spec.containers}}
        {{- range $index, $container := $apiDeploymentContainers }}
            {{- if eq $container.name "anchore-engine-api" }}
                {{- $apiContainerImage := $container.image }}
                {{- $installedAnchoreVersion := (regexFind ":v[0-9]+\\.[0-9]+\\.[0-9]+" $apiContainerImage | trimPrefix ":") }}
                {{- if $installedAnchoreVersion }}
                    {{- if not (regexMatch "v4\\.[2-9]\\.[0-9]" ($installedAnchoreVersion | quote)) }}
                        {{- fail "Anchore Enterprise v4.4.x only supports upgrades from Enterprise v4.2.0 and higher. See release notes for more information - https://docs.anchore.com/current/docs/releasenotes/440/" }}
                    {{- end }}
                {{- end }}
            {{- end }}
        {{- end }}
    {{- end }}
{{- end }}
{{- end }}