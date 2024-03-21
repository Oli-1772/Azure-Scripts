#Authenticates using Enterprise application in Azure a user with 2FA enabled will have to reauthenticate each time the script is run and cannot be automated this way
$APPLICATIONID="ENTERPRISE-APPLICATION-ID"
$SECUREPASS="ENTERPRISE-APPLICATION-KEY"
$TENANTID="TENANT-ID"
$azureSubscription = "AZURE-SUBSCRIPTION-ID"	
$appGwName = "APPLICATION-GATEWAY-NAME"
$ResourceGroupName = "RESOURCEGROUP"


$azureSecurePass = ConvertTo-SecureString $securePass -AsPlainText -Force	
$credentials = New-Object System.Management.Automation.PSCredential($applicationId , $azureSecurePass)		
Connect-AzAccount -Credential $credentials -TenantId $tenantId -ServicePrincipal -ErrorAction stop -WarningAction 'silentlyContinue' |out-null
set-azcontext $azureSubscription

#Retrieve backend health 
try {
    $backendHealth = Get-AzApplicationGatewayBackendHealth -Name $appGwName -ResourceGroupName $ResourceGroupName -ErrorAction Stop | Select-Object -ExpandProperty BackendAddressPools | Select-Object -ExpandProperty BackendHttpSettingsCollection  | Select-Object -ExpandProperty servers | Select-Object -Property "Address", "Health"
} catch {
    Write-Error "Error retrieving backend health: $($_.Exception.Message)"
    exit 1
}
#Print to screen results, green if healthy red if unhealthy 
foreach ($server in $backendHealth) {
    if ($server.Health -eq "Healthy") {
        Write-Host "`n----------------------------------------------------------------" -ForegroundColor Yellow
        Write-Host "Server is healthy: $($server.Address)" -ForegroundColor Green
        Write-Host "----------------------------------------------------------------" -ForegroundColor Yellow
    } elseif ($server.Health -eq "Unhealthy") {
        Write-Host "`n----------------------------------------------------------------" -ForegroundColor Yellow
        Write-Host "Server is Unhealthy: $($server.Address)" -ForegroundColor Red
        Write-Host "----------------------------------------------------------------" -ForegroundColor Yellow
    }
}