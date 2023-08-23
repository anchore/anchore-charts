# Anchore Helm Chart

This chart deploys the Anchore Enterprise container image analysis system. Anchore requires a PostgreSQL database (>=9.6) which may be handled by the chart or supplied externally, and executes in a service-based architecture utilizing the following Anchore Enterprise services: External API, SimpleQueue, Catalog, Policy Engine, Analyzer, GUI, RBAC, Reporting, Notifications and On-premises Feeds. Enterprise services require a valid Anchore Enterprise license, as well as credentials with access to the private DockerHub repository hosting the images. These are not enabled by default.

Each of these services can be scaled and configured independently.

## Anchore Enterprise Components

 The following features are available to Anchore Enterprise customers. Please contact the Anchore team for more information about getting a license for the Enterprise features. [Anchore Enterprise Demo](https://anchore.com/demo/)

```txt
    * Role-based access control
    * LDAP integration
    * Graphical user interface
    * Customizable UI dashboards
    * On-premises feeds service
    * Proprietary vulnerability data feed (vulnDB, MSRC)
    * Anchore reporting API
    * Notifications - Slack, GitHub, Jira, etc.
    * Microsoft image vulnerability scanning
    * Kubernetes runtime image inventory/scanning
```

## Chart Details

The chart is split into global and service specific configurations for all Anchore Enterprise components.

* The `anchoreGlobal` section is for configuration values required by all Anchore components.
* The `anchoreEnterpriseGlobal` section is for configuration values required by all Anchore Enterprise components.
* Service specific configuration values allow customization for each individual service.

For a description of each component, view the official documentation at: [Anchore Enterprise Service Overview](https://docs.anchore.com/current/docs/overview/architecture/)

## Installing the Anchore Helm Chart

Anchore will take approximately three minutes to bootstrap. After the initial bootstrap period, Anchore will begin a vulnerability feed sync. During this time, image analysis will show zero vulnerabilities until the sync is completed. This sync can take multiple hours depending on which feeds are enabled. The following anchore-cli command is available to poll the system and report back when the engine is bootstrapped and the vulnerability feeds are all synced up. `anchore-cli system wait`

The recommended way to install the Anchore Helm Chart is with a customized values file and a custom release name. It is highly recommended to set non-default passwords when deploying. All passwords are set to defaults specified in the chart. It is also recommended to utilize an external database, rather then using the included postgresql chart.

Create a new file named `anchore_values.yaml` and add all desired custom values (see the following examples); then run the following command:

### Enabling Enterprise Services

Enterprise services require an Anchore Enterprise license, as well as credentials with
permission to the private docker repositories that contain the enterprise images.

To use this Helm chart with the Enterprise services enabled, perform the following steps.

1. Create a Kubernetes secret containing your license file.

    ```bash
    kubectl create secret generic anchore-enterprise-license --from-file=license.yaml=<PATH/TO/LICENSE.YAML>
    ```

1. Create a Kubernetes secret containing DockerHub credentials with access to the private Anchore Enterprise repositories.

    ```bash
    kubectl create secret docker-registry anchore-enterprise-pullcreds --docker-server=docker.io --docker-username=<DOCKERHUB_USER> --docker-password=<DOCKERHUB_PASSWORD> --docker-email=<EMAIL_ADDRESS>
    ```

1. (demo) Install the Helm chart using default values.

    ```bash
    helm repo add anchore https://charts.anchore.io
    helm install <release_name> --set anchoreEnterpriseGlobal.enabled=true anchore/anchore-engine
    ```

1. (production) Install the Helm chart using a custom anchore_values.yaml file - *see the following examples*.

    ```bash
    helm repo add anchore https://charts.anchore.io
    helm install <release_name> -f anchore_values.yaml anchore/anchore-engine
    ```

### Example anchore_values.yaml - installing Anchore Enterprise

*Note: Installs with chart managed PostgreSQL & Redis databases. This is not a guaranteed production ready config.*

```yaml
## anchore_values.yaml

postgresql:
  postgresPassword: <PASSWORD>
  persistence:
    size: 50Gi

anchoreGlobal:
  defaultAdminPassword: <PASSWORD>
  defaultAdminEmail: <EMAIL>
  enableMetrics: True

anchoreEnterpriseGlobal:
  enabled: true

anchore-feeds-db:
  postgresPassword: <PASSWORD>
  persistence:
    size: 20Gi

ui-redis:
  auth:
    password: <PASSWORD>
```

#### Helm v3 installation

```bash
helm repo add anchore https://charts.anchore.io
helm install <release_name> -f anchore_values.yaml anchore/anchore-engine
```

## Installing on OpenShift

As of chart version 1.3.1, deployments to OpenShift are fully supported. Due to permission constraints when utilizing OpenShift, the official RHEL postgresql image must be utilized, which requires custom environment variables to be configured for compatibility with this chart.

To perform an Enterprise deployment on OpenShift, use the following anchore_values.yaml configuration

*Note: Installs with chart managed PostgreSQL database. This is not a guaranteed production ready config.*

```yaml
## anchore_values.yaml

postgresql:
  image: registry.access.redhat.com/rhscl/postgresql-96-rhel7
  imageTag: latest
  extraEnv:
  - name: POSTGRESQL_USER
    value: anchoreengine
  - name: POSTGRESQL_PASSWORD
    value: <PGPASSWORD>
  - name: POSTGRESQL_DATABASE
    value: anchore
  - name: PGUSER
    value: postgres
  - name: LD_LIBRARY_PATH
    value: /opt/rh/rh-postgresql96/root/usr/lib64
  - name: PATH
     value: /opt/rh/rh-postgresql96/root/usr/bin:/opt/app-root/src/bin:/opt/app-root/bin:/usr/local/sbin:/usr/local/bin:/usr/sbin:/usr/bin:/sbin:/bin
    postgresPassword: <PGPASSWORD>
    persistence:
      size: 20Gi

anchoreGlobal:
  defaultAdminPassword: <PASSWORD>
  defaultAdminEmail: <EMAIL>
  enableMetrics: True
  openShiftDeployment: True
  securityContext:
    runAsUser: null
    runAsGroup: null
    fsGroup: null

anchore-feeds-db:
  image: registry.access.redhat.com/rhscl/postgresql-96-rhel7
  imageTag: latest
  extraEnv:
  - name: POSTGRESQL_USER
    value: anchoreengine
  - name: POSTGRESQL_PASSWORD
    value: <PGPASSWORD>
  - name: POSTGRESQL_DATABASE
    value: anchore
  - name: PGUSER
    value: postgres
  - name: LD_LIBRARY_PATH
    value: /opt/rh/rh-postgresql96/root/usr/lib64
  - name: PATH
     value: /opt/rh/rh-postgresql96/root/usr/bin:/opt/app-root/src/bin:/opt/app-root/bin:/usr/local/sbin:/usr/local/bin:/usr/sbin:/usr/bin:/sbin:/bin
    postgresPassword: <PGPASSWORD>
    persistence:
      size: 50Gi

ui-redis:
  auth:
    password: <PASSWORD>
  master:
    podSecurityContext:
      enabled: true
      fsGroup: 1000670000
    containerSecurityContext:
      enabled: true
      runAsUser: 1000670000
      runAsNonRoot: true
      allowPrivilegeEscalation: false
      capabilities:
        drop: ["ALL"]
      seccompProfile:
        type: "RuntimeDefault"
```

# Chart Updates

See the Anchore [Release Notes](https://docs.anchore.com/current/docs/releasenotes/) for updates to Anchore.

## Upgrading from previous chart versions

A Helm post-upgrade hook job will shut down all previously running Anchore services and perform the Anchore database upgrade process using a Kubernetes job.

The upgrade will only be considered successful when this job completes successfully. Performing an upgrade will cause the Helm client to block until the upgrade job completes and the new Anchore service pods are started. To view progress of the upgrade process, tail the logs of the upgrade jobs `anchore-engine-upgrade` and `anchore-enterprise-upgrade`. These job resources will be removed upon a successful Helm upgrade.

# Chart Version 1.27.0

* Anchore Enterprise image updated to v4.9.0 - [Release Notes](https://docs.anchore.com/current/docs/releasenotes/490/)

# Chart Version 1.26.3

* Anchore Enterprise image updated to v4.8.1 - [Release Notes](https://docs.anchore.com/current/docs/releasenotes/481/)

# Chart version 1.26.1

* Added `.Values.anchoreGlobal.usePreupgradeHook` to enable doing the enterprise and feeds upgrade jobs using a helm pre-upgrade hook. This is useful when doing helm upgrade with the --wait flag, or for ArgoCD. Enabling this option will create a service account and role with permissions to get/update/patch deployments and list pods. See templates/hooks/pre-upgrade/anchore_upgrade_role.yaml for a complete list of roles. This is disabled by default.

# Chart version 1.26.0

* Anchore Enterprise image updated to v4.8.0 - [Release Notes](https://docs.anchore.com/current/docs/releasenotes/480/)

## Chart version 1.25.0

* Anchore Enterprise image updated to v4.7.0 - [Release Notes](https://docs.anchore.com/current/docs/releasenotes/470/)

## Chart version 1.24.0

* Anchore Enterprise image updated to v4.6.0 - [Release Notes](https://docs.anchore.com/current/docs/releasenotes/460/)

* `.Values.anchoreGlobal.doSourceAtEntry.filePath` has been changed to `.Values.anchoreGlobal.doSourceAtEntry.filePaths` which accepts a list of file paths. This allows for multiple files to be sourced prior to starting the Anchore services instead of a single file.
  * Remove `.Values.anchoreGlobal.doSourceAtEntry.filePath` and add the following to your values file:

    ```yaml
    anchoreGlobal:
      doSourceAtEntry:
        filePaths:
          - /path/to/file1
          - /path/to/file2
    ```

* Updated the configuration for Anchore Enterprise database connections. This will ensure that special characters are handled properly in database passwords. Also allows configuring the db hostname and port separately. 

  * If your postgresql connection is using a non-standard port, you will need to update your values file to include the hostname and port. For example:

    ```yaml
    postgresql:
      externalEndpoint: <HOSTNAME>
      postgresPort: <PORT>
    ```

  * If you're using external secrets and an non-standard port, you will need to update your secrets to include the hostname and port.

    ```yaml
      ANCHORE_DB_HOST: <HOSTNAME>
      ANCHORE_DB_PORT: <PORT>
    ```

## Chart version 1.23.0

* Anchore Enterprise image updated to v4.5.0 - [Release Notes](https://docs.anchore.com/current/docs/releasenotes/450/)

## Chart version 1.22.0

* Anchore Enterprise image updated to v4.4.0 - [Release Notes](https://docs.anchore.com/current/docs/releasenotes/440/)
* Allow configuration of the URL used for pulling Ubuntu vulnerability feed.
* The UI now emits prometheus metrics when `.Values.anchoreGlobal.enableMetrics=true`

## Chart version 1.21.0

* Revamped how the chart is configured when using existing secrets. Users upgrading from a previous chart version will need to update their values file to match the new convention. Update the following in your values file:
  * Set `.Values.anchoreGlobal.useExistingSecrets=true`
  * Update your existing secrets to include all environment variables used by deployments
    * Add to the secret specified in `.Values.anchoreGlobal.existingSecretName`:
      * ANCHORE_DB_HOST
      * ANCHORE_DB_USER
      * ANCHORE_DB_NAME
    * Add to secret specified in `.Values.anchoreEnterpriseFeeds.existingSecretName`:
      * ANCHORE_FEEDS_DB_HOST
      * ANCHORE_FEEDS_DB_USER
      * ANCHORE_FEEDS_DB_NAME
  * Update the following keys:
    * `.Values.anchoreGlobal.existingSecret` -> `.Values.anchoreGlobal.existingSecretName`
    * `.Values.anchoreEnterpriseFeeds.existingSecret` -> `.Values.anchoreEnterpriseFeeds.existingSecretName`
    * `.Values.anchoreEnterpriseUi.existingSecret` -> `.Values.anchoreEnterpriseUi.existingSecretName`
* See the [existing secrets section](#utilize-an-existing-secret) for more details.

## Chart version 1.20.1

* Anchore Enterprise image update to v4.3.0 - [Release Notes](https://docs.anchore.com/current/docs/releasenotes/430/).
* Add configuration options for wolfi feed driver.

## Chart version 1.20.0

* Anchore Enterprise image update to v4.2.0 - [Release Notes](https://docs.anchore.com/current/docs/releasenotes/420/).
* Removed embedded k8s runtime inventory configurations.
  * Deletes service account, role, & rolebindigs created by `.Values.anchoreCatalog.createServiceAccount`.
  * To enable cluster runtime inventory use the [Kai Helm Chart](https://github.com/anchore/anchore-charts/tree/main/stable/kai).

## Chart version 1.19.0

* Redis chart updated from version 10 to 16.11.3 updated to the latest version as bitnami has started removing older version of their charts.
* redis will by default run in the `standalone` architecture.
* `anchore-ui-redis` in the helm values should now be `ui-redis`
  * if you've set the the `password` value under `anchore-ui-redis`, you will now have to change it to `auth.password`, making the end change `ui-redis.auth.password`

* WARNING: Users may be logged out from the platform after this happens since this will delete the old redis deployment and spin up a new one in its place
  * For more information on why this is necessary, see [the breaking change here](https://github.com/bitnami/charts/tree/master/bitnami/redis/#to-1400)

## Chart version 1.18.0

* Anchore Enterprise image updated to v4.0.0 - [Release Notes](https://docs.anchore.com/current/docs/releasenotes/400/)
* WARNING: For Anchore Enterprise deployments the v2 (grype) vulnerability scanner is the only valid configuration. The v1 (legacy) vulnerability scanner is no longer supported.
* The containers in the API pod have been split into 4 separate pods for better control of resource allocation & node placement. The new pods are deployed as follows:
  * External APIs (Engine API & Reports API)
  * Enterprise Notifications service
  * Enterprise Reports worker
  * Enterprise RBAC manager

## Chart version 1.17.1

* The number of concurrent worker threads used for downloading RHEL feeds has been made configurable and the default value has been reduced from 20 to 5. The default number of threads has been reduced due to recent throttling on concurrent requests from RHEL that was causing feed download failures.

## Chart version 1.17.0

Chart version 1.17.0 is an Enterprise focused release. Anchore users will see no change in behavior from this release.

For Enterprise users, this release specifically helps reduce downtime needed during the transition from the v1 scanner to the v2 scanner. This version sets the GrypeDB driver to run in the feed service v1-scanner deployments so that the GrypeDB is ready when the update to the v2 scanner is made and thus reduces effective downtime during the maintenance window needed for that configuration change.

It is recommended that users upgrade to this chart version prior to changing the scanner configuration to move from the V1 scanner to the V2 scanner.

  ### WARNING

  After this upgrade, the Enterprise Feeds service requires a minimum of 10GB of memory allocated. **Failure to allocate adequate resources to this pod will result in crash loops and an unavailable feeds service.** Resource allocation example:

  ```yaml
  anchoreEnterpriseFeeds:
    resources:
      limits:
        cpu: 1
        memory: 10G
      requests:
        cpu: 1
        memory: 10G
  ```

The impacts of this upgrade are as follows:

* For deployments currently utilizing the V1 (legacy) vulnerability provider, configured with `.Values.anchorePolicyEngine.vulnerabilityProvider=legacy`, this upgrade will enable the GrypeDB Driver on the Enterprise Feeds service.
  * The GrypeDB driver can be manually disabled for legacy deployments using `.Values.anchoreEnterpriseFeeds.grypeDriverEnabled=false`
* For deployments of Anchore, configured with `.Values.anchoreEnterpriseGlobal=false`, this upgrade will have zero impact.
* For Enterprise deployments currently utilizing the Grype vulnerability provider, configured with `.Values.anchorePolicyEngine.vulnerabilityProvider=grype`, this release will have zero impact.

## Chart version 1.16.0

* Anchore image updated to v1.1.0 - [Release Notes](https://engine.anchore.io/docs/releasenotes/110/)
* Anchore Enterprise image updated to v3.3.0 - [Release Notes](https://docs.anchore.com/current/docs/releasenotes/330/)

## Chart version 1.15.0

Chart version v1.15.0 sets the V2 vulnerability scanner, based on [Grype](https://github.com/anchore/grype), as the default for new deployments. **Users upgrading from chart versions prior to v1.15.0 will need to explicitly set their preferred vulnerability provider using `.Values.anchorePolicyEngine.vulnerabilityProvider`.** If the vulnerability provider is not explicitly set, Helm will prevent an upgrade from being initiated.

* Anchore image updated to v1.0.0 - [Release Notes](https://engine.anchore.io/docs/releasenotes/100/)
* Anchore Enterprise image updated to v3.2.0 - [Release Notes](https://docs.anchore.com/current/docs/releasenotes/320/)
* Enterprise Feeds - Now uses a PVC for the persistent workspace directory. This directory is used by the vulnerability drivers for downloading vulnerability data, and should be persistent for optimal performance.
* Enterprise Feeds - When enabling the Ruby Gems vulnerability driver, the Helm chart will now spin up an ephemeral Postgresql deployment for the Feeds service to load Ruby vulnerability data.

## Chart version 1.14.0

* Anchore image updated to v0.10.1 - [Release Notes](https://engine.anchore.io/docs/releasenotes/0101/)
* Anchore Enterprise image updated to v3.1.1 - [Release Notes](https://docs.anchore.com/current/docs/releasenotes/311/)
* Enterprise Feeds - MSRC feeds no longer require an access token. No changes are needed, however MSRC access tokens can now be removed from values and/or existing secrets.

## Chart version 1.13.0

* Anchore image updated to v0.10.0 - [Release Notes](https://engine.anchore.io/docs/releasenotes/0100/)
* Anchore Enterprise image updated to v3.1.0 - [Release Notes](https://docs.anchore.com/current/docs/releasenotes/310/)
* If utilizing the Enterprise Runtime Inventory feature, the catalog service can now be configured to automatically setup RBAC for image discovery within the cluster. This is configured under `.Values.anchoreCatalog.runtimeInventory`

## Chart version 1.12.0

* Anchore image updated to v0.9.1
* Anchore Enterprise images updated to v3.0.0
* Existing secrets now work for Enterprise feeds and Enterprise UI - see [existing secrets configuration](#-Utilize-an-Existing-Secret)
* Anchore admin default password no longer defaults to `foobar`. If no password is specified, a random string will be generated.

## Chart version 1.10.0

Chart dependency declarations have been updated to be compatible with Helm v3.4.0

## Chart version 1.8.0

The following features were added with this version:

* Malware scanning - see .Values.anchoreAnalyzer.configFile.malware
* Binary content scanning
* Content hints file analysis - see .Values.anchoreAnalyzer.enableHints
* Updated image deletion behavior

For more details see - https://docs.anchore.com/current/docs/engine/releasenotes/080

## Chart version 1.7.0

Starting with version 1.7.0, the anchore-engine chart will be hosted on charts.anchore.io. If you're upgrading from a previous version of the chart, you will need to delete your previous deployment and redeploy Anchore using the chart from the Anchore Charts repository.

This version of the chart includes the dependent Postgresql chart in the charts/ directory rather then pulling it from upstream. All apiVersions were updated for compatibility with Kubernetes v1.16+ and the postgresql image has been updated to version 9.6.18. The chart version also updates to the latest version of the Redis chart from Bitnami. These dependency updates require deleting and re-installing your chart.

# Configuration

All configurations should be appended to your custom `anchore_values.yaml` file and utilized when installing the chart. While the configuration options of Anchore are extensive, the options provided by the chart are as follows:

## Exposing the service outside the cluster using Ingress

This configuration allows SSL termination using your chosen ingress controller.

#### NGINX Ingress Controller

```yaml
ingress:
  enabled: true
```

#### ALB Ingress Controller

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

anchoreApi:
  service:
    type: NodePort

anchoreEnterpriseUi:
  service
    type: NodePort
```

#### GCE Ingress Controller

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

anchoreApi:
  service:
    type: NodePort

anchoreEnterpriseUi:
  service
    type: NodePort
```

## Exposing the service outside the cluster Using Service Type

```yaml
anchoreApi:
  service:
    type: LoadBalancer
```

## Utilize an Existing Secret

Rather than passing secrets into the Helm values file directly, users can create secrets in the namespace prior to deploying this Helm chart. When using existing secrets, the chart will load environment variables into deployments from the secret names specified by the following values:

* `.Values.anchoreGlobal.existingSecretName` [default: anchore-engine-env]
* `.Values.anchoreEnterpriseFeeds.existingSecretName` [default: anchore-enterprise-feeds-env]
* `.Values.anchoreEnterpriseUi.existingSecretName` [default: anchore-enterprise-ui-env]

To use existing secrets, set the following in your values file:

```yaml
anchoreGlobal:
  useExistingSecrets: true
```

Create the following secrets:
```yaml
# These secrets will work as-is when using helm deployed redis/postgresql with the default chart values and a helm release name of `anchore`. When utilizing these secrets, users are expected to update the environment variables with appropriate configurations for their environment.

---
apiVersion: v1
kind: Secret
metadata:
  name: anchore-engine-env
type: Opaque
stringData:
  ANCHORE_ADMIN_PASSWORD: foobar1234
  ANCHORE_DB_NAME: anchore
  ANCHORE_DB_USER: anchoreengine
  ANCHORE_DB_HOST: anchore-postgresql
  ANCHORE_DB_PORT: 5432
  ANCHORE_DB_PASSWORD: anchore-postgres,123
  # (if applicable) ANCHORE_SAML_SECRET: foobar,saml1234

---
apiVersion: v1
kind: Secret
metadata:
  name: anchore-enterprise-feeds-env
type: Opaque
stringData:
  ANCHORE_ADMIN_PASSWORD: foobar1234
  ANCHORE_FEEDS_DB_NAME: anchore-feeds
  ANCHORE_FEEDS_DB_USER: anchoreengine
  ANCHORE_FEEDS_DB_PASSWORD: anchore-postgres,123
  ANCHORE_FEEDS_DB_HOST: anchore-anchore-feeds-db
  ANCHORE_FEEDS_DB_PORT: 5432
  # (if applicable) ANCHORE_SAML_SECRET: foobar,saml1234
  # (if applicable) ANCHORE_GITHUB_TOKEN: foobar,github1234
  # (if applicable) ANCHORE_NVD_API_KEY: foobar,nvd1234
  # (if applicable) ANCHORE_GEM_DB_NAME: anchore-gems
  # (if applicable) ANCHORE_GEM_DB_USER: anchoregemsuser
  # (if applicable) ANCHORE_GEM_DB_PASSWORD: foobar1234
  # (if applicable) ANCHORE_GEM_DB_HOST: anchorefeeds-gem-db.example.com:5432

---
apiVersion: v1
kind: Secret
metadata:
  name: anchore-enterprise-ui-env
type: Opaque
stringData:
  # if using TLS to connect to Postgresql you must add the ?ssl=[require|verify-ca|verify-full] parameter to the end of the URI
  ANCHORE_APPDB_URI: postgresql://anchoreengine:anchore-postgres,123@anchore-postgresql:5432/anchore
  ANCHORE_REDIS_URI: redis://nouser:anchore-redis,123@anchore-ui-redis-master:6379
```

## Install using an existing/external PostgreSQL instance

*Note: it is recommended to use an external Postgresql instance for production installs.*

See comments in the values.yaml file for details on using SSL for external database connections.

```yaml
postgresql:
  postgresPassword: <PASSWORD>
  postgresUser: <USER>
  postgresDatabase: <DATABASE>
  enabled: false
  externalEndpoint: <HOSTNAME:5432>

anchoreGlobal:
  dbConfig:
    ssl: true
    sslMode: require
```

## Install using Google CloudSQL

```yaml
## anchore_values.yaml
postgresql:
  enabled: false
  postgresPassword: <CLOUDSQL-PASSWORD>
  postgresUser: <CLOUDSQL-USER>
  postgresDatabase: <CLOUDSQL-DATABASE>

cloudsql:
  enabled: true
  instance: "project:zone:cloudsqlinstancename"
  # Optional existing service account secret to use.
  useExistingServiceAcc: true
  serviceAccSecretName: my_service_acc
  serviceAccJsonName: for_cloudsql.json
  image:
    repository: gcr.io/cloudsql-docker/gce-proxy
    tag: 1.12
    pullPolicy: IfNotPresent
```

## Archive Driver

*Note: it is recommended to use an external archive driver for production installs.*

The archive subsystem of Anchore is what stores large JSON documents, and can consume substantial storage if
you analyze a lot of images. A general rule for storage provisioning is 10MB per image analyzed, so with thousands of
analyzed images, you may need many gigabytes of storage. The Archive drivers now support other backends than just postgresql,
so you can leverage external and scalable storage systems and keep the postgresql storage usage to a much lower level.

### Configuring Compression

The archive system has compression available to help reduce size of objects and storage consumed in exchange for slightly
slower performance and more cpu usage. There are two config values:

To toggle on/off (default is True), and set a minimum size for compression to be used (to avoid compressing things too small to be of much benefit, the default is 100):

```yaml
anchoreCatalog:
  archive:
    compression:
      enabled=True
      min_size_kbytes=100
```

### The supported archive drivers are

* S3 - Any AWS s3-api compatible system (e.g. minio, scality, etc)
* OpenStack Swift
* Local FS - A local file system on the core pod. It does not handle sharing or replication, so it is generally only for testing.
* DB - the default postgresql backend

### S3

```yaml
anchoreCatalog:
  archive:
    storage_driver:
      name: 's3'
      config:
        access_key: 'MY_ACCESS_KEY'
        secret_key: 'MY_SECRET_KEY'
        #iamauto: True
        url: 'https://S3-end-point.example.com'
        region: null
        bucket: 'anchorearchive'
        create_bucket: True
    compression:
    ... # Compression config here
```

### Using Swift

The Swift configuration is basically a pass-thru to the underlying pythonswiftclient so it can take quite a few different
options depending on your Swift deployment and config. The best way to configure the Swift driver is by using a custom values.yaml.

The Swift driver supports the following authentication methods:

* Keystone V3
* Keystone V2
* Legacy (username / password)

#### Keystone V3

```yaml
anchoreCatalog:
  archive:
    storage_driver:
      name: swift
      config:
        auth_version: '3'
        os_username: 'myusername'
        os_password: 'mypassword'
        os_project_name: myproject
        os_project_domain_name: example.com
        os_auth_url: 'foo.example.com:8000/auth/etc'
        container: 'anchorearchive'
        # Optionally
        create_container: True
    compression:
    ... # Compression config here
```

#### Keystone V2

```yaml
anchoreCatalog:
  archive:
    storage_driver:    
      name: swift
      config:
        auth_version: '2'
        os_username: 'myusername'
        os_password: 'mypassword'
        os_tenant_name: 'mytenant'
        os_auth_url: 'foo.example.com:8000/auth/etc'
        container: 'anchorearchive'
        # Optionally
        create_container: True
    compression:
    ... # Compression config here
```

#### Legacy Username/Password

```yaml
anchoreCatalog:
  archive:
    storage_driver:
      name: swift
      config:
        user: 'user:password'
        auth: 'http://swift.example.com:8080/auth/v1.0'
        key:  'anchore'
        container: 'anchorearchive'
        # Optionally
        create_container: True
    compression:
    ... # Compression config here
```

### Using Postgresql

This is the default archive driver and requires no additional configuration.

## Prometheus Metrics

Anchore supports exporting prometheus metrics form each container. Do the following to enable metrics:

```yaml
anchoreGlobal:
  enableMetrics: True
```

When enabled, each service provides the metrics over the existing service port so your prometheus deployment will need to
know about each pod, and the ports it provides to scrape the metrics.

## Using custom certificates

A secret needs to be created in the same namespace as the anchore-engine chart installation. This secret should contain all custom certs, including CA certs & any certs used for internal TLS communication. 
This secret will be mounted to all Anchore pods at /home/anchore/certs to be utilized by the system.

## Event Notifications

Anchore in v0.2.3 introduces a new events subsystem that exposes system-wide events via both a REST api as well
as via webhooks. The webhooks support filtering to ensure only certain event classes result in webhook calls to help limit
the volume of calls if you desire. Events, and all webhooks, are emitted from the core components, so configuration is
done in the coreConfig.

To configure the events:

```yaml
anchoreCatalog:
  events:
    notification:
      enabled:true
    level=error
```

## Scaling Individual Components

As of Chart version 0.9.0, all services can now be scaled-out by increasing the replica counts. The chart now supports
this configuration.

To set a specific number of service containers:

```yaml
anchoreAnalyzer:
  replicaCount: 5

anchorePolicyEngine:
  replicaCount: 3
```

To update the number in a running configuration:

```bash
helm upgrade --set anchoreAnalyzer.replicaCount=2 <releasename> anchore/anchore-engine -f anchore_values.yaml
```
