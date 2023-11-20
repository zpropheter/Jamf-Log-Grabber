# Jamf Log Grabber
## _Get all the logs you'll ever need_

<img src="https://i.imgur.com/tvEU3Lt.png" width="200" height="200" />

Jamf Log Grabber is a bash based script that can be deployed manually, via Jamf MDM Policy, or as a Self Service Tool.

Here's everything you'll be able to see
- Jamf Binary Related Logs: com.jamfsoftware.jamf.plist, Jamf.Log, Install.Log, System.logs
- Jamf Connect Logs and Plists
- Jamf Protect Plists
- MDM Communication Statuses
- Recon Troubleshooting: Checks for files left behind during a Jamf Recon command and provides a file name for further investigation
- Intune Logs for Device Compliance
- 3 Custom apps to configure for your own log gathering

## Features

- Ready to deploy script with preset Jamf Pro Variables
- Simplified Customization
- Verbose results file for fast diagnostics

## Installation

Download the latest copy of Jamf Log Grabber [here](https://github.com/zpropheter/Jamf-Log-Grabber/tree/main)

In Jamf Pro, paste the contents of the script in a new script payload under Settings> Computer Management> Scripts> +New
<img src="https://i.imgur.com/VTm1Sfl.png" width="400" height="400" />

Click on Options and set the names for Parameters 4-9 as follows
<img src="https://i.imgur.com/FBU6bHv.png" width="400" height="400" />

Under Computers> Policies, create a new policy that contains the Jamf Log Grabber. If you want to get additional app logs, set the name and file path you want as seen below in the "Parameter Values" section
<img src="https://i.imgur.com/2fXTmog.png" width="400" height="400" />

When the script is ran, there will be a folder with your app name and the logs inside as seen with DEPNotify in this example.
<img src="https://i.imgur.com/LApTCKx.png" width="400" height="400" />

If you do not see your app folder, it is because the file not found and the cleanup array removed the empty folder.

