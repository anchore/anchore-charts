# Anchore Enterprise Feeds Helm Chart

> :exclamation: **Important:** View the **[Chart Release Notes](#release-notes)** for the latest changes prior to installation or upgrading.

This Helm chart deploys the Anchore Enterprise Feeds service on a [Kubernetes](http://kubernetes.io) cluster using the [Helm](https://helm.sh) package manager.

Anchore Enterprise Feeds is an On-Premises service that supplies operating system and non-operating system vulnerability data and package data for consumption by Anchore Policy Engine. Policy Engine uses this data for finding vulnerabilities and evaluating policies.

See the [Anchore Feeds Documentation](https://docs.anchore.com/current/docs/overview/feeds/) for more details.

## Table of Contents

- [Prerequisites](#prerequisites)
- [Installing the Chart](#installing-the-chart)
- [Installing on Openshift](#installing-on-openshift)
- [Uninstalling the Chart](#uninstalling-the-chart)
- [Configuration](#configuration)
  - [Feeds External Database Configuration](#feeds-external-database-configuration)
  - [Feeds Driver Configuration](#feeds-driver-configuration)
  - [Existing Secrets](#existing-secrets)
  - [Ingress](#ingress)
  - [Prometheus Metrics](#prometheus-metrics)
- [Parameters](#parameters)
- [Release Notes](#release-notes)

## Prerequisites

- [Helm](https://helm.sh/) >=3.8
- [Kubernetes](https://kubernetes.io/) >=1.23

## Installing the Chart

This guide covers deploying Anchore Enterprise on a Kubernetes cluster with the default configuration.

This guide covers deploying Anchore Enterprise on a Kubernetes cluster with the default configuration. For production deployments, refer to the [Configuration](#configuration) section for additional guidance.

1. **Create a Kubernetes Secret for License File**: Generate a Kubernetes secret to store your Anchore Enterprise license file.

    ```shell
    export NAMESPACE=anchore
    export LICENSE_PATH="license.yaml"

    kubectl create secret generic anchore-enterprise-license --from-file=license.yaml=${LICENSE_PATH} -n ${NAMESPACE}
    ```

1. **Create a Kubernetes Secret for DockerHub Credentials**: Generate another Kubernetes secret for DockerHub credentials. These credentials should have access to private Anchore Enterprise repositories. We recommend that you create a brand new DockerHub user for these pull credentials. Contact [Anchore Support](https://get.anchore.com/contact/) to obtain access.

    ```shell
    export NAMESPACE=anchore
    export DOCKERHUB_PASSWORD="password"
    export DOCKERHUB_USER="username"
    export DOCKERHUB_EMAIL="example@email.com"

    kubectl create secret docker-registry anchore-enterprise-pullcreds --docker-server=docker.io --docker-username=${DOCKERHUB_USER} --docker-password=${DOCKERHUB_PASSWORD} --docker-email=${DOCKERHUB_EMAIL} -n ${NAMESPACE}
    ```

1. **Add Chart Repository & Deploy Anchore Enterprise**: Create a custom values file, named `anchore_values.yaml`, to override any chart parameters. Refer to the [Parameters](#parameters) section for available options.

    > :exclamation: **Important**: Default passwords are specified in the chart. It's highly recommended to modify these before deploying.

    ```shell
    export NAMESPACE=anchore
    export RELEASE=my-release

    helm repo add anchore https://charts.anchore.io
    helm install ${RELEASE} -n ${NAMESPACE} anchore/feeds -f anchore_values.yaml
    ```

    > **Note**: This command installs Anchore Enterprise with a chart-managed PostgreSQL database, which may not be suitable for production use. See the [External Database](#external-database-requirements) section for details on using an external database.

1. **Post-Installation Steps**: Anchore Enterprise will take some time to initialize. After the bootstrap phase, it will begin a vulnerability feed sync. Image analysis will show zero vulnerabilities until this sync is complete. This can take several hours based on the enabled feeds.

    > **Tip**: List all releases using `helm list`

### Installing on Openshift

By default, we assign the `securityContext.fsGroup`, `securityContext.runAsGroup`, and `securityContext.runAsUser` to `1000`. This will most likely fail on openshift for not being in the range determined by the `openshift.io/sa.scc.uid-range` annotation openshift attaches to the namespace when created. If using the chartEnabled postgresql, postgres will fail to come up as well due to this reason.

1. Either disable the securityContext or set the appropriate values.
1. If using the chartEnabled postgres, you will also need to either disable the feeds-db.primary.podSecurityContext and feeds-db.primary.containerSecurityContext, or set the appropriate values for them

Note: disabling the containerSecurityContext and podSecurityContext may not be suitable for production. See [Redhat's documentation](https://docs.openshift.com/container-platform/4.13/authentication/managing-security-context-constraints.html#managing-pod-security-policies) on what may be suitable for production.

For more information on the openshift.io/sa.scc.uid-range annotation, see the [openshift docs](https://docs.openshift.com/dedicated/authentication/managing-security-context-constraints.html#security-context-constraints-pre-allocated-values_configuring-internal-oauth)

```shell
helm install feedsy anchore/feeds \
  --set securityContext.fsGroup=null \
  --set securityContext.runAsGroup=null \
  --set securityContext.runAsUser=null \
  --set feeds-db.primary.containerSecurityContext.enabled=false \
  --set feeds-db.primary.podSecurityContext.enabled=false \
  --set feeds-db.volumePermissions.enabled=true
```

#### Example OpenShift values file

```yaml
# NOTE: This is not a production ready values file for an openshift deployment.
securityContext:
  fsGroup: null
  runAsGroup: null
  runAsUser: null

feeds-db:
  primary:
    containerSecurityContext:
      enabled: false
    podSecurityContext:
      enabled: false
  volumePermissions:
    enabled: true
```

## Upgrading the Chart

A Helm pre-upgrade hook initiates a Kubernetes job that scales down all active Anchore Feeds pods and handles the Anchore database upgrade.

The Helm upgrade is marked as successful only upon the job's completion. This process causes the Helm client to pause until the job finishes and new Anchore Enterprise pods are initiated. To monitor the upgrade, follow the logs of the upgrade job, which is automatically removed after a successful Helm upgrade.

  ```shell
  export NAMESPACE=anchore
  export RELEASE=my-release

  helm upgrade ${RELEASE} -n ${NAMESPACE} anchore/feeds -f anchore_values.yaml
  ```

An optional post-upgrade hook is available to perform Anchore Feeds upgrades without forcing all pods to terminate prior to running the upgrade. This is the same upgrade behavior that was enabled by default in the legacy anchore-engine chart. To enable the post-upgrade hook, set `feedsUpgradeJob.usePostUpgradeHook=true` in your values file.

## Uninstalling the Chart

To completely remove the Anchore Feeds deployment and associated Kubernetes resources, follow the steps below:

  ```shell
  export NAMESPACE=anchore
  export RELEASE=my-release

  helm delete ${RELEASE} -n ${NAMESPACE}
  ```

After deleting the helm release, there are still a few persistent volume claims to delete. Delete these only if you're certain you no longer need them.

  ```shell
  export NAMESPACE=anchore
  export RELEASE=my-release

  kubectl get pvc -n ${NAMESPACE}
  kubectl delete pvc ${RELEASE}-feeds -n ${NAMESPACE}
  kubectl delete pvc ${RELEASE}-feeds-db -n ${NAMESPACE}
  ```

## Configuration

This section outlines the available configuration options for Anchore Enterprise. The default settings are specified in the bundled [values file](https://github.com/anchore/anchore-charts-dev/blob/main/stable/feeds/values.yaml). To customize these settings, create your own `anchore_values.yaml` file and populate it with the configuration options you wish to override. To apply your custom configuration during installation, pass your custom values file to the `helm install` command:

```shell
export NAMESPACE=anchore
export RELEASE="my-release"

helm install ${RELEASE} -n ${NAMESPACE} anchore/feeds -f custom_values.yaml
```

For additional guidance on customizing your Anchore Enterprise deployment, reach out to [Anchore Support](get.anchore.com/contact/).

### Feeds External Database Configuration

Anchore Enterprise Feeds require access to a Postgres-compatible database, version 12 or higher to operate. Note that this is a separate database from the primary Anchore Enterprise database. For Enterprise Feeds, an external database such as AWS RDS or Google CloudSQL is recommended for production deployments. The Helm chart provides a chart-managed database by default unless otherwise configured.

See previous examples of configuring RDS Postgres and Google CloudSQL.

```yaml
anchoreConfig:
  database:
    ssl: true
    sslMode: require

feeds-db:
  # enabled: false disables the chart-managed Postgres instance; this is a Helmism
  enabled: false

  # auth.username, auth.password & auth.database are required values for external Postgres
  auth.password: <PASSWORD>
  auth.username: <USER>
  auth.database: <DATABASE>

  # Required for external Postgres.
  # Specify an external (already existing) Postgres deployment for use.
  # Set to the host eg. mypostgres.myserver.io
  externalEndpoint: <HOSTNAME>
```

### Feeds Driver Configuration

This service is comprised of different drivers for different vulnerability feeds. The drivers can be configured separately, and some drivers require a token or other credential.

See the [Anchore Enterprise Feeds](https://docs.anchore.com/current/docs/configuration/feeds/) documentation for details.

```yaml
anchoreConfig:
  feeds:
    drivers:
      github:
        enabled: true
        # The GitHub feeds driver requires a GitHub developer personal access token with no permission scopes selected.
        # See https://docs.github.com/en/github/authenticating-to-github/keeping-your-account-and-data-secure/creating-a-personal-access-token
        token: your-github-token

      # Enable microsoft feeds
      msrc:
        enabled: true
```

### Existing Secrets

For deployments where version-controlled configurations are essential, it's advised to avoid storing credentials directly in values files. Instead, manually create Kubernetes secrets and reference them as existing secrets within your values files. When using existing secrets, the chart will load environment variables into deployments from the secret names specified by the following values:

- `.Values.existingSecretName` [default: anchore-enterprise-feeds-env]

To enable this feature, set the following values to `true` in your values file:

```yaml
useExistingSecrets: true
```

```yaml
apiVersion: v1
kind: Secret
metadata:
  name: anchore-enterprise-feeds-env
    app: anchore
type: Opaque
stringData:
  ANCHORE_ADMIN_PASSWORD: foobar1234
  ANCHORE_FEEDS_DB_NAME: anchore-feeds
  ANCHORE_FEEDS_DB_USER: anchoreengine
  ANCHORE_FEEDS_DB_PASSWORD: anchore-postgres,123
  ANCHORE_FEEDS_DB_HOST: anchore-enterprise-feeds-db
  ANCHORE_FEEDS_DB_PORT: 5432
  # (if applicable) ANCHORE_SAML_SECRET: foobar,saml1234
  # (if applicable) ANCHORE_GITHUB_TOKEN: foobar,github1234
  # (if applicable) ANCHORE_NVD_API_KEY: foobar,nvd1234
  # (if applicable) ANCHORE_GEM_DB_NAME: anchore-gems
  # (if applicable) ANCHORE_GEM_DB_USER: anchoregemsuser
  # (if applicable) ANCHORE_GEM_DB_PASSWORD: foobar1234
  # (if applicable) ANCHORE_GEM_DB_HOST: anchorefeeds-gem-db.example.com:5432
```

### Ingress

[Ingress](https://kubernetes.io/docs/concepts/services-networking/ingress/) serves as the gateway to expose HTTP and HTTPS routes from outside the Kubernetes cluster to services within it. Routing is governed by rules specified in the Ingress resource. Kubernetes supports a variety of ingress controllers, such as AWS ALB and GCE controllers.

This Helm chart includes a foundational ingress configuration that is customizable. You can expose various Anchore Enterprise external APIs, including the core API, UI, reporting, RBAC, and feeds, by editing the `ingress` section in your values file.

Ingress is disabled by default in this Helm chart. To enable it, along with the [NGINX ingress controller](https://kubernetes.github.io/ingress-nginx/) for core API and UI routes, set the `ingress.enabled` value to `true`.

```yaml
ingress:
  enabled: true
```

#### ALB Ingress Controller

The [Kubernetes ALB ingress controller](https://docs.aws.amazon.com/eks/latest/userguide/alb-ingress.html) must be installed into the cluster for this configuration to work.

```yaml
ingress:
  enabled: true
  annotations:
    alb.ingress.kubernetes.io/scheme: internet-facing
  ingressClassName: alb

  hosts:
    - anchore-feeds.example.com

service:
  type: NodePort
```

#### GCE Ingress Controller

The [Kubernetes GCE ingress controller](https://cloud.google.com/kubernetes-engine/docs/concepts/ingress) must be installed into the cluster for this configuration to work.

```yaml
ingress:
  enabled: true
  ingressClassName: gce
  paths:
    - /v1/feeds/*
    - /v2/feeds/*

  hosts:
    - anchore-feeds.example.com

service:
  type: NodePort
```

### Prometheus Metrics

Anchore Enterprise offers native support for exporting Prometheus metrics from each of its containers. When this feature is enabled, each service exposes metrics via its existing service port. If you're adding Prometheus manually to your deployment, you'll need to configure it to recognize each pod and its corresponding ports.

```yaml
anchoreConfig:
  metrics:
    enabled: true
    auth_disabled: true
```

## Parameters

### Common Resource Parameters

| Name                                    | Description                                                                                           | Value                                 |
| --------------------------------------- | ----------------------------------------------------------------------------------------------------- | ------------------------------------- |
| `standalone`                            | Enable running the Anchore Feeds service in standalone mode                                           | `true`                                |
| `url`                                   | Set a custom feeds URL. Useful when using a feeds service endpoint that is external from the cluster. | `""`                                  |
| `fullnameOverride`                      | overrides the fullname set on resources                                                               | `""`                                  |
| `nameOverride`                          | overrides the name set on resources                                                                   | `""`                                  |
| `image`                                 | Image used for feeds deployment                                                                       | `docker.io/anchore/enterprise:v5.7.0` |
| `imagePullPolicy`                       | Image pull policy used by all deployments                                                             | `IfNotPresent`                        |
| `imagePullSecretName`                   | Name of Docker credentials secret for access to private repos                                         | `anchore-enterprise-pullcreds`        |
| `serviceAccountName`                    | Name of a service account used to run all Feeds pods                                                  | `""`                                  |
| `injectSecretsViaEnv`                   | Enable secret injection into pod via environment variables instead of via k8s secrets                 | `false`                               |
| `licenseSecretName`                     | Name of the Kubernetes secret containing your license.yaml file                                       | `anchore-enterprise-license`          |
| `certStoreSecretName`                   | Name of secret containing the certificates & keys used for SSL, SAML & CAs                            | `""`                                  |
| `extraEnv`                              | Common environment variables set on all containers                                                    | `[]`                                  |
| `labels`                                | Common labels set on all Kubernetes resources                                                         | `{}`                                  |
| `annotations`                           | Common annotations set on all Kubernetes resources                                                    | `{}`                                  |
| `resources`                             | Resource requests and limits for Anchore Feeds pods                                                   | `{}`                                  |
| `nodeSelector`                          | Node labels for Anchore Feeds pod assignment                                                          | `{}`                                  |
| `tolerations`                           | Tolerations for Anchore Feeds pod assignment                                                          | `[]`                                  |
| `affinity`                              | Affinity for Anchore Feeds pod assignment                                                             | `{}`                                  |
| `service.type`                          | Service type for Anchore Feeds                                                                        | `ClusterIP`                           |
| `service.port`                          | Service port for Anchore Feeds                                                                        | `8448`                                |
| `service.annotations`                   | Annotations for Anchore Feeds service                                                                 | `{}`                                  |
| `service.labels`                        | Labels for Anchore Feeds service                                                                      | `{}`                                  |
| `service.nodePort`                      | nodePort for Anchore Feeds service                                                                    | `""`                                  |
| `scratchVolume.mountPath`               | The mount path of an external volume for scratch space for image analysis                             | `/anchore_scratch`                    |
| `scratchVolume.fixGroupPermissions`     | Enable an initContainer that will fix the fsGroup permissions                                         | `false`                               |
| `scratchVolume.fixerInitContainerImage` | Set the container image for the permissions fixer init container                                      | `alpine`                              |
| `scratchVolume.details`                 | Details for the k8s volume to be created                                                              | `{}`                                  |
| `persistence.enabled`                   | Enable mounting an external volume for feeds driver workspace                                         | `true`                                |
| `persistence.fixGroupPermissions`       | Enable an initContainer that will fix the fsGroup permissions                                         | `false`                               |
| `persistence.resourcePolicy`            | Resource policy Helm annotation on PVC. Can be nil or "keep"                                          | `keep`                                |
| `persistence.existingClaim`             | Specify an existing volume claim                                                                      | `""`                                  |
| `persistence.storageClass`              | Persistent volume storage class                                                                       | `""`                                  |
| `persistence.accessMode`                | Access Mode for persistent volume                                                                     | `ReadWriteOnce`                       |
| `persistence.size`                      | Size of persistent volume                                                                             | `40Gi`                                |
| `persistence.mountPath`                 | Mount path on Anchore Feeds container for persistent volume                                           | `/workspace`                          |
| `persistence.subPath`                   | Directory name used for persistent volume storage                                                     | `feeds-workspace`                     |
| `persistence.annotations`               | Annotations for PVC                                                                                   | `{}`                                  |
| `extraVolumes`                          | mounts additional volumes to each pod                                                                 | `[]`                                  |
| `extraVolumeMounts`                     | mounts additional volumes to each pod                                                                 | `[]`                                  |
| `securityContext.runAsUser`             | The securityContext runAsUser for all Feeds pods                                                      | `1000`                                |
| `securityContext.runAsGroup`            | The securityContext runAsGroup for all Feeds pods                                                     | `1000`                                |
| `securityContext.fsGroup`               | The securityContext fsGroup for all Feeds pods                                                        | `1000`                                |
| `containerSecurityContext`              | The securityContext for all Feeds containers                                                          | `{}`                                  |
| `probes.liveness.initialDelaySeconds`   | Initial delay seconds for liveness probe                                                              | `120`                                 |
| `probes.liveness.timeoutSeconds`        | Timeout seconds for liveness probe                                                                    | `10`                                  |
| `probes.liveness.periodSeconds`         | Period seconds for liveness probe                                                                     | `10`                                  |
| `probes.liveness.failureThreshold`      | Failure threshold for liveness probe                                                                  | `6`                                   |
| `probes.liveness.successThreshold`      | Success threshold for liveness probe                                                                  | `1`                                   |
| `probes.readiness.timeoutSeconds`       | Timeout seconds for the readiness probe                                                               | `10`                                  |
| `probes.readiness.periodSeconds`        | Period seconds for the readiness probe                                                                | `10`                                  |
| `probes.readiness.failureThreshold`     | Failure threshold for the readiness probe                                                             | `3`                                   |
| `probes.readiness.successThreshold`     | Success threshold for the readiness probe                                                             | `1`                                   |
| `doSourceAtEntry.enabled`               | Does a `source` of the file paths defined before starting Anchore services                            | `false`                               |
| `doSourceAtEntry.filePaths`             | List of file paths to `source` before starting Anchore services                                       | `[]`                                  |
| `useExistingSecrets`                    | forgoes secret creation and uses the secret defined in existingSecretName                             | `false`                               |
| `existingSecretName`                    | Name of the existing secret to be used for Anchore Feeds Service                                      | `anchore-enterprise-feeds-env`        |
| `configOverride`                        | Allows for overriding the default Anchore configuration file                                          | `{}`                                  |
| `scripts`                               | Collection of helper scripts usable in all anchore enterprise pods                                    | `{}`                                  |

### Anchore Feeds Configuration Parameters

| Name                                                                       | Description                                                                                                                      | Value                                                                                                                                 |
| -------------------------------------------------------------------------- | -------------------------------------------------------------------------------------------------------------------------------- | ------------------------------------------------------------------------------------------------------------------------------------- |
| `anchoreConfig.service_dir`                                                | Path to directory where default Anchore configs are placed at startup                                                            | `/anchore_service`                                                                                                                    |
| `anchoreConfig.log_level`                                                  | The log level for Anchore services: NOTE: This is deprecated, use logging.log_level                                              | `INFO`                                                                                                                                |
| `anchoreConfig.logging.colored_logging`                                    | Enable colored output in the logs                                                                                                | `false`                                                                                                                               |
| `anchoreConfig.logging.exception_backtrace_logging`                        | Enable stack traces in the logs                                                                                                  | `false`                                                                                                                               |
| `anchoreConfig.logging.exception_diagnose_logging`                         | Enable detailed exception information in the logs                                                                                | `false`                                                                                                                               |
| `anchoreConfig.logging.file_rotation_rule`                                 | Maximum size of a log file before it is rotated                                                                                  | `10 MB`                                                                                                                               |
| `anchoreConfig.logging.file_retention_rule`                                | Number of log files to retain before deleting the oldest                                                                         | `10`                                                                                                                                  |
| `anchoreConfig.logging.log_level`                                          | Log level for the service code                                                                                                   | `INFO`                                                                                                                                |
| `anchoreConfig.logging.server_access_logging`                              | Set whether to print server access to logging                                                                                    | `true`                                                                                                                                |
| `anchoreConfig.logging.server_response_debug_logging`                      | Log the elapsed time to process the request and the response size (debug log level)                                              | `false`                                                                                                                               |
| `anchoreConfig.logging.server_log_level`                                   | Log level specifically for the server (uvicorn)                                                                                  | `info`                                                                                                                                |
| `anchoreConfig.logging.structured_logging`                                 | Enable structured logging output (JSON)                                                                                          | `false`                                                                                                                               |
| `anchoreConfig.server.max_connection_backlog`                              | Max connections permitted in the backlog before dropping                                                                         | `2048`                                                                                                                                |
| `anchoreConfig.server.max_wsgi_middleware_worker_queue_size`               | Max number of requests to queue for processing by ASGI2WSGI middleware                                                           | `100`                                                                                                                                 |
| `anchoreConfig.server.max_wsgi_middleware_worker_count`                    | Max number of workers to have in the ASGI2WSGI middleware worker pool                                                            | `50`                                                                                                                                  |
| `anchoreConfig.server.timeout_graceful_shutdown`                           | Seconds to permit for graceful shutdown or false to disable                                                                      | `false`                                                                                                                               |
| `anchoreConfig.server.timeout_keep_alive`                                  | Seconds to keep a connection alive before closing                                                                                | `5`                                                                                                                                   |
| `anchoreConfig.keys.secret`                                                | The shared secret used for signing & encryption, auto-generated by Helm if not set                                               | `""`                                                                                                                                  |
| `anchoreConfig.keys.privateKeyFileName`                                    | The file name of the private key used for signing & encryption, found in the k8s secret specified in .Values.certStoreSecretName | `""`                                                                                                                                  |
| `anchoreConfig.keys.publicKeyFileName`                                     | The file name of the public key used for signing & encryption, found in the k8s secret specified in .Values.certStoreSecretName  | `""`                                                                                                                                  |
| `anchoreConfig.user_authentication.oauth.enabled`                          | Enable OAuth for Anchore user authentication                                                                                     | `false`                                                                                                                               |
| `anchoreConfig.user_authentication.oauth.default_token_expiration_seconds` | The expiration, in seconds, for OAuth tokens                                                                                     | `3600`                                                                                                                                |
| `anchoreConfig.user_authentication.oauth.refresh_token_expiration_seconds` | The expiration, in seconds, for OAuth refresh tokens                                                                             | `86400`                                                                                                                               |
| `anchoreConfig.user_authentication.hashed_passwords`                       | Enable storing passwords as secure hashes in the database                                                                        | `false`                                                                                                                               |
| `anchoreConfig.user_authentication.sso_require_existing_users`             | set to true in order to disable the SSO JIT provisioning during authentication                                                   | `false`                                                                                                                               |
| `anchoreConfig.metrics.enabled`                                            | Enable Prometheus metrics for all Anchore services                                                                               | `false`                                                                                                                               |
| `anchoreConfig.metrics.auth_disabled`                                      | Disable auth on Prometheus metrics for all Anchore services                                                                      | `false`                                                                                                                               |
| `anchoreConfig.database.timeout`                                           |                                                                                                                                  | `120`                                                                                                                                 |
| `anchoreConfig.database.ssl`                                               | Enable SSL/TLS for the database connection                                                                                       | `false`                                                                                                                               |
| `anchoreConfig.database.sslMode`                                           | The SSL mode to use for database connection                                                                                      | `require`                                                                                                                             |
| `anchoreConfig.database.sslRootCertFileName`                               | File name of the database root CA certificate stored in the k8s secret specified with .Values.certStoreSecretName                | `""`                                                                                                                                  |
| `anchoreConfig.database.db_pool_size`                                      | The database max connection pool size                                                                                            | `30`                                                                                                                                  |
| `anchoreConfig.database.db_pool_max_overflow`                              | The maximum overflow size of the database connection pool                                                                        | `100`                                                                                                                                 |
| `anchoreConfig.database.engineArgs`                                        | Set custom database engine arguments for SQLAlchemy                                                                              | `{}`                                                                                                                                  |
| `anchoreConfig.internalServicesSSL.enabled`                                | Force all Enterprise services to use SSL for internal communication                                                              | `false`                                                                                                                               |
| `anchoreConfig.internalServicesSSL.verifyCerts`                            | Enable cert verification against the local cert bundle, if this set to false self-signed certs are allowed                       | `false`                                                                                                                               |
| `anchoreConfig.internalServicesSSL.certSecretKeyFileName`                  | File name of the private key used for internal SSL stored in the secret specified in .Values.certStoreSecretName                 | `""`                                                                                                                                  |
| `anchoreConfig.internalServicesSSL.certSecretCertFileName`                 | File name of the root CA certificate used for internal SSL stored in the secret specified in .Values.certStoreSecretName         | `""`                                                                                                                                  |
| `anchoreConfig.feeds.cycle_timers.driver_sync`                             | Time delay in seconds between consecutive driver runs for processing data                                                        | `7200`                                                                                                                                |
| `anchoreConfig.feeds.drivers.debian.releases`                              | Additional Debian feeds groups                                                                                                   | `{}`                                                                                                                                  |
| `anchoreConfig.feeds.drivers.ubuntu.releases`                              | Additional Ubuntu feed groups                                                                                                    | `{}`                                                                                                                                  |
| `anchoreConfig.feeds.drivers.npm.enabled`                                  | Enable vulnerability drivers for npm data                                                                                        | `false`                                                                                                                               |
| `anchoreConfig.feeds.drivers.gem.enabled`                                  | Enable vulnerability drivers for gem data                                                                                        | `false`                                                                                                                               |
| `anchoreConfig.feeds.drivers.gem.db_connect`                               | Defines the database endpoint used for loading the rubygems package data as a PostgreSQL dump                                    | `postgresql://${ANCHORE_GEM_DB_USER}:${ANCHORE_GEM_DB_PASSWORD}@${ANCHORE_GEM_DB_HOST}:${ANCHORE_GEM_DB_PORT}/${ANCHORE_GEM_DB_NAME}` |
| `anchoreConfig.feeds.drivers.nvdv2.api_key`                                | The NVD API key value                                                                                                            | `""`                                                                                                                                  |
| `anchoreConfig.feeds.drivers.msrc.enabled`                                 | Enable Microsoft feeds                                                                                                           | `false`                                                                                                                               |
| `anchoreConfig.feeds.drivers.msrc.whitelist`                               | MSRC product IDs for generating feed data, this extends the pre-defined list of product IDs                                      | `[]`                                                                                                                                  |
| `anchoreConfig.feeds.drivers.github.enabled`                               | Enable GitHub advisory feeds (requires GitHub PAT)                                                                               | `false`                                                                                                                               |
| `anchoreConfig.feeds.drivers.github.token`                                 | GitHub developer personal access token with zero permission scopes                                                               | `""`                                                                                                                                  |

### Anchore Feeds Database Parameters

| Name                                        | Description                                                                                       | Value                   |
| ------------------------------------------- | ------------------------------------------------------------------------------------------------- | ----------------------- |
| `feeds-db.chartEnabled`                     | Use the dependent chart for Feeds Postgresql deployment                                           | `true`                  |
| `feeds-db.externalEndpoint`                 | External Feeds Postgresql hostname when not using Helm managed chart (eg. mypostgres.myserver.io) | `""`                    |
| `feeds-db.auth.username`                    | Username used to connect to Postgresql                                                            | `anchore-feeds`         |
| `feeds-db.auth.password`                    | Password used to connect to Postgresql                                                            | `anchore-postgres,123`  |
| `feeds-db.auth.database`                    | Database name used when connecting to Postgresql                                                  | `anchore-feeds`         |
| `feeds-db.primary.service.ports.postgresql` | Port used to connect to Postgresql                                                                | `5432`                  |
| `feeds-db.primary.persistence.size`         | Configure size of the persistent volume used with helm managed chart                              | `20Gi`                  |
| `feeds-db.primary.extraEnvVars`             | An array to add extra environment variables                                                       | `[]`                    |
| `feeds-db.image.tag`                        | Specifies the image to use for this chart.                                                        | `13.11.0-debian-11-r15` |

### Feeds Gem Database Parameters

| Name                                      | Description                                                                                 | Value                   |
| ----------------------------------------- | ------------------------------------------------------------------------------------------- | ----------------------- |
| `gem-db.chartEnabled`                     | Use the dependent chart for Postgresql deployment                                           |                         |
| `gem-db.externalEndpoint`                 | External Postgresql hostname when not using Helm managed chart (eg. mypostgres.myserver.io) | `""`                    |
| `gem-db.auth.username`                    | Username used to connect to Postgresql                                                      | `anchore-gem-feeds`     |
| `gem-db.auth.password`                    | Password used to connect to Postgresql                                                      | `anchore-postgres,123`  |
| `gem-db.auth.database`                    | Database name used when connecting to Postgresql                                            | `anchore-gem-feeds`     |
| `gem-db.primary.service.ports.postgresql` | Port used to connect to Postgresql                                                          | `5432`                  |
| `gem-db.primary.persistence.size`         | Configure size of the persistent volume used with helm managed chart                        | `20Gi`                  |
| `gem-db.primary.extraEnvVars`             | An array to add extra environment variables                                                 | `[]`                    |
| `gem-db.image.tag`                        | Specifies the image to use for this chart.                                                  | `13.11.0-debian-11-r15` |

### Anchore Feeds Upgrade Job Parameters

| Name                                      | Description                                                                                                                                     | Value                  |
| ----------------------------------------- | ----------------------------------------------------------------------------------------------------------------------------------------------- | ---------------------- |
| `feedsUpgradeJob.enabled`                 | Enable the Anchore Feeds database upgrade job                                                                                                   | `true`                 |
| `feedsUpgradeJob.force`                   | Force the Anchore Feeds database upgrade job to run as a regular job instead of as a Helm hook                                                  | `false`                |
| `feedsUpgradeJob.rbacCreate`              | Create RBAC resources for the upgrade job                                                                                                       | `true`                 |
| `feedsUpgradeJob.serviceAccountName`      | Use an existing service account for the upgrade job                                                                                             | `""`                   |
| `feedsUpgradeJob.usePostUpgradeHook`      | Use a Helm post-upgrade hook to run the upgrade job instead of the default pre-upgrade hook. This job does not require creating RBAC resources. | `false`                |
| `feedsUpgradeJob.kubectlImage`            | The image to use for the upgrade job's init container that uses kubectl to scale down deployments before an upgrade                             | `bitnami/kubectl:1.27` |
| `feedsUpgradeJob.nodeSelector`            | Node labels for the Anchore Feeds upgrade job pod assignment                                                                                    | `{}`                   |
| `feedsUpgradeJob.tolerations`             | Tolerations for the Anchore Feeds upgrade job pod assignment                                                                                    | `[]`                   |
| `feedsUpgradeJob.affinity`                | Affinity for the Anchore Feeds upgrade job pod assignment                                                                                       | `{}`                   |
| `feedsUpgradeJob.annotations`             | Annotations for the Anchore Feeds upgrade job                                                                                                   | `{}`                   |
| `feedsUpgradeJob.labels`                  | Labels for the Anchore Feeds upgrade job                                                                                                        | `{}`                   |
| `feedsUpgradeJob.resources`               | Resources for the Anchore Feeds upgrade job                                                                                                     | `{}`                   |
| `feedsUpgradeJob.ttlSecondsAfterFinished` | The time period in seconds the upgrade job, and it's related pods should be retained for                                                        | `-1`                   |

### Ingress Parameters

| Name                       | Description                                                        | Value            |
| -------------------------- | ------------------------------------------------------------------ | ---------------- |
| `ingress.enabled`          | Create an ingress resource for external Anchore service APIs       | `false`          |
| `ingress.labels`           | Labels for the ingress resource                                    | `{}`             |
| `ingress.annotations`      | Annotations for the ingress resource                               | `{}`             |
| `ingress.hosts`            | List of custom hostnames for the Anchore Feeds API                 | `[]`             |
| `ingress.paths`            | The path used for accessing the Anchore Feeds API                  | `["/v2/feeds/"]` |
| `ingress.tls`              | Configure tls for the ingress resource                             | `[]`             |
| `ingress.ingressClassName` | sets the ingress class name. As of k8s v1.18, this should be nginx | `nginx`          |

### Google CloudSQL DB Parameters

| Name                             | Description                                                                    | Value                                     |
| -------------------------------- | ------------------------------------------------------------------------------ | ----------------------------------------- |
| `cloudsql.enabled`               | Use CloudSQL proxy container for GCP database access                           | `false`                                   |
| `cloudsql.image`                 | Image to use for GCE CloudSQL Proxy                                            | `gcr.io/cloudsql-docker/gce-proxy:1.25.0` |
| `cloudsql.imagePullPolicy`       | Image Pull Policy to use for CloudSQL image                                    | `IfNotPresent`                            |
| `cloudsql.instance`              | CloudSQL instance, eg: 'project:zone:instancename'                             | `""`                                      |
| `cloudsql.useExistingServiceAcc` | Use existing service account                                                   | `false`                                   |
| `cloudsql.serviceAccSecretName`  |                                                                                | `""`                                      |
| `cloudsql.serviceAccJsonName`    |                                                                                | `""`                                      |
| `cloudsql.extraArgs`             | a list of extra arguments to be passed into the cloudsql container command. eg | `[]`                                      |


## Release Notes

For the latest updates and features in Anchore Enterprise, see the official [Release Notes](https://docs.anchore.com/current/docs/releasenotes/).

- **Major Chart Version Change (e.g., v0.1.2 -> v1.0.0)**: Signifies an incompatible breaking change that necessitates manual intervention, such as updates to your values file or data migrations.
- **Minor Chart Version Change (e.g., v0.1.2 -> v0.2.0)**: Indicates a significant change to the deployment that does not require manual intervention.
- **Patch Chart Version Change (e.g., v0.1.2 -> v0.1.3)**: Indicates a backwards-compatible bug fix or documentation update.

### v2.7.x

- Update Anchore Feeds image to v5.7.0. See the [Release Notes](https://docs.anchore.com/current/docs/releasenotes/570/) for more information.

### v2.6.x

- Update Anchore Feeds image to v5.6.0. See the [Release Notes](https://docs.anchore.com/current/docs/releasenotes/560/) for more information.

### v2.5.x

- Update Anchore Feeds image to v5.5.0. See the [Release Notes](https://docs.anchore.com/current/docs/releasenotes/550/) for more information.
- Added support for service specific annotations.

### v2.4.0

- Update Anchore Feeds image to v5.4.0. See the [Release Notes](https://docs.anchore.com/current/docs/releasenotes/540/) for more information.

### v2.3.0

- Update Anchore Feeds image to v5.3.0. See the [Release Notes](https://docs.anchore.com/current/docs/releasenotes/530/) for more information.
- Bump kubeVersion requirement to allow deployment on Kubernetes v1.29.x clusters.

### v2.2.0

- Update Anchore Feeds image to v5.2.0. See the [Release Notes](https://docs.anchore.com/current/docs/releasenotes/520/) for more information.
- Removes the `null` value from the default `ANCHORE_GITHUB_TOKEN` environment variable in the `anchore-enterprise-feeds-env` secret. This was causing issues with all feeds drivers if a token was not provided.

### v2.1.0

- Update Anchore Feeds image to v5.1.0. See the [Release Notes](https://docs.anchore.com/current/docs/releasenotes/510/) for more information.

### v2.0.0

- Updated Anchore Feeds image to v5.0.0
- Anchore Feeds v5.0.0 introduces a breaking change to the API endpoints, and requires updating any external integrations to use the new endpoints. See the [Migration Guide](https://docs.anchore.com/current/docs/migration_guide/) for more information.
- The following values were removed as only the `v2` API is supported in Anchore Feeds 5.0.0:
  - `feeds.service.apiVersion`

### v1.0.0

- This is a stable release of the Anchore Feeds Helm chart and is recommended for production deployments.
- Deploys Anchore Feeds v4.9.3.

### v0.x.x

- This is a pre-release version of the Anchore Enterprise Helm chart and is not recommended for production deployments.
