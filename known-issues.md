# Known issues

This document helps with troubleshooting and provides an introduction to the most requested features, gotchas, and questions.

* Follow the following steps if you need to restart the deployment process.

    1. Delete azure resource group and app registration by following the steps in the `Teardown` section in [README.md](./README.md).
    1. Delete the Terraform files (lock, plan, and state)

        ```shell
        rm -rf terraform/.terraform*
        rm -rf terraform/terraform.tfstate*
        rm terraform/proseware.tfplan
        ```

    1. Use source control to revert change to pom.xml as needed

        ```shell
        git checkout src/airsonic-advanced/airsonic-main/pom.xml
        ```

    1. Retry from setup-initial-env step in [README.md](./README.md).  Enter a new name in the script for APP_NAME

* Login with OAuth 2.0 Invalid credentials

    ![Aisonic AAD](docs/assets/azureauthtimeout.png)

    Refresh the browser to recover from the above error.

* Some of the videos may not play correctly.  Skip the video and choose a different one to play.

    ![Aisonic Video Playing Error](docs/assets/error-playing-video.png)

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

* Access to the Azure Redis Cache console error

    You can launch the console for Azure Redis Cache through the Azure Portal.

    ![Aisonic AAD](docs/assets/azure-redis-console.png)

    You may encounter the following errors when issuing Redis commands.

    ![Aisonic AAD](docs/assets/azure-redis-private-console-error.png)

    Enable *public network access* to use the console.

    ![Aisonic AAD](docs/assets/azure-redis-enable-public-network-access.png)
