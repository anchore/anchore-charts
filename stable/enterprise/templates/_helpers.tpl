{{/*
Allow configOverride per service.
*/}}
{{- define "enterprise.configOverride" -}}
{{- $component := .component -}}

{{- with (index .Values (print $component)).configOverride }}
  {{- print .  -}}
{{- else }}
  {{- if .Values.configOverride }}
    {{- print .Values.configOverride -}}
  {{- end }}
{{- end }}
{{- end -}}

{{/*
Creates the configMap based on component passed in.
*/}}
{{- define "enterprise.configMap" -}}
{{- $component := .component -}}
{{- $configMapName := include "enterprise.fullname" . -}}
{{- include "enterprise.exclusionCheck" . -}}
kind: ConfigMap
apiVersion: v1
metadata:
  name: {{ $configMapName }}-{{ $component | lower }}
  namespace: {{ .Release.Namespace }}
  labels: {{- include "enterprise.common.labels" . | nindent 4 }}
  annotations: {{- include "enterprise.common.annotations" . | nindent 4 }}
data:
  config.yaml: |
    # Anchore {{ $component | title }} Service Configuration File, mounted from a configmap
    #
{{- if (include "enterprise.configOverride" (merge (dict "component" $component) .)) }}
{{ tpl (include "enterprise.configOverride" (merge (dict "component" $component) .)) . | indent 4 }}
{{- else }}
{{ tpl (.Files.Get "files/base_config.yaml") . | indent 4 }}
{{ tpl (.Files.Get (printf "files/%s_config.yaml" ($component | lower))) . | indent 4 }}
{{- end }}
{{- end -}}

{{/*
Consolidated deprecation and validation checks for breaking changes.
*/}}
{{- define "enterprise.deprecationChecks" -}}
{{/* postgresql.chartEnabled was removed when the Bitnami PostgreSQL dependency was dropped */}}
{{- if hasKey .Values.postgresql "chartEnabled" }}
  {{- fail "postgresql.chartEnabled is no longer supported. The Bitnami PostgreSQL dependency has been removed. Please remove postgresql.chartEnabled from your values and configure postgresql.externalEndpoint, postgresql.auth.username, postgresql.auth.password, and postgresql.auth.database (or use existing secrets) to connect to your own PostgreSQL database." }}
{{- end }}
{{/* retrieve_files was renamed to file_contents */}}
{{- if hasKey .Values.anchoreConfig.analyzer.configFile "retrieve_files" }}
  {{- fail "anchoreConfig.analyzer.configFile.retrieve_files is no longer supported. This key has been renamed to `file_contents`. Please update your values file to use `anchoreConfig.analyzer.configFile.file_contents` instead." }}
{{- end }}
{{/* image_ttl_days=-1 is no longer valid */}}
{{- if eq (toString .Values.anchoreConfig.catalog.runtime_inventory.image_ttl_days) "-1" }}
  {{- fail "The value `-1` is no longer valid for `anchoreConfig.catalog.runtime_inventory.image_ttl_days`. Please use `anchoreConfig.catalog.runtime_inventory.inventory_ingest_overwrite=true` to force runtime inventory to be overwritten upon every update for that reported context. `anchoreConfig.catalog.runtime_inventory.inventory_ttl_days` must be set to a value >1." }}
{{- end }}
{{/* internalServicesSSL has been removed — SSL is now configured via the server block at the root or per-service level */}}
{{- if hasKey .Values.anchoreConfig "internalServicesSSL" }}
  {{- fail "anchoreConfig.internalServicesSSL is no longer supported. SSL is now configured via `anchoreConfig.server` (root level) or per-service `anchoreConfig.<service>.server` blocks using `ssl_enable`, `ssl_cert`, `ssl_chain`, and `ssl_key`." }}
{{- end }}
{{/* apiext.external has been replaced by per-service external_hostname, external_port, external_tls */}}
{{- if hasKey .Values.anchoreConfig.apiext "external" }}
  {{- fail "anchoreConfig.apiext.external is no longer supported. Use `anchoreConfig.apiext.external_hostname`, `anchoreConfig.apiext.external_port`, and `anchoreConfig.apiext.external_tls` instead." }}
{{- end }}
{{- end -}}

{{/*
Create database hostname string from supplied values file. Used for setting the ANCHORE_DB_HOST env var in the UI & Engine secret.
*/}}
{{- define "enterprise.dbHostname" }}
  {{- if and (index .Values "cloudsql" "enabled") }}
    {{- print "127.0.0.1" }}
  {{- else }}
    {{- required "postgresql.externalEndpoint is required" .Values.postgresql.externalEndpoint }}
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
  {{- else if .Values.createServiceAccount }}
    {{- printf "%s-%s" (include "enterprise.fullname" .) "sa" -}}
  {{- end }}
{{- end }}
{{- end -}}


{{/*
Return the proper protocol when Anchore SSL is enabled via the root server block
*/}}
{{- define "enterprise.setProtocol" -}}
  {{- if .Values.anchoreConfig.server.ssl_enable }}
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
{{- include "enterprise.deprecationChecks" . }}

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
Returns the value of ANCHORE_POLICY_ENGINE_ENABLE_PACKAGE_DB_LOAD, preserving it from the
previous env var ConfigMap on upgrades. Defaults to false on fresh installs.
*/}}
{{- define "enterprise.policyEngineEnablePackageDBLoad" -}}
{{- $val := false -}}
{{- if .Release.IsUpgrade -}}
  {{- $envvarConfigmap := (lookup "v1" "ConfigMap" .Release.Namespace (printf "%s-enterprise-config-env-vars" .Release.Name)) -}}
  {{- if $envvarConfigmap -}}
    {{- $val = index $envvarConfigmap.data "ANCHORE_POLICY_ENGINE_ENABLE_PACKAGE_DB_LOAD" -}}
  {{- end -}}
{{- end -}}
{{- $val -}}
{{- end -}}

{{/*
Checks if any removed env vars are set via extraEnv (global or component-level).
These env vars have been replaced by direct values file configuration and should no longer be set via extraEnv.
Each entry in the list is a dict with "name" (env var name), "values_path" (replacement values path), and "components" (list of component keys to check).
*/}}
{{- define "enterprise.envVarExtraEnvCheck" -}}
{{- $disallowedEnvVars := list
  (dict "name" "ANCHORE_LAYER_CACHE_ENABLED" "values_path" "anchoreConfig.analyzer.layer_cache_max_gigabytes" "components" (list "analyzer"))
  (dict "name" "ANCHORE_LAYER_CACHE_SIZE_GB" "values_path" "anchoreConfig.analyzer.layer_cache_max_gigabytes" "components" (list "analyzer"))
  (dict "name" "ANCHORE_HINTS_ENABLED" "values_path" "anchoreConfig.analyzer.enable_hints" "components" (list "analyzer"))
  (dict "name" "ANCHORE_OWNED_PACKAGE_FILTERING_ENABLED" "values_path" "anchoreConfig.analyzer.enable_owned_package_filtering" "components" (list "analyzer"))
  (dict "name" "ANCHORE_CATALOG_IMAGE_GC_WORKERS" "values_path" "anchoreConfig.catalog.image_gc.max_worker_threads" "components" (list "catalog"))
  (dict "name" "ANCHORE_ENTERPRISE_RUNTIME_INVENTORY_TTL_DAYS" "values_path" "anchoreConfig.catalog.runtime_inventory.inventory_ttl_days" "components" (list "catalog"))
  (dict "name" "ANCHORE_ENTERPRISE_RUNTIME_INVENTORY_INGEST_OVERWRITE" "values_path" "anchoreConfig.catalog.runtime_inventory.inventory_ingest_overwrite" "components" (list "catalog"))
  (dict "name" "ANCHORE_ENTERPRISE_INTEGRATION_HEALTH_REPORTS_TTL_DAYS" "values_path" "anchoreConfig.catalog.integrations.integration_health_report_ttl_days" "components" (list "catalog"))
  (dict "name" "ANCHORE_IMPORT_OPERATION_EXPIRATION_DAYS" "values_path" "anchoreConfig.catalog.import_operation_expiration_days" "components" (list "catalog"))
  (dict "name" "ANCHORE_POLICY_EVAL_CACHE_TTL_SECONDS" "values_path" "anchoreConfig.policy_engine.policy_evaluation_cache_ttl" "components" (list "policyEngine"))
  (dict "name" "ANCHORE_POLICY_ENGINE_ENABLE_PACKAGE_DB_LOAD" "values_path" "N/A (managed automatically on upgrades)" "components" (list "policyEngine"))
  (dict "name" "ANCHORE_ENTERPRISE_REPORTS_ENABLE_GRAPHIQL" "values_path" "anchoreConfig.reports.enable_graphiql" "components" (list "reports"))
  (dict "name" "ANCHORE_ENTERPRISE_REPORTS_MAX_ASYNC_EXECUTION_THREADS" "values_path" "anchoreConfig.reports.max_async_execution_threads" "components" (list "reports"))
  (dict "name" "ANCHORE_ENTERPRISE_REPORTS_ASYNC_EXECUTION_TIMEOUT" "values_path" "anchoreConfig.reports.async_execution_timeout" "components" (list "reports"))
  (dict "name" "ANCHORE_ENTERPRISE_REPORTS_ENABLE_DATA_INGRESS" "values_path" "anchoreConfig.reports_worker.enable_data_ingress" "components" (list "reportsWorker"))
  (dict "name" "ANCHORE_ENTERPRISE_REPORTS_ENABLE_DATA_EGRESS" "values_path" "anchoreConfig.reports_worker.enable_data_egress" "components" (list "reportsWorker"))
  (dict "name" "ANCHORE_ENTERPRISE_REPORTS_DATA_EGRESS_WINDOW" "values_path" "anchoreConfig.reports_worker.data_egress_window" "components" (list "reportsWorker"))
  (dict "name" "ANCHORE_ENTERPRISE_REPORTS_DATA_REFRESH_MAX_WORKERS" "values_path" "anchoreConfig.reports_worker.data_refresh_max_workers" "components" (list "reportsWorker"))
  (dict "name" "ANCHORE_ENTERPRISE_REPORTS_DATA_LOAD_MAX_WORKERS" "values_path" "anchoreConfig.reports_worker.data_load_max_workers" "components" (list "reportsWorker"))
  (dict "name" "ANCHORE_ENTERPRISE_UI_URL" "values_path" "anchoreConfig.notifications.ui_url" "components" (list "notifications"))
  (dict "name" "ANCHORE_DATA_SYNC_AUTO_SYNC_ENABLED" "values_path" "anchoreConfig.data_syncer.auto_sync_enabled" "components" (list "dataSyncer"))
  (dict "name" "ANCHORE_ADMIN_EMAIL" "values_path" "anchoreConfig.default_admin_email" "components" (list))
  (dict "name" "ANCHORE_API_DRIVEN_CONFIGURATION_ENABLED" "values_path" "anchoreConfig.api_driven_configuration_enabled" "components" (list))
  (dict "name" "ANCHORE_ALLOW_ECR_IAM_AUTO" "values_path" "anchoreConfig.allow_awsecr_iam_auto" "components" (list))
  (dict "name" "ANCHORE_AUTH_PRIVKEY" "values_path" "anchoreConfig.keys.publicKeyFileName" "components" (list))
  (dict "name" "ANCHORE_AUTH_PUBKEY" "values_path" "anchoreConfig.keys.privateKeyFileName" "components" (list))
  (dict "name" "ANCHORE_DISABLE_METRICS_AUTH" "values_path" "anchoreConfig.metrics.auth_disabled" "components" (list))
  (dict "name" "ANCHORE_DB_SSL" "values_path" "anchoreConfig.database.ssl" "components" (list))
  (dict "name" "ANCHORE_DB_SSL_MODE" "values_path" "anchoreConfig.database.sslMode" "components" (list))
  (dict "name" "ANCHORE_DB_SSL_ROOT_CERT" "values_path" "anchoreConfig.database.sslRootCertFileName" "components" (list))
  (dict "name" "ANCHORE_ENABLE_METRICS" "values_path" "anchoreConfig.metrics.enabled" "components" (list))
  (dict "name" "ANCHORE_MAX_COMPRESSED_IMAGE_SIZE_MB" "values_path" "anchoreConfig.max_compressed_image_size_mb" "components" (list))
  (dict "name" "ANCHORE_MAX_IMPORT_CONTENT_SIZE_MB" "values_path" "anchoreConfig.max_import_content_size_mb" "components" (list))
  (dict "name" "ANCHORE_MAX_IMPORT_SOURCE_SIZE_MB" "values_path" "anchoreConfig.max_source_import_size_mb" "components" (list))
  (dict "name" "ANCHORE_OAUTH_TOKEN_EXPIRATION" "values_path" "anchoreConfig.user_authentication.oauth.default_token_expiration_seconds" "components" (list))
  (dict "name" "ANCHORE_OAUTH_REFRESH_TOKEN_EXPIRATION" "values_path" "anchoreConfig.user_authentication.oauth.refresh_token_expiration_seconds" "components" (list))
  (dict "name" "ANCHORE_SSO_REQUIRES_EXISTING_USERS" "values_path" "anchoreConfig.user_authentication.sso_require_existing_users" "components" (list))
  (dict "name" "ANCHORE_IMAGE_ANALYZE_TIMEOUT_SECONDS" "values_path" "anchoreConfig.image_analyze_timeout_seconds" "components" (list))
-}}
{{- range $disallowed := $disallowedEnvVars }}
  {{- range $envEntry := $.Values.extraEnv }}
    {{- if eq $envEntry.name $disallowed.name }}
      {{- fail (printf "The environment variable '%s' is no longer supported via extraEnv. Please remove it from extraEnv and set it directly via the values file at '%s'." $disallowed.name $disallowed.values_path) }}
    {{- end }}
  {{- end }}
  {{- range $comp := $disallowed.components }}
    {{- $compValues := index $.Values $comp }}
    {{- if $compValues }}
      {{- if $compValues.extraEnv }}
        {{- range $envEntry := $compValues.extraEnv }}
          {{- if eq $envEntry.name $disallowed.name }}
            {{- fail (printf "The environment variable '%s' is no longer supported via %s.extraEnv. Please remove it and set it directly via the values file at '%s'." $disallowed.name $comp $disallowed.values_path) }}
          {{- end }}
        {{- end }}
      {{- end }}
    {{- end }}
  {{- end }}
{{- end }}
{{- end -}}

{{/*
Ensuring use_proxy cannot be enabled without enable_ssl
*/}}
{{- define "enterprise.useProxyCheck" -}}
{{- if .Values.anchoreConfig.ui.enable_proxy }}
    {{- if not .Values.anchoreConfig.ui.enable_ssl -}}
        {{ fail (printf "Cannot enable use_proxy without enabling enable_ssl") }}
    {{- end }}
{{- end }}
{{- end }}

{{/*
Adds extendedConfig for a given service. Appends arbitrary user-supplied YAML to the service config block. Should only be used by recommendation of Anchore Support.
NOTE: nindent is intentionally inside the helper (not at the call site) because piping an empty result through nindent
produces trailing whitespace, which causes YAML to render config.yaml as a quoted string instead of a block scalar.
Usage: {{- include "enterprise.serviceExtendedConfig" (merge (dict "serviceName" "catalog") .) }}
*/}}
{{- define "enterprise.serviceExtendedConfig" -}}
{{- $extendedConfig := (index .Values.anchoreConfig (print .serviceName)).extendedConfig -}}
{{- if $extendedConfig }}
{{- toYaml $extendedConfig | nindent 4 }}
{{- end -}}
{{- end -}}

{{/*
Determine the secret name for a storage driver's credentials.
Returns the existingCredentialSecret if set, or the auto-generated osaa-creds name if access_key/secret_key are in config.
Usage: {{ include "enterprise.storageCredentialSecretName" (dict "storeConfig" .Values.anchoreConfig.catalog.object_store "storeName" "object_store" "context" .) }}
*/}}
{{- define "enterprise.storageCredentialSecretName" -}}
{{- $storeConfig := .storeConfig -}}
{{- if $storeConfig -}}
  {{- $sd := index $storeConfig "storage_driver" -}}
  {{- if $sd -}}
    {{- $sdConfig := index $sd "config" -}}
    {{- if $sdConfig -}}
      {{- if index $sdConfig "existingCredentialSecret" -}}
        {{- index $sdConfig "existingCredentialSecret" -}}
      {{- else if and (index $sdConfig "access_key") (index $sdConfig "secret_key") -}}
        {{- printf "%s-osaa-creds" (include "enterprise.fullname" .context) -}}
      {{- end -}}
    {{- end -}}
  {{- end -}}
{{- end -}}
{{- end -}}

{{/*
Determine the secret name for an OSAA migration storage driver's credentials.
Returns the existingCredentialSecret if set, or the auto-generated osaa-migration-creds name if access_key/secret_key are in config.
Usage: {{ include "enterprise.migrationStorageCredentialSecretName" (dict "storeConfig" .Values.osaaMigrationJob.objectStoreMigration.object_store "storeName" "object_store" "context" .) }}
*/}}
{{- define "enterprise.migrationStorageCredentialSecretName" -}}
{{- $storeConfig := .storeConfig -}}
{{- if $storeConfig -}}
  {{- $sd := index $storeConfig "storage_driver" -}}
  {{- if $sd -}}
    {{- $sdConfig := index $sd "config" -}}
    {{- if $sdConfig -}}
      {{- if index $sdConfig "existingCredentialSecret" -}}
        {{- index $sdConfig "existingCredentialSecret" -}}
      {{- else if and (index $sdConfig "access_key") (index $sdConfig "secret_key") -}}
        {{- printf "%s-osaa-migration-creds" (include "enterprise.fullname" .context) -}}
      {{- end -}}
    {{- end -}}
  {{- end -}}
{{- end -}}
{{- end -}}

{{/*
Render env vars sourced from a secret for an OSAA migration storage driver.
Uses the same env var names (ANCHORE_OBJECT_STORE_ACCESS_KEY, etc.) so that the
osaa configmap's ${ANCHORE_*} placeholders resolve correctly in the migration pod.
Usage: {{ include "enterprise.migrationStorageCredentialEnv" (dict "storeConfig" .Values.osaaMigrationJob.objectStoreMigration.object_store "envPrefix" "ANCHORE_OBJECT_STORE" "storeName" "object_store" "context" .) }}
*/}}
{{- define "enterprise.migrationStorageCredentialEnv" -}}
{{- $secretName := include "enterprise.migrationStorageCredentialSecretName" . -}}
{{- $envPrefix := .envPrefix -}}
{{- $storeName := .storeName -}}
{{- if $secretName }}
{{- $sdConfig := index .storeConfig "storage_driver" "config" -}}
{{- $isExisting := index $sdConfig "existingCredentialSecret" -}}
{{- $accessKeyField := ternary (index $sdConfig "accessKeySecretKey" | default "access_key") (printf "%s_access_key" $storeName) (not (empty $isExisting)) -}}
{{- $secretKeyField := ternary (index $sdConfig "secretKeySecretKey" | default "secret_key") (printf "%s_secret_key" $storeName) (not (empty $isExisting)) }}
- name: {{ $envPrefix }}_ACCESS_KEY
  valueFrom:
    secretKeyRef:
      name: {{ $secretName }}
      key: {{ $accessKeyField }}
- name: {{ $envPrefix }}_SECRET_KEY
  valueFrom:
    secretKeyRef:
      name: {{ $secretName }}
      key: {{ $secretKeyField }}
{{- end -}}
{{- end -}}

{{/*
Render a storage config block (object_store or analysis_archive), replacing access_key/secret_key
with env var placeholders when credentials will be sourced from a secret (either existing or auto-created).
Usage: {{ include "enterprise.storageConfig" (dict "storeConfig" .Values.anchoreConfig.catalog.object_store "envPrefix" "ANCHORE_OBJECT_STORE" "storeName" "object_store" "context" .) }}
*/}}
{{- define "enterprise.storageConfig" -}}
{{- $storeConfig := .storeConfig -}}
{{- $envPrefix := .envPrefix -}}
{{- $secretName := include "enterprise.storageCredentialSecretName" . -}}
{{- $hasDriverConfig := false -}}
{{- if $storeConfig -}}
  {{- $sd := index $storeConfig "storage_driver" -}}
  {{- if $sd -}}
    {{- if index $sd "config" -}}
      {{- $hasDriverConfig = true -}}
    {{- end -}}
  {{- end -}}
{{- end -}}
{{- if $hasDriverConfig -}}
  {{- $sdConfig := deepCopy (index (index $storeConfig "storage_driver") "config") -}}
  {{- if $secretName -}}
    {{- $_ := set $sdConfig "access_key" (printf "${%s_ACCESS_KEY}" $envPrefix) -}}
    {{- $_ := set $sdConfig "secret_key" (printf "${%s_SECRET_KEY}" $envPrefix) -}}
  {{- end -}}
  {{- $_ := unset $sdConfig "existingCredentialSecret" -}}
  {{- $_ := unset $sdConfig "accessKeySecretKey" -}}
  {{- $_ := unset $sdConfig "secretKeySecretKey" -}}
  {{- $sd := deepCopy (index $storeConfig "storage_driver") -}}
  {{- $_ := set $sd "config" $sdConfig -}}
  {{- $modified := deepCopy $storeConfig -}}
  {{- $_ := set $modified "storage_driver" $sd -}}
  {{- toYaml $modified -}}
{{- else -}}
  {{- toYaml $storeConfig -}}
{{- end -}}
{{- end -}}

{{/*
Render env vars sourced from a secret for a given storage driver (existing or auto-created).
For existing secrets, uses accessKeySecretKey/secretKeySecretKey as the key names (defaults: access_key/secret_key).
For auto-created osaa-creds, uses <storeName>_access_key/<storeName>_secret_key as the key names.
Usage: {{ include "enterprise.storageCredentialEnv" (dict "storeConfig" .Values.anchoreConfig.catalog.object_store "envPrefix" "ANCHORE_OBJECT_STORE" "storeName" "object_store" "context" .) }}
*/}}
{{- define "enterprise.storageCredentialEnv" -}}
{{- $secretName := include "enterprise.storageCredentialSecretName" . -}}
{{- $envPrefix := .envPrefix -}}
{{- $storeName := .storeName -}}
{{- if $secretName }}
{{- $sdConfig := index .storeConfig "storage_driver" "config" -}}
{{- $isExisting := index $sdConfig "existingCredentialSecret" -}}
{{- $accessKeyField := ternary (index $sdConfig "accessKeySecretKey" | default "access_key") (printf "%s_access_key" $storeName) (not (empty $isExisting)) -}}
{{- $secretKeyField := ternary (index $sdConfig "secretKeySecretKey" | default "secret_key") (printf "%s_secret_key" $storeName) (not (empty $isExisting)) }}
- name: {{ $envPrefix }}_ACCESS_KEY
  valueFrom:
    secretKeyRef:
      name: {{ $secretName }}
      key: {{ $accessKeyField }}
- name: {{ $envPrefix }}_SECRET_KEY
  valueFrom:
    secretKeyRef:
      name: {{ $secretName }}
      key: {{ $secretKeyField }}
{{- end -}}
{{- end -}}

{{/*
Get a value from anchoreConfig with component-level override support and deep merge.
Checks anchoreConfig.<configComponent>.<configKey> first, falls back to anchoreConfig.<configKey>.
When both levels define a map for the same key, the maps are deep merged with the component values taking precedence.

Usage:
  {{ include "enterprise.anchoreConfig.get" (merge (dict "configComponent" "component_catalog" "configKey" "log_level") .) }}
  {{ include "enterprise.anchoreConfig.get" (merge (dict "configComponent" "component_catalog" "configKey" "logging") .) }}
*/}}
{{- define "enterprise.anchoreConfig.get" -}}
{{- $component := .configComponent -}}
{{- $key := .configKey -}}
{{- $global := .Values.anchoreConfig -}}
{{- $componentCfg := dict -}}
{{- if hasKey $global $component -}}
  {{- $val := index $global $component -}}
  {{- if not (eq $val nil) -}}
    {{- $componentCfg = $val -}}
  {{- end -}}
{{- end -}}
{{- $hasGlobal := hasKey $global $key -}}
{{- $hasComponent := hasKey $componentCfg $key -}}
{{- if and $hasGlobal $hasComponent -}}
  {{- $gv := index $global $key -}}
  {{- $cv := index $componentCfg $key -}}
  {{- if and (kindIs "map" $gv) (kindIs "map" $cv) -}}
    {{- merge (deepCopy $cv) $gv | toYaml -}}
  {{- else -}}
    {{- $cv | toYaml -}}
  {{- end -}}
{{- else if $hasComponent -}}
  {{- index $componentCfg $key | toYaml -}}
{{- else if $hasGlobal -}}
  {{- index $global $key | toYaml -}}
{{- end -}}
{{- end -}}
