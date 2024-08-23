az keyvault secret set --vault-name <YourKeyVaultName> --name "ADJoinUser" --value "<username>"
az keyvault secret set --vault-name <YourKeyVaultName> --name "ADJoinPassword" --value "<password>"

az identity create --name <IdentityName> --resource-group <ResourceGroupName> --location <Location>

az vm identity assign --resource-group <ResourceGroupName> --name <VMName> --identity <IdentityName>

az keyvault update --name <YourKeyVaultName> --enable-rbac-authorization true

az role assignment create --role "Key Vault Secrets User" --assignee <UAMIClientId> --scope "/subscriptions/<SubscriptionId>/resourceGroups/<ResourceGroupName>/providers/Microsoft.KeyVault/vaults/<YourKeyVaultName>"

Configuration JoinDomain
{
    param
    (
        [Parameter(Mandatory=$true)]
        [string]$DomainName,

        [Parameter(Mandatory=$true)]
        [string]$KeyVaultName,

        [Parameter(Mandatory=$true)]
        [string]$VMIdentityClientId
    )

    Import-DscResource -ModuleName xPSDesiredStateConfiguration, xDSCDomainJoin

    Node localhost
    {
        $credentialUsername = (Get-AzKeyVaultSecret -VaultName $KeyVaultName -Name "ADJoinUser" -AsPlainText -DefaultProfile (New-AzKeyVaultManagedIdentityPolicy -ClientId $VMIdentityClientId))
        $credentialPassword = (Get-AzKeyVaultSecret -VaultName $KeyVaultName -Name "ADJoinPassword" -AsPlainText -DefaultProfile (New-AzKeyVaultManagedIdentityPolicy -ClientId $VMIdentityClientId))
        $credential = New-Object System.Management.Automation.PSCredential ($credentialUsername, (ConvertTo-SecureString $credentialPassword -AsPlainText -Force))

        xDSCDomainJoin JoinDomain
        {
            DomainName = $DomainName
            Credential = $credential
            JoinOU = "OU=Computers,DC=example,DC=com"  # Optional
            Name = $env:COMPUTERNAME
            Restart = $true
        }
    }
}

JoinDomain -DomainName "yourdomain.com" -KeyVaultName "<YourKeyVaultName>" -VMIdentityClientId "<IdentityClientId>"

# Ensure Az modules are installed
Install-Module -Name Az -AllowClobber -Force

# Authenticate with the Managed Identity
Connect-AzAccount -Identity

# Apply the configuration
$configPath = "C:\path\to\JoinDomain.ps1"
. $configPath
Start-DscConfiguration -Path $configPath -Wait -Verbose -Force

