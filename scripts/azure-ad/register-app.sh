AD_DISPLAY_NAME=contoso-fiber-app-$RANDOM

# Registering the Azure AD application
echo "Registering Azure AD application $AD_DISPLAY_NAME..."
az ad app create --display-name $AD_DISPLAY_NAME --sign-in-audience AzureADMyOrg --web-redirect-uris http://localhost:8080/login/oauth2/code/ --app-roles @manifest.json --enable-id-token-issuance > ad-app.json

# Retrieve the Application ID and get the client secret
AD_APP_ID=$(jq -r '.appId' ad-app.json)
az ad app credential reset --id ${AD_APP_ID} --append > ad-credentials.json

# Create a service principal for the app
echo "Creating service principal..."
az ad sp create --id ${AD_APP_ID}

CLIENT_ID=$(cat ad-credentials.json | jq -r '.appId')
CLIENT_SECRET=$(cat ad-credentials.json | jq -r '.password')
TENANT_ID=$(cat ad-credentials.json | jq -r '.tenant')

# Update Application ID URI
echo "Updating Application ID URI..."
AD_APP_ID_URI="api://${CLIENT_ID}"
az ad app update --id ${AD_APP_ID} --identifier-uris ${AD_APP_ID_URI}

# Assign the current user as owner of the application
echo "Assigning current user as owner of the application..."
az ad app owner add --id ${AD_APP_ID} --owner-object-id $(az ad signed-in-user show --query id --output tsv)

# Delete the temporary files
echo "Deleting temporary files..."
rm ad-app.json
rm ad-credentials.json

# Display the client it, client secret, and tenant ID
echo ""
echo "---------------------"
echo "Spring Security Properties"
echo "---------------------"
echo "CLIENT_ID: ${CLIENT_ID}"
echo "CLIENT_SECRET: ${CLIENT_SECRET}"
echo "TENANT_ID: ${TENANT_ID}"
echo "---------------------"
echo ""
