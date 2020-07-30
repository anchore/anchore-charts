# Anchore Engine Helm Chart

This chart deploys the Anchore Engine docker container image analysis system. Anchore Engine requires a PostgreSQL database (>=9.6) which may be handled by the chart or supplied externally, and executes in a service based architecture utilizing the following Anchore Engine services: External API, SimpleQueue, Catalog, Policy Engine, and Analyzer.

This chart can also be used to install the following Anchore Enterprise services: GUI, RBAC, Reporting, Notifications & On-premises Feeds. Enterprise services require a valid Anchore Enterprise License as well as credentials with access to the private DockerHub repository hosting the images. These are not enabled by default.

Each of these services can be scaled and configured independently.

See [Anchore Engine](https://github.com/anchore/anchore-engine) for more project details.

## Chart Details

The chart is split into global and service specific configurations for the OSS Anchore Engine, as well as global and services specific configurations for the Enterprise components.

  * The `anchoreGlobal` section is for configuration values required by all Anchore Engine components.
  * The `anchoreEnterpriseGlobal` section is for configuration values required by all Anchore Engine Enterprise components.
  * Service specific configuration values allow customization for each individual service.

For a description of each component, view the official documentation at: [Anchore Enterprise Service Overview](https://docs.anchore.com/current/docs/overview/architecture/)

## Installing the Anchore Engine Helm Chart
TL;DR - `helm repo add anchore-charts https://charts.anchore.io && helm install anchore-charts/anchore-engine`

Anchore Engine will take approximately 3 minutes to bootstrap. After the initial bootstrap period, Anchore Engine will begin a vulnerability feed sync. During this time, image analysis will show zero vulnerabilities until the sync is completed. This sync can take multiple hours depending on which feeds are enabled. The following anchore-cli command is available to poll the system and report back when the engine is bootstrapped and the vulnerability feeds are all synced up. `anchore-cli system wait`

The recommended way to install the Anchore Engine Helm Chart is with a customized values file and a custom release name. It is highly recommended to set non-default passwords when deploying, all passwords are set to defaults specified in the chart. It is also recommended to utilize an external database, rather then using the included postgresql chart.

Create a new file named `anchore_values.yaml` and add all desired custom values (examples below); then run the following command:

  #### Helm v3 installation
  `helm repo add anchore-charts https://charts.anchore.io`

  `helm install <release_name> -f anchore_values.yaml anchore-charts/anchore-engine`

##### Example anchore_values.yaml - using chart managed PostgreSQL service with custom passwords.
*Note: Installs with chart managed PostgreSQL database. This is not a guaranteed production ready config.*
```
## anchore_values.yaml

postgresql:
  postgresPassword: <PASSWORD>
  persistence:
    size: 50Gi

anchoreGlobal:
  defaultAdminPassword: <PASSWORD>
  defaultAdminEmail: <EMAIL>
```

## Adding Enterprise Components

 The following features are available to Anchore Enterprise customers. Please contact the Anchore team for more information about getting a license for the enterprise features. [Anchore Enterprise Demo](https://anchore.com/demo/)

    * Role based access control
    * LDAP integration
    * Graphical user interface
    * Customizable UI dashboards
    * On-premises feeds service
    * Proprietary vulnerability data feed (vulnDB, MSRC)
    * Anchore reporting API
    * Notifications - Slack, GitHub, Jira, etc
    * Microsoft image vulnerability scanning

### Enabling Enterprise Services
Enterprise services require an Anchore Enterprise license, as well as credentials with
permission to the private docker repositories that contain the enterprise images.

To use this Helm chart with the enterprise services enabled, perform these steps.

1. Create a kubernetes secret containing your license file.

    `kubectl create secret generic anchore-enterprise-license --from-file=license.yaml=<PATH/TO/LICENSE.YAML>`

1. Create a kubernetes secret containing DockerHub credentials with access to the private anchore enterprise repositories.

    `kubectl create secret docker-registry anchore-enterprise-pullcreds --docker-server=docker.io --docker-username=<DOCKERHUB_USER> --docker-password=<DOCKERHUB_PASSWORD> --docker-email=<EMAIL_ADDRESS>`

1. (demo) Install the Helm chart using default values
    #### Helm v3 installation
    `helm repo add anchore-charts https://charts.anchore.io`

    `helm install <release_name> --set anchoreEnterpriseGlobal.enabled=true anchore-charts/anchore-engine`

2. (production) Install the Helm chart using a custom anchore_values.yaml file - *see examples below*
    #### Helm v3 installation
    `helm repo add anchore-charts https://charts.anchore.io`

    `helm install <release_name> -f anchore_values.yaml anchore-charts/anchore-engine`

#### Example anchore_values.yaml - installing Anchore Enterprise

*Note: Installs with chart managed PostgreSQL & Redis databases. This is not a guaranteed production ready config.*
```
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
  enabled: True

anchore-feeds-db:
  postgresPassword: <PASSWORD>
  persistence:
    size: 20Gi

anchore-ui-redis:
  password: <PASSWORD>
```

## Installing on OpenShift
As of chart version 1.3.1 deployments to OpenShift are fully supported. Due to permission constraints when utilizing OpenShift, the official RHEL postgresql image must be utilized, which requires custom environment variables to be configured for compatibility with this chart.

#### Example anchore_values.yaml - deploying on OpenShift
*Note: Installs with chart managed PostgreSQL database. This is not a guaranteed production ready config.*
```
## anchore_values.yaml

postgresql:
  image: registry.access.redhat.com/rhscl/postgresql-96-rhel7
  imageTag: latest
  extraEnv:
  - name: POSTGRESQL_USER
    value: anchoreengine
  - name: POSTGRESQL_PASSWORD
    value: anchore-postgres,123
  - name: POSTGRESQL_DATABASE
    value: anchore
  - name: PGUSER
    value: postgres
  - name: LD_LIBRARY_PATH
    value: /opt/rh/rh-postgresql96/root/usr/lib64
  - name: PATH
     value: /opt/rh/rh-postgresql96/root/usr/bin:/opt/app-root/src/bin:/opt/app-root/bin:/usr/local/sbin:/usr/local/bin:/usr/sbin:/usr/bin:/sbin:/bin
  postgresPassword: <PASSWORD>
  persistence:
    size: 50Gi

anchoreGlobal:
  defaultAdminPassword: <PASSWORD>
  defaultAdminEmail: <EMAIL>
  openShiftDeployment: True
```

To perform an Enterprise deployment on OpenShift use the following anchore_values.yaml configuration

*Note: Installs with chart managed PostgreSQL database. This is not a guaranteed production ready config.*
```
## anchore_values.yaml

postgresql:
  image: registry.access.redhat.com/rhscl/postgresql-96-rhel7
  imageTag: latest
  extraEnv:
  - name: POSTGRESQL_USER
    value: anchoreengine
  - name: POSTGRESQL_PASSWORD
    value: anchore-postgres,123
  - name: POSTGRESQL_DATABASE
    value: anchore
  - name: PGUSER
    value: postgres
  - name: LD_LIBRARY_PATH
    value: /opt/rh/rh-postgresql96/root/usr/lib64
  - name: PATH
     value: /opt/rh/rh-postgresql96/root/usr/bin:/opt/app-root/src/bin:/opt/app-root/bin:/usr/local/sbin:/usr/local/bin:/usr/sbin:/usr/bin:/sbin:/bin
    postgresPassword: <PASSWORD>
    persistence:
      size: 20Gi

anchoreGlobal:
  defaultAdminPassword: <PASSWORD>
  defaultAdminEmail: <EMAIL>
  enableMetrics: True
  openShiftDeployment: True

anchoreEnterpriseGlobal:
  enabled: True

anchore-feeds-db:
  image: registry.access.redhat.com/rhscl/postgresql-96-rhel7
  imageTag: latest
  extraEnv:
  - name: POSTGRESQL_USER
    value: anchoreengine
  - name: POSTGRESQL_PASSWORD
    value: anchore-postgres,123
  - name: POSTGRESQL_DATABASE
    value: anchore
  - name: PGUSER
    value: postgres
  - name: LD_LIBRARY_PATH
    value: /opt/rh/rh-postgresql96/root/usr/lib64
  - name: PATH
     value: /opt/rh/rh-postgresql96/root/usr/bin:/opt/app-root/src/bin:/opt/app-root/bin:/usr/local/sbin:/usr/local/bin:/usr/sbin:/usr/bin:/sbin:/bin
    postgresPassword: <PASSWORD>
    persistence:
      size: 50Gi

anchore-ui-redis:
  password: <PASSWORD>
```
# Chart Updates
See the anchore-engine [CHANGELOG](https://github.com/anchore/anchore-engine/blob/master/CHANGELOG.md) for updates to anchore engine.

## Upgrading from previous chart versions
A Helm post-upgrade hook job will shut down all previously running Anchore services and perform the Anchore DB upgrade process using a kubernetes job. The upgrade will only be considered successful when this job completes successfully. Performing an upgrade will cause the Helm client to block until the upgrade job completes and the new Anchore service pods are started. To view progress of the upgrade process, tail the logs of the upgrade jobs `anchore-engine-upgrade` and `anchore-enterprise-upgrade`. These job resources will be removed upon a successful helm upgrade.

## Chart version 1.7.0


### Migrating The Anchore Engine Chart To The New Anchore Charts Repository

**FIXME write a nice overview paragraph here.**

For these examples, we assume that your namespace is called `my-namespace` and your Anchore installation is called `my-anchore`.

These examples use Helm version 3 and kubectl client version 1.18 and server version 1.14.

#### Scan An Image For A Quick Validation Upon Reinstallation

Scan an image to use as a quick validation of your data once you reinstall Anchore Engine (the command used to run an anchore-cli pod in your cluster may differ based on your namespace and installation names). You may wish to use a different image; we're using `alpine:latest`:

      $ kubectl run -i --tty anchore-cli --restart=Always --image anchore/engine-cli  --env ANCHORE_CLI_USER=admin --env ANCHORE_CLI_PASS=${ANCHORE_CLI_PASS} --env ANCHORE_CLI_URL=http://my-anchore-anchore-engine-legacy-api.my-namespace.svc.cluster.local:8228/v1/
      [anchore@anchore-cli anchore-cli]$ anchore-cli image add alpine:latest
      Image Digest: sha256:a15790640a6690aa1730c38cf0a440e2aa44aaca9b0e8931a9f2b0d7cc90fd65
      Parent Digest: sha256:185518070891758909c9f839cf4ca393ee977ac378609f700f60a771a2dfe321
      Analysis Status: not_analyzed
      Image Type: docker
      Analyzed At: None
      Image ID: a24bb4013296f61e89ba57005a7b3e52274d8edd3ae2077d04395f806b63d83e
      Dockerfile Mode: None
      Distro: None
      Distro Version: None
      Size: None
      Architecture: None
      Layer Count: None

      Full Tag: docker.io/alpine:latest
      Tag Detected At: 2020-06-25T23:28:49Z

Wait a short while, then:

      [anchore@anchore-cli anchore-cli]$ anchore-cli evaluate check alpine:latest
      Image Digest: sha256:a15790640a6690aa1730c38cf0a440e2aa44aaca9b0e8931a9f2b0d7cc90fd65
      Full Tag: docker.io/alpine:latest
      Status: pass
      Last Eval: 2020-06-25T23:29:47Z
      Policy ID: 2c53a13c-1765-11e8-82ef-23527761d060

Note the results to refer to later.

#### Determine Your Database PersistentVolumeClaim

Find the name of the database PersistentVolumeClaim using `kubectl`:

      $ kubectl get persistentvolumeclaim --namespace my-namespace
      NAME                    STATUS   VOLUME                                     CAPACITY   ACCESS MODES   STORAGECLASS   AGE
      my-anchore-postgresql   Bound   pvc-739f6f21-b73b-11ea-a2b9-42010a800176    20Gi       RWO            standard       2d

The name of your PersistentVolumeClaim in the example shown is `my-anchore-postgresql`. Note that, as you will need it later.

#### Uninstall Your Anchore Installation With Helm

      $ helm uninstall --namespace=my-namespace my-anchore
      release "my-anchore" uninstalled

Your PersistentVolumeClaim will still be resident in your cluster:

      $ kubectl get persistentvolumeclaim --namespace my-namespace
      NAME                    STATUS   VOLUME                                     CAPACITY   ACCESS MODES   STORAGECLASS   AGE
      my-anchore-postgresql   Bound    pvc-739f6f21-b73b-11ea-a2b9-42010a800176   20Gi       RWO            standard       2d

#### Add The New Anchore Helm Chart Repository And Install The Anchore Helm Chart

      $ helm repo add anchore-charts https://charts.anchore.io
      "anchore-charts" has been added to your repositories

      $ helm repo update
      Hang tight while we grab the latest from your chart repositories...
      ...Successfully got an update from the "anchore-charts" chart repository

This is where you'll need the name of the PersistentVolumeClaim from above, to override the value `postgresql.persistence.existingclaim`:

      $ helm install --set postgresql.persistence.existingclaim=my-anchore-postgresql --namespace=my-namespace my-anchore anchore-charts/anchore-engine
      NAME: my-anchore
      LAST DEPLOYED: Thu Jun 25 12:25:33 2020
      NAMESPACE: my-namespace
      STATUS: deployed
      REVISION: 1
      TEST SUITE: None
      NOTES:
      To use Anchore Engine you need the URL, username, and password to access the API.
      ...more instructions...

Verify that your PersistentVolumeClaim is in place:

      $ kubectl get persistentvolumeclaim --namespace my-namespace
      NAME                    STATUS   VOLUME                                     CAPACITY   ACCESS MODES   STORAGECLASS   AGE
      my-anchore-postgresql   Bound    pvc-739f6f21-b73b-11ea-a2b9-42010a800176   20Gi       RWO            standard       2d

Reconnect to the anchore-cli pod, or create another.  Then validate that you still have the results from scanning `alpine:latest` (the "Last Eval" time will differ, as it's the time the evaluate command is run):

      [anchore@anchore-cli anchore-cli]$ anchore-cli evaluate check alpine:latest
      Image Digest: sha256:a15790640a6690aa1730c38cf0a440e2aa44aaca9b0e8931a9f2b0d7cc90fd65
      Full Tag: docker.io/alpine:latest
      Status: pass
      Last Eval: 2020-06-25T23:34:05Z
      Policy ID: 2c53a13c-1765-11e8-82ef-23527761d060

You are now running Anchore Engine from the new chart repository, with your data in place.


### Migrating The Anchore Enterprise Chart To The New Anchore Charts Repository

**FIXME write a nice overview paragraph here.**

For these examples, we assume that your namespace is called `my-namespace` and your Anchore installation is called `my-anchore`.

These examples use Helm version 3 and kubectl client version 1.18 and server version 1.14.

#### Scan An Image For A Quick Validation Upon Reinstallation

Scan an image to use as a quick validation of your data once you reinstall Anchore Engine (the command used to run an anchore-cli pod in your cluster may differ based on your namespace and installation names). You may wish to use a different image; we're using `alpine:latest`:

      $ kubectl run -i --tty anchore-cli --restart=Always --image anchore/engine-cli  --env ANCHORE_CLI_USER=admin --env ANCHORE_CLI_PASS=${ANCHORE_CLI_PASS} --env ANCHORE_CLI_URL=http://my-anchore-anchore-engine-legacy-api.my-namespace.svc.cluster.local:8228/v1/
      [anchore@anchore-cli anchore-cli]$ anchore-cli image add alpine:latest
      Image Digest: sha256:a15790640a6690aa1730c38cf0a440e2aa44aaca9b0e8931a9f2b0d7cc90fd65
      Parent Digest: sha256:185518070891758909c9f839cf4ca393ee977ac378609f700f60a771a2dfe321
      Analysis Status: not_analyzed
      Image Type: docker
      Analyzed At: None
      Image ID: a24bb4013296f61e89ba57005a7b3e52274d8edd3ae2077d04395f806b63d83e
      Dockerfile Mode: None
      Distro: None
      Distro Version: None
      Size: None
      Architecture: None
      Layer Count: None

      Full Tag: docker.io/alpine:latest
      Tag Detected At: 2020-06-25T23:28:49Z

Wait a short while, then:

      [anchore@anchore-cli anchore-cli]$ anchore-cli evaluate check alpine:latest
      Image Digest: sha256:a15790640a6690aa1730c38cf0a440e2aa44aaca9b0e8931a9f2b0d7cc90fd65
      Full Tag: docker.io/alpine:latest
      Status: pass
      Last Eval: 2020-06-25T23:29:47Z
      Policy ID: 2c53a13c-1765-11e8-82ef-23527761d060

Note the results to refer to later.

#### Determine Your Database PersistentVolumeClaim

Find the names of the database PersistentVolumeClaims using `kubectl`:

      $ kubectl get persistentvolumeclaim --namespace my-namespace
      NAME                                           STATUS   VOLUME                                     CAPACITY   ACCESS MODES   STORAGECLASS   AGE
      my-anchore-anchore-feeds-db                    Bound    pvc-cd7ebb6f-bbe0-11ea-b9bf-42010a800020   20Gi       RWO            standard       3d
      my-anchore-postgresql                          Bound    pvc-cd7dc7d2-bbe0-11ea-b9bf-42010a800020   20Gi       RWO            standard       3d

The names of the PersistentVolumeClaims in the example shown are `my-anchore-anchore-feeds-db` and `my-anchore-postgresql`, You may have other persistent volume clains, but only `my-anchore-anchore-feeds-db` and `my-anchore-postgresql` are relevant for this migration; note the names, as you will need them later.

#### Uninstall Your Anchore Installation With Helm

      $ helm uninstall --namespace=my-namespace my-anchore
      release "my-anchore" uninstalled

Remove the Redis DB PersistentVolumeClaim, as another will be created when reinstalling:

    $ kubectl delete pvc redis-data-my-anchore-anchore-ui-redis-master-0

Your other PersistentVolumeClaims will still be resident in your cluster:

      $ kubectl get persistentvolumeclaim --namespace my-namespace
      NAME                          STATUS   VOLUME                                     CAPACITY   ACCESS MODES   STORAGECLASS   AGE
      my-anchore-anchore-feeds-db   Bound    pvc-a22abf70-bbb9-11ea-840b-42010a8001d8   20Gi       RWO            standard       3d
      my-anchore-postgresql         Bound    pvc-e6daf90a-bbb8-11ea-840b-42010a8001d8   20Gi       RWO            standard       3d

#### Add The New Anchore Helm Chart Repository And Install The Anchore Helm Chart

      $ helm repo add anchore-charts https://charts.anchore.io
      "anchore-charts" has been added to your repositories

      $ helm repo update
      Hang tight while we grab the latest from your chart repositories...
      ...Successfully got an update from the "anchore-charts" chart repository

This is where you'll need the name of the PersistentVolumeClaims from above, to set the values `postgresql.persistence.existingclaim` and `anchore-feeds-db.persistence.existingclaim`.  Note that in the helm command, we're including a simple values file to enable Anchore Enterprise:

      $ cat enterprise_values.yaml
      anchoreEnterpriseGlobal:
        enabled: true

      $ helm install --set postgresql.persistence.existingclaim=my-anchore-postgresql,anchore-feeds-db.persistence.existingclaim=my-anchore-anchore-feeds-db --namespace=my-namespace my-anchore -f enterprise_values.yaml new-repo-name/anchore-engine
      NAME: my-anchore
      LAST DEPLOYED: Thu Jun 25 12:25:33 2020
      NAMESPACE: my-namespace
      STATUS: deployed
      REVISION: 1
      TEST SUITE: None
      NOTES:
      To use Anchore Engine you need the URL, username, and password to access the API.
      ...more instructions...

Your PersistentVolumeClaims are in place:

      $ kubectl get persistentvolumeclaim --namespace my-namespace
      NAME                          STATUS   VOLUME                                     CAPACITY   ACCESS MODES   STORAGECLASS   AGE
      my-anchore-anchore-feeds-db   Bound    pvc-a22abf70-bbb9-11ea-840b-42010a8001d8   20Gi       RWO            standard       3d
      my-anchore-postgresql         Bound    pvc-e6daf90a-bbb8-11ea-840b-42010a8001d8   20Gi       RWO            standard       3d

Reconnect to the anchore-cli pod, or create another.  Then validate that you still have the results from scanning `alpine:latest` (the "Last Eval" time will differ, as it's the time the evaluate command is run):

      [anchore@anchore-cli anchore-cli]$ anchore-cli evaluate check alpine:latest
      Image Digest: sha256:a15790640a6690aa1730c38cf0a440e2aa44aaca9b0e8931a9f2b0d7cc90fd65
      Full Tag: docker.io/alpine:latest
      Status: pass
      Last Eval: 2020-06-25T23:34:05Z
      Policy ID: 2c53a13c-1765-11e8-82ef-23527761d060

You are now running Anchore Enterprise from the new chart repository, with your data in place.


# Configuration

All configurations should be appended to your custom `anchore_values.yaml` file and utilized when installing the chart. While the configuration options of Anchore Engine are extensive, the options provided by the chart are:

## Exposing the service outside the cluster:

#### Using Ingress

This configuration allows SSL termination using your chosen ingress controller.

##### NGINX Ingress Controller
```
ingress:
  enabled: true
```

##### ALB Ingress Controller
```
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

##### GCE Ingress Controller
  ```
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

#### Using Service Type
  ```
  anchoreApi:
    service:
      type: LoadBalancer
  ```

### Utilize an Existing Secret
Can be used to override the default secrets.yaml provided
```
anchoreGlobal:
  existingSecret: "foo-bar"
```

### Install using an existing/external PostgreSQL instance
*Note: it is recommended to use an external Postgresql instance for production installs*

  ```
  postgresql:
    postgresPassword: <PASSWORD>
    postgresUser: <USER>
    postgresDatabase: <DATABASE>
    enabled: false
    externalEndpoint: <HOSTNAME:5432>

  anchoreGlobal:
    dbConfig:
      ssl: true
  ```

### Install using Google CloudSQL
  ```
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

### Archive Driver
*Note: it is recommended to use an external archive driver for production installs.*

The archive subsystem of Anchore Engine is what stores large json documents and can consume quite a lot of storage if
you analyze a lot of images. A general rule for storage provisioning is 10MB per image analyzed, so with thousands of
analyzed images, you may need many gigabytes of storage. The Archive drivers now support other backends than just postgresql,
so you can leverage external and scalable storage systems and keep the postgresql storage usage to a much lower level.

##### Configuring Compression:

The archive system has compression available to help reduce size of objects and storage consumed in exchange for slightly
slower performance and more cpu usage. There are two config values:

To toggle on/off (default is True), and set a minimum size for compression to be used (to avoid compressing things too small to be of much benefit, the default is 100):

  ```
  anchoreCatalog:
    archive:
      compression:
        enabled=True
        min_size_kbytes=100
  ```

##### The supported archive drivers are:

* S3 - Any AWS s3-api compatible system (e.g. minio, scality, etc)
* OpenStack Swift
* Local FS - A local filesystem on the core pod. Does not handle sharding or replication, so generally only for testing.
* DB - the default postgresql backend

#### S3:
  ```
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

#### Using Swift:

The swift configuration is basically a pass-thru to the underlying pythonswiftclient so it can take quite a few different
options depending on your swift deployment and config. The best way to configure the swift driver is by using a custom values.yaml

The Swift driver supports three authentication methods:

* Keystone V3
* Keystone V2
* Legacy (username / password)

##### Keystone V3:
  ```
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

##### Keystone V2:
  ```
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

##### Legacy username/password:
  ```
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

#### Postgresql:

This is the default archive driver and requires no additional configuration.

### Prometheus Metrics

Anchore Engine supports exporting prometheus metrics form each container. To enable metrics:
  ```
  anchoreGlobal:
    enableMetrics: True
  ```

When enabled, each service provides the metrics over the existing service port so your prometheus deployment will need to
know about each pod and the ports it provides to scrape the metrics.

### Using custom certificates
A secret needs to be created in the same namespace as the anchore-engine chart installation. This secret should contain all custom certs, including CA certs & any certs used for internal TLS communication. 
This secret will be mounted to all anchore-engine pods at /home/anchore/certs to be utilized by the system.

### Event Notifications

Anchore Engine in v0.2.3 introduces a new events subsystem that exposes system-wide events via both a REST api as well
as via webhooks. The webhooks support filtering to ensure only certain event classes result in webhook calls to help limit
the volume of calls if you desire. Events, and all webhooks, are emitted from the core components, so configuration is
done in the coreConfig.

To configure the events:
  ```
  anchoreCatalog:
    events:
      notification:
        enabled:true
      level=error
  ```

### Scaling Individual Components

As of Chart version 0.9.0, all services can now be scaled-out by increasing the replica counts. The chart now supports
this configuration.

To set a specific number of service containers:
  ```
  anchoreAnalyzer:
    replicaCount: 5

  anchorePolicyEngine:
    replicaCount: 3
  ```

To update the number in a running configuration:

`helm upgrade --set anchoreAnalyzer.replicaCount=2 <releasename> anchore-charts/anchore-engine -f anchore_values.yaml`
