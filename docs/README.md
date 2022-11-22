# Reliable Java Eeb Application

The architecture applies the principles of the [Well-Architected Framework](https://docs.microsoft.com/azure/architecture/framework/) and [Twelve-Factor Applications](https://12factor.net/) to migrate and modernize a legacy, line-of-business (LOB) web app to the cloud. The guide addresses the challenges in refactoring a monolithic Java application with a PostgreSQL database and developing a modern, reliable, and scalable Java application. 

This is a complete solution with deployable artifacts. The deployable artifacts create a modernized LOB web application that has improved reliability, security, performance, and more mature operational practices at a predictable cost. It provides a foundation upon which you can achieve longer-term objectives.

## Use Cases

This solution is ideal for organizations that have a cataloging application, but it can apply to other industries.

## Architecture

The diagram depicts the web application solution that you can deploy with the implementation guidance.

![Aisonic Azure architecture](assets/airsonic-azure-architecture.png)

## Azure Well-Architected Framework

The five pillars of the Azure Well-Architected Framework provide guiding tenets that improve the quality of cloud applications.  Refer to the links below to see how each of the pillars were incorporated into the solution.

- [Reliability](./reliability.md)
- [Security](./security.md)
- [Cost Optimization](./cost-optimization.md)
- [Operational Excellence](./operational-excellence.md)
- [Performance Efficiency](./performance-efficiency.md)

## Deploy the solution

This solution uses the Azure CLI and Terraform to set up Azure services and deploy the code. Follow the [Quick Start Guide](./quick-start-guide.md) to deploy the code to Azure.
