# Anchore Enterprise Helm Chart

> :exclamation: **Important:** View the **[Chart Release Notes](#release-notes)** for the latest changes prior to installation or upgrading.

This Helm chart deploys Anchore Enterprise on a [Kubernetes](http://kubernetes.io) cluster using the [Helm](https://helm.sh) package manager.

Anchore Enterprise is an software bill of materials (SBOM) - powered software supply chain management solution designed for a cloud-native world. It provides continuous visibility into supply chain security risks. Anchore Enterprise takes a developer-friendly approach that minimizes friction by embedding automation into development toolchains to generate SBOMs and accurately identify vulnerabilities, malware, misconfigurations, and secrets for faster remediation.

See the [Anchore Enterprise Documentation](https://docs.anchore.com) for more details.

## Table of Contents

- [Prerequisites](#prerequisites)
- [Installing the Chart](#installing-the-chart)
- [Installing on Openshift](#installing-on-openshift)
- [Upgrading](#upgrading-the-chart)
- [Uninstalling the Chart](#uninstalling-the-chart)
- [Configuration](#configuration)
  - [External Database Requirements](#external-database-requirements)
  - [Installing on Openshift](#installing-on-openshift)
  - [Enterprise Feeds Configuration](#enterprise-feeds-configuration)
  - [Analyzer Image Layer Cache Configuration](#analyzer-image-layer-cache-configuration)
  - [Configuring Object Storage](#configuring-object-storage)
  - [Configuring Analysis Archive Storage](#configuring-analysis-archive-storage)
  - [Existing Secrets](#existing-secrets)
  - [Ingress](#ingress)
  - [Prometheus Metrics](#prometheus-metrics)
  - [Scaling Individual Services](#scaling-individual-services)
  - [Using TLS Internally](#using-tls-internally)
- [Migrating to the Anchore Enterprise Helm Chart](#migrating-to-the-anchore-enterprise-helm-chart)
- [Parameters](#parameters)
- [Release Notes](#release-notes)

## Prerequisites

- [Helm](https://helm.sh/) >=3.8
- [Kubernetes](https://kubernetes.io/) >=1.23

## Installing the Chart

> **Note**: For migration steps from an Anchore Engine Helm chart deployment, refer to the [Migrating to the Anchore Enterprise Helm Chart](#migrating-to-the-anchore-enterprise-helm-chart) section.

This guide covers deploying Anchore Enterprise on a Kubernetes cluster with the default configuration. Refer to the [Configuration](#configuration) section for additional guidance on production deployments.

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
    helm install ${RELEASE} -n ${NAMESPACE} anchore/enterprise -f anchore_values.yaml
    ```

    > **Note**: This command installs Anchore Enterprise with a chart-managed PostgreSQL database, which may not be suitable for production use. See the [External Database](#external-database-requirements) section for details on using an external database.

1. **Post-Installation Steps**: Anchore Enterprise will take some time to initialize. After the bootstrap phase, it will begin a vulnerability feed sync. Image analysis will show zero vulnerabilities until this sync is complete. This can take several hours based on the enabled feeds. Use the following [anchorectl](https://docs.anchore.com/current/docs/deployment/anchorectl/) commands to check the system status:

    ```shell
    export NAMESPACE=anchore
    export RELEASE=my-release
    export ANCHORECTL_URL=http://localhost:8228/v1/
    export ANCHORECTL_PASSWORD=$(kubectl get secret "${RELEASE}-enterprise" -o jsonpath='{.data.ANCHORE_ADMIN_PASSWORD}' | base64 -d -)

    kubectl port-forward -n ${NAMESPACE} svc/${RELEASE}-enterprise-api 8228:8228 # port forward for anchorectl in another terminal
    anchorectl system status # anchorectl defaults to the user admin, and to the password ${ANCHORECTL_PASSWORD} automatically if set
    ```

    > **Tip**: List all releases using `helm list`

### Installing on Openshift

As of August 2, 2023, Helm does not offer native support for passing `null` values to child or dependency charts. For details, refer to this [Helm GitHub issue](https://github.com/helm/helm/issues/9027). Given that the `feeds` chart is a dependency, a workaround is to deploy it as a standalone chart and configure the `enterprise` deployment to point to this separate `feeds` deployment.

Additionally, be aware that you'll need to either disable or properly set the parameters for `containerSecurityContext`, `runAsUser`, and `fsGroup` for the `ui-redis` and any PostgreSQL database that you deploy using the Enterprise chart (e.g., via `postgresql.chartEnabled` or `feeds-db.chartEnabled`).

For example:

1. **Deploy feeds chart as a standalone deployment:**

    ```shell
    helm install my-release anchore/feeds \
      --set securityContext.fsGroup=null \
      --set securityContext.runAsGroup=null \
      --set securityContext.runAsUser=null \
      --set feeds-db.primary.containerSecurityContext.enabled=false \
      --set feeds-db.primary.podSecurityContext.enabled=false
    ```

1. **Deploy the enterprise chart with appropriate values:**

    ```shell
    helm install anchore anchore/enterprise \
      --set securityContext.fsGroup=null \
      --set securityContext.runAsGroup=null \
      --set securityContext.runAsUser=null \
      --set feeds.chartEnabled=false \
      --set feeds.url=my-release-feeds \
      --set postgresql.primary.containerSecurityContext.enabled=false \
      --set postgresql.primary.podSecurityContext.enabled=false \
      --set ui-redis.master.podSecurityContext.enabled=false \
      --set ui-redis.master.containerSecurityContext.enabled=false
    ```

    > **Note:** disabling the containerSecurityContext and podSecurityContext may not be suitable for production. See [Redhat's documentation](https://docs.openshift.com/container-platform/4.13/authentication/managing-security-context-constraints.html#managing-pod-security-policies) on what may be suitable for production. For more information on the openshift.io/sa.scc.uid-range annotation, see the [openshift docs](https://docs.openshift.com/dedicated/authentication/managing-security-context-constraints.html#security-context-constraints-pre-allocated-values_configuring-internal-oauth)

#### Example Openshift values file

```yaml
# NOTE: This is not a production ready values file for an openshift deployment.

securityContext:
  fsGroup: null
  runAsGroup: null
  runAsUser: null
feeds:
  chartEnabled: false
  url: my-release-feeds
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

## Upgrading the Chart

A Helm pre-upgrade hook initiates a Kubernetes job that scales down all active Anchore Enterprise pods and handles the Anchore database upgrade.

The Helm upgrade is marked as successful only upon the job's completion. This process causes the Helm client to pause until the job finishes and new Anchore Enterprise pods are initiated. To monitor the upgrade, follow the logs of the upgrade jobs. These jobs are automatically removed after a subsequent successful Helm upgrade.

  ```shell
  export NAMESPACE=anchore
  export RELEASE=my-release

  helm upgrade ${RELEASE} -n ${NAMESPACE} anchore/enterprise -f anchore_values.yaml
  ```

An optional post-upgrade hook is available to perform Anchore Enterprise upgrades without forcing all pods to terminate prior to running the upgrade. This is the same upgrade behavior that was enabled by default in the legacy anchore-engine chart. To enable the post-upgrade hook, set `upgradeJob.usePostUpgradeHook=true` in your values file.

## Uninstalling the Chart

To completely remove the Anchore Enterprise deployment and associated Kubernetes resources, follow the steps below:

  ```shell
  export NAMESPACE=anchore
  export RELEASE=my-release

  helm uninstall ${RELEASE} -n ${NAMESPACE}
  ```

After deleting the helm release, there are still a few persistent volume claims to delete. Delete these only if you're certain you no longer need them.

  ```shell
  export NAMESPACE=anchore
  export RELEASE=my-release

  kubectl get pvc -n ${NAMESPACE}
  kubectl delete pvc ${RELEASE}-feeds -n ${NAMESPACE}
  kubectl delete pvc ${RELEASE}-feeds-db -n ${NAMESPACE}
  kubectl delete pvc ${RELEASE}-postgresql -n ${NAMESPACE}
  ```

## Configuration

This section outlines some of the available configuration options for Anchore Enterprise. The default settings are specified in the bundled [values file](https://github.com/anchore/anchore-charts-dev/blob/main/stable/enterprise/values.yaml). To customize these settings, create your own `anchore_values.yaml` file and populate it with the configuration options you wish to override. To apply your custom configuration during installation, pass your custom values file to the `helm install` command:

```shell
export NAMESPACE=anchore
export RELEASE="my-release"

helm install ${RELEASE} -n ${NAMESPACE} anchore/enterprise -f custom_values.yaml
```

For additional guidance on customizing your Anchore Enterprise deployment, reach out to [Anchore Support](get.anchore.com/contact/).

### External Database Requirements

Anchore Enterprise requires the use of a PostgreSQL-compatible database version 13 or above. For production environments, leveraging managed database services like AWS RDS or Google Cloud SQL is advised. While the Helm chart includes a chart-managed database by default, you can override this setting to use an external database.

For optimal performance, allocate a minimum of 100GB storage to accommodate images, tags, subscriptions, policies, and other data entities. Furthermore, configure the database to support a minimum of 2,000 client connections. This limit may need to be adjusted upward if you're running more Anchore services than the default configuration.

#### External Postgres Database Configuration

```yaml
postgresql:
  chartEnabled: false
  auth.password: <PASSWORD>
  auth.username: <USER>
  auth.database: <DATABASE>
  externalEndpoint: <HOSTNAME>

anchoreConfig:
  database:
    ssl: true
    sslMode: require
```

#### RDS Postgres Database Configuration With TLS

To obtain a comprehensive AWS RDS PostgreSQL certificate bundle, which includes both intermediate and root certificates for all AWS regions, you can download it [here](https://truststore.pki.rds.amazonaws.com/global/global-bundle.pem). An example of creating the certificate secret can be found in [TLS Configuration](#using-tls-internally).

```yaml
postgresql:
  chartEnabled: false
  auth.password: <PASSWORD>
  auth.username: <USER>
  auth.database: <DATABASE>
  externalEndpoint: <HOSTNAME>

certStoreSecretName: some-cert-store-secret

anchoreConfig:
  database:
    ssl: true
    sslMode: verify-full
    # sslRootCertName is the name of the Postgres root CA certificate stored in certStoreSecretName
    sslRootCertFileName: postgres-root-ca-cert
```

#### Google CloudSQL Database Configuration

```yaml
## anchore_values.yaml
postgresql:
  chartEnabled: false
  auth.password: <CLOUDSQL-PASSWORD>
  auth.username: <CLOUDSQL-USER>
  auth.database: <CLOUDSQL-DATABASE>

cloudsql:
  enabled: true
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
      msrc:
        enabled: true
```

#### Enterprise Feeds External Database Configuration

Anchore Enterprise Feeds requires the use of a PostgreSQL-compatible database version 13 or above. This database is distinct from the primary Anchore Enterprise database. For production environments, leveraging managed database services like AWS RDS or Google Cloud SQL is advised. While the Helm chart includes a chart-managed database by default, you can override this setting to use an external database.

See previous [examples](#external-database-requirements) of configuring RDS Postgresql and Google CloudSQL.

```yaml
feeds:
  anchoreConfig:
    database:
      ssl: true
      sslMode: require

  feeds-db:
    enabled: false
    auth.password: <PASSWORD>
    auth.username: <USER>
    auth.database: <DATABASE>
    externalEndpoint: <HOSTNAME>
```

### Analyzer Image Layer Cache Configuration

To improve performance, the Anchore Enterprise Analyzer can be configured to cache image layers. This can be particularly helpful if many images analyzed are built from the same set of base images.

It is recommended that layer cache data is stored in an external volume to ensure that the cache does not use all of the ephemeral storage allocated for an analyzer host. See [Anchore Enterprise Layer Caching](https://docs.anchore.com/current/docs/configuration/storage/layer_caching/) documentation for details. Refer to the default values file for configuring the analysis scratch volume.

```yaml
anchoreConfig:
  analyzer:
    layer_cache_max_gigabytes: 6
```

### Configuring Object Storage

Anchore Enterprise utilizes an object storage system to persistently store metadata related to images, tags, policies, and subscriptions.

#### Configuring The Object Storage Backend

In addition to a database (Postgres) storage backend, Anchore Enterprise object storage drivers also support S3 and Swift storage. This enables scalable external object storage without burdening Postgres.

> **Note:** Using external object storage is recommended for production usage.

- [Database backend](https://docs.anchore.com/current/docs/configuration/storage/object_store/database_driver/): Postgres database backend; this is the default, so using Postgres as the analysis archive storage backend requires no additional configuration
- [Local FS backend](https://docs.anchore.com/current/docs/configuration/storage/object_store/filesystem_driver/): A local filesystem on the core pod (Does not handle sharding or replication; generally recommended only for testing)
- [OpenStack Swift backend](https://docs.anchore.com/current/docs/configuration/storage/object_store/swift_driver/)
- [S3 backend](https://docs.anchore.com/current/docs/configuration/storage/object_store/s3_driver/): Any AWS S3 API compatible system (e.g. MinIO, Scality)

### Configuring Analysis Archive Storage

The Analysis Archive subsystem within Anchore Enterprise is designed to store extensive JSON documents, potentially requiring significant storage capacity based on the number of images analyzed. As a general guideline, allocate approximately 10MB of storage per analyzed image. Consequently, analyzing thousands of images could necessitate gigabytes of storage space. The Analysis Archive subsystem offers configurable options for both data compression and selection of the storage backend.

Configuration of external analysis archive storage is essentially identical to configuration of external object storage. See [Anchore Enterprise Analysis Archive](https://docs.anchore.com/current/docs/configuration/storage/analysis_archive/) documentation for details.

> **Note:** Using external analysis archive storage is recommended for production usage.

### Existing Secrets

For deployments where version-controlled configurations are essential, it's advised to avoid storing credentials directly in values files. Instead, manually create Kubernetes secrets and reference them as existing secrets within your values files. When using existing secrets, the chart will load environment variables into deployments from the secret names specified by the following values:

- `.Values.existingSecretName` [default: anchore-enterprise-env]
- `.Values.feeds.existingSecretName` [default: anchore-enterprise-feeds-env]
- `.Values.ui.existingSecretName` [default: anchore-enterprise-ui-env]

To enable this feature, set the following values to `true` in your values file:

```yaml
useExistingSecrets: true

feeds:
  useExistingSecrets: true
```

Below are sample Kubernetes secret objects and corresponding guidelines on integrating them into your Anchore Enterprise configuration.

```yaml
---
apiVersion: v1
kind: Secret
metadata:
  name: anchore-enterprise-env
type: Opaque
stringData:
  ANCHORE_ADMIN_PASSWORD: foobar1234
  ANCHORE_DB_NAME: anchore
  ANCHORE_DB_USER: anchore
  ANCHORE_DB_HOST: anchore-postgresql
  ANCHORE_DB_PORT: 5432
  ANCHORE_DB_PASSWORD: anchore-postgres,123
  # (if applicable) ANCHORE_SAML_SECRET: foobar,saml1234

---
apiVersion: v1
kind: Secret
metadata:
  name: anchore-enterprise-ui-env
type: Opaque
stringData:
  # if using TLS to connect to Postgresql you must add the ?ssl=[require|verify-ca|verify-full] parameter to the end of the URI
  ANCHORE_APPDB_URI: postgresql://anchoreengine:anchore-postgres,123@anchore-postgresql:5432/anchore
  ANCHORE_REDIS_URI: redis://:anchore-redis,123@anchore-ui-redis-master:6379

---
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

  apiHosts:
    - anchore-api.example.com
  uiHosts:
    - anchore-ui.example.com
  feedsHosts:
    - anchore-feeds.example.com
  reportsHosts:
    - anchore-reports.example.com

api:
  service:
    type: NodePort

feeds:
  service:
    type: NodePort

reports:
  service:
    type: NodePort

ui:
  service:
    type: NodePort
```

#### GCE Ingress Controller

The [Kubernetes GCE ingress controller](https://cloud.google.com/kubernetes-engine/docs/concepts/ingress) must be installed into the cluster for this configuration to work.

```yaml
ingress:
  enabled: true
  ingressClassName: gce
  apiPaths:
    - /v1/*
    - /v2/*
    - /version/*
  feedsPaths:
    - /v1/feeds/*
    - /v2/feeds/*
  reportsPaths:
    - /v1/reports/*
    - /v2/reports/*
  uiPath: /*

  apiHosts:
    - anchore-api.example.com
  uiHosts:
    - anchore-ui.example.com
  feedsHosts:
    - anchore-feeds.example.com
  reportsHosts:
    - anchore-reports.example.com

api:
  service:
    type: NodePort

feeds:
  service:
    type: NodePort

reports:
  service:
    type: NodePort

ui:
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

For those using the [Prometheus operator](https://github.com/prometheus-operator/prometheus-operator/blob/main/Documentation/user-guides/getting-started.md), a ServiceMonitor can be deployed within the same namespace as your Anchore Enterprise release. Once deployed, the Prometheus operator will automatically begin scraping the pre-configured endpoints for metrics.

#### Example ServiceMonitor Configuration

The `targetPort` values in this example use the default Anchore Enterprise service ports.

You will require a ServiceAccount for Prometheus (referenced in the Prometheus configuration below).

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

Anchore Enterprise services can be scaled by adjusting replica counts:

```yaml
analyzer:
  replicaCount: 5

policyEngine:
  replicaCount: 3
```

> **Note:** Contact [Anchore Support](https://get.anchore.com/contact/) for assistance in scaling and tuning your Anchore Enterprise installation.

### Using TLS Internally

Anchore Enterprise supports TLS for secure communication between its services. For detailed configuration steps, refer to the [Anchore TLS documentation](https://docs.anchore.com/current/docs/configuration/tls_ssl/).

To implement this, create a Kubernetes secret in the same namespace where the Helm chart is installed. This secret should encapsulate all custom certificates, including CA certificates and those used for internal TLS communication.

The Kubernetes secret will be mounted into all Anchore Enterprise containers at the path `/home/anchore/certs`. Anchore Enterprise's entrypoint script will auto-configure all certificates located in this directory, supplementing them with the operating system's default CA bundle.

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
    ssl: true
    sslMode: verify-full
    # sslRootCertName is the name of the Postgres root CA certificate stored in certStoreSecretName
    sslRootCertFileName: rds-combined-ca-cert-bundle.pem

  internalServicesSSL:
    enabled: true
    # Specify whether cert is verified against the local certificate bundle (If set to false, self-signed certs are allowed)
    verifyCerts: true
    certSecretKeyFileName: internal-cert-key.pem
    certSecretCertFileName: internal-cert.pem

ui:
  # Specify an LDAP CA cert if using LDAP authenication
  ldapsRootCaCertName: ldap-combined-ca-cert-bundle.pem
```

## Migrating to the Anchore Enterprise Helm Chart

This guide provides steps for transitioning from an Anchore Engine Helm chart deployment to the updated Anchore Enterprise Helm chart, a necessary step for users planning to upgrade to Anchore Enterprise version v5.0.0 or later.

  > :warning: **Warning**: The values file used by the Anchore Enterprise Helm chart is different from the one used by the Anchore Engine Helm chart. Make sure to convert your existing values file accordingly.

A [migration script](https://github.com/anchore/anchore-charts/tree/main/scripts) is available to automate the conversion of your Anchore Engine values file to the new Enterprise format. A usage example is provided below.

### Migration Prerequisites

- **Anchore Version**: Ensure that your current deployment is running Anchore Enterprise version 4.9.x (but not v5.0.0+). This is required to ensure that the migration script can properly convert your values file.

  > **Note:** Upgrade your [anchore-engine](https://github.com/anchore/anchore-charts/tree/main/stable/anchore-engine) chart deployment to `v1.28.0` or higher to ensure that you're running Anchore Enterprise v4.9.x.

- **PostgreSQL Version**: You need PostgreSQL version 13 or higher. For upgrading your existing PostgreSQL installation, refer to the official [PostgreSQL documentation](https://www.postgresql.org/docs/13/upgrading.html). Database migration help for helm managed PostgreSQL deployments is provided below.

  > **Note:** This chart deploys PostgreSQL 13 by default.

- **Runtime Environment**: Docker or Podman must be installed on the machine where the migration will run.

### Expected Changes to Your Deployment

The Anchore Enterprise Helm chart introduces several changes to the deployment compared to the Anchore Engine chart deployment. These changes are outlined below.

#### Service Names

- All service names have been updated to follow the Enterprise naming convention:
  - `<RELEASE_NAME>-anchore-engine-api` -> `<RELEASE_NAME>-enterprise-api`
  - `<RELEASE_NAME>-anchore-engine-catalog` -> `<RELEASE_NAME>-enterprise-catalog`
  - `<RELEASE_NAME>-anchore-engine-enterprise-feeds` -> `<RELEASE_NAME>-feeds`
  - `<RELEASE_NAME>-anchore-engine-enterprise-notifications` -> `<RELEASE_NAME>-enterprise-notifications`
  - `<RELEASE_NAME>-anchore-engine-enterprise-rbac` -> `<RELEASE_NAME>-enterprise-rbac-manager`
  - `<RELEASE_NAME>-anchore-engine-enterprise-reports` -> `<RELEASE_NAME>-enterprise-reports`
  - `<RELEASE_NAME>-anchore-engine-enterprise-ui` -> `<RELEASE_NAME>-enterprise-ui`
  - `<RELEASE_NAME>-anchore-engine-policy` -> `<RELEASE_NAME>-enterprise-policy`
  - `<RELEASE_NAME>-anchore-engine-simplequeue` -> `<RELEASE_NAME>-enterprise-simplequeue`

#### Labels, Annotations & Selectors

- Standard Kubernetes labels and annotations replace the custom ones used in Anchore Engine:
  - `component` -> `app.kubernetes.io/component`
  - `release` -> `app.kubernetes.io/instance`
  - `app` -> `app.kubernetes.io/name`
  - `chart` -> `helm.sh/chart`

#### Dependent Services

- The Feeds service is now deployed as a dependent chart, it can be configured using the [Feeds Values](https://github.com/anchore/anchore-charts/blob/main/stable/feeds/values.yaml)
- The bundled PostgreSQL chart has been replaced with the Bitnami PostgreSQL Chart as a dependency. Configuration options can be found in the [Postgresql Values](https://github.com/bitnami/charts/blob/main/bitnami/postgresql/values.yaml).

#### Upgrade Behavior

- Pre-upgrade Helm hooks, along with a Bitnami/kubectl init container, are used to terminate all pods before running the Anchore upgrade. You can revert to legacy post-upgrade hooks by setting `upgradeJob.usePostUpgradeHook=true`.

#### Application Configuration

- Configuration is now primarily managed through environment variables, specified in the `<RELEASE_NAME>-enterprise-config-env-vars` ConfigMap and set via the values file.
- Previously, unexposed values for advanced Anchore configurations have been removed. Instead, you can use the `extraEnv` value to set the required environment variables.

### Migration Rollback Strategy

The migration employs a blue/green deployment strategy to minimize risk and facilitate easy rollback. Should you encounter issues during the migration, reverting to the prior state is straightforward: simply scale your Anchore-Engine deployment back up.

For those using an external PostgreSQL database without the benefit of a blue/green deployment strategy, a manual database restoration is necessary. Utilize a pre-migration backup to restore the database to its previous version, and then proceed to scale your Anchore-Engine deployment back up.

See the [Migration Rollback Steps](#migration-rollback-steps) section for more details.

### Step-by-Step Migration Process

1. **Upgrade Existing Anchore Engine Deployment**: Upgrade your existing Anchore Engine deployment to chart version 1.28.0 or higher. This will ensure that your deployment is running Anchore Enterprise v4.9.x.

    ```shell
    export NAMESPACE=anchore
    export ENGINE_RELEASE=<YOUR_ENGINE_RELEASE_NAME> # Existing Engine release name
    export VALUES_FILE_NAME=my-values-file.yaml  # Existing Engine chart values file

    helm repo update
    helm upgrade ${ENGINE_RELEASE} -n ${NAMESPACE} anchore/anchore-engine -f ${VALUES_FILE_NAME} --version=^1.28.0
    ```

1. **Generate a New Enterprise Values File**: Use the migration script to convert your existing Anchore Engine values file to the new Anchore Enterprise format.

    >**Note**: This command mounts a local volume to persistently store the output files, it also mounts the input values file within the container for conversion. It's critical to review both the output logs and the new `output/enterprise.values.yaml` file before moving forward.

    ```shell
    export VALUES_FILE_NAME=my-values-file.yaml  # Existing Engine chart values file

    docker run -v ${PWD}:/tmp -v ${PWD}/${VALUES_FILE_NAME}:/app/${VALUES_FILE_NAME} docker.io/anchore/enterprise-helm-migrator:latest -e /app/${VALUES_FILE_NAME} -d /tmp/output
    ```

### If Using an External PostgreSQL Database

1. **Scale Down Anchore Engine**: To avoid data inconsistency, scale down your existing Anchore Engine deployment to zero replicas.

    ```shell
    export NAMESPACE=anchore
    export ENGINE_RELEASE=<YOUR_ENGINE_RELEASE_NAME>

    kubectl scale deployment --replicas=0 -l app=${ENGINE_RELEASE}-anchore-engine -n ${NAMESPACE}
    ```

1. **Perform database backup**: Backup your external database. See the official [PostgreSQL documentation](https://www.postgresql.org/docs/13/backup.html) for guidance. If using a managed cloud database service refer to their documentation.

1. **Perform database upgrade**: Upgrade your external database. See the official [PostgreSQL documentation](https://www.postgresql.org/docs/13/upgrading.html) for guidance. If using a managed cloud database service refer to their documentation.

    > Tip: Leveraging a backup to instantiate a new database instance enables a non-intrusive database upgrade and Enterprise chart migration. This approach preserves the integrity of your original database. By adopting a blue/green deployment strategy for the migration, you gain the advantage of effortless rollbacks in case of migration-related issues.

1. **(Optional) Update Database Hostname**: If you're employing a blue/green deployment strategy for the database upgrade, update the database hostname in your values file and/or existing Kubernetes secrets to point to your newly created database instance. This step is essential for properly configuring the Enterprise chart to use the new database.

1. **Deploy Anchore Enterprise**: Use the converted values file to deploy the new Anchore Enterprise Helm chart.

    >**Note:** If you are **not using existing secrets**, you will need to uncomment the `ADMIN_PASS` and `SET_ADMIN_PASS` export commands below. This is needed to ensure that your Enterprise deployment stores the correct Anchore admin password in the secret.

    ```shell
    export NAMESPACE=anchore
    export ENTERPRISE_RELEASE=<YOUR_ENTERPRISE_RELEASE_NAME>
    export ENTERPRISE_VALUES_FILE=${PWD}/output/enterprise.my-values-file.yaml

    # If you are not using existing secrets, uncomment the following export commands
    #
    # export ADMIN_PASS=$(kubectl get secret -n ${NAMESPACE} ${ENGINE_RELEASE}-anchore-engine-admin-pass -o jsonpath="{.data.ANCHORE_ADMIN_PASSWORD}" | base64 -d -)
    # export SET_ADMIN_PASS=("--set" "anchoreConfig.default_admin_password=${ADMIN_PASS}")

    helm install ${ENTERPRISE_RELEASE} -n ${NAMESPACE} ${SET_ADMIN_PASS[@]} -f ${ENTERPRISE_VALUES_FILE} anchore/enterprise --version=1.0.0
    ```

1. **Verification and Cleanup**: After confirming that the Anchore Enterprise deployment is functional, you can safely uninstall the old Anchore Engine deployment.

    ```shell
    export NAMESPACE=anchore
    export ENGINE_RELEASE=<YOUR_ENGINE_RELEASE_NAME>

    helm uninstall ${ENGINE_RELEASE} -n ${NAMESPACE}
    ```

    You may now have old engine persistent volume claims to delete. Delete these only when you are confident with the state of your new Enterprise Chart deployment.

      ```shell
      export NAMESPACE=anchore
      export ENGINE_RELEASE=<YOUR_ENGINE_RELEASE_NAME>

      kubectl get pvc -n ${NAMESPACE}
      kubectl delete pvc ${ENGINE_RELEASE}-anchore-engine-enterprise-feeds -n ${NAMESPACE}

### If Using the Dependent PostgreSQL Chart

1. **Scale Down Anchore Engine**: To avoid data inconsistency, scale down your existing Anchore Engine deployment to zero replicas.

    ```shell
    export NAMESPACE=anchore
    export ENGINE_RELEASE=<YOUR_ENGINE_RELEASE_NAME>

    kubectl scale deployment --replicas=0 -l app=${ENGINE_RELEASE}-anchore-engine -n ${NAMESPACE}
    ```

1. **Deploy Anchore Enterprise**: Use the converted values file to deploy the new Anchore Enterprise Helm chart.

    >**Note:** You will have to migrate data from the old database to the new one after the chart is installed. The enterprise chart contains a helper pod to aid with this. This helper pod is enabled using the `startMigrationPod=true` & `migrationAnchoreEngineSecretName=${ENGINE_RELEASE}-anchore-engine` flags in the following command.
    >
    > If you **are using existing secrets**, you should ignore setting the `ADMIN_PASS` and `SET_ADMIN_PASS` environment variables.

    ```shell
    export NAMESPACE=anchore
    export ENGINE_RELEASE=<YOUR_ENGINE_RELEASE_NAME>
    export ENTERPRISE_RELEASE=<YOUR_ENTERPRISE_RELEASE_NAME>
    export ENTERPRISE_VALUES_FILE=${PWD}/output/enterprise.my-values-file.yaml  # The converted file

    # If you are using existing secrets, ignore the following export commands
    #
    export ADMIN_PASS=$(kubectl get secret -n ${NAMESPACE} ${ENGINE_RELEASE}-anchore-engine-admin-pass -o jsonpath="{.data.ANCHORE_ADMIN_PASSWORD}" | base64 -d -)
    export SET_ADMIN_PASS=("--set" "anchoreConfig.default_admin_password=${ADMIN_PASS}")

    helm install ${ENTERPRISE_RELEASE} -n ${NAMESPACE} --set startMigrationPod=true --set migrationAnchoreEngineSecretName=${ENGINE_RELEASE}-anchore-engine ${SET_ADMIN_PASS[@]} anchore/enterprise -f ${ENTERPRISE_VALUES_FILE} --version=1.0.0
    ```

1. **Scale Down Anchore Enterprise**: Before migrating the database, scale down the new Anchore Enterprise deployment to zero replicas.

    ```shell
    export NAMESPACE=anchore
    export ENTERPRISE_RELEASE=<YOUR_ENTERPRISE_RELEASE_NAME>

    kubectl scale deployment -n ${NAMESPACE} --replicas=0 -l app.kubernetes.io/instance=${ENTERPRISE_RELEASE}
    ```

1. **Database Preparation**: Replace the existing Anchore database schema with a new database schema in the PostgreSQL 13 deployment. If you set `startMigrationPod=true` as per the step above, you can exec into the migrator pod using the following commands:

    ```shell
    export NAMESPACE=anchore
    export ENTERPRISE_RELEASE=<YOUR_ENTERPRISE_RELEASE_NAME>

    kubectl -n ${NAMESPACE} exec -it ${ENTERPRISE_RELEASE}-enterprise-migrate-db -- /bin/bash -c 'PGPASSWORD=${NEW_DB_PASSWORD} dropdb -h ${NEW_DB_HOST} -U ${NEW_DB_USERNAME} ${NEW_DB_NAME}; PGPASSWORD=${NEW_DB_PASSWORD} psql -h ${NEW_DB_HOST}  -U ${NEW_DB_USERNAME} -c "CREATE DATABASE ${NEW_DB_NAME}" postgres'
    ```

1. **Data Migration**: Migrate data from the old Anchore Engine database to the new Anchore Enterprise database.

    - If you are using the migration helper pod, exec into that pod and perform the database migration using following commands:

        ```shell
        export NAMESPACE=anchore
        export ENTERPRISE_RELEASE=<YOUR_ENTERPRISE_RELEASE_NAME>

        kubectl -n ${NAMESPACE} exec -it ${ENTERPRISE_RELEASE}-enterprise-migrate-db -- /bin/bash -c 'PGPASSWORD=${OLD_DB_PASSWORD} pg_dump -h ${OLD_DB_HOST} -U ${OLD_DB_USERNAME} -c ${OLD_DB_NAME} | PGPASSWORD=${NEW_DB_PASSWORD} psql -h ${NEW_DB_HOST} -U ${NEW_DB_USERNAME} ${NEW_DB_NAME}'
        ```

    - If you are using your own pod then follow these steps

         1. Gather old DB parameters from the secret ${OLD_ENGINE_RELEASE}-anchore-engine
         1. Gather new DB parameters from the new secret ${NEW_ENTERPRISE_RELEASE}-enterprise
         1. Start a migration pod that has all the psql binaries required e.g. docker.io/postgresql:13
         1. Export all the required environment variables

        ```shell
        PGPASSWORD=${OLD_DB_PASSWORD} pg_dump -h ${OLD_DB_HOST} -U ${OLD_DB_USERNAME} -c ${OLD_DB_NAME} | PGPASSWORD=${NEW_DB_PASSWORD} psql -h ${NEW_DB_HOST} -U ${NEW_DB_USERNAME} ${NEW_DB_NAME}
        ```

1. **Upgrade Anchore Enterprise**: After migrating the data, upgrade the Anchore Enterprise Helm deployment.

    ```shell
    export NAMESPACE=anchore
    export ENTERPRISE_RELEASE=<YOUR_ENTERPRISE_RELEASE_NAME>
    export ENTERPRISE_VALUES_FILE=${PWD}/output/enterprise.my-values-file.yaml  # The converted file

    helm upgrade ${ENTERPRISE_RELEASE} -n ${NAMESPACE} --set startMigrationPod=false anchore/enterprise -f ${ENTERPRISE_VALUES_FILE} --version=1.0.0
    ```

1. **Final Verification and Cleanup**: After ensuring the new deployment is operational, uninstall the old Anchore Engine deployment.

    ```shell
    export NAMESPACE=anchore
    export ENGINE_RELEASE=<YOUR_ENGINE_RELEASE_NAME>

    helm uninstall ${ENGINE_RELEASE} -n ${NAMESPACE}
    ```

    You may now have old engine persistent volume claims to delete. Delete these only when you are confident with the state of your new Enterprise Chart deployment.

    ```shell
    export NAMESPACE=anchore
    export ENGINE_RELEASE=<YOUR_ENGINE_RELEASE_NAME>

    kubectl get pvc -n ${NAMESPACE}
    kubectl delete pvc ${ENGINE_RELEASE}-anchore-engine-enterprise-feeds -n ${NAMESPACE}
    kubectl delete pvc ${ENGINE_RELEASE}-anchore-feeds-db -n ${NAMESPACE}
    kubectl delete pvc ${ENGINE_RELEASE}-postgresql -n ${NAMESPACE}
    ```

### Migration Rollback Steps

In case of issues during the migration, execute the following rollback steps:

1. **Uninstall the Anchore Enterprise Chart**: Remove the Anchore Enterprise deployment from your cluster.
1. **Remove Migrated Values File**: Delete the `output` directory generated by the migration script.
1. **Erase Enterprise Database**: Delete the database associated with the Anchore Enterprise deployment.
1. **(Optional) Restore Anchore-Engine Database**: If necessary, restore the Anchore-Engine database from a backup.
1. **Reactivate Anchore Engine**: Scale the Anchore Engine deployment back to its original state.
1. **Retry Migration**: Re-attempt the migration process following the initial steps.

This rollback procedure is designed to revert your environment to its pre-migration state, allowing for a fresh migration attempt.

## Parameters

### Global Resource Parameters

| Name                      | Description                             | Value |
| ------------------------- | --------------------------------------- | ----- |
| `global.fullnameOverride` | overrides the fullname set on resources | `""`  |
| `global.nameOverride`     | overrides the name set on resources     | `""`  |

### Common Resource Parameters

| Name                                  | Description                                                                           | Value                                 |
| ------------------------------------- | ------------------------------------------------------------------------------------- | ------------------------------------- |
| `image`                               | Image used for all Anchore Enterprise deployments, excluding Anchore UI               | `docker.io/anchore/enterprise:v5.1.0` |
| `imagePullPolicy`                     | Image pull policy used by all deployments                                             | `IfNotPresent`                        |
| `imagePullSecretName`                 | Name of Docker credentials secret for access to private repos                         | `anchore-enterprise-pullcreds`        |
| `startMigrationPod`                   | Spin up a Database migration pod to help migrate the database to the new schema       | `false`                               |
| `migrationPodImage`                   | The image reference to the migration pod                                              | `docker.io/postgres:13-bookworm`      |
| `migrationAnchoreEngineSecretName`    | The name of the secret that has anchore-engine values                                 | `my-engine-anchore-engine`            |
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
| `scripts`                             | Collection of helper scripts usable in all anchore enterprise pods                    | `{}`                                  |

### Anchore Configuration Parameters

| Name                                                                           | Description                                                                                                                      | Value              |
| ------------------------------------------------------------------------------ | -------------------------------------------------------------------------------------------------------------------------------- | ------------------ |
| `anchoreConfig.service_dir`                                                    | Path to directory where default Anchore config files are placed at startup                                                       | `/anchore_service` |
| `anchoreConfig.log_level`                                                      | The log level for Anchore services                                                                                               | `INFO`             |
| `anchoreConfig.allow_awsecr_iam_auto`                                          | Enable AWS IAM instance role for ECR auth                                                                                        | `true`             |
| `anchoreConfig.keys.secret`                                                    | The shared secret used for signing & encryption, auto-generated by Helm if not set.                                              | `""`               |
| `anchoreConfig.keys.privateKeyFileName`                                        | The file name of the private key used for signing & encryption, found in the k8s secret specified in .Values.certStoreSecretName | `""`               |
| `anchoreConfig.keys.publicKeyFileName`                                         | The file name of the public key used for signing & encryption, found in the k8s secret specified in .Values.certStoreSecretName  | `""`               |
| `anchoreConfig.user_authentication.oauth.enabled`                              | Enable OAuth for Anchore user authentication                                                                                     | `true`             |
| `anchoreConfig.user_authentication.oauth.default_token_expiration_seconds`     | The expiration, in seconds, for OAuth tokens                                                                                     | `3600`             |
| `anchoreConfig.user_authentication.oauth.refresh_token_expiration_seconds`     | The expiration, in seconds, for OAuth refresh tokens                                                                             | `86400`            |
| `anchoreConfig.user_authentication.allow_api_keys_for_saml_users`              | Enable API key generation and authentication for SAML users                                                                      | `false`            |
| `anchoreConfig.user_authentication.max_api_key_age_days`                       | The maximum age, in days, for API keys                                                                                           | `365`              |
| `anchoreConfig.user_authentication.max_api_keys_per_user`                      | The maximum number of API keys per user                                                                                          | `100`              |
| `anchoreConfig.user_authentication.hashed_passwords`                           | Enable storing passwords as secure hashes in the database                                                                        | `true`             |
| `anchoreConfig.user_authentication.sso_require_existing_users`                 | set to true in order to disable the SSO JIT provisioning during authentication                                                   | `false`            |
| `anchoreConfig.metrics.enabled`                                                | Enable Prometheus metrics for all Anchore services                                                                               | `false`            |
| `anchoreConfig.metrics.auth_disabled`                                          | Disable auth on Prometheus metrics for all Anchore services                                                                      | `false`            |
| `anchoreConfig.webhooks`                                                       | Enable Anchore services to provide webhooks for external system updates                                                          | `{}`               |
| `anchoreConfig.default_admin_password`                                         | The password for the Anchore Enterprise admin user                                                                               | `""`               |
| `anchoreConfig.default_admin_email`                                            | The email address used for the Anchore Enterprise admin user                                                                     | `admin@myanchore`  |
| `anchoreConfig.database.timeout`                                               |                                                                                                                                  | `120`              |
| `anchoreConfig.database.ssl`                                                   | Enable SSL/TLS for the database connection                                                                                       | `false`            |
| `anchoreConfig.database.sslMode`                                               | The SSL mode to use for database connection                                                                                      | `verify-full`      |
| `anchoreConfig.database.sslRootCertFileName`                                   | File name of the database root CA certificate stored in the k8s secret specified with .Values.certStoreSecretName                | `""`               |
| `anchoreConfig.database.db_pool_size`                                          | The database max connection pool size                                                                                            | `30`               |
| `anchoreConfig.database.db_pool_max_overflow`                                  | The maximum overflow size of the database connection pool                                                                        | `100`              |
| `anchoreConfig.database.engineArgs`                                            | Set custom database engine arguments for SQLAlchemy                                                                              | `{}`               |
| `anchoreConfig.internalServicesSSL.enabled`                                    | Force all Enterprise services to use SSL for internal communication                                                              | `false`            |
| `anchoreConfig.internalServicesSSL.verifyCerts`                                | Enable cert verification against the local cert bundle, if this set to false self-signed certs are allowed                       | `false`            |
| `anchoreConfig.internalServicesSSL.certSecretKeyFileName`                      | File name of the private key used for internal SSL stored in the secret specified in .Values.certStoreSecretName                 | `""`               |
| `anchoreConfig.internalServicesSSL.certSecretCertFileName`                     | File name of the root CA certificate used for internal SSL stored in the secret specified in .Values.certStoreSecretName         | `""`               |
| `anchoreConfig.policyBundles`                                                  | Include custom Anchore policy bundles                                                                                            | `{}`               |
| `anchoreConfig.apiext.external.enabled`                                        | Allow overrides for constructing Anchore API URLs                                                                                | `false`            |
| `anchoreConfig.apiext.external.useTLS`                                         | Enable TLS for external API access                                                                                               | `true`             |
| `anchoreConfig.apiext.external.hostname`                                       | Hostname for the external Anchore API                                                                                            | `""`               |
| `anchoreConfig.apiext.external.port`                                           | Port configured for external Anchore API                                                                                         | `8443`             |
| `anchoreConfig.analyzer.cycle_timers.image_analyzer`                           | The interval between checks of the work queue for new analysis jobs                                                              | `1`                |
| `anchoreConfig.analyzer.layer_cache_max_gigabytes`                             | Specify a cache size > 0GB to enable image layer caching                                                                         | `0`                |
| `anchoreConfig.analyzer.enable_hints`                                          | Enable a user-supplied 'hints' file to override and/or augment the software artifacts found during analysis                      | `false`            |
| `anchoreConfig.analyzer.configFile`                                            | Custom Anchore Analyzer configuration file contents in YAML                                                                      | `{}`               |
| `anchoreConfig.catalog.cycle_timers.image_watcher`                             | Interval (seconds) to check for an update to a tag                                                                               | `3600`             |
| `anchoreConfig.catalog.cycle_timers.policy_eval`                               | Interval (seconds) to run a policy evaluation on images with policy_eval subscription activated                                  | `3600`             |
| `anchoreConfig.catalog.cycle_timers.vulnerability_scan`                        | Interval to run a vulnerability scan on images with vuln_update subscription activated                                           | `14400`            |
| `anchoreConfig.catalog.cycle_timers.analyzer_queue`                            | Interval to add new work on the image analysis queue                                                                             | `1`                |
| `anchoreConfig.catalog.cycle_timers.archive_tasks`                             | Interval to trigger Anchore Catalog archive Tasks                                                                                | `43200`            |
| `anchoreConfig.catalog.cycle_timers.notifications`                             | Interval in which notifications will be processed for state changes                                                              | `30`               |
| `anchoreConfig.catalog.cycle_timers.service_watcher`                           | Interval of service state update poll, used for system status                                                                    | `15`               |
| `anchoreConfig.catalog.cycle_timers.policy_bundle_sync`                        | Interval of policy bundle sync                                                                                                   | `300`              |
| `anchoreConfig.catalog.cycle_timers.repo_watcher`                              | Interval between checks to repo for new tags                                                                                     | `60`               |
| `anchoreConfig.catalog.cycle_timers.image_gc`                                  | Interval for garbage collection of images marked for deletion                                                                    | `60`               |
| `anchoreConfig.catalog.cycle_timers.k8s_image_watcher`                         | Interval for the runtime inventory image analysis poll                                                                           | `150`              |
| `anchoreConfig.catalog.cycle_timers.resource_metrics`                          | Interval (seconds) for computing metrics from the DB                                                                             | `60`               |
| `anchoreConfig.catalog.cycle_timers.events_gc`                                 | Interval (seconds) for cleaning up events in the system based on timestamp                                                       | `43200`            |
| `anchoreConfig.catalog.cycle_timers.artifact_lifecycle_policy_tasks`           | Interval (seconds) for running artifact lifecycle policy tasks                                                                   | `43200`            |
| `anchoreConfig.catalog.event_log`                                              | Event log for webhooks, YAML configuration                                                                                       | `{}`               |
| `anchoreConfig.catalog.analysis_archive`                                       | Custom analysis archive YAML configuration                                                                                       | `{}`               |
| `anchoreConfig.catalog.object_store`                                           | Custom object storage YAML configuration                                                                                         | `{}`               |
| `anchoreConfig.catalog.runtime_inventory.inventory_ttl_days`                   | TTL for runtime inventory.                                                                                                       | `120`              |
| `anchoreConfig.catalog.runtime_inventory.inventory_ingest_overwrite`           | force runtime inventory to be overwritten upon every update for that reported context.                                           | `false`            |
| `anchoreConfig.catalog.down_analyzer_task_requeue`                             | Allows fast re-queueing when image status is 'analyzing' on an analyzer that is no longer in the 'up' state                      | `true`             |
| `anchoreConfig.policy_engine.cycle_timers.feed_sync`                           | Interval to run a feed sync to get latest cve data                                                                               | `14400`            |
| `anchoreConfig.policy_engine.cycle_timers.feed_sync_checker`                   | Interval between checks to see if there needs to be a task queued                                                                | `3600`             |
| `anchoreConfig.policy_engine.overrideFeedsToUpstream`                          | Override the Anchore Feeds URL to use the public upstream Anchore Feeds                                                          | `false`            |
| `anchoreConfig.notifications.cycle_timers.notifications`                       | Interval that notifications are sent                                                                                             | `30`               |
| `anchoreConfig.notifications.ui_url`                                           | Set the UI URL that is included in the notification, defaults to the Enterprise UI service name                                  | `""`               |
| `anchoreConfig.reports.enable_graphiql`                                        | Enable GraphiQL, a GUI for editing and testing GraphQL queries and mutations                                                     | `true`             |
| `anchoreConfig.reports.async_execution_timeout`                                | Configure how long a scheduled query must be running for before it is considered timed out                                       | `48h`              |
| `anchoreConfig.reports_worker.enable_data_ingress`                             | Enable periodically syncing data into the Anchore Reports Service                                                                | `true`             |
| `anchoreConfig.reports_worker.enable_data_egress`                              | Periodically remove reporting data that has been removed in other parts of system                                                | `false`            |
| `anchoreConfig.reports_worker.data_egress_window`                              | defines a number of days to keep reporting data following its deletion in the rest of system.                                    | `0`                |
| `anchoreConfig.reports_worker.data_refresh_max_workers`                        | The maximum number of concurrent threads to refresh existing results (etl vulnerabilities and evaluations) in reports service.   | `10`               |
| `anchoreConfig.reports_worker.data_load_max_workers`                           | The maximum number of concurrent threads to load new results (etl vulnerabilities and evaluations) to reports service.           | `10`               |
| `anchoreConfig.reports_worker.cycle_timers.reports_image_load`                 | Interval that vulnerabilities for images are synced                                                                              | `600`              |
| `anchoreConfig.reports_worker.cycle_timers.reports_tag_load`                   | Interval that vulnerabilties by tags are synced                                                                                  | `600`              |
| `anchoreConfig.reports_worker.cycle_timers.reports_runtime_inventory_load`     | Interval that the runtime inventory is synced                                                                                    | `600`              |
| `anchoreConfig.reports_worker.cycle_timers.reports_extended_runtime_vuln_load` | Interval extended runtime reports are synched (ecs, k8s containers and namespaces)                                               | `1800`             |
| `anchoreConfig.reports_worker.cycle_timers.reports_image_refresh`              | Interval that images are refreshed                                                                                               | `7200`             |
| `anchoreConfig.reports_worker.cycle_timers.reports_tag_refresh`                | Interval that tags are refreshed                                                                                                 | `7200`             |
| `anchoreConfig.reports_worker.cycle_timers.reports_metrics`                    | Interval for how often reporting metrics are generated                                                                           | `3600`             |
| `anchoreConfig.reports_worker.cycle_timers.reports_image_egress`               | Interval stale states are removed by image                                                                                       | `600`              |
| `anchoreConfig.reports_worker.cycle_timers.reports_tag_egress`                 | Interval stale states are removed by tag                                                                                         | `600`              |
| `anchoreConfig.ui.enable_proxy`                                                | Trust a reverse proxy when setting secure cookies (via the `X-Forwarded-Proto` header)                                           | `false`            |
| `anchoreConfig.ui.enable_ssl`                                                  | Enable SSL in the Anchore UI container                                                                                           | `false`            |
| `anchoreConfig.ui.enable_shared_login`                                         | Allow single user to start multiple Anchore UI sessions                                                                          | `true`             |
| `anchoreConfig.ui.redis_flushdb`                                               | Flush user session keys and empty data on Anchore UI startup                                                                     | `true`             |
| `anchoreConfig.ui.force_websocket`                                             | Force WebSocket protocol for socket message communications                                                                       | `false`            |
| `anchoreConfig.ui.authentication_lock.count`                                   | Number of failed authentication attempts allowed before a temporary lock is applied                                              | `5`                |
| `anchoreConfig.ui.authentication_lock.expires`                                 | Authentication lock duration                                                                                                     | `300`              |
| `anchoreConfig.ui.custom_links`                                                | List of up to 10 external links provided                                                                                         | `{}`               |
| `anchoreConfig.ui.enable_add_repositories`                                     | Specify what users can add image repositories to the Anchore UI                                                                  | `{}`               |
| `anchoreConfig.ui.log_level`                                                   | Descriptive detail of the application log output                                                                                 | `http`             |
| `anchoreConfig.ui.enrich_inventory_view`                                       | aggregate and include compliance and vulnerability data from the reports service.                                                | `true`             |
| `anchoreConfig.ui.appdb_config.native`                                         | toggle the postgreSQL drivers used to connect to the database between the native and the NodeJS drivers.                         | `true`             |
| `anchoreConfig.ui.appdb_config.pool.max`                                       | maximum number of simultaneous connections allowed in the connection pool                                                        | `10`               |
| `anchoreConfig.ui.appdb_config.pool.min`                                       | minimum number of connections                                                                                                    | `0`                |
| `anchoreConfig.ui.appdb_config.pool.acquire`                                   | the timeout in milliseconds used when acquiring a new connection                                                                 | `30000`            |
| `anchoreConfig.ui.appdb_config.pool.idle`                                      | the maximum time that a connection can be idle before being released                                                             | `10000`            |
| `anchoreConfig.ui.dbUser`                                                      | allows overriding and separation of the ui database user.                                                                        | `""`               |
| `anchoreConfig.ui.dbPassword`                                                  | allows overriding and separation of the ui database user authentication                                                          | `""`               |

### Anchore API k8s Deployment Parameters

| Name                      | Description                                          | Value       |
| ------------------------- | ---------------------------------------------------- | ----------- |
| `api.replicaCount`        | Number of replicas for Anchore API deployment        | `1`         |
| `api.service.type`        | Service type for Anchore API                         | `ClusterIP` |
| `api.service.port`        | Service port for Anchore API                         | `8228`      |
| `api.service.reportsPort` | Service port for Anchore Reports API                 | `8558`      |
| `api.service.annotations` | Annotations for Anchore API service                  | `{}`        |
| `api.service.labels`      | Labels for Anchore API service                       | `{}`        |
| `api.service.nodePort`    | nodePort for Anchore API service                     | `""`        |
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
| `catalog.service.nodePort`    | nodePort for Anchore Catalog service                     | `""`        |
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
| `policyEngine.service.nodePort`    | nodePort for Anchore Policy Engine service                     | `""`        |
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
| `simpleQueue.service.nodePort`    | nodePort for Anchore Simple Queue service                     | `""`        |
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
| `notifications.service.nodePort`    | nodePort for Anchore Notifications service                     | `""`        |
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
| `reports.service.nodePort`    | nodePort for Anchore Reports service                     | `""`        |
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
| `rbacManager.service.nodePort`    | nodePort for Anchore RBAC Manager service                     | `""`        |
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
| `ui.image`                   | Image used for the Anchore UI container                                       | `docker.io/anchore/enterprise-ui:v5.1.0` |
| `ui.imagePullPolicy`         | Image pull policy for Anchore UI image                                        | `IfNotPresent`                           |
| `ui.existingSecretName`      | Name of an existing secret to be used for Anchore UI DB and Redis endpoints   | `anchore-enterprise-ui-env`              |
| `ui.ldapsRootCaCertName`     | Name of the custom CA certificate file store in `.Values.certStoreSecretName` | `""`                                     |
| `ui.service.type`            | Service type for Anchore UI                                                   | `ClusterIP`                              |
| `ui.service.port`            | Service port for Anchore UI                                                   | `80`                                     |
| `ui.service.annotations`     | Annotations for Anchore UI service                                            | `{}`                                     |
| `ui.service.labels`          | Labels for Anchore UI service                                                 | `{}`                                     |
| `ui.service.sessionAffinity` | Session Affinity for Ui service                                               | `ClientIP`                               |
| `ui.service.nodePort`        | nodePort for Anchore UI service                                               | `""`                                     |
| `ui.extraEnv`                | Set extra environment variables for Anchore UI pods                           | `[]`                                     |
| `ui.resources`               | Resource requests and limits for Anchore UI pods                              | `{}`                                     |
| `ui.labels`                  | Labels for Anchore UI pods                                                    | `{}`                                     |
| `ui.annotations`             | Annotation for Anchore UI pods                                                | `{}`                                     |
| `ui.nodeSelector`            | Node labels for Anchore UI pod assignment                                     | `{}`                                     |
| `ui.tolerations`             | Tolerations for Anchore UI pod assignment                                     | `[]`                                     |
| `ui.affinity`                | Affinity for Anchore ui pod assignment                                        | `{}`                                     |
| `ui.serviceAccountName`      | Service account name for Anchore UI pods                                      | `""`                                     |

### Anchore Upgrade Job Parameters

| Name                                 | Description                                                                                                                                     | Value                  |
| ------------------------------------ | ----------------------------------------------------------------------------------------------------------------------------------------------- | ---------------------- |
| `upgradeJob.enabled`                 | Enable the Anchore Enterprise database upgrade job                                                                                              | `true`                 |
| `upgradeJob.force`                   | Force the Anchore Feeds database upgrade job to run as a regular job instead of as a Helm hook                                                  | `false`                |
| `upgradeJob.rbacCreate`              | Create RBAC resources for the Anchore upgrade job                                                                                               | `true`                 |
| `upgradeJob.serviceAccountName`      | Use an existing service account for the Anchore upgrade job                                                                                     | `""`                   |
| `upgradeJob.usePostUpgradeHook`      | Use a Helm post-upgrade hook to run the upgrade job instead of the default pre-upgrade hook. This job does not require creating RBAC resources. | `false`                |
| `upgradeJob.kubectlImage`            | The image to use for the upgrade job's init container that uses kubectl to scale down deployments before an upgrade                             | `bitnami/kubectl:1.27` |
| `upgradeJob.nodeSelector`            | Node labels for the Anchore upgrade job pod assignment                                                                                          | `{}`                   |
| `upgradeJob.tolerations`             | Tolerations for the Anchore upgrade job pod assignment                                                                                          | `[]`                   |
| `upgradeJob.affinity`                | Affinity for the Anchore upgrade job pod assignment                                                                                             | `{}`                   |
| `upgradeJob.annotations`             | Annotations for the Anchore upgrade job                                                                                                         | `{}`                   |
| `upgradeJob.resources`               | Resource requests and limits for the Anchore upgrade job                                                                                        | `{}`                   |
| `upgradeJob.labels`                  | Labels for the Anchore upgrade job                                                                                                              | `{}`                   |
| `upgradeJob.ttlSecondsAfterFinished` | The time period in seconds the upgrade job, and it's related pods should be retained for                                                        | `-1`                   |

### Ingress Parameters

| Name                       | Description                                                        | Value                  |
| -------------------------- | ------------------------------------------------------------------ | ---------------------- |
| `ingress.enabled`          | Create an ingress resource for external Anchore service APIs       | `false`                |
| `ingress.labels`           | Labels for the ingress resource                                    | `{}`                   |
| `ingress.annotations`      | Annotations for the ingress resource                               | `{}`                   |
| `ingress.apiHosts`         | List of custom hostnames for the Anchore API                       | `[]`                   |
| `ingress.apiPaths`         | The path used for accessing the Anchore API                        | `["/v2/","/version/"]` |
| `ingress.uiHosts`          | List of custom hostnames for the Anchore UI                        | `[]`                   |
| `ingress.uiPath`           | The path used for accessing the Anchore UI                         | `/`                    |
| `ingress.feedsHosts`       | List of custom hostnames for the Anchore Feeds API                 | `[]`                   |
| `ingress.feedsPaths`       | The path used for accessing the Anchore Feeds API                  | `["/v2/feeds/"]`       |
| `ingress.reportsHosts`     | List of custom hostnames for the Anchore Reports API               | `[]`                   |
| `ingress.reportsPaths`     | The path used for accessing the Anchore Reports API                | `["/v2/reports/"]`     |
| `ingress.tls`              | Configure tls for the ingress resource                             | `[]`                   |
| `ingress.ingressClassName` | sets the ingress class name. As of k8s v1.18, this should be nginx | `nginx`                |

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

| Name                                  | Description                                                                                      | Value               |
| ------------------------------------- | ------------------------------------------------------------------------------------------------ | ------------------- |
| `ui-redis.chartEnabled`               | Use the dependent chart for the UI Redis deployment                                              | `true`              |
| `ui-redis.externalEndpoint`           | External Redis endpoint when not using Helm managed chart (eg redis://:<password>@hostname:6379) | `""`                |
| `ui-redis.auth.password`              | Password used for connecting to Redis                                                            | `anchore-redis,123` |
| `ui-redis.architecture`               | Redis deployment architecture                                                                    | `standalone`        |
| `ui-redis.master.persistence.enabled` | enables persistence                                                                              | `false`             |

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

For the latest updates and features in Anchore Enterprise, see the official [Release Notes](https://docs.anchore.com/current/docs/releasenotes/).

- **Major Chart Version Change (e.g., v0.1.2 -> v1.0.0)**: Signifies an incompatible breaking change that necessitates manual intervention, such as updates to your values file or data migrations.
- **Minor Chart Version Change (e.g., v0.1.2 -> v0.2.0)**: Indicates a significant change to the deployment that does not require manual intervention.
- **Patch Chart Version Change (e.g., v0.1.2 -> v0.1.3)**: Indicates a backwards-compatible bug fix or documentation update.

### V2.2.0

- The following keys were changed:
    1. anchoreConfig.user_authentication.oauth.allow_api_keys_for_saml_users -> anchoreConfig.user_authentication.allow_api_keys_for_saml_users
    2. anchoreConfig.user_authentication.oauth.max_api_key_age_days -> anchoreConfig.user_authentication.max_api_key_age_days
    3. anchoreConfig.user_authentication.oauth.max_api_keys_per_user -> anchoreConfig.user_authentication.max_api_keys_per_user

### V2.1.0

- Deploys Anchore Enterprise v5.1.0. See the [Release Notes](https://docs.anchore.com/current/docs/releasenotes/510/) for more information.
- The Redis client utilized by the UI has been updated and no longer requires a username to be specified in the URI. The chart configuration has been updated to reflect this change. If you are using secrets generated by the chart, no action is required.

  - :warning: **WARNING:** If you are using existing secrets, you will need to update your ANCHORE_REDIS_URI environment variable to remove the `nouser` username. The UI will not function without this change. For example:

    ```yaml
    ANCHORE_REDIS_URI: redis://:anchore-redis,123@anchore-ui-redis:6379
    ```

### v2.0.0

- Deploys Anchore Enterprise v5.0.0
- Anchore Enterprise v5.0.0 introduces a breaking change to the API endpoints, and requires updating any external integrations to use the new endpoints. See the [Migration Guide](https://docs.anchore.com/current/docs/deployment/upgrade/5.0/) for more information.
- The following values were removed as only the `v2` API is supported in Anchore Enterprise 5.0.0:
  - `api.service.apiVersion`
  - `notifications.service.apiVersion`
  - `reports.service.apiVersion`
  - `rbacManager.service.apiVersion`
  - `feeds.service.apiVersion`

### v1.0.0

- This is a stable release of the Anchore Enterprise Helm chart and is recommended for production deployments.
- Deploys Anchore Enterprise v4.9.3.
- This version of the chart is required for the migration from the anchore-engine chart, and is a pre-requisite for Anchore Enterprise 5.0.

### v0.x.x

- This is a pre-release version of the Anchore Enterprise Helm chart and is not recommended for production deployments.
