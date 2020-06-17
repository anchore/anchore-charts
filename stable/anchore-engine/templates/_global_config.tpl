{{- define "anchore-engine.globalConfig" -}}
    # Anchore Global Configuration
    service_dir: {{ .Values.anchoreGlobal.serviceDir }}
    tmp_dir: {{ .Values.anchoreGlobal.scratchVolume.mountPath }}
    log_level: {{ .Values.anchoreGlobal.logLevel }}
    image_analyze_timeout_seconds: {{ .Values.anchoreGlobal.imageAnalyzeTimeoutSeconds }}
    cleanup_images: {{ .Values.anchoreGlobal.cleanupImages }}
    allow_awsecr_iam_auto: {{ .Values.anchoreGlobal.allowECRUseIAMRole }}
    host_id: "${ANCHORE_POD_NAME}"
    internal_ssl_verify: {{ .Values.anchoreGlobal.internalServicesSsl.verifyCerts }}
    auto_restart_services: false
  
    global_client_connect_timeout: {{ default 0 .Values.anchoreGlobal.clientConnectTimeout }}
    global_client_read_timeout: {{ default 0 .Values.anchoreGlobal.clientReadTimeout }}
  
    metrics:
      enabled: {{ .Values.anchoreGlobal.enableMetrics }}
      auth_disabled: {{ .Values.anchoreGlobal.metricsAuthDisabled }}
    {{ if .Values.anchoreGlobal.webhooksEnabled }}
    webhooks:
      {{- toYaml .Values.anchoreGlobal.webhooks | nindent 6 }}
    {{ end }}
    # Configure what feeds to sync.
    # The sync will hit http://ancho.re/feeds, if any outbound firewall config needs to be set in your environment.
    feeds:
      sync_enabled: true
      selective_sync:
        # If enabled only sync specific feeds instead of all that are found.
        enabled: true
        feeds:
          github: {{ default "true" .Values.anchoreGlobal.syncGithub }}
          # Vulnerabilities feed is the feed for distro cve sources (redhat, debian, ubuntu, oracle, alpine....)
          vulnerabilities: {{ default "true" .Values.anchoreGlobal.syncVulnerabilites }}
          # NVD Data is used for non-distro CVEs (jars, npm, etc) that are not packaged and released by distros as rpms, debs, etc
          nvdv2: {{ default "true" .Values.anchoreGlobal.syncNvd }}
          # Warning: enabling the package sync causes the service to require much
          #   more memory to do process the significant data volume. We recommend at least 4GB available for the container
          packages: {{ default "false" .Values.anchoreGlobal.syncPackages }}
          vulndb: false
          microsoft: false
          # Sync github data if available for GHSA matches
          github: {{ default "true" .Values.anchoreGlobal.syncGithub }}
      client_url: "https://ancho.re/v1/account/users"
      token_url: "https://ancho.re/oauth/token"
      anonymous_user_username: anon@ancho.re
      anonymous_user_password: pbiU2RYZ2XrmYQ
      connection_timeout_seconds: {{ default 3 .Values.anchoreGlobal.feedsConnectionTimeout }}
      read_timeout_seconds: {{ default 180 .Values.anchoreGlobal.feedsReadTimeout }}
    default_admin_password: ${ANCHORE_ADMIN_PASSWORD}
    default_admin_email: {{ .Values.anchoreGlobal.defaultAdminEmail }}
  
    # Locations for keys used for signing and encryption. Only one of 'secret' or 'public_key_path'/'private_key_path' needs to be set. If all are set then the keys take precedence over the secret value
    # Secret is for a shared secret and if set, all components in anchore should have the exact same value in their configs.
    keys:
      secret: {{ .Values.anchoreGlobal.saml.secret }}
      {{- with .Values.anchoreGlobal.saml.publicKeyName }}
      public_key_path: /home/anchore/certs/{{- . }}
      {{- end }}
      {{- with .Values.anchoreGlobal.saml.privateKeyName }}
      private_key_path: /home/anchore/certs/{{- . }}
      {{- end }}
    # Configuring supported user authentication and credential management
    user_authentication:
      oauth:
        enabled: {{ .Values.anchoreGlobal.oauthEnabled }}
        default_token_expiration_seconds: {{ .Values.anchoreGlobal.oauthTokenExpirationSeconds }}
      # Set this to True to enable storing user passwords only as secure hashes in the db. This can dramatically increase CPU usage if you
      # don't also use oauth and tokens for internal communications (which requires keys/secret to be configured as well)
      # WARNING: you should not change this after a system has been initialized as it may cause a mismatch in existing passwords
      hashed_passwords: {{ .Values.anchoreGlobal.hashedPasswords }}
    credentials:
      database:
        {{- if .Values.anchoreGlobal.dbConfig.ssl }}
        db_connect: "postgresql://${ANCHORE_DB_USER}:${ANCHORE_DB_PASSWORD}@${ANCHORE_DB_HOST}/${ANCHORE_DB_NAME}?sslmode={{- .Values.anchoreGlobal.dbConfig.sslMode -}}&sslrootcert=/home/anchore/certs/{{- .Values.anchoreGlobal.dbConfig.sslRootCertName -}}"
        {{- else }}
        db_connect: "postgresql://${ANCHORE_DB_USER}:${ANCHORE_DB_PASSWORD}@${ANCHORE_DB_HOST}/${ANCHORE_DB_NAME}"
        {{- end }}
        db_connect_args:
          timeout: {{ .Values.anchoreGlobal.dbConfig.timeout }}
          ssl: false
        db_pool_size: {{ .Values.anchoreGlobal.dbConfig.connectionPoolSize }}
        db_pool_max_overflow: {{ .Values.anchoreGlobal.dbConfig.connectionPoolMaxOverflow }}
    # End Anchore Global Configuration
{{- end -}}