{{/*
Common annotations
When calling this template, .component can be included in the context for component specific annotations
{{- include "enterprise.common.annotations" (merge (dict "component" $component) .) }}
*/}}
{{- define "enterprise.common.annotations" -}}
{{- $component := .component -}}
{{- if and (not .nil) (not .Values.annotations) (not (index .Values (print $component)).annotations) }}
  {{- print "{}" }}
{{- else }}
  {{- with .Values.annotations }}
{{ toYaml . }}
  {{- end }}
  {{- if $component }}
    {{- with (index .Values (print $component)).annotations }}
{{ toYaml . }}
    {{- end }}
  {{- end }}
{{- end }}
{{- end -}}

{{/*
Service annotations
{{- include "enterprise.service.annotations" (merge (dict "component" $component) .) }}
*/}}
{{- define "enterprise.service.annotations" -}}
{{- $component := .component -}}
{{- if and (not .nil) (not .Values.annotations) (not (index .Values (print $component)).service.annotations) }}
  {{- print "{}" }}
{{- else }}
  {{- with .Values.annotations -}}
{{ toYaml . }}
  {{- end }}
  {{- if $component }}
    {{- with (index .Values (print $component)).service.annotations }}
{{ toYaml . }}
    {{- end }}
  {{- end }}
{{- end }}
{{- end -}}

{{/*
Setup a container for the cloudsql proxy to run in all pods when .Values.cloudsql.enabled = true and .Values.cloudsql.useSideCar false
*/}}
{{- define "enterprise.common.cloudsqlContainer" -}}
{{- if and (.Values.cloudsql.enabled) (not .Values.cloudsql.useSideCar) -}}
- name: cloudsql-proxy
  image: {{ include "enterprise.renderImage" (dict "image" .Values.cloudsql.image "context" .) | trim }}
  imagePullPolicy: {{ .Values.cloudsql.imagePullPolicy }}
{{- with .Values.containerSecurityContext }}
  securityContext:
    {{ toYaml . | nindent 4 }}
{{- end }}
  command: ["/cloud_sql_proxy"]
  args:
    - "-instances={{ .Values.cloudsql.instance }}=tcp:5432"
  {{- if .Values.cloudsql.extraArgs }}
    {{- range $arg := .Values.cloudsql.extraArgs }}
    - {{ quote $arg }}
    {{- end }}
  {{- end }}
  {{- if .Values.cloudsql.useExistingServiceAcc }}
    - "-credential_file=/var/{{ .Values.cloudsql.serviceAccSecretName }}/{{ .Values.cloudsql.serviceAccJsonName }}"
  volumeMounts:
    - mountPath: "/var/{{ .Values.cloudsql.serviceAccSecretName }}"
      name: {{ .Values.cloudsql.serviceAccSecretName }}
      readOnly: true
{{- end }}
{{- end }}
{{- end -}}


{{/*
Setup a sidecar container for the cloudsql proxy to run in all pods when .Values.cloudsql.enabled = true and .Values.cloudsql.useSideCar
*/}}
{{- define "enterprise.common.cloudsqlInitContainer" -}}
{{- if and (.Values.cloudsql.enabled) (.Values.cloudsql.useSideCar) -}}
- name: cloudsql-proxy
  image: {{ include "enterprise.renderImage" (dict "image" .Values.cloudsql.image "context" .) | trim }}
  imagePullPolicy: {{ .Values.cloudsql.imagePullPolicy }}
  restartPolicy: Always
  ports:
    - name: cloudsql-proxy
      containerPort: 8090
      protocol: TCP
{{- with .Values.containerSecurityContext }}
  securityContext:
    {{ toYaml . | nindent 4 }}
{{- end }}
  command: ["/cloud_sql_proxy"]
  args:
    - "-instances={{ .Values.cloudsql.instance }}=tcp:5432"
    - "-use_http_health_check"
  {{- if .Values.cloudsql.extraArgs }}
    {{- range $arg := .Values.cloudsql.extraArgs }}
    - {{ quote $arg }}
    {{- end }}
  {{- end }}
  {{- if .Values.cloudsql.useExistingServiceAcc }}
    - "-credential_file=/var/{{ .Values.cloudsql.serviceAccSecretName }}/{{ .Values.cloudsql.serviceAccJsonName }}"
  volumeMounts:
    - mountPath: "/var/{{ .Values.cloudsql.serviceAccSecretName }}"
      name: {{ .Values.cloudsql.serviceAccSecretName }}
      readOnly: true
  livenessProbe:
    httpGet:
      path: /liveness
      port: cloudsql-proxy
      scheme: HTTP
    initialDelaySeconds: {{ .Values.probes.liveness.initialDelaySeconds }}
    timeoutSeconds: {{ .Values.probes.liveness.timeoutSeconds }}
    periodSeconds: {{ .Values.probes.liveness.periodSeconds }}
    failureThreshold: {{ .Values.probes.liveness.failureThreshold }}
    successThreshold: {{ .Values.probes.liveness.successThreshold }}
  startupProbe:
    httpGet:
      path: /startup
      port: cloudsql-proxy
      scheme: HTTP
    timeoutSeconds: {{ .Values.probes.readiness.timeoutSeconds }}
    periodSeconds: {{ .Values.probes.readiness.periodSeconds }}
    failureThreshold: {{ .Values.probes.readiness.failureThreshold }}
    successThreshold: {{ .Values.probes.readiness.successThreshold }}
{{- end }}
{{- end }}
{{- end -}}

{{/*
Setup the common docker-entrypoint command for all Anchore Enterprise containers
*/}}
{{- define "enterprise.common.dockerEntrypoint" -}}
{{ print (include "enterprise.doSourceFile" .) }} /docker-entrypoint.sh anchore-enterprise-manager service start --no-auto-upgrade
{{- end -}}


{{/*
Setup the common envFrom configs
*/}}
{{- define "enterprise.common.envFrom" -}}
{{- if and .hook .Values.injectSecretsViaEnv -}}
{{/* For hooks the configMapRef is skipped, and secretRefs are skipped whenever
     secrets are injected via env. That leaves nothing to emit, so output an
     explicit empty list to keep call sites' `envFrom:` a valid list rather than
     rendering `envFrom: null`. */}}
[]
{{- else -}}
{{- if not .hook }}
- configMapRef:
    name: {{ .Release.Name }}-enterprise-config-env-vars
{{- end }}
{{- if not .Values.injectSecretsViaEnv }}
  {{- if .Values.useExistingSecrets }}
- secretRef:
    name: {{ .Values.existingSecretName }}
  {{- else if .hook }}
- secretRef:
    name: {{ template "enterprise.hooks.fullname" . }}
  {{- else }}
- secretRef:
    name: {{ template "enterprise.fullname" . }}
  {{- end }}
{{- end }}
{{- end -}}
{{- end -}}


{{/*
Common environment variables
When calling this template, .component can be included in the context for component specific env vars
{{- include "enterprise.common.environment" (merge (dict "component" $component) .) }}
*/}}
{{- define "enterprise.common.environment" -}}
{{- $component := .component -}}
{{- with .Values.extraEnv }}
{{ toYaml . }}
{{- end }}
{{- if $component }}
  {{- with (index .Values (print $component)).extraEnv }}
{{ toYaml . }}
  {{- end }}

# check if the domainSuffix is set on the service level of the component, if it is, use that, else use the global domainSuffix
{{- $serviceName := include (printf "enterprise.%s.fullname" $component) . }}
{{- $domainSuffix := .Values.domainSuffix }}

{{- with (index .Values (print $component)).service }}
{{- if .domainSuffix }}
{{- $domainSuffix = .domainSuffix }}
{{- end }}
{{- end }}

- name: ANCHORE_ENDPOINT_HOSTNAME
  value: {{ $serviceName }}.{{- if $domainSuffix -}}{{ $domainSuffix }}{{- else -}}{{ .Release.Namespace }}.svc.cluster.local{{- end }}

  {{- with (index .Values (print $component)).service }}
- name: ANCHORE_PORT
  value: {{ .port | quote }}
  {{- else }}
- name: ANCHORE_PORT
  value: "null"
  {{- end }}
{{- end }}
- name: ANCHORE_HOST_ID
  valueFrom:
    fieldRef:
      fieldPath: metadata.name
{{- include "enterprise.storageCredentialEnv" (dict "storeConfig" .Values.anchoreConfig.catalog.object_store "envPrefix" "ANCHORE_OBJECT_STORE" "storeName" "object_store" "context" .) }}
{{- include "enterprise.storageCredentialEnv" (dict "storeConfig" .Values.anchoreConfig.catalog.analysis_archive "envPrefix" "ANCHORE_ANALYSIS_ARCHIVE" "storeName" "analysis_archive" "context" .) }}
{{- include "enterprise.dbEncryptionKeyEnv" . }}
{{- end -}}


{{/*
Common extraVolumes
When calling this template, .component can be included in the context for component specific annotations
{{- include "enterprise.common.extraVolumes" (merge (dict "component" $component) .) }}
*/}}
{{- define "enterprise.common.extraVolumes" -}}
{{- $component := .component -}}
{{- with .Values.extraVolumes }}
{{ toYaml . }}
{{- end }}
{{- if $component }}
  {{- with (index .Values (print $component)).extraVolumes }}
{{ toYaml . }}
  {{- end }}
{{- end }}
{{- end -}}


{{/*
Common extraVolumeMounts
When calling this template, .component can be included in the context for component specific annotations
{{- include "enterprise.common.extraVolumes" (merge (dict "component" $component) .) }}
*/}}
{{- define "enterprise.common.extraVolumeMounts" -}}
{{- $component := .component -}}
{{- with .Values.extraVolumeMounts }}
{{ toYaml . }}
{{- end }}
{{- if $component }}
  {{- with (index .Values (print $component)).extraVolumeMounts }}
{{ toYaml . }}
  {{- end }}
{{- end }}
{{- end -}}


{{/*
Setup the common fix permissions init container for all pods using a scratch volume
*/}}
{{- define "enterprise.common.fixPermissionsInitContainer" -}}
- name: mode-fixer
  image: {{ include "enterprise.renderImage" (dict "image" .Values.scratchVolume.fixerInitContainerImage "context" .) | trim }}
  securityContext:
    runAsUser: 0
  volumeMounts:
    - name: "anchore-scratch"
      mountPath: {{ .Values.scratchVolume.mountPath }}
  command:
    - sh
    - -c
    - (chmod 0775 {{ .Values.scratchVolume.mountPath }}; chgrp {{ .Values.securityContext.fsGroup }} {{ .Values.scratchVolume.mountPath }} )
{{- end -}}


{{/*
Common labels
When calling this template, .component can be included in the context for component specific labels
{{- include "enterprise.common.labels" (merge (dict "component" $component) .) }}
*/}}
{{- define "enterprise.common.labels" -}}
{{- $component := .component -}}
{{- if $component }}
  {{- with (index .Values (print $component)).labels }}
{{ toYaml . }}
  {{- end }}
{{- end }}
{{- with .Values.labels }}
{{ toYaml . }}
{{- end }}
app.kubernetes.io/name: {{ template "enterprise.fullname" . }}
  {{- with $component }}
app.kubernetes.io/component: {{ . | lower }}
  {{- end }}
app.kubernetes.io/instance: {{ .Release.Name }}
app.kubernetes.io/version: {{ .Chart.AppVersion }}
app.kubernetes.io/part-of: anchore
app.kubernetes.io/managed-by: {{ .Release.Service }}
helm.sh/chart: {{ printf "%s-%s" .Chart.Name .Chart.Version | replace "+" "_" | trunc 63 | trimSuffix "-" }}
{{- end -}}


{{/*
Setup the common liveness probes for all Anchore Enterprise containers
*/}}
{{- define "enterprise.common.livenessProbe" -}}
{{- $component := .component -}}
httpGet:
  path: /health
  port: {{ $component | lower }}
  scheme: {{ include "enterprise.setProtocol" . | upper }}
initialDelaySeconds: {{ .Values.probes.liveness.initialDelaySeconds }}
timeoutSeconds: {{ .Values.probes.liveness.timeoutSeconds }}
periodSeconds: {{ .Values.probes.liveness.periodSeconds }}
failureThreshold: {{ .Values.probes.liveness.failureThreshold }}
successThreshold: {{ .Values.probes.liveness.successThreshold }}
{{- end -}}


{{/*
Return anchore default selector match labels
When calling this template, .component can be included in the context for component specific env vars
{{- include "enterprise.common.matchLabels" (merge (dict "component" $component) .) }}
*/}}
{{- define "enterprise.common.matchLabels" -}}
{{- $component := .component -}}
app.kubernetes.io/name: {{ template "enterprise.fullname" . }}
app.kubernetes.io/component: {{ $component | lower }}
{{- end -}}

{{/*
Returns the global image registry host override, or an empty string when it isn't set.
*/}}
{{- define "enterprise.globalImageRegistryHost" -}}
{{- $global := default dict .Values.global -}}
{{- default "" $global.imageRegistryHost | trimSuffix "/" -}}
{{- end }}

{{/*
Strips the registry host from a string image reference, returning everything after it.
The leading path segment is treated as a registry host when it contains a '.' or a ':', or when it
is 'localhost' - the same rule the docker/OCI reference parsers use. References that don't include a
registry host (eg. 'alpine', 'bitnamilegacy/kubectl:1.30') are returned unchanged.
*/}}
{{- define "enterprise.imageWithoutRegistryHost" -}}
{{- $ref := trim . -}}
{{- $parts := splitList "/" $ref -}}
{{- $host := first $parts -}}
{{- if and (gt (len $parts) 1) (or (contains "." $host) (contains ":" $host) (eq $host "localhost")) -}}
{{- join "/" (rest $parts) -}}
{{- else -}}
{{- $ref -}}
{{- end -}}
{{- end }}

{{/*
Generic image rendering helper.
Reusable image specification template for Anchore Enterprise
Accepts:
- dict "image" <image value> "context" <root context>
Handles:
- string values
- dicts with tag or digest
- global.imageRegistryHost, which replaces the registry host of either form
- fails if incomplete
*/}}
{{- define "enterprise.renderImage" -}}
{{- $image := .image }}
{{- $globalHost := include "enterprise.globalImageRegistryHost" .context }}
{{- if eq (printf "%T" $image) "string" }}
  {{- if $globalHost }}
  {{ printf "%s/%s" $globalHost (include "enterprise.imageWithoutRegistryHost" $image) | trim }}
  {{- else }}
  {{ $image | trim }}
  {{- end }}
{{- else }}
  {{- if $globalHost }}
    {{- $image = merge (dict "registry" $globalHost) $image }}
  {{- end }}
  {{- if and $image.digest $image.registry $image.repository }}
  {{ printf "%s/%s@%s" $image.registry $image.repository $image.digest | trim }}
  {{- else if and $image.tag $image.registry $image.repository }}
  {{ printf "%s/%s:%s" $image.registry $image.repository $image.tag | trim }}
  {{- else }}
  {{ fail (printf "Invalid image: must include registry, repository, and either tag or digest. Got: %#v" $image) }}
  {{- end }}
{{- end }}
{{- end }}

{{/*
Create an image specification template that can override the default image
based on global settings
*/}}
{{- define "enterprise.common.image" -}}
{{ include "enterprise.renderImage" (dict "image" .Values.image "context" .) }}
{{- end }}

{{/*
Create an image specification template for the UI that can override the default image
based on component-specific or global settings
*/}}
{{- define "enterprise.ui.image" -}}
{{ include "enterprise.renderImage" (dict "image" .Values.ui.image "context" .) }}
{{- end }}


{{/*
Create an image specification template for kubectl
*/}}
{{- define "enterprise.kubectl.image" -}}
  {{ include "enterprise.renderImage" (dict "image" .Values.kubectlImage "context" .) }}
{{- end }}

{{/*
Setup the common pod spec configs
*/}}
{{- define "enterprise.common.podSpec" -}}
{{- $component := .component -}}
{{- with .Values.securityContext }}
securityContext: {{- toYaml . | nindent 2 }}
{{- end }}
{{- if or .Values.createServiceAccount .Values.serviceAccountName (index .Values (print $component)).serviceAccountName (eq $component "upgradeJob") (eq $component "osaaMigrationJob") }}
serviceAccountName: {{ include "enterprise.serviceAccountName" (merge (dict "component" $component) .) }}
{{- end }}
{{- if .Values.useExistingPullCredSecret }}
{{- with .Values.imagePullSecretName }}
imagePullSecrets:
  - name: {{ . }}
{{- end }}
{{- else }}
imagePullSecrets:
  - name: {{ template "enterprise.fullname" . }}-pullcreds
{{- end }}
{{- with (default .Values.nodeSelector (index .Values (print $component)).nodeSelector) }}
nodeSelector: {{- toYaml . | nindent 2 }}
{{- end }}
{{- with (default .Values.affinity (index .Values (print $component)).affinity) }}
affinity: {{- toYaml . | nindent 2 }}
{{- end }}
{{- with (default .Values.topologySpreadConstraints (index .Values (print $component)).topologySpreadConstraints) }}
topologySpreadConstraints: {{- toYaml . | nindent 2 }}
{{- end }}
{{- with (default .Values.tolerations (index .Values (print $component)).tolerations) }}
tolerations: {{- toYaml . | nindent 2 }}
{{- end }}
dnsConfig:
  options:
    - name: ndots
      value: {{ .Values.dnsConfig.ndots | quote }}
{{- end -}}


{{/*
Setup the common readiness probes for all Anchore Enterprise containers
*/}}
{{- define "enterprise.common.readinessProbe" -}}
{{- $component := .component -}}
httpGet:
  path: /health
  port: {{ $component | lower }}
  scheme: {{ include "enterprise.setProtocol" . | upper }}
timeoutSeconds: {{ .Values.probes.readiness.timeoutSeconds }}
periodSeconds: {{ .Values.probes.readiness.periodSeconds }}
failureThreshold: {{ .Values.probes.readiness.failureThreshold }}
successThreshold: {{ .Values.probes.readiness.successThreshold }}
{{- with .Values.probes.readiness.initialDelaySeconds }}
initialDelaySeconds: {{ . }}
{{- end }}
{{- end -}}


{{/*
Setup the common anchore scratch volume details config
*/}}
{{- define "enterprise.common.scratchVolume.details" -}}
{{- $component := .component -}}
{{- if (index .Values (print $component)).scratchVolume.details }}
  {{- toYaml (index .Values (print $component)).scratchVolume.details }}
{{- else if .Values.scratchVolume.details }}
  {{- toYaml .Values.scratchVolume.details }}
{{- else }}
emptyDir: {}
{{- end }}
{{- end -}}


{{/*
Setup the common anchore volume mounts
*/}}
{{- define "enterprise.common.volumeMounts" -}}
{{- $component := .component -}}
{{- include "enterprise.common.extraVolumeMounts" (merge (dict "component" $component) .) }}
- name: anchore-license
  mountPath: /home/anchore/license.yaml
  subPath: license.yaml
{{- $ngComponents := list "componentCatalog" }}
{{- if has $component $ngComponents }}
- name: bootstrap-config-volume
  mountPath: /config/bootstrap_ng.yaml
  subPath: bootstrap_ng.yaml
- name: config-volume
  mountPath: /config/config_ng.yaml
  subPath: config_ng.yaml
{{- else }}
- name: config-volume
  mountPath: /config/config.yaml
  subPath: config.yaml
{{- end }}
- name: anchore-scripts
  mountPath: /scripts
- name: anchore-scratch
  mountPath: {{ .Values.scratchVolume.mountPath }}
{{- include "enterprise.common.writableVolumeMounts" (merge (dict "component" $component) .) }}
{{- if .Values.certStoreSecretName }}
- name: certs
  mountPath: /home/anchore/certs/
  readOnly: true
{{- end }}
{{- end -}}

{{/*
Helper: returns a truthy value if any initContainers (global or component-specific)
are configured for the given component.

Usage:
  {{- if include "enterprise.common.hasInitContainers" (merge (dict "component" $component) .) }}
    ...
  {{- end }}
*/}}
{{- define "enterprise.common.hasInitContainers" -}}
{{- $component := .component -}}

{{- with .Values.initContainers -}}
true
{{- end }}

{{- if $component }}
  {{- with (index .Values (print $component)).initContainers -}}
true
  {{- end }}
{{- end }}

{{- end -}}

{{/*
Render initContainers for a specific component
Usage: {{- include "enterprise.common.initContainers" (merge (dict "component" $component) .) | nindent 8 }}
*/}}
{{- define "enterprise.common.initContainers" -}}
{{- $component := .component -}}

{{/* First add any global initContainers */}}
{{- with .Values.initContainers }}
{{ toYaml . }}
{{- end }}

{{/* Then add component-specific initContainers */}}
{{- if $component }}
  {{- with (index .Values (print $component)).initContainers }}
{{ toYaml . }}
  {{- end }}
{{- end }}
{{- end -}}

{{/*
Setup the common anchore volumes
*/}}
{{- define "enterprise.common.volumes" -}}
{{- $component := .component -}}
{{- include "enterprise.common.extraVolumes" (merge (dict "component" $component) .) }}
- name: anchore-license
  secret:
    {{- include "enterprise.licenseSecret" . | nindent 4 }}
- name: anchore-scripts
  configMap:
    name: {{ .Release.Name }}-enterprise-scripts
    defaultMode: 0755
{{- $ngComponents := list "componentCatalog" }}
{{- if has $component $ngComponents }}
- name: bootstrap-config-volume
  configMap:
    name: {{ template "enterprise.fullname" . }}-{{ $component | lower }}-bootstrap
- name: config-volume
  configMap:
    name: {{ template "enterprise.fullname" . }}-{{ $component | lower }}
{{- else if .Values.osaaMigrationJob.enabled }}
- name: config-volume
  configMap:
    name: {{ template "enterprise.osaaMigrationJob.fullname" . }}
{{- else }}
- name: config-volume
  configMap:
    name: {{ template "enterprise.fullname" . }}
{{- end }}
{{- with .Values.certStoreSecretName }}
- name: certs
  secret:
    secretName: {{ . }}
{{- end }}
{{- if .Values.cloudsql.useExistingServiceAcc }}
- name: {{ .Values.cloudsql.serviceAccSecretName }}
  secret:
    secretName: {{ .Values.cloudsql.serviceAccSecretName }}
{{- end }}
{{- include "enterprise.common.writableVolumes" (merge (dict "component" $component) .) }}
{{- end -}}

{{/*
Deployment Strategy Definition. For preupgrade hooks, use RollingUpdate. For postupgrade hooks, use Recreate.
*/}}
{{- define "enterprise.common.deploymentStrategy" -}}
type: Recreate
{{- end -}}

{{/*
External access configuration for a service.
Renders external_hostname and external_port from the service's anchoreConfig.
external_tls is derived from the root anchoreConfig.server.ssl_enable so it tracks
the chart-wide TLS toggle without per-service duplication.
{{- include "enterprise.anchoreConfig.anchoreService.external" (merge (dict "anchoreService" "apiext") .) }}
*/}}
{{- define "enterprise.anchoreConfig.anchoreService.external" -}}
{{- $anchoreService := .anchoreService -}}
{{- $serviceConfig := index .Values.anchoreConfig (print $anchoreService) -}}
external_hostname: {{ $serviceConfig.external_hostname | toYaml }}
external_port: {{ $serviceConfig.external_port | toYaml }}
external_tls: {{ .Values.anchoreConfig.server.ssl_enable }}
{{- end -}}

{{/*
Cycle timers configuration for a service.
Renders cycle_timers from the service's anchoreConfig.
{{- include "enterprise.anchoreConfig.anchoreService.cycleTimers" (merge (dict "anchoreService" "analyzer") .) }}
*/}}
{{- define "enterprise.anchoreConfig.anchoreService.cycleTimers" -}}
{{- $anchoreService := .anchoreService -}}
{{- $serviceConfig := index .Values.anchoreConfig (print $anchoreService) -}}
cycle_timers: {{- toYaml $serviceConfig.cycle_timers | nindent 2 }}
{{- end -}}

{{/*
Common server blocks — merges component-level overrides on top of anchoreConfig.server.
{{- include "enterprise.anchoreConfig.anchoreService.server" (merge (dict "anchoreService" "policy_engine") .) }}
*/}}
{{- define "enterprise.anchoreConfig.anchoreService.server" -}}
{{- $anchoreService := .anchoreService -}}
{{- $server := deepCopy .Values.anchoreConfig.server -}}
{{- $serviceCfg := index .Values.anchoreConfig (print $anchoreService) -}}
{{- if and $serviceCfg (kindIs "map" $serviceCfg) (hasKey $serviceCfg "server") $serviceCfg.server (kindIs "map" $serviceCfg.server) -}}
  {{/* deepCopy the service block: merge mutates its destination in place, and $serviceCfg.server is a live .Values reference that must not be mutated (it would leak across templates). */}}
  {{- $server = merge (deepCopy $serviceCfg.server) $server -}}
  {{/* merge/mergo skips zero-value sources, so a per-service ssl_enable=false would be clobbered by a truthy root. Set it explicitly, presence-based, to mirror the app's per-service-then-root resolution. */}}
  {{- if hasKey $serviceCfg.server "ssl_enable" -}}
    {{- $_ := set $server "ssl_enable" $serviceCfg.server.ssl_enable -}}
  {{- end -}}
{{- end -}}
{{- toYaml $server | nindent 6 }}
{{- end -}}

{{/*
Return the ng-relevant server config for a service.
Starts with the ng subset of anchoreConfig.server, then merges any component-level overrides on top.
Component overrides can both override existing ng fields and add new ones (e.g. custom timeouts).
Usage: {{- include "enterprise.anchoreConfig.anchoreService.ngServer" (merge (dict "anchoreService" "component_catalog") .) }}
*/}}
{{- define "enterprise.anchoreConfig.anchoreService.ngServer" -}}
{{- $anchoreService := .anchoreService -}}
{{- $server := .Values.anchoreConfig.server -}}
{{- $ngFields := dict "process_worker_count" ($server.process_worker_count) "timeout_keep_alive" ($server.timeout_keep_alive) "ssl_cert" ($server.ssl_cert) "ssl_chain" ($server.ssl_chain) "ssl_enable" ($server.ssl_enable) "ssl_key" ($server.ssl_key) }}
{{- $serviceCfg := index .Values.anchoreConfig (print $anchoreService) -}}
{{- if and $serviceCfg (kindIs "map" $serviceCfg) (hasKey $serviceCfg "server") $serviceCfg.server (kindIs "map" $serviceCfg.server) -}}
  {{/* deepCopy the service block so merge does not mutate the live .Values reference in place. */}}
  {{- $ngFields = merge (deepCopy $serviceCfg.server) $ngFields -}}
  {{/* set ssl_enable explicitly (presence-based) since merge/mergo would drop a per-service false. */}}
  {{- if hasKey $serviceCfg.server "ssl_enable" -}}
    {{- $_ := set $ngFields "ssl_enable" $serviceCfg.server.ssl_enable -}}
  {{- end -}}
{{- end -}}
{{- toYaml $ngFields | nindent 6 }}
{{- end -}}

{{/*
containerSecurityContext helper to include security context if defined. service level context takes precedence over toplevel context.
When calling this template, .component can be included in the context for component specific security context
{{- include "enterprise.common.containerSecurityContext" (merge (dict "component" $component) .) }}
*/}}
{{- define "enterprise.common.containerSecurityContext" -}}
{{- $component := .component -}}
{{- $componentCtx := index .Values (print $component) }}
{{- if $componentCtx.containerSecurityContext }}
  {{- toYaml $componentCtx.containerSecurityContext }}
{{- else if .Values.containerSecurityContext }}
  {{- toYaml .Values.containerSecurityContext }}
{{- end }}
{{- end -}}

{{/*
Return "true" when the effective container security context for the component enables
readOnlyRootFilesystem. Mirrors enterprise.common.containerSecurityContext resolution:
a component-level containerSecurityContext fully replaces the top-level one.
Used to gate the writable emptyDir volumes Anchore requires on a read-only root filesystem.
*/}}
{{- define "enterprise.common.readOnlyRootFilesystem" -}}
{{- $component := .component -}}
{{- $componentCtx := index .Values (print $component) -}}
{{- $ctx := dict -}}
{{- if and $componentCtx $componentCtx.containerSecurityContext -}}
  {{- $ctx = $componentCtx.containerSecurityContext -}}
{{- else if .Values.containerSecurityContext -}}
  {{- $ctx = .Values.containerSecurityContext -}}
{{- end -}}
{{- if $ctx.readOnlyRootFilesystem -}}true{{- end -}}
{{- end -}}

{{/*
Writable emptyDir volumes required when the container root filesystem is read-only.
Anchore writes to these paths at runtime (verified against the running image):
  /var/log/anchore        - logger touches a file here at import time (every service)
  /tmp                    - file-logging base path (/tmp/anchore-logs) and tempfiles
  {{ .Values.anchoreConfig.service_dir }}  - service_dir: host_id.json, default policy
Rendered only when readOnlyRootFilesystem is enabled, so default installs are unchanged.
*/}}
{{- define "enterprise.common.writableVolumes" -}}
{{- if eq (include "enterprise.common.readOnlyRootFilesystem" .) "true" }}
- name: anchore-logs
  emptyDir: {}
- name: anchore-tmp
  emptyDir: {}
- name: anchore-service-dir
  emptyDir: {}
{{- end }}
{{- end -}}

{{/*
Container mounts paired with enterprise.common.writableVolumes. Gated identically.
*/}}
{{- define "enterprise.common.writableVolumeMounts" -}}
{{- if eq (include "enterprise.common.readOnlyRootFilesystem" .) "true" }}
- name: anchore-logs
  mountPath: /var/log/anchore
- name: anchore-tmp
  mountPath: /tmp
- name: anchore-service-dir
  mountPath: {{ .Values.anchoreConfig.service_dir }}
{{- end }}
{{- end -}}

{{/*
Return the logging config for a service — merges component-level overrides on top of anchoreConfig.logging.
Usage: {{ include "enterprise.common.logging" (merge (dict "service" "apiext") .) }}
*/}}
{{- define "enterprise.common.logging" -}}
{{- $service := .service -}}
{{- $logging := deepCopy .Values.anchoreConfig.logging -}}
{{- $serviceCfg := index .Values.anchoreConfig $service -}}
{{- if and $serviceCfg (kindIs "map" $serviceCfg) (hasKey $serviceCfg "logging") $serviceCfg.logging -}}
  {{- $logging = merge $serviceCfg.logging $logging -}}
{{- end -}}
  {{- toYaml $logging -}}
{{- end -}}

{{/*
Return the ng-relevant logging config for a service.
Starts with the ng subset of anchoreConfig.logging, then merges any component-level overrides on top.
Component overrides can both override existing ng fields and add new ones (e.g. log_level).
Usage: {{ include "enterprise.common.ngLogging" (merge (dict "service" "component_catalog") .) }}
*/}}
{{- define "enterprise.common.ngLogging" -}}
{{- $service := .service -}}
{{- $logging := .Values.anchoreConfig.logging -}}
{{- $ngFields := dict "colored_logging" ($logging.colored_logging) "exception_backtrace_logging" ($logging.exception_backtrace_logging) "exception_diagnose_logging" ($logging.exception_diagnose_logging) "file_rotation_rule" ($logging.file_rotation_rule) "file_retention_rule" ($logging.file_retention_rule) "structured_logging" ($logging.structured_logging) -}}
{{- if $service -}}
  {{- $serviceCfg := index .Values.anchoreConfig $service -}}
  {{- if and $serviceCfg (kindIs "map" $serviceCfg) (hasKey $serviceCfg "logging") $serviceCfg.logging -}}
    {{- $ngFields = merge $serviceCfg.logging $ngFields -}}
  {{- end -}}
{{- end -}}
  {{- toYaml $ngFields -}}
{{- end -}}

{{- define "enterprise.common.listenAddress" -}}
{{- $component := .component -}}
{{- $componentCtx := index .Values (print $component) }}
{{- if $componentCtx.service.listenAddress }}
  {{- $componentCtx.service.listenAddress }}
{{- else if .Values.listenAddress }}
  {{- .Values.listenAddress }}
{{- end }}
{{- end -}}

{{/*
Emit hostAliases for a component, merging global and component-specific entries.

Expected values:
  .Values.hostAliases: []                   # global/common entries
  .Values.<component>.hostAliases: []       # per-component entries

Call with:
  {{ include "enterprise.common.hostAliases" (merge (dict "component" $component) .) }}
*/}}
{{- define "enterprise.common.hostAliases" -}}
  {{- $vals := .Values -}}

  {{- /* Determine component name (string) if provided */ -}}
  {{- $comp := "" -}}
  {{- if and (hasKey . "component") (kindIs "string" .component) -}}
    {{- $comp = .component -}}
  {{- end }}

  {{- /* Global/common hostAliases (may be empty) */ -}}
  {{- $global := default (list) $vals.hostAliases -}}

  {{- /* Component-specific hostAliases (may be empty) */ -}}
  {{- $local := list -}}
  {{- if and $comp (hasKey $vals $comp) -}}
    {{- $compVals := index $vals $comp -}}
    {{- $local = default (list) $compVals.hostAliases -}}
  {{- end }}

  {{- /* Global first, then component-specific */ -}}
  {{- $merged := concat $global $local -}}

  {{- if gt (len $merged) 0 }}
hostAliases:
{{ toYaml $merged | nindent 2 }}
  {{- end }}
{{- end }}
