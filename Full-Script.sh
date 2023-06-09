#!/bin/bash

#This script is designed to grab every Jamf Log you can think of when you're troubleshooting.
#Jamf Connect files are labeled as you would find them by using the menu bar> about> collect logs
#All other files are labeled as you would find them on the machine
#Results folder contains a .txt to tell you what it can't find. This should match what you know to be installed on the machine
#This script is grouped by app so you can pull out what you need if you just want to run it for the specific applications


#define variables
log_folder=$HOME/Desktop/Logs
not_found=$HOME/Desktop/Logs/Results/
results=$not_found/Results.txt
JSS=$log_folder/JSS
protect=$log_folder/Protect
connect=$log_folder/Connect
trust=$log_folder/Trust
managed_preferences=$log_folder/Managed_Preferences
profiles=$log_folder/Profiles
recon=$log_folder/Recon

currenttime=$(date +"%D %T")

#clear out previous results
if [ -e $log_folder ] ;then rm -r $log_folder
fi

#create a folder to save all logs
mkdir -p $log_folder/{Results,JSS,Connect,Trust,Protect,Managed_Preferences,Profiles,Recon}

#create a log file for script and save to Not_Found directory so users can see what logs were not gathered
touch $results

#build a jamf helper to notify users that log collection will begin and to send files in to Support when completed
buttonClicked=$(/Library/Application\ Support/JAMF/bin/jamfHelper.app/Contents/MacOS/jamfHelper -windowType utility -icon /Applications/Self\ Service.app/Contents/Resources/AppIcon.icns -title "Jamf Log Grabber" -heading "Jamf Log Grabber" -description "You have been asked to send logs over to your Support Department. Press OK to start the process. When we're done, send the 'Logs' folder we put on your desktop to your Support Department" -button1 "OK" -button2 "Cancel" -defaultButton 1 -cancelButton 2)

if [ $buttonClicked == 0 ]; then
	# Buttion 1 was Clicked
	echo "Script Ran at $currenttime" >> $results
elif [ $buttonClicked == 2 ]; then
	# Buttion 2 was Clicked
	echo "Cancel was clicked at $currenttime" >> $results; else
		exit 
	fi

#add Jamf client log to logs folder
if [ -e /private/var/log/jamf.log ]; then cp "/private/var/log/jamf.log" $JSS 
else
	echo "Jamf Client Logs not found" >> $results
fi

#check for jamf install logs 
if [ -e /var/log/Install.log ]; then cp "/var/log/Install.log" $JSS 
else
	echo "Jamf Install Logs not found" >> $results
fi

#check for jamf system logs 
if [ -e /var/log/system.log ]; then cp "/var/log/system.log" $JSS
else
	echo "Jamf System Logs not found" >> $results
fi

#find and copy jamf software plist, copy, and convert to readable format and copy debug log, not likely to show anything pertinent but kept in just in case
if [ -e /Library/Preferences/com.jamfsoftware.jamf.plist ]; then cp "/Library/Preferences/com.jamfsoftware.jamf.plist" "$JSS/com.jamfsoftware.jamf.plist" | plutil -convert xml1 "$JSS/com.jamfsoftware.jamf.plist" | log show --style compact --predicate 'subsystem == "com.jamfsoftware.jamf"' --debug > "$JSS/Jamfsoftware.log"
else
	echo "Jamf Connect Login plist not found" >> $results
fi

#check for jamf login logs and plist, copy, and convert to readable format
if [ -e /tmp/jamf_login.log ]; then cp "/tmp/jamf_login.log" $connect
else
	echo "Jamf Login /tmp file not found" >> $results
fi

if [ -e /Library/Managed\ Preferences/com.jamf.connect.login.plist ]; then cp "/Library/Managed Preferences/com.jamf.connect.login.plist" "$connect/com.jamf.connect.login_managed.plist" | plutil -convert xml1 "$connect/com.jamf.connect.login_managed.plist" | log show --style compact --predicate 'subsystem == "com.jamf.connect.login"' --debug > "$connect/com.jamf.connect.login.log"
else
	echo "Jamf Connect Login plist not found" >> $results
fi

#check for jamf connect license, copy, decrypt, and convert to readable format
LicensefromLogin=$(defaults read /Library/Managed\ Preferences/com.jamf.connect.login.plist LicenseFile 2>/dev/null)
LicensefromMenubar=$(defaults read /Library/Managed\ Preferences/com.jamf.connect.plist LicenseFile 2>/dev/null)
if [[ "$LicensefromLogin" == "PD94"* ]]; then
	(echo "$LicensefromLogin" | base64 -d) > $connect/license.txt
elif [[ "$LicensefromMenubar" == "PD94"* ]]; then
	(echo "$LicensefromMenubar" | base64 -d) > $connect/license.txt
else
	file=""
fi

#check for jamf connect state plist, copy, and convert to readable format
State_plist=$(defaults read com.jamf.connect.state.plist 2>/dev/null)
if [[ "$State_plist" == "" ]]; then
	echo "A Jamf Connect State list was not found because no user is logged into Menu Bar" >> $results; else cp $HOME/Library/Preferences/com.jamf.connect.state.plist "$connect/com.jamf.connect.state.plist" | plutil -convert xml1 $connect/com.jamf.connect.state.plist
	fi

#check for jamf connect menu bar plist, copy, and convert to readable format
if [ -e /Library/Managed\ Preferences/com.jamf.connect.plist ]; then cp "/Library/Managed Preferences/com.jamf.connect.plist" "$connect/com.jamf.connect_managed.plist" | plutil -convert xml1 "$connect/com.jamf.connect_managed.plist" | log show --style compact --predicate 'subsystem == "com.jamf.connect"' --debug > "$connect/com.jamf.connect.log"
else
	echo "Jamf Connect plist not found" >> $results
fi

#check for kerberos ticket
kerblist=$("klist" 2>/dev/null)
if [[ "$kerblist" == "" ]];then
	echo "No Kerberos Ticket for Current Logged in User" > $connect/klist_manuallyCollected.txt; else
		echo $kerblist > $connect/klist_manuallyCollected.txt
fi

#list authchanger settings
/usr/local/bin/authchanger -print > "$connect/authchanger_manuallyCollected.txt"


#check for jamf protect plist, copy, and convert to readable format
if [ -e /Library/Managed\ Preferences/com.jamf.protect.plist ]; then cp "/Library/Managed Preferences/com.jamf.protect.plist" "$protect/com.jamf.protect.plist" | plutil -convert xml1 "$protect/com.jamf.protect.plist"
else
	echo "Jamf Protect plist not found" >> $results
fi

#check for jamf trust plist, copy, and convert to readable format
if [ -e /Library/Managed\ Preferences/com.jamf.trust.plist ]; then cp "/Library/Managed Preferences/com.jamf.trust.plist" "$trust/com.jamf.trust.plist" | plutil -convert xml1 "$trust/com.jamf.trust.plist"
else
	echo "Jamf Trust plist not found" >> $results
fi

#check for managed preference plists, copy, and convert to readable format
if [ -e /Library/Managed\ Preferences/ ]; then cp /Library/Managed\ Preferences/*.plist $managed_preferences
else
	echo "No Managed Preferences plist files found" >> $results
fi

sleep 5

#Unable to check folder for wildcart plist like *.plist 
#If this section isn't working, find a common plist that is deployed fleet wide like notifications or system extensions and change it in the next line
if [ -e $managed_preferences/com.apple.TCC.configuration-profile-policy.plist ]; then plutil -convert xml1 $HOME/Desktop/Logs/managed_preferences/*.plist
else
	echo "No files to convert to plist" > $results
fi

#checks for files left behind by recon that should have been deleted after completing recon
if [  -f /Library/Application\ Support/JAMF/tmp/*.tmp ]; then
	cp /Library/Application\ Support/JAMF/tmp/*.tmp $recon
else
	echo "No leftover shell scripts found in the recon directory" >> $results
fi


#list all installed user and machine profiles and saves to a .txt file

profiles show > $profiles/User_Installed_Profiles.txt

#remove comment to see machine profiles but requires sudo priveliges 
# sudo profiles show > $profiles/Machine_Installed_Profiles.txt
