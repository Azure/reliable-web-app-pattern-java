# Known Issues

## Error: updating Flexible Server

During a second run of `azd up` in a multi-region deployment, you may encounter an error like the following:

```
Error: updating Flexible Server (Subscription: "a1fe858c-e1c9-4131-8937-14ef521502fd"
│ Resource Group Name: "rg-cfcamsnick7-spoke2-prod"
│ Flexible Server Name: "psqlf-cfcamsnick7-westus3-prod"): polling after Update: polling failed: the Azure API returned the following error:
│ 
│ Status: "InternalServerError"
│ Code: ""
│ Message: "An unexpected error occured while processing the request. Tracking ID: '648bacd3-484c-43ff-8e03-78657e36971c'"
│ Activity Id: ""
│ 
│ ---
│ 
│ API Response:
│ 
│ ----[start]----
│ {"name":"987b48d2-2190-48be-b80c-e1dbd185b217","status":"Failed","startTime":"2024-02-09T17:29:45.12Z","error":{"code":"InternalServerError","message":"An unexpected error occured while processing the request. Tracking ID: '648bacd3-484c-43ff-8e03-78657e36971c'"}}
│ -----[end]-----
│ 
```

There is no workaround for this error. You must delete the deployment and start over.

## Access to the Azure Redis Cache console error

You can launch the console for Azure Redis Cache through the Azure Portal.

![Redis Console](docs/assets/azure-redis-console.png)

You may encounter the following errors when issuing Redis commands.

![Redis Error](docs/assets/azure-redis-private-console-error.png)

Enable *public network access* to use the console.

![Redis Enable Public Access](docs/assets/azure-redis-enable-public-network-access.png)
