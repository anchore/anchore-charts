{{/*
Create database hostname string from supplied values file. Used for setting the ANCHORE_DB_HOST env var in the UI & Engine secret.
*/}}
{{- define "enterprise.dbHostname" }}
  {{- if and (index .Values "postgresql" "externalEndpoint") (not (index .Values "postgresql" "enabled")) }}
    {{- print ( index .Values "postgresql" "externalEndpoint" ) }}
  {{- else if and (index .Values "cloudsql" "enabled") (not (index .Values "postgresql" "enabled")) }}
    {{- print "localhost" }}
  {{- else }}
    {{- $db_host := include "postgres.fullname" . }}
    {{- printf "%s" $db_host -}}
  {{- end }}
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