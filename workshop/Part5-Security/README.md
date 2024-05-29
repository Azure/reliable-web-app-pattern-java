## Introduction to Managed Identity and Security Practices

For enhancing security within Azure-based applications, it is crucial to use managed identities for intra-service communication. Managed identities eliminate the need for developers to manage credentials explicitly, reducing the risk of credential leaks. If a component does not support managed identities, alternative mechanisms such as certificates or passwords should be employed. However, it is paramount to store these credentials securely in Azure Key Vault and regularly rotate them to maintain security integrity.

This section provides a fundamental understanding of why managed identities and these secure practices are essential for protecting your applications and data.


In Part 0, there was no security framework. This section focuses on how to secure our reference example by implementing comprehensive role-based access control and utilizing Azure Web Application Firewall to protect against a wider array of threats.
The Reliable Web App pattern uses managed identities to implement identity-centric security. Private endpoints, web application firewall, and restricted access to the web app provide a secure ingress.

## RBAC (role-based access control)

The web app also includes a role-based access control (RBAC) feature. The Contoso Fiber team uses Microsoft Entra ID for authentication. Contoso Fiber chose Microsoft Entra ID for the following reasons:

- Authentication and authorization. It handles authentication and authorization of employees.
- Scalability. It scales to support larger scenarios.
- User-identity control. Employees can use their existing enterprise identities.
- Support for authorization protocols. It supports OAuth 2.0 for managed identities.

This system has an "Account Manager" role and a "Field Service" role. The "Account Manager" role has access to create new Accounts.

![image of Microsoft Entra ID Enterprise Applications Role Assignment](images/contoso-fiber-app-role-assignment.png)

## WAF (Web Application Firewall)

Azure Web Application Firewall (WAF) is Azure's web application firewall and provides centralized protection of from common web exploits and vulnerabilities.

Contoso Fiber chose the Web Application Firewall for the following benefits:

- Global protection. It provides increased global web app protection without sacrificing performance.
- Botnet protection. You can configure bot protection rules to monitor for botnet attacks.
- Parity with on-premises. The on-premises solution was running behind a web application firewall managed by IT.

## Secrets manager

Contoso Fiber has secrets to manage. They used Key Vault for the following reasons:

- Encryption. It supports encryption at rest and in transit.
- Supports managed identities. The application services can use managed identities to access the secret store.
- Monitoring and logging. It facilitates audit access and generates alerts when stored secrets change.
- Integration. It supports two methods for the web app to access secrets. Contoso Fiber can use app settings in the hosting platform (App Service), or they can reference the secret in their application code (app properties file).

## Azure Private link

Azure Private Link provides access to platform-as-a-service solutions over a private endpoint in your virtual network. Traffic between your virtual network and the service travels across the Microsoft backbone network.

Contoso Fiber chose Private Link for the following reasons:

- Enhanced security. It lets the application privately access services on Azure and reduces the network footprint of data stores to help protect against data leakage.
- Minimal effort. Private endpoints support the web app platform and the database platform that the web app uses. Both platforms mirror the existing on-premises setup, so minimal changes are required.

## Exercise

The Contoso Fiber Customer Account Management System (CAMS) web application is used by the team to manage customer accounts and help them with support tickets related to their internet or cable services. To demo the full application, you can:

1. Click on the "Account" page in the left side menu
2. Click on the "Add Account" button in the list of accounts
3. Create an Account
4. On the "Account Details" page, click on the "New Support Case" button
5. Create a Support Case
6. On the "Account Details" page, click on the row of the support case to see the details
7. Click on the "Escalte to L2" button to escalate the support case
8. Click on the "Level 2" page in the left side menu to see the list of all escalated support cases

In the web app, the Contoso Fiber team uses this process, with the help of role based access, to address customer support issues in a timely manner.

## Next Up

Next, we will delve into operational excellence in cloud applications --> [Part 6 - Operational Excellence](../Part6-Operational-Excellence/README.md) 

## Resources
[Well-Architected Framework security portal](https://learn.microsoft.com/en-us/azure/well-architected/security)

[Security Checklist](https://learn.microsoft.com/azure/well-architected/security/checklist)
