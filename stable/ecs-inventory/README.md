# Anchore ECS Inventory Helm Chart
## Anchore ECS Inventory: Anchore ECS Inventory
Anchore ECS Inventory is a tool to gather an inventory of images in use by Amazon Elastic Container Service (ECS) and ship them to the Anchore platform. Anchore ECS Inventory must be able to resolve the Anchore URL and requires API credentials. The minimum version of the Anchore Enterprise platform required for K8s Inventory is 4.7.

## Installation
Anchore ECS Inventory creates it's own secret based on your values.yaml file for the following keys that are required for successfully deploying and connecting the ecs-inventory service to the Anchore Platform and AWS ECS Service:
- ecsInventory.awsAccessKeyId
- ecsInventory.awsSecretAccessKey

You can install the chart via via:
  ```
  helm repo add anchore https://charts.anchore.io
  helm install <release-name> -f <values.yaml> anchore/ecs-inventory
  ```

A basic values file can always be found [here](https://github.com/anchore/anchore-charts/tree/master/stable/ecs-inventory/values.yaml). The key configurations are in the ecsInventory section.

## Using your own secrets

The (ecsInventory.useExistingSecret and ecsInventory.existingSecretName) or ecsInventory.injectSecretsViaEnv keys allows you to create your own secret and provide it in the values file or place the required secret into the pod via different means such as injecting the secrets into the pod using hashicorp vault.

For example:

- Create a secret in kubernetes:

    ```
    apiVersion: v1
    kind: Secret
    metadata:
      name: ecs-inventory-secrets
    type: Opaque
    stringData:
      ANCHORE_ECS_INVENTORY_ANCHORE_PASSWORD: foobar
      AWS_ACCESS_KEY_ID: someKeyId
      AWS_SECRET_ACCESS_KEY: someSecretAccessKey
    ```

- Provide it to the helm chart via the values file:
    ```
    ecsInventory:
        useExistingSecret: true
        existingSecretName: "ecs-inventory-secrets"
    ```

The Anchore API Password and required AWS secret values can also be injected into the environment of the ecs-inventory container. For injecting the environment variable
  ```
  # set
  ecsInventory:
    injectSecretsViaEnv=true
  ```

See the [ecs-inventory repo](https://github.com/anchore/ecs-inventory) for more information about the ECS Inventory specific configuration## Parameters

## Parameters

### Common Resource Parameters

| Name                                  | Description                                                          | Value                                    |
| ------------------------------------- | -------------------------------------------------------------------- | ---------------------------------------- |
| `replicaCount`                        | Number of replicas for the Ecs Inventory deployment                  | `1`                                      |
| `image`                               | Image used for all Ecs Inventory deployment deployments              | `docker.io/anchore/ecs-inventory:v1.1.0` |
| `imagePullPolicy`                     | Image pull policy used by all deployments                            | `IfNotPresent`                           |
| `imagePullSecretName`                 | Name of Docker credentials secret for access to private repos        | `""`                                     |
| `serviceAccountName`                  | Name of a service account used to run all Anchore Ecs Inventory pods | `""`                                     |
| `useExistingSecret`                   | set to true to use an existing/precreated secret                     | `false`                                  |
| `existingSecretName`                  | the name of the precreated secret                                    | `""`                                     |
| `injectSecretsViaEnv`                 | Enable secret injection into pod environment variables               | `false`                                  |
| `extraEnv`                            | extra environment variables. These will be set on all containers.    | `[]`                                     |
| `annotations`                         | Common annotations set on all Kubernetes resources                   | `{}`                                     |
| `deploymentAnnotations`               | annotations to set on the ecs-inventory deployment                   | `{}`                                     |
| `securityContext.runAsUser`           | The securityContext runAsUser for all Anchore ECS Inventory pods     | `1000`                                   |
| `securityContext.runAsGroup`          | The securityContext runAsGroup for all Anchore ECS Inventory pods    | `1000`                                   |
| `securityContext.fsGroup`             | The securityContext fsGroup for all Anchore ECS Inventory pods       | `1000`                                   |
| `resources`                           | Resource requests and limits for Anchore ECS Inventory pods          | `{}`                                     |
| `nodeSelector`                        | Node labels for pod assignment                                       | `{}`                                     |
| `tolerations`                         | Tolerations for pod assignment                                       | `[]`                                     |
| `affinity`                            | Affinity for pod assignment                                          | `{}`                                     |
| `labels`                              | Adds additionnal labels to all kubernetes resources                  | `{}`                                     |
| `probes.liveness.initialDelaySeconds` | Initial delay seconds for liveness probe                             | `1`                                      |
| `probes.liveness.timeoutSeconds`      | Timeout seconds for liveness probe                                   | `10`                                     |
| `probes.liveness.periodSeconds`       | Period seconds for liveness probe                                    | `5`                                      |
| `probes.liveness.failureThreshold`    | Failure threshold for liveness probe                                 | `6`                                      |
| `probes.liveness.successThreshold`    | Success threshold for liveness probe                                 | `1`                                      |
| `probes.readiness.timeoutSeconds`     | Timeout seconds for the readiness probe                              | `10`                                     |
| `probes.readiness.periodSeconds`      | Period seconds for the readiness probe                               | `15`                                     |
| `probes.readiness.failureThreshold`   | Failure threshold for the readiness probe                            | `3`                                      |
| `probes.readiness.successThreshold`   | Success threshold for the readiness probe                            | `1`                                      |


### ecsInventory Parameters ##

| Name                                     | Description                                                        | Value                   |
| ---------------------------------------- | ------------------------------------------------------------------ | ----------------------- |
| `ecsInventory.quiet`                     | Determine whether or not to log the inventory report to stdout     | `false`                 |
| `ecsInventory.output`                    | The output format of the report (options: table, json)             | `json`                  |
| `ecsInventory.logLevel`                  | the level of verbosity for logs                                    | `info`                  |
| `ecsInventory.logFile`                   | location to write the log file (default is not to have a log file) | `""`                    |
| `ecsInventory.pollingIntervalSeconds`    | The polling interval of the ECS API in seconds                     | `60`                    |
| `ecsInventory.anchoreUrl`                | the url of the anchore platform                                    | `http://localhost:8228` |
| `ecsInventory.anchoreAccount`            | the account of the anchore platform                                | `admin`                 |
| `ecsInventory.anchoreUser`               | the username of the anchore platform                               | `admin`                 |
| `ecsInventory.anchorePassword`           | the password of the anchore platform                               | `foobar`                |
| `ecsInventory.anchoreHttpInsecure`       | whether or not anchore is using ssl/tls                            | `true`                  |
| `ecsInventory.anchoreHttpTimeoutSeconds` | the amount of time in seconds before timing out                    | `10`                    |
| `ecsInventory.awsAccessKeyId`            | the AWS Access Key ID                                              | `foobar`                |
| `ecsInventory.awsSecretAccessKey`        | the AWS Secret Access Key                                          | `foobar`                |
| `ecsInventory.awsRegion`                 | the AWS Region                                                     | `us-west-2`             |
