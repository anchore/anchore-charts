# Anchore Admission Controller

> **Note: this integration requires a valid license or subscription entitlement from Anchore**

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
existingCredentialsSecret: anchore-credentials
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

## Image Registry

The chart's image is a set of parts rather than one string:

```yaml
image:
  registry: ""            # empty -> taken from global.imageRegistryHost
  repository: anchore/kubernetes-admission-controller
  tag: "v0.8.4"
```

The registry is chosen from three levels, most specific first:

| Level | Where | Wins over |
| --- | --- | --- |
| 1. Per-image `registry` | `image.registry`, `initCa.image.registry` | everything below |
| 2. `global.imageRegistryHost` | one value for the whole chart | the chart defaults |
| 3. Chart default | `docker.io` | — |

Stated as one rule:

> **An image value that states no registry of its own takes one from `global.imageRegistryHost`. An image value that does state one keeps it.**

To mirror the image, set the global once:

```yaml
global:
  imageRegistryHost: harbor.example.com
```

Only the registry comes from the global — the repository and tag stay with the chart, so chart upgrades keep moving the version. `global.imageRegistryHost` may include a path, eg. `harbor.example.com/anchore`.

To pull one image from a different registry than the rest — for example when the Anchore image and the third-party `cfssl` image live in different proxy-cache projects — set that image's `registry`:

```yaml
global:
  imageRegistryHost: harbor.example.com/anchore
initCa:
  image:
    registry: harbor.example.com/dockerhub
```

An image value may also be given as a complete reference string (`image: myregistry.example.com/anchore/kubernetes-admission-controller:v0.8.4`), which is used as written. A string that states no registry host takes one from the global like any other value.

Overriding a **nested** image value with a reference string — ``initCa.image`` — makes Helm print a warning:

```
coalesce.go:298: warning: cannot overwrite table with non table for ...
```

The string is still used; Helm is noting that it replaced the default's parts wholesale. Top-level values (`image`) do not warn. Writing the dict form instead avoids it:

```yaml
initCa:
  image:
    registry: myregistry.example.com
    repository: cfssl/cfssl
    tag: "v1.6.5"
```

Note that the chart attaches a single image pull secret, so images split across registries need credentials that can read all of them.


## Chart Configuration

| Key | Expected Type | Default Value | Description |
|---|---|---|---|
|replicaCount | int | 1 | replicas, should generally only need one
|---|---|---|---|
|logVerbosity | int | 6 | log verbosity of controller, 1 = error, 2 warn, 3 debug....
|---|---|---|---|
|global.imageRegistryHost | str | docker.io | Registry host used by every image value in this chart that does not set its own. Only the registry is taken from here, so the repository and tag stay with the chart
|---|---|---|---|
|image.registry | str | "" | Registry for the controller image. Empty means take it from global.imageRegistryHost; set it to pull this image from a different registry
|---|---|---|---|
|image.repository | str | anchore/kubernetes-admission-controller | Repository for the controller image
|---|---|---|---|
|image.tag | str | release tag | Tag for the controller image
|---|---|---|---|
|initCa.image.registry | str | "" | Registry for the init-ca image. Empty means take it from global.imageRegistryHost
|---|---|---|---|
|initCa.image.repository | str | cfssl/cfssl | Repository for the init-ca image
|---|---|---|---|
|initCa.image.tag | str | v1.6.5 | Tag for the init-ca image
|---|---|---|---|
|imagePullPolicy | str | IfNotPresent | Standard k8s pull policy setting
|---|---|---|---|
|imagePullSecrets | array | [] | Image pull secrets
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
|initCa.image | str | cfssl/cfssl:latest | Tag including registry and repository for the initCa image
|---|---|---|---|
|initCa.extraEnv | array | [] | Define custom environment variables to pass to init-ca pod |
|---|---|---|---|

## Updating configuration

Updates to configuration are handled dynamically by the service, so updates to the chart can be applied without restarting
the pods.

Modify the values.yaml you're using and simply run: `helm upgrade <release> -f values.yaml`

Using the '--recreate-pods' is not required to get updates of config to the running controller.

## Release Notes

- **Major Chart Version Change (e.g., v0.1.2 -> v1.0.0)**: Signifies an incompatible breaking change that necessitates manual intervention, such as updates to your values file or data migrations.
- **Minor Chart Version Change (e.g., v0.1.2 -> v0.2.0)**: Indicates a significant change to the deployment that does not require manual intervention.
- **Patch Chart Version Change (e.g., v0.1.2 -> v0.1.3)**: Indicates a backwards-compatible bug fix or documentation update.

### v0.9.0

**The image value is now a dict, and the registry can be set once for the whole chart.**

- Adds `global.imageRegistryHost`. An image value that states no registry of its own takes one from it, so mirroring the Anchore images is a single setting. See [Image Registry](#image-registry).
- `image` and `initCa.image` are now `registry` / `repository` / `tag` rather than reference strings. Setting `registry` points that image at a different registry without pinning its version, so chart upgrades keep moving the tag. Complete reference strings are still accepted and are used as written, so existing values files continue to work.
- Rendered image references now always include the registry host, so `anchore/kubernetes-admission-controller:v0.8.4` renders as `docker.io/anchore/kubernetes-admission-controller:v0.8.4`. This resolves to the same image and is a no-op for pulls, but it changes the pod spec, so an upgrade will show a diff and roll the pods.

No values changes are required to upgrade.
