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
{{/* Hook pods with injectSecretsViaEnv provide every env var themselves
     (creds and the config.yaml placeholder defaults alike) via extraEnv,
     so the chart's configMapRef/secretRef are both skipped. Emit an explicit
     empty list so the call site's `envFrom:` stays a valid list. */}}
[]
{{- else -}}
{{/* The env-vars ConfigMap holds only non-secret defaults for ${...} placeholders
     in config.yaml (e.g. ANCHORE_DATA_SYNCER_VENDOR_VEX_*). Hook pods render the
     same config.yaml so they need it too, but the regular release configmap is
     either not present yet (fresh install) or still stale (upgrade — not updated
     until after pre-upgrade hooks). Hook pods therefore mount the hook sibling
     from templates/hooks/hook_envvars_configmap.yaml, which is managed at
     hook-weight 0 so it always reflects the new release. */}}
- configMapRef:
    name: {{ if .hook -}}
      {{ template "enterprise.hooks.fullname" . }}-env-vars
    {{- else -}}
      {{ .Release.Name }}-enterprise-config-env-vars
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
Returns the global image registry host, with any trailing slash removed.
Defaults to docker.io via values.yaml; the default dict guards a values file that sets
`global:` with nothing under it, which would otherwise be a nil dereference.
*/}}
{{- define "enterprise.globalImageRegistryHost" -}}
{{- $global := default dict .Values.global -}}
{{- default "" $global.imageRegistryHost | trimSuffix "/" -}}
{{- end }}

{{/*
Reports whether a string image reference states a registry host of its own.
The leading path segment is a registry host when it contains a '.' or a ':', or when it is
'localhost' - the same rule the docker/OCI reference parsers use, so this always agrees with
what the container runtime does with the same string.
*/}}
{{- define "enterprise.imageStatesRegistry" -}}
{{- $parts := splitList "/" (trim .) -}}
{{- $head := first $parts -}}
{{- if and (gt (len $parts) 1) (or (contains "." $head) (contains ":" $head) (eq $head "localhost")) -}}
true
{{- end -}}
{{- end }}

{{/*
Generic image rendering helper.
Reusable image specification template for Anchore Enterprise
Accepts:
- dict "image" <image value> "context" <root context>
Handles:
- dicts with tag or digest
- string values
- fails if incomplete

An image value that states no registry of its own - a dict without `registry`, or a string
without a registry host - takes one from global.imageRegistryHost. An image value that does
state one keeps it, so a single image can be pointed at a different mirror than the rest.
*/}}
{{- define "enterprise.renderImage" -}}
{{- $image := .image }}
{{- $globalHost := include "enterprise.globalImageRegistryHost" .context }}
{{- if eq (printf "%T" $image) "string" }}
  {{- $ref := trim $image }}
  {{- if or (include "enterprise.imageStatesRegistry" $ref) (not $globalHost) }}
  {{ $ref }}
  {{- else }}
  {{ printf "%s/%s" $globalHost $ref }}
  {{- end }}
{{- else }}
  {{- $registry := trimSuffix "/" (default $globalHost $image.registry) }}
  {{/* tag before digest: the shipped defaults pin a digest, and Helm merges a user's `tag` into
       that default rather than replacing it, so digest-precedence would silently ignore the tag */}}
  {{- if and $image.tag $registry $image.repository }}
  {{ printf "%s/%s:%s" $registry $image.repository $image.tag | trim }}
  {{- else if and $image.digest $registry $image.repository }}
  {{ printf "%s/%s@%s" $registry $image.repository $image.digest | trim }}
  {{- else }}
  {{ fail (printf "Invalid image: must include repository, either tag or digest, and a registry (set it on the image or via global.imageRegistryHost). Got: %#v" $image) }}
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
Render the scale-down init container(s) shared by the upgrade and osaaMigration jobs.

`kubectlImage.shell` selects how the scale-down runs, because kubectl images differ in what
they contain:

  - A shell path (default "/bin/bash") renders one container running the script below.
    "/bin/sh" works equally well - the script is POSIX, deliberately - which covers slim
    images such as alpine/kubectl whose only shell is busybox ash.
  - "" renders three containers, each a bare kubectl invocation with no shell at all, for
    distroless images such as registry.k8s.io/kubectl. Those images contain the kubectl
    binary and nothing else: no bash, no sh, no coreutils. A script of any kind is
    impossible there, so the branching has to become container ordering instead.

The shell-free path is not a free substitution. `kubectl scale` exits non-zero with
"no objects passed to scale" when the selector matches nothing, and has no
--ignore-not-found, so that mode cannot treat an empty result as the normal state the
script treats it as. See the chart README.

Known asymmetry, left alone deliberately: the scripted drain below selects on
app.kubernetes.io/name plus phase=Running and excludes no hook components, so a
smoke-test pod left Running by a concurrent `helm test` is counted as an undrained
service and waited on. The shell-free path excludes those components. This is
pre-existing behaviour, character-identical to every released chart, and reachable only
by running `helm test` and `helm upgrade` against one release at the same time. Changing
the selector here would alter the default upgrade path for every existing customer,
which this change is specifically written not to do. It is worth fixing on its own.
*/}}
{{- define "enterprise.common.scaleDownInitContainers" -}}
{{- $component := .component -}}
{{- $image := include "enterprise.kubectl.image" . | trim -}}
{{- $selector := printf "app.kubernetes.io/name=%s" (include "enterprise.fullname" .) -}}
{{/* The drain step must wait only on Anchore's service pods, never on a hook job's pod.
     Every hook job carries app.kubernetes.io/name=<fullname>, same as the services.

     This list must name EVERY hook component in the chart that produces a pod. As of 4.6.0
     that is four components across five templates: the two upgrade-path jobs above,
     pre_install_job.yaml, anchorectl_smoketest.yaml, and hooks/post-upgrade/upgrade_job.yaml,
     which needs no entry of its own because it reuses $component "upgradeJob". If you add
     another, add it here too, or the shell-free drain will wait on it.

     The last two are excluded for a reason that is easy to miss, because neither is deleted
     when it finishes: pre_install_job.yaml uses hook-delete-policy: before-hook-creation,
     and the smoke-test Pod has no delete policy at all. A *completed* one of either is
     already excluded by the phase filter below, but one left Pending - a failed install that
     could not schedule, or a `helm test` that timed out in ImagePullBackOff - is not, and
     nothing will ever delete it, so the drain would wait out its full --timeout on a pod
     that is not a service.

     Only pods carrying app.kubernetes.io/name=<fullname> matter here. The postgresql and
     ui-redis subcharts label their pods with their own names, so they never match and are
     never drained.

     Listed explicitly and in a fixed order so the rendered selector is stable between the
     jobs. The calling component is appended if it is not already here, so a future hook job
     that includes this helper still excludes its own pod. Lowercased because
     enterprise.common.matchLabels renders the label as `{{ $component | lower }}`. */}}
{{- $hookComponents := list -}}
{{- range list "upgradeJob" "osaaMigrationJob" "preInstallJob" "smokeTest" -}}
{{- $hookComponents = append $hookComponents (lower .) -}}
{{- end -}}
{{- if not (has (lower $component) $hookComponents) -}}
{{- $hookComponents = append $hookComponents (lower $component) -}}
{{- end -}}
{{- $drainSelector := printf "%s,app.kubernetes.io/component notin (%s)" $selector (join "," $hookComponents) -}}
{{/* Only an explicit "" selects shell-free. A missing key keeps the historical /bin/bash,
     and because Helm deletes a null-valued key, `shell: null` also lands here as /bin/bash.

     The kindIs guard is required, not defensive. enterprise.renderImage accepts kubectlImage
     as a plain reference string, the README documents that form as supported, and the v3.13.0
     Bitnami workaround tells customers to write exactly that. hasKey against a string is a
     template error rather than a false result, so without this guard every render fails for
     those values files. A string carries nowhere to put a shell, so it keeps /bin/bash;
     selecting another mode means moving to the dict form. */}}
{{- $shell := "/bin/bash" -}}
{{- if and (kindIs "map" .Values.kubectlImage) (hasKey .Values.kubectlImage "shell") -}}
{{- $shell = default "" .Values.kubectlImage.shell -}}
{{- end -}}
{{- $securityContext := "" -}}
{{- if or .Values.containerSecurityContext (index .Values $component).containerSecurityContext -}}
{{- $securityContext = include "enterprise.common.containerSecurityContext" (merge (dict "component" $component) .) -}}
{{- end -}}
{{- $resources := (index .Values $component).resources -}}
{{- if $shell -}}
- name: scale-down-anchore
  image: {{ $image }}
  command: [{{ $shell | quote }}, "-c"]
  args:
    - |
      set -u
      SELECTOR="{{ $selector }}"

      # List the deployments before scaling them. `kubectl scale` reports both "no
      # deployments exist" and "not allowed to list deployments" as the same
      # `no objects passed to scale` error, so it cannot distinguish a missing RBAC
      # grant from an empty result. An explicit list can: it exits non-zero when the
      # request is denied, and exits 0 with no output when nothing matches.
      # stderr is intentionally left unredirected so any API error lands in the pod log.
      deployments=$(kubectl get deployments -l "${SELECTOR}" --no-headers -o name) && rc=0 || rc=$?
      if [ "${rc}" -ne 0 ]; then
        echo "Unable to list the Anchore deployments (exit ${rc}); refusing to continue, because the services cannot be confirmed to be scaled down." >&2
        echo "The service account this job runs as needs get/list/watch on deployments, patch on deployments/scale, and get/list/watch on pods." >&2
        exit "${rc}"
      fi

      # No deployments matched. This is a normal state, not a failure: the release may
      # have had its deployments deleted and be relying on this upgrade to recreate
      # them. There is nothing running to scale down, so let the upgrade proceed.
      if [ -z "${deployments}" ]; then
        echo "No deployments matched ${SELECTOR}; nothing to scale down."
        exit 0
      fi

      kubectl scale deployments --all --replicas=0 -l "${SELECTOR}" && rc=0 || rc=$?
      if [ "${rc}" -ne 0 ]; then
        echo "Failed to scale the Anchore deployments down (exit ${rc})." >&2
        exit "${rc}"
      fi

      # Wait for the pods to drain. Deliberately unbounded: a large deployment can take
      # a long time to drain, and a job that keeps reporting which pods it is still
      # waiting on is more useful than one that gives up. Failing to *list* the pods is
      # a different condition from pods still running, and exits rather than being
      # counted as zero — that miscount is what previously let the migration and upgrade
      # proceed against services that were never scaled down.
      while true; do
        pods=$(kubectl get pods -l "${SELECTOR}" --field-selector=status.phase=Running --no-headers) && rc=0 || rc=$?
        if [ "${rc}" -ne 0 ]; then
          echo "Unable to list pods (exit ${rc}); cannot confirm the Anchore services are down." >&2
          exit "${rc}"
        fi
        running=$(printf '%s' "${pods}" | grep -c .)
        if [ "${running}" -eq 0 ]; then
          break
        fi
        printf '%s\n' "${pods}" >&2
        echo "waiting for ${running} pod(s) to go down..."
        sleep 5
      done
      echo "All Anchore pods are down."
  {{- if $securityContext }}
  securityContext: {{- $securityContext | nindent 4 }}
  {{- end }}
  {{- with $resources }}
  resources: {{- toYaml . | nindent 4 }}
  {{- end }}
{{- else -}}
{{/*
Shell-free: one kubectl call per container, run in order. Any non-zero exit fails the pod,
which is the only control flow available without a shell.
*/}}
- name: list-deployments
  {{/* Exists to turn an ambiguous failure into a readable one. `kubectl scale` reports "no
       deployments exist" and "not allowed to list deployments" with the same
       `no objects passed to scale` message; an explicit list exits non-zero with the API's
       own Forbidden text when the request is denied, and 0 with no output when nothing
       matches. It proves only that deployments are listable: permission to patch
       deployments/scale, and to list and watch pods, is not checked here and will surface
       in the two containers below. */}}
  image: {{ $image }}
  command: ["kubectl"]
  args: ["get", "deployments", "-l", {{ $selector | quote }}, "--no-headers", "-o", "name"]
  {{- if $securityContext }}
  securityContext: {{- $securityContext | nindent 4 }}
  {{- end }}
  {{- with $resources }}
  resources: {{- toYaml . | nindent 4 }}
  {{- end }}
- name: scale-down-anchore
  image: {{ $image }}
  command: ["kubectl"]
  args: ["scale", "deployments", "--all", "--replicas=0", "-l", {{ $selector | quote }}]
  {{- if $securityContext }}
  securityContext: {{- $securityContext | nindent 4 }}
  {{- end }}
  {{- with $resources }}
  resources: {{- toYaml . | nindent 4 }}
  {{- end }}
- name: wait-for-drain
  {{/* Both exclusions are load-bearing, and each fixes a different hang.

       The label exclusion: this job's own pod carries the same app.kubernetes.io/name label
       as the services it drains, and sits in phase Pending while its init containers run.
       Without it this step waits for itself to be deleted and the upgrade hangs until Helm
       times out.

       The phase exclusion: a release accumulates Succeeded hook pods. The pre-install job
       uses hook-delete-policy before-hook-creation, so its pod is still there, carries the
       release's name label, and is not one of the components excluded above. Waiting for a
       completed pod that nothing will ever delete hangs just as hard.

       What is deliberately NOT filtered is phase Pending. kubectl wait resolves its pod set
       once and then watches those objects, so anything missing from that first list is never
       waited on. Filtering to phase=Running would drop a pod that is still ContainerCreating
       when this starts, and that pod can go on to run out its full termination grace period
       after this step has already returned 0.

       Note that the scripted path does not handle this case either: it counts only Running
       pods and breaks as soon as that count is zero, so a pod still coming up lets it exit
       early too. Verified in a cluster. The two paths are strict about different things -
       this one waits for pods that are still starting but cannot see pods created after it
       begins; the script is the other way round. Neither is a superset of the other.

       A negative --timeout means "wait for a week", the closest this mode gets to the
       scripted path's deliberately unbounded wait. It exits 0 when nothing matches. */}}
  image: {{ $image }}
  command: ["kubectl"]
  args: ["wait", "--for=delete", "pod", "-l", {{ $drainSelector | quote }}, "--field-selector=status.phase!=Succeeded,status.phase!=Failed", "--timeout=-1s"]
  {{- if $securityContext }}
  securityContext: {{- $securityContext | nindent 4 }}
  {{- end }}
  {{- with $resources }}
  resources: {{- toYaml . | nindent 4 }}
  {{- end }}
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
{{/*
Emit serviceAccountName only when one actually resolves. The upgrade and migration jobs used
to emit the key unconditionally, so with rbacCreate=false and no name set anywhere it rendered
`serviceAccountName:` with no value. Kubernetes accepts that (the null decodes to "" and the
ServiceAccount admission plugin substitutes `default`), but omitting the key expresses the same
intent without relying on that normalization.
*/}}
{{- with (include "enterprise.serviceAccountName" (merge (dict "component" $component) .) | trim) }}
serviceAccountName: {{ . }}
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
