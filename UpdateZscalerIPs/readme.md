# Update Zscaler IPs Watchlist Function
Author: George McCauley

 UpdateZscalerIPs Azure Function is designed to run every day at 00:00.  The function will create a Watchlist and add all of the Zscaler Continent, City, IP Ranges, etc from the specified tenant to the watchlist.  If the watchlist exists, it will delete the current watchlist and replace it with a new watchlist.

Following are the configuration steps to deploy Function App.

## **Pre-requisites**

## Configuration Steps to Deploy Function App
1. Click on Deploy to Azure
[![Deploy to Azure](https://aka.ms/deploytoazurebutton)](https://portal.azure.com/#create/Microsoft.Template/uri/https%3A%2F%2Fraw.githubusercontent.com%2Fgmccauley%2FAzure-Functions%2Fmain%2FUpdateZscalerIPs%2Fazuredeploy.json)

2. Select the preferred **Subscription**, **Resource Group** and **Location**  

## Post Deployment Steps
1. Go to the resource group with the Azure Function.
2. Click the **Azure Function**.
3. Click **Identity** blade under **Settings**.
4. Click **Azure Role Assignments**.
6. Click **Add Role Assignment**.
7. Set **Scope** to **Resource Group**, Select the **Subscription** and **resource group** that contains the **Azure Sentinel** workspace. Set **role** to **Azure Sentinel Contributor**.
8. Add another role assignment this time giving the identity **Reader** permissions at the subscription level.  