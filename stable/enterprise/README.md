# Anchore Enterprise Helm Chart

This Helm chart deploys Anchore Enterprise on a [Kubernetes](http://kubernetes.io) cluster using the [Helm](https://helm.sh) package manager.

Anchore Enterprise is an software bill of materials (SBOM) - powered software supply chain management solution designed for a cloud-native world. It provides continuous visibility into supply chain security risks. Anchore Enterprise takes a developer-friendly approach that minimizes friction by embedding automation into development toolchains to generate SBOMs and accurately identify vulnerabilities, malware, misconfigurations, and secrets for faster remediation.

See the [Anchore Enterprise Documentation](https://docs.anchore.com) for more details.

## Table of Contents

- [Prerequisites](#prerequisites)
- [Installing the Chart](#installing-the-chart)
- [Uninstalling the Chart](#uninstalling-the-chart)
- [Configuration](#configuration)
  - [External Database Setup](#external-database-setup)
  - [Enterprise Feeds Configuration](#enterprise-feeds-configuration)
  - [Analyzer Image Layer Cache Configuration](#analyzer-image-layer-cache-configuration)
  - [Configuring Object Storage](#configuring-object-storage)
  - [Configuring Analysis Archive Storage](#configuring-analysis-archive-storage)
  - [Existing Secrets](#existing-secrets)
  - [Ingress](#ingress)
  - [Configuring The ALB Ingress Controller](#configuring-the-alb-ingress-controller)
  - [SSO](#sso)
  - [Prometheus Metrics](#prometheus-metrics)
  - [Scaling Individual Services](#scaling-individual-services)
  - [Using TLS Internally](#using-tls-internally)
  - [Anchore Enterprise Notifications](#anchore-enterprise-notifications)
  - [Anchore Enterprise Reports](#anchore-enterprise-reports)
  - [Installing on Openshift](#installing-on-openshift)
- [Parameters](#parameters)
- [Release Notes](#release-notes)

## Prerequisites

* [Helm](https://helm.sh/) >=3.8- [Anchore Enterprise Helm Chart](#anchore-enterprise-helm-chart)
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

> **Note:** Passwords are set to defaults specified in the chart. It is strongly recommended to change passwords from the defaults when deploying.

```shell
export RELEASE="YOUR RELEASE NAME"

helm install ${RELEASE} -f anchore_values.yaml anchore/enterprise
```

> **Note:** This installs Anchore Enterprise with a chart-managed Postgresql database, which may not be a production ready configuration.

Anchore Enterprise will take several minutes to bootstrap. After the initial bootstrap period, Anchore Enterprise will begin a vulnerability feed sync. Until the sync is completed, image analysis will show zero vulnerabilities. **This sync can take multiple hours depending on which feeds are enabled.** The following [anchorectl](https://docs.anchore.com/current/docs/deployment/anchorectl/) command is available to poll and report back when the system is bootstrapped and vulnerability feeds have finished syncing:

```shell
export RELEASE="YOUR RELEASE NAME"

export ANCHORECTL_PASSWORD=$(kubectl get secret "${RELEASE}-enterprise" -o ‘go-template={{index .data “ANCHORE_ADMIN_PASSWORD”}}’ | base64 -D -)

# port forward or set up ingress for anchorectl; example, in another terminal:
# kubectl port-forward svc/${RELEASE}-enterprise-api 8228:8228

anchorectl system wait # anchorectl defaults to the user admin, and to the password ${ANCHORECTL_PASSWORD} automatically if set
```

> **Tip**: List all releases using `helm list`

These commands deploy Anchore Enterprise on the Kubernetes cluster with default configuration. The [Parameters](#parameters) section lists the parameters that can be configured during installation.

## Uninstalling the Chart

To uninstall/delete the deployment:

```bash
export RELEASE="YOUR RELEASE NAME"

helm delete ${RELEASE}
```

The command removes all the Kubernetes components associated with the chart and deletes the release.

## Configuration

The following sections describe the various configuration options available for Anchore Enterprise. The default configuration is set in the included [values file](https://github.com/anchore/anchore-charts-dev/blob/main/stable/enterprise/values.yaml). To override these values, create a custom `anchore_values.yaml` file and add the desired configuration options. Your custom values file can be passed to `helm install` using the `-f` flag.

Contact [Anchore Support](get.anchore.com/contact/) for more assistance with configuring your deployment.

### External Database Setup

Anchore Enterprise requires access to a Postgres-compatible database, version 13 or higher to operate. An external database such as AWS RDS or Google CloudSQL is recommended for production deployments. The Helm chart provides a chart-managed database by default unless otherwise configured.

A minimum of 100GB allocated storage is recommended for images, tags, subscriptions, policies, and other artifacts. The database should be configured for max client connections of at least 2000. This may need to be increased when running more than the default number of Anchore services.

#### External Postgres Database Configuration

```yaml
postgresql:
  chartEnabled: false

  # auth.username, auth.password & auth.database are required values for external Postgres
  auth.password: <PASSWORD>
  auth.username: <USER>
  auth.database: <DATABASE>

  # Required for external Postgres.
  # Specify an external (already existing) Postgres deployment for use.
  # Set to the host eg. mypostgres.myserver.io
  externalEndpoint: <HOSTNAME>

anchoreConfig:
  database:
    ssl: true
    sslMode: require

```

#### RDS Postgres Database Configuration With TLS

Note that the `postgresql:` configuration section is the same as the previous example.

```yaml
certStoreSecretName: some-cert-store-secret

anchoreConfig:
  database:
    ssl: true
    sslMode: verify-full
    # sslRootCertName is the name of the Postgres root CA certificate stored in certStoreSecretName
    sslRootCertFileName: postgres-root-ca-cert

```

To get a AWS RDS Postgres certificate bundle that contains both the intermediate and root certificates for all AWS Regions, download [here](https://truststore.pki.rds.amazonaws.com/global/global-bundle.pem).

An example of creating the certificate secret can be found in [TLS Configuration](#using-tls-internally).

#### Google CloudSQL Database Configuration

```yaml
## anchore_values.yaml
postgresql:
  chartEnabled: false
  auth.password: <CLOUDSQL-PASSWORD>
  auth.username: <CLOUDSQL-USER>
  auth.database: <CLOUDSQL-DATABASE>

cloudsql:
  # To use CloudSQL in GKE set 'enable: true'
  enabled: true
  # set CloudSQL instance: 'project:zone:instancename'
  instance: "project:zone:instancename"
  # Optional existing service account secret to use. See https://cloud.google.com/sql/docs/postgres/authentication
  useExistingServiceAcc: true
  # If using an existing Service Account, you must create a secret (named my_service_acc in the example below)
  # which includes the JSON token from Google's IAM (corresponding to for_cloudsql.json in the example below)
  serviceAccSecretName: my_service_acc
  serviceAccJsonName: for_cloudsql.json
```

### Enterprise Feeds Configuration

The Anchore Enterprise Feeds service is provided as a dependent [Helm chart](https://github.com/anchore/anchore-charts/tree/main/stable/feeds). This service is comprised of different drivers for different vulnerability feeds. The drivers can be configured separately, and some drivers require a token or other credential.

See the [Anchore Enterprise Feeds](https://docs.anchore.com/current/docs/configuration/feeds/) documentation for details.

```yaml
feeds:
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

#### Enterprise Feeds External Database Configuration

Anchore Enterprise Feeds require access to a Postgres-compatible database, version 13 or higher to operate. Note that this is a separate database from the primary Anchore Enterprise database. For Enterprise Feeds, an external database such as AWS RDS or Google CloudSQL is recommended for production deployments. The Helm chart provides a chart-managed database by default unless otherwise configured.

See previous examples of configuring RDS Postgres and Google CloudSQL.

```yaml
feeds:
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

### Analyzer Image Layer Cache Configuration

To improve performance, the Anchore Enterprise Analyzer can be configured to cache image layers. This can be
particularly helpful if many images analyzed are built from the same set of base images.

It is recommended that layer cache data is stored in an external volume to ensure that the cache does not use all
of the ephemeral storage allocated for an analyzer host. See [Anchore Enterprise Layer Caching](https://docs.anchore.com/current/docs/configuration/storage/layer_caching/)
documentation for details.

```yaml
anchoreConfig:
  analyzer:
    # Enable image layer caching by setting a cache size > 0GB.
    layer_cache_max_gigabytes: 6
```

Refer to the default values file for configuring the analysis scratch volume.

### Configuring Object Storage

Anchore Enterprise stores metadata for images, tags, policies, and subscriptions.

#### Configuring The Object Storage Backend

In addition to a database (Postgres) storage backend, Anchore Enterprise object storage drivers
also support S3 and Swift storage. This enables scalable external object storage without burdening Postgres.

**Note: Using external object storage is recommended for production usage.**

- [Database backend](https://docs.anchore.com/current/docs/configuration/storage/object_store/database_driver/): Postgres database backend; this is the default, so using Postgres as the analysis archive storage backend requires no additional configuration
- [Local FS backend](https://docs.anchore.com/current/docs/configuration/storage/object_store/filesystem_driver/): A local filesystem on the core pod (Does not handle sharding or replication; generally recommended only for testing)
- [OpenStack Swift backend](https://docs.anchore.com/current/docs/configuration/storage/object_store/swift_driver/)
- [S3 backend](https://docs.anchore.com/current/docs/configuration/storage/object_store/s3_driver/): Any AWS S3 API compatible system (e.g. MinIO, Scality)

### Configuring Analysis Archive Storage

The analysis archive subsystem of Anchore Enterprise stores large JSON documents and can consume a large amount of storage
depending on the volume of images analyzed. A general rule for storage provisioning is 10MB per image analyzed. Thus with thousands of
analyzed images, you may need many gigabytes of storage. The analysis archive allows configuration of compression and storage backend.

Configuration of external analysis archive storage is essentially identical to configuration of external object storage. See [Anchore Enterprise Analysis Archive](https://docs.anchore.com/current/docs/configuration/storage/analysis_archive/) documentation for details.

**Note: Using external analysis archive storage is recommended for production usage.**

### Existing Secrets

For deployment scenarios that require version-controlled configuration to be used, it is recommended that credentials not be stored in values files.
To accomplish this, you can manually create Kubernetes secrets and specify them as existing secrets in your values files.

Below we show example Kubernetes secret objects, and how they would be used in Anchore Enterprise configuration.

```yaml
---
apiVersion: v1
kind: Secret
metadata:
  name: anchore-enterprise-env
type: Opaque
stringData:
  ANCHORE_ADMIN_PASSWORD: "<ADMIN_PASS>"
  ANCHORE_DB_PASSWORD: "<DB_PASS>"

---
apiVersion: v1
kind: Secret
metadata:
  name: anchore-enterprise-ui-env
type: Opaque
stringData:
  ANCHORE_ADMIN_PASSWORD: "<ADMIN_PASS>"
  ANCHORE_APPDB_URI: "postgresql://<PG_USER>:<DB_PASS>@<DB_HOSTNAME>:5432/<DATABASE_NAME>"
  ANCHORE_REDIS_URI: "redis://nouser:<REDIS_PASS>@<REDIS_HOSTNAME>:6379"

---
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

feeds:
  useExistingSecrets: true
```

### Ingress

[Ingress](https://kubernetes.io/docs/concepts/services-networking/ingress/) exposes HTTP and HTTPS routes from outside the cluster to services within the cluster. Traffic routing is controlled by rules defined on the Ingress resource. Kubernetes supports a variety of ingress controllers, including AWS ALB controllers and GCE controllers.

This Helm chart provides basic ingress configuration suitable for customization. You can expose routes for Anchore Enterprise external APIs including the core external API, UI, reporting, RBAC, and feeds by configuring the `ingress:` section in your values file.

Ingress is disabled by default in the Helm chart. The NGINX ingress controller with the core API and UI routes can be enabled by changing the `ingress.enabled` value to `true`.

Note that the [Kubernetes NGINX ingress controller](https://kubernetes.github.io/ingress-nginx/) must be installed into the cluster for this configuration to work.

```yaml
ingress:
  enabled: true
```

### Configuring The ALB Ingress Controller

Note that the [Kubernetes ALB ingress controller](https://docs.aws.amazon.com/eks/latest/userguide/alb-ingress.html) must be installed into the cluster for this configuration to work.

```yaml
ingress:
  enabled: true
  annotations:
    kubernetes.io/ingress.class: alb
    alb.ingress.kubernetes.io/scheme: internet-facing
  apiPath: /v1/*
  uiPath: /*
  apiHosts:
    - anchore-api.example.com
  uiHosts:
    - anchore-ui.example.com

api:
  service:
    type: NodePort

ui:
  service:
    type: NodePort
```

#### GCE Ingress Controller

Note that the [Kubernetes GCE ingress controller](https://cloud.google.com/kubernetes-engine/docs/concepts/ingress) must be installed into the cluster for this configuration to work.

```yaml
ingress:
  enabled: true
  annotations:
    kubernetes.io/ingress.class: gce
  apiPath: /v1/*
  uiPath: /*
  apiHosts:
    - anchore-api.example.com
  uiHosts:
    - anchore-ui.example.com

api:
  service:
    type: NodePort

ui:
  service:
    type: NodePort
```

### SSO

See [Anchore Enterprise SSO](https://docs.anchore.com/current/docs/configuration/sso/) documentation for information on configuring single sign-on.

```yaml
anchoreConfig:
  user_authentication:
    oauth:
      enabled: true
    # WARNING: You should not change hashed_paswords after a system has been initialized as it may cause a mismatch in existing passwords
    hashed_passwords: true
```

### Prometheus Metrics

Anchore Enterprise supports exporting Prometheus metrics from each container.

```yaml
anchoreConfig:
  metrics:
    enabled: true
    auth_disabled: true
```

When enabled, each service provides metrics over its existing service port, so your Prometheus deployment will need to
know about each pod and the ports it provides. You'll need to know this if adding Prometheus manually to your deployment.

If using the [Prometheus operator](https://github.com/prometheus-operator/prometheus-operator/blob/main/Documentation/user-guides/getting-started.md), a ServiceMonitor can be deployed into your cluster (in same namespace as your Anchore Enterprise release) and the Prometheus operator will start scraping the configured endpoints for metrics.

#### Example ServiceMonitor Configuration

The `targetPort` values in this example use the default Anchore Enterprise service ports.

Note that you will require a ServiceAccount for Prometheus (referenced in the Prometheus configuration below).

```yaml
---
apiVersion: monitoring.coreos.com/v1
kind: Prometheus
metadata:
  name: prometheus
  namespace: <your-namespace>
  labels:
    prometheus: prometheus
spec:
  replicas: 1
  serviceAccountName: prometheus
  serviceMonitorSelector:
    matchLabels:
      serviceMonitorName: anchore

---
apiVersion: monitoring.coreos.com/v1
kind: ServiceMonitor
metadata:
  name: anchore-prom-metrics
  namespace: <your-namespace>
  labels:
    serviceMonitorName: anchore # from Prometheus configuration above
spec:
  namespaceSelector:
    matchNames:
    - <your-namespace>
  selector:
    matchLabels:
      app.kubernetes.io/instance: <your-anchore-helm-release-name>
  endpoints:
  # api
  - targetPort: 8228
    interval: 30s
    path: /metrics
    scheme: http
  # catalog
  - targetPort: 8082
    interval: 30s
    path: /metrics
    scheme: http
  # policy engine
  - targetPort: 8087
    interval: 30s
    path: /metrics
    scheme: http
  # simple queue
  - targetPort: 8083
    interval: 30s
    path: /metrics
    scheme: http
  # feeds
  - targetPort: 8448
    interval: 30s
    path: /metrics
    scheme: http
  # reports
  - targetPort: 8558
    interval: 30s
    path: /metrics
    scheme: http
  # notifications
  - targetPort: 8668
    interval: 30s
    path: /metrics
    scheme: http
  # RBAC manager
  - targetPort: 8229
    interval: 30s
    path: /metrics
    scheme: http
```

### Scaling Individual Services

Anchore Enterprise services can be scaled by adjusting replica counts.

To set a specific number of service containers:

```yaml
analyzer:
  replicaCount: 5

policyEngine:
  replicaCount: 3
```

To update the number in a running configuration:

```shell
export RELEASE="YOUR-RELEASE-NAME"

helm upgrade --set analyzer.replicaCount=2 ${RELEASE} anchore/enterprise -f anchore_values.yaml
```

Contact [Anchore Support](https://get.anchore.com/contact/) for assistance in scaling and tuning your Anchore Enterprise installation.

### Using TLS Internally

Communication between Anchore Enterprise services can be configured with TLS. See the [Anchore TLS](https://docs.anchore.com/current/docs/configuration/tls_ssl/) documentation for more information.

A Kubernetes secret needs to be created in the same namespace as the chart installation. This secret should contain all custom certificates, including CA certificates and any certificates used for internal TLS communication.

This secret will be mounted to all Anchore Enterprise containers at `/home/anchore/certs`. The Anchore Enterprise entrypoint script configures all certificates found in `/home/anchore/certs` along with the operating system's default CA bundle.

```yaml
---
apiVersion: v1
kind: Secret
metadata:
  name: anchore-tls-certs
  namespace: ...
type: Opaque
data:
  internal-ca-cert-bundle.pam:
[base64 encoded text]
  rds-combined-ca-cert-bundle.pem:
[base64 encoded text]
  internal-cert.pem:
[base64 encoded text]
  internal-cert-key.pem:
[base64 encoded text]
  ldap-combined-ca-cert-bundle.pem:
[base64 encoded text]
```

Values configuration corresponding to above example secret:

```yaml
certStoreSecretName: anchore-tls-certs

anchoreConfig:
  database:
    timeout: 120
    # Use SSL, but the default Postgres config in helm's stable repo does not support SSL on server side, so this should be set for external DBs only.
    # All SSL dbConfig values are only utilized when ssl=true
    ssl: true
    sslMode: verify-full
    # sslRootCertName is the name of the Postgres root CA certificate stored in certStoreSecretName
    sslRootCertFileName: rds-combined-ca-cert-bundle.pem

  internalServicesSSL:
    # Set internalServicesSSL.enabled to true to force all Enterprise services to use SSL for internal communication
    enabled: true
    # Specify whether cert is verfied against the local certifacte bundle (If set to false, self-signed certs are allowed)
    verifyCerts: true
    certSecretKeyFileName: internal-cert-key.pem
    certSecretCertFileName: internal-cert.pem

ui:
  ldapsRootCaCertName: ldap-combined-ca-cert-bundle.pem
```

### Anchore Enterprise Notifications

Anchore Enterprise includes Notifications service to alert external endpoints about the system’s activity. Notifications can be configured to send alerts to Slack, GitHub Issues, and Jira.

See the [Anchore Notifications](https://docs.anchore.com/current/docs/configuration/notifications/) documentation for details.

### Anchore Enterprise Reports

Anchore Enterprise Reports aggregates data to provide insightful analytics and metrics for account-wide artifacts. The service employs GraphQL to expose a rich API for querying the aggregated data and metrics.

See the [Anchore Reports](https://docs.anchore.com/current/docs/configuration/reports/) documentation for details.

### Installing on Openshift

As of August 2nd, 2023, helm does not support passing `null` values to child/dependency charts. See the [helm issue](https://github.com/helm/helm/issues/9027) for more details. With the feeds chart being a dependency, you will need to deploy the `feeds` chart as a standalone chart and point the `enterprise` deployment to the standalone feeds deployment. Also note that you need to disable or set the appropriate values for the containerSecurityContext, runAsUser, and fsGroup for ui-redis and any postgres db you're using the enteprise chart to deploy (eg. postgresql.chartEnabled or feeds-db.chartEnabled).

For example:

1. deploy feeds chart as a standalone deployment
```shell
helm install feedsy anchore/feeds \
  --set securityContext.fsGroup=null \
  --set securityContext.runAsGroup=null \
  --set securityContext.runAsUser=null \
  --set feeds-db.primary.containerSecurityContext.enabled=false \
  --set feeds-db.primary.podSecurityContext.enabled=false
```

2. deploy the enterprise chart with appropriate values
```shell
helm install anchore . \
  --set securityContext.fsGroup=null \
  --set securityContext.runAsGroup=null \
  --set securityContext.runAsUser=null \
  --set feeds.chartEnabled=false \
  --set feeds.url=feedsy-feeds \
  --set postgresql.primary.containerSecurityContext.enabled=false \
  --set postgresql.primary.podSecurityContext.enabled=false \
  --set ui-redis.master.podSecurityContext.enabled=false \
  --set ui-redis.master.containerSecurityContext.enabled=false
```

Note: disabling the containerSecurityContext and podSecurityContext may not be suitable for production. See [Redhat's documentation](https://docs.openshift.com/container-platform/4.13/authentication/managing-security-context-constraints.html#managing-pod-security-policies) on what may be suitable for production.

For more information on the openshift.io/sa.scc.uid-range annotation, see the [openshift docs](https://docs.openshift.com/dedicated/authentication/managing-security-context-constraints.html#security-context-constraints-pre-allocated-values_configuring-internal-oauth)

#### Example Openshift values file:
```yaml
# NOTE: This is not a production ready values file for an openshift deployment.

securityContext:
  fsGroup: null
  runAsGroup: null
  runAsUser: null
feeds:
  chartEnabled: false
  url: feedsy-feeds
postgresql:
  primary:
    containerSecurityContext:
      enabled: false
    podSecurityContext:
      enabled: false
ui-redis:
  master:
    podSecurityContext:
      enabled: false
    containerSecurityContext:
      enabled: false
```

## Parameters

### Common Resource Parameters

| Name                                  | Description                                                                           | Value                                 |
| ------------------------------------- | ------------------------------------------------------------------------------------- | ------------------------------------- |
| `fullnameOverride`                    | overrides the fullname set on resources                                               | `""`                                  |
| `nameOverride`                        | overrides the name set on resources                                                   | `""`                                  |
| `image`                               | Image used for all Anchore Enterprise deployments, excluding Anchore UI               | `docker.io/anchore/enterprise:v4.9.0` |
| `imagePullPolicy`                     | Image pull policy used by all deployments                                             | `IfNotPresent`                        |
| `imagePullSecretName`                 | Name of Docker credentials secret for access to private repos                         | `anchore-enterprise-pullcreds`        |
| `serviceAccountName`                  | Name of a service account used to run all Anchore pods                                | `""`                                  |
| `injectSecretsViaEnv`                 | Enable secret injection into pod via environment variables instead of via k8s secrets | `false`                               |
| `licenseSecretName`                   | Name of the Kubernetes secret containing your license.yaml file                       | `anchore-enterprise-license`          |
| `certStoreSecretName`                 | Name of secret containing the certificates & keys used for SSL, SAML & CAs            | `""`                                  |
| `extraEnv`                            | Common environment variables set on all containers                                    | `[]`                                  |
| `useExistingSecrets`                  | forgoes secret creation and uses the secret defined in existingSecretName             | `false`                               |
| `existingSecretName`                  | Name of an existing secret to be used for Anchore core services, excluding Anchore UI | `anchore-enterprise-env`              |
| `labels`                              | Common labels set on all Kubernetes resources                                         | `{}`                                  |
| `annotations`                         | Common annotations set on all Kubernetes resources                                    | `{}`                                  |
| `scratchVolume.mountPath`             | The mount path of an external volume for scratch space for image analysis             | `/analysis_scratch`                   |
| `scratchVolume.fixGroupPermissions`   | Enable an initContainer that will fix the fsGroup permissions                         | `false`                               |
| `scratchVolume.details`               | Details for the k8s volume to be created                                              | `{}`                                  |
| `extraVolumes`                        | mounts additional volumes to each pod                                                 | `[]`                                  |
| `extraVolumeMounts`                   | mounts additional volumes to each pod                                                 | `[]`                                  |
| `securityContext.runAsUser`           | The securityContext runAsUser for all Anchore pods                                    | `1000`                                |
| `securityContext.runAsGroup`          | The securityContext runAsGroup for all Anchore pods                                   | `1000`                                |
| `securityContext.fsGroup`             | The securityContext fsGroup for all Anchore pods                                      | `1000`                                |
| `containerSecurityContext`            | The securityContext for all containers                                                | `{}`                                  |
| `probes.liveness.initialDelaySeconds` | Initial delay seconds for liveness probe                                              | `120`                                 |
| `probes.liveness.timeoutSeconds`      | Timeout seconds for liveness probe                                                    | `10`                                  |
| `probes.liveness.periodSeconds`       | Period seconds for liveness probe                                                     | `10`                                  |
| `probes.liveness.failureThreshold`    | Failure threshold for liveness probe                                                  | `6`                                   |
| `probes.liveness.successThreshold`    | Success threshold for liveness probe                                                  | `1`                                   |
| `probes.readiness.timeoutSeconds`     | Timeout seconds for the readiness probe                                               | `10`                                  |
| `probes.readiness.periodSeconds`      | Period seconds for the readiness probe                                                | `10`                                  |
| `probes.readiness.failureThreshold`   | Failure threshold for the readiness probe                                             | `3`                                   |
| `probes.readiness.successThreshold`   | Success threshold for the readiness probe                                             | `1`                                   |
| `doSourceAtEntry.enabled`             | Does a `source` of the file path defined before starting Anchore services             | `false`                               |
| `doSourceAtEntry.filePaths`           | List of file paths to `source` before starting Anchore services                       | `[]`                                  |
| `configOverride`                      | Allows for overriding the default Anchore configuration file                          | `""`                                  |


### Anchore Configuration Parameters

| Name                                                                       | Description                                                                                                                      | Value              |
| -------------------------------------------------------------------------- | -------------------------------------------------------------------------------------------------------------------------------- | ------------------ |
| `anchoreConfig.service_dir`                                                | Path to directory where default Anchore config files are placed at startup                                                       | `/anchore_service` |
| `anchoreConfig.log_level`                                                  | The log level for Anchore services                                                                                               | `INFO`             |
| `anchoreConfig.allow_awsecr_iam_auto`                                      | Enable AWS IAM instance role for ECR auth                                                                                        | `true`             |
| `anchoreConfig.keys.secret`                                                | The shared secret used for signing & encryption, auto-generated by Helm if not set.                                              | `""`               |
| `anchoreConfig.keys.privateKeyFileName`                                    | The file name of the private key used for signing & encryption, found in the k8s secret specified in .Values.certStoreSecretName | `""`               |
| `anchoreConfig.keys.publicKeyFileName`                                     | The file name of the public key used for signing & encryption, found in the k8s secret specified in .Values.certStoreSecretName  | `""`               |
| `anchoreConfig.user_authentication.oauth.enabled`                          | Enable OAuth for Anchore user authentication                                                                                     | `false`            |
| `anchoreConfig.user_authentication.oauth.default_token_expiration_seconds` | The expiration, in seconds, for OAuth tokens                                                                                     | `3600`             |
| `anchoreConfig.user_authentication.oauth.refresh_token_expiration_seconds` | The expiration, in seconds, for OAuth refresh tokens                                                                             | `86400`            |
| `anchoreConfig.user_authentication.hashed_passwords`                       | Enable storing passwords as secure hashes in the database                                                                        | `false`            |
| `anchoreConfig.user_authentication.sso_require_existing_users`             | set to true in order to disable the SSO JIT provisioning during authentication                                                   | `false`            |
| `anchoreConfig.metrics.enabled`                                            | Enable Prometheus metrics for all Anchore services                                                                               | `false`            |
| `anchoreConfig.metrics.auth_disabled`                                      | Disable auth on Prometheus metrics for all Anchore services                                                                      | `false`            |
| `anchoreConfig.webhooks`                                                   | Enable Anchore services to provide webhooks for external system updates                                                          | `{}`               |
| `anchoreConfig.default_admin_password`                                     | The password for the Anchore Enterprise admin user                                                                               | `""`               |
| `anchoreConfig.default_admin_email`                                        | The email address used for the Anchore Enterprise admin user                                                                     | `admin@myanchore`  |
| `anchoreConfig.database.timeout`                                           |                                                                                                                                  | `120`              |
| `anchoreConfig.database.ssl`                                               | Enable SSL/TLS for the database connection                                                                                       | `false`            |
| `anchoreConfig.database.sslMode`                                           | The SSL mode to use for database connection                                                                                      | `verify-full`      |
| `anchoreConfig.database.sslRootCertFileName`                               | File name of the database root CA certificate stored in the k8s secret specified with .Values.certStoreSecretName                | `""`               |
| `anchoreConfig.database.db_pool_size`                                      | The database max connection pool size                                                                                            | `30`               |
| `anchoreConfig.database.db_pool_max_overflow`                              | The maximum overflow size of the database connection pool                                                                        | `100`              |
| `anchoreConfig.database.engineArgs`                                        | Set custom database engine arguments for SQLAlchemy                                                                              | `{}`               |
| `anchoreConfig.internalServicesSSL.enabled`                                | Force all Enterprise services to use SSL for internal communication                                                              | `false`            |
| `anchoreConfig.internalServicesSSL.verifyCerts`                            | Enable cert verification against the local cert bundle, if this set to false self-signed certs are allowed                       | `false`            |
| `anchoreConfig.internalServicesSSL.certSecretKeyFileName`                  | File name of the private key used for internal SSL stored in the secret specified in .Values.certStoreSecretName                 | `""`               |
| `anchoreConfig.internalServicesSSL.certSecretCertFileName`                 | File name of the root CA certificate used for internal SSL stored in the secret specified in .Values.certStoreSecretName         | `""`               |
| `anchoreConfig.policyBundles`                                              | Include custom Anchore policy bundles                                                                                            | `{}`               |
| `anchoreConfig.apiext.external.enabled`                                    | Allow overrides for constructing Anchore API URLs                                                                                | `false`            |
| `anchoreConfig.apiext.external.useTLS`                                     | Enable TLS for external API access                                                                                               | `true`             |
| `anchoreConfig.apiext.external.hostname`                                   | Hostname for the external Anchore API                                                                                            | `""`               |
| `anchoreConfig.apiext.external.port`                                       | Port configured for external Anchore API                                                                                         | `8443`             |
| `anchoreConfig.analyzer.cycle_timers.image_analyzer`                       | The interval between checks of the work queue for new analysis jobs                                                              | `1`                |
| `anchoreConfig.analyzer.max_threads`                                       | The concurrency of the Anchore Analyzer worker process                                                                           | `1`                |
| `anchoreConfig.analyzer.layer_cache_max_gigabytes`                         | Specify a cache size > 0GB to enable image layer caching                                                                         | `0`                |
| `anchoreConfig.analyzer.enable_hints`                                      | Enable a user-supplied 'hints' file to override and/or augment the software artifacts found during analysis                      | `false`            |
| `anchoreConfig.analyzer.configFile`                                        | Custom Anchore Analyzer configuration file contents in YAML                                                                      | `{}`               |
| `anchoreConfig.catalog.cycle_timers.image_watcher`                         | Interval (seconds) to check for an update to a tag                                                                               | `3600`             |
| `anchoreConfig.catalog.cycle_timers.policy_eval`                           | Interval (seconds) to run a policy evaluation on images with policy_eval subscription activated                                  | `3600`             |
| `anchoreConfig.catalog.cycle_timers.vulnerability_scan`                    | Interval to run a vulnerability scan on images with vuln_update subscription activated                                           | `14400`            |
| `anchoreConfig.catalog.cycle_timers.analyzer_queue`                        | Interval to add new work on the image analysis queue                                                                             | `1`                |
| `anchoreConfig.catalog.cycle_timers.archive_tasks`                         | Interval to trigger Anchore Catalog archive Tasks                                                                                | `43200`            |
| `anchoreConfig.catalog.cycle_timers.notifications`                         | Interval in which notifications will be processed for state changes                                                              | `30`               |
| `anchoreConfig.catalog.cycle_timers.service_watcher`                       | Interval of service state update poll, used for system status                                                                    | `15`               |
| `anchoreConfig.catalog.cycle_timers.policy_bundle_sync`                    | Interval of policy bundle sync                                                                                                   | `300`              |
| `anchoreConfig.catalog.cycle_timers.repo_watcher`                          | Interval between checks to repo for new tags                                                                                     | `60`               |
| `anchoreConfig.catalog.cycle_timers.image_gc`                              | Interval for garbage collection of images marked for deletion                                                                    | `60`               |
| `anchoreConfig.catalog.cycle_timers.k8s_image_watcher`                     | Interval for the runtime inventory image analysis poll                                                                           | `150`              |
| `anchoreConfig.catalog.cycle_timers.resource_metrics`                      | Interval (seconds) for computing metrics from the DB                                                                             | `60`               |
| `anchoreConfig.catalog.cycle_timers.events_gc`                             | Interval (seconds) for cleaning up events in the system based on timestamp                                                       | `43200`            |
| `anchoreConfig.catalog.event_log`                                          | Event log for webhooks, YAML configuration                                                                                       | `{}`               |
| `anchoreConfig.catalog.analysis_archive`                                   | Custom analysis archive YAML configuration                                                                                       | `{}`               |
| `anchoreConfig.catalog.object_store`                                       | Custom object storage YAML configuration                                                                                         | `{}`               |
| `anchoreConfig.catalog.runtime_inventory.image_ttl_days`                   | TTL for images in the inventory report working set                                                                               | `1`                |
| `anchoreConfig.catalog.down_analyzer_task_requeue`                         | Allows fast re-queueing when image status is 'analyzing' on an analyzer that is no longer in the 'up' state                      | `true`             |
| `anchoreConfig.policy_engine.cycle_timers.feed_sync`                       | Interval to run a feed sync to get latest cve data                                                                               | `14400`            |
| `anchoreConfig.policy_engine.cycle_timers.feed_sync_checker`               | Interval between checks to see if there needs to be a task queued                                                                | `3600`             |
| `anchoreConfig.policy_engine.overrideFeedsToUpstream`                      | Override the Anchore Feeds URL to use the public upstream Anchore Feeds                                                          | `false`            |
| `anchoreConfig.notifications.cycle_timers.notifications`                   | Interval that notifications are sent                                                                                             | `30`               |
| `anchoreConfig.notifications.ui_url`                                       | Set the UI URL that is included in the notification, defaults to the Enterprise UI service name                                  | `""`               |
| `anchoreConfig.reports.enable_graphiql`                                    | Enable GraphiQL, a GUI for editing and testing GraphQL queries and mutations                                                     | `true`             |
| `anchoreConfig.reports_worker.enable_data_ingress`                         | Enable periodically syncing data into the Anchore Reports Service                                                                | `true`             |
| `anchoreConfig.reports_worker.enable_data_egress`                          | Periodically remove reporting data that has been removed in other parts of system                                                | `false`            |
| `anchoreConfig.reports_worker.data_egress_window`                          | defines a number of days to keep reporting data following its deletion in the rest of system.                                    | `0`                |
| `anchoreConfig.reports_worker.data_refresh_max_workers`                    | The maximum number of concurrent threads to refresh existing results (etl vulnerabilities and evaluations) in reports service.   | `10`               |
| `anchoreConfig.reports_worker.data_load_max_workers`                       | The maximum number of concurrent threads to load new results (etl vulnerabilities and evaluations) to reports service.           | `10`               |
| `anchoreConfig.reports_worker.cycle_timers.reports_data_load`              | Interval that images and tags are synced                                                                                         | `600`              |
| `anchoreConfig.reports_worker.cycle_timers.reports_data_refresh`           | Interval that policy evaluations and vulnerabilities are synced                                                                  | `7200`             |
| `anchoreConfig.reports_worker.cycle_timers.reports_metrics`                | Interval for how often reporting metrics are generated                                                                           | `3600`             |
| `anchoreConfig.reports_worker.cycle_timers.reports_data_egress`            | Interval that stale reporting data removal is synced                                                                             | `600`              |
| `anchoreConfig.ui.enable_proxy`                                            | Trust a reverse proxy when setting secure cookies (via the `X-Forwarded-Proto` header)                                           | `false`            |
| `anchoreConfig.ui.enable_ssl`                                              | Enable SSL in the Anchore UI container                                                                                           | `false`            |
| `anchoreConfig.ui.enable_shared_login`                                     | Allow single user to start multiple Anchore UI sessions                                                                          | `true`             |
| `anchoreConfig.ui.redis_flushdb`                                           | Flush user session keys and empty data on Anchore UI startup                                                                     | `true`             |
| `anchoreConfig.ui.force_websocket`                                         | Force WebSocket protocol for socket message communications                                                                       | `false`            |
| `anchoreConfig.ui.authentication_lock.count`                               | Number of failed authentication attempts allowed before a temporary lock is applied                                              | `5`                |
| `anchoreConfig.ui.authentication_lock.expires`                             | Authentication lock duration                                                                                                     | `300`              |
| `anchoreConfig.ui.custom_links`                                            | List of up to 10 external links provided                                                                                         | `{}`               |
| `anchoreConfig.ui.enable_add_repositories`                                 | Specify what users can add image repositories to the Anchore UI                                                                  | `{}`               |
| `anchoreConfig.ui.log_level`                                               | Descriptive detail of the application log output                                                                                 | `http`             |
| `anchoreConfig.ui.enrich_inventory_view`                                   | aggregate and include compliance and vulnerability data from the reports service.                                                | `true`             |
| `anchoreConfig.ui.appdb_config.native`                                     | toggle the postgreSQL drivers used to connect to the database between the native and the NodeJS drivers.                         | `true`             |
| `anchoreConfig.ui.appdb_config.pool.max`                                   | maximum number of simultaneous connections allowed in the connection pool                                                        | `10`               |
| `anchoreConfig.ui.appdb_config.pool.min`                                   | minimum number of connections                                                                                                    | `0`                |
| `anchoreConfig.ui.appdb_config.pool.acquire`                               | the timeout in milliseconds used when acquiring a new connection                                                                 | `30000`            |
| `anchoreConfig.ui.appdb_config.pool.idle`                                  | the maximum time that a connection can be idle before being released                                                             | `10000`            |
| `anchoreConfig.ui.dbUser`                                                  | allows overriding and separation of the ui database user.                                                                        | `""`               |
| `anchoreConfig.ui.dbPassword`                                              | allows overriding and separation of the ui database user authentication                                                          | `""`               |


### Anchore API k8s Deployment Parameters

| Name                      | Description                                          | Value       |
| ------------------------- | ---------------------------------------------------- | ----------- |
| `api.replicaCount`        | Number of replicas for Anchore API deployment        | `1`         |
| `api.service.type`        | Service type for Anchore API                         | `ClusterIP` |
| `api.service.port`        | Service port for Anchore API                         | `8228`      |
| `api.service.reportsPort` | Service port for Anchore Reports API                 | `8558`      |
| `api.service.annotations` | Annotations for Anchore API service                  | `{}`        |
| `api.service.labels`      | Labels for Anchore API service                       | `{}`        |
| `api.extraEnv`            | Set extra environment variables for Anchore API pods | `[]`        |
| `api.resources`           | Resource requests and limits for Anchore API pods    | `{}`        |
| `api.labels`              | Labels for Anchore API pods                          | `{}`        |
| `api.annotations`         | Annotation for Anchore API pods                      | `{}`        |
| `api.nodeSelector`        | Node labels for Anchore API pod assignment           | `{}`        |
| `api.tolerations`         | Tolerations for Anchore API pod assignment           | `[]`        |
| `api.affinity`            | Affinity for Anchore API pod assignment              | `{}`        |
| `api.serviceAccountName`  | Service account name for Anchore API pods            | `""`        |


### Anchore Analyzer k8s Deployment Parameters

| Name                          | Description                                                           | Value  |
| ----------------------------- | --------------------------------------------------------------------- | ------ |
| `analyzer.replicaCount`       | Number of replicas for the Anchore Analyzer deployment                | `1`    |
| `analyzer.service.port`       | The port used for gatherings metrics when .Values.metricsEnabled=true | `8084` |
| `analyzer.extraEnv`           | Set extra environment variables for Anchore Analyzer pods             | `[]`   |
| `analyzer.resources`          | Resource requests and limits for Anchore Analyzer pods                | `{}`   |
| `analyzer.labels`             | Labels for Anchore Analyzer pods                                      | `{}`   |
| `analyzer.annotations`        | Annotation for Anchore Analyzer pods                                  | `{}`   |
| `analyzer.nodeSelector`       | Node labels for Anchore Analyzer pod assignment                       | `{}`   |
| `analyzer.tolerations`        | Tolerations for Anchore Analyzer pod assignment                       | `[]`   |
| `analyzer.affinity`           | Affinity for Anchore Analyzer pod assignment                          | `{}`   |
| `analyzer.serviceAccountName` | Service account name for Anchore API pods                             | `""`   |


### Anchore Catalog k8s Deployment Parameters

| Name                          | Description                                              | Value       |
| ----------------------------- | -------------------------------------------------------- | ----------- |
| `catalog.replicaCount`        | Number of replicas for the Anchore Catalog deployment    | `1`         |
| `catalog.service.type`        | Service type for Anchore Catalog                         | `ClusterIP` |
| `catalog.service.port`        | Service port for Anchore Catalog                         | `8082`      |
| `catalog.service.annotations` | Annotations for Anchore Catalog service                  | `{}`        |
| `catalog.service.labels`      | Labels for Anchore Catalog service                       | `{}`        |
| `catalog.extraEnv`            | Set extra environment variables for Anchore Catalog pods | `[]`        |
| `catalog.resources`           | Resource requests and limits for Anchore Catalog pods    | `{}`        |
| `catalog.labels`              | Labels for Anchore Catalog pods                          | `{}`        |
| `catalog.annotations`         | Annotation for Anchore Catalog pods                      | `{}`        |
| `catalog.nodeSelector`        | Node labels for Anchore Catalog pod assignment           | `{}`        |
| `catalog.tolerations`         | Tolerations for Anchore Catalog pod assignment           | `[]`        |
| `catalog.affinity`            | Affinity for Anchore Catalog pod assignment              | `{}`        |
| `catalog.serviceAccountName`  | Service account name for Anchore Catalog pods            | `""`        |


### Anchore Feeds Chart Parameters

| Name                 | Description                                                                                    | Value   |
| -------------------- | ---------------------------------------------------------------------------------------------- | ------- |
| `feeds.chartEnabled` | Enable the Anchore Feeds chart                                                                 | `true`  |
| `feeds.standalone`   | Sets the Anchore Feeds chart to run into non-standalone mode, for use with Anchore Enterprise. | `false` |
| `feeds.url`          | Set the URL for a standalone Feeds service. Use when chartEnabled=false.                       | `""`    |


### Anchore Policy Engine k8s Deployment Parameters

| Name                               | Description                                                    | Value       |
| ---------------------------------- | -------------------------------------------------------------- | ----------- |
| `policyEngine.replicaCount`        | Number of replicas for the Anchore Policy Engine deployment    | `1`         |
| `policyEngine.service.type`        | Service type for Anchore Policy Engine                         | `ClusterIP` |
| `policyEngine.service.port`        | Service port for Anchore Policy Engine                         | `8087`      |
| `policyEngine.service.annotations` | Annotations for Anchore Policy Engine service                  | `{}`        |
| `policyEngine.service.labels`      | Labels for Anchore Policy Engine service                       | `{}`        |
| `policyEngine.extraEnv`            | Set extra environment variables for Anchore Policy Engine pods | `[]`        |
| `policyEngine.resources`           | Resource requests and limits for Anchore Policy Engine pods    | `{}`        |
| `policyEngine.labels`              | Labels for Anchore Policy Engine pods                          | `{}`        |
| `policyEngine.annotations`         | Annotation for Anchore Policy Engine pods                      | `{}`        |
| `policyEngine.nodeSelector`        | Node labels for Anchore Policy Engine pod assignment           | `{}`        |
| `policyEngine.tolerations`         | Tolerations for Anchore Policy Engine pod assignment           | `[]`        |
| `policyEngine.affinity`            | Affinity for Anchore Policy Engine pod assignment              | `{}`        |
| `policyEngine.serviceAccountName`  | Service account name for Anchore Policy Engine pods            | `""`        |


### Anchore Simple Queue Parameters

| Name                              | Description                                                   | Value       |
| --------------------------------- | ------------------------------------------------------------- | ----------- |
| `simpleQueue.replicaCount`        | Number of replicas for the Anchore Simple Queue deployment    | `1`         |
| `simpleQueue.service.type`        | Service type for Anchore Simple Queue                         | `ClusterIP` |
| `simpleQueue.service.port`        | Service port for Anchore Simple Queue                         | `8083`      |
| `simpleQueue.service.annotations` | Annotations for Anchore Simple Queue service                  | `{}`        |
| `simpleQueue.service.labels`      | Labels for Anchore Simple Queue service                       | `{}`        |
| `simpleQueue.extraEnv`            | Set extra environment variables for Anchore Simple Queue pods | `[]`        |
| `simpleQueue.resources`           | Resource requests and limits for Anchore Simple Queue pods    | `{}`        |
| `simpleQueue.labels`              | Labels for Anchore Simple Queue pods                          | `{}`        |
| `simpleQueue.annotations`         | Annotation for Anchore Simple Queue pods                      | `{}`        |
| `simpleQueue.nodeSelector`        | Node labels for Anchore Simple Queue pod assignment           | `{}`        |
| `simpleQueue.tolerations`         | Tolerations for Anchore Simple Queue pod assignment           | `[]`        |
| `simpleQueue.affinity`            | Affinity for Anchore Simple Queue pod assignment              | `{}`        |
| `simpleQueue.serviceAccountName`  | Service account name for Anchore Simple Queue pods            | `""`        |


### Anchore Notifications Parameters

| Name                                | Description                                                    | Value       |
| ----------------------------------- | -------------------------------------------------------------- | ----------- |
| `notifications.replicaCount`        | Number of replicas for the Anchore Notifications deployment    | `1`         |
| `notifications.service.type`        | Service type for Anchore Notifications                         | `ClusterIP` |
| `notifications.service.port`        | Service port for Anchore Notifications                         | `8668`      |
| `notifications.service.annotations` | Annotations for Anchore Notifications service                  | `{}`        |
| `notifications.service.labels`      | Labels for Anchore Notifications service                       | `{}`        |
| `notifications.extraEnv`            | Set extra environment variables for Anchore Notifications pods | `[]`        |
| `notifications.resources`           | Resource requests and limits for Anchore Notifications pods    | `{}`        |
| `notifications.labels`              | Labels for Anchore Notifications pods                          | `{}`        |
| `notifications.annotations`         | Annotation for Anchore Notifications pods                      | `{}`        |
| `notifications.nodeSelector`        | Node labels for Anchore Notifications pod assignment           | `{}`        |
| `notifications.tolerations`         | Tolerations for Anchore Notifications pod assignment           | `[]`        |
| `notifications.affinity`            | Affinity for Anchore Notifications pod assignment              | `{}`        |
| `notifications.serviceAccountName`  | Service account name for Anchore Notifications pods            | `""`        |


### Anchore Reports Parameters

| Name                          | Description                                              | Value       |
| ----------------------------- | -------------------------------------------------------- | ----------- |
| `reports.replicaCount`        | Number of replicas for the Anchore Reports deployment    | `1`         |
| `reports.service.type`        | Service type for Anchore Reports                         | `ClusterIP` |
| `reports.service.port`        | Service port for Anchore Reports Worker                  | `8558`      |
| `reports.service.annotations` | Annotations for Anchore Reports service                  | `{}`        |
| `reports.service.labels`      | Labels for Anchore Reports service                       | `{}`        |
| `reports.extraEnv`            | Set extra environment variables for Anchore Reports pods | `[]`        |
| `reports.resources`           | Resource requests and limits for Anchore Reports pods    | `{}`        |
| `reports.labels`              | Labels for Anchore Reports pods                          | `{}`        |
| `reports.annotations`         | Annotation for Anchore Reports pods                      | `{}`        |
| `reports.nodeSelector`        | Node labels for Anchore Reports pod assignment           | `{}`        |
| `reports.tolerations`         | Tolerations for Anchore Reports pod assignment           | `[]`        |
| `reports.affinity`            | Affinity for Anchore Reports pod assignment              | `{}`        |
| `reports.serviceAccountName`  | Service account name for Anchore Reports pods            | `""`        |


### Anchore RBAC Authentication Parameters

| Name                 | Description                                                                | Value |
| -------------------- | -------------------------------------------------------------------------- | ----- |
| `rbacAuth.extraEnv`  | Set extra environment variables for Anchore RBAC Authentication containers | `[]`  |
| `rbacAuth.resources` | Resource requests and limits for Anchore RBAC Authentication containers    | `{}`  |


### Anchore RBAC Manager Parameters

| Name                              | Description                                                   | Value       |
| --------------------------------- | ------------------------------------------------------------- | ----------- |
| `rbacManager.replicaCount`        | Number of replicas for the Anchore RBAC Manager deployment    | `1`         |
| `rbacManager.service.type`        | Service type for Anchore RBAC Manager                         | `ClusterIP` |
| `rbacManager.service.port`        | Service port for Anchore RBAC Manager                         | `8229`      |
| `rbacManager.service.annotations` | Annotations for Anchore RBAC Manager service                  | `{}`        |
| `rbacManager.service.labels`      | Labels for Anchore RBAC Manager service                       | `{}`        |
| `rbacManager.extraEnv`            | Set extra environment variables for Anchore RBAC Manager pods | `[]`        |
| `rbacManager.resources`           | Resource requests and limits for Anchore RBAC Manager pods    | `{}`        |
| `rbacManager.labels`              | Labels for Anchore RBAC Manager pods                          | `{}`        |
| `rbacManager.annotations`         | Annotation for Anchore RBAC Manager pods                      | `{}`        |
| `rbacManager.nodeSelector`        | Node labels for Anchore RBAC Manager pod assignment           | `{}`        |
| `rbacManager.tolerations`         | Tolerations for Anchore RBAC Manager pod assignment           | `[]`        |
| `rbacManager.affinity`            | Affinity for Anchore RBAC Manager pod assignment              | `{}`        |
| `rbacManager.serviceAccountName`  | Service account name for Anchore RBAC Manager pods            | `""`        |


### Anchore UI Parameters

| Name                         | Description                                                                   | Value                                    |
| ---------------------------- | ----------------------------------------------------------------------------- | ---------------------------------------- |
| `ui.image`                   | Image used for the Anchore UI container                                       | `docker.io/anchore/enterprise-ui:v4.9.0` |
| `ui.imagePullPolicy`         | Image pull policy for Anchore UI image                                        | `IfNotPresent`                           |
| `ui.existingSecretName`      | Name of an existing secret to be used for Anchore UI DB and Redis endpoints   | `anchore-enterprise-ui-env`              |
| `ui.ldapsRootCaCertName`     | Name of the custom CA certificate file store in `.Values.certStoreSecretName` | `""`                                     |
| `ui.service.type`            | Service type for Anchore UI                                                   | `ClusterIP`                              |
| `ui.service.port`            | Service port for Anchore UI                                                   | `80`                                     |
| `ui.service.annotations`     | Annotations for Anchore UI service                                            | `{}`                                     |
| `ui.service.labels`          | Labels for Anchore UI service                                                 | `{}`                                     |
| `ui.service.sessionAffinity` | Session Affinity for Ui service                                               | `ClientIP`                               |
| `ui.extraEnv`                | Set extra environment variables for Anchore UI pods                           | `[]`                                     |
| `ui.resources`               | Resource requests and limits for Anchore UI pods                              | `{}`                                     |
| `ui.labels`                  | Labels for Anchore UI pods                                                    | `{}`                                     |
| `ui.annotations`             | Annotation for Anchore UI pods                                                | `{}`                                     |
| `ui.nodeSelector`            | Node labels for Anchore UI pod assignment                                     | `{}`                                     |
| `ui.tolerations`             | Tolerations for Anchore UI pod assignment                                     | `[]`                                     |
| `ui.affinity`                | Affinity for Anchore ui pod assignment                                        | `{}`                                     |
| `ui.serviceAccountName`      | Service account name for Anchore UI pods                                      | `""`                                     |


### Anchore Upgrade Job Parameters

| Name                            | Description                                                                                                                                     | Value   |
| ------------------------------- | ----------------------------------------------------------------------------------------------------------------------------------------------- | ------- |
| `upgradeJob.enabled`            | Enable the Anchore Enterprise database upgrade job                                                                                              | `true`  |
| `upgradeJob.force`              | Force the Anchore Feeds database upgrade job to run as a regular job instead of as a Helm hook                                                  | `false` |
| `upgradeJob.rbacCreate`         | Create RBAC resources for the Anchore upgrade job                                                                                               | `true`  |
| `upgradeJob.serviceAccountName` | Use an existing service account for the Anchore upgrade job                                                                                     | `""`    |
| `upgradeJob.usePostUpgradeHook` | Use a Helm post-upgrade hook to run the upgrade job instead of the default pre-upgrade hook. This job does not require creating RBAC resources. | `false` |
| `upgradeJob.nodeSelector`       | Node labels for the Anchore upgrade job pod assignment                                                                                          | `{}`    |
| `upgradeJob.tolerations`        | Tolerations for the Anchore upgrade job pod assignment                                                                                          | `[]`    |
| `upgradeJob.affinity`           | Affinity for the Anchore upgrade job pod assignment                                                                                             | `{}`    |
| `upgradeJob.annotations`        | Annotations for the Anchore upgrade job                                                                                                         | `{}`    |
| `upgradeJob.resources`          | Resource requests and limits for the Anchore upgrade job                                                                                        | `{}`    |
| `upgradeJob.labels`             | Labels for the Anchore upgrade job                                                                                                              | `{}`    |


### Ingress Parameters

| Name                       | Description                                                        | Value   |
| -------------------------- | ------------------------------------------------------------------ | ------- |
| `ingress.enabled`          | Create an ingress resource for external Anchore service APIs       | `false` |
| `ingress.labels`           | Labels for the ingress resource                                    | `{}`    |
| `ingress.annotations`      | Annotations for the ingress resource                               | `{}`    |
| `ingress.apiHosts`         | List of custom hostnames for the Anchore API                       | `[]`    |
| `ingress.apiPath`          | The path used for accessing the Anchore API                        | `/v1/`  |
| `ingress.uiHosts`          | List of custom hostnames for the Anchore UI                        | `[]`    |
| `ingress.uiPath`           | The path used for accessing the Anchore UI                         | `/`     |
| `ingress.feedsHosts`       | List of custom hostnames for the Anchore Feeds API                 | `[]`    |
| `ingress.feedsPath`        | The path used for accessing the Anchore Feeds API                  | `""`    |
| `ingress.reportsHosts`     | List of custom hostnames for the Anchore Reports API               | `[]`    |
| `ingress.reportsPath`      | The path used for accessing the Anchore Reports API                | `""`    |
| `ingress.tls`              | Configure tls for the ingress resource                             | `[]`    |
| `ingress.ingressClassName` | sets the ingress class name. As of k8s v1.18, this should be nginx | `nginx` |


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


### Anchore UI Redis Parameters

| Name                                  | Description                                                                                            | Value               |
| ------------------------------------- | ------------------------------------------------------------------------------------------------------ | ------------------- |
| `ui-redis.chartEnabled`               | Use the dependent chart for the UI Redis deployment                                                    | `true`              |
| `ui-redis.externalEndpoint`           | External Redis endpoint when not using Helm managed chart (eg redis://nouser:<password>@hostname:6379) | `""`                |
| `ui-redis.auth.password`              | Password used for connecting to Redis                                                                  | `anchore-redis,123` |
| `ui-redis.architecture`               | Redis deployment architecture                                                                          | `standalone`        |
| `ui-redis.master.persistence.enabled` | enables persistence                                                                                    | `false`             |


### Anchore Database Parameters

| Name                                          | Description                                                                                 | Value                   |
| --------------------------------------------- | ------------------------------------------------------------------------------------------- | ----------------------- |
| `postgresql.chartEnabled`                     | Use the dependent chart for Postgresql deployment                                           | `true`                  |
| `postgresql.externalEndpoint`                 | External Postgresql hostname when not using Helm managed chart (eg. mypostgres.myserver.io) | `""`                    |
| `postgresql.auth.username`                    | Username used to connect to postgresql                                                      | `anchore`               |
| `postgresql.auth.password`                    | Password used to connect to postgresql                                                      | `anchore-postgres,123`  |
| `postgresql.auth.database`                    | Database name used when connecting to postgresql                                            | `anchore`               |
| `postgresql.primary.service.ports.postgresql` | Port used to connect to Postgresql                                                          | `5432`                  |
| `postgresql.primary.persistence.size`         | Configure size of the persistent volume used with helm managed chart                        | `20Gi`                  |
| `postgresql.primary.extraEnvVars`             | An array to add extra environment variables                                                 | `[]`                    |
| `postgresql.image.tag`                        | Specifies the image to use for this chart.                                                  | `13.11.0-debian-11-r15` |


## Release Notes

See the Anchore [Release Notes](https://docs.anchore.com/current/docs/releasenotes/) for updates to Anchore Enterprise.

A major chart version change (v0.1.2 -> v1.0.0) indicates that there is an **incompatible breaking change needing manual actions.**

A minor chart version change (v0.1.2 -> v0.2.0) indicates a change that **may require updates to your values file.**

### v0.0.1

* This is a pre-release version of the Anchore Enterprise Helm chart. It is not intended for production use.
