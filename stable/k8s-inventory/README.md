# K8s Inventory Helm Chart
K8s Inventory is the foundation of Anchore Enterprise's Runtime Inventory feature. Running K8s Inventory via Helm is a great way to retrieve your Kubernetes Image inventory without providing Cluster Credentials to Anchore. The minimum version of the Anchore Enterprise platform required for K8s Inventory is 4.7.

K8s Inventory runs as a read-only service account in the cluster it's deployed to. 

In order to report the inventory to Anchore, K8s Inventory does require authentication material for your Anchore Enterprise deployment.
K8s Inventory's helm chart automatically creates a kubernetes secret for the Anchore Password based on the values file you use, Ex.:
```
k8sInventory:
    anchore:
        password: foobar
```
It will set the following environment variable based on this: `ANCHORE_K8S_INVENTORY_ANCHORE_PASSWORD=foobar`.

If you don't want to store your Anchore password in the values file, you can create your own secret to do this:
```
apiVersion: v1
kind: Secret
metadata:
  name: k8s-inventory-anchore-password
type: Opaque
stringData:
  ANCHORE_K8S_INVENTORY_ANCHORE_PASSWORD: foobar
```
and then provide it to the helm chart via the values file:
```
useExistingSecret: true
existingSecretName: k8s-inventory-anchore-password
```
You can install the chart via via:
```
helm repo add anchore https://charts.anchore.io
helm install <release-name> -f <values.yaml> anchore/k8s-inventory
``` 
A basic values file can always be found [here](https://github.com/anchore/anchore-charts/tree/master/stable/k8s-inventory/values.yaml)

The key configurations are in the k8sInventory.anchore section. K8s Inventory must be able to resolve the Anchore URL and requires API credentials.

Note: the Anchore API Password can be provided via a kubernetes secret, or injected into the environment of the K8s Inventory container
* For injecting the environment variable, see: injectSecretsViaEnv
* For providing your own secret for the Anchore API Password, see: useExistingSecret. K8s Inventory creates it's own secret based on your values.yaml file for key k8sInventory.anchore.password, but the k8sInventory.useExistingSecret key allows you to create your own secret and provide it in the values file.

See the [K8s Inventory repo](https://github.com/anchore/k8s-inventory) for more information about the K8s Inventory specific configuration

## Parameters

### Common Resource Parameters

| Name                                  | Description                                                                                                             | Value                   |
| ------------------------------------- | ----------------------------------------------------------------------------------------------------------------------- | ----------------------- |
| `replicaCount`                        | Number of replicas for the K8s Inventory deployment                                                                     | `1`                     |
| `image.pullPolicy`                    | Image pull policy used by the K8s Inventory deployment                                                                  | `Always`                |
| `image.repository`                    | Image used for the K8s Inventory deployment                                                                             | `anchore/k8s-inventory` |
| `image.tag`                           | Image tag used for the K8s Inventory deployment                                                                         | `v1.0.0`                |
| `imagePullSecrets`                    | secrets where Kubernetes should get the credentials for pulling private images                                          | `[]`                    |
| `nameOverride`                        | overrides the name set on resources                                                                                     | `""`                    |
| `fullnameOverride`                    | overrides the fullname set on resources                                                                                 | `""`                    |
| `injectSecretsViaEnv`                 | Enable secret injection into pod via environment variables instead of via k8s secrets                                   | `false`                 |
| `serviceAccount.create`               | Create a service account for k8s-inventory to use                                                                       | `true`                  |
| `serviceAccount.annotations`          | Annotations to add to the service account                                                                               | `{}`                    |
| `serviceAccount.name`                 | The name of the service account to use. If not set and create is true, a name is generated using the fullname template. | `k8s-inventory`         |
| `podAnnotations`                      | Annotations set on all pods                                                                                             | `{}`                    |
| `annotations`                         | Common annotations set on all Kubernetes resources                                                                      | `{}`                    |
| `podSecurityContext`                  | Security context set on all pods                                                                                        | `{}`                    |
| `securityContext`                     | Security context set on all containers                                                                                  | `{}`                    |
| `service.type`                        | Service type for K8s Inventory                                                                                          | `ClusterIP`             |
| `service.port`                        | Service port for K8s Inventory                                                                                          | `80`                    |
| `resources`                           | Resource requests and limits for K8s Inventory pods                                                                     | `{}`                    |
| `nodeSelector`                        | Node labels for K8s Inventory pods assignment                                                                           | `{}`                    |
| `tolerations`                         | Tolerations for K8s Inventory pods assignment                                                                           | `[]`                    |
| `affinity`                            | Affinity for K8s Inventory pods assignment                                                                              | `{}`                    |
| `labels`                              | Adds additionnal labels to all kubernetes resources                                                                     | `{}`                    |
| `probes.liveness.initialDelaySeconds` | Initial delay seconds for liveness probe                                                                                | `1`                     |
| `probes.liveness.timeoutSeconds`      | Timeout seconds for liveness probe                                                                                      | `10`                    |
| `probes.liveness.periodSeconds`       | Period seconds for liveness probe                                                                                       | `5`                     |
| `probes.liveness.failureThreshold`    | Failure threshold for liveness probe                                                                                    | `6`                     |
| `probes.liveness.successThreshold`    | Success threshold for liveness probe                                                                                    | `1`                     |
| `probes.readiness.timeoutSeconds`     | Timeout seconds for the readiness probe                                                                                 | `10`                    |
| `probes.readiness.periodSeconds`      | Period seconds for the readiness probe                                                                                  | `15`                    |
| `probes.readiness.failureThreshold`   | Failure threshold for the readiness probe                                                                               | `3`                     |
| `probes.readiness.successThreshold`   | Success threshold for the readiness probe                                                                               | `1`                     |
| `useExistingSecret`                   | Specify whether to use an existing secret                                                                               | `false`                 |
| `existingSecretName`                  | if using an existing secret, specify the existing secret name                                                           | `""`                    |

### k8sInventory Parameters ##

| Name                                            | Description                                                                                                                         | Value                   |
| ----------------------------------------------- | ----------------------------------------------------------------------------------------------------------------------------------- | ----------------------- |
| `k8sInventory.output`                           | The output format of the report (options: table, json)                                                                              | `json`                  |
| `k8sInventory.quiet`                            | Determine whether or not to log the inventory report to stdout                                                                      | `false`                 |
| `k8sInventory.verboseInventoryReports`          | Determine whether or not to log the inventory report to stdout                                                                      | `false`                 |
| `k8sInventory.log.structured`                   | Determine whether or not to use structured logs                                                                                     | `false`                 |
| `k8sInventory.log.level`                        | the level of verbosity for logs                                                                                                     | `debug`                 |
| `k8sInventory.log.file`                         | location to write the log file (default is not to have a log file)                                                                  | `""`                    |
| `k8sInventory.kubeconfig.path`                  | Path should not be changed                                                                                                          | `use-in-cluster`        |
| `k8sInventory.kubeconfig.cluster`               | Tells Anchore which cluster this inventory is coming from                                                                           | `docker-desktop`        |
| `k8sInventory.namespaceSelectors.include`       | Which namespaces to search as explicit strings, not regex; Will search all namespaces if empty array                                | `[]`                    |
| `k8sInventory.namespaceSelectors.exclude`       | Which namespaces to exclude can use explicit strings and/or regexes.                                                                | `[]`                    |
| `k8sInventory.mode`                             | Can be one of adhoc, periodic (defaults to adhoc)                                                                                   | `periodic`              |
| `k8sInventory.pollingIntervalSeconds`           | Only respected if mode is periodic                                                                                                  | `60`                    |
| `k8sInventory.kubernetes.requestTimeoutSeconds` | Sets the request timeout for kubernetes API requests                                                                                | `60`                    |
| `k8sInventory.kubernetes.requestBatchSize`      | Sets the number of objects to iteratively return when listing resources                                                             | `100`                   |
| `k8sInventory.kubernetes.workerPoolSize`        | Worker pool size for collecting pods from namespaces. Adjust this if the api-server gets overwhelmed                                | `100`                   |
| `k8sInventory.missingTagPolicy.policy`          | One of the following options [digest, insert, drop]. Default is 'digest'                                                            | `digest`                |
| `k8sInventory.missingTagPolicy.tag`             | Dummy tag to use. Only applicable if policy is 'insert'. Defaults to UNKNOWN                                                        | `UNKNOWN`               |
| `k8sInventory.ignoreNotRunning`                 | Ignore images out of pods that are not in a Running state                                                                           | `true`                  |
| `k8sInventory.anchore.url`                      | the url of the anchore platform                                                                                                     | `http://localhost:8228` |
| `k8sInventory.anchore.user`                     | the username of the anchore platform. The user specified must be an admin user or have full-control, or read-write RBAC permissions | `admin`                 |
| `k8sInventory.anchore.password`                 | the password of the anchore platform                                                                                                | `foobar`                |
| `k8sInventory.anchore.account`                  | the account to send data to                                                                                                         | `admin`                 |
| `k8sInventory.anchore.http.insecure`            | whether or not anchore is using ssl/tls                                                                                             | `true`                  |
| `k8sInventory.anchore.http.timeoutSeconds`      | the amount of time in seconds before timing out                                                                                     | `10`                    |
