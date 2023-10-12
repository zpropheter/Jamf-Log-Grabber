#!/bin/bash

#Jamf Log Grabber is designed to collect any logs associated with Jamf Products as well as MDM Managed Preferences. It features start and finish notifications for end users to be notified if desired
#Jamf Products currently supported: Jamf Binary (including Recon Troubleshooting), Jamf Connect, Jamf Security (Protect and Trust) 

# Redistribution and use in source and binary forms, with or without
# modification, are permitted provided that the following conditions are met:
#        * Redistributions of source code must retain the above copyright
#         notice, this list of conditions and the following disclaimer.
#      * Redistributions in binary form must reproduce the above copyright
#           notice, this list of conditions and the following disclaimer in the
#           documentation and/or other materials provided with the distribution.
#         * Neither the name of the JAMF Software, LLC nor the
#           names of its contributors may be used to endorse or promote products
#           derived from this software without specific prior written permission.
# THIS SOFTWARE IS PROVIDED BY JAMF SOFTWARE, LLC "AS IS" AND ANY
# EXPRESSED OR IMPLIED WARRANTIES, INCLUDING, BUT NOT LIMITED TO, THE IMPLIED
# WARRANTIES OF MERCHANTABILITY AND FITNESS FOR A PARTICULAR PURPOSE ARE
# DISCLAIMED. IN NO EVENT SHALL JAMF SOFTWARE, LLC BE LIABLE FOR ANY
# DIRECT, INDIRECT, INCIDENTAL, SPECIAL, EXEMPLARY, OR CONSEQUENTIAL DAMAGES
# (INCLUDING, BUT NOT LIMITED TO, PROCUREMENT OF SUBSTITUTE GOODS OR SERVICES;
# LOSS OF USE, DATA, OR PROFITS; OR BUSINESS INTERRUPTION) HOWEVER CAUSED AND
# ON ANY THEORY OF LIABILITY, WHETHER IN CONTRACT, STRICT LIABILITY, OR TORT
# (INCLUDING NEGLIGENCE OR OTHERWISE) ARISING IN ANY WAY OUT OF THE USE OF THIS
# SOFTWARE, EVEN IF ADVISED OF THE POSSIBILITY OF SUCH DAMAGE.

#INSTEAD OF MANUALLY SETTING THE COLLECTION VARIABLES, CREATE A MODE THAT LOG GRABBER WILL OPERATE IN
#OPTIONS= JAMF, JAMFZIP, ALL, ALLZIP
#Set to Jamf custom script variable to be able to change on the fly if deploying via policy
log_mode="$4"

#VARIABLES MUST BE SET TO 'TRUE' OR 'FALSE' AND ARE CASE SENSITIVE
JSS_LOGS=TRUE
Recon_Troubleshoot=TRUE
Jamf_Self_Service=TRUE
Jamf_Connect=TRUE
Jamf_Protect=TRUE
Managed_Preferences_Folder=TRUE
Start_Notification=FALSE
Finish_Notification=FALSE
ZIP_Folder=TRUE

#If Start_Notification is set to 'TRUE' use this to CUSTOMIZE YOUR START NOTIFICATION FROM JAMF HELPER BY EDITING THE QUOTED ITEMS OF EACH VARIABLE
Start_Notification_Title=$(echo "Support Desk Notification")
Start_Notification_Heading=$(echo "Jamf Log Grabber")
Start_Notification_Description=$(echo "You have been asked to send logs over to your Support Department. Press OK to start the process. An additional notification will show when completed.")
Start_Notification_Confirm_Button=$(echo "Start")
Start_Notification_Cancel_Button=$(echo "Cancel")

#If Finish_Notification is set to 'TRUE' use this to CUSTOMIZE YOUR START NOTIFICATION FROM JAMF HELPER BY EDITING THE QUOTED ITEMS OF EACH VARIABLE
Finish_Notification_Title=$(echo "Support Desk Notification")
Finish_Notification_Heading=$(echo "Jamf Log Grabber")
Finish_Notification_Description=$(echo "Log collection has completed, please forward the zipped file with your name and the date to your Support Department.")
Finish_Notification_Confirm_Button=$(echo "OK")

#IF A VARIABLE ABOVE IS SET TO 'FALSE', REMOVE THE FOLDER NAME FOR IT BELOW TO AVOID ERRORS WITH THE CLEANUP FUNCTION AT THE END OF THE SCRIPT
cleanup=("JSS Recon Self_Service Connect Jamf_Security Managed_Preferences")


#HARD CODED VARIABLES, DO NOT CHANGE
log_folder=$HOME/Desktop/Logs
results=$log_folder/Results.txt
JSS=$log_folder/JSS
security=$log_folder/Jamf_Security
connect=$log_folder/Connect
managed_preferences=$log_folder/Managed_Preferences
recon=$log_folder/Recon
self_service=$log_folder/Self_Service
loggedInUser=$( echo "show State:/Users/ConsoleUser" | /usr/sbin/scutil | /usr/bin/awk '/Name :/ && ! /loginwindow/ { print $3 }' )
reconleftovers=$(ls /Library/Application\ Support/JAMF/tmp/)

#DATE FOR LOG FOLDER ZIP CREATION
currentlogdate=$(date)

#DATE AND TIME FOR RESULTS.TXT INFORMATION
currenttime=$(date +"%D %T")

#START NOTIFICATION CALLS JAMF HELPER TO NOTIFY USERS THAT LOG COLLECTION IS BEGINNING AND ADVISES THEM OF BEHAVIOR TO LOOK FOR WHEN COMPLETED.
if [[ "$Start_Notification" == TRUE ]];then
	#BUILD A JAMF HELPER TO NOTIFY USERS THAT LOG COLLECTION WILL BEGIN AND TO SEND FILES IN TO SUPPORT WHEN COMPLETED
	buttonClicked=$(/Library/Application\ Support/JAMF/bin/jamfHelper.app/Contents/MacOS/jamfHelper -windowType utility -icon /Applications/Self\ Service.app/Contents/Resources/AppIcon.icns -title "$Start_Notification_Title" -heading "$Start_Notification_Heading" -description "$Start_Notification_Description" -button1 "$Start_Notification_Confirm_Button" -button2 "$Start_Notification_Cancel_Button" -defaultButton 1 -cancelButton 2)

if [[ $buttonClicked == 0 ]]; then
	# BUTTON 1 WAS CLICKED
	echo "Running"
elif [[ $buttonClicked == 2 ]]; then
	# BUTTON 2 WAS CLICKED
	echo "Script cancelled at '$currenttime'" 
	exit
fi
elif [[ $Start_Notification == FALSE ]]; then
	echo "Start notification turned off"
else
	echo "Start_Notification set to invalid value"
fi

#CLEAR OUT PREVIOUS RESULTS
if [ -e $log_folder ] ;then rm -r $log_folder
fi

#CREATE A FOLDER TO SAVE ALL LOGS
mkdir -p $log_folder

#CREATE A LOG FILE FOR SCRIPT AND SAVE TO LOGS DIRECTORY SO ADMINS CAN SEE WHAT LOGS WERE NOT GATHERED
touch $results

#SET A TIME AND DATE STAMP FOR WHEN THE LOG GRABBER WAS RAN
echo -e "Log Grabber was started at '$currenttime'\n" >> $results

if [[ $log_mode == JAMF ]]; then
	echo "Jamf only mode enabled" >> $results
	JSS_LOGS=TRUE
	Recon_Troubleshoot=TRUE
	Jamf_Self_Service=TRUE
	Jamf_Connect=TRUE
	Jamf_Protect=TRUE
	Managed_Preferences_Folder=FALSE
	ZIP_Folder=FALSE
elif [[ $log_mode == JAMFZIP ]]; then
	echo "Jamf only zip mode enabled" >> $results
	JSS_LOGS=TRUE
	Recon_Troubleshoot=TRUE
	Jamf_Self_Service=TRUE
	Jamf_Connect=TRUE
	Jamf_Protect=TRUE
	Managed_Preferences_Folder=FALSE
	ZIP_Folder=TRUE
elif [[ $log_mode == ALL ]]; then
	echo "Collect ALL logs mode enabled" >> $results
	JSS_LOGS=TRUE
	Recon_Troubleshoot=TRUE
	Jamf_Self_Service=TRUE
	Jamf_Connect=TRUE
	Jamf_Protect=TRUE
	Managed_Preferences_Folder=TRUE
	ZIP_Folder=FALSE
elif [[ $log_mode == ALLZIP ]]; then
	echo "Collect ALL logs and ZIP mode enabled" >> $results
	JSS_LOGS=TRUE
	Recon_Troubleshoot=TRUE
	Jamf_Self_Service=TRUE
	Jamf_Connect=TRUE
	Jamf_Protect=TRUE
	Managed_Preferences_Folder=TRUE
	ZIP_Folder=FALSE
else
	echo "Log Mode not turned on or set to incorrect variable, will use manual settings" >> $results
fi 

#LOG COLLECTION FOR JAMF BINARY
if [[ "$JSS_LOGS" == TRUE ]];then
	mkdir -p $log_folder/JSS
	#FIND AND COPY THE JAMF SOFTWARE PLIST THEN CONVERT IT TO A READABLE FORMAT.
	#COPY DEBUG LOG
	if [ -e /Users/$loggedInUser/Library/Preferences/com.jamfsoftware.jamf.plist ]; then cp "/Library/Preferences/com.jamfsoftware.jamf.plist" "$JSS/com.jamfsoftware.jamf.plist" | plutil -convert xml1 "$JSS/com.jamfsoftware.jamf.plist" | log show --style compact --predicate 'subsystem == "com.jamfsoftware.jamf"' --debug > "$JSS/Jamfsoftware.log"
	else
		echo -e "Jamf Software plist not found\n" >> $results
	fi
	#ADD JAMF CLIENT LOGS TO LOG FOLDER
	if [ -e /private/var/log/jamf.log ]; then cp "/private/var/log/jamf.log" $JSS
		echo -e "Jamf.log found on machine for information about what this reports visit this URL:\nhttps://learn.jamf.com/bundle/jamf-pro-documentation-current/page/Components_Installed_on_Managed_Computers.html\n" >> $results
	else
		echo -e "Jamf Client Logs not found\n" >> $results
	fi
	#CHECK FOR JAMF INSTALL LOGS
	if [ -e /var/log/install.log ]; then cp "/var/log/install.log" $JSS 
	else
		echo -e "Install Logs not found\n" >> $results
	fi
	#CHECK FOR JAMF SYSTEM LOGS
	if [ -e /var/log/system.log ]; then cp "/var/log/system.log" $JSS
	else
		echo -e "System Logs not found\n" >> $results
	fi
	#FIND AND COPY JAMF SOFTWARE PLIST, THEN COPY AND CONVERT TO A READABLE FORMAT
	#COPY DEBUG LOG
	if [ -e /Library/Preferences/com.jamfsoftware.jamf.plist ]; then cp "/Library/Preferences/com.jamfsoftware.jamf.plist" "$JSS/com.jamfsoftware.jamf.plist" | plutil -convert xml1 "$JSS/com.jamfsoftware.jamf.plist" | log show --style compact --predicate 'subsystem == "com.jamfsoftware.jamf"' --debug > "$JSS/Jamfsoftware.log"
	else
		echo -e "Jamf Connect Login plist not found\n" >> $results
	fi
	#THIS SECTION IS UNLIKELY TO WORK IF THE MDM IS NOT COMMUNICATING WITH THE DEVICE.
	#IT WILL STILL GET GOOD INFORMATION IF MDM IS COMMUNICATING
	#IF A DEVICE IS NOT COMMUNICATING WITH MDM, THIS WILL ALSO GIVE ITEMS TO LOOK INTO
	#WRITE TO LOGS WHAT WE ARE DOING NEXT
	echo -e "Checking $loggedInUser's computer for MDM communication issues:" >> $results
	#CHECK MDM STATUS AND ADVISE IF IT IS COMMUNICATING
	result=$(log show --style compact --predicate '(process CONTAINS "mdmclient")' --last 1d | grep "Unable to create MDM identity")
	if [[ $result == '' ]]; then
			echo -e "-MDM is communicating" >> $results
		else
			echo -e "-MDM is broken" >> $results
		fi
	#CHECK FOR THE MDM PROFILE TO BE INSTALLED
	mdmProfile=$(/usr/libexec/mdmclient QueryInstalledProfiles | grep "00000000-0000-0000-A000-4A414D460003")
	if [[ $mdmProfile == "" ]]; then
		echo -e "-MDM Profile Not Installed" >> $results
	else
		echo -e "-MDM Profile Installed" >> $results
	fi
	#TELL THE STATUS OF THE MDM DAEMON
	mdmDaemonStatus=$(/System/Library/PrivateFrameworks/ApplePushService.framework/apsctl status | grep -A 18 com.apple.aps.mdmclient.daemon.push.production | awk -F':' '/persistent connection status/ {print $NF}' | sed 's/^ *//g')
	echo -e "-The MDM Daemon Status is:$mdmDaemonStatus" >> $results
	#WRITE THE APNS TOPIC TO THE RESULTS FILE IF IT EXISTS
	profileTopic=$(system_profiler SPConfigurationProfileDataType | grep "Topic" | awk -F '"' '{ print $2 }');
	if [ "$profileTopic" != "" ]; then
		echo -e "-APNS Topic is: $profileTopic\n" >> $results
	else
		echo -e "-No APNS Topic Found\n" >> $results
	fi
elif [[ "$JSS_LOGS" == FALSE ]];then
		echo -e "JSS Log Collection turned off" >> $results
else
	echo -e "JSS Log Collection variable set to invalid value" >>$results
fi

#JAMF RECON TROUBLESHOOTING
if [[ "$Recon_Troubleshoot" == TRUE ]];then
	mkdir -p $log_folder/Recon
	#check for Jamf Recon leftovers
	if [[ $reconleftovers == "" ]]; then
		echo -e "Recon Folder Empty, we love to see that!\n" >> $results
	else
		echo $reconleftovers > $recon/Leftovers.txt
		#DIAGNOSTIC INFORMATION FOR RECON RESULTS. FOLLOWING THESE STEPS WILL HELP IDENTIFY PROBLEMATIC EXTENSION ATTRIBUTES AND/OR INVENTORY CHECK IN PROBLEMS
		echo -e "\nRecon leftovers found and listed above\nTo remediate, take the following steps:\n1. Open Terminal\n2.Type 'rm -r /Library/Application\ Support/JAMF/tmp/*'\nThis will remove all temporary files in the folder and allow the inventory update to complete.\nSometimes these files get stuck, so this helps reset them.\nIf the files come back:\n1\n1. Run a 'cat /Library/Application\ Support/JAMF/tmp/temporaryfilename'\n2. Find the extension attribute that matches the output from the command and disable or delete it until the root cause is identified\n" >> $recon/Leftovers.txt
		#REPORT IN RESULTS FILE THAT LEFTOVERS WERE FOUND
		echo -e "\nRecon Troubleshoot found files in the /tmp directory that should not be there. A report of these files as well as next actions can be found in the Leftovers.txt file in the Recon Directory.\n" >> $results
	fi
elif [[ "$Recon_Troubleshoot" == FALSE ]];then
	echo -e "Recon Troubleshoot turned off\n" >> $results
else
	echo -e "Recon Troubleshoot variable set to invalid value\n" >> $results
fi

#JAMF SELF SERVICE LOG COLLECTION
if [[ "$Jamf_Self_Service" == TRUE ]];then
	mkdir -p $log_folder/Self_Service
	#check for jamf self service logs
	if [ -e /$HOME/Library/Logs/JAMF ]; then cp -r "$HOME/Library/Logs/JAMF/" $self_service
	else
		echo -e "Jamf Self Service Logs not found\n" >> $results
	fi
elif [[ "$Jamf_Self_Service" == FALSE ]];then
	echo -e "Jamf Self Service log collection turned off\n" >> $results
else
	echo -e "Jamf Self Service log collection variable set to invalid value\n" $results
fi

#JAMF CONNECT LOG COLLECTION
if [[ "$Jamf_Connect" == TRUE ]];then
	echo "Collecting Jamf Connect logs..." >>$results
	mkdir -p $log_folder/Connect
	#create a log file for script and save to Logs directory so users can see what logs were not gathered
	touch $results	
	if [ -e /Library/Managed\ Preferences/com.jamf.connect.plist ]; then
		#OUTPUT ALL HISTORICAL JAMF CONNECT LOGS, THIS WILL ALWAYS GENERATE A LOG FILE EVEN IF CONNECT IS NOT INSTALLED
		log show --style compact --predicate 'subsystem == "com.jamf.connect"' --debug > $connect/JamfConnect.log
		#OUTPUT ALL HISTORICAL JAMF CONNECT LOGIN LOGS
		log show --style compact --predicate 'subsystem == "com.jamf.connect.login"' --debug > $connect/jamfconnect.login.log
		kerberioscheck=$(kerblist=$("klist" 2>/dev/null)
	if [[ "$kerblist" == "" ]];then
		echo "-No Kerberos Ticket for Current Logged in User" > $connect/klist_manuallyCollected.txt; else
			echo $kerblist > $connect/klist_manuallyCollected.txt
fi);else
	echo -e "-No Jamf Connect Installed, doing nothing\n" >> $results
	fi
	#CHECK FOR JAMF CONNECT LOGIN LOGS AND PLIST, THEN COPY AND CONVERT TO A READABLE FORMAT
	if [ -e /tmp/jamf_login.log ]; then cp "/tmp/jamf_login.log" $connect/jamf_login_tmp.log
	else
		echo -e "-Jamf Login /tmp file not found\n-This usually only exists on recent installs.\n-Don't worry if you don't see anything. We're just being thorough.\n" >> $results
	fi
	
	if [ -e /Library/Managed\ Preferences/com.jamf.connect.login.plist ]; then cp "/Library/Managed Preferences/com.jamf.connect.login.plist" "$connect/com.jamf.connect.login_managed.plist" | plutil -convert xml1 "$connect/com.jamf.connect.login_managed.plist" | log show --style compact --predicate 'subsystem == "com.jamf.connect.login"' --debug > "$connect/com.jamf.connect.login.log"
	else
		echo -e "-Jamf Connect Login plist not found\n" >> $results
	fi
	
	#CHECK FOR JAMF CONNECT LICENSE, THEN COPY AND CONVERT TO A READABLE FORMAT
	LicensefromLogin=$(defaults read /Library/Managed\ Preferences/com.jamf.connect.login.plist LicenseFile 2>/dev/null)
	LicensefromMenubar=$(defaults read /Library/Managed\ Preferences/com.jamf.connect.plist LicenseFile 2>/dev/null)
	if [[ "$LicensefromLogin" == "PD94"* ]]; then
		(echo "$LicensefromLogin" | base64 -d) > $connect/license.txt
	elif [[ "$LicensefromMenubar" == "PD94"* ]]; then
		(echo "$LicensefromMenubar" | base64 -d) > $connect/license.txt
	else
		file=""
	fi
	
	#CHECK FOR JAMF CONNECT STATE PLIST, THEN COPY AND CONVERT TO A READABLE FORMAT
	State_plist=$(defaults read /Users/$loggedInUser/Library/Preferences/com.jamf.connect.state.plist 2>/dev/null)
	if [[ "$State_plist" == "" ]]; then
		echo -e "-A Jamf Connect State list was not found because no user is logged into Menu Bar\n" >> $results; 
	else cp $HOME/Library/Preferences/com.jamf.connect.state.plist "$connect/com.jamf.connect.state.plist" | plutil -convert xml1 $connect/com.jamf.connect.state.plist
		fi
	
	#CHECK FOR JAMF CONNECT MENU BAR PLIST, THEN COPY AND CONVERT TO A READABLE FORMAT
	if [ -e /Library/Managed\ Preferences/com.jamf.connect.plist ]; then cp "/Library/Managed Preferences/com.jamf.connect.plist" "$connect/com.jamf.connect_managed.plist" | plutil -convert xml1 "$connect/com.jamf.connect_managed.plist" | log show --style compact --predicate 'subsystem == "com.jamf.connect"' --debug > "$connect/com.jamf.connect.log"
	else
		echo -e "Jamf Connect plist not found\n" >> $results
	fi
	
	#LIST AUTHCHANGER SETTIGNS
	if [ -e /usr/local/bin/authchanger ]; then
		/usr/local/bin/authchanger -print > "$connect/authchanger_manuallyCollected.txt"
		echo -e "-Authchanger changes the authentication database for MacOS.\nMore info can be found at this URL:\nhttps://learn.jamf.com/bundle/jamf-connect-documentation-current/page/authchanger.html\nReview the authchanger_manuallyCollected.txt file to see your settings and determine if Authchanger needs to be modified for your environment.\n" >> $results;
	else
			echo -e "-No Authchanger settings found\n" >> $results
		fi
elif [[ "$Jamf_Connect" == FALSE ]];then
echo -e "Jamf Connect log collection turned off\n" >> $results
else
echo -e"Jamf Connect log collection variable set to invalid value\n"
fi

#JAMF SECURITY LOG COLLECTION
if [[ "$Jamf_Protect" == TRUE ]];then
	#MAKE DIRECTORY FOR ALL JAMF SECURITY RELATED FILES
	mkdir -p $log_folder/Jamf_Security
	#CHECK FOR JAMF PROTECT PLIST, THEN COPY AND CONVERT TO READABLE FORMAT
	if [ -e /Library/Managed\ Preferences/com.jamf.protect.plist ]; then cp "/Library/Managed Preferences/com.jamf.protect.plist" "$security/com.jamf.protect.plist" | plutil -convert xml1 "$security/com.jamf.protect.plist"
	else
		echo -e "Jamf Protect plist not found\n" >> $results
	fi
	#CHECK FOR JAMF TRUST PLIST, THEN COPY AND CONVERT TO READABLE FORMAT
	if [ -e /Library/Managed\ Preferences/com.jamf.trust.plist ]; then cp "/Library/Managed Preferences/com.jamf.trust.plist" "$security/com.jamf.trust.plist" | plutil -convert xml1 "$security/com.jamf.trust.plist"
	else
		echo -e "Jamf Trust plist not found\n" >> $results
	fi
elif [[ "$Jamf_Protect" == FALSE ]];then
	echo -e "Jamf Security log collection turned off\n" >> $results
else
	echo -e "Jamf Security log collection variable set to invalid value\n" >> $results
fi

#MANAGED PREFERENCES PLIST COLLECTION
if [[ "$Managed_Preferences_Folder" == TRUE ]];then
	mkdir -p $log_folder/Managed_Preferences
	#CHECK FOR MANAGED PREFERENCE PLISTS, THEN COPY AND CONVERT THEM TO A READABLE FORMAT
	if [ -e /Library/Managed\ Preferences/ ]; then cp /Library/Managed\ Preferences/*.plist $managed_preferences
		echo -e "The Managed Preferences folder deploys plists that tell the referenced application what parameters to follow. If you deployed settings to an application that aren't applying, make sure the preference domain plist is deployed to this folder.Check the Managed_Preferences output for results.\n" >> $results
	else
		echo -e "No Managed Preferences plist files found\n" >> $results
	fi
	#SLEEP TO ALLOW COPY TO FINISH PROCESSING ALL FILES
	sleep 5
	
	#UNABLE TO CHECK FOLDER FOR WILDCARD PLIST LIKE *.PLIST
	#IF THIS SECTION IS NOT WORKING, FIND A COMMON PLIST THAT IS DEPLOYED FLEET WIDE LIKE A NOTIFICATION PAYLOAD OR SYSTEM EXTENSIONS AND CHANGE IT IN THE NEXT LINE
	if [ -e $managed_preferences/com.apple.TCC.configuration-profile-policy.plist ]; then plutil -convert xml1 $HOME/Desktop/Logs/managed_preferences/*.plist
	else
		echo -e "No files to convert to plist\n" >> $results
	fi
	#LIST ALL INSTALLED USER AND MACHINE PROFILES AND SAVE TO A .TXT FILE
	profiles show > $log_folder/User_Installed_Profiles.txt
	
	#REMOVE COMMENT OT SEE MACHINE PROFILES. WILL REQUIRE SUDO PRIVELIGES
	# sudo profiles show > $log_folder/User_Installed_Profiles.txt
	
elif [[ "$Managed_Preferences_Folder" == FALSE ]];then
	echo -e "Managed Preferences collection turned off\n" >> $results
else
	echo -e "Managed Preferences collection variable set to invalid value\n" >> $results
fi

#CLEANS OUT EMPTY FOLDERS TO AVOID CONFUSION
echo -e "Cleaning out empty folders from the directory...." >> $results
for emptyfolder in $cleanup
do	
if [ -z "$(ls -A /$log_folder/$emptyfolder)" ]; then
	echo -e "-$emptyfolder folder is empty, removing folder" >>$results | rm -r $log_folder/$emptyfolder
else
	echo -e "-$emptyfolder folder is not empty, leaving folder" >>$results
fi
done
echo -e "-Finished cleaning up.\n" >> $results
			
if [[ "$Finish_Notification" == TRUE ]];then
#BUILD A JAMF HELPER TO NOTIFY USERS THAT LOG COLLECTION IS COMPLETED
buttonClicked2=$(/Library/Application\ Support/JAMF/bin/jamfHelper.app/Contents/MacOS/jamfHelper -icon "/Applications/Self Service.app/Contents/Resources/AppIcon.icns" -windowType utility -title "$Finish_Notification_Title" -defaultButton 1 -description "$Finish_Notification_Description" -heading "$Finish_Notification_Heading" -button1 "$Finish_Notification_Confirm_Button")
				
if [ $buttonClicked2 == 0 ]; then
#USER RECEIVED THE CONFIRMATION HELPER THAT SCRIPT COMPLETED
echo -e "Script completed at $currenttime\n" >> $results
else
echo -e "Jamf Helper did not notify user that log collection was complete\n" >> $results
fi
elif [[ $Finish_Notification == FALSE ]]; then
	echo -e "Finish Notification turned off\n" >> $results
	
else
	echo -e "Finish Notification set to invalid value\n" >> $results
fi

#STAMP TIME COMPLETED BEFORE ZIPPING FILES
echo -e "Completed Log Grabber on '$currenttime'\n" >> $results

#ZIP IT ALL UP FOR ATTACHMENT TO AN EMAIL

#SET WORKING DIRECTORY TO DESKTOP
if [[ "$ZIP_Folder" == TRUE ]];then
cd $HOME/Desktop
#NAME ZIPPED FOLDER WITH LOGGED IN USER AND TIME
zip $HOME/Desktop/"$loggedInUser"_logs_collected_"$currentlogdate".zip -r Logs
rm -r $log_folder
elif [[ "$ZIP_Folder" == FALSE ]];then
	echo -e "Zip Folder turned off, leaving logs folder on the user's desktop" >> $results
else
	echo -e "Zip Folder set to invalid value" >> $results
fi
