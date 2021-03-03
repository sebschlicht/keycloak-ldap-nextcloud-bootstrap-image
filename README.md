# LDAP-Keycloak-Nextcloud Keycloak Boostrap Image

This Docker image allows to bootstrap the provisioning of Keycloak from file.

Its main purpose is to provide a starting point for connecting Nextcloud with LDAP, via Keycloak.

Thus, the bootstrapped realm features:

* an LDAP user federation, to make LDAP users accessible to services
* a Nextcloud client, to make these users accessible to Nextcloud

Basically, it templates the described realm with user-provided variables and imports it into a running Keycloak instance

## Prerequirements

* a basic understanding of the involved services and tools
* a running application stack (OpenLDAP, Keycloak), e.g. via Docker. see `examples/docker-compose.app.yml`
* existing LDAP users in an organizational unit. see `examples/ldap-users.ldif`

## Usage

Adapt the example file `examples/docker-compose.bootstrap.yml` to your needs.

The bootstrapping container and your Keycloak instance must be in the same Docker network.
Make sure to adapt `keycloak-services`, if you are not using the example application stack file.

Check [environment variables](#environment-variables) to see what you might want to change.

    docker-compose -f examples/docker-compose.bootstrap.yml run --rm keycloak-provisioning

## Keycloak Provisioning

Bootstrapping this realm simplifies the initial setup process but it is only one step towards fully automated provisioning from static files.

Please note that all examples files make assumptions that may not fit your use case.
Various environment variables and other lines will have to be adapted.

### Provision your Keycloak

1. use this image to bootstrap a Keycloak realm (see `examples/docker-compose.bootstrap.yml`)

       docker-compose -f docker-compose.bootstrap.yml run --rm keycloak-provisioning

2. login into Keycloak (example: http://localhost:8080)
3. make any changes that you'd like to persist, e.g.

   * enforce WebAuthn 2FA
   * add clients to connect more services to Keycloak/LDAP

4. stop your existing Keycloak instance and create the provisioning folder

       docker stop keycloak
       mkdir keycloak-provisioning

5. perform a full export of your final realm, using the Keycloak binary. See `examples/docker-compose.export.yml`.

       docker-compose -f docker-compose.export.yml up | grep 'Export finished successfully'

   wait until the export is finished and then stop the container (Ctrl-C)

6. now you can provisiong your realm to any Keycloak instance, using the Keycloak binary. See `examples/docker-compose.provisioning.yml`.

       docker-compose -f docker-compose.provisioning.yml up -d

## Environment Variables

The following environment variables are used in this image to bootstrap the realm:

Name | Default Value | Description
---- | ------------- | -----------
LDAP_HOST             | openldap  | hostname / IP address of the LDAP machine
LDAP_BIND_DN          | -         | LDAP DN to bind Keycloak to
LDAP_BIND_CREDENTIALS | -         | password of the specified LDAP binding
LDAP_USERS_DN         | -         | LDAP DN of the organizational unit to import users from
KEYCLOAK_PROTOCOL     | http      | protocol for Keycloak URLs
KEYCLOAK_HOST         | keycloak  | hostname / IP address of the Keycloak machine
KEYCLOAK_PORT         | 8080      | port to reach Keycloak on the specified host
KEYCLOAK_USERNAME     | admin     | Keycloak user for the LDAP client
KEYCLOAK_PASSWORD     | -         | password of the specified Keycloak user
KEYCLOAK_REALM        | -         | name of the resulting realm
NEXTCLOUD_PROTOCOL    | https     | protocol for Nextcloud URLs
NEXTCLOUD_HOST        | nextcloud | hostname / IP address of the Nextcloud machine
NEXTCLOUD_PORT        | 443       | port to reach Nextcloud on the specified host

## Resources

* [HowTo: Setup Nextcloud SSO with Keycloak](https://stackoverflow.com/questions/48400812/sso-with-saml-keycloak-and-nextcloud)
* [Keycloak documentation: WebAuthn (2FA)](https://www.keycloak.org/docs/latest/server_admin/index.html#_webauthn)
* [Keycloak documentation: import/export](https://www.keycloak.org/docs/latest/server_admin/index.html#_export_import)
