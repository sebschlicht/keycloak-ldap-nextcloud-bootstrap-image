#!/bin/bash

keycloak_endpoint="$KEYCLOAK_PROTOCOL://$KEYCLOAK_HOST:$KEYCLOAK_PORT"
echo "$keycloak_endpoint"

load_x509_certificates () {
    local certificate_folder="$1"

    local nextcloud_certificate_file="$certificate_folder/nextcloud.cert"
    if [ -r "$nextcloud_certificate_file" ]; then
        local client_certificate
        client_certificate="$( tail -n +2 "$nextcloud_certificate_file" | head -n -1 | tr -d '\n' )"

        export NEXTCLOUD_CLIENT_CERTIFICATE="$client_certificate"
    else
        echo "Failed to load X.509 certificate from file '$nextcloud_certificate_file'!"
        return 1
    fi
}

template_file () {
    local source="$1"
    local target="$2"

    envsubst '${LDAP_HOST},${LDAP_BIND_DN},${LDAP_BIND_CREDENTIALS},${LDAP_USERS_DN},${KEYCLOAK_PROTOCOL},${KEYCLOAK_HOST},${KEYCLOAK_PORT},${KEYCLOAK_REALM},${NEXTCLOUD_PROTOCOL},${NEXTCLOUD_HOST},${NEXTCLOUD_PORT}' < "$source" > "$target"
}

extract_realm_name () {
    local realm_file="$1"
    jq -r .realm < "$realm_file"
}

extract_user_federation_id () {
    local realm_file="$1"
    local user_federation_name="$2"

    jq -r ".components[\"org.keycloak.storage.UserStorageProvider\"][] | select(.name == \"$user_federation_name\") | .id" < "$realm_file"
}

get_access_token () {
    local keycloak_token_url="$keycloak_endpoint/auth/realms/master/protocol/openid-connect/token"

    local http_response
    http_response="$( curl -s -X POST "$keycloak_token_url" --data-urlencode "grant_type=password" --data-urlencode "client_id=admin-cli" --data-urlencode "username=$KEYCLOAK_USERNAME" --data-urlencode "password=$KEYCLOAK_PASSWORD" )"
    echo "$http_response" | jq -r .access_token
}

remove_realm () {
  local token="$1"
  local realm="$2"

  local http_response
  http_response="$( curl -s -X DELETE -H "Authorization: bearer $token" "$keycloak_endpoint/auth/admin/realms/$realm" )"

  if [ -n "$http_response" ]; then
    echo "$http_response"
  fi
}

import_realm () {
    local token="$1"
    local realm_file="$2"

    # WARN won't accept any credentials ???
    curl -s -H "Authorization: bearer $token" -H 'Content-Type: application/json' "$keycloak_endpoint/auth/admin/realms" --data "@$realm_file"
}

sync_all_ldap_users () {
    local token="$1"
    local realm_file="$2"

    local ldap_client_id
    ldap_client_id="$( extract_user_federation_id "$realm_file" 'ldap' )"

    local keycloak_sync_url="$keycloak_endpoint/auth/admin/realms/$realm/user-storage/$ldap_client_id/sync?action=triggerFullSync"
    local http_response
    http_response="$( curl -s -X POST -H "Authorization: bearer $token" "$keycloak_sync_url" )"
    echo "user synchronization: $http_response" >&1

    return "$( echo "$http_response" | jq -r .failed )"
}

# template realm
realm_file_template=realm.tpl.json
realm_file=realm.json
if ! load_x509_certificates "/certificates"; then
    exit 1
fi
template_file "$realm_file_template" "$realm_file"
realm="$( extract_realm_name "$realm_file" )"

# import realm and sync users
access_token="$( get_access_token )"
echo 'removing existing realm (ignore warnings, if realm not existing)'
remove_realm "$access_token" "$realm"
echo 'importing templated realm'
import_realm "$access_token" "$realm_file"
echo 'syncing LDAP users'
sync_all_ldap_users "$access_token" "$realm_file"
