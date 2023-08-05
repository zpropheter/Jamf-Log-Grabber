#!/bin/bash

#You can now set variables to collect specific logs, simply comment out any lines you do not want to run
JSS_LOGS=('Collect')
Recon_Troubleshoot=('Collect')
Jamf_Self_Service=('Collect')
Jamf_Connect=('Collect')
Jamf_Protect=('Collect')
Managed_Preferences_Folder=('Collect')
All_Profiles=('Collect')
cleanup=("JSS Recon Self_Service Connect Security Managed_Preferences")


#define variables
log_folder=$HOME/Desktop/Logs
results=$log_folder/Results.txt
JSS=$log_folder/JSS
security=$log_folder/Jamf_Security
connect=$log_folder/Connect
trust=$log_folder/Trust
managed_preferences=$log_folder/Managed_Preferences
profiles=$log_folder/Profiles
recon=$log_folder/Recon
self_service=$log_folder/Self_Service
loggedInUser=$( echo "show State:/Users/ConsoleUser" | /usr/sbin/scutil | /usr/bin/awk '/Name :/ && ! /loginwindow/ { print $3 }' )

currentlogdate=$(date)
currenttime=$(date +"%D %T")

#clear out previous results
if [ -e $log_folder ] ;then rm -r $log_folder
fi

#create a folder to save all logs
mkdir -p $log_folder

#create a log file for script and save to Logs directory so users can see what logs were not gathered
touch $results

#Section for collecting client side JSS Logs
for logfileJSS in "${JSS_LOGS[@]}"
do
	mkdir -p $log_folder/JSS
	#add Jamf client log to logs folder
	if [ -e /private/var/log/jamf.log ]; then cp "/private/var/log/jamf.log" $JSS
	else
		echo "Jamf Client Logs not found" >> $results
	fi
	#check for jamf install logs 
	if [ -e /var/log/install.log ]; then cp "/var/log/install.log" $JSS 
	else
		echo "Install Logs not found" >> $results
	fi
	#check for jamf system logs 
	if [ -e /var/log/system.log ]; then cp "/var/log/system.log" $JSS
	else
		echo "System Logs not found" >> $results
	fi
	#find and copy jamf software plist, copy, and convert to readable format and copy debug log, not likely to show anything pertinent but kept in just in case
	if [ -e /Library/Preferences/com.jamfsoftware.jamf.plist ]; then cp "/Library/Preferences/com.jamfsoftware.jamf.plist" "$JSS/com.jamfsoftware.jamf.plist" | plutil -convert xml1 "$JSS/com.jamfsoftware.jamf.plist" | log show --style compact --predicate 'subsystem == "com.jamfsoftware.jamf"' --debug > "$JSS/Jamfsoftware.log"
	else
		echo "Jamf Connect Login plist not found" >> $results
	fi
done

#Section for collecting Jamf Recon Leftovers
for logfileRecon in "${Recon_Troubleshoot[@]}"
do
	mkdir -p $log_folder/Recon
	#check for Jamf Recon leftovers
	if [  -f /Library/Application\ Support/JAMF/tmp/*.tmp ]; then
		cp /Library/Application\ Support/JAMF/tmp/*.tmp $recon
	else
		echo "No leftover shell scripts found in the recon directory" >> $results
	fi
done

#Section for collecting Jamf Self Service Logs
for logfileSelfService in "${Jamf_Self_Service[@]}"
do
	mkdir -p $log_folder/Self_Service
	#check for jamf self service logs
	if [ -e /$HOME/Library/Logs/JAMF ]; then cp -r "$HOME/Library/Logs/JAMF/" $self_service
	else
		echo "Jamf Self Service Logs not found" >> $results
	fi
done

#Section for collecting Jamf Connect Logs
for logfileJamfConnect in "${Jamf_Connect[@]}"
do
	mkdir -p $log_folder/Connect
	#find and copy jamf software plist, copy, and convert to readable format and copy debug log, not likely to show anything pertinent but kept in just in case
	if [ -e /Library/Preferences/com.jamfsoftware.jamf.plist ]; then cp "/Library/Preferences/com.jamfsoftware.jamf.plist" "$JSS/com.jamfsoftware.jamf.plist" | plutil -convert xml1 "$JSS/com.jamfsoftware.jamf.plist" | log show --style compact --predicate 'subsystem == "com.jamfsoftware.jamf"' --debug > "$JSS/Jamfsoftware.log"
	else
		echo "Jamf Connect Login plist not found" >> $results
	fi
	
	#create a log file for script and save to Logs directory so users can see what logs were not gathered
	touch $results	
	if [ -e /Library/Preferences/com.jamfsoftware.jamf.plist ]; then
		#outputs all historical Jamf connect logs, this will always generate a log file even if Connect is 
		log show --style compact --predicate 'subsystem == "com.jamf.connect"' --debug > $connect/JamfConnect.log
		#outputs all historical Jamf connect login logs
		log show --style compact --predicate 'subsystem == "com.jamf.connect.login"' --debug > $connect/jamfconnect.login.log
		kerberioscheck=$(kerblist=$("klist" 2>/dev/null)
	if [[ "$kerblist" == "" ]];then
		echo "No Kerberos Ticket for Current Logged in User" > $connect/klist_manuallyCollected.txt; else
			echo $kerblist > $connect/klist_manuallyCollected.txt);else
	echo "No Jamf Connect Installed, doing nothing" >> $results
	fi
	
	#check for jamf login logs and plist, copy, and convert to readable format
	if [ -e /tmp/jamf_login.log ]; then cp "/tmp/jamf_login.log" $connect/jamf_login_tmp.log
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
	
	#list authchanger settings
	if [ -e /usr/local/bin/authchanger ]; then
		/usr/local/bin/authchanger -print > "$connect/authchanger_manuallyCollected.txt";else
			echo "No Authchanger settings found" >> $results
		fi
done

#Section for collecting Jamf Self Service Logs
for logfileJamfSecurity in "${Jamf_Protect[@]}"
do
	#make directory for all Jamf Security related files
	mkdir -p $log_folder/Security
	#check for jamf protect plist, copy, and convert to readable format
	if [ -e /Library/Managed\ Preferences/com.jamf.protect.plist ]; then cp "/Library/Managed Preferences/com.jamf.protect.plist" "$protect/com.jamf.protect.plist" | plutil -convert xml1 "$security/com.jamf.protect.plist"
	else
		echo "Jamf Protect plist not found" >> $results
	fi
	
	#check for jamf trust plist, copy, and convert to readable format
	if [ -e /Library/Managed\ Preferences/com.jamf.trust.plist ]; then cp "/Library/Managed Preferences/com.jamf.trust.plist" "$trust/com.jamf.trust.plist" | plutil -convert xml1 "$security/com.jamf.trust.plist"
	else
		echo "Jamf Trust plist not found" >> $results
	fi
done

#Section for collecting Managed Preference Plists
for logfileManagedPreferences in "${Managed_Preferences_Folder[@]}"
do
	mkdir -p $log_folder/Managed_Preferences
	#check for managed preference plists, copy, and convert to readable format
	if [ -e /Library/Managed\ Preferences/ ]; then cp /Library/Managed\ Preferences/*.plist $managed_preferences
	else
		echo "No Managed Preferences plist files found" >> $results
	fi
	#sleep to allow copy to finish processing all files
	sleep 5
	
	#Unable to check folder for wildcart plist like *.plist 
	#If this section isn't working, find a common plist that is deployed fleet wide like notifications or system extensions and change it in the next line
	if [ -e $managed_preferences/com.apple.TCC.configuration-profile-policy.plist ]; then plutil -convert xml1 $HOME/Desktop/Logs/managed_preferences/*.plist
	else
		echo "No files to convert to plist" >> $results
	fi
	#list all installed user and machine profiles and saves to a .txt file
	profiles show > $log_folder/User_Installed_Profiles.txt
	
	#remove comment to see machine profiles but requires sudo priveliges 
	# sudo profiles show > $log_folder/User_Installed_Profiles.txt
done

#cleans out empty folders to avoid confusion
for emptyfolder in $cleanup
do	
if [ -z "$(ls -A /$log_folder/$emptyfolder)" ]; then
	echo "$emptyfolder is Empty removing folder" >>$results | rm -r $log_folder/$emptyfolder
else
	echo "$emptyfolder is Not Empty leaving folder" >>$results
fi
done

zip $HOME/Desktop/"$loggedInUser"_logs_collected_"$currentlogdate".zip -r $log_folder

rm -r $log_folder