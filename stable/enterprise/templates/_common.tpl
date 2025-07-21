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
  image: {{ .Values.cloudsql.image }}
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
  image: {{ .Values.cloudsql.image }}
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
- configMapRef:
    name: {{ .Release.Name }}-enterprise-config-env-vars
{{- if not .Values.injectSecretsViaEnv }}
  {{- if .Values.useExistingSecrets }}
- secretRef:
    name: {{ .Values.existingSecretName }}
  {{- else }}
- secretRef:
    name: {{ template "enterprise.fullname" . }}
  {{- end }}
{{- end }}
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
  image: {{ .Values.scratchVolume.fixerInitContainerImage }}
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
Generic image rendering helper.
Reusable image specification template for Anchore Enterprise
Accepts:
- dict "image" <image value>
Handles:
- string values
- dicts with tag or digest
- fails if incomplete
*/}}
{{- define "enterprise.renderImage" -}}
{{- $image := .image }}
{{- if eq (printf "%T" $image) "string" }}
  {{ $image | trim }}
{{- else if and $image.digest $image.registry $image.repository }}
  {{ printf "%s/%s@%s" $image.registry $image.repository $image.digest | trim }}
{{- else if and $image.tag $image.registry $image.repository }}
  {{ printf "%s/%s:%s" $image.registry $image.repository $image.tag | trim }}
{{- else }}
  {{ fail (printf "Invalid image: must include registry, repository, and either tag or digest. Got: %#v" $image) }}
{{- end }}
{{- end }}

{{/*
Create an image specification template that can override the default image
based on global settings
*/}}
{{- define "enterprise.common.image" -}}
{{ include "enterprise.renderImage" (dict "image" .Values.image) }}
{{- end }}

{{/*
Create an image specification template for the UI that can override the default image
based on component-specific or global settings
*/}}
{{- define "enterprise.ui.image" -}}
{{ include "enterprise.renderImage" (dict "image" .Values.ui.image) }}
{{- end }}


{{/*
Create an image specification template for kubectl that can override the default image
based on component-specific or global settings
*/}}
{{- define "enterprise.kubectl.image" -}}
{{- $kubectlImage := .Values.kubectlImage }}
{{- $legacyOsaa := .Values.osaaMigrationJob.kubectlImage }}
{{- $legacyUpgrade := .Values.upgradeJob.kubectlImage }}
{{- if $kubectlImage }}
  {{ include "enterprise.renderImage" (dict "image" $kubectlImage) }}
{{- else if and $legacyOsaa (eq (printf "%T" $legacyOsaa) "string") }}
  {{ $legacyOsaa | trim }}
{{- else if and $legacyUpgrade (eq (printf "%T" $legacyUpgrade) "string") }}
  {{ $legacyUpgrade | trim }}
{{- else }}
  {{ fail "No valid kubectlImage found in Values." }}
{{- end }}
{{- end }}

{{/*
Display deprecation warnings if legacy kubectlImage values are set
*/}}
{{- define "enterprise.kubectl.deprecationWarnings" -}}
{{- if .Values.osaaMigrationJob.kubectlImage }}
{{ printf "NOTICE: 'osaaMigrationJob.kubectlImage' is deprecated and will be removed in a future release. Use 'global.kubectlImage' instead." }}
{{- end }}
{{- if .Values.upgradeJob.kubectlImage }}
{{ printf "NOTICE: 'upgradeJob.kubectlImage' is deprecated and will be removed in a future release. Use 'global.kubectlImage' instead." }}
{{- end }}
{{- end }}

{{/*
Setup the common pod spec configs
*/}}
{{- define "enterprise.common.podSpec" -}}
{{- $component := .component -}}
{{- with .Values.securityContext }}
securityContext: {{- toYaml . | nindent 2 }}
{{- end }}
{{- if or .Values.serviceAccountName (index .Values (print $component)).serviceAccountName (eq $component "upgradeJob") (eq $component "osaaMigrationJob") }}
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
- name: config-volume
  mountPath: /config/config.yaml
  subPath: config.yaml
- name: anchore-scripts
  mountPath: /scripts
{{- if .Values.certStoreSecretName }}
- name: certs
  mountPath: /home/anchore/certs/
  readOnly: true
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
{{- if .Values.osaaMigrationJob.enabled }}
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
{{- end -}}

{{/*
Deployment Strategy Definition. For preupgrade hooks, use RollingUpdate. For postupgrade hooks, use Recreate.
*/}}
{{- define "enterprise.common.deploymentStrategy" -}}
type: Recreate
{{- end -}}
