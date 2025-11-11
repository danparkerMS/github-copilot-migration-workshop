#!/bin/bash

# Deploy Azure Resources using Bicep
# This script deploys the MessageService API and GreetingsFunction to Azure

set -e

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m' # No Color

echo -e "${GREEN}=== Azure Deployment Script ===${NC}"
echo ""

# Check if Azure CLI is installed
if ! command -v az &> /dev/null; then
    echo -e "${RED}Error: Azure CLI is not installed${NC}"
    echo "Please install it from: https://docs.microsoft.com/en-us/cli/azure/install-azure-cli"
    exit 1
fi

# Check if logged in to Azure
echo -e "${YELLOW}Checking Azure login status...${NC}"
if ! az account show &> /dev/null; then
    echo -e "${YELLOW}Not logged in to Azure. Logging in...${NC}"
    az login
else
    echo -e "${GREEN}Already logged in to Azure${NC}"
fi

# Get parameters
RESOURCE_GROUP_NAME="${1:-rg-msgapp-dev}"
LOCATION="${2:-eastus}"
DEPLOYMENT_NAME="msgapp-deployment-$(date +%Y%m%d-%H%M%S)"

echo ""
echo -e "${GREEN}Deployment Configuration:${NC}"
echo "  Resource Group: $RESOURCE_GROUP_NAME"
echo "  Location: $LOCATION"
echo "  Deployment Name: $DEPLOYMENT_NAME"
echo ""

# Check if resource group exists
echo -e "${YELLOW}Checking resource group...${NC}"
if ! az group show --name "$RESOURCE_GROUP_NAME" &> /dev/null; then
    echo -e "${YELLOW}Resource group does not exist. Creating...${NC}"
    az group create --name "$RESOURCE_GROUP_NAME" --location "$LOCATION"
    echo -e "${GREEN}Resource group created${NC}"
else
    echo -e "${GREEN}Resource group already exists${NC}"
fi

# Deploy the Bicep template
echo ""
echo -e "${YELLOW}Deploying Azure resources...${NC}"
echo "This may take several minutes..."
echo ""

az deployment group create \
    --name "$DEPLOYMENT_NAME" \
    --resource-group "$RESOURCE_GROUP_NAME" \
    --template-file Infrastructure/main.bicep \
    --parameters Infrastructure/main.parameters.json \
    --parameters location="$LOCATION"

# Check deployment status
if [ $? -eq 0 ]; then
    echo ""
    echo -e "${GREEN}=== Deployment Successful! ===${NC}"
    echo ""
    
    # Get outputs
    echo -e "${GREEN}Deployment Outputs:${NC}"
    API_URL=$(az deployment group show --name "$DEPLOYMENT_NAME" --resource-group "$RESOURCE_GROUP_NAME" --query properties.outputs.apiUrl.value -o tsv)
    FUNCTION_APP_NAME=$(az deployment group show --name "$DEPLOYMENT_NAME" --resource-group "$RESOURCE_GROUP_NAME" --query properties.outputs.functionAppName.value -o tsv)
    APP_SERVICE_NAME=$(az deployment group show --name "$DEPLOYMENT_NAME" --resource-group "$RESOURCE_GROUP_NAME" --query properties.outputs.appServiceName.value -o tsv)
    
    echo "  API URL: $API_URL"
    echo "  Function App: $FUNCTION_APP_NAME"
    echo "  App Service: $APP_SERVICE_NAME"
    echo ""
    
    echo -e "${YELLOW}Next Steps:${NC}"
    echo "1. Deploy the API code:"
    echo "   cd MessageServiceApi && dotnet publish -c Release"
    echo "   az webapp deployment source config-zip --resource-group $RESOURCE_GROUP_NAME --name $APP_SERVICE_NAME --src publish.zip"
    echo ""
    echo "2. Deploy the Function code:"
    echo "   cd GreetingsFunction && dotnet publish -c Release"
    echo "   func azure functionapp publish $FUNCTION_APP_NAME"
    echo ""
    echo -e "${GREEN}Or use the provided deployment scripts in the docs/ folder${NC}"
else
    echo ""
    echo -e "${RED}Deployment Failed!${NC}"
    echo "Please check the error messages above and try again."
    exit 1
fi
