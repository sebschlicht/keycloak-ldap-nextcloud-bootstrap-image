# Keycloak Bootstrap Image for LDAP-Keycloak-Nextcloud setup

This Docker image allows to bootstrap the provisioning of Keycloak from file.

Its main purpose is to provide a starting point for connecting Nextcloud with LDAP, via Keycloak, using SAML.

Thus, it bootstrapps a single realm into a running Keycloak instance that features:

* an LDAP user federation, to make LDAP users accessible to services
* a Nextcloud client, to make these users accessible to Nextcloud

When following this guide, you can learn how to permanently provision LDAP and Keycloak.

## Prerequisites

* basic understanding of the involved services and tools
* running application stack (LDAP, Keycloak, Nextcloud), e.g. via Docker. see `examples/docker-compose.app.yml`
* existing LDAP users in an organizational unit (provisioned when using `examples/docker-compose.app.yml`)

## Usage

Generate a new X.509 key pair for the Nextcloud SAML client:

    openssl req  -nodes -new -x509  -keyout private.key -out public.cert

Adapt the example file `examples/docker-compose.bootstrap.yml` to your needs.

>Note: The bootstrapping container and your Keycloak instance must be in the same Docker network.
If you are not using the example application stack file, make sure to adapt the external network name (`keycloak-services`).

Check [environment variables](#environment-variables) for descriptions and to see what you might want to add.

Once you are finished, bootstrap the realm by running

    docker-compose -f examples/docker-compose.bootstrap.yml run --rm keycloak-provisioning

While Keycloak is now ready to serve, you still have to configure Nextcloud to use Keycloak, using the key pair that you created in the first step.
Follow the instructions in the section `Configure Nextcloud` of [this excellent guide](https://stackoverflow.com/questions/48400812/sso-with-saml-keycloak-and-nextcloud) to see how.

## Keycloak Provisioning

Bootstrapping your realm simplifies the initial setup process but it is only one step towards fully automated provisioning from static files.

>Note: All examples files make assumptions that may not fit your use case.
Various environment variables and other lines will have to be adapted.

For a fully automated provisioning, perform the following steps:

1. use this image to bootstrap a Keycloak realm, as already shown (see `examples/docker-compose.bootstrap.yml`)

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

6. now you can always provisiong your entire realm to any Keycloak instance, using the Keycloak binary. See `examples/docker-compose.provisioning.yml`.

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

## LDAP Provisioning

LDAP is already provisioned in this example, using the Docker image's ability to bootstrap LDIF files from mounted volumes.
Make sure to keep the `--copy-service` flag or you will run into file permissions issues.

To create a valid provisioning file, export your DN to an LDIF file via *phpldapadmin* but remove the base DN entry (i.e. the first).

## Resources

* [HowTo: Setup Nextcloud SSO with Keycloak](https://stackoverflow.com/questions/48400812/sso-with-saml-keycloak-and-nextcloud)
* [Keycloak documentation: WebAuthn (2FA)](https://www.keycloak.org/docs/latest/server_admin/index.html#_webauthn)
* [Keycloak documentation: import/export](https://www.keycloak.org/docs/latest/server_admin/index.html#_export_import)
