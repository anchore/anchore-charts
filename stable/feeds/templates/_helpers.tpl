{{/*
Create feeds database hostname string from supplied values file. Used for setting the ANCHORE_FEEDS_DB_HOST env var in the Feeds secret.
*/}}
{{- define "feeds.dbHostname" -}}
{{- if and (index .Values "feeds-db" "externalEndpoint") (not (index .Values "feeds-db" "enabled")) }}
  {{- print ( index .Values "feeds-db" "externalEndpoint" ) }}
{{- else if and (index .Values "cloudsql" "enabled") (not (index .Values "feeds-db" "enabled")) }}
  {{- print "localhost" }}
{{- else }}
  {{- $db_host := include "feeds-db.fullname" . }}
  {{- printf "%s" $db_host }}
{{- end }}
{{- end -}}

{{/*
Allows sourcing of a specified file in the entrypoint of all containers when .Values.doSourceAtEntry.enabled = true
*/}}
{{- define "feeds.doSourceFile" -}}
{{- if .Values.doSourceAtEntry.enabled }}
  {{- range $index, $file := .Values.doSourceAtEntry.filePaths }}
      {{- printf "if [ -f %v ];then source %v;fi;" $file $file }}
  {{- end }}
{{- end }}
{{- end -}}

{{/*
Return the proper protocol when internal SSL is enabled
*/}}
{{- define "feeds.setProtocol" -}}
{{- if .Values.anchoreConfig.internalServicesSSL.enabled }}
  {{- print "https" }}
{{- else }}
  {{- print "http" }}
{{- end }}
{{- end -}}

{{/*
Return a URL for the external feeds service
*/}}
{{- define "feeds.setGrypeProviderURL" -}}
{{- $grypeProviderFeedsExternalURL := "" }}
{{- $regexSearchPattern := (printf "/v2.*$" | toString) }}
{{- if .Values.url }}
  {{- $urlPathSuffix := (default "" (regexFind $regexSearchPattern .Values.url) ) }}
  {{- $anchoreFeedsHost := (trimSuffix $urlPathSuffix .Values.url) }}
  {{- $grypeProviderFeedsExternalURL = (printf "%s/v2/" $anchoreFeedsHost) }}
{{- else }}
    {{- $grypeProviderFeedsExternalURL = (printf "%s://%s:%s/v2/" (include "feeds.setProtocol" .) (include "feeds.fullname" .) (.Values.service.port | toString)) -}}
{{- end }}
{{- print $grypeProviderFeedsExternalURL }}
{{- end -}}

{{/*
Checks if the appVersion.minor has increased, which is indicitive of requiring a db upgrade/service scaling down
*/}}
{{- define "feeds.appVersionChanged" -}}

{{- $configMapName := include "feeds.fullname" . -}}
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