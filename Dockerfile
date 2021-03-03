FROM alpine:3.12

RUN apk add --no-cache \
    curl \
    gettext \
    jq

ENV LDAP_HOST="${LDAP_HOST:-openldap}" \
    KEYCLOAK_PROTOCOL="${KEYCLOAK_PROTOCOL:-http}" \
    KEYCLOAK_HOST="${KEYCLOAK_HOST:-keycloak}" \
    KEYCLOAK_PORT="${KEYCLOAK_PORT:-8080}" \
    KEYCLOAK_USERNAME="${KEYCLOAK_USERNAME:-admin}" \
    NEXTCLOUD_PROTOCOL="${NEXTCLOUD_PROTOCOL:-https}" \
    NEXTCLOUD_HOST="${NEXTCLOUD_HOST:-nextcloud}" \
    NEXTCLOUD_PORT="${NEXTCLOUD_PORT:-443}"

WORKDIR /app

COPY template-realm.sh realm.tpl.json ./

ENTRYPOINT [ "sh", "./template-realm.sh" ]
