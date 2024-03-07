# Reliable web app pattern for Java

> :mega: **Got feedback?** Fill out [this survey](https://aka.ms/eap/rwa/java/survey) to help us shape the future of Enterprise App Patterns and understand whether we're focusing on the business goals and features important to you. [Microsoft Privacy Statement](https://go.microsoft.com/fwlink/?LinkId=521839)

The reference implementation provides a production-grade web application that uses best practices from our guidance and gives developers concrete examples to build their own Reliable Web Application in Azure. This repository specifically demonstrates a Customer Account Management System (CAMS) application for the fictional company Contoso Fiber, embodying the reliable web app pattern with a focus on Java technologies. It guides developers through a simulated migration from an on-premises web application to Azure, detailing the architectural changes and enhancements that capitalize on the cloud's strengths during the initial adoption phase. 

This project has a [a companion article in the Azure Architecture Center](https://aka.ms/eap/rwa/java/doc) that describes design patterns and best practices and [a six-part video series (YouTube)](https://aka.ms/eap/rwa/java/videos) that details the reliable web app pattern for Java web app. Here's an outline of the contents in this readme:

- [Architecture](#architecture)
- [Workflow](#workflow)
- [Steps to deploy the reference implementation](#steps-to-deploy-the-reference-implementation)
- [Additional links](#additional-links)
- [Data Collection](#data-collection)

## Architecture

Contoso Fiber aligned to a hub and spoke network topology in the production deployment architecture to centralize common resources. This network topology provided cost savings, enhanced security, and facilitated network integration (platform and hybrid):

![Architecture](./docs/icons/reliable-web-app-java.svg)

This diagram describes the production deployment which is described in the [prod-deployment.md](./prod-deployment.md) file. The following steps below are for a [development deployment](./docs/icoms/reliable-web-app-java-dev.svg) which is a simplified version.

## Steps to deploy the reference implementation

Clone the repository and open the project using the Dev Container.

```shell
git clone https://github.com/Azure/web-app-pattern-java.git

cd web-app-pattern-java
```

If you don't see the popup to *Reopen in Container*, open the Visual Studio Code Command Palette to execute the command. There are three ways to open the command palette:

- For Mac users, use the keyboard shortcut ⇧⌘P
- For Windows and Linux users, use Ctrl+Shift+P
- From the Visual Studio Code top menu, navigate to View -> Command Palette.


## Deployment Options

The Reliable Web App pattern for Java can be deployed using the following options:

- [Local Development](./local-development.md)
- [Dev deployment](./dev-deployment.md)
- [Production Deployment](./prod-deployment.md)

## Additional links

- [Known issues](known-issues.md)
- [Troubleshooting](troubleshooting.md)
- [Pattern Simulations](demo.md)
- [Developer Experience](developer-experience.md)
- [Calculating SLA](./assets/sla-calculation.md)
- [Logging](docs/logging.md)
- [Redis](docs/REDIS.md)
- [Report security concerns](SECURITY.md)
- [Find Support](SUPPORT.md)
- [Contributing](CONTRIBUTING.md)

## Trademarks

This project may contain trademarks or logos for projects, products, or services. Authorized use of Microsoft 
trademarks or logos is subject to and must follow 
[Microsoft's Trademark & Brand Guidelines](https://www.microsoft.com/en-us/legal/intellectualproperty/trademarks/usage/general).
Use of Microsoft trademarks or logos in modified versions of this project must not cause confusion or imply Microsoft sponsorship.
Any use of third-party trademarks or logos are subject to those third-party's policies.

## Data Collection

The software may collect information about you and your use of the software and send it to Microsoft. Microsoft may use this information to provide services and improve our products and services. You may turn off the telemetry as described in the repository. There are also some features in the software that may enable you and Microsoft to collect data from users of your applications. If you use these features, you must comply with applicable law, including providing appropriate notices to users of your applications together with a copy of Microsoft's privacy statement. Our privacy statement is located at https://go.microsoft.com/fwlink/?LinkId=521839. You can learn more about data collection and use in the help documentation and our privacy statement. Your use of the software operates as your consent to these practices.

### Telemetry Configuration

Telemetry collection is on by default.

To opt out, run the following command `azd env set ENABLE_TELEMETRY` to `false` in your AZD environment.