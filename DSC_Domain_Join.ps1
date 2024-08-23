### Objective
To automate joining hundreds of Azure virtual machines (VMs) to your on-premises Active Directory domain, the recommended approach is to use **Azure Desired State Configuration (DSC)**. This method is scalable, secure, and easy to manage, allowing you to automate the domain join process without storing passwords in any code or script.

### Overview of the Process
1. **Prerequisites**: Ensure that you have the necessary Azure resources and access.
2. **Create and Configure Azure Key Vault**: Store AD credentials securely.
3. **Create a DSC Configuration Script**: Define the desired state for the VM.
4. **Compile and Upload the DSC Configuration**: Prepare the DSC configuration for deployment.
5. **Apply the DSC Configuration via Azure Automation or Custom Script Extension**: Deploy the configuration to your VMs.

### Step 1: **Prerequisites**
1. **Azure VMs**: Ensure your VMs are deployed and connected to the correct VNet with access to your on-premises domain controller.
2. **Azure Automation Account**: If you plan to use Azure Automation, ensure you have an Automation Account created.
3. **PowerShell Module**: Install the `Az` PowerShell module if you don't already have it.

### Step 2: **Create and Configure Azure Key Vault**

1. **Create an Azure Key Vault**:
   ```bash
   az keyvault create --name <YourKeyVaultName> --resource-group <YourResourceGroup> --location <YourLocation>
   ```

2. **Store AD Credentials in Key Vault**:
   ```bash
   az keyvault secret set --vault-name <YourKeyVaultName> --name "AD-Username" --value "<YourADUsername>"
   az keyvault secret set --vault-name <YourKeyVaultName> --name "AD-Password" --value "<YourADPassword>"
   ```

3. **Assign the Azure VM Managed Identity access to Key Vault**:
   ```bash
   az vm identity assign --name <YourVMName> --resource-group <YourResourceGroup>
   az keyvault set-policy --name <YourKeyVaultName> --object-id <VM-Managed-Identity-Object-ID> --secret-permissions get
   ```

### Step 3: **Create a DSC Configuration Script**

Create a DSC configuration script (`DomainJoin.ps1`) that will define the desired state for the VM to be joined to the domain.

```powershell
configuration DomainJoin {
    param (
        [string]$DomainName,
        [string]$OrganizationalUnit,
        [string]$KeyVaultName
    )

    Import-DscResource -ModuleName PSDesiredStateConfiguration

    Node $AllNodes.NodeName {
        LocalConfigurationManager {
            ActionAfterReboot = 'ContinueConfiguration'
            ConfigurationMode = 'ApplyAndAutoCorrect'
            RebootNodeIfNeeded = $true
            AllowModuleOverWrite = $true
        }

        $username = Get-AzKeyVaultSecret -VaultName $KeyVaultName -Name 'AD-Username' | Select-Object -ExpandProperty SecretValueText
        $password = Get-AzKeyVaultSecret -VaultName $KeyVaultName -Name 'AD-Password' | Select-Object -ExpandProperty SecretValueText
        $securePassword = ConvertTo-SecureString $password -AsPlainText -Force
        $credential = New-Object -TypeName System.Management.Automation.PSCredential -ArgumentList $username, $securePassword

        xComputer MyComputer {
            Name = $env:COMPUTERNAME
            DomainName = $DomainName
            Credential = $credential
            OUPath = $OrganizationalUnit
            Restart = $true
        }
    }
}

# Define the parameters
$domainName = '<YourDomainName>'
$ouPath = '<YourOrganizationalUnit>' # e.g., "OU=Servers,DC=example,DC=com"
$keyVaultName = '<YourKeyVaultName>'

# Generate the configuration
DomainJoin -DomainName $domainName -OrganizationalUnit $ouPath -KeyVaultName $keyVaultName

# Compile the configuration to a MOF file
Start-DscConfiguration -Path ./DomainJoin -Wait -Verbose -Force
```

### Step 4: **Compile and Upload the DSC Configuration**

1. **Compile the DSC Configuration**:
   Run the script above in your local environment to generate the `MOF` file, which is required for deployment.

2. **Upload the DSC Configuration to Azure Automation**:
   If using Azure Automation:
   ```powershell
   Import-AzAutomationDscConfiguration -SourcePath ./DomainJoin.ps1 -ResourceGroupName <YourResourceGroup> -AutomationAccountName <YourAutomationAccountName> -Published
   ```

### Step 5: **Apply the DSC Configuration via Azure Automation**

1. **Deploy DSC Configuration to the VMs**:
   Use Azure Automation to apply the DSC configuration to your VMs.

   ```powershell
   Start-AzAutomationDscNodeConfiguration `
     -ResourceGroupName <YourResourceGroup> `
     -AutomationAccountName <YourAutomationAccountName> `
     -NodeConfigurationName "DomainJoin.localhost" `
     -ConfigurationName "DomainJoin" `
     -NodeName <YourVMName> `
     -RebootNodeIfNeeded $true
   ```

### Step 6: **Monitor and Manage the Process**

- **Monitoring**: Monitor the DSC status via the Azure portal or through the Azure Automation logs to ensure all VMs are joined to the domain successfully.
- **Updating Configuration**: If you need to update the configuration, modify the DSC script and recompile it. This allows you to easily push updates to hundreds of VMs.

### Notes:
- **Scalable Solution**: This approach is scalable for large environments, allowing you to manage and update domain joins for hundreds of VMs efficiently.
- **No Passwords in Code**: The use of Azure Key Vault ensures that no sensitive information, like passwords, is stored in the script.
- **Security Best Practices**: Ensure that access to the Key Vault and Automation Account is tightly controlled and audited.

This method provides a secure, scalable, and manageable solution for automating the process of joining Azure VMs to your on-premises Active Directory domain.