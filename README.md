# Jamf Log Grabber
## _Get all the logs you'll ever need_

# LIMITATIONS:
# _This script is not intended for using to attach logs to a device record in Jamf Pro. Do not utilize such a workflow as it can lead to severe server performance issues_

Jamf Log Grabber is a bash based script that can be deployed manually, via Jamf MDM Policy, or as a Self Service Tool. It creates a zip folder on the user's desktop for upload to your service desk for troubleshooting.

## Supported Applications Include
- All Jamf Applications
- Device Compliance
- App Installers
- Multiple client side log diagnostics
- Up to 3 custom apps


## Features

- Simplified Customization
- Verbose results file for faster diagnostics
- MDM Communication Information
- Network checks for Jamf Remote Assist and App Installers
- Inventory Troubleshooting: Checks for files left behind during a Jamf Recon command and provides a file name for further investigation
- Jamf Connect License Check and troubleshooting
- 3 Custom apps to configure for your own log gathering

## Installation

Create a Jamf Pro policy that runs the following bash script:
- `curl -sSL https://jamf.it/get-logs | bash`

To call it manually in a terminal window, use the following command:
- `curl -sSL https://jamf.it/get-logs | sudo bash`

If you want to run Jamf Log Grabber with custom application create a Jamf Pro policy that runs the following bash script:
```
#!/bin/bash

export CustomApp1Name="$4"
export CustomApp1LogSource="$5"
export CustomApp2Name="$6"
export CustomApp2LogSource="$7"
export CustomApp3Name="$8"
export CustomApp3LogSource="$9"

curl -sSL jamf.it/get-logs-custom | bash
```

-In Jamf Pro, paste the contents of the script in a new script payload under Settings> Computer Management> Scripts> +New

-Click on Options and set the names for Parameters 4-9 as follows
<img src="https://i.imgur.com/FBU6bHv.png" width="800" height="400" />

-Under Computers> Policies, create a new policy that contains the Jamf Log Grabber. If you want to get additional app logs, set the name and file path you want as seen below in the "Parameter Values" section
<img src="https://i.imgur.com/2fXTmog.png" width="800" height="400" />

-When the script is ran, there will be a folder with your app name and the logs inside as seen with DEPNotify in this example.

<img src="https://i.imgur.com/LApTCKx.png" width="800" height="400" />

-If you do not see your app folder, it is because the file was not found and the cleanup array removed the empty folder. You can confirm checking the cleanup section of results.html
