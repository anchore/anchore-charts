{{/*
Prometheus helper templates for Anchore Enterprise monitoring configuration.
*/}}

{{/*
Generate optimized Prometheus configuration for Anchore Enterprise monitoring.
This template automatically discovers all Anchore services with proper port mapping.
*/}}
{{- define "enterprise.prometheus.config" -}}
global:
  evaluation_interval: 1m
  scrape_interval: 1m
  scrape_timeout: 10s
rule_files:
- /etc/config/recording_rules.yml
- /etc/config/alerting_rules.yml
- /etc/config/rules
- /etc/config/alerts
scrape_configs:
# Self-monitoring
{{/* Prometheus listens on 9090 inside the container by default */}}
{{- $serverPort := 9090 }}
- job_name: prometheus
  static_configs:
    - targets:
      - localhost:{{ $serverPort }}
    
# Kubernetes API server monitoring
- bearer_token_file: /var/run/secrets/kubernetes.io/serviceaccount/token
  job_name: kubernetes-apiservers
  kubernetes_sd_configs:
  - role: endpoints
  relabel_configs:
  - action: keep
    regex: default;kubernetes;https
    source_labels:
    - __meta_kubernetes_namespace
    - __meta_kubernetes_service_name
    - __meta_kubernetes_endpoint_port_name
  scheme: https
  tls_config:
    ca_file: /var/run/secrets/kubernetes.io/serviceaccount/ca.crt
    
# Kubernetes nodes monitoring
- bearer_token_file: /var/run/secrets/kubernetes.io/serviceaccount/token
  job_name: kubernetes-nodes
  kubernetes_sd_configs:
  - role: node
  relabel_configs:
  - action: labelmap
    regex: __meta_kubernetes_node_label_(.+)
  - replacement: kubernetes.default.svc:443
    target_label: __address__
  - regex: (.+)
    replacement: /api/v1/nodes/$1/proxy/metrics
    source_labels:
    - __meta_kubernetes_node_name
    target_label: __metrics_path__
  scheme: https
  tls_config:
    ca_file: /var/run/secrets/kubernetes.io/serviceaccount/ca.crt
    
# Kubernetes pods with prometheus annotations
- job_name: kubernetes-pods
  kubernetes_sd_configs:
  - role: pod
  relabel_configs:
  - action: keep
    regex: true
    source_labels:
    - __meta_kubernetes_pod_annotation_prometheus_io_scrape
  - action: replace
    regex: (.+)
    source_labels:
    - __meta_kubernetes_pod_annotation_prometheus_io_path
    target_label: __metrics_path__
  - action: replace
    regex: ([^:]+)(?::\d+)?;(\d+)
    replacement: $1:$2
    source_labels:
    - __address__
    - __meta_kubernetes_pod_annotation_prometheus_io_port
    target_label: __address__
  - action: labelmap
    regex: __meta_kubernetes_pod_label_(.+)
  - action: replace
    source_labels:
    - __meta_kubernetes_namespace
    target_label: kubernetes_namespace
  - action: replace
    source_labels:
    - __meta_kubernetes_pod_name
    target_label: kubernetes_pod_name
    
# Anchore Enterprise services - auto-discovery with port mapping
- job_name: anchore-enterprise
  kubernetes_sd_configs:
  - role: pod
  relabel_configs:
  # Keep only Anchore Enterprise pods
  - action: keep
    regex: {{ include "enterprise.fullname" . }}
    source_labels:
    - __meta_kubernetes_pod_label_app_kubernetes_io_name
  # Skip containers that don't expose metrics
  - action: drop
    regex: upgrade-enterprise-db|anchore-scripts
    source_labels:
    - __meta_kubernetes_pod_container_name
  # Map each Anchore component to its specific metrics port
  - regex: api;(.+)
    replacement: $1:8228
    source_labels:
    - __meta_kubernetes_pod_label_app_kubernetes_io_component
    - __meta_kubernetes_pod_ip
    target_label: __address__
  - regex: catalog;(.+)
    replacement: $1:8082
    source_labels:
    - __meta_kubernetes_pod_label_app_kubernetes_io_component
    - __meta_kubernetes_pod_ip
    target_label: __address__
  - regex: analyzer;(.+)
    replacement: $1:8084
    source_labels:
    - __meta_kubernetes_pod_label_app_kubernetes_io_component
    - __meta_kubernetes_pod_ip
    target_label: __address__
  - regex: policyengine;(.+)
    replacement: $1:8087
    source_labels:
    - __meta_kubernetes_pod_label_app_kubernetes_io_component
    - __meta_kubernetes_pod_ip
    target_label: __address__
  - regex: simplequeue;(.+)
    replacement: $1:8083
    source_labels:
    - __meta_kubernetes_pod_label_app_kubernetes_io_component
    - __meta_kubernetes_pod_ip
    target_label: __address__
  - regex: notifications;(.+)
    replacement: $1:8668
    source_labels:
    - __meta_kubernetes_pod_label_app_kubernetes_io_component
    - __meta_kubernetes_pod_ip
    target_label: __address__
  - regex: reports;(.+)
    replacement: $1:8558
    source_labels:
    - __meta_kubernetes_pod_label_app_kubernetes_io_component
    - __meta_kubernetes_pod_ip
    target_label: __address__
  - regex: reportsworker;(.+)
    replacement: $1:8559
    source_labels:
    - __meta_kubernetes_pod_label_app_kubernetes_io_component
    - __meta_kubernetes_pod_ip
    target_label: __address__
  - regex: datasyncer;(.+)
    replacement: $1:8778
    source_labels:
    - __meta_kubernetes_pod_label_app_kubernetes_io_component
    - __meta_kubernetes_pod_ip
    target_label: __address__
  - regex: ui;(.+)
    replacement: $1:3000
    source_labels:
    - __meta_kubernetes_pod_label_app_kubernetes_io_component
    - __meta_kubernetes_pod_ip
    target_label: __address__
  # Set standard metrics path
  - replacement: /metrics
    target_label: __metrics_path__
  # Add useful labels for identification
  - source_labels:
    - __meta_kubernetes_pod_label_app_kubernetes_io_component
    target_label: anchore_service
  - source_labels:
    - __meta_kubernetes_namespace
    target_label: kubernetes_namespace
  - source_labels:
    - __meta_kubernetes_pod_name
    target_label: kubernetes_pod_name
{{- if index .Values.prometheus "prometheus-node-exporter" "enabled" }}
# Determine node-exporter port from values (default 9120)
{{ $ne := (index .Values "prometheus" "prometheus-node-exporter") | default (dict) }}
{{ $nePort := 9120 }}
{{ $neName := "prometheus-node-exporter" }}
{{ if hasKey $ne "nameOverride" }}
{{   $neName = get $ne "nameOverride" }}
{{ end }}
{{ if hasKey $ne "port" }}
{{   $nePort = get $ne "port" }}
{{ else if and (hasKey $ne "service") (hasKey (get $ne "service") "targetPort") }}
{{   $nePort = get (get $ne "service") "targetPort" }}
{{ else if and (hasKey $ne "service") (hasKey (get $ne "service") "port") }}
{{   $nePort = get (get $ne "service") "port" }}
{{ end }}
# Node exporter for system metrics
- job_name: node-exporter
  kubernetes_sd_configs:
  - role: pod
  relabel_configs:
    - action: keep
      source_labels:
        - __meta_kubernetes_pod_label_app_kubernetes_io_name
      regex: "^(?:{{ .Release.Name }}-)?{{ $neName }}$"
    - action: keep
      source_labels:
        - __meta_kubernetes_pod_label_app_kubernetes_io_instance
      regex: "^{{ .Release.Name }}$"
    - action: replace
      source_labels:
        - __meta_kubernetes_pod_ip
      regex: "^(.+)$"
      replacement: ${1}:{{ $nePort }}
      target_label: __address__
{{- end }}
{{- if index .Values.prometheus "kube-state-metrics" "enabled" }}
# Kube-state-metrics for cluster state
- job_name: kube-state-metrics
  kubernetes_sd_configs:
  - role: pod
  relabel_configs:
  - action: keep
    regex: kube-state-metrics
    source_labels:
    - __meta_kubernetes_pod_label_app_kubernetes_io_name
{{- end }}
{{- end }}
