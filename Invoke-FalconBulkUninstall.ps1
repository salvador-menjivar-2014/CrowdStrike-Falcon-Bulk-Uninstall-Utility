<#
.SYNOPSIS
    Automates the bulk uninstallation of the CrowdStrike Falcon Sensor on multiple hosts using the PSFalcon PowerShell module.

.DESCRIPTION
    This script reads a list of Host IDs from a CSV file and sends a remote uninstall command for each host via the CrowdStrike Falcon API.
    It handles authentication, error checking, and provides detailed logging of the process.

    This is designed for security administrators to efficiently decommission multiple endpoints from CrowdStrike Falcon.

.PARAMETER CsvPath
    The full path to the CSV file containing the list of hosts to uninstall.

.PARAMETER CsvIdColumn
    The name of the column in your CSV file that contains the CrowdStrike Host ID (also known as Agent ID or AID).
    Defaults to "HostID".

.PARAMETER FalconClientId
    Your CrowdStrike Falcon API Client ID. It is recommended to use an API key with the "Sensor Management" write permission.

.PARAMETER FalconClientSecret
    Your CrowdStrike Falcon API Client Secret.

.EXAMPLE
    .\Invoke-FalconBulkUninstall.ps1 -CsvPath "C:\temp\hosts-to-remove.csv" -FalconClientId "your_client_id" -FalconClientSecret "your_client_secret"

    This command will read the CSV file from C:\temp\hosts-to-remove.csv, authenticate to the API, and attempt to uninstall each sensor listed in the "HostID" column.

.EXAMPLE
    .\Invoke-FalconBulkUninstall.ps1 -CsvPath ".\servers.csv" -CsvIdColumn "AgentID" -FalconClientId "your_client_id" -FalconClientSecret "your_client_secret"

    This command uses a CSV file named "servers.csv" in the current directory and reads the Host IDs from a column named "AgentID".

.NOTES
    Author: [Your Name]
    Version: 1.0
    Requires: PSFalcon PowerShell Module. Run 'Install-Module -Name PSFalcon -Scope CurrentUser' to install.
#>
[CmdletBinding()]
param (
    [Parameter(Mandatory = $true)]
    [string]$CsvPath,

    [Parameter(Mandatory = $false)]
    [string]$CsvIdColumn = "HostID",

    [Parameter(Mandatory = $true)]
    [string]$FalconClientId,

    [Parameter(Mandatory = $true)]
    [string]$FalconClientSecret
)

# --- Main Script Logic ---

# Step 1: Check for and import the required PSFalcon module.
try {
    # Use -ErrorAction Stop to ensure the catch block is triggered on failure.
    Import-Module PSFalcon -ErrorAction Stop
    Write-Host "[INFO] PSFalcon module imported successfully." -ForegroundColor Green
}
catch {
    Write-Error "[FATAL] Failed to import PSFalcon. Please run 'Install-Module -Name PSFalcon -Scope CurrentUser' in a new PowerShell session and try again."
    # Stop the script if the essential module can't be loaded.
    return
}

# Step 2: Authenticate to the CrowdStrike Falcon API.
Write-Host "[INFO] Requesting API token from CrowdStrike..."
try {
    # The PSFalcon module automatically handles the token. We just need to set the config.
    Set-FalconConfig -ClientId $FalconClientId -ClientSecret $FalconClientSecret -ErrorAction Stop
    Write-Host "[SUCCESS] API credentials configured successfully." -ForegroundColor Green
}
catch {
    Write-Error "[FATAL] Failed to configure API credentials. Please check your Client ID and Client Secret."
    return
}

# Step 3: Validate and import the CSV file.
if (-not (Test-Path -Path $CsvPath -PathType Leaf)) {
    Write-Error "[FATAL] CSV file not found at the specified path: $CsvPath"
    return
}

try {
    $hostsToRemove = Import-Csv -Path $CsvPath -ErrorAction Stop
    Write-Host "[INFO] Successfully loaded $($hostsToRemove.Count) records from CSV file." -ForegroundColor Green
}
catch {
    Write-Error "[FATAL] Failed to read or parse the CSV file. Please check that it is a valid, comma-separated file and is not locked by another program."
    return
}

# Step 4: Loop through each host and send the uninstall command.
Write-Host "--- Starting bulk uninstall process ---"
foreach ($device in $hostsToRemove) {
    # Access the Host ID using the dynamic column name provided in the $CsvIdColumn parameter.
    $currentHostId = $device.$CsvIdColumn

    # Validate that the Host ID is not null or just whitespace.
    if ([string]::IsNullOrWhiteSpace($currentHostId)) {
        Write-Warning "[SKIP] Skipping a row in the CSV because the '$CsvIdColumn' value is empty."
        continue
    }

    Write-Host "[ACTION] Sending uninstall command for Host ID: $currentHostId..." -ForegroundColor Yellow
    try {
        # The -QueueOffline parameter tells Falcon to uninstall the sensor even if it's not currently online.
        # The command will be queued until the sensor next checks in.
        $result = Uninstall-FalconSensor -Id $currentHostId -QueueOffline $true -ErrorAction Stop
        
        # The API returns a confirmation object. We log the key details.
        Write-Host "[SUCCESS] Uninstall command queued for Host ID: $currentHostId. State: $($result.state)" -ForegroundColor Green
    }
    catch {
        # This block will catch any API errors from the Uninstall-FalconSensor command.
        $errorMessage = $_.Exception.Message
        Write-Error "[FAILED] Could not queue uninstall for Host ID: $currentHostId. API Error: $errorMessage"
    }
}

Write-Host "--- Script complete ---"
