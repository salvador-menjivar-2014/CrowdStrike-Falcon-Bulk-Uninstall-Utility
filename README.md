# CrowdStrike Falcon Bulk Uninstall Utility (PowerShell)

This repository contains a PowerShell script for automating the bulk uninstallation of the CrowdStrike Falcon Sensor across multiple hosts. It is designed as a tool for security and systems administrators to efficiently decommission endpoints from the Falcon platform by interacting directly with the CrowdStrike API.

---

## ► The Challenge: Decommissioning Endpoints at Scale

When decommissioning servers or workstations, a critical step is to remove the security agent to free up licenses and prevent orphaned hosts in the management console. Manually uninstalling the CrowdStrike Falcon sensor from dozens or hundreds of machines is time-consuming, prone to human error, and doesn't scale.

This script solves that problem by automating the entire process. It reads a simple list of hosts from a CSV file and programmatically sends a remote uninstall command to each one via the Falcon API.

## ► Key Features & Skills Demonstrated

This script is a practical example of automating a critical security operations task, showcasing the following skills:

*   **Security Automation:** Automating a key security lifecycle management task, reducing manual effort and ensuring consistency.
*   **API Integration:** Interacting with a major security vendor's API (CrowdStrike Falcon) for programmatic control of endpoints.
*   **Robust PowerShell Scripting:**
    *   **Advanced Functions:** Uses `[CmdletBinding()]` and `param()` blocks to create a professional, reusable tool with mandatory parameters.
    *   **Error Handling:** Implements `try`/`catch` blocks for all critical operations (module import, API authentication, file I/O) to ensure the script fails safely and provides clear error messages.
    *   **Dependency Management:** Checks for the required `PSFalcon` module before execution.
*   **Safe & Idempotent Design:** The script only sends uninstall commands. It doesn't delete host records, and running it multiple times on the same list is safe. The `-QueueOffline` parameter ensures the command will be delivered even if the host is not currently online.
*   **Clear & Actionable Logging:** Provides color-coded console output to clearly indicate progress, successes, warnings, and failures.
*   **Comment-Based Help:** Includes detailed, structured comments that allow users to get help directly from the console via `Get-Help .\Invoke-FalconBulkUninstall.ps1 -Full`.

---

## ► How to Use

### 1. Prerequisites

*   **PowerShell:** A modern version of PowerShell (5.1 or later).
*   **PSFalcon Module:** The script requires the official CrowdStrike `PSFalcon` module. Install it with the following command in PowerShell:
    ```powershell
    Install-Module -Name PSFalcon -Scope CurrentUser
    ```
*   **API Credentials:** You need a CrowdStrike Falcon API key (Client ID and Client Secret) with the **Sensor Management: Write** permission.
*   **Execution Policy:** Your PowerShell execution policy must allow local scripts to run. If you encounter an error, you can set it for your current session with:
    ```powershell
    Set-ExecutionPolicy -ExecutionPolicy RemoteSigned -Scope Process
    ```

### 2. Prepare the CSV File

Create a CSV file with a list of the hosts you want to uninstall. The script requires at least one column containing the CrowdStrike Host ID (also known as the Agent ID or AID).

**Example `hosts-to-remove.csv`:**
```csv
Hostname,HostID,OperatingSystem
Server01,a1b2c3d4e5f678901234567890abcdef,Windows
Workstation05,b2c3d4e5f678901234567890abcdefa,Windows
```

### 3. Run the Script

Open a PowerShell terminal, navigate to the directory containing the script and your CSV, and run the command.

**Basic Example:**
```powershell
.\Invoke-FalconBulkUninstall.ps1 -CsvPath ".\hosts-to-remove.csv" -FalconClientId "YOUR_CLIENT_ID" -FalconClientSecret "YOUR_CLIENT_SECRET"
```

**Example with a Custom Column Name:**
If your Host ID column is named `AgentID`, you can specify it:
```powershell
.\Invoke-FalconBulkUninstall.ps1 -CsvPath ".\hosts.csv" -CsvIdColumn "AgentID" -FalconClientId "YOUR_CLIENT_ID" -FalconClientSecret "YOUR_CLIENT_SECRET"
```
