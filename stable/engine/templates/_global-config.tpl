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

    default_admin_password: ${ANCHORE_ADMIN_PASSWORD}
    default_admin_email: {{ .Values.anchoreGlobal.defaultAdminEmail }}

    # Locations for keys used for signing and encryption. Only one of 'secret' or 'public_key_path'/'private_key_path' needs to be set. If all are set then the keys take precedence over the secret value
    # Secret is for a shared secret and if set, all components in anchore should have the exact same value in their configs.
    keys:
    # Configuring supported user authentication and credential management
    user_authentication:
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
        {{- with .Values.anchoreGlobal.dbConfig.engineArgs }}
        db_engine_args:
          {{- toYaml . | nindent 10 }}
        {{- end }}
    # End Anchore Global Configuration
{{- end -}}
