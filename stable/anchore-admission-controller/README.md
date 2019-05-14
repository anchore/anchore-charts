# Anchore Admission Controller

This chart deploys an admission controller for kubernetes that makes admission decisions based on policy-based evaluation of image content.

The controller's code is at: https://github.com/anchore/kubernetes-admission-controller , with more details on the implementation and config there.

This chart is a simple wrapper to wire up credentials, configuration, and setup rbac, tls, and api service config for the controller.


## Running the chart

1. The chart does not deploy an anchore engine service, if you don't already have anchore running, you can use the anchore chart
to deploy one with:

```
helm install --name anchore stable/anchore-engine
```

Setup of policies and users is covered in the anchore documentation, for this readme we'll use admin user credentials, but it 
is *strongly* suggested that you use a non-admin user for the controller credential.

1. Create a secret for the anchore credentials that the controller will use to make api calls to Anchore. This must be done out-of-band of the chart creation and should be in the
same namespace you will deploy the chart to. The file must be a json file with the format:

```
{
  "users": [
    { "username": "user1", "password": "password"},
    { "uesrname": "user2", "password": "password2"},
    ...      
  ]
}
```

The file *must* be named `credentials.json` in the secret so that it mounts properly in the pod.

Not all users in the anchore engine need to be specified, only those that will be referenced in the controller configuration.

To create the secret:

```
kubectl create secret generic anchore-credentials --from-file=credentials.json
```

Next, create a _values.yaml_ for the chart with a minimum set of keys:
```
credentialsSecret: anchore-credentials
anchoreEndpoint: <anchore service endpoint for external api>
policySelectors:
  - Selector:
      ResourceType: "image"
      SelectorKeyRegex: ".*"
      SelectorValueRegex: ".*"
    PolicyReference:
      Username: "admin"
      # This is the default bundle id in anchore engine
      PolicyBundleId: "2c53a13c-1765-11e8-82ef-23527761d060"
    # Mode is one of: "policy", "analysis", or "breakglass". policy=>require policy pass, analysis=>require image analyzed, breakglass=>do nothing
    Mode: breakglass
```

Finally install the chart with:
```
helm install --name <release name> --repo https://charts.anchore.io/stable anchore-admission-controller -f <path to values.yaml>
```

If you need to delete and re-install the chart, you will find the [cleanup script](files/cleanup.sh) useful.
It will remove kubernetes objects which are not removed by a helm delete. Pass the release name as an argument.

## Chart Configuration

| Key | Expected Type | Default Value | Description |
|---|---|---|---|
|replicaCount | int | 1 | replicas, should generally only need one 
|---|---|---|---|
|logVerbosity | int | 6 | log verbosity of controller, 1 = error, 2 warn, 3 debug....
|---|---|---|---|
|image | str | release tag | Tag including registry and repository for image to use 
|---|---|---|---|
|imagePullPolicy | str | IfNotPresent | Standard k8s pull policy setting
|---|---|---|---|
|service.name | str | anchoreadmissioncontroller | Name for the svc instance 
|---|---|---|---|
|service.type | str | ClusterIp | Type to use for k8s service definition
|---|---|---|---|
|service.internalPort | int | 443 | Port the pod listens on
|---|---|---|---|
|service.externalPort | int | 443 | Port to expose to service clients
|---|---|---|---|
|apiService.group | str | admission.anchore.io | Service group implemented by the service image (must match that presented by controller)
|---|---|---|---|
|apiService.version | str | v1beta1 | api service version, should not need to be updated
|---|---|---|---|
|credentialSecret | str | null | Name of the secret to use for credentials
|---|---|---|---|
|anchoreEndpoint | str | "" | Anchore URL to use for api access
|---|---|---|---|
|policySelectors | array | default catch-all | Selector rules, see the project github page for detail on format and options.
|---|---|---|---|
|requestAnalysis | boolean | true | Ask anchore to analyze an image that isn't already analyzed
|---|---|---|---|

## Updating configuration

Updates to configuration are handled dynamically by the service, so updates to the chart can be applied without restarting
the pods.

Modify the values.yaml you're using and simply run: `helm upgrade <release> -f values.yaml`

Using the '--recreate-pods' is not required to get updates of config to the running controller.
