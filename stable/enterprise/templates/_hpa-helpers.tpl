{{/*
Render a HorizontalPodAutoscaler for an Anchore component.

Usage:
  {{- include "enterprise.hpa" (merge (dict "component" "analyzer") .) }}

The component name must match both the key under .Values and the
"enterprise.<component>.fullname" template (eg. "policyEngine").

Renders nothing unless .Values.<component>.autoscaling.enabled is true.
*/}}
{{- define "enterprise.hpa" -}}
{{- $component := .component -}}
{{- $autoscaling := (index .Values $component).autoscaling -}}
{{- if $autoscaling.enabled -}}
{{- $fullname := include (printf "enterprise.%s.fullname" $component) . -}}
{{- /* A resource metric is enabled by setting its target; unset means it is not used */ -}}
{{- $cpuEnabled := $autoscaling.targetCPUUtilizationPercentage -}}
{{- $memoryEnabled := $autoscaling.targetMemoryUtilizationPercentage -}}
{{- if not (or $cpuEnabled $memoryEnabled $autoscaling.customMetrics) -}}
{{- fail (printf "%s.autoscaling.enabled is true but no scaling metric is configured; an HPA with no metrics cannot scale. Set %s.autoscaling.customMetrics, or %s.autoscaling.targetCPUUtilizationPercentage / targetMemoryUtilizationPercentage." $component $component $component) -}}
{{- end -}}
apiVersion: autoscaling/v2
kind: HorizontalPodAutoscaler
metadata:
  name: {{ $fullname }}
  namespace: {{ .Release.Namespace }}
  labels: {{- include "enterprise.common.labels" (merge (dict "component" $component) .) | nindent 4 }}
  annotations: {{- include "enterprise.common.annotations" (merge (dict "component" $component) .) | nindent 4 }}
spec:
  scaleTargetRef:
    apiVersion: apps/v1
    kind: Deployment
    name: {{ $fullname }}
  minReplicas: {{ $autoscaling.minReplicas }}
  maxReplicas: {{ $autoscaling.maxReplicas }}
  metrics:
    {{- with $autoscaling.customMetrics }}
    {{- toYaml . | nindent 4 }}
    {{- end }}
    {{- if $cpuEnabled }}
    - type: Resource
      resource:
        name: cpu
        target:
          type: Utilization
          averageUtilization: {{ $autoscaling.targetCPUUtilizationPercentage }}
    {{- end }}
    {{- if $memoryEnabled }}
    - type: Resource
      resource:
        name: memory
        target:
          type: Utilization
          averageUtilization: {{ $autoscaling.targetMemoryUtilizationPercentage }}
    {{- end }}
  {{- with $autoscaling.behavior }}
  behavior: {{- toYaml . | nindent 4 }}
  {{- end }}
{{- end -}}
{{- end -}}
