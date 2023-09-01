# Anchore Enterprise Feeds Helm Chart

This Helm chart deploys the Anchore Enterprise Feeds service on a [Kubernetes](http://kubernetes.io) cluster using the [Helm](https://helm.sh) package manager.

Anchore Enterprise Feeds is an On-Premises service that supplies operating system and non-operating system vulnerability data and package data for consumption by Anchore Policy Engine. Policy Engine uses this data for finding vulnerabilities and evaluating policies.

See the [Anchore Feeds Documentation](https://docs.anchore.com/current/docs/overview/feeds/) for more details.

## Table of Contents

- [Prerequisites](#prerequisites)
- [Installing the Chart](#installing-the-chart)
- [Uninstalling the Chart](#uninstalling-the-chart)
- [Configuration](#configuration)
  - [Feeds External Database Configuration](#feeds-external-database-configuration)
  - [Feeds Driver Configuration](#feeds-driver-configuration)
  - [Existing Secrets](#existing-secrets)
  - [Ingress](#ingress)
  - [Installing on Openshift](#installing-on-openshift)
- [Parameters](#parameters)
- [Release Notes](#release-notes)

## Prerequisites

* [Helm](https://helm.sh/) >=3.8
* [Kubernetes](https://kubernetes.io/) >=1.23

## Installing the Chart

**View the [Chart Release Notes](#release-notes) for the latest changes prior to installation or upgrading.**

Create a kubernetes secret containing your license file

```shell
export LICENSE_PATH="PATH TO LICENSE.YAML"

kubectl create secret generic anchore-enterprise-license --from-file=license.yaml=${LICENSE_PATH}
```

Create a kubernetes secret containing DockerHub credentials with access to the private Anchore Enterprise repositories. Contact [Anchore Support](https://get.anchore.com/contact/) for access.

```shell
export DOCKERHUB_PASSWORD="YOUR DOCKERHUB PASSWORD"
export DOCKERHUB_USER="YOUR DOCKERHUB USERNAME"
export DOCKERHUB_EMAIL="YOUR EMAIL ADDRESS"

kubectl create secret docker-registry anchore-enterprise-pullcreds --docker-server=docker.io --docker-username=${DOCKERHUB_USER} --docker-password=${DOCKERHUB_PASSWORD} --docker-email=${DOCKERHUB_EMAIL}
```

Add Helm Chart Repository And Install Chart

```shell
helm repo add anchore https://charts.anchore.io
```

Create a new file named `anchore_values.yaml` and add all desired custom [values](#parameters); then run the following command:

```shell
export RELEASE="YOUR RELEASE NAME"

helm install ${RELEASE} -f anchore_values.yaml anchore/feeds
```

> **Note:** This installs Anchore Feeds with a chart-managed Postgresql database, which may not be a production ready configuration.

> **Tip**: List all releases using `helm list`

These commands deploy the Anchore Enterprise Feeds service on the Kubernetes cluster with default configuration. The [Parameters](#parameters) section lists the parameters that can be configured during installation.

## Uninstalling the Chart

To uninstall/delete the deployment:

```bash
export RELEASE="YOUR RELEASE NAME"

helm delete ${RELEASE}
```

The command removes all the Kubernetes components associated with the chart and deletes the release.

## Configuration

The following sections describe the various configuration options available for Anchore Enterprise. The default configuration is set in the included [values file](https://github.com/anchore/anchore-charts-dev/blob/main/stable/enterprise/values.yaml). To override these values, create a custom `anchore_values.yaml` file and add the desired configuration options. You custom values file can be passed to `helm install` using the `-f` flag.

Contact [Anchore Support](get.anchore.com/contact/) for more assistance with configuring your deployment.

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

For deployment scenarios that require version-controlled configuration to be used, it is recommended that credentials not be stored in values files. To accomplish this, you can manually create Kubernetes secrets and specify them as existing secrets in your values files.

Below we show example Kubernetes secret objects, and how they would be used in Anchore Enterprise configuration.

```yaml
apiVersion: v1
kind: Secret
metadata:
  name: anchore-enterprise-feeds-env
    app: anchore
type: Opaque
stringData:
  ANCHORE_ADMIN_PASSWORD: "<ADMIN_PASS>"
  ANCHORE_FEEDS_DB_PASSWORD: "<FEEDS_DB_PASS>"
```

```yaml
useExistingSecrets: true
```

### Ingress

[Ingress](https://kubernetes.io/docs/concepts/services-networking/ingress/) exposes HTTP and HTTPS routes from outside the cluster to services within the cluster. Traffic routing is controlled by rules defined on the Ingress resource. Kubernetes supports a variety of ingress controllers, including AWS ALB controllers and GCE controllers.

This Helm chart provides basic ingress configuration suitable for customization. You can expose routes for Anchore Feeds APIs by configuring the `ingress:` section in your values file.

Ingress is disabled by default in the Helm chart. The NGINX ingress controller with the core API and UI routes can be enabled by changing the `ingress.enabled` value to `true`.

Note that the [Kubernetes NGINX ingress controller](https://kubernetes.github.io/ingress-nginx/) must be installed into the cluster for this configuration to work.

```yaml
ingress:
  enabled: true
```

### Installing on Openshift

By default, we assign the `securityContext.fsGroup`, `securityContext.runAsGroup`, and `securityContext.runAsUser` to `1000`. This will most likely fail on openshift for not being in the range determined by the `openshift.io/sa.scc.uid-range` annotation openshift attaches to the namespace when created. If using the chartEnabled postgresql, postgres will fail to come up as well due to this reason.

1. Either disable the securityContext or set the appropriate values.
2. If using the chartEnabled postgres, you will also need to either disable the feeds-db.primary.podSecurityContext and feeds-db.primary.containerSecurityContext, or set the appropriate values for them

Note: disabling the containerSecurityContext and podSecurityContext may not be suitable for production. See [Redhat's documentation](https://docs.openshift.com/container-platform/4.13/authentication/managing-security-context-constraints.html#managing-pod-security-policies) on what may be suitable for production.

For more information on the openshift.io/sa.scc.uid-range annotation, see the [openshift docs](https://docs.openshift.com/dedicated/authentication/managing-security-context-constraints.html#security-context-constraints-pre-allocated-values_configuring-internal-oauth)

```shell
helm install feedsy anchore/feeds \
  --set securityContext.fsGroup=null \
  --set securityContext.runAsGroup=null \
  --set securityContext.runAsUser=null \
  --set feeds-db.primary.containerSecurityContext.enabled=false \
  --set feeds-db.primary.podSecurityContext.enabled=false
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
```

## Parameters

### Common Resource Parameters

| Name                                  | Description                                                                                                                       | Value                                 |
| ------------------------------------- | --------------------------------------------------------------------------------------------------------------------------------- | ------------------------------------- |
| `standalone`                          | Enable running the Anchore Feeds service in standalone mode                                                                       | `true`                                |
| `enterpriseFullname`                  | set the fullname on enterprise resources. Only needed when standalone=false and fullnameOverride is set for the enterprise chart. | `""`                                  |
| `fullnameOverride`                    | overrides the fullname set on resources                                                                                           | `""`                                  |
| `nameOverride`                        | overrides the name set on resources                                                                                               | `""`                                  |
| `image`                               | Image used for feeds deployment                                                                                                   | `docker.io/anchore/enterprise:v4.9.0` |
| `imagePullPolicy`                     | Image pull policy used by all deployments                                                                                         | `IfNotPresent`                        |
| `imagePullSecretName`                 | Name of Docker credentials secret for access to private repos                                                                     | `anchore-enterprise-pullcreds`        |
| `serviceAccountName`                  | Name of a service account used to run all Feeds pods                                                                              | `""`                                  |
| `injectSecretsViaEnv`                 | Enable secret injection into pod via environment variables instead of via k8s secrets                                             | `false`                               |
| `licenseSecretName`                   | Name of the Kubernetes secret containing your license.yaml file                                                                   | `anchore-enterprise-license`          |
| `certStoreSecretName`                 | Name of secret containing the certificates & keys used for SSL, SAML & CAs                                                        | `""`                                  |
| `extraEnv`                            | Common environment variables set on all containers                                                                                | `[]`                                  |
| `labels`                              | Common labels set on all Kubernetes resources                                                                                     | `{}`                                  |
| `annotations`                         | Common annotations set on all Kubernetes resources                                                                                | `{}`                                  |
| `resources`                           | Resource requests and limits for Anchore Feeds pods                                                                               | `{}`                                  |
| `nodeSelector`                        | Node labels for Anchore Feeds pod assignment                                                                                      | `{}`                                  |
| `tolerations`                         | Tolerations for Anchore Feeds pod assignment                                                                                      | `[]`                                  |
| `affinity`                            | Affinity for Anchore Feeds pod assignment                                                                                         | `{}`                                  |
| `service.type`                        | Service type for Anchore Feeds                                                                                                    | `ClusterIP`                           |
| `service.port`                        | Service port for Anchore Feeds                                                                                                    | `8448`                                |
| `service.annotations`                 | Annotations for Anchore Feeds service                                                                                             | `{}`                                  |
| `service.labels`                      | Labels for Anchore Feeds service                                                                                                  | `{}`                                  |
| `scratchVolume.mountPath`             | The mount path of an external volume for scratch space for image analysis                                                         | `/anchore_scratch`                    |
| `scratchVolume.fixGroupPermissions`   | Enable an initContainer that will fix the fsGroup permissions                                                                     | `false`                               |
| `scratchVolume.details`               | Details for the k8s volume to be created                                                                                          | `{}`                                  |
| `persistence.enabled`                 | Enable mounting an external volume for feeds driver workspace                                                                     | `true`                                |
| `persistence.resourcePolicy`          | Resource policy Helm annotation on PVC. Can be nil or "keep"                                                                      | `keep`                                |
| `persistence.existingClaim`           | Specify an existing volume claim                                                                                                  | `""`                                  |
| `persistence.storageClass`            | Persistent volume storage class                                                                                                   | `""`                                  |
| `persistence.accessMode`              | Access Mode for persistent volume                                                                                                 | `ReadWriteOnce`                       |
| `persistence.size`                    | Size of persistent volume                                                                                                         | `40Gi`                                |
| `persistence.mountPath`               | Mount path on Anchore Feeds container for persistent volume                                                                       | `/workspace`                          |
| `persistence.subPath`                 | Directory name used for persistent volume storage                                                                                 | `feeds-workspace`                     |
| `persistence.annotations`             | Annotations for PVC                                                                                                               | `{}`                                  |
| `extraVolumes`                        | mounts additional volumes to each pod                                                                                             | `[]`                                  |
| `extraVolumeMounts`                   | mounts additional volumes to each pod                                                                                             | `[]`                                  |
| `securityContext.runAsUser`           | The securityContext runAsUser for all Feeds pods                                                                                  | `1000`                                |
| `securityContext.runAsGroup`          | The securityContext runAsGroup for all Feeds pods                                                                                 | `1000`                                |
| `securityContext.fsGroup`             | The securityContext fsGroup for all Feeds pods                                                                                    | `1000`                                |
| `containerSecurityContext`            | The securityContext for all Feeds containers                                                                                      | `{}`                                  |
| `probes.liveness.initialDelaySeconds` | Initial delay seconds for liveness probe                                                                                          | `120`                                 |
| `probes.liveness.timeoutSeconds`      | Timeout seconds for liveness probe                                                                                                | `10`                                  |
| `probes.liveness.periodSeconds`       | Period seconds for liveness probe                                                                                                 | `10`                                  |
| `probes.liveness.failureThreshold`    | Failure threshold for liveness probe                                                                                              | `6`                                   |
| `probes.liveness.successThreshold`    | Success threshold for liveness probe                                                                                              | `1`                                   |
| `probes.readiness.timeoutSeconds`     | Timeout seconds for the readiness probe                                                                                           | `10`                                  |
| `probes.readiness.periodSeconds`      | Period seconds for the readiness probe                                                                                            | `10`                                  |
| `probes.readiness.failureThreshold`   | Failure threshold for the readiness probe                                                                                         | `3`                                   |
| `probes.readiness.successThreshold`   | Success threshold for the readiness probe                                                                                         | `1`                                   |
| `doSourceAtEntry.enabled`             | Does a `source` of the file paths defined before starting Anchore services                                                        | `false`                               |
| `doSourceAtEntry.filePaths`           | List of file paths to `source` before starting Anchore services                                                                   | `[]`                                  |
| `useExistingSecrets`                  | forgoes secret creation and uses the secret defined in existingSecretName                                                         | `false`                               |
| `existingSecretName`                  | Name of the existing secret to be used for Anchore Feeds Service                                                                  | `anchore-enterprise-feeds-env`        |
| `configOverride`                      | Allows for overriding the default Anchore configuration file                                                                      | `{}`                                  |


### Anchore Feeds Configuration Parameters

| Name                                                                       | Description                                                                                                                      | Value                                                                                                                                 |
| -------------------------------------------------------------------------- | -------------------------------------------------------------------------------------------------------------------------------- | ------------------------------------------------------------------------------------------------------------------------------------- |
| `anchoreConfig.service_dir`                                                | Path to directory where default Anchore configs are placed at startup                                                            | `/anchore_service`                                                                                                                    |
| `anchoreConfig.log_level`                                                  | The log level for Anchore services                                                                                               | `INFO`                                                                                                                                |
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
| `anchoreConfig.feeds.drivers.nvdv2.api_key`                                | The NVD API key value                                                                                                            | `nil`                                                                                                                                 |
| `anchoreConfig.feeds.drivers.msrc.enabled`                                 | Enable Microsoft feeds                                                                                                           | `false`                                                                                                                               |
| `anchoreConfig.feeds.drivers.msrc.whitelist`                               | MSRC product IDs for generating feed data, this extends the pre-defined list of product IDs                                      | `[]`                                                                                                                                  |
| `anchoreConfig.feeds.drivers.github.enabled`                               | Enable GitHub advisory feeds (requires GitHub PAT)                                                                               | `false`                                                                                                                               |
| `anchoreConfig.feeds.drivers.github.token`                                 | GitHub developer personal access token with zero permission scopes                                                               | `nil`                                                                                                                                 |


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
| `gem-db.chartEnabled`                     | Use the dependent chart for Postgresql deployment                                           | `false`                 |
| `gem-db.externalEndpoint`                 | External Postgresql hostname when not using Helm managed chart (eg. mypostgres.myserver.io) | `""`                    |
| `gem-db.auth.username`                    | Username used to connect to Postgresql                                                      | `anchore-gem-feeds`     |
| `gem-db.auth.password`                    | Password used to connect to Postgresql                                                      | `anchore-postgres,123`  |
| `gem-db.auth.database`                    | Database name used when connecting to Postgresql                                            | `anchore-gem-feeds`     |
| `gem-db.primary.service.ports.postgresql` | Port used to connect to Postgresql                                                          | `5432`                  |
| `gem-db.primary.persistence.size`         | Configure size of the persistent volume used with helm managed chart                        | `20Gi`                  |
| `gem-db.primary.extraEnvVars`             | An array to add extra environment variables                                                 | `[]`                    |
| `gem-db.image.tag`                        | Specifies the image to use for this chart.                                                  | `13.11.0-debian-11-r15` |


### Anchore Feeds Upgrade Job Parameters

| Name                                 | Description                                                                                                                                     | Value   |
| ------------------------------------ | ----------------------------------------------------------------------------------------------------------------------------------------------- | ------- |
| `feedsUpgradeJob.enabled`            | Enable the Anchore Feeds database upgrade job                                                                                                   | `true`  |
| `feedsUpgradeJob.force`              | Force the Anchore Feeds database upgrade job to run as a regular job instead of as a Helm hook                                                  | `false` |
| `feedsUpgradeJob.rbacCreate`         | Create RBAC resources for the upgrade job                                                                                                       | `true`  |
| `feedsUpgradeJob.serviceAccountName` | Use an existing service account for the upgrade job                                                                                             | `""`    |
| `feedsUpgradeJob.usePostUpgradeHook` | Use a Helm post-upgrade hook to run the upgrade job instead of the default pre-upgrade hook. This job does not require creating RBAC resources. | `false` |
| `feedsUpgradeJob.nodeSelector`       | Node labels for the Anchore Feeds upgrade job pod assignment                                                                                    | `{}`    |
| `feedsUpgradeJob.tolerations`        | Tolerations for the Anchore Feeds upgrade job pod assignment                                                                                    | `[]`    |
| `feedsUpgradeJob.affinity`           | Affinity for the Anchore Feeds upgrade job pod assignment                                                                                       | `{}`    |
| `feedsUpgradeJob.annotations`        | Annotations for the Anchore Feeds upgrade job                                                                                                   | `{}`    |
| `feedsUpgradeJob.labels`             | Labels for the Anchore Feeds upgrade job                                                                                                        | `{}`    |
| `feedsUpgradeJob.resources`          | Resources for the Anchore Feeds upgrade job                                                                                                     | `{}`    |


### Ingress Parameters

| Name                       | Description                                                        | Value       |
| -------------------------- | ------------------------------------------------------------------ | ----------- |
| `ingress.enabled`          | Create an ingress resource for external Anchore service APIs       | `false`     |
| `ingress.labels`           | Labels for the ingress resource                                    | `{}`        |
| `ingress.annotations`      | Annotations for the ingress resource                               | `{}`        |
| `ingress.hosts`            | List of custom hostnames for the Anchore Feeds API                 | `[]`        |
| `ingress.path`             | The path used for accessing the Anchore Feeds API                  | `/v1/feeds` |
| `ingress.tls`              | Configure tls for the ingress resource                             | `[]`        |
| `ingress.ingressClassName` | sets the ingress class name. As of k8s v1.18, this should be nginx | `nginx`     |


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

A major chart version change (v0.1.2 -> v1.0.0) indicates that there is an **incompatible breaking change needing manual actions.**

A minor chart version change (v0.1.2 -> v0.2.0) indicates a change that **may require updates to your values file.**

### v0.0.1

* This is a pre-release version of the Anchore Enterprise Helm chart. It is not intended for production use.
