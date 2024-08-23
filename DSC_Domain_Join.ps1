To securely automate the process of joining an Azure virtual machine to your on-premises Active Directory domain using a deployment script, follow these step-by-step instructions:

### Prerequisites:
1. **Azure VM**: Ensure your VM is deployed and connected to the correct virtual network (VNet) with access to your on-premises domain controller.
2. **Service Principal**: Create a service principal with appropriate permissions to manage your Azure resources.
3. **Key Vault**: Store your Active Directory credentials (domain join account username and password) securely in Azure Key Vault.

### Step 1: **Create an Azure Key Vault and Store Secrets**

1. **Create an Azure Key Vault** (if you don’t have one already):
   ```bash
   az keyvault create --name <YourKeyVaultName> --resource-group <YourResourceGroup> --location <YourLocation>
   ```

2. **Store the AD username and password in the Key Vault**:
   ```bash
   az keyvault secret set --vault-name <YourKeyVaultName> --name "AD-Username" --value "<YourADUsername>"
   az keyvault secret set --vault-name <YourKeyVaultName> --name "AD-Password" --value "<YourADPassword>"
   ```

### Step 2: **Create the Deployment Script**

Here’s a PowerShell script that will be executed on the Azure VM to join it to the domain securely. The script retrieves the credentials from Azure Key Vault.

```powershell
# Parameters
$vaultName = "<YourKeyVaultName>"
$vmName = "<YourVMName>"
$resourceGroupName = "<YourResourceGroupName>"
$domainName = "<YourDomainName>"
$domainOUPath = "<YourOrganizationalUnit>" # Example: "OU=Servers,DC=example,DC=com"

# Install necessary features
Install-WindowsFeature -Name AD-Domain-Services -IncludeManagementTools

# Retrieve AD credentials from Key Vault
$adUsername = (az keyvault secret show --name "AD-Username" --vault-name $vaultName --query value -o tsv).Trim()
$adPassword = (az keyvault secret show --name "AD-Password" --vault-name $vaultName --query value -o tsv).Trim()

# Convert password to a secure string
$securePassword = ConvertTo-SecureString $adPassword -AsPlainText -Force
$credentials = New-Object System.Management.Automation.PSCredential ($adUsername, $securePassword)

# Join the machine to the domain
Add-Computer -DomainName $domainName -Credential $credentials -OUPath $domainOUPath -Restart

# Optional: Rename the computer if needed
Rename-Computer -NewName $vmName -Restart

```

### Step 3: **Execute the Script on the Azure VM**

1. **Connect to the VM** via Azure CLI or any other method, such as RDP.
   ```bash
   az vm run-command invoke \
   --resource-group <YourResourceGroupName> \
   --name <YourVMName> \
   --command-id RunPowerShellScript \
   --scripts @<PathToYourScript.ps1>
   ```

   Alternatively, you can use Azure Custom Script Extension to automatically execute the script post-deployment.

### Step 4: **Verify the Domain Join**

Once the script executes successfully, the VM should restart and join the specified domain. Verify by logging into the VM with domain credentials.

### Step 5: **Clean Up (Optional)**

To enhance security, consider clearing out any sensitive data or ensuring proper access control on the Key Vault and the script's execution environment.

### Notes:
- **Secure access to Key Vault**: Ensure that only authorized users and systems have access to the Key Vault.
- **No hardcoded credentials**: Credentials are securely retrieved from the Key Vault, and no passwords are stored in scripts or code.

This approach securely automates the domain-join process using Azure services and PowerShell, ensuring that no sensitive information is exposed in the code.

Once the scripting and Azure Automation are configured, the process for an administrator to initiate the automation to join a virtual machine (VM) to the domain is streamlined and straightforward.

### Steps for the Administrator to Kick Off the Automation

1. **Deploy the VM**:
   - Ensure that the VM is deployed and connected to the correct virtual network (VNet) with access to your on-premises domain controller. The VM should also have a managed identity assigned to access the Azure Key Vault.

2. **Apply the Desired State Configuration (DSC) via Azure Automation**:
   - After the VM is deployed, the administrator can initiate the domain join process by applying the pre-configured DSC configuration to the VM.

3. **Start the DSC Configuration via Azure Portal**:
   - Go to the **Azure Portal**:
     1. Navigate to the **Automation Account** where the DSC configuration is stored.
     2. In the Automation Account, go to **State Configuration (DSC)** under the **Configuration Management** section.
     3. Select **Nodes**, and click on **+ Add**.
     4. Choose the target VM from the list.
     5. Select the **DSC Configuration** you want to apply (e.g., `DomainJoin`).
     6. Click **OK** to start the configuration.

   - **Or via PowerShell/Azure CLI**:
     - If you prefer to use PowerShell or the Azure CLI, you can trigger the process with a command like the following:

     ```powershell
     Start-AzAutomationDscNodeConfiguration `
       -ResourceGroupName <YourResourceGroup> `
       -AutomationAccountName <YourAutomationAccountName> `
       -NodeConfigurationName "DomainJoin.localhost" `
       -ConfigurationName "DomainJoin" `
       -NodeName <YourVMName> `
       -RebootNodeIfNeeded $true
     ```

4. **Monitoring**:
   - The administrator can monitor the progress and status of the domain join process from the Azure Portal or through the logs in the Automation Account.
   - You can also set up alerts in Azure Monitor to notify the administrator of the success or failure of the configuration.

### Summary

For each VM that needs to be joined to the domain, the administrator only needs to:

1. Deploy the VM with the required network connectivity and managed identity.
2. Apply the DSC configuration to the VM via the Azure Portal or PowerShell/CLI.
3. Monitor the process.

This approach minimizes the manual effort required and allows the domain join process to be easily applied to multiple VMs, making it highly scalable and efficient.