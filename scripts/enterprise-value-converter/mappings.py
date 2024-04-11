# If we see this as first level, just skip them
KEYS_WITHOUT_CHANGES = {
    "cloudsql",
    "ingress"
}

# check this last. If this is the last thing, and it starts with this, drop the key. eg anchoreGlobal.something -> something
CHECK_LAST = {
    "anchoreEnterpriseGlobal",
    "anchoreGlobal"
}

# if first level in dep charts, and no matches in any of mapping, log to file
DEPENDENCY_CHARTS = {
    "anchore-feeds-db": "feeds-db",
    "anchore-feeds-gem-db": "gem-db",
    "anchore-ui-redis": "ui-redis",
    "postgresql": "postgresql",
    "ui-redis": "ui-redis"
}

# if second key is in this list, replace first key with the value from TOP_LEVEL_MAPPING
KUBERNETES_KEYS = {
    "affinity",
    "annotations",
    "deploymentAnnotations",
    "extraEnv",
    "labels",
    "nodeSelector",
    "replicaCount",
    "resources",
    "service",
    "tolerations",
    "serviceAccountName"
}
TOP_LEVEL_MAPPING = {
    "anchore-feeds-db": "feeds.feeds-db",
    "anchore-feeds-gem-db": "feeds.gem-db",
    "anchore-ui-redis": "ui-redis",
    "anchoreAnalyzer": "analyzer",
    "anchoreApi": "api",
    "anchoreCatalog": "catalog",
    "anchoreEnterpriseEngineUpgradeJob": "upgradeJob",
    "anchoreEnterpriseFeeds": "feeds",
    "anchoreEnterpriseFeedsUpgradeJob": "feeds.feedsUpgradeJob",
    "anchoreEnterpriseNotifications": "notifications",
    "anchoreEnterpriseRbac": "rbacManager",
    "anchoreEnterpriseReports": "reports",
    "anchoreEnterpriseUi": "ui",
    "anchorePolicyEngine": "policyEngine",
    "anchoreSimpleQueue": "simpleQueue",
    "ingress": "ingress"
}

LEVEL_TWO_CHANGE_KEY_MAPPING = {
    "anchore-feeds-db.externalEndpoint": "feeds.feeds-db.externalEndpoint",
    "anchoreEnterpriseUi.customLinks": "anchoreConfig.ui.custom_links",
    "anchoreEnterpriseUi.enableAddRepositories": "anchoreConfig.ui.enable_add_repositories",
    "anchoreEnterpriseFeeds.url": "feeds.url",
    ########################################################################
    ################ TEST configfile, set malware stuff ####################
    ########################################################################
    "anchoreAnalyzer.configFile": "anchoreConfig.analyzer.configFile",
    "anchoreApi.external": "anchoreConfig.apiext.external",
    "anchoreCatalog.analysis_archive": "anchoreConfig.catalog.analysis_archive",
    "anchoreCatalog.cycleTimers": "anchoreConfig.catalog.cycle_timers",
    "anchoreCatalog.events": "anchoreConfig.catalog.event_log",
    "anchoreCatalog.object_store": "anchoreConfig.catalog.object_store",
    "anchoreEnterpriseEngineUpgradeJob.enabled": "upgradeJob.enabled",
    "anchoreEnterpriseFeeds.cycleTimers": "feeds.anchoreConfig.feeds.cycle_timers",
    "anchoreEnterpriseFeeds.dbConfig": "feeds.anchoreConfig.dbConfig",
    "anchoreEnterpriseFeeds.debianExtraReleases": "feeds.anchoreConfig.feeds.drivers.debian.releases",

    "anchoreEnterpriseFeeds.gemDriverEnabled": "feeds.anchoreConfig.feeds.drivers.gem.enabled",
    "anchoreEnterpriseFeeds.githubDriverEnabled": "feeds.anchoreConfig.feeds.drivers.github.enabled",
    "anchoreEnterpriseFeeds.githubDriverToken": "feeds.anchoreConfig.feeds.drivers.github.token",

    "anchoreEnterpriseFeeds.msrcWhitelist": "feeds.anchoreConfig.feeds.drivers.msrc.whitelist",
    "anchoreEnterpriseFeeds.msrcDriverEnabled": "feeds.anchoreConfig.feeds.drivers.msrc.enabled",

    "anchoreEnterpriseFeeds.npmDriverEnabled": "feeds.anchoreConfig.feeds.drivers.npm.enabled",


    "anchoreEnterpriseFeeds.persistence": "feeds.persistence",
    "anchoreEnterpriseFeeds.ubuntuExtraReleases": "feeds.anchoreConfig.feeds.drivers.ubuntu.releases",

    "anchoreEnterpriseFeedsUpgradeJob.enabled": "feeds.feedsUpgradeJob.enabled",
    "anchoreEnterpriseNotifications.cycleTimers": "anchoreConfig.notifications.cycle_timers",
    "anchoreEnterpriseReports.cycleTimers": "anchoreConfig.reports_worker.cycle_timers",
    "anchoreEnterpriseUi.appDBConfig": "anchoreConfig.ui.appdb_config",
    "anchoreEnterpriseUi.authenticationLock": "anchoreConfig.ui.authentication_lock",
    "anchoreEnterpriseUi.existingSecretName": "ui.existingSecretName",
    "anchoreEnterpriseUi.image": "ui.image",
    "anchoreEnterpriseUi.imagePullPolicy": "ui.imagePullPolicy",
    "anchoreEnterpriseUi.ldapsRootCaCertName": "ui.ldapsRootCaCertName",
    "anchoreGlobal.dbConfig": "anchoreConfig.database",
    "anchoreGlobal.internalServicesSsl": "anchoreConfig.internalServicesSSL",
    "anchoreGlobal.policyBundles": "anchoreConfig.policyBundles",
    "anchoreGlobal.webhooks": "anchoreConfig.webhooks",
    "anchorePolicyEngine.cycleTimers": "anchoreConfig.policy_engine.cycle_timers",
    "anchorePolicyEngine.overrideFeedsToUpstream": "anchoreConfig.policy_engine.overrideFeedsToUpstream",

    "postgresql.externalEndpoint": "postgresql.externalEndpoint",
    "postgresql.persistence": "postgresql.primary.persistence",
    "postgresql.extraEnv": "postgresql.primary.extraEnvVars",
    "anchore-feeds-db.extraEnv": "feeds.feeds-db.primary.extraEnvVars",
    "anchore-feeds-gem-db.extraEnv": "feeds.gem-db.primary.extraEnvVars",

    "anchore-feeds-gem-db.persistence": "feeds.gem-db.primary.persistence",
    "anchore-feeds-db.persistence": "feeds.feeds-db.primary.persistence",

    "anchoreEnterpriseRbac.managerResources": "rbacManager.resources",
}

LEVEL_THREE_CHANGE_KEY_MAPPING = {
    "anchore-feeds-db.persistence.resourcePolicy": "feeds.feeds-db.primary.persistence.resourcePolicy",
    "anchore-feeds-db.persistence.size": "feeds.feeds-db.primary.persistence.size",
    "anchoreAnalyzer.cycleTimers.image_analyzer": "anchoreConfig.analyzer.cycle_timers.image_analyzer",
    "anchoreGlobal.saml.secret": "anchoreConfig.keys.secret",
}

# We need to go all the way down to the value. Replace the whole original key
FULL_CHANGE_KEY_MAPPING = {
    "fullnameOverride": "global.fullnameOverride",
    "nameOverride": "global.nameOverride",
    "postgresql.enabled": "postgresql.chartEnabled",
    "postgresql.postgresDatabase": "postgresql.auth.database",
    "postgresql.postgresPassword": "postgresql.auth.password",
    "postgresql.postgresUser": "postgresql.auth.username",
    "postgresql.postgresPort": "postgresql.primary.service.ports.postgresql",
    "postgresql.imageTag": "postgresql.image.tag",

    "anchore-feeds-db.imageTag": "feeds.feeds-db.image.tag",
    "anchore-feeds-gem-db.imageTag": "feeds.gem-db.image.tag",
    "anchore-feeds-db.enabled": "feeds.feeds-db.chartEnabled",

    "anchore-feeds-db.postgresDatabase": "feeds.feeds-db.auth.database",
    "anchore-feeds-db.postgresPassword": "feeds.feeds-db.auth.password",
    "anchore-feeds-db.postgresPort": "feeds.feeds-db.primary.service.ports.postgresql",
    "anchore-feeds-db.postgresUser": "feeds.feeds-db.auth.username",

    "anchore-feeds-gem-db.enabled": "feeds.gem-db.chartEnabled",
    "anchore-feeds-gem-db.externalEndpoint": "feeds.gem-db.externalEndpoint",


    "anchore-feeds-gem-db.postgresDatabase": "feeds.gem-db.auth.database",
    "anchore-feeds-gem-db.postgresPassword": "feeds.gem-db.auth.password",
    "anchore-feeds-gem-db.postgresPort": "feeds.gem-db.primary.service.ports.postgresql",
    "anchore-feeds-gem-db.postgresUser": "feeds.gem-db.auth.username",


    "anchoreAnalyzer.containerPort": "analyzer.service.port",
    "anchoreAnalyzer.enableHints": "anchoreConfig.analyzer.enable_hints",

    "anchoreAnalyzer.layerCacheMaxGigabytes": "anchoreConfig.analyzer.layer_cache_max_gigabytes",
    "anchoreApi.external.use_tls": "anchoreConfig.apiext.external.useTLS",
    "anchoreCatalog.downAnalyzerTaskRequeue": "anchoreConfig.catalog.down_analyzer_task_requeue",
    "anchoreCatalog.runtimeInventory.imageTTLDays": "anchoreConfig.catalog.runtime_inventory.image_ttl_days",
    "anchoreEnterpriseFeeds.enabled": "feeds.chartEnabled",
    "anchoreEnterpriseFeeds.nvdDriverApiKey": "feeds.anchoreConfig.feeds.drivers.nvdv2.api_key",
    "anchoreEnterpriseNotifications.uiUrl": "anchoreConfig.notifications.ui_url",

    "anchoreEnterpriseRbac.service.managerPort": "rbacManager.service.port",
    "anchoreEnterpriseRbac.service.type": "rbacManager.service.type",


    "anchoreEnterpriseReports.dataEgressWindow": "anchoreConfig.reports_worker.data_egress_window",
    "anchoreEnterpriseReports.dataLoadMaxWorkers": "anchoreConfig.reports_worker.data_load_max_workers",
    "anchoreEnterpriseReports.dataRefreshMaxWorkers": "anchoreConfig.reports_worker.data_refresh_max_workers",
    "anchoreEnterpriseReports.enableDataEgress": "anchoreConfig.reports_worker.enable_data_egress",
    "anchoreEnterpriseReports.enableDataIngress": "anchoreConfig.reports_worker.enable_data_ingress",
    "anchoreEnterpriseReports.enableGraphiql": "anchoreConfig.reports.enable_graphiql",
    "anchoreEnterpriseReports.service.apiPort": "reports.service.port",
    "anchoreEnterpriseUi.enableProxy": "anchoreConfig.ui.enable_proxy",
    "anchoreEnterpriseUi.enableSharedLogin": "anchoreConfig.ui.enable_shared_login",
    "anchoreEnterpriseUi.enableSsl": "anchoreConfig.ui.enable_ssl",
    "anchoreEnterpriseUi.enrichInventoryView": "anchoreConfig.ui.enrich_inventory_view",
    "anchoreEnterpriseUi.forceWebsocket": "anchoreConfig.ui.force_websocket",
    "anchoreEnterpriseUi.logLevel": "anchoreConfig.ui.log_level",
    "anchoreEnterpriseUi.dbUser": "ui.dbUser",
    "anchoreEnterpriseUi.dbPass": "ui.dbPass",
    "anchoreEnterpriseUi.redisHost": "anchoreConfig.ui.redis_host",
    "anchoreEnterpriseUi.redisFlushdb": "anchoreConfig.ui.redis_flushdb",
    "anchoreGlobal.dbConfig.connectionPoolMaxOverflow": "anchoreConfig.database.db_pool_max_overflow",
    "anchoreGlobal.dbConfig.connectionPoolSize": "anchoreConfig.database.db_pool_size",
    "anchoreGlobal.dbConfig.sslRootCertName": "anchoreConfig.database.sslRootCertFileName",
    "anchoreGlobal.defaultAdminEmail": "anchoreConfig.default_admin_email",
    "anchoreGlobal.defaultAdminPassword": "anchoreConfig.default_admin_password",
    "anchoreGlobal.enableMetrics": "anchoreConfig.metrics.enabled",
    "anchoreGlobal.hashedPasswords": "anchoreConfig.user_authentication.hashed_passwords",
    "anchoreGlobal.internalServicesSsl.certSecretCertName": "anchoreConfig.internalServicesSSL.certSecretCertFileName",
    "anchoreGlobal.internalServicesSsl.certSecretKeyName": "anchoreConfig.internalServicesSSL.certSecretKeyFileName",
    "anchoreGlobal.logLevel": "anchoreConfig.log_level",
    "anchoreGlobal.metricsAuthDisabled": "anchoreConfig.metrics.auth_disabled",
    "anchoreGlobal.oauthEnabled": "anchoreConfig.user_authentication.oauth.enabled",
    "anchoreGlobal.oauthRefreshTokenExpirationSeconds": "anchoreConfig.user_authentication.oauth.refresh_token_expiration_seconds",
    "anchoreGlobal.oauthTokenExpirationSeconds": "anchoreConfig.user_authentication.oauth.default_token_expiration_seconds",
    "anchoreGlobal.saml.privateKeyName": "anchoreConfig.keys.privateKeyFileName",
    "anchoreGlobal.saml.publicKeyName": "anchoreConfig.keys.publicKeyFileName",
    "anchoreGlobal.serviceDir": "anchoreConfig.service_dir",
    "anchoreGlobal.ssoRequireExistingUsers": "anchoreConfig.user_authentication.sso_require_existing_users",
    "cloudsql.image.pullPolicy": "cloudsql.imagePullPolicy",
    "inject_secrets_via_env": "injectSecretsViaEnv",


    "ui-redis.enabled": "ui-redis.chartEnabled",
    "anchoreGlobal.allowECRUseIAMRole": "anchoreConfig.allow_awsecr_iam_auto",
}

#### ENGINE TO ENTERPRISE FOR KEYS THAT ARE NOW ENV VARS ####
ENTERPRISE_ENV_VAR_MAPPING = {
    "anchoreAnalyzer.maxRequestThreads": "analyzer.ANCHORE_MAX_REQUEST_THREADS",
    "anchoreAnalyzer.enableOwnedPackageFiltering": "analyzer.ANCHORE_OWNED_PACKAGE_FILTERING_ENABLED",
    "anchoreApi.maxRequestThreads": "api.ANCHORE_MAX_REQUEST_THREADS",
    "anchoreCatalog.maxRequestThreads": "catalog.ANCHORE_MAX_REQUEST_THREADS",
    "anchoreCatalog.imageGCMaxWorkerThreads": "catalog.ANCHORE_CATALOG_IMAGE_GC_WORKERS",

    "anchoreEnterpriseNotifications.maxRequestThreads": "notifications.ANCHORE_MAX_REQUEST_THREADS",
    "anchoreEnterpriseReports.maxRequestThreads": "reports.ANCHORE_MAX_REQUEST_THREADS",

    "anchoreGlobal.clientConnectTimeout": "ANCHORE_GLOBAL_CLIENT_CONNECT_TIMEOUT",
    "anchoreGlobal.clientReadTimeout": "ANCHORE_GLOBAL_CLIENT_READ_TIMEOUT",
    "anchoreGlobal.maxCompressedImageSizeMB": "ANCHORE_MAX_COMPRESSED_IMAGE_SIZE_MB",
    "anchoreGlobal.serverRequestTimeout": "ANCHORE_GLOBAL_SERVER_REQUEST_TIMEOUT_SEC",
    "anchoreGlobal.syncGithub": "ANCHORE_FEEDS_GITHUB_ENABLED",
    "anchoreGlobal.syncPackages": "ANCHORE_FEEDS_PACKAGES_ENABLED",
    "anchoreGlobal.syncVulnerabilites": "ANCHORE_FEEDS_VULNERABILITIES_ENABLED",
    "anchoreGlobal.syncNvd": "ANCHORE_FEEDS_DRIVER_NVDV2_ENABLED",
    "anchoreGlobal.imageAnalyzeTimeoutSeconds": "ANCHORE_IMAGE_ANALYZE_TIMEOUT_SECONDS",

    "anchorePolicyEngine.cacheTTL": "policyEngine.ANCHORE_POLICY_EVAL_CACHE_TTL_SECONDS",
    "anchorePolicyEngine.enablePackageDbLoad": "policyEngine.ANCHORE_POLICY_ENGINE_ENABLE_PACKAGE_DB_LOAD",
    "anchorePolicyEngine.maxRequestThreads": "policyEngine.ANCHORE_MAX_REQUEST_THREADS",
    "anchoreSimpleQueue.maxRequestThreads": "simpleQueue.ANCHORE_MAX_REQUEST_THREADS",
    "anchoreEnterpriseReports.vulnerabilitiesByK8sNamespace": "ANCHORE_ENTERPRISE_REPORTS_VULNERABILITIES_BY_K8S_NAMESPACE",
    "anchoreEnterpriseReports.vulnerabilitiesByK8sContainer": "ANCHORE_ENTERPRISE_REPORTS_VULNERABILITIES_BY_K8S_CONTAINER",
    "anchoreEnterpriseReports.vulnerabilitiesByEcsContainer": "ANCHORE_ENTERPRISE_REPORTS_VULNERABILITIES_BY_ECS_CONTAINER"
}

#### ENGINE TO FEEDS KEYS THAT ARE NOW ENV VARS ####
FEEDS_ENV_VAR_MAPPING = {

    "anchoreEnterpriseFeeds.alpineDriverEnabled": "feeds.ANCHORE_FEEDS_DRIVER_ALPINE_ENABLED",
    "anchoreEnterpriseFeeds.amazonDriverEnabled": "feeds.ANCHORE_FEEDS_DRIVER_AMAZON_ENABLED",
    "anchoreEnterpriseFeeds.anchoreMatchExclusionsEnabled": "feeds.ANCHORE_FEEDS_DRIVER_MATCH_EXCLUSIONS",
    "anchoreEnterpriseFeeds.apiOnly": "feeds.ANCHORE_FEEDS_API_ONLY",
    "anchoreEnterpriseFeeds.chainguardDriverEnabled": "feeds.ANCHORE_FEEDS_DRIVER_CHAINGUARD_ENABLED",
    "anchoreEnterpriseFeeds.debianDriverEnabled": "feeds.ANCHORE_FEEDS_DRIVER_DEBIAN_ENABLED",
    "anchoreEnterpriseFeeds.grypeDriverEnabled": "feeds.ANCHORE_FEEDS_DRIVER_GRYPEDB_ENABLED",
    "anchoreEnterpriseFeeds.grypedbPersistProviderWorkspaces": "feeds.ANCHORE_FEEDS_GRYPEDB_PERSIST_WORKSPACE",
    "anchoreEnterpriseFeeds.grypedbPreloadEnabled": "feeds.ANCHORE_FEEDS_GRYPEDB_PRELOAD_ENABLED",
    "anchoreEnterpriseFeeds.grypedbPreloadWorkspaceArchivePath": "feeds.ANCHORE_FEEDS_GRYPEDB_PRELOAD_PATH",
    "anchoreEnterpriseFeeds.grypedbRestoreProviderWorkspaces": "feeds.ANCHORE_FEEDS_GRYPEDB_RESTORE_WORKSPACE",
    "anchoreEnterpriseFeeds.maxRequestThreads": "feeds.ANCHORE_MAX_REQUEST_THREADS",

    "anchoreEnterpriseFeeds.olDriverEnabled": "feeds.ANCHORE_FEEDS_DRIVER_OL_ENABLED",
    "anchoreEnterpriseFeeds.rhelDriverConcurrency": "feeds.ANCHORE_FEEDS_DRIVER_RHEL_CONCURRENCY",
    "anchoreEnterpriseFeeds.rhelDriverEnabled": "feeds.ANCHORE_FEEDS_DRIVER_RHEL_ENABLED",
    "anchoreEnterpriseFeeds.slesDriverEnabled": "feeds.ANCHORE_FEEDS_DRIVER_SLES_ENABLED",
    "anchoreEnterpriseFeeds.ubuntuDriverEnabled": "feeds.ANCHORE_FEEDS_DRIVER_UBUNTU_ENABLED",
    "anchoreEnterpriseFeeds.ubuntuDriverGitBranch": "feeds.ANCHORE_FEEDS_DRIVER_UBUNTU_BRANCH",
    "anchoreEnterpriseFeeds.ubuntuDriverGitUrl": "feeds.ANCHORE_FEEDS_DRIVER_UBUNTU_URL",
    "anchoreEnterpriseFeeds.wolfiDriverEnabled": "feeds.ANCHORE_FEEDS_DRIVER_WOLFI_ENABLED",
    "anchoreEnterpriseFeeds.nvdv2DriverEnabled": "feeds.ANCHORE_FEEDS_DRIVER_NVDV2_ENABLED",
}

#### VALUES THAT ARE NO LONGER PART OF THE NEW CHART ####
DEPRECATED_KEYS = {

    "anchoreEngineUpgradeJob": "deprecated",

    "anchoreEnterpriseFeeds.nvdDriverEnabled": "deprecated",
    "anchoreEnterpriseFeeds.useNvdDriverApiKey": "deprecated",

    "anchoreEnterpriseGlobal.enabled": "deprecated",
    "anchoreEnterpriseNotifications.enabled": "deprecated",
    "anchoreEnterpriseRbac.enabled": "deprecated",
    "anchoreEnterpriseRbac.service.authPort": "8089",
    "anchoreEnterpriseReports.enabled": "deprecated",
    "anchoreEnterpriseUi.enabled": "deprecated",
    "anchoreGlobal.feedsConnectionTimeout": "3",
    "anchoreGlobal.feedsReadTimeout": "60",
    "anchoreGlobal.image": "deprecated",

    "anchoreGlobal.imagePullPolicy": "deprecated",
    "anchoreGlobal.imagePullSecretName": "deprecated",
    "anchoreGlobal.syncGrypeDB": "true",
    "anchoreGlobal.webhooksEnabled": "deprecated",
    "postgresql.persistence.resourcePolicy": "deprecated",
    "anchoreGlobal.saml.useExistingSecret": "deprecated",
    "anchoreEnterpriseReports.service.workerPort": "deprecated",
    "anchoreAnalyzer.concurrentTasksPerWorker": "deprecated",
}

POST_PROCESSING = {
    "postgresql.image": {
        "action": "split_value",
        "split_on": ":",
        "new_keys": ("postgresql.image.repository", "postgresql.image.tag")
    },
    "anchore-feeds-db.image": {
        "action": "split_value",
        "split_on": ":",
        "new_keys": ("feeds.feeds-db.image.repository", "feeds.feeds-db.image.tag")
    },
    "anchore-feeds-gem-db.image": {
        "action": "split_value",
        "split_on": ":",
        "new_keys": ("feeds.gem-db.image.repository", "feeds.gem-db.image.tag")
    },
    "cloudsql.image.repository": {
        "action": "merge",
        "merge_keys": ("cloudsql.image.repository", "cloudsql.image.tag"),
        "new_key": "cloudsql.image"
    },
    "cloudsql.image.tag": {
        "action": "merge",
        "merge_keys": ("cloudsql.image.repository", "cloudsql.image.tag"),
        "new_key": "cloudsql.image"
    },
    "anchoreEnterpriseRbac.extraEnv": {
        "action": "duplicate",
        "new_keys": ["rbacManager.extraEnv"]
    },
    "anchoreEnterpriseGlobal.imagePullSecretName": {
        "action": "duplicate",
        "new_keys": ["imagePullSecretName", "feeds.imagePullSecretName"]
    },
    "anchoreEnterpriseFeeds.existingSecretName": {
        "action": "key_addition",
        "new_keys": [("feeds.existingSecretName", "default"), ("feeds.useExistingSecrets", True)]
    }
}
