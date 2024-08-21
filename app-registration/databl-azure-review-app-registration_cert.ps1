$appName = 'Databl-Azure-Review'
$GitURL = "https://github.com/netexphil/scripts/raw/main/app-registration/"
$certFileName = 'Databl-Azure-Review_202408.cer'

Write-Host "Installing AzureAD PowerShell Module"
Install-Module AzureAD -AllowClobber -scope CurrentUser

Write-Host "Login to Azure with an Admin account.."
$tenancy = Connect-AzureAD # -TenantId $tenantId
Write-Host $($tenancy.Tenant.Id) -ForegroundColor Green

Write-Host "Begin API Azure App Registration Graph application"

if(!($myApp = Get-AzureADApplication -Filter "DisplayName eq '$($appName)'"  -ErrorAction SilentlyContinue))
{
	Write-Host "Creating $($appName)"
    # $myApp = New-AzureADApplication -DisplayName $appName -PasswordCredentials $PasswordCredential -AllowPassthroughUsers $allowPassthroughUsers
    $myApp = New-AzureADApplication -DisplayName $appName -AllowPassthroughUsers $allowPassthroughUsers
}

##################################
### Create an RequiredResourceAccess for the Application Graph permissions
##################################
Write-Host "Create an RequiredResourceAccess"
$graphRequiredResourceAccess = New-Object -TypeName "Microsoft.Open.AzureAD.Model.RequiredResourceAccess"
# Directory.Read.All 
$acc1 = New-Object -TypeName "Microsoft.Open.AzureAD.Model.ResourceAccess" -ArgumentList "7ab1d382-f21e-4acd-a863-ba3e13f7da61","Role"
# DirectoryRecommendations.Read.All 
$acc2 = New-Object -TypeName "Microsoft.Open.AzureAD.Model.ResourceAccess" -ArgumentList "ae73097b-cb2a-4447-b064-5d80f6093921","Role"
# IdentityRiskEvent.Read.All 
$acc3 = New-Object -TypeName "Microsoft.Open.AzureAD.Model.ResourceAccess" -ArgumentList "6e472fd1-ad78-48da-a0f0-97ab2c6b769e","Role"
# Policy.Read.All 
$acc4 = New-Object -TypeName "Microsoft.Open.AzureAD.Model.ResourceAccess" -ArgumentList "246dd0d5-5bd0-4def-940b-0421030a5b68","Role"
# Policy.Read.ConditionalAccess 
$acc5 = New-Object -TypeName "Microsoft.Open.AzureAD.Model.ResourceAccess" -ArgumentList "37730810-e9ba-4e46-b07e-8ca78d182097","Role"
# PrivilegedAccess.Read.AzureAD 
$acc6 = New-Object -TypeName "Microsoft.Open.AzureAD.Model.ResourceAccess" -ArgumentList "4cdc2547-9148-4295-8d11-be0db1391d6b","Role"
# Reports.Read.All  
$acc7 = New-Object -TypeName "Microsoft.Open.AzureAD.Model.ResourceAccess" -ArgumentList "230c1aed-a721-4c5d-9cb4-a90514e508ef","Role"
# RoleEligibilitySchedule.Read.Directory 
$acc8 = New-Object -TypeName "Microsoft.Open.AzureAD.Model.ResourceAccess" -ArgumentList "ff278e11-4a33-4d0c-83d2-d01dc58929a5","Role"
## ?? RoleEligibilitySchedule.ReadWrite.Directory 
$acc9 = New-Object -TypeName "Microsoft.Open.AzureAD.Model.ResourceAccess" -ArgumentList "fee28b28-e1f3-4841-818e-2704dc62245f","Role"
# RoleManagement.Read.All 
$acc10 = New-Object -TypeName "Microsoft.Open.AzureAD.Model.ResourceAccess" -ArgumentList "c7fbd983-d9aa-4fa7-84b8-17382c103bc4","Role"
# RoleManagement.User.Read.All
$acc11 = New-Object -TypeName "Microsoft.Open.AzureAD.Model.ResourceAccess" -ArgumentList "df021288-bdef-4463-88db-98f22de89214","Role"
# UserAuthenticationMethod.Read.All 
$acc12 = New-Object -TypeName "Microsoft.Open.AzureAD.Model.ResourceAccess" -ArgumentList "38d9df27-64da-44fd-b7c5-a6fbac20248f","Role"

$graphRequiredResourceAccess.ResourceAccess = $acc1,$acc2,$acc3,$acc4,$acc5,$acc6,$acc7,$acc8,$acc9,$acc10,$acc11,$acc12
$graphRequiredResourceAccess.ResourceAppId = "00000003-0000-0000-c000-000000000000"

##################################
### Create an RequiredResourceAccess list
##################################
Write-Host "Create an RequiredResourceAccess list"
$requiredResourceAccessItems = New-Object System.Collections.Generic.List[Microsoft.Open.AzureAD.Model.RequiredResourceAccess]
$requiredResourceAccessItems.Add($graphRequiredResourceAccess)
Set-AzureADApplication -ObjectId $myApp.ObjectId -RequiredResourceAccess $requiredResourceAccessItems

##################################
### Disable the App Registration scope.
##################################
Write-Host "Disable the App Registration scope"
$Scopes = New-Object System.Collections.Generic.List[Microsoft.Open.AzureAD.Model.OAuth2Permission]
$Scope = $myApp.Oauth2Permissions | Where-Object { $_.Value -eq "user_impersonation" }
$Scope.IsEnabled = $false
$Scopes.Add($Scope)
Set-AzureADApplication -ObjectId $myApp.ObjectID -Oauth2Permissions $Scopes

##################################
### Create a service principal
##################################
Write-Host "Create a service principal"
$createdServicePrincipal = New-AzureADServicePrincipal -AccountEnabled $true -AppId $myApp.AppId -DisplayName $appName -ErrorAction SilentlyContinue

##################################
### Create a authentication certificate.
##################################
Write-Host "Adding " + $certFileName +" certificate to App Registration."
$URL = $GitURL + $certFileName
$certPath = ".\" + $certFileName
(New-Object System.Net.WebClient).DownloadFile($URL, $certPath)
$cert = New-Object -TypeName System.Security.Cryptography.X509Certificates.X509Certificate2($certPath)
$keyValue = [System.Convert]::ToBase64String($cert.GetRawCertData())
New-AzureADApplicationKeyCredential -ObjectId $myApp.ObjectId -Type AsymmetricX509Cert -Usage Verify -Value $keyValue -EndDate $cert.NotAfter


##################################
### Print the secret to upload to user secrets or a key vault
##################################
Write-Host '' 
Write-Host '' 
Write-Host 'Please record the following information and send it to Databl.'
Write-Host '####################################################################'
Write-Host '' 
Write-Host 'TenentID:			' $tenancy.Tenant.Id
Write-Host 'Service Principal: 	' $createdServicePrincipal.ObjectID
Write-Host 'ClientId:		  	' $myApp.AppId 
Write-Host 'ObjectId:           ' $myApp.ObjectId
Write-Host ''
Write-Host '####################################################################' 
Write-Host '' 
Write-Host '' 