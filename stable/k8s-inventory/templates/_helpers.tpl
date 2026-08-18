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
Returns the global image registry host override, or an empty string when it isn't set.
*/}}
{{- define "k8sInventory.globalImageRegistryHost" -}}
{{- $global := default dict .Values.global -}}
{{- default "" $global.imageRegistryHost | trimSuffix "/" -}}
{{- end }}

{{/*
Strips the registry host from a string image reference, returning everything after it.
The leading path segment is treated as a registry host when it contains a '.' or a ':', or when it
is 'localhost' - the same rule the docker/OCI reference parsers use. References that don't include a
registry host (eg. 'anchore/k8s-inventory') are returned unchanged.
*/}}
{{- define "k8sInventory.imageWithoutRegistryHost" -}}
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
The image used by the K8s Inventory deployment, with its registry host replaced by
global.imageRegistryHost when that is set.
*/}}
{{- define "k8sInventory.image" -}}
{{- $ref := printf "%s:%s" .Values.image.repository (default .Chart.AppVersion .Values.image.tag) -}}
{{- $globalHost := include "k8sInventory.globalImageRegistryHost" . -}}
{{- if $globalHost -}}
{{- printf "%s/%s" $globalHost (include "k8sInventory.imageWithoutRegistryHost" $ref) -}}
{{- else -}}
{{- $ref -}}
{{- end -}}
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
