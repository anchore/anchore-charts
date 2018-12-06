#!/bin/bash

name=${1}

KUBE_CA=$(kubectl config view --minify=true --flatten -o json | jq '.clusters[0].cluster."certificate-authority-data"' -r)
cat > validating-webhook.yaml <<EOF
apiVersion: admissionregistration.k8s.io/v1beta1
kind: ValidatingWebhookConfiguration
metadata:
  name: ${name}-anchore-admission-controller.admission.anchore.io
webhooks:
- name: ${name}-anchore-admission-controller.admission.anchore.io
  clientConfig:
    service:
      namespace: default
      name: kubernetes
      path: /apis/admission.anchore.io/v1beta1/imagechecks
    caBundle: $KUBE_CA
  rules:
  - operations:
    - CREATE
    apiGroups:
    - ""
    apiVersions:
    - "*"
    resources:
    - pods
  failurePolicy: Fail
# Uncomment this and customize to exclude specific namespaces from the validation requirement
#  namespaceSelector:
#    matchExpressions:
#      - key: exclude.admission.anchore.io
#        operator: NotIn
#        values: ["true"]
EOF


