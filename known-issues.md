# Known issues

This document helps with troubleshooting and provides an introduction to the most requested features, gotchas, and questions.

## Troubleshooting

* Follow the following steps if you need to restart the deployment process.

    1. Delete azure resource group and app registration by following the steps in the `Teardown` section in [README.md](./README.md).
    1. Delete the Terraform files (lock, plan, and state)

        ```shell
        rm -rf terraform/.terraform*
        rm -rf terraform/terraform.tfstate*
        rm terraform/airsonic.tfplan
        ```

    1. Use source control to revert change to pom.xml as needed

        ```shell
        git checkout src/airsonic-advanced/airsonic-main/pom.xml
        ```

    1. Retry from setup-initial-env step in [README.md](./README.md).  Enter a new name in the script for APP_NAME

* Login with OAuth 2.0 Invalid credentials

    ![Aisonic AAD](docs/assets/azureauthtimeout.png)

    Refresh the browser to recover from the above error.

* In some cases, the deployment of Redis Cache can take a long time.
    
    ```
    module.cache.azurerm_redis_cache.cache: Still creating... [18m10s elapsed]
    module.cache.azurerm_redis_cache.cache: Still creating... [18m20s elapsed]
    module.cache.azurerm_redis_cache.cache: Still creating... [18m30s elapsed]
    module.cache.azurerm_redis_cache.cache: Still creating... [18m40s elapsed]
    module.cache.azurerm_redis_cache.cache: Still creating... [18m50s elapsed]
    module.cache.azurerm_redis_cache.cache: Still creating... [19m0s elapsed]
    module.cache.azurerm_redis_cache.cache: Still creating... [19m10s elapsed]
    module.cache.azurerm_redis_cache.cache: Still creating... [19m20s elapsed]
    ````
