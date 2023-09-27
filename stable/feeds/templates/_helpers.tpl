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
{{- $regexSearchPattern := (printf "/%s.*$" .Values.service.apiVersion | toString) }}
{{- if .Values.url }}
  {{- $urlPathSuffix := (default "" (regexFind $regexSearchPattern .Values.url) ) }}
  {{- $anchoreFeedsHost := (trimSuffix $urlPathSuffix .Values.url) }}
  {{- $grypeProviderFeedsExternalURL = (printf "%s/%s/" $anchoreFeedsHost .Values.service.apiVersion) }}
{{- else }}
    {{- $grypeProviderFeedsExternalURL = (printf "%s://%s:%s/%s/" (include "feeds.setProtocol" .) (include "feeds.fullname" .) (.Values.service.port | toString) .Values.service.apiVersion ) -}}
{{- end }}
{{- print $grypeProviderFeedsExternalURL }}
{{- end -}}
