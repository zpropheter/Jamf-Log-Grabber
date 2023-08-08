# Jamf-Log-Grabber

This script is designed to be a customizable log gathering script for troubleshooting.

### **Not to be used with /attachments endpoint via Jamf API**

It runs quickly in the background and does uses very few resources, however you can toggle User notification on or off if you're concerned about interrupting sensitive work with it running in the background.

Customizable items are listed below:

Lines 28-37 are TRUE/FALSE variables for what items you want to collect. If you turn one of these off, remove the correlating folder name in line 32 to reduce errors. If you fail to do this, there will be errors regarding a nonexistent folder when cleanup runs

Lines 39-44 are customizable variable for the Jamf Helper Start Notification. Edit the quoted text in the variable to change the Jamf Helper Window

Lines 46-50 are customizable variable for the Jamf Helper Finish Notification. Edit the quoted text in the variable to change the Jamf Helper Window

This can be deployed as a Self Service Policy or as a standard policy. The main log folder is left on the user's desktop. If the file is zipped, it will stamp the username and date on the archive.

Sudo permission is needed for the Recon Troubleshoot to work, everything else functions without sudo.
