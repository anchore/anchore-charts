# KAI Helm Chart
KAI is the foundation of Anchore Enterprise's Runtime Inventory feature. Running KAI via Helm is a great way to retrieve your Kubernetes Image inventory without providing Cluster Credentials to Anchore.

KAI runs as a read-only service account in the cluster it's deployed to.

In order to report the inventory to Anchore, KAI does require authentication material for your Anchore Enterprise deployment.
KAI's helm chart automatically creates a kubernetes secret for the Anchore Password based on the values file you use, Ex.:
```
kai:
    anchore:
        password: foobar
```
It will set the following environment variable based on this: `KAI_ANCHORE_PASSWORD=foobar`.

If you don't want to store your Anchore password in the values file, you can create your own secret to do this:
```
apiVersion: v1
kind: Secret
metadata:
  name: kai-anchore-password
type: Opaque
stringData:
  KAI_ANCHORE_PASSWORD: foobar
```
and then provide it to the helm chart via the values file:
```
kai:
    existingSecret: kai-anchore-password
```
You can install the chart via via:
```
helm repo add anchore https://charts.anchore.io
helm install <release-name> -f <values.yaml> anchore/kai
```
A basic values file can always be found [here](https://github.com/anchore/anchore-charts/tree/master/stable/kai/values.yaml)

The key configurations are in the kai.anchore section. Kai must be able to resolve the Anchore URL and requires API credentials.

Note: the Anchore API Password can be provided via a kubernetes secret, or injected into the environment of the kai container
* For injecting the environment variable, see: inject_secrets_via_env
* For providing your own secret for the Anchore API Password, see: kai.existing_secret. kai creates it's own secret based on your values.yaml file for key kai.anchore.password, but the kai.existingSecret key allows you to create your own secret and provide it in the values file.

See the [kai repo](https://github.com/anchore/kai) for more information about the KAI-specific configuration
