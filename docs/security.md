# Security

Security design principles describe a securely architected system hosted on cloud or on-premises datacenters (or a combination of both). Application of these principles dramatically increases the likelihood your architecture assures confidentiality, integrity, and availability. These patterns are used by the Airsonic sample to improve security.

## Use Managed identity

Making the most of the Azure platform means leveraging multiple services and features. To do this, you will need to create secure connections between those resources. Connection strings are the most common example of creating secure connections.

For on-prem apps there were two popular choices for connection strings. Your connection string could specify a SQL user and password, or you could hide the password from the config file with the *Trusted connection* and *Integrated security* features.

These features enabled an app to connect to a SQL database with an Active Directory account. These were often referred to as service accounts because the service was the only one that should ever be able to login with the password.

In Azure we recommend using managed identity as a similar concept. Azure resources that support managed identity also provide client libraries to enable this feature.

There are a couple of ways to use managed identity. The guide [here](https://learn.microsoft.com/en-us/azure/developer/java/spring-framework/migrate-postgresql-to-passwordless-connection?tabs=sign-in-azure-cli%2Cjava%2Capp-service%2Cassign-role-service-connector) describes the steps used to migrate the Airsonic application to use passwordless connections.

Airsonic uses the Azure PostgreSQL authentication plugin in JDBC URL to indicate the use of passwordless connections. In the Airsonic sample the Azure PostgreSQL connection string is stored in the App Service Configuration, and not Key Vault, because there is no password (or secret). The following is an example connection string for Azure PostgreSQL.

```sh
app_settings = {
  DatabaseConfigEmbedDriver = "org.postgresql.Driver"
  DatabaseConfigEmbedUrl    = "jdbc:postgresql://${var.database_fqdn}:5432/${var.database_name}?stringtype=unspecified&authenticationPluginClassName=com.azure.identity.providers.postgresql.AzureIdentityPostgresqlAuthenticationPlugin"
}
```

<sup>[Link to app-service/main.tf](../terraform/modules/app-service/main.tf)</sup>

Note that in this sample, the *Authentication* section of the connection string is how we inform the Microsoft client library that we want to connect with managed identity.

There are no passwords in the terraform templates, the Java code, the config file, or the App Service configuration settings. Managed identities do not have passwords that can be leaked so you don't need to create a rotation strategy to ensure their integrity.

The terraform templates in this project handle the following tasks associated with using managed identity in a solution.

### TODO: Links to code

For more information, see:

- [Managed identity](https://learn.microsoft.com/en-us/azure/active-directory/managed-identities-azure-resources/overview)
- [Web app managed identity](https://learn.microsoft.com/en-us/azure/active-directory/develop/multi-service-web-app-access-storage?tabs=azure-portal%2Cprogramming-language-csharp#enable-managed-identity-on-an-app)
- [Azure services that can use managed identities to access other services](https://learn.microsoft.com/en-us/azure/active-directory/managed-identities-azure-resources/managed-identities-status)

## Use identity-based authentication

By default, Azure resources come with connection strings, and secret keys, but these connections are not identity based. This means they have two drawbacks over managed identity. First, they do not identify the resource that is connecting. When an app uses the secret key to connect you lose traceability to understand who is connecting and the context to understand why. Second, you lose the ability to govern what permissions should be applied to during a connection. Using managed identity enables you to understand who is connecting to your resources and it enables you to set permissions that govern the actions that can be performed.

<!-- source: https://learn.microsoft.com/en-us/azure/active-directory/managed-identities-azure-resources/managed-identity-best-practice-recommendations#follow-the-principle-of-least-privilege-when-granting-access-->

Governing the actions that can be performed is a key tenet of security. When granting access to a resource we recommend that you always grant the least permissions needed. Using extra permissions when not needed gives attackers more opportunity to compromise the confidentiality, integrity, or the availability of your solution. In the managed identity section above you can see how to do this with role assignments. 

> In this sample we grant the managed identity admin access to PostgreSQL because Airsonic uses [Liquibase](https://www.liquibase.org/) for databse migrations. If you choose another approach to managing your SQL schema you should reduce these permissions to read/write access.

## Secret management

In the managed identity section we showed that the Azure PostreSQL connection string is not a secret.

### Azure Key Vault

Protecting  secrets plays a critical role in ensuring the security of the solution.
Azure Key Vault is used to ensure secrets are stored securely with software encryption using industry-standard algorithms and key lengths.

<!-- source: https://learn.microsoft.com/en-us/azure/key-vault/general/overview -->
Access to key vault also requires proper authentication and authorization before a caller (user or application) can get access. Authentication establishes the identity of the caller, while authorization determines the operations that they are allowed to perform. Authentication is done via Azure Active Directory. Authorization may be done via Azure role-based access control (Azure RBAC) or Key Vault access policy. 

> For additional security Key Vault supports the ability to monitor access and use. This is not configured as part of this sample. You can learn more by reading
[Monitoring Azure Key Vault](https://learn.microsoft.com/en-us/azure/key-vault/general/monitor-key-vault)

The Airsonic does not use Azure Key Vault.  Key Vault is provisioned in our terraform templates to initially store the Azure PostgreSQL admin name and password.

#### Endpoint security

The Airsonic team also manages their security risk by applying networking constraints to their Azure resources. By default, Azure PostgreSQL and Azure App Service are all publicly accessible resources.

The team secures their data, their secrets, and ensures the integrity of the system by using Azure Private Endpoints and blocking public network access. Azure Private Link is a service that enables Azure resources to connect directly to an Azure Virtual Network where they receive a private IP address. Because these resources have private IP addresses the team can block all public internet connections.

Using this Virtual Network approach also enables the team to prepare for future network scenarios, including hybrid networking, if the web app needs to access on-prem resources.

> Read the [Best practices for endpoint security](https://docs.microsoft.com/azure/architecture/framework/security/design-network-endpoints)
> doc if you would like to learn more about how to secure traffic to and
> from your Azure resources

