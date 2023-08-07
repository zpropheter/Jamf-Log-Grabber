#!/bin/bash

#Jamf Log Grabber is designed to collect any logs associated with Jamf Products as well as MDM Managed Preferences. It features start and finish notifications for end users to be notified if desired
#Jamf Products currently supported: Jamf Binary (including Recon Troubleshooting), Jamf Connect, Jamf Security (Protect and Trust) 


#VARIABLES MUST BE SET TO 'TRUE' OR 'FALSE' AND ARE CASE SENSITIVE
JSS_LOGS=FALSE
Recon_Troubleshoot=TRUE
Jamf_Self_Service=FALSE
Jamf_Connect=FALSE
Jamf_Protect=FALSE
Managed_Preferences_Folder=FALSE
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
echo "Log Grabber was started at '$currenttime'" >> $results

#LOG COLLECTION FOR JAMF BINARY
if [[ "$JSS_LOGS" == TRUE ]];then
	mkdir -p $log_folder/JSS
	#FIND AND COPY THE JAMF SOFTWARE PLIST THEN CONVERT IT TO A READABLE FORMAT.
	#COPY DEBUG LOG
	if [ -e /Library/Preferences/com.jamfsoftware.jamf.plist ]; then cp "/Library/Preferences/com.jamfsoftware.jamf.plist" "$JSS/com.jamfsoftware.jamf.plist" | plutil -convert xml1 "$JSS/com.jamfsoftware.jamf.plist" | log show --style compact --predicate 'subsystem == "com.jamfsoftware.jamf"' --debug > "$JSS/Jamfsoftware.log"
	else
		echo "Jamf Software plist not found" >> $results
	fi
	#ADD JAMF CLIENT LOGS TO LOG FOLDER
	if [ -e /private/var/log/jamf.log ]; then cp "/private/var/log/jamf.log" $JSS
	else
		echo "Jamf Client Logs not found" >> $results
	fi
	#CHECK FOR JAMF INSTALL LOGS
	if [ -e /var/log/install.log ]; then cp "/var/log/install.log" $JSS 
	else
		echo "Install Logs not found" >> $results
	fi
	#CHECK FOR JAMF SYSTEM LOGS
	if [ -e /var/log/system.log ]; then cp "/var/log/system.log" $JSS
	else
		echo "System Logs not found" >> $results
	fi
	#FIND AND COPY JAMF SOFTWARE PLIST, THEN COPY AND CONVERT TO A READABLE FORMAT
	#COPY DEBUG LOG
	if [ -e /Library/Preferences/com.jamfsoftware.jamf.plist ]; then cp "/Library/Preferences/com.jamfsoftware.jamf.plist" "$JSS/com.jamfsoftware.jamf.plist" | plutil -convert xml1 "$JSS/com.jamfsoftware.jamf.plist" | log show --style compact --predicate 'subsystem == "com.jamfsoftware.jamf"' --debug > "$JSS/Jamfsoftware.log"
	else
		echo "Jamf Connect Login plist not found" >> $results
	fi
elif [[ "$JSS_LOGS" == FALSE ]];then
		echo "JSS Log Collection turned off" >> $results
else
	echo "JSS Log Collection variable set to invalid value"
fi

#JAMF RECON TROUBLESHOOTING
if [[ "$Recon_Troubleshoot" == TRUE ]];then
	mkdir -p $log_folder/Recon
	#check for Jamf Recon leftovers
	if [[ $reconleftovers == "" ]]; then
		echo "Recon Folder clean" >> $results
	else
		echo $reconleftovers > $recon/Leftovers.txt
	fi
elif [[ "$Recon_Troubleshoot" == FALSE ]];then
	echo "Recon Troubleshoot turned off" >> $results
else
	echo "Recon Troubleshoot variable set to invalid value"
fi

#JAMF SELF SERVICE LOG COLLECTION
if [[ "$Jamf_Self_Service" == TRUE ]];then
	mkdir -p $log_folder/Self_Service
	#check for jamf self service logs
	if [ -e /$HOME/Library/Logs/JAMF ]; then cp -r "$HOME/Library/Logs/JAMF/" $self_service
	else
		echo "Jamf Self Service Logs not found" >> $results
	fi
elif [[ "$Jamf_Self_Service" == FALSE ]];then
	echo "Jamf Self Service log collection turned off" >> $results
else
	echo "Jamf Self Service log collection variable set to invalid value"
fi

#JAMF CONNECT LOG COLLECTION
if [[ "$Jamf_Connect" == TRUE ]];then
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
		echo "No Kerberos Ticket for Current Logged in User" > $connect/klist_manuallyCollected.txt; else
			echo $kerblist > $connect/klist_manuallyCollected.txt
fi);else
	echo "No Jamf Connect Installed, doing nothing" >> $results
	fi
	#CHECK FOR JAMF CONNECT LOGIN LOGS AND PLIST, THEN COPY AND CONVERT TO A READABLE FORMAT
	if [ -e /tmp/jamf_login.log ]; then cp "/tmp/jamf_login.log" $connect/jamf_login_tmp.log
	else
		echo "Jamf Login /tmp file not found" >> $results
	fi
	
	if [ -e /Library/Managed\ Preferences/com.jamf.connect.login.plist ]; then cp "/Library/Managed Preferences/com.jamf.connect.login.plist" "$connect/com.jamf.connect.login_managed.plist" | plutil -convert xml1 "$connect/com.jamf.connect.login_managed.plist" | log show --style compact --predicate 'subsystem == "com.jamf.connect.login"' --debug > "$connect/com.jamf.connect.login.log"
	else
		echo "Jamf Connect Login plist not found" >> $results
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
	State_plist=$(defaults read com.jamf.connect.state.plist 2>/dev/null)
	if [[ "$State_plist" == "" ]]; then
		echo "A Jamf Connect State list was not found because no user is logged into Menu Bar" >> $results; else cp $HOME/Library/Preferences/com.jamf.connect.state.plist "$connect/com.jamf.connect.state.plist" | plutil -convert xml1 $connect/com.jamf.connect.state.plist
		fi
	
	#CHECK FOR JAMF CONNECT MENU BAR PLIST, THEN COPY AND CONVERT TO A READABLE FORMAT
	if [ -e /Library/Managed\ Preferences/com.jamf.connect.plist ]; then cp "/Library/Managed Preferences/com.jamf.connect.plist" "$connect/com.jamf.connect_managed.plist" | plutil -convert xml1 "$connect/com.jamf.connect_managed.plist" | log show --style compact --predicate 'subsystem == "com.jamf.connect"' --debug > "$connect/com.jamf.connect.log"
	else
		echo "Jamf Connect plist not found" >> $results
	fi
	
	#LIST AUTHCHANGER SETTIGNS
	if [ -e /usr/local/bin/authchanger ]; then
		/usr/local/bin/authchanger -print > "$connect/authchanger_manuallyCollected.txt";else
			echo "No Authchanger settings found" >> $results
		fi
elif [[ "$Jamf_Connect" == FALSE ]];then
echo "Jamf Connect log collection turned off" >> $results
else
echo "Jamf Connect log collection variable set to invalid value"
fi

#JAMF SECURITY LOG COLLECTION
if [[ "$Jamf_Protect" == TRUE ]];then
	#MAKE DIRECTORY FOR ALL JAMF SECURITY RELATED FILES
	mkdir -p $log_folder/Jamf_Security
	#CHECK FOR JAMF PROTECT PLIST, THEN COPY AND CONVERT TO READABLE FORMAT
	if [ -e /Library/Managed\ Preferences/com.jamf.protect.plist ]; then cp "/Library/Managed Preferences/com.jamf.protect.plist" "$security/com.jamf.protect.plist" | plutil -convert xml1 "$security/com.jamf.protect.plist"
	else
		echo "Jamf Protect plist not found" >> $results
	fi
	
	#CHECK FO RJAMF TRUST PLIST, THEN COPY AND CONVERT TO READABLE FORMAT
	if [ -e /Library/Managed\ Preferences/com.jamf.trust.plist ]; then cp "/Library/Managed Preferences/com.jamf.trust.plist" "$security/com.jamf.trust.plist" | plutil -convert xml1 "$security/com.jamf.trust.plist"
	else
		echo "Jamf Trust plist not found" >> $results
	fi
elif [[ "$Jamf_Protect" == FALSE ]];then
	echo "Jamf Security log collection turned off" >> $results
else
	echo "Jamf Security log collection variable set to invalid value"
fi

#MANAGED PREFERENCES PLIST COLLECTION
if [[ "$Managed_Preferences_Folder" == TRUE ]];then
	mkdir -p $log_folder/Managed_Preferences
	#CHECK FOR MANAGED PREFERENCE PLISTS, THEN COPY AND CONVERT THEM TO A READABLE FORMAT
	if [ -e /Library/Managed\ Preferences/ ]; then cp /Library/Managed\ Preferences/*.plist $managed_preferences
	else
		echo "No Managed Preferences plist files found" >> $results
	fi
	#SLEEP TO ALLOW COPY TO FINISH PROCESSING ALL FILES
	sleep 5
	
	#UNABLE TO CHECK FOLDER FOR WILDCARD PLIST LIKE *.PLIST
	#IF THIS SECTION IS NOT WORKING, FIND A COMMON PLIST THAT IS DEPLOYED FLEET WIDE LIKE A NOTIFICATION PAYLOAD OR SYSTEM EXTENSIONS AND CHANGE IT IN THE NEXT LINE
	if [ -e $managed_preferences/com.apple.TCC.configuration-profile-policy.plist ]; then plutil -convert xml1 $HOME/Desktop/Logs/managed_preferences/*.plist
	else
		echo "No files to convert to plist" >> $results
	fi
	#LIST ALL INSTALLED USER AND MACHINE PROFILES AND SAVE TO A .TXT FILE
	profiles show > $log_folder/User_Installed_Profiles.txt
	
	#REMOVE COMMENT OT SEE MACHINE PROFILES. WILL REQUIRE SUDO PRIVELIGES
	# sudo profiles show > $log_folder/User_Installed_Profiles.txt
	
elif [[ "$Managed_Preferences_Folder" == FALSE ]];then
	echo "Managed Preferences collection turned off" >> $results
else
	echo "Managed Preferences collection variable set to invalid value"
fi

#CLEANS OUT EMPTY FOLDERS TO AVOID CONFUSION
for emptyfolder in $cleanup
do	
if [ -z "$(ls -A /$log_folder/$emptyfolder)" ]; then
	echo "$emptyfolder is Empty removing folder" >>$results | rm -r $log_folder/$emptyfolder
else
	echo "$emptyfolder is Not Empty leaving folder" >>$results
fi
done
			
if [[ "$Finish_Notification" == TRUE ]];then
#BUILD A JAMF HELPER TO NOTIFY USERS THAT LOG COLLECTION IS COMPLETED
buttonClicked2=$(/Library/Application\ Support/JAMF/bin/jamfHelper.app/Contents/MacOS/jamfHelper -icon "/Applications/Self Service.app/Contents/Resources/AppIcon.icns" -windowType utility -title "$Finish_Notification_Title" -defaultButton 1 -description "$Finish_Notification_Description" -heading "$Finish_Notification_Heading" -button1 "$Finish_Notification_Confirm_Button")
				
if [ $buttonClicked2 == 0 ]; then
#USER RECEIVED THE CONFIRMATION HELPER THAT SCRIPT COMPLETED
echo "Script completed at $currenttime" > $results
else
echo "Jamf Helper did not notify user that log collection was complete" > $results
fi
elif [[ $Finish_Notification == FALSE ]]; then
	echo "Finish Notification turned off"
else
	echo "Finish Notification set to invalid value"
fi

#STAMP TIME COMPLETED BEFORE ZIPPING FILES
echo "Completed Log Grabber on '$currenttime'" >> $results

#ZIP IT ALL UP FOR ATTACHMENT TO AN EMAIL

#SET WORKING DIRECTORY TO DESKTOP
if [[ "$ZIP_Folder" == TRUE ]];then
cd $HOME/Desktop
#NAME ZIPPED FOLDER WITH LOGGED IN USER AND TIME
zip $HOME/Desktop/"$loggedInUser"_logs_collected_"$currentlogdate".zip -r Logs
rm -r $log_folder
elif [[ "$ZIP_Folder" == FALSE ]];then
	echo "Zip Folder turned off, leaving logs folder"
else
	echo "Zip Folder set to invalid value"
fi
