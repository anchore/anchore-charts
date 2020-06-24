#!/bin/bash

ns="default"
if [ -n "${2}" ]
then
	ns="${2}"
fi

echo "Using ns = ${ns}"

kubectl -n "${ns}" delete clusterrolebinding/extension-"${1}"-anchore-admission-controller-init-ca-cluster
kubectl -n "${ns}" delete rolebinding/extension-"${1}"-anchore-admission-controller-init-ca-admin
kubectl -n "${ns}" delete role/"${1}"-anchore-admission-controller-init-ca
kubectl -n "${ns}" delete clusterrole/"${1}"-anchore-admission-controller-init-ca-cluster
kubectl -n "${ns}" delete serviceaccount/"${1}"-anchore-admission-controller-init-ca
kubectl -n "${ns}" delete cm/"${1}"-init-ca
kubectl -n "${ns}" delete job/"${1}"-init-ca
kubectl delete APIService/v1beta1.admission.anchore.io
kubectl -n "${ns}" delete secret/"${1}"-anchore-admission-controller-certs
