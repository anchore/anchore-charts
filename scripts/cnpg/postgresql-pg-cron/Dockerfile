ARG PG_VERSION=17
FROM ghcr.io/cloudnative-pg/postgresql:${PG_VERSION}-bookworm

USER root
RUN apt-get update && \
    apt-get install -y --no-install-recommends "postgresql-${PG_MAJOR}-cron" && \
    apt-get purge -y --auto-remove -o APT::AutoRemove::RecommendsImportant=false && \
    rm -rf /var/lib/apt/lists/*
USER 26
