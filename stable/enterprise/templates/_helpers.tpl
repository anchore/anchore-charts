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
Returns the proper URL for the feeds service
*/}}
{{- define "enterprise.feedsURL" }}
{{- $anchoreFeedsURL := "" }}
  {{- if .Values.feeds.url }}
    {{- /* remove everything from the URL after /v2 to get the hostname, then use that to construct the proper URL */}}
    {{- $regexSearchPattern := (printf "/%s.*$" .Values.feeds.service.apiVersion | toString) }}
    {{- $urlPathSuffix := (default "" (regexFind $regexSearchPattern .Values.feeds.url) ) }}
    {{- $anchoreFeedsHost := (trimSuffix $urlPathSuffix .Values.feeds.url) -}}
    {{- $anchoreFeedsURL = (printf "%s/%s/feeds" $anchoreFeedsHost .Values.feeds.service.apiVersion) -}}
  {{- else if .Values.feeds.chartEnabled }}
    {{- $anchoreFeedsURL = (printf "%s://%s:%s/%s/feeds" (include "enterprise.feeds.setProtocol" .) (include "enterprise.feeds.fullname" .) (.Values.feeds.service.port | toString) .Values.feeds.service.apiVersion) -}}
  {{- end }}
    {{- print $anchoreFeedsURL -}}
{{- end -}}


{{/*
Returns the proper URL for the grype provider
*/}}
{{- define "enterprise.grypeProviderURL" }}
{{- $grypeProviderFeedsExternalURL := "" -}}
{{- $regexSearchPattern := (printf "/%s.*$" .Values.feeds.service.apiVersion | toString) }}
  {{- if .Values.feeds.url }}
    {{- /* remove everything from the URL after /v2 to get the hostname, then use that to construct the proper URL */}}
    {{- $urlPathSuffix := (default "" ( regexFind $regexSearchPattern .Values.feeds.url )) -}}
    {{- $anchoreFeedsHost := (trimSuffix $urlPathSuffix .Values.feeds.url) -}}
    {{- $grypeProviderFeedsExternalURL = (printf "%s/%s/databases/grypedb" $anchoreFeedsHost .Values.feeds.service.apiVersion) -}}
  {{- else if .Values.feeds.chartEnabled }}
    {{- $grypeProviderFeedsExternalURL = (printf "%s://%s:%s/%s/databases/grypedb" (include "enterprise.feeds.setProtocol" .) (include "enterprise.feeds.fullname" .) (.Values.feeds.service.port | toString) .Values.feeds.service.apiVersion ) -}}
  {{- end }}

  {{- /* Set the grypeProviderFeedsExternalURL to upstream feeds if still unset or if specifically overridden */}}
  {{- if or (empty $grypeProviderFeedsExternalURL) .Values.anchoreConfig.policy_engine.overrideFeedsToUpstream -}}
    {{- $grypeProviderFeedsExternalURL = "https://toolbox-data.anchore.io/grype/databases/listing.json" -}}
  {{- end }}
    {{- print $grypeProviderFeedsExternalURL -}}
{{- end -}}


{{/*
Set the appropriate kubernetes service account name.
We truncate at 63 chars because some Kubernetes name fields are limited to this (by the DNS naming spec).
*/}}
{{- define "enterprise.serviceAccountName" -}}
{{- $component := .component -}}
{{- with (index .Values (print $component)).serviceAccountName }}
  {{- print . | trunc 63 | trimSuffix "-" -}}
{{- else }}
  {{- if and .Values.upgradeJob.rbacCreate (eq $component "upgradeJob") }}
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
Return the proper protocol when Anchore internal SSL is enabled
*/}}
{{- define "enterprise.feeds.setProtocol" -}}
  {{- if .Values.feeds.anchoreConfig.internalServicesSSL.enabled }}
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
{{- define "service.nodePort" -}}
{{- $component := .component -}}
{{- if (index .Values (print $component)).service.nodePort -}}
nodePort: {{ (index .Values (print $component)).service.nodePort }}
{{- end -}}
{{- end -}}
