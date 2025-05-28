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
  - [Analyzer Image Layer Cache Configuration](#analyzer-image-layer-cache-configuration)
  - [Configuring Object Storage](#configuring-object-storage)
  - [Configuring Analysis Archive Storage](#configuring-analysis-archive-storage)
  - [Existing Secrets](#existing-secrets)
  - [Ingress](#ingress)
  - [Prometheus Metrics](#prometheus-metrics)
  - [Scaling Individual Services](#scaling-individual-services)
  - [Using TLS Internally](#using-tls-internally)
- [Object storage migration](#object-storage-migration)
- [Parameters](#parameters)
- [Release Notes](#release-notes)

## Prerequisites

- [Helm](https://helm.sh/) >=3.8
- [Kubernetes](https://kubernetes.io/) >=1.23

## Installing the Chart

This guide covers deploying Anchore Enterprise on a Kubernetes cluster with the default configuration. Refer to the [Configuration](#configuration) section for additional guidance on production deployments.

1. **Create a Kubernetes Secret for License File**: Generate a Kubernetes secret to store your Anchore Enterprise license file.

    ```shell
    export NAMESPACE=anchore
    export LICENSE_PATH="license.yaml"

    kubectl create secret generic anchore-enterprise-license --from-file=license.yaml=${LICENSE_PATH} -n ${NAMESPACE}
    ```

2. **Create a Kubernetes Secret for DockerHub Credentials**: Generate another Kubernetes secret for DockerHub credentials. These credentials should have access to private Anchore Enterprise repositories. We recommend that you create a brand new DockerHub user for these pull credentials. Contact [Anchore Support](https://get.anchore.com/contact/) to obtain access.

    ```shell
    export NAMESPACE=anchore
    export DOCKERHUB_PASSWORD="password"
    export DOCKERHUB_USER="username"
    export DOCKERHUB_EMAIL="example@email.com"

    kubectl create secret docker-registry anchore-enterprise-pullcreds --docker-server=docker.io --docker-username=${DOCKERHUB_USER} --docker-password=${DOCKERHUB_PASSWORD} --docker-email=${DOCKERHUB_EMAIL} -n ${NAMESPACE}
    ```

3. **Add Chart Repository & Deploy Anchore Enterprise**: Create a custom values file, named `anchore_values.yaml`, to override any chart parameters. Refer to the [Parameters](#parameters) section for available options.

    > :exclamation: **Important**: Default passwords are specified in the chart. It's highly recommended to modify these before deploying.

    ```shell
    export NAMESPACE=anchore
    export RELEASE=my-release

    helm repo add anchore https://charts.anchore.io
    helm install ${RELEASE} -n ${NAMESPACE} anchore/enterprise -f anchore_values.yaml
    ```

    > **Note**: This command installs Anchore Enterprise with a chart-managed PostgreSQL database, which may not be suitable for production use. See the [External Database](#external-database-requirements) section for details on using an external database.

4. **Post-Installation Steps**: Anchore Enterprise will take some time to initialize. Use the following [anchorectl](https://docs.anchore.com/current/docs/deployment/anchorectl/) commands to check the system status:

    ```shell
    export NAMESPACE=anchore
    export RELEASE=my-release
    export ANCHORECTL_URL=http://localhost:8228/v1/
    export ANCHORECTL_PASSWORD=$(kubectl get secret -n ${NAMESPACE} "${RELEASE}-enterprise" -o jsonpath='{.data.ANCHORE_ADMIN_PASSWORD}' | base64 -d -)

    kubectl port-forward -n ${NAMESPACE} svc/${RELEASE}-enterprise-api 8228:8228 # port forward for anchorectl in another terminal
    anchorectl system status # anchorectl defaults to the user admin, and to the password ${ANCHORECTL_PASSWORD} automatically if set
    ```

    > **Tip**: List all releases using `helm list`

### Installing on Openshift

You will need to either disable or properly set the parameters for `containerSecurityContext`, `runAsUser`, and `fsGroup` for the `ui-redis` and any PostgreSQL database that you deploy using the Enterprise chart (e.g., via `postgresql.chartEnabled`). Also, by default, Anchore Enterprise creates a user that normally runs the application with a uid/gid/group of 1000. If your deployment uses any other user as openshift usually does, you will need to update the HOME environment variable to a directory where the analyzer service can write to.

For example:

1. **Deploy the enterprise chart with appropriate values:**

    ```shell
    helm install anchore anchore/enterprise \
      --set securityContext.fsGroup=null \
      --set securityContext.runAsGroup=null \
      --set securityContext.runAsUser=null \
      --set postgresql.primary.containerSecurityContext.enabled=false \
      --set postgresql.primary.podSecurityContext.enabled=false \
      --set ui-redis.master.podSecurityContext.enabled=false \
      --set ui-redis.master.containerSecurityContext.enabled=false \
      --set analyzer.extraEnv[0].name=HOME \
      --set analyzer.extraEnv[0].value=/tmp
    ```

    > **Note:** disabling the containerSecurityContext and podSecurityContext may not be suitable for production. See [Redhat's documentation](https://docs.openshift.com/container-platform/4.13/authentication/managing-security-context-constraints.html#managing-pod-security-policies) on what may be suitable for production. For more information on the openshift.io/sa.scc.uid-range annotation, see the [openshift docs](https://docs.openshift.com/dedicated/authentication/managing-security-context-constraints.html#security-context-constraints-pre-allocated-values_configuring-internal-oauth)

#### Example Openshift values file

```yaml
# NOTE: This is not a production ready values file for an openshift deployment.

securityContext:
  fsGroup: null
  runAsGroup: null
  runAsUser: null
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
analyzer:
  extraEnv:
    - name: HOME
      value: /tmp
```

## Upgrading the Chart

> :exclamation: **Important:** View the **[Chart Release Notes](#release-notes)** for the latest changes prior to upgrading.

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

#### RDS Postgres Database Configuration

Please note that automatic password rotation using AWS Secrets Manager is enabled by default upon provisioning a new RDS cluster however this feature is not currently supported by Anchore Enterprise.

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
- `.Values.ui.existingSecretName` [default: anchore-enterprise-ui-env]

To enable this feature, set the following values to `true` in your values file:

```yaml
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

```

### Ingress

[Ingress](https://kubernetes.io/docs/concepts/services-networking/ingress/) serves as the gateway to expose HTTP and HTTPS routes from outside the Kubernetes cluster to services within it. Routing is governed by rules specified in the Ingress resource. Kubernetes supports a variety of ingress controllers, such as AWS ALB and GCE controllers.

This Helm chart includes a foundational ingress configuration that is customizable. You can expose various Anchore Enterprise external APIs, including the core API, UI, and Reporting by editing the `ingress` section in your values file.

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

api:
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

### Prometheus Metrics

Anchore Enterprise offers native support for exporting Prometheus metrics from each of its containers. When this feature is enabled, each service exposes metrics via its existing service port. If you're adding Prometheus manually to your deployment, you'll need to configure it to recognize each pod and its corresponding ports.

```yaml
anchoreConfig:
  metrics:
    enabled: true
    auth_disabled: true
```

For those using the [Prometheus operator](https://github.com/prometheus-operator/prometheus-operator/blob/main/Documentation/developer/getting-started.md), a ServiceMonitor can be deployed within the same namespace as your Anchore Enterprise release. Once deployed, the Prometheus operator will automatically begin scraping the pre-configured endpoints for metrics.

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
  # Specify an LDAP CA cert if using LDAP authenication.
  # Note if using an internal ca cert for internalServicesSSL, combine that into the ldap-combined-ca-cert-bundle.pem
  ldapsRootCaCertName: ldap-combined-ca-cert-bundle.pem
```

## Object Storage Migration

To cleanly migrate data from one archive driver to another, Anchore Enterprise includes some tooling that automates the process in the ‘anchore-enterprise-manager’ tool packaged with the system.
The enterprise helm chart provides a way to run the migration steps listed in the [object store migration docs](https://docs.anchore.com/current/docs/configuration/storage/object_store/migration/#migrating-analysis-archive-data)
automatically by spinning up a job and crafting the configs required and running the necessary migration commands.

The source's config.yaml uses the `anchoreConfig.catalog.object_store` and `anchoreConfig.catalog.analysis_archive` objects as it's configs. This is currently what your system is deployed with.

The dest-config.yaml uses the `osaaMigrationJob.objectStoreMigration.object_store` and `osaaMigrationJob.analysisArchiveMigration.analysis_archive` respectively to know what it will be migrating to.

To enable the job that runs the migration, update the osaaMigrationJob's values as needed, then run a `helm upgrade`. This will create a job using the pre-upgrade hook to ensure all services are spun down before the migration is ran. It uses the same service account as the upgrade job unless specified otherwise. This service account must have permissions to list and scale down deployments and pods. As the upgrade may take a while, you may want to run your helm upgrade using a longer `--timeout` option to allow the upgrade job to run through without failing due to the timeout.

```yaml
# example config
osaaMigrationJob:
  enabled: true # note that we are enabling the migration job
  analysisArchiveMigration:
    run: true # we are specifying to run the analysis_archive migration
    bucket: "analysis_archive"
    mode: to_analysis_archive
    # the deployment will be migrated to use the following configs for catalog.analysis_archive
    analysis_archive:
      enabled: true
      compression:
        enabled: true
        min_size_kbytes: 100
      storage_driver:
        name: s3
        config:
          access_key: my_access_key
          secret_key: my_secret_key
          url: 'http://myminio.mynamespace.svc.cluster.local:9000'
          region: null
          bucket: analysisarchive
  objectStoreMigration:
    run: true
    # note that since this is the same as anchoreConfig.catalog.object_store, the migration
    # command for migrating the object store will still run, but it will not do anything as there
    # is nothing to be done
    object_store:
      verify_content_digests: true
      compression:
        enabled: false
        min_size_kbytes: 100
      storage_driver:
        name: db
        config: {}

# the deployment was previously deployed using the following configs
anchoreConfig:
  default_admin_password: foobar
  catalog:
    analysis_archive:
      enabled: true
      compression:
        enabled: true
        min_size_kbytes: 100
      storage_driver:
        name: db
        config: {}
    object_store:
      verify_content_digests: true
      compression:
        enabled: true
        min_size_kbytes: 100
      storage_driver:
        name: db
        config: {}
```

After the migration is complete, the deployment of Anchore will use the `osaaMigrationJob`'s `analysis_archive` and `object_store` configs depending on if you specified to `run` the migration for the respective config. Since the migration only needs to be ran once, you should update your values.yaml to replace your old `anchoreConfig.catalog.analysis_archive` and `anchoreConfig.catalog.object_store` sections with what you declared in the `osaaMigrationJob` section. You can then set the `osaaMigrationJob.enabled` value to false as to not spin up the job anymore since it is no longer needed.

### Object Storage Migration Rollback

To restore your deployment to using your previous driver configurations:

1. put your original `catalog.analysis_archive` and `catalog.object_store` configs in the `osaaMigrationJob` configs. Your `catalog.analysis_archive` and `catalog.object_store` should currently be what you tried to migrate to (what was in the `osaaMigrationJob` configs) as per the instructions above saying
    - """Since the migration only needs to be ran once, you should update your values.yaml to replace your old `anchoreConfig.catalog.analysis_archive` and `anchoreConfig.catalog.object_store` sections with what you declared in the `osaaMigrationJob` section.""""
2. set to true, `osaaMigrationJob.enable` and (`osaaMigrationJob.objectStoreMigration.run` and/or `osaaMigrationJob.analysisArchiveMigration.run`)
3. set `osaaMigrationJob.analysisArchiveMigration.mode=from_analysis_archive`
4. do a `helm upgrade` (remember to increase your timeout based on how much data is being migrated)
5. Once the migration completes, move your original configs (what is currently in `osaaMigrationJob`) to `anchoreConfig.catalog.analysis_archive` and `anchoreConfig.catalog.object_store`, and update your values file to set `osaaMigrationJob.enabled=false`

## Parameters

### Global Resource Parameters

| Name                      | Description                             | Value |
| ------------------------- | --------------------------------------- | ----- |
| `global.fullnameOverride` | overrides the fullname set on resources | `""`  |
| `global.nameOverride`     | overrides the name set on resources     | `""`  |

### Common Resource Parameters

| Name                                    | Description                                                                                                                        | Value                                  |
| --------------------------------------- | ---------------------------------------------------------------------------------------------------------------------------------- | -------------------------------------- |
| `image`                                 | Image used for all Anchore Enterprise deployments, excluding Anchore UI                                                            | `docker.io/anchore/enterprise:v5.18.0` |
| `imagePullPolicy`                       | Image pull policy used by all deployments                                                                                          | `IfNotPresent`                         |
| `imagePullSecretName`                   | Name of Docker credentials secret for access to private repos                                                                      | `anchore-enterprise-pullcreds`         |
| `kubectlImage`                          | The image to use for the job's init container that uses kubectl to scale down deployments for the migration / upgrade              | `bitnami/kubectl:1.30`                 |
| `useExistingPullCredSecret`             | forgoes pullcred secret creation and uses the secret defined in imagePullSecretName                                                | `true`                                 |
| `imageCredentials.registry`             | The registry URL for the image pull secret                                                                                         | `""`                                   |
| `imageCredentials.username`             | The username for the image pull secret                                                                                             | `""`                                   |
| `imageCredentials.password`             | The password for the image pull secret                                                                                             | `""`                                   |
| `imageCredentials.email`                | The email for the image pull secret                                                                                                | `""`                                   |
| `startMigrationPod`                     | Spin up a Database migration pod to help migrate the database to the new schema                                                    | `false`                                |
| `migrationPodImage`                     | The image reference to the migration pod                                                                                           | `docker.io/postgres:13-bookworm`       |
| `migrationAnchoreEngineSecretName`      | The name of the secret that has anchore-engine values                                                                              | `my-engine-anchore-engine`             |
| `serviceAccountName`                    | Name of a service account used to run all Anchore pods                                                                             | `""`                                   |
| `injectSecretsViaEnv`                   | Enable secret injection into pod via environment variables instead of via k8s secrets                                              | `false`                                |
| `license`                               | License for Anchore Enterprise                                                                                                     | `{}`                                   |
| `licenseSecretName`                     | Name of the Kubernetes secret containing your license.yaml file                                                                    | `anchore-enterprise-license`           |
| `useExistingLicenseSecret`              | forgoes license secret creation and uses the secret defined in licenseSecretName                                                   | `true`                                 |
| `certStoreSecretName`                   | Name of secret containing the certificates & keys used for SSL, SAML & CAs                                                         | `""`                                   |
| `extraEnv`                              | Common environment variables set on all containers                                                                                 | `[]`                                   |
| `useExistingSecrets`                    | forgoes secret creation and uses the secret defined in existingSecretName                                                          | `false`                                |
| `existingSecretName`                    | Name of an existing secret to be used for Anchore core services, excluding Anchore UI                                              | `anchore-enterprise-env`               |
| `labels`                                | Common labels set on all Kubernetes resources                                                                                      | `{}`                                   |
| `annotations`                           | Common annotations set on all Kubernetes resources                                                                                 | `{}`                                   |
| `nodeSelector`                          | Common nodeSelector set on all Kubernetes pods                                                                                     | `{}`                                   |
| `tolerations`                           | Common tolerations set on all Kubernetes pods                                                                                      | `[]`                                   |
| `affinity`                              | Common affinity set on all Kubernetes pods                                                                                         | `{}`                                   |
| `topologySpreadConstraints`             | Common topologySpreadConstraints set on all Kubernetes pods.                                                                       | `[]`                                   |
| `scratchVolume.mountPath`               | The mount path of an external volume for scratch space. Used for the following pods: analyzer, policy-engine, catalog, and reports | `/analysis_scratch`                    |
| `scratchVolume.fixGroupPermissions`     | Enable an initContainer that will fix the fsGroup permissions on all scratch volumes                                               | `false`                                |
| `scratchVolume.fixerInitContainerImage` | The image to use for the mode-fixer initContainer                                                                                  | `alpine`                               |
| `scratchVolume.details`                 | Details for the k8s volume to be created (defaults to default emptyDir)                                                            | `{}`                                   |
| `extraVolumes`                          | mounts additional volumes to each pod                                                                                              | `[]`                                   |
| `extraVolumeMounts`                     | mounts additional volumes to each pod                                                                                              | `[]`                                   |
| `securityContext.runAsUser`             | The securityContext runAsUser for all Anchore pods                                                                                 | `1000`                                 |
| `securityContext.runAsGroup`            | The securityContext runAsGroup for all Anchore pods                                                                                | `1000`                                 |
| `securityContext.fsGroup`               | The securityContext fsGroup for all Anchore pods                                                                                   | `1000`                                 |
| `containerSecurityContext`              | The securityContext for all containers                                                                                             | `{}`                                   |
| `probes.liveness.initialDelaySeconds`   | Initial delay seconds for liveness probe                                                                                           | `120`                                  |
| `probes.liveness.timeoutSeconds`        | Timeout seconds for liveness probe                                                                                                 | `10`                                   |
| `probes.liveness.periodSeconds`         | Period seconds for liveness probe                                                                                                  | `10`                                   |
| `probes.liveness.failureThreshold`      | Failure threshold for liveness probe                                                                                               | `6`                                    |
| `probes.liveness.successThreshold`      | Success threshold for liveness probe                                                                                               | `1`                                    |
| `probes.readiness.timeoutSeconds`       | Timeout seconds for the readiness probe                                                                                            | `10`                                   |
| `probes.readiness.periodSeconds`        | Period seconds for the readiness probe                                                                                             | `10`                                   |
| `probes.readiness.failureThreshold`     | Failure threshold for the readiness probe                                                                                          | `3`                                    |
| `probes.readiness.successThreshold`     | Success threshold for the readiness probe                                                                                          | `1`                                    |
| `doSourceAtEntry.enabled`               | Does a `source` of the file path defined before starting Anchore services                                                          | `false`                                |
| `doSourceAtEntry.filePaths`             | List of file paths to `source` before starting Anchore services                                                                    | `[]`                                   |
| `configOverride`                        | Allows for overriding the default Anchore configuration file                                                                       | `""`                                   |
| `scripts`                               | Collection of helper scripts usable in all anchore enterprise pods                                                                 | `{}`                                   |
| `domainSuffix`                          | domain suffix for appending to the ANCHORE_ENDPOINT_HOSTNAME. If blank, domainSuffix will be "namespace.svc.cluster.local".        | `""`                                   |

### Anchore Configuration Parameters

| Name                                                                                    | Description                                                                                                                      | Value                       |
| --------------------------------------------------------------------------------------- | -------------------------------------------------------------------------------------------------------------------------------- | --------------------------- |
| `anchoreConfig.service_dir`                                                             | Path to directory where default Anchore config files are placed at startup                                                       | `/anchore_service`          |
| `anchoreConfig.log_level`                                                               | The log level for Anchore services: NOTE: This is deprecated, use logging.log_level                                              | `<ALLOW_API_CONFIGURATION>` |
| `anchoreConfig.logging.colored_logging`                                                 | Enable colored output in the logs                                                                                                | `false`                     |
| `anchoreConfig.logging.exception_backtrace_logging`                                     | Enable stack traces in the logs                                                                                                  | `false`                     |
| `anchoreConfig.logging.exception_diagnose_logging`                                      | Enable detailed exception information in the logs                                                                                | `false`                     |
| `anchoreConfig.logging.file_rotation_rule`                                              | Maximum size of a log file before it is rotated                                                                                  | `10 MB`                     |
| `anchoreConfig.logging.file_retention_rule`                                             | Number of log files to retain before deleting the oldest                                                                         | `10`                        |
| `anchoreConfig.logging.log_level`                                                       | Log level for the service code                                                                                                   | `<ALLOW_API_CONFIGURATION>` |
| `anchoreConfig.logging.server_access_logging`                                           | Set whether to print server access to logging                                                                                    | `true`                      |
| `anchoreConfig.logging.server_response_debug_logging`                                   | Log the elapsed time to process the request and the response size (debug log level)                                              | `false`                     |
| `anchoreConfig.logging.server_log_level`                                                | Log level specifically for the server (uvicorn)                                                                                  | `info`                      |
| `anchoreConfig.logging.structured_logging`                                              | Enable structured logging output (JSON)                                                                                          | `false`                     |
| `anchoreConfig.server.max_connection_backlog`                                           | Max connections permitted in the backlog before dropping                                                                         | `2048`                      |
| `anchoreConfig.server.max_wsgi_middleware_worker_queue_size`                            | Max number of requests to queue for processing by ASGI2WSGI middleware                                                           | `100`                       |
| `anchoreConfig.server.max_wsgi_middleware_worker_count`                                 | Max number of workers to have in the ASGI2WSGI middleware worker pool                                                            | `50`                        |
| `anchoreConfig.server.timeout_graceful_shutdown`                                        | Seconds to permit for graceful shutdown or false to disable                                                                      | `false`                     |
| `anchoreConfig.server.timeout_keep_alive`                                               | Seconds to keep a connection alive before closing                                                                                | `5`                         |
| `anchoreConfig.audit.enabled`                                                           | Enable audit logging                                                                                                             | `true`                      |
| `anchoreConfig.allow_awsecr_iam_auto`                                                   | Enable AWS IAM instance role for ECR auth                                                                                        | `true`                      |
| `anchoreConfig.keys.secret`                                                             | The shared secret used for signing & encryption, auto-generated by Helm if not set.                                              | `""`                        |
| `anchoreConfig.keys.privateKeyFileName`                                                 | The file name of the private key used for signing & encryption, found in the k8s secret specified in .Values.certStoreSecretName | `""`                        |
| `anchoreConfig.keys.publicKeyFileName`                                                  | The file name of the public key used for signing & encryption, found in the k8s secret specified in .Values.certStoreSecretName  | `""`                        |
| `anchoreConfig.user_authentication.oauth.enabled`                                       | Enable OAuth for Anchore user authentication                                                                                     | `true`                      |
| `anchoreConfig.user_authentication.oauth.default_token_expiration_seconds`              | The expiration, in seconds, for OAuth tokens                                                                                     | `3600`                      |
| `anchoreConfig.user_authentication.oauth.refresh_token_expiration_seconds`              | The expiration, in seconds, for OAuth refresh tokens                                                                             | `86400`                     |
| `anchoreConfig.user_authentication.allow_api_keys_for_saml_users`                       | Enable API key generation and authentication for SAML users                                                                      | `false`                     |
| `anchoreConfig.user_authentication.max_api_key_age_days`                                | The maximum age, in days, for API keys                                                                                           | `365`                       |
| `anchoreConfig.user_authentication.max_api_keys_per_user`                               | The maximum number of API keys per user                                                                                          | `100`                       |
| `anchoreConfig.user_authentication.remove_deleted_user_api_keys_older_than_days`        | The number of days elapsed after a user API key is deleted before it is garbage collected (-1 to disable)                        | `365`                       |
| `anchoreConfig.user_authentication.hashed_passwords`                                    | Enable storing passwords as secure hashes in the database                                                                        | `true`                      |
| `anchoreConfig.user_authentication.sso_require_existing_users`                          | set to true in order to disable the SSO JIT provisioning during authentication                                                   | `false`                     |
| `anchoreConfig.user_authentication.disallow_native_users`                               | Disallow native users to authenticate by any method. Only SSO/'saml' users will be able to access the system.                    | `false`                     |
| `anchoreConfig.user_authentication.log_saml_assertions`                                 | Enable logging of received SAML assertions at INFO level for SSO debugging in API container.                                     | `false`                     |
| `anchoreConfig.metrics.enabled`                                                         | Enable Prometheus metrics for all Anchore services                                                                               | `false`                     |
| `anchoreConfig.metrics.auth_disabled`                                                   | Disable auth on Prometheus metrics for all Anchore services                                                                      | `false`                     |
| `anchoreConfig.webhooks`                                                                | Enable Anchore services to provide webhooks for external system updates                                                          | `{}`                        |
| `anchoreConfig.default_admin_password`                                                  | The password for the Anchore Enterprise admin user                                                                               | `""`                        |
| `anchoreConfig.default_admin_email`                                                     | The email address used for the Anchore Enterprise admin user                                                                     | `admin@myanchore`           |
| `anchoreConfig.database.timeout`                                                        |                                                                                                                                  | `120`                       |
| `anchoreConfig.database.ssl`                                                            | Enable SSL/TLS for the database connection                                                                                       | `false`                     |
| `anchoreConfig.database.sslMode`                                                        | The SSL mode to use for database connection                                                                                      | `verify-full`               |
| `anchoreConfig.database.sslRootCertFileName`                                            | File name of the database root CA certificate stored in the k8s secret specified with .Values.certStoreSecretName                | `""`                        |
| `anchoreConfig.database.db_pool_size`                                                   | The database max connection pool size                                                                                            | `30`                        |
| `anchoreConfig.database.db_pool_max_overflow`                                           | The maximum overflow size of the database connection pool                                                                        | `100`                       |
| `anchoreConfig.database.engineArgs`                                                     | Set custom database engine arguments for SQLAlchemy                                                                              | `{}`                        |
| `anchoreConfig.internalServicesSSL.enabled`                                             | Force all Enterprise services to use SSL for internal communication                                                              | `false`                     |
| `anchoreConfig.internalServicesSSL.verifyCerts`                                         | Enable cert verification against the local cert bundle, if this set to false self-signed certs are allowed                       | `false`                     |
| `anchoreConfig.internalServicesSSL.certSecretKeyFileName`                               | File name of the private key used for internal SSL stored in the secret specified in .Values.certStoreSecretName                 | `""`                        |
| `anchoreConfig.internalServicesSSL.certSecretCertFileName`                              | File name of the root CA certificate used for internal SSL stored in the secret specified in .Values.certStoreSecretName         | `""`                        |
| `anchoreConfig.policyBundles`                                                           | Include custom Anchore policy bundles                                                                                            | `{}`                        |
| `anchoreConfig.apiext.external.enabled`                                                 | Allow overrides for constructing Anchore API URLs                                                                                | `false`                     |
| `anchoreConfig.apiext.external.useTLS`                                                  | Enable TLS for external API access                                                                                               | `true`                      |
| `anchoreConfig.apiext.external.hostname`                                                | Hostname for the external Anchore API                                                                                            | `""`                        |
| `anchoreConfig.apiext.external.port`                                                    | Port configured for external Anchore API                                                                                         | `8443`                      |
| `anchoreConfig.apiext.image_content.remove_license_content_from_sbom_return`            | Remove license content from SBOM downloads                                                                                       | `<ALLOW_API_CONFIGURATION>` |
| `anchoreConfig.analyzer.cycle_timers.image_analyzer`                                    | The interval between checks of the work queue for new analysis jobs                                                              | `1`                         |
| `anchoreConfig.analyzer.layer_cache_max_gigabytes`                                      | Specify a cache size > 0GB to enable image layer caching                                                                         | `0`                         |
| `anchoreConfig.analyzer.enable_hints`                                                   | Enable a user-supplied 'hints' file to override and/or augment the software artifacts found during analysis                      | `false`                     |
| `anchoreConfig.analyzer.configFile`                                                     | Custom Anchore Analyzer configuration file contents in YAML                                                                      | `{}`                        |
| `anchoreConfig.catalog.account_prometheus_metrics`                                      | Enable per-account image status prometheus metrics.                                                                              | `<ALLOW_API_CONFIGURATION>` |
| `anchoreConfig.catalog.sbom_vuln_scan.auto_scale`                                       | Automatically scale batch_size and pool_size. Disable to configure manually.                                                     | `true`                      |
| `anchoreConfig.catalog.sbom_vuln_scan.batch_size`                                       | The number of SBOMs to select to scan within a single batch, when 'auto_scale' is disabled                                       | `1`                         |
| `anchoreConfig.catalog.sbom_vuln_scan.pool_size`                                        | The number of concurrent vulnerability scans to dispatch from each catalog instance                                              | `1`                         |
| `anchoreConfig.catalog.cycle_timers.image_watcher`                                      | Interval (seconds) to check for an update to a tag                                                                               | `3600`                      |
| `anchoreConfig.catalog.cycle_timers.policy_eval`                                        | Interval (seconds) to run a policy evaluation on images with policy_eval subscription activated                                  | `3600`                      |
| `anchoreConfig.catalog.cycle_timers.vulnerability_scan`                                 | Interval to run a vulnerability scan on images with vuln_update subscription activated                                           | `14400`                     |
| `anchoreConfig.catalog.cycle_timers.analyzer_queue`                                     | Interval to add new work on the image analysis queue                                                                             | `1`                         |
| `anchoreConfig.catalog.cycle_timers.archive_tasks`                                      | Interval to trigger Anchore Catalog archive Tasks                                                                                | `43200`                     |
| `anchoreConfig.catalog.cycle_timers.notifications`                                      | Interval in which notifications will be processed for state changes                                                              | `30`                        |
| `anchoreConfig.catalog.cycle_timers.service_watcher`                                    | Interval of service state update poll, used for system status                                                                    | `15`                        |
| `anchoreConfig.catalog.cycle_timers.policy_bundle_sync`                                 | Interval of policy bundle sync                                                                                                   | `300`                       |
| `anchoreConfig.catalog.cycle_timers.repo_watcher`                                       | Interval between checks to repo for new tags                                                                                     | `60`                        |
| `anchoreConfig.catalog.cycle_timers.image_gc`                                           | Interval for garbage collection of images marked for deletion                                                                    | `60`                        |
| `anchoreConfig.catalog.cycle_timers.k8s_image_watcher`                                  | Interval for the runtime inventory image analysis poll                                                                           | `150`                       |
| `anchoreConfig.catalog.cycle_timers.resource_metrics`                                   | Interval (seconds) for computing metrics from the DB                                                                             | `60`                        |
| `anchoreConfig.catalog.cycle_timers.events_gc`                                          | Interval (seconds) for cleaning up events in the system based on timestamp                                                       | `43200`                     |
| `anchoreConfig.catalog.cycle_timers.artifact_lifecycle_policy_tasks`                    | Interval (seconds) for running artifact lifecycle policy tasks                                                                   | `43200`                     |
| `anchoreConfig.catalog.event_log`                                                       | Event log for webhooks, YAML configuration                                                                                       | `{}`                        |
| `anchoreConfig.catalog.analysis_archive`                                                | Custom analysis archive YAML configuration                                                                                       | `{}`                        |
| `anchoreConfig.catalog.object_store`                                                    | Custom object storage YAML configuration                                                                                         | `{}`                        |
| `anchoreConfig.catalog.runtime_inventory.inventory_ttl_days`                            | TTL for runtime inventory.                                                                                                       | `120`                       |
| `anchoreConfig.catalog.runtime_inventory.inventory_ingest_overwrite`                    | force runtime inventory to be overwritten upon every update for that reported context.                                           | `false`                     |
| `anchoreConfig.catalog.integrations.integration_health_report_ttl_days`                 | TTL for integration health reports.                                                                                              | `2`                         |
| `anchoreConfig.catalog.down_analyzer_task_requeue`                                      | Allows fast re-queueing when image status is 'analyzing' on an analyzer that is no longer in the 'up' state                      | `true`                      |
| `anchoreConfig.policy_engine.vulnerabilities.matching.exclude.providers`                | List of providers to exclude from matching                                                                                       | `nil`                       |
| `anchoreConfig.policy_engine.vulnerabilities.matching.exclude.package_types`            | List of package types to exclude from matching                                                                                   | `nil`                       |
| `anchoreConfig.policy_engine.enable_user_base_image`                                    | Enables usage of Well Known Annotation to identify base image for use in ancestry calculations                                   | `true`                      |
| `anchoreConfig.notifications.cycle_timers.notifications`                                | Interval that notifications are sent                                                                                             | `30`                        |
| `anchoreConfig.notifications.ui_url`                                                    | Set the UI URL that is included in the notification, defaults to the Enterprise UI service name                                  | `""`                        |
| `anchoreConfig.reports.enable_graphiql`                                                 | Enable GraphiQL, a GUI for editing and testing GraphQL queries and mutations                                                     | `true`                      |
| `anchoreConfig.reports.async_execution_timeout`                                         | Configure how long a scheduled query must be running for before it is considered timed out                                       | `48h`                       |
| `anchoreConfig.reports.cycle_timers.reports_scheduled_queries`                          | Interval  in seconds to check for scheduled queries that need to be run                                                          | `600`                       |
| `anchoreConfig.reports.use_volume`                                                      | Configure the reports service to buffer report generation to disk instead of in memory                                           | `false`                     |
| `anchoreConfig.reports_worker.enable_data_ingress`                                      | Enable periodically syncing data into the Anchore Reports Service                                                                | `true`                      |
| `anchoreConfig.reports_worker.enable_data_egress`                                       | Periodically remove reporting data that has been removed in other parts of system                                                | `false`                     |
| `anchoreConfig.reports_worker.data_egress_window`                                       | defines a number of days to keep reporting data following its deletion in the rest of system.                                    | `0`                         |
| `anchoreConfig.reports_worker.data_refresh_max_workers`                                 | The maximum number of concurrent threads to refresh existing results (etl vulnerabilities and evaluations) in reports service.   | `10`                        |
| `anchoreConfig.reports_worker.data_load_max_workers`                                    | The maximum number of concurrent threads to load new results (etl vulnerabilities and evaluations) to reports service.           | `10`                        |
| `anchoreConfig.reports_worker.cycle_timers.reports_image_load`                          | Interval that vulnerabilities for images are synced                                                                              | `600`                       |
| `anchoreConfig.reports_worker.cycle_timers.reports_tag_load`                            | Interval that vulnerabilities by tags are synced                                                                                 | `600`                       |
| `anchoreConfig.reports_worker.cycle_timers.reports_runtime_inventory_load`              | Interval that the runtime inventory is synced                                                                                    | `600`                       |
| `anchoreConfig.reports_worker.cycle_timers.reports_extended_runtime_vuln_load`          | Interval extended runtime reports are synched (ecs, k8s containers and namespaces)                                               | `1800`                      |
| `anchoreConfig.reports_worker.cycle_timers.reports_image_refresh`                       | Interval that images are refreshed                                                                                               | `7200`                      |
| `anchoreConfig.reports_worker.cycle_timers.reports_tag_refresh`                         | Interval that tags are refreshed                                                                                                 | `7200`                      |
| `anchoreConfig.reports_worker.cycle_timers.reports_metrics`                             | Interval for how often reporting metrics are generated                                                                           | `3600`                      |
| `anchoreConfig.reports_worker.cycle_timers.reports_image_egress`                        | Interval stale states are removed by image                                                                                       | `600`                       |
| `anchoreConfig.reports_worker.cycle_timers.reports_tag_egress`                          | Interval stale states are removed by tag                                                                                         | `600`                       |
| `anchoreConfig.reports_worker.runtime_report_generation.use_legacy_loaders_and_queries` | Use legacy loaders and queries for runtime report generation                                                                     | `false`                     |
| `anchoreConfig.ui.enable_proxy`                                                         | Trust a reverse proxy when setting secure cookies (via the `X-Forwarded-Proto` header)                                           | `false`                     |
| `anchoreConfig.ui.enable_ssl`                                                           | Enable SSL in the Anchore UI container                                                                                           | `false`                     |
| `anchoreConfig.ui.enable_shared_login`                                                  | Allow single user to start multiple Anchore UI sessions                                                                          | `true`                      |
| `anchoreConfig.ui.redis_flushdb`                                                        | Flush user session keys and empty data on Anchore UI startup                                                                     | `true`                      |
| `anchoreConfig.ui.force_websocket`                                                      | Force WebSocket protocol for socket message communications                                                                       | `false`                     |
| `anchoreConfig.ui.authentication_lock.count`                                            | Number of failed authentication attempts allowed before a temporary lock is applied                                              | `5`                         |
| `anchoreConfig.ui.authentication_lock.expires`                                          | Authentication lock duration                                                                                                     | `300`                       |
| `anchoreConfig.ui.sso_auth_only`                                                        | Enable SSO authentication only                                                                                                   | `false`                     |
| `anchoreConfig.ui.custom_links`                                                         | List of up to 10 external links provided                                                                                         | `{}`                        |
| `anchoreConfig.ui.enable_add_repositories`                                              | Specify what users can add image repositories to the Anchore UI                                                                  | `{}`                        |
| `anchoreConfig.ui.custom_message`                                                       | Custom message to display on the login page                                                                                      | `{}`                        |
| `anchoreConfig.ui.log_level`                                                            | Descriptive detail of the application log output                                                                                 | `http`                      |
| `anchoreConfig.ui.enrich_inventory_view`                                                | aggregate and include compliance and vulnerability data from the reports service.                                                | `true`                      |
| `anchoreConfig.ui.appdb_config.native`                                                  | toggle the postgreSQL drivers used to connect to the database between the native and the NodeJS drivers.                         | `true`                      |
| `anchoreConfig.ui.appdb_config.pool.max`                                                | maximum number of simultaneous connections allowed in the connection pool                                                        | `10`                        |
| `anchoreConfig.ui.appdb_config.pool.min`                                                | minimum number of connections                                                                                                    | `0`                         |
| `anchoreConfig.ui.appdb_config.pool.acquire`                                            | the timeout in milliseconds used when acquiring a new connection                                                                 | `30000`                     |
| `anchoreConfig.ui.appdb_config.pool.idle`                                               | the maximum time that a connection can be idle before being released                                                             | `10000`                     |
| `anchoreConfig.ui.dbUser`                                                               | allows overriding and separation of the ui database user.                                                                        | `""`                        |
| `anchoreConfig.ui.dbPassword`                                                           | allows overriding and separation of the ui database user authentication                                                          | `""`                        |

### Anchore Analyzer k8s Deployment Parameters

| Name                                 | Description                                                                                                                                                                  | Value  |
| ------------------------------------ | ---------------------------------------------------------------------------------------------------------------------------------------------------------------------------- | ------ |
| `analyzer.replicaCount`              | Number of replicas for the Anchore Analyzer deployment                                                                                                                       | `1`    |
| `analyzer.service.port`              | The port used for gatherings metrics when .Values.metricsEnabled=true                                                                                                        | `8084` |
| `analyzer.service.domainSuffix`      | domain suffix for appending to the ANCHORE_ENDPOINT_HOSTNAME. If blank, domainSuffix will be "namespace.svc.cluster.local". Takes precedence over the top level domainSuffix | `""`   |
| `analyzer.extraEnv`                  | Set extra environment variables for Anchore Analyzer pods                                                                                                                    | `[]`   |
| `analyzer.resources`                 | Resource requests and limits for Anchore Analyzer pods                                                                                                                       | `{}`   |
| `analyzer.labels`                    | Labels for Anchore Analyzer pods                                                                                                                                             | `{}`   |
| `analyzer.annotations`               | Annotation for Anchore Analyzer pods                                                                                                                                         | `{}`   |
| `analyzer.nodeSelector`              | Node labels for Anchore Analyzer pod assignment                                                                                                                              | `{}`   |
| `analyzer.tolerations`               | Tolerations for Anchore Analyzer pod assignment                                                                                                                              | `[]`   |
| `analyzer.affinity`                  | Affinity for Anchore Analyzer pod assignment                                                                                                                                 | `{}`   |
| `analyzer.topologySpreadConstraints` | Topology spread constraints for Anchore Analyzer pod assignment                                                                                                              | `[]`   |
| `analyzer.serviceAccountName`        | Service account name for Anchore API pods                                                                                                                                    | `""`   |
| `analyzer.scratchVolume.details`     | Details for the k8s volume to be created for Anchore Analyzer scratch space                                                                                                  | `{}`   |

### Anchore API k8s Deployment Parameters

| Name                            | Description                                                                                                                                                                  | Value       |
| ------------------------------- | ---------------------------------------------------------------------------------------------------------------------------------------------------------------------------- | ----------- |
| `api.replicaCount`              | Number of replicas for Anchore API deployment                                                                                                                                | `1`         |
| `api.service.type`              | Service type for Anchore API                                                                                                                                                 | `ClusterIP` |
| `api.service.port`              | Service port for Anchore API                                                                                                                                                 | `8228`      |
| `api.service.annotations`       | Annotations for Anchore API service                                                                                                                                          | `{}`        |
| `api.service.labels`            | Labels for Anchore API service                                                                                                                                               | `{}`        |
| `api.service.nodePort`          | nodePort for Anchore API service                                                                                                                                             | `""`        |
| `api.service.domainSuffix`      | domain suffix for appending to the ANCHORE_ENDPOINT_HOSTNAME. If blank, domainSuffix will be "namespace.svc.cluster.local". Takes precedence over the top level domainSuffix | `""`        |
| `api.extraEnv`                  | Set extra environment variables for Anchore API pods                                                                                                                         | `[]`        |
| `api.extraVolumes`              | Define additional volumes for Anchore API pods                                                                                                                               | `[]`        |
| `api.extraVolumeMounts`         | Define additional volume mounts for Anchore API pods                                                                                                                         | `[]`        |
| `api.resources`                 | Resource requests and limits for Anchore API pods                                                                                                                            | `{}`        |
| `api.labels`                    | Labels for Anchore API pods                                                                                                                                                  | `{}`        |
| `api.annotations`               | Annotation for Anchore API pods                                                                                                                                              | `{}`        |
| `api.nodeSelector`              | Node labels for Anchore API pod assignment                                                                                                                                   | `{}`        |
| `api.tolerations`               | Tolerations for Anchore API pod assignment                                                                                                                                   | `[]`        |
| `api.affinity`                  | Affinity for Anchore API pod assignment                                                                                                                                      | `{}`        |
| `api.topologySpreadConstraints` | Topology spread constraints for Anchore API pod assignment                                                                                                                   | `[]`        |
| `api.serviceAccountName`        | Service account name for Anchore API pods                                                                                                                                    | `""`        |

### Anchore Catalog k8s Deployment Parameters

| Name                                | Description                                                                                                                                                                  | Value       |
| ----------------------------------- | ---------------------------------------------------------------------------------------------------------------------------------------------------------------------------- | ----------- |
| `catalog.replicaCount`              | Number of replicas for the Anchore Catalog deployment                                                                                                                        | `1`         |
| `catalog.service.type`              | Service type for Anchore Catalog                                                                                                                                             | `ClusterIP` |
| `catalog.service.port`              | Service port for Anchore Catalog                                                                                                                                             | `8082`      |
| `catalog.service.annotations`       | Annotations for Anchore Catalog service                                                                                                                                      | `{}`        |
| `catalog.service.labels`            | Labels for Anchore Catalog service                                                                                                                                           | `{}`        |
| `catalog.service.nodePort`          | nodePort for Anchore Catalog service                                                                                                                                         | `""`        |
| `catalog.service.domainSuffix`      | domain suffix for appending to the ANCHORE_ENDPOINT_HOSTNAME. If blank, domainSuffix will be "namespace.svc.cluster.local". Takes precedence over the top level domainSuffix | `""`        |
| `catalog.extraEnv`                  | Set extra environment variables for Anchore Catalog pods                                                                                                                     | `[]`        |
| `catalog.extraVolumes`              | Define additional volumes for Anchore Catalog pods                                                                                                                           | `[]`        |
| `catalog.extraVolumeMounts`         | Define additional volume mounts for Anchore Catalog pods                                                                                                                     | `[]`        |
| `catalog.resources`                 | Resource requests and limits for Anchore Catalog pods                                                                                                                        | `{}`        |
| `catalog.labels`                    | Labels for Anchore Catalog pods                                                                                                                                              | `{}`        |
| `catalog.annotations`               | Annotation for Anchore Catalog pods                                                                                                                                          | `{}`        |
| `catalog.nodeSelector`              | Node labels for Anchore Catalog pod assignment                                                                                                                               | `{}`        |
| `catalog.tolerations`               | Tolerations for Anchore Catalog pod assignment                                                                                                                               | `[]`        |
| `catalog.affinity`                  | Affinity for Anchore Catalog pod assignment                                                                                                                                  | `{}`        |
| `catalog.topologySpreadConstraints` | Topology spread constraints for Anchore Catalog pod assignment                                                                                                               | `[]`        |
| `catalog.serviceAccountName`        | Service account name for Anchore Catalog pods                                                                                                                                | `""`        |
| `catalog.scratchVolume.details`     | Details for the k8s volume to be created for Anchore Catalog scratch space                                                                                                   | `{}`        |

### Anchore DataSyncer k8s Deployment Parameters

| Name                                   | Description                                                                                                                                                                  | Value       |
| -------------------------------------- | ---------------------------------------------------------------------------------------------------------------------------------------------------------------------------- | ----------- |
| `dataSyncer.replicaCount`              | Number of replicas for the Anchore DataSyncer deployment                                                                                                                     | `1`         |
| `dataSyncer.service.type`              | Service type for Anchore DataSyncer                                                                                                                                          | `ClusterIP` |
| `dataSyncer.service.port`              | Service port for Anchore DataSyncer                                                                                                                                          | `8778`      |
| `dataSyncer.service.annotations`       | Annotations for Anchore DataSyncer service                                                                                                                                   | `{}`        |
| `dataSyncer.service.labels`            | Labels for Anchore DataSyncer service                                                                                                                                        | `{}`        |
| `dataSyncer.service.nodePort`          | nodePort for Anchore DataSyncer service                                                                                                                                      | `""`        |
| `dataSyncer.service.domainSuffix`      | domain suffix for appending to the ANCHORE_ENDPOINT_HOSTNAME. If blank, domainSuffix will be "namespace.svc.cluster.local". Takes precedence over the top level domainSuffix | `""`        |
| `dataSyncer.extraEnv`                  | Set extra environment variables for Anchore DataSyncer pods                                                                                                                  | `[]`        |
| `dataSyncer.extraVolumes`              | Define additional volumes for Anchore DataSyncer pods                                                                                                                        | `[]`        |
| `dataSyncer.extraVolumeMounts`         | Define additional volume mounts for Anchore DataSyncer pods                                                                                                                  | `[]`        |
| `dataSyncer.resources`                 | Resource requests and limits for Anchore DataSyncer pods                                                                                                                     | `{}`        |
| `dataSyncer.labels`                    | Labels for Anchore DataSyncer pods                                                                                                                                           | `{}`        |
| `dataSyncer.annotations`               | Annotation for Anchore DataSyncer pods                                                                                                                                       | `{}`        |
| `dataSyncer.nodeSelector`              | Node labels for Anchore DataSyncer pod assignment                                                                                                                            | `{}`        |
| `dataSyncer.tolerations`               | Tolerations for Anchore DataSyncer pod assignment                                                                                                                            | `[]`        |
| `dataSyncer.affinity`                  | Affinity for Anchore DataSyncer pod assignment                                                                                                                               | `{}`        |
| `dataSyncer.topologySpreadConstraints` | Topology spread constraints for Anchore DataSyncer pod assignment                                                                                                            | `[]`        |
| `dataSyncer.serviceAccountName`        | Service account name for Anchore DataSyncer pods                                                                                                                             | `""`        |
| `dataSyncer.scratchVolume.details`     | Details for the k8s volume to be created for Anchore DataSyncer scratch space                                                                                                | `{}`        |

### Anchore Notifications Parameters

| Name                                      | Description                                                                                                                                                                  | Value       |
| ----------------------------------------- | ---------------------------------------------------------------------------------------------------------------------------------------------------------------------------- | ----------- |
| `notifications.replicaCount`              | Number of replicas for the Anchore Notifications deployment                                                                                                                  | `1`         |
| `notifications.service.type`              | Service type for Anchore Notifications                                                                                                                                       | `ClusterIP` |
| `notifications.service.port`              | Service port for Anchore Notifications                                                                                                                                       | `8668`      |
| `notifications.service.annotations`       | Annotations for Anchore Notifications service                                                                                                                                | `{}`        |
| `notifications.service.labels`            | Labels for Anchore Notifications service                                                                                                                                     | `{}`        |
| `notifications.service.nodePort`          | nodePort for Anchore Notifications service                                                                                                                                   | `""`        |
| `notifications.service.domainSuffix`      | domain suffix for appending to the ANCHORE_ENDPOINT_HOSTNAME. If blank, domainSuffix will be "namespace.svc.cluster.local". Takes precedence over the top level domainSuffix | `""`        |
| `notifications.extraEnv`                  | Set extra environment variables for Anchore Notifications pods                                                                                                               | `[]`        |
| `notifications.extraVolumes`              | Define additional volumes for Anchore Notifications pods                                                                                                                     | `[]`        |
| `notifications.extraVolumeMounts`         | Define additional volume mounts for Anchore Notifications pods                                                                                                               | `[]`        |
| `notifications.resources`                 | Resource requests and limits for Anchore Notifications pods                                                                                                                  | `{}`        |
| `notifications.labels`                    | Labels for Anchore Notifications pods                                                                                                                                        | `{}`        |
| `notifications.annotations`               | Annotation for Anchore Notifications pods                                                                                                                                    | `{}`        |
| `notifications.nodeSelector`              | Node labels for Anchore Notifications pod assignment                                                                                                                         | `{}`        |
| `notifications.tolerations`               | Tolerations for Anchore Notifications pod assignment                                                                                                                         | `[]`        |
| `notifications.affinity`                  | Affinity for Anchore Notifications pod assignment                                                                                                                            | `{}`        |
| `notifications.topologySpreadConstraints` | Topology spread constraints for Anchore Notifications pod assignment                                                                                                         | `[]`        |
| `notifications.serviceAccountName`        | Service account name for Anchore Notifications pods                                                                                                                          | `""`        |

### Anchore Policy Engine k8s Deployment Parameters

| Name                                     | Description                                                                                                                                                                  | Value       |
| ---------------------------------------- | ---------------------------------------------------------------------------------------------------------------------------------------------------------------------------- | ----------- |
| `policyEngine.replicaCount`              | Number of replicas for the Anchore Policy Engine deployment                                                                                                                  | `1`         |
| `policyEngine.service.type`              | Service type for Anchore Policy Engine                                                                                                                                       | `ClusterIP` |
| `policyEngine.service.port`              | Service port for Anchore Policy Engine                                                                                                                                       | `8087`      |
| `policyEngine.service.annotations`       | Annotations for Anchore Policy Engine service                                                                                                                                | `{}`        |
| `policyEngine.service.labels`            | Labels for Anchore Policy Engine service                                                                                                                                     | `{}`        |
| `policyEngine.service.nodePort`          | nodePort for Anchore Policy Engine service                                                                                                                                   | `""`        |
| `policyEngine.service.domainSuffix`      | domain suffix for appending to the ANCHORE_ENDPOINT_HOSTNAME. If blank, domainSuffix will be "namespace.svc.cluster.local". Takes precedence over the top level domainSuffix | `""`        |
| `policyEngine.extraEnv`                  | Set extra environment variables for Anchore Policy Engine pods                                                                                                               | `[]`        |
| `policyEngine.extraVolumes`              | Define additional volumes for Anchore Policy Engine pods                                                                                                                     | `[]`        |
| `policyEngine.extraVolumeMounts`         | Define additional volume mounts for Anchore Policy Engine pods                                                                                                               | `[]`        |
| `policyEngine.resources`                 | Resource requests and limits for Anchore Policy Engine pods                                                                                                                  | `{}`        |
| `policyEngine.labels`                    | Labels for Anchore Policy Engine pods                                                                                                                                        | `{}`        |
| `policyEngine.annotations`               | Annotation for Anchore Policy Engine pods                                                                                                                                    | `{}`        |
| `policyEngine.nodeSelector`              | Node labels for Anchore Policy Engine pod assignment                                                                                                                         | `{}`        |
| `policyEngine.tolerations`               | Tolerations for Anchore Policy Engine pod assignment                                                                                                                         | `[]`        |
| `policyEngine.affinity`                  | Affinity for Anchore Policy Engine pod assignment                                                                                                                            | `{}`        |
| `policyEngine.topologySpreadConstraints` | Topology spread constraints for Anchore Policy Engine pod assignment                                                                                                         | `[]`        |
| `policyEngine.serviceAccountName`        | Service account name for Anchore Policy Engine pods                                                                                                                          | `""`        |
| `policyEngine.scratchVolume.details`     | Details for the k8s volume to be created for Anchore Policy Engine scratch space                                                                                             | `{}`        |

### Anchore Reports Parameters

| Name                                | Description                                                                                                                                                                  | Value       |
| ----------------------------------- | ---------------------------------------------------------------------------------------------------------------------------------------------------------------------------- | ----------- |
| `reports.replicaCount`              | Number of replicas for the Anchore Reports deployment                                                                                                                        | `1`         |
| `reports.service.type`              | Service type for Anchore Reports                                                                                                                                             | `ClusterIP` |
| `reports.service.port`              | Service port for Anchore Reports                                                                                                                                             | `8558`      |
| `reports.service.annotations`       | Annotations for Anchore Reports service                                                                                                                                      | `{}`        |
| `reports.service.labels`            | Labels for Anchore Reports service                                                                                                                                           | `{}`        |
| `reports.service.nodePort`          | nodePort for Anchore Reports service                                                                                                                                         | `""`        |
| `reports.service.domainSuffix`      | domain suffix for appending to the ANCHORE_ENDPOINT_HOSTNAME. If blank, domainSuffix will be "namespace.svc.cluster.local". Takes precedence over the top level domainSuffix | `""`        |
| `reports.extraEnv`                  | Set extra environment variables for Anchore Reports pods                                                                                                                     | `[]`        |
| `reports.extraVolumes`              | Define additional volumes for Anchore Reports pods                                                                                                                           | `[]`        |
| `reports.extraVolumeMounts`         | Define additional volume mounts for Anchore Reports pods                                                                                                                     | `[]`        |
| `reports.resources`                 | Resource requests and limits for Anchore Reports pods                                                                                                                        | `{}`        |
| `reports.labels`                    | Labels for Anchore Reports pods                                                                                                                                              | `{}`        |
| `reports.annotations`               | Annotation for Anchore Reports pods                                                                                                                                          | `{}`        |
| `reports.nodeSelector`              | Node labels for Anchore Reports pod assignment                                                                                                                               | `{}`        |
| `reports.tolerations`               | Tolerations for Anchore Reports pod assignment                                                                                                                               | `[]`        |
| `reports.affinity`                  | Affinity for Anchore Reports pod assignment                                                                                                                                  | `{}`        |
| `reports.topologySpreadConstraints` | Topology spread constraints for Anchore Reports pod assignment                                                                                                               | `[]`        |
| `reports.serviceAccountName`        | Service account name for Anchore Reports pods                                                                                                                                | `""`        |
| `reports.scratchVolume.details`     | Details for the k8s volume to be created for Anchore Reports scratch space                                                                                                   | `{}`        |

### Anchore Reports Worker Parameters

| Name                                      | Description                                                                                                                                                                  | Value       |
| ----------------------------------------- | ---------------------------------------------------------------------------------------------------------------------------------------------------------------------------- | ----------- |
| `reportsWorker.replicaCount`              | Number of replicas for the Anchore Reports deployment                                                                                                                        | `1`         |
| `reportsWorker.service.type`              | Service type for Anchore Reports Worker                                                                                                                                      | `ClusterIP` |
| `reportsWorker.service.port`              | Service port for Anchore Reports Worker                                                                                                                                      | `8559`      |
| `reportsWorker.service.annotations`       | Annotations for Anchore Reports Worker service                                                                                                                               | `{}`        |
| `reportsWorker.service.labels`            | Labels for Anchore Reports Worker service                                                                                                                                    | `{}`        |
| `reportsWorker.service.nodePort`          | nodePort for Anchore Reports Worker service                                                                                                                                  | `""`        |
| `reportsWorker.service.domainSuffix`      | domain suffix for appending to the ANCHORE_ENDPOINT_HOSTNAME. If blank, domainSuffix will be "namespace.svc.cluster.local". Takes precedence over the top level domainSuffix | `""`        |
| `reportsWorker.extraEnv`                  | Set extra environment variables for Anchore Reports Worker pods                                                                                                              | `[]`        |
| `reportsWorker.extraVolumes`              | Define additional volumes for Anchore Reports Worker pods                                                                                                                    | `[]`        |
| `reportsWorker.extraVolumeMounts`         | Define additional volume mounts for Anchore Reports Worker pods                                                                                                              | `[]`        |
| `reportsWorker.resources`                 | Resource requests and limits for Anchore Reports Worker pods                                                                                                                 | `{}`        |
| `reportsWorker.labels`                    | Labels for Anchore Reports Worker pods                                                                                                                                       | `{}`        |
| `reportsWorker.annotations`               | Annotation for Anchore Reports Worker pods                                                                                                                                   | `{}`        |
| `reportsWorker.nodeSelector`              | Node labels for Anchore Reports Worker pod assignment                                                                                                                        | `{}`        |
| `reportsWorker.tolerations`               | Tolerations for Anchore Reports Worker pod assignment                                                                                                                        | `[]`        |
| `reportsWorker.affinity`                  | Affinity for Anchore Reports Worker pod assignment                                                                                                                           | `{}`        |
| `reportsWorker.topologySpreadConstraints` | Topology spread constraints for Anchore Reports Worker pod assignment                                                                                                        | `[]`        |
| `reportsWorker.serviceAccountName`        | Service account name for Anchore Reports Worker pods                                                                                                                         | `""`        |

### Anchore Simple Queue Parameters

| Name                                    | Description                                                                                                                                                                  | Value       |
| --------------------------------------- | ---------------------------------------------------------------------------------------------------------------------------------------------------------------------------- | ----------- |
| `simpleQueue.replicaCount`              | Number of replicas for the Anchore Simple Queue deployment                                                                                                                   | `1`         |
| `simpleQueue.service.type`              | Service type for Anchore Simple Queue                                                                                                                                        | `ClusterIP` |
| `simpleQueue.service.port`              | Service port for Anchore Simple Queue                                                                                                                                        | `8083`      |
| `simpleQueue.service.annotations`       | Annotations for Anchore Simple Queue service                                                                                                                                 | `{}`        |
| `simpleQueue.service.labels`            | Labels for Anchore Simple Queue service                                                                                                                                      | `{}`        |
| `simpleQueue.service.nodePort`          | nodePort for Anchore Simple Queue service                                                                                                                                    | `""`        |
| `simpleQueue.service.domainSuffix`      | domain suffix for appending to the ANCHORE_ENDPOINT_HOSTNAME. If blank, domainSuffix will be "namespace.svc.cluster.local". Takes precedence over the top level domainSuffix | `""`        |
| `simpleQueue.extraEnv`                  | Set extra environment variables for Anchore Simple Queue pods                                                                                                                | `[]`        |
| `simpleQueue.extraVolumes`              | Define additional volumes for Anchore Simple Queue pods                                                                                                                      | `[]`        |
| `simpleQueue.extraVolumeMounts`         | Define additional volume mounts for Anchore Simple Queue pods                                                                                                                | `[]`        |
| `simpleQueue.resources`                 | Resource requests and limits for Anchore Simple Queue pods                                                                                                                   | `{}`        |
| `simpleQueue.labels`                    | Labels for Anchore Simple Queue pods                                                                                                                                         | `{}`        |
| `simpleQueue.annotations`               | Annotation for Anchore Simple Queue pods                                                                                                                                     | `{}`        |
| `simpleQueue.nodeSelector`              | Node labels for Anchore Simple Queue pod assignment                                                                                                                          | `{}`        |
| `simpleQueue.tolerations`               | Tolerations for Anchore Simple Queue pod assignment                                                                                                                          | `[]`        |
| `simpleQueue.affinity`                  | Affinity for Anchore Simple Queue pod assignment                                                                                                                             | `{}`        |
| `simpleQueue.topologySpreadConstraints` | Topology spread constraints for Anchore Simple Queue pod assignment                                                                                                          | `[]`        |
| `simpleQueue.serviceAccountName`        | Service account name for Anchore Simple Queue pods                                                                                                                           | `""`        |

### Anchore UI Parameters

| Name                           | Description                                                                                                                                                                  | Value                                     |
| ------------------------------ | ---------------------------------------------------------------------------------------------------------------------------------------------------------------------------- | ----------------------------------------- |
| `ui.image`                     | Image used for the Anchore UI container                                                                                                                                      | `docker.io/anchore/enterprise-ui:v5.18.0` |
| `ui.imagePullPolicy`           | Image pull policy for Anchore UI image                                                                                                                                       | `IfNotPresent`                            |
| `ui.existingSecretName`        | Name of an existing secret to be used for Anchore UI DB and Redis endpoints                                                                                                  | `anchore-enterprise-ui-env`               |
| `ui.ldapsRootCaCertName`       | Name of the custom CA certificate file store in `.Values.certStoreSecretName`                                                                                                | `""`                                      |
| `ui.service.type`              | Service type for Anchore UI                                                                                                                                                  | `ClusterIP`                               |
| `ui.service.port`              | Service port for Anchore UI                                                                                                                                                  | `80`                                      |
| `ui.service.annotations`       | Annotations for Anchore UI service                                                                                                                                           | `{}`                                      |
| `ui.service.labels`            | Labels for Anchore UI service                                                                                                                                                | `{}`                                      |
| `ui.service.sessionAffinity`   | Session Affinity for Ui service                                                                                                                                              | `ClientIP`                                |
| `ui.service.nodePort`          | nodePort for Anchore UI service                                                                                                                                              | `""`                                      |
| `ui.service.domainSuffix`      | domain suffix for appending to the ANCHORE_ENDPOINT_HOSTNAME. If blank, domainSuffix will be "namespace.svc.cluster.local". Takes precedence over the top level domainSuffix | `""`                                      |
| `ui.extraEnv`                  | Set extra environment variables for Anchore UI pods                                                                                                                          | `[]`                                      |
| `ui.extraVolumes`              | Define additional volumes for Anchore UI pods                                                                                                                                | `[]`                                      |
| `ui.extraVolumeMounts`         | Define additional volume mounts for Anchore UI pods                                                                                                                          | `[]`                                      |
| `ui.resources`                 | Resource requests and limits for Anchore UI pods                                                                                                                             | `{}`                                      |
| `ui.labels`                    | Labels for Anchore UI pods                                                                                                                                                   | `{}`                                      |
| `ui.annotations`               | Annotation for Anchore UI pods                                                                                                                                               | `{}`                                      |
| `ui.nodeSelector`              | Node labels for Anchore UI pod assignment                                                                                                                                    | `{}`                                      |
| `ui.tolerations`               | Tolerations for Anchore UI pod assignment                                                                                                                                    | `[]`                                      |
| `ui.affinity`                  | Affinity for Anchore ui pod assignment                                                                                                                                       | `{}`                                      |
| `ui.topologySpreadConstraints` | Topology spread constraints for Anchore UI pod assignment                                                                                                                    | `[]`                                      |
| `ui.serviceAccountName`        | Service account name for Anchore UI pods                                                                                                                                     | `""`                                      |

### Anchore Upgrade Job Parameters

| Name                                   | Description                                                                                                                                     | Value                  |
| -------------------------------------- | ----------------------------------------------------------------------------------------------------------------------------------------------- | ---------------------- |
| `upgradeJob.enabled`                   | Enable the Anchore Enterprise database upgrade job                                                                                              | `true`                 |
| `upgradeJob.force`                     | Force the Anchore Feeds database upgrade job to run as a regular job instead of as a Helm hook                                                  | `false`                |
| `upgradeJob.rbacCreate`                | Create RBAC resources for the Anchore upgrade job                                                                                               | `true`                 |
| `upgradeJob.serviceAccountName`        | Use an existing service account for the Anchore upgrade job                                                                                     | `""`                   |
| `upgradeJob.usePostUpgradeHook`        | Use a Helm post-upgrade hook to run the upgrade job instead of the default pre-upgrade hook. This job does not require creating RBAC resources. | `false`                |
| `upgradeJob.kubectlImage`              | The image to use for the upgrade job's init container that uses kubectl to scale down deployments before an upgrade                             | `bitnami/kubectl:1.30` |
| `upgradeJob.nodeSelector`              | Node labels for the Anchore upgrade job pod assignment                                                                                          | `{}`                   |
| `upgradeJob.tolerations`               | Tolerations for the Anchore upgrade job pod assignment                                                                                          | `[]`                   |
| `upgradeJob.affinity`                  | Affinity for the Anchore upgrade job pod assignment                                                                                             | `{}`                   |
| `upgradeJob.topologySpreadConstraints` | Topology spread constraints for the Anchore upgrade job pod assignment                                                                          | `[]`                   |
| `upgradeJob.annotations`               | Annotations for the Anchore upgrade job                                                                                                         | `{}`                   |
| `upgradeJob.resources`                 | Resource requests and limits for the Anchore upgrade job                                                                                        | `{}`                   |
| `upgradeJob.labels`                    | Labels for the Anchore upgrade job                                                                                                              | `{}`                   |
| `upgradeJob.ttlSecondsAfterFinished`   | The time period in seconds the upgrade job, and it's related pods should be retained for                                                        | `-1`                   |

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

| Name                                  | Description                                                                                      | Value                              |
| ------------------------------------- | ------------------------------------------------------------------------------------------------ | ---------------------------------- |
| `ui-redis.chartEnabled`               | Use the dependent chart for the UI Redis deployment                                              | `true`                             |
| `ui-redis.externalEndpoint`           | External Redis endpoint when not using Helm managed chart (eg redis://:<password>@hostname:6379) | `""`                               |
| `ui-redis.auth.password`              | Password used for connecting to Redis                                                            | `anchore-redis,123`                |
| `ui-redis.architecture`               | Redis deployment architecture                                                                    | `standalone`                       |
| `ui-redis.master.persistence.enabled` | enables persistence                                                                              | `false`                            |
| `ui-redis.image.registry`             | Specifies the image registry to use for this chart.                                              | `docker.io`                        |
| `ui-redis.image.repository`           | Specifies the image repository to use for this chart.                                            | `bitnami/redis`                    |
| `ui-redis.image.tag`                  | Specifies the image to use for this chart.                                                       | `7.0.12-debian-11-r0`              |
| `ui-redis.image.pullSecrets`          | Specifies the image pull secrets to use for this chart.                                          | `["anchore-enterprise-pullcreds"]` |

### Anchore Database Parameters

| Name                                          | Description                                                                                 | Value                              |
| --------------------------------------------- | ------------------------------------------------------------------------------------------- | ---------------------------------- |
| `postgresql.chartEnabled`                     | Use the dependent chart for Postgresql deployment                                           | `true`                             |
| `postgresql.externalEndpoint`                 | External Postgresql hostname when not using Helm managed chart (eg. mypostgres.myserver.io) | `""`                               |
| `postgresql.auth.username`                    | Username used to connect to postgresql                                                      | `anchore`                          |
| `postgresql.auth.password`                    | Password used to connect to postgresql                                                      | `anchore-postgres,123`             |
| `postgresql.auth.database`                    | Database name used when connecting to postgresql                                            | `anchore`                          |
| `postgresql.primary.resources`                | The resource limits & requests for the PostgreSQL Primary containers                        | `{}`                               |
| `postgresql.primary.service.ports.postgresql` | Port used to connect to Postgresql                                                          | `5432`                             |
| `postgresql.primary.persistence.size`         | Configure size of the persistent volume for PostgreSQL Primary data volume                  | `20Gi`                             |
| `postgresql.primary.persistence.storageClass` | PVC Storage Class for PostgreSQL Primary data volume                                        | `""`                               |
| `postgresql.primary.extraEnvVars`             | An array to add extra environment variables                                                 | `[]`                               |
| `postgresql.image.repository`                 | Specifies the image repository to use for this chart.                                       | `bitnami/postgresql`               |
| `postgresql.image.registry`                   | Specifies the image registry to use for this chart.                                         | `docker.io`                        |
| `postgresql.image.tag`                        | Specifies the image to use for this chart.                                                  | `13.11.0-debian-11-r15`            |
| `postgresql.image.pullSecrets`                | Specifies the image pull secrets to use for this chart.                                     | `["anchore-enterprise-pullcreds"]` |

### Anchore Object Store and Analysis Archive Migration

| Name                                                         | Description                                                                                                      | Value                  |
| ------------------------------------------------------------ | ---------------------------------------------------------------------------------------------------------------- | ---------------------- |
| `osaaMigrationJob.enabled`                                   | Enable the Anchore Object Store and Analysis Archive migration job                                               | `false`                |
| `osaaMigrationJob.kubectlImage`                              | The image to use for the job's init container that uses kubectl to scale down deployments for the migration      | `bitnami/kubectl:1.30` |
| `osaaMigrationJob.extraEnv`                                  | An array to add extra environment variables                                                                      | `[]`                   |
| `osaaMigrationJob.extraVolumes`                              | Define additional volumes for Anchore Object Store and Analysis Archive migration job                            | `[]`                   |
| `osaaMigrationJob.extraVolumeMounts`                         | Define additional volume mounts for Anchore Object Store and Analysis Archive migration job                      | `[]`                   |
| `osaaMigrationJob.resources`                                 | Resource requests and limits for Anchore Object Store and Analysis Archive migration job                         | `{}`                   |
| `osaaMigrationJob.labels`                                    | Labels for Anchore Object Store and Analysis Archive migration job                                               | `{}`                   |
| `osaaMigrationJob.annotations`                               | Annotation for Anchore Object Store and Analysis Archive migration job                                           | `{}`                   |
| `osaaMigrationJob.nodeSelector`                              | Node labels for Anchore Object Store and Analysis Archive migration job pod assignment                           | `{}`                   |
| `osaaMigrationJob.tolerations`                               | Tolerations for Anchore Object Store and Analysis Archive migration job pod assignment                           | `[]`                   |
| `osaaMigrationJob.affinity`                                  | Affinity for Anchore Object Store and Analysis Archive migration job pod assignment                              | `{}`                   |
| `osaaMigrationJob.topologySpreadConstraints`                 | Topology spread constraints for Anchore Object Store and Analysis Archive migration job pod assignment           | `[]`                   |
| `osaaMigrationJob.serviceAccountName`                        | Service account name for Anchore Object Store and Analysis Archive migration job pods                            | `""`                   |
| `osaaMigrationJob.analysisArchiveMigration.bucket`           | The name of the bucket to migrate                                                                                | `analysis_archive`     |
| `osaaMigrationJob.analysisArchiveMigration.run`              | Run the analysis_archive migration                                                                               | `false`                |
| `osaaMigrationJob.analysisArchiveMigration.mode`             | The mode for the analysis_archive migration. valid values are 'to_analysis_archive' and 'from_analysis_archive'. | `to_analysis_archive`  |
| `osaaMigrationJob.analysisArchiveMigration.analysis_archive` | The configuration of the catalog.analysis_archive for the dest-config.yaml                                       | `{}`                   |
| `osaaMigrationJob.objectStoreMigration.run`                  | Run the object_store migration                                                                                   | `false`                |
| `osaaMigrationJob.objectStoreMigration.object_store`         | The configuration of the object_store for the dest-config.yaml                                                   | `{}`                   |

## Release Notes

For the latest updates and features in Anchore Enterprise, see the official [Release Notes](https://docs.anchore.com/current/docs/releasenotes/).

- **Major Chart Version Change (e.g., v0.1.2 -> v1.0.0)**: Signifies an incompatible breaking change that necessitates manual intervention, such as updates to your values file or data migrations.
- **Minor Chart Version Change (e.g., v0.1.2 -> v0.2.0)**: Indicates a significant change to the deployment that does not require manual intervention.
- **Patch Chart Version Change (e.g., v0.1.2 -> v0.1.3)**: Indicates a backwards-compatible bug fix or documentation update.

### V3.10.x

- Deploys Anchore Enterprise v5.18.x. See the [Release Notes](https://docs.anchore.com/current/docs/releasenotes/5180/) for more information.

### V3.9.x

- Updates image specification for Enterprise, Enterprise UI, and subsequent jobs (upgrade / osaa migration) and accepts a full pullstring (default), or the following dict (only one of tag or digest should be used, will default to digest if both are specified):
  - enterprise image:

    ```yaml
      image: docker.io/anchore/enterprise:v5.17.1
        # registry: docker.io
        # repository: anchore/enterprise
        # tag: "v5.17.1"
        # digest: sha256:abcdef123456
    ```

  - ui image:

    ```yaml
      ui:
        image: docker.io/anchore/enterprise-ui:v5.17.0
          # registry: docker.io
          # repository: anchore/enterprise-ui
          # tag: "v5.17.0"
          # digest: sha256:abcdef123456
    ```

- .Values.osaaMigrationJob.kubectlImage should now be specified under .Values.common.kubectlImage and accepts a full pullstring (default), or the following dict (only one of tag or digest should be used, will default to digest if both are specified):

  ```yaml
    kubectlImage:
      registry: docker.io
      repository: bitnami/kubectl
      tag: "1.30"
      digest:
  ```

### V3.8.x

- Changes ANCHORE_POLICY_ENGINE_ENABLE_PACKAGE_DB_LOAD configmap envvar from True to False for new installations of Anchore. If updating from an existing installation, the value will come from the existing configmap value. This value was changed because if set to True, Anchore will load file digest info for every installed package into a database table which can have an impact on the system performance. Most users will not need this by default.

### V3.7.x

- Deploys Anchore Enterprise v5.17.x. See the [Release Notes](https://docs.anchore.com/current/docs/releasenotes/5170/) for more information.

### V3.6.x

- Deploys Anchore Enterprise v5.16.x. See the [Release Notes](https://docs.anchore.com/current/docs/releasenotes/5160/) for more information.

### V3.5.x

- Deploys Anchore Enterprise v5.15.x. See the [Release Notes](https://docs.anchore.com/current/docs/releasenotes/5150/) for more information.

### V3.4.x

- Deploys Anchore Enterprise v5.14.x. See the [Release Notes](https://docs.anchore.com/current/docs/releasenotes/5140/) for more information.

### V3.3.x

- Deploys Anchore Enterprise v5.13.x. See the [Release Notes](https://docs.anchore.com/current/docs/releasenotes/5130/) for more information.
- Updates the malware scanning internal timeout from 2 minutes to 30 minutes for each 2 gig chunck

### V3.2.x

- Deploys Anchore Enterprise v5.12.x. See the [Release Notes](https://docs.anchore.com/current/docs/releasenotes/5120/) for more information.
- Updates the bitnami/kubectl image to 1.30 to address critical vulnerabilities present in bitnami/kubectl:1.27
- Updates the values of the following to "<ALLOW_API_CONFIGURATION>" to allow updating their respective configurations through the UI in the future. Any changes to these values will still be respected (ie. if you changed it previously or going forward). If a value was never set, it will still default to the previous default value, but the default value is now handled in the application itself.
  - `anchoreConfig.log_level`
  - `anchoreConfig.analyzer.configFile.malware.clamav.enabled`

### V3.1.x

- Deploys Anchore Enterprise v5.11.x. See the [Release Notes](https://docs.anchore.com/current/docs/releasenotes/5110/) for more information.

### V3.0.x

- Deploys Anchore Enterprise v5.10.x. See the [Release Notes](https://docs.anchore.com/current/docs/releasenotes/5100/) for more information.
- Feeds service has been removed as a dependency to the enterprise chart. Instead, Anchore will use Anchore's hosted Data Service.
  - If you had any ingress pointing to the feeds service api, that is no longer necessary as it doesn't exist anymore.
  - A new anchore component (deployment/service) called `datasyncer` has been added to sync with the Anchore hosted Data Service.
- :warning: **WARNING:** Values file changes necessary:
  - **The following values will have to be set manually in your values file**:
    - `anchoreConfig.policy_engine.vulnerabilities.matching.exclude.providers`
    - `anchoreConfig.policy_engine.vulnerabilities.matching.exclude.package_types`
  - If you don't want to exclude any providers or package types, you can set them to an empty list. eg:

    ```yaml
      anchoreConfig:
        policy_engine:
          vulnerabilities:
            matching:
              exclude:
                providers: []
                package_types: []
    ```

  - If you had any drivers disabled in your feeds deployment, you will have to exclude them. eg:

    ```yaml
      anchoreConfig:
        policy_engine:
          vulnerabilities:
            matching:
              exclude:
                providers: ['nvd', 'github']
                package_types: ['rpm']
    ```

    Refer to the [Anchore docs](https://docs.anchore.com/current/docs/configuration/feeds/feed_configuration/) for the available providers and package_types.
- The following values were added to the values file to handle the creation or reuse of pull creds and Anchore license secrets:
  - `useExistingLicenseSecret`: defaults to `true` to be backwards compatible with existing deployments. If you are doing a new deployment, you can either set the `license` field for the secret to be created for you or you can create the secret out of band from helm.
  - `useExistingPullCredSecret`: defaults to `true` to be backwards compatible with existing deployments. If you are doing a new deployment, you can either set the `imageCredentials` fields for a secret to be created for you or create the secret out of band from helm.

### V2.10.x

- Deploys Anchore Enterprise v5.9.x. See the [Release Notes](https://docs.anchore.com/current/docs/releasenotes/590/) for more information.

### V2.9.x

- Deploys Anchore Enterprise v5.8.x. See the [Release Notes](https://docs.anchore.com/current/docs/releasenotes/580/) for more information.
- **Helm upgrade SLO improvements:**
  - Deployments will only be scaled down when database upgrades are required, as determined by a major/minor version change of the appVersion in Chart.yaml.
  - Deployments will no longer be scaled down for Anchore Enterprise or Kubernetes resource  configuration changes.
- Adds a domainSuffix to the service name for all services' ANCHORE_ENDPOINT_HOSTNAME. *If using proxies, you will need to update it from the service name to the fqdn. eg. anchore-enterprise-api -> anchore-enterprise-api.mynamespace.svc.cluster.local*

### V2.8.x

- Deploys Anchore Enterprise v5.7.x. See the [Release Notes](https://docs.anchore.com/current/docs/releasenotes/570/) for more information.

### V2.7.x

- Deploys Anchore Enterprise v5.6.x. See the [Release Notes](https://docs.anchore.com/current/docs/releasenotes/560/) for more information.

### V2.6.x

- Deploys Anchore Enterprise v5.5.x. See the [Release Notes](https://docs.anchore.com/current/docs/releasenotes/550/) for more information.
- Adds support for service specific annotations.
- Adds a configurable job for object/analysis store backend migration.

### V2.5.x

- Deploys Anchore Enterprise v5.4.x. See the [Release Notes](https://docs.anchore.com/current/docs/releasenotes/540/) for more information.
- Anchore Enterprise v5.4.0 introduces changes to how RBAC is managed. The chart has been updated to reflect these changes, no action is required.
  - The rbac-manager and rbac-authorizer components are no longer necessary and have been removed from the chart.
  - The `rbacManager` and `rbacAuthorizer` sections of the values file have been removed.

### V2.4.x

- Deploys Anchore Enterprise v5.3.x. See the [Release Notes](https://docs.anchore.com/current/docs/releasenotes/530/) for more information.
- Bump kubeVersion requirement to allow deployment on Kubernetes v1.29.x clusters.

### V2.3.0

- Deploys Anchore Enterprise v5.2.0. See the [Release Notes](https://docs.anchore.com/current/docs/releasenotes/520/) for more information.
- The reports pod has been split out of the API deployment and is now a separate deployment. A new deployment called `reports_worker` has been added. This allows for more granular control over the resources allocated to the reports and reports_worker services.
  - :warning: **WARNING:** Values file changes necessary:
    - If you are using a custom port for the reports service, previously set with `api.service.reportsPort`, you will need to update your values file to use `reports.service.port` instead.
    - Component specific configurations such as resources (as well as annotations, labels, extraEnv, etc) were previously set for both reports pods found in the `reports_deployment` and `api_deployment` using the `reports.resources` section of the values file. These have been split into separate deployments and the resources are now set in the `reports.resources` and `reports_worker.resources` sections of the values file. If you are using custom resources, you will need to update your values file to reflect this change.
- The reports service is now an internal service and the GraphQLAPI/ReportsAPI is served to users by the API service and routed internally in the deployment as needed. This version of the chart removed deprecated ingress configurations to accommodate this change. Update your values file to remove all references to the `reports` service in the `ingress` section.

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
