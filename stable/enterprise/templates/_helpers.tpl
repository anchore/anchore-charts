{{/*
Create database hostname string from supplied values file. Used for setting the ANCHORE_DB_HOST env var in the UI & Engine secret.
*/}}
{{- define "enterprise.dbHostname" }}
  {{- if (index .Values "postgresql" "externalEndpoint") }}
    {{- print ( index .Values "postgresql" "externalEndpoint" ) }}
  {{- else if and (index .Values "cloudsql" "enabled") }}
    {{- print "127.0.0.1" }}
  {{- else }}
    {{- $db_host := include "postgres.fullname" . }}
    {{- printf "%s" $db_host -}}
  {{- end }}
{{- end }}

{{/* enterprise.defaultAuditResourceURIs */}}
{{- define "enterprise.defaultAuditResourceURIs" -}}
- "/accounts"
- "/accounts/{account_name}"
- "/accounts/{account_name}/state"
- "/accounts/{account_name}/users"
- "/accounts/{account_name}/users/{username}"
- "/accounts/{account_name}/users/{username}/api-keys"
- "/accounts/{account_name}/users/{username}/api-keys/{key_name}"
- "/accounts/{account_name}/users/{username}/credentials"
- "/rbac-manager/roles"
- "/rbac-manager/roles/{role_name}/members"
- "/rbac-manager/saml/idps"
- "/rbac-manager/saml/idps/{name}"
- "/rbac-manager/saml/idps/{name}/user-group-mappings"
- "/system/user-groups"
- "/system/user-groups/{group_uuid}"
- "/system/user-groups/{group_uuid}/roles"
- "/system/user-groups/{group_uuid}/users"
- "/user/api-keys"
- "/user/api-keys/{key_name}"
- "/user/credentials"
{{- end }}


{{/*
Return Anchore default admin password
*/}}
{{- define "enterprise.defaultAdminPassword" -}}
  {{- if .Values.anchoreConfig.default_admin_password }}
    {{- .Values.anchoreConfig.default_admin_password -}}
  {{- else -}}
    {{- randAlphaNum 32 -}}
  {{- end -}}
{{- end -}}

{{/*
Return Anchore SAML SECRET
*/}}
{{- define "enterprise.samlSecret" -}}
  {{- if .Values.anchoreConfig.keys.secret }}
    {{- .Values.anchoreConfig.keys.secret -}}
  {{- else -}}
    {{- randAlphaNum 32 -}}
  {{- end -}}
{{- end -}}

{{/*
Allows sourcing of a specified file in the entrypoint of all containers when .Values.doSourceAtEntry.enabled == true
*/}}
{{- define "enterprise.doSourceFile" }}
  {{- if .Values.doSourceAtEntry.enabled }}
    {{- range $index, $file := .Values.doSourceAtEntry.filePaths }}
        {{- printf "if [ -f %v ];then source %v;fi;" $file $file }}
    {{- end }}
  {{- end }}
{{- end }}

{{/*
Allows passing in a feature flag to the ui application on startup
*/}}
{{- define "enterprise.ui.featureFlags" }}
  {{- range $index, $val := .Values.ui.extraEnv -}}
    {{- if eq .name "ANCHORE_FEATURE_FLAG" }}
      {{- printf "-f %v" .value }}
    {{- end }}
  {{- end }}
{{- end }}


{{/*
Set the appropriate kubernetes service account name.
We truncate at 63 chars because some Kubernetes name fields are limited to this (by the DNS naming spec).
*/}}
{{- define "enterprise.serviceAccountName" -}}
{{- $component := .component -}}
{{- with (index .Values (print $component)).serviceAccountName }}
  {{- print . | trunc 63 | trimSuffix "-" -}}
{{- else }}
  {{- if and .Values.upgradeJob.rbacCreate (or (eq $component "upgradeJob") (eq $component "osaaMigrationJob") ) }}
    {{- printf "%s-%s" (include "enterprise.fullname" .) "upgrade-sa" -}}
  {{- else if .Values.serviceAccountName }}
    {{- print .Values.serviceAccountName | trunc 63 | trimSuffix "-" -}}
  {{- end }}
{{- end }}
{{- end -}}


{{/*
Return the proper protocol when Anchore internal SSL is enabled
*/}}
{{- define "enterprise.setProtocol" -}}
  {{- if .Values.anchoreConfig.internalServicesSSL.enabled }}
{{- print "https" -}}
  {{- else -}}
{{- print "http" -}}
  {{- end }}
{{- end -}}


{{/*
Return the database password for the Anchore Enterprise UI config
*/}}
{{- define "enterprise.ui.dbPassword" -}}
{{ ternary .Values.postgresql.auth.password .Values.anchoreConfig.ui.dbPassword (empty .Values.anchoreConfig.ui.dbPassword) }}
{{- end -}}


{{/*
Return the database user for the Anchore Enterprise UI config
*/}}
{{- define "enterprise.ui.dbUser" -}}
{{ ternary .Values.postgresql.auth.username .Values.anchoreConfig.ui.dbUser (empty .Values.anchoreConfig.ui.dbUser) }}
{{- end -}}

{{/*
Set the nodePort for services if its defined
*/}}
{{- define "enterprise.service.nodePort" -}}
{{- $component := .component -}}
{{- if (index .Values (print $component)).service.nodePort -}}
nodePort: {{ (index .Values (print $component)).service.nodePort }}
{{- end -}}
{{- end -}}

{{/*
Checks if the appVersion.minor has increased, which is indicitive of requiring a db upgrade/service scaling down
*/}}
{{- define "enterprise.appVersionChanged" -}}
  {{- if .Values.upgradeJob.forceScaleDownDeployment -}}
    {{- print "true" -}}
  {{- else -}}
    {{- $configMapName := include "enterprise.fullname" . -}}
    {{- $configMap := (lookup "v1" "ConfigMap" .Release.Namespace $configMapName) -}}
    {{- if $configMap -}}
      {{- $currentAppVersion := .Chart.AppVersion -}}
      {{- $currentAppVersionSplit := splitList "." $currentAppVersion -}}
      {{- $currentAppVersionMajorMinor := ($currentAppVersionSplit | initial | join ".") -}}
      {{- $labelVersionKey := "app.kubernetes.io/version" -}}
      {{- $configMapAppVersion := index $configMap.metadata.labels $labelVersionKey -}}
      {{- $configMapAppVersionSplit := splitList "." $configMapAppVersion -}}
      {{- $configMapAppVersionMajorMinor := ($configMapAppVersionSplit | initial | join ".") -}}
      {{- if ne $currentAppVersionMajorMinor $configMapAppVersionMajorMinor -}}
        {{- print "true" -}}
      {{- else -}}
        {{- print "false" -}}
      {{- end -}}
    {{- else -}}
      {{- print "true" -}}
    {{- end -}}

  {{- end -}}
{{- end -}}

{{/*
Constructs a proper dockerconfig json string for use in the image pull secret that is managed by the chart
*/}}
{{- define "enterprise.imagePullSecret" }}
{{- printf "{\"auths\":{\"%s\":{\"username\":\"%s\",\"password\":\"%s\",\"email\":\"%s\",\"auth\":\"%s\"}}}" .Values.imageCredentials.registry .Values.imageCredentials.username .Values.imageCredentials.password .Values.imageCredentials.email (printf "%s:%s" .Values.imageCredentials.username .Values.imageCredentials.password | b64enc) | b64enc }}
{{- end }}

{{- define "enterprise.licenseSecret" -}}
{{- if .Values.useExistingLicenseSecret }}
{{- with .Values.licenseSecretName }}
secretName: {{ . }}
{{- end }}
{{- else }}
secretName: {{ template "enterprise.fullname" . }}-license
{{- end }}
{{- end -}}


{{/*
Takes in a map of drivers and checks if the driver is enabled. If not, update the map to sets the notify flag to true
*/}}
{{- define "checkDriverEnabled" -}}
  {{- $drivers := .drivers -}}
  {{- $driverName := .driverName -}}
  {{- $driver := index $drivers $driverName -}}
  {{- if $driver }}
    {{- $driverEnabled := index $driver "enabled" -}}
    {{- if not $driverEnabled }}
      {{- $notify := .notify -}}
      {{- $_ := set . "notify" true -}}
    {{- end }}
  {{- end }}
{{- end }}

{{/*
Checks if the feeds chart was previously disabled or if any of the drivers were disabled. If so and required values aren't set, fail the upgrade.
*/}}
{{- define "enterprise.exclusionCheck" -}}

{{ $notify := false }}

{{/* checks if theres a feeds key, and if so, require values if feeds.chartEnabled is false or feeds.extraEnvs contain ANCHORE_FEEDS_DRIVER or drivers are disabled via values */}}
{{ $feeds := index .Values "feeds" }}
{{- if $feeds -}}
  {{ $feedsChartEnabled := index .Values "feeds" "chartEnabled" }}
  {{- if (not $feedsChartEnabled) -}}
    {{ $notify = true }}
  {{- end -}}

  {{- if not $notify -}}
    {{ $feedsExtraEnvs := index .Values "feeds" "extraEnv" }}
    {{- if $feedsExtraEnvs -}}
      {{- range $index, $val := $feedsExtraEnvs -}}
        {{- if contains "ANCHORE_FEEDS_DRIVER" .name -}}
          {{ $notify = true }}
        {{- end -}}
      {{- end -}}
    {{- end -}}
  {{- end -}}

  {{- if not $notify -}}
    {{- $anchoreConfig := index $feeds "anchoreConfig" }}
    {{- if $anchoreConfig }}
      {{- $anchoreFeeds := index $anchoreConfig "feeds" }}
      {{- if $anchoreFeeds }}
        {{- $drivers := index $anchoreFeeds "drivers" }}
        {{/* calling function to check if driver is enabled, if driver is disabled, set notify to true if its not already true */}}
        {{- if $drivers }}
          {{- $context := dict "drivers" $drivers "notify" $notify "driverName" "gem" }}
          {{- include "checkDriverEnabled" $context }}
          {{- $notify = $context.notify }}

          {{- $context := dict "drivers" $drivers "notify" $notify "driverName" "github" }}
          {{- include "checkDriverEnabled" $context }}
          {{- $notify = $context.notify }}

          {{- $context := dict "drivers" $drivers "notify" $notify "driverName" "msrc" }}
          {{- include "checkDriverEnabled" $context }}
          {{- $notify = $context.notify }}

          {{- $context := dict "drivers" $drivers "notify" $notify "driverName" "npm" }}
          {{- include "checkDriverEnabled" $context }}
          {{- $notify = $context.notify }}
        {{- end -}}
      {{- end -}}
    {{- end -}}
  {{- end -}}
{{- end -}}

{{/* if we haven't needed a notification yet, check if top level extraEnvs have ANCHORE_FEEDS_DRIVER */}}
{{- if not $notify -}}
  {{- range $index, $val := .Values.extraEnv -}}
    {{- if contains "ANCHORE_FEEDS_DRIVER" .name -}}
      {{ $notify = true }}
    {{- end -}}
  {{- end -}}
{{- end -}}

{{ if $notify }}
    {{- $exclude_providers := required "anchoreConfig.policy_engine.vulnerabilities.matching.exclude.providers is required" .Values.anchoreConfig.policy_engine.vulnerabilities.matching.exclude.providers -}}
    {{- $exclude_package := required "anchoreConfig.policy_engine.vulnerabilities.matching.exclude.package_types is required" .Values.anchoreConfig.policy_engine.vulnerabilities.matching.exclude.package_types -}}
{{- end -}}

{{- end -}}

{{/*
Conditionally set replica count based on component autoscaling configuration
Usage: {{- include "enterprise.replicaCount" (merge (dict "component" $component) .) }}
If autoscaling is enabled for the component, don't set replicas (let HPA manage it)
Otherwise, set it to the component's replicaCount value
*/}}
{{- define "enterprise.replicaCount" -}}
{{- $component := .component -}}
{{- $componentValues := index .Values $component -}}
{{- if and $componentValues (hasKey $componentValues "autoscaling") $componentValues.autoscaling.enabled -}}
  {{- /* Autoscaling is enabled - don't set replicas */ -}}
{{- else -}}
  {{- /* Autoscaling is disabled - set replicas */ -}}
replicas: {{ $componentValues.replicaCount }}
{{- end -}}
{{- end -}}

{{/*
helper to error out if prometheus adapter is enabled but url is not set
Usage: {{- include "enterprise.prometheusAdapterCheck" . }}
*/}}

{{- define "enterprise.prometheusAdapterCheck" -}}
{{- if index .Values "prometheus-adapter" "enabled" }}
  {{- if or (not (index .Values "prometheus-adapter" "prometheus")) (not (index .Values "prometheus-adapter" "prometheus" "url")) (eq (index .Values "prometheus-adapter" "prometheus" "url") "") }}
    {{- fail "prometheus-adapter is enabled but prometheus.url is not set. Please set prometheus.url to the Prometheus server that is collecting Anchore metrics." -}}
  {{- end -}}
{{- end -}}
{{- end -}}