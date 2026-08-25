{{/*
Returns the global image registry host, with any trailing slash removed.
Defaults to docker.io via values.yaml; the default dict guards a values file that sets
`global:` with nothing under it, which would otherwise be a nil dereference.
*/}}
{{- define "k8sInventory.globalImageRegistryHost" -}}
{{- $global := default dict .Values.global -}}
{{- default "" $global.imageRegistryHost | trimSuffix "/" -}}
{{- end }}

{{/*
Reports whether a string image reference states a registry host of its own.
The leading path segment is a registry host when it contains a '.' or a ':', or when it is
'localhost' - the same rule the docker/OCI reference parsers use, so this always agrees with
what the container runtime does with the same string.
*/}}
{{- define "k8sInventory.imageStatesRegistry" -}}
{{- $parts := splitList "/" (trim .) -}}
{{- $head := first $parts -}}
{{- if and (gt (len $parts) 1) (or (contains "." $head) (contains ":" $head) (eq $head "localhost")) -}}
true
{{- end -}}
{{- end }}

{{/*
Generic image rendering helper.
Accepts: dict "image" <image value> "context" <root context>
Handles dicts with tag or digest, and complete reference strings; fails if incomplete.

An image value that states no registry of its own - a dict without `registry`, or a string
without a registry host - takes one from global.imageRegistryHost. An image value that does
state one keeps it, so a single image can be pointed at a different mirror than the rest.
*/}}
{{- define "k8sInventory.renderImage" -}}
{{- $image := .image }}
{{- $globalHost := include "k8sInventory.globalImageRegistryHost" .context }}
{{- if eq (printf "%T" $image) "string" }}
  {{- $ref := trim $image }}
  {{- if or (include "k8sInventory.imageStatesRegistry" $ref) (not $globalHost) }}
  {{ $ref }}
  {{- else }}
  {{ printf "%s/%s" $globalHost $ref }}
  {{- end }}
{{- else }}
  {{- $registry := trimSuffix "/" (default $globalHost $image.registry) }}
  {{- if and $image.digest $registry $image.repository }}
  {{ printf "%s/%s@%s" $registry $image.repository $image.digest | trim }}
  {{- else if and $image.tag $registry $image.repository }}
  {{ printf "%s/%s:%s" $registry $image.repository $image.tag | trim }}
  {{- else }}
  {{ fail (printf "Invalid image: must include repository, either tag or digest, and a registry (set it on the image or via global.imageRegistryHost). Got: %#v" $image) }}
  {{- end }}
{{- end }}
{{- end }}

{{/*
Expand the name of the chart.
*/}}
{{- define "k8sInventory.name" -}}
{{- default .Chart.Name .Values.nameOverride | trunc 63 | trimSuffix "-" }}
{{- end }}

{{/*
Create a default fully qualified app name.
We truncate at 63 chars because some Kubernetes name fields are limited to this (by the DNS naming spec).
If release name contains chart name it will be used as a full name.
*/}}
{{- define "k8sInventory.fullname" -}}
{{- if .Values.fullnameOverride }}
{{- .Values.fullnameOverride | trunc 63 | trimSuffix "-" }}
{{- else }}
{{- $name := default .Chart.Name .Values.nameOverride }}
{{- if contains $name .Release.Name }}
{{- .Release.Name | trunc 63 | trimSuffix "-" }}
{{- else }}
{{- printf "%s-%s" .Release.Name $name | trunc 63 | trimSuffix "-" }}
{{- end }}
{{- end }}
{{- end }}

{{/*
Create chart name and version as used by the chart label.
*/}}
{{- define "k8sInventory.chart" -}}
{{- printf "%s-%s" .Chart.Name .Chart.Version | replace "+" "_" | trunc 63 | trimSuffix "-" }}
{{- end }}

{{/*
Common labels
*/}}
{{- define "k8sInventory.labels" -}}
helm.sh/chart: {{ include "k8sInventory.chart" . }}
{{ include "k8sInventory.selectorLabels" . }}
{{- if .Chart.AppVersion }}
app.kubernetes.io/version: {{ .Chart.AppVersion | quote }}
chart: {{ .Chart.Name }}-{{ .Chart.Version }}
{{- end }}
app.kubernetes.io/managed-by: {{ .Release.Service }}
{{- with .Values.labels }}
{{ toYaml . }}
{{- end }}
app: {{ include "k8sInventory.fullname" . }}
release: {{ .Release.Name }}
heritage: {{ .Release.Service }}
{{- end }}

{{/*
Selector labels
*/}}
{{- define "k8sInventory.selectorLabels" -}}
app.kubernetes.io/name: {{ include "k8sInventory.name" . }}
app.kubernetes.io/instance: {{ .Release.Name }}
{{- end }}

{{/*
Create the name of the service account to use
*/}}
{{- define "k8sInventory.serviceAccountName" -}}
{{- if .Values.serviceAccount.create }}
{{- default (include "k8sInventory.fullname" .) .Values.serviceAccount.name }}
{{- else }}
{{- default "default" .Values.serviceAccount.name }}
{{- end }}
{{- end }}

{{/*
Require Anchore endpoint and Anchore credentials
*/}}
{{- define "checkAnchoreRequisites" }}
{{- if or (not .Values.k8sInventory.anchore.url) (not .Values.k8sInventory.anchore.user) (and (not .Values.useExistingSecret) (not .Values.k8sInventory.anchore.password)) }}
    {{- fail "Anchore endpoint and credentials are required. See the chart README for more instructions on configuring Anchore Requisites." }}
{{- end }}
{{- end }}

{{/*
The image used by the K8s Inventory deployment, defaulting its tag to the chart appVersion.
This chart takes the dict form only - image.pullPolicy lives in the same dict, so a bare
reference string was never a valid value here.
*/}}
{{- define "k8sInventory.image" -}}
{{- $image := merge (dict "tag" (default .Chart.AppVersion .Values.image.tag)) .Values.image -}}
{{- include "k8sInventory.renderImage" (dict "image" $image "context" .) | trim -}}
{{- end }}
