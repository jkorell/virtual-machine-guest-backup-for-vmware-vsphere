# Virtual Machine Guest Backup for VMware vSphere
# http://code.google.com/p/virtual-machine-guest-backup-for-vmware-vsphere/
# Version 1.0B
#
# Copyright 2011 Chris Gay
# 
# This program is free software: you can redistribute it and/or modify
# it under the terms of the GNU General Public License as published by
# the Free Software Foundation, either version 3 of the License, or
# (at your option) any later version.
# 
# This program is distributed in the hope that it will be useful,
# but WITHOUT ANY WARRANTY; without even the implied warranty of
# MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
# GNU General Public License for more details.
#
# You should have received a copy of the GNU General Public License
# along with this program.  If not, see <http://www.gnu.org/licenses/>.
#
#
# Description:
# Virtual Machine Guest Backup for VMware vSphere is a Windows Powershell
# script that uses the VMware vSphere PowerCLI snap-in to connect to VMware
# vSphere Hosts and/or VMware vCenter Servers and backup the virtual hard
# disk, configuration and snapshot files for VM Guests without powering them
# down.
#
#
# Requirements:
# - VMware vSphere 4.1 Host (Paid Version)
# - VMware vSphere PowerCLI 4.1 (http://www.vmware.com/support/developer/PowerCLI/index.html)
# - PowerShell 2.0
#
#
# Change Log:
# 28/06/2011 - Initial release, v1.0B



#**************************************************************CONFIGURATION PARAMETERS**************************************************************

#Please see ConfigurationParameters at http://code.google.com/p/virtual-machine-guest-backup-for-vmware-vsphere/
$Destination_Path = ""

#Report email parameters
$Email_Report = 1
$Smtp_Server = ""
$Email_From = ""
$Email_To = ""
$Email_Subject = ""

#VM host(s) parameters
$VM_Host = @() 

#Host Configration Parameters START
$VM_Host += "" | Select Address,Protocol,Username,Password,All_Guests,Exclude_Guests,Include_Guests,Guests_SS_Name
$VM_Host[$VM_Host.Count-1].Address = ""
$VM_Host[$VM_Host.Count-1].Protocol = "https"
$VM_Host[$VM_Host.Count-1].Username = ""
$VM_Host[$VM_Host.Count-1].Password = ""
$VM_Host[$VM_Host.Count-1].All_Guests = 1
$VM_Host[$VM_Host.Count-1].Exclude_Guests = ""
$VM_Host[$VM_Host.Count-1].Include_Guests = ""
$VM_Host[$VM_Host.Count-1].Guests_SS_Name = "BackupDR"
#Host Configration Parameters END

#**************************************************************       FUNCTIONS        **************************************************************

function Email-Report ($CUSTOM_BODY) {
	#Email the report if enabled
	if($Email_Report -eq 1) {		
		#Create the SMTP client connected to the specified SMTP server
		$SMTP = New-Object Net.Mail.SmtpClient($SMTP_SERVER)
		$EMAIL_ADDRESSES = $EMAIL_TO.split(',')
		
		if($ERR -eq 1) {
			#There has been an error, send as unsuccessful with full log
			$SUBJECT = $EMAIL_SUBJECT + ": Unsuccessful"
				if($CUSTOM_BODY.count -gt 0) {
					#Using a custom body for the report email
					$BODY = $CUSTOM_BODY
				}
				else {
					#Load log
					$TMP_BODY = Get-Content $LOG_FILE
					$BODY = ""
					
					#Build body
					foreach($line in $TMP_BODY) {
						$BODY = $BODY + $line + "`r`n"
					}
				}
		}		
		else {
			#There were no errors during the backup procedure, send as successful with the summary only
			$SUBJECT = $EMAIL_SUBJECT + ": Successful"
			
			$BODY = ""
					
			#Build body
			foreach($line in $VMGB_RES) {
				$BODY = $BODY + $line + "`r`n"
			}
		}
		
		#Send email report to each email address
		foreach($ADDRESS in $EMAIL_ADDRESSES) {
			$smtp.Send($EMAIL_FROM, $ADDRESS, $SUBJECT, $BODY)
		}
	}
}


#**************************************************************        SCRIPT         **************************************************************

#Set the screen buffer size to prevent word wrapping in the log
[void]($host.UI.RawUI.BufferSize = new-object System.Management.Automation.Host.Size(1024,3000))

#Start transcription log
$START_DATE = Get-Date

#Create start the log
try {
	$LOG_FILE = ".\VM_Guest_Backup_Log.txt"
	[void](Start-Transcript -Path $LOG_FILE)
}
catch {
	$ERR = 1
	"[" + (get-date -Format "dd/MM/yyyy hh:mm:ss tt") +  "] - (Error) " + $error[0].Exception.Message
	""
	""
	"[" + (get-date -Format "dd/MM/yyyy hh:mm:ss tt") +  "] - Virtual Machine Guest Backup for VMware vSphere Aborted."
	
	#Send email report with custom body
	Email-Report ("[" + (get-date -Format "dd/MM/yyyy hh:mm:ss tt") +  "] - (Error) " + $error[0].Exception.Message)
	
	#End script
	break
}

#Script header info
"VM Guest Backup for VMware vSphere" 
"Version 1.0B"
""
"Copyright 2011 Chris Gay"
""
"This program is free software: you can redistribute it and/or modify"
"it under the terms of the GNU General Public License as published by"
"the Free Software Foundation, either version 3 of the License, or"
"(at your option) any later version."
"" 
"This program is distributed in the hope that it will be useful,"
"but WITHOUT ANY WARRANTY; without even the implied warranty of"
"MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the"
"GNU General Public License for more details."
""
"You should have received a copy of the GNU General Public License"
"along with this program.  If not, see <http://www.gnu.org/licenses/>."
"Show script start message and log path"
""
""
$START_DATE.ToShortDateString() + " " + $START_DATE.ToShortTimeString() + " - Virtual Machine Guest Backup for VMware vSphere Started"
""
""

#Initialize results array
$VMHR = @() 

#Load VMware vSphere PowerCLI Snap-in
"[" + (get-date -Format "dd/MM/yyyy hh:mm:ss tt") +  "] - Loading VMware vSphere PowerCLI Snap-in..."
Add-PSSnapin VMware.VimAutomation.Core -ErrorAction SilentlyContinue

#Map the specified destination path as a Powershell Drive with the name DEST
"[" + (get-date -Format "dd/MM/yyyy hh:mm:ss tt") +  "] - Connecting to Backup Destination ($Destination_Path)..."
try {
	[void](New-PSDrive -Name DEST -PSProvider FileSystem -Root $Destination_Path -ErrorAction Stop) #Creates a PowerShell drive for the desitination path
}
catch {
	$ERR = 1
	"[" + (get-date -Format "dd/MM/yyyy hh:mm:ss tt") +  "] - (Error) " + $error[0].Exception.Message
	""
	""
	"[" + (get-date -Format "dd/MM/yyyy hh:mm:ss tt") +  "] - Virtual Machine Guest Backup for VMware vSphere Aborted."
	[void](Stop-Transcript)
	
	#Remove powershell header and footer from log
	$TMP_FILE = Get-Content $LOG_FILE
	$FILE_END = $TMP_FILE.count - 5
	$TMP_BODY = (Get-Content $LOG_FILE)[6 .. $FILE_END]
	[void](Set-Content -Path $LOG_FILE -Value $TMP_BODY)
		
	#Send report email
	Email-Report
	
	#End script
	break
}


#VM hosts loop
$VM_Host | Foreach { #Host backup loop
	$CONTINUE_HOST = 1
	$FAILURE = 0
	#Intialize variables and get host details and start time
	$VMH = $_
	$VMHR += "" | Select Address,Guests,Start,Finish,Result
	$VMHR[$VMHR.Count-1].Address = $VMH.Address
	$VMHR[$VMHR.Count-1].Guests = @()
	$VMHR[$VMHR.Count-1].Start = Get-Date
	$VMHR[$VMHR.Count-1].Result = "In Progress"
	
	""
	""
	"[" + (get-date -Format "dd/MM/yyyy hh:mm:ss tt") +  "] - Connecting to VMware vSphere Host or vCenter Server " + $VMH.Address + "..."
	
	#Try to connect to the VMware vSphere Host or VMware vCenter Server
	try {
		[void](Connect-VIServer -Protocol $VMH.Protocol -Server $VMH.Address -User $VMH.Username -Password $VMH.Password  -ErrorAction Stop) #Connects to the vSphere Host or vCenter Server specified in the config variables
	}
	catch {
		$CONTINUE_HOST = 0
		$ERR = 1
		
		#Update results
		$VMHR[$VMHR.Count-1].Result = "Failed"
		$VMHR[$VMHR.Count-1].Finish = Get-Date
		
		"[" + (get-date -Format "dd/MM/yyyy hh:mm:ss tt") +  "] - (Error) " + $error[0].Exception.Message
		"[" + (get-date -Format "dd/MM/yyyy hh:mm:ss tt") +  "] - Aborting Backup Procedure for Host @ " + $_.Address + "..."
		""
		""
	}
	
	#Build VM guests array
	if($CONTINUE_HOST -eq 1) {
		"[" + (get-date -Format "dd/MM/yyyy hh:mm:ss tt") +  "] - Building List of VM Guests..."
		
		try {
			#Generate VM guest lists
			if($_.All_Guests -eq 1) {
				#List all VM guests and add them to the VMGS array
				$ALL_VMGS = get-vm  -ErrorAction Stop | Select Name
				$VMGS = @()
				foreach ($VM in $ALL_VMS) {
					$VMGS += $VM.Name
				}
			}	
			else {
				#Add VM guests entered in the include guests array to the VMGS array
				$VMGS = $_.Include_Guests.split(',') 
			}
			
			#Add VM guests to results
			Foreach ($VMG in $VMGS) { 
				if(!($VMH.Exclude_Guests.split(',') -contains $VM)) {
					#VM guest is not in the exclude guests array, add VM guest to results
					$VMHR[$VMHR.Count-1].Guests += "" | Select Name,Files,Start,Finish,Result
					$VMHR[$VMHR.Count-1].Guests[$VMHR[$VMHR.Count-1].Guests.count-1].Name = $VMG
					$VMHR[$VMHR.Count-1].Guests[$VMHR[$VMHR.Count-1].Guests.count-1].Files = @()
				}
			}
		}
		catch {
			$CONTINUE_HOST = 0
			$ERR = 1
			
			#Update results
			$VMHR[$VMHR.Count-1].Result = "Failed"
			$VMHR[$VMHR.Count-1].Finish = Get-Date
			
			"[" + (get-date -Format "dd/MM/yyyy hh:mm:ss tt") +  "] - (Error) " + $error[0].Exception.Message
			"[" + (get-date -Format "dd/MM/yyyy hh:mm:ss tt") +  "] - Aborting Backup Procedure for Host @ " + $_.Address + "..."
			""
			""
		}
	}
	
	
	if($CONTINUE_HOST -eq 1) { 
		Foreach($VMGR in $VMHR[$VMHR.Count-1].Guests) { #VM guest backup loop
			$CONTINUE_GUEST = 1
			$VMGR.Start = Get-Date
			$VMGR.Result = "In Progress"
			""
			"[" + (get-date -Format "dd/MM/yyyy hh:mm:ss tt") +  "] - Starting Backup Procedure For " + $VMGR.Name + "..."
			
			try {
				#Load VM object and view
				$VMGO = Get-VM $VMGR.Name -ErrorAction Stop
				$VMGOV = Get-View $VMGO -ErrorAction Stop
				
				#Build file list
				"[" + (get-date -Format "dd/MM/yyyy hh:mm:ss tt") +  "] - Building List of Files..."
				Foreach ($FILE in $VMGOV.LayoutEx.File) {
					$VMG_FILE = $FILE.Name
					$DS = $VMG_FILE.subString($VMG_FILE.indexOf('[') + 1, $VMG_FILE.indexOf(']') - 1)
					$FP = $VMG_FILE.subString($VMG_FILE.IndexOf(']') + 2)
					$RP = $FP.subString(0, $FP.LastIndexOf('/'))
					$FN = $FP.subString($FP.LastIndexOf('/') + 1)
					
					if($FILE.Type -eq "diskDescriptor") {
						$VMGR.Files += "" | Select Name,Rootpath,Datastore,Size,Start,Finish,Result
						$VMGR.Files[$VMGR.Files.Count-1].Name = $FN
						$VMGR.Files[$VMGR.Files.Count-1].Rootpath = $RP 
						$VMGR.Files[$VMGR.Files.Count-1].Datastore = $DS
						$VMGR.Files[$VMGR.Files.Count-1].Size = $FILE.Size
						$VMGR.Files[$VMGR.Files.Count-1].Result = ""
						
					}
					elseif($FILE.Type -eq "diskExtent") {
						$VMGR.Files += "" | Select Name,Rootpath,Datastore,Size,Start,Finish,Result
						$VMGR.Files[$VMGR.Files.Count-1].Name = $FN
						$VMGR.Files[$VMGR.Files.Count-1].Rootpath = $RP 
						$VMGR.Files[$VMGR.Files.Count-1].Datastore = $DS
						$VMGR.Files[$VMGR.Files.Count-1].Size = $FILE.Size
						$VMGR.Files[$VMGR.Files.Count-1].Result = ""
					}
					elseif($FILE.Type -eq "config") {
						$VMGR.Files += "" | Select Name,Rootpath,Datastore,Size,Start,Finish,Result
						$VMGR.Files[$VMGR.Files.Count-1].Name = $FN
						$VMGR.Files[$VMGR.Files.Count-1].Rootpath = $RP 
						$VMGR.Files[$VMGR.Files.Count-1].Datastore = $DS
						$VMGR.Files[$VMGR.Files.Count-1].Size = $FILE.Size
						$VMGR.Files[$VMGR.Files.Count-1].Result = ""
					}
					elseif($FILE.Type -eq "extendedConfig") {
						$VMGR.Files += "" | Select Name,Rootpath,Datastore,Size,Start,Finish,Result
						$VMGR.Files[$VMGR.Files.Count-1].Name = $FN
						$VMGR.Files[$VMGR.Files.Count-1].Rootpath = $RP 
						$VMGR.Files[$VMGR.Files.Count-1].Datastore = $DS
						$VMGR.Files[$VMGR.Files.Count-1].Size = $FILE.Size
						$VMGR.Files[$VMGR.Files.Count-1].Result = ""
					}
					elseif($FILE.Type -eq "snapshotData") {
						$VMGR.Files += "" | Select Name,Rootpath,Datastore,Size,Start,Finish,Result
						$VMGR.Files[$VMGR.Files.Count-1].Name = $FN
						$VMGR.Files[$VMGR.Files.Count-1].Rootpath = $RP 
						$VMGR.Files[$VMGR.Files.Count-1].Datastore = $DS
						$VMGR.Files[$VMGR.Files.Count-1].Size = $FILE.Size
						$VMGR.Files[$VMGR.Files.Count-1].Result = ""
					}
					elseif($FILE.Type -eq "snapshotList") {
						$VMGR.Files += "" | Select Name,Rootpath,Datastore,Size,Start,Finish,Result
						$VMGR.Files[$VMGR.Files.Count-1].Name = $FN
						$VMGR.Files[$VMGR.Files.Count-1].Rootpath = $RP 
						$VMGR.Files[$VMGR.Files.Count-1].Datastore = $DS
						$VMGR.Files[$VMGR.Files.Count-1].Size = $FILE.Size
						$VMGR.Files[$VMGR.Files.Count-1].Result = ""
					}
				}
			}
			catch {
				$CONTINUE_GUEST = 0
				$ERR = 1
				#Set host failure flag
				$FAILURE = 1
				
				#Update results
				$VMGR.Result = "Failed"
				$VMGR.Finish = Get-Date
				"[" + (get-date -Format "dd/MM/yyyy hh:mm:ss tt") +  "] - (Error) " + $error[0].Exception.Message
				"[" + (get-date -Format "dd/MM/yyyy hh:mm:ss tt") +  "] - Aborting Backup Procedure for VM Guest " + $VMGR.Name + "..."
				""
			}
			
			if($CONTINUE_GUEST -eq 1) { 
				#Create snapshot if the VM guest is powered on
				
				if($VMGO.PowerState -eq "PoweredOn") {
					try {
						"[" + (get-date -Format "dd/MM/yyyy hh:mm:ss tt") +  "] - Creating Snapshot..."
						""
						[void]($VMGO | New-Snapshot -Name $VMH.Guests_SS_Name -ErrorAction Stop)
						$VMG_SS_CREATED = 1
					}
					catch {
						$CONTINUE_GUEST = 0
						
						#Set host failure flag
						$FAILURE = 1
						$VMGR.Finish = Get-Date
						#Update results
						$VMGR.Result = "Failed"
						
						"[" + (get-date -Format "dd/MM/yyyy hh:mm:ss tt") +  "] - (Error) " + $error[0].Exception.Message
						"[" + (get-date -Format "dd/MM/yyyy hh:mm:ss tt") +  "] - Aborting Backup Procedure for VM Guest " + $VMGR.Name + "..."
						""
					}
				}
				else {
					#Create no snapshot
					$VMG_SS_CREATED = 0
				}
				
			}
			
			
			if($CONTINUE_GUEST -eq 1) { 
				#File backup loop start
				Foreach ($VMGRF in $VMGR.Files) {
					$CONTINUE_FILE = 1
					$VMGRF.Start = Get-Date
					$VMGRF.Result = "In Progress"
					"[" + (get-date -Format "dd/MM/yyyy hh:mm:ss tt") +  "] - Started Backup of " +  $VMGRF.Name + "..."
					
					try {
						#Construct destination path and check if it exists
						$DFP = $VMHR[$VMHR.Count-1].Address + "\" + $VMGRF.Datastore + "\" + $VMGRF.Rootpath
						$DFPN = $VMHR[$VMHR.Count-1].Address + "\" + $VMGRF.Datastore + "\" + $VMGRF.Rootpath + "\" + $VMGRF.Name
						$SFPN = $VMGRF.Rootpath + "\" + $VMGRF.Name
						if(!(Test-Path DEST:$DFP)) {
							#Directory does not exist, make it
							[void](mkdir DEST:$DFP)
						}
						
						#Get datastore object
						$DS = Get-Datastore -Name $VMGRF.Datastore -ErrorAction Stop
						
						#Map the datastore as a Powershell Drive
						[void](New-PSDrive -Location $DS -Root '/' -Name SRC -PSProvider VimDatastore)
						
						#Copy the file
						Copy-DatastoreItem SRC:\$SFPN  -Destination DEST:\$DFPN -Force -ErrorAction Stop
						
						#Remove Powershell Drive
						[void](Remove-PSDrive -Name SRC)
						
						#Set file finished date
						$VMGRF.Finish = Get-Date
					}
					catch {
						$CONTINUE_FILE = 0
						$ERR = 1
						#Set host failure flag
						$FAILURE = 1
						$VMGRF.Finish = Get-Date
						#Update results
						$VMGRF.Result = "Failed"
						
						#Set file finished date
						$VMGRF.Finish = Get-Date
						$FILE_TOTAL_TIME = $VMGRF.Finish - $VMGRF.Start
						"[" + (get-date -Format "dd/MM/yyyy hh:mm:ss tt") +  "] - (Error) " + $error[0].Exception.Message
						"[" + (get-date -Format "dd/MM/yyyy hh:mm:ss tt") +  "] - Aborting Backup of " + $VMGRF.Name + " after " + ("{0:D2}" -f $FILE_TOTAL_TIME.Days) + ":" + ("{0:D2}" -f $FILE_TOTAL_TIME.Hours) + ":" + ("{0:D2}" -f $FILE_TOTAL_TIME.Minutes) + ":" + ("{0:D2}" -f $FILE_TOTAL_TIME.Seconds)  + "..."
					}
					
					if($CONTINUE_FILE -eq 1) {
						#Set file result
						$VMGRF.Result = "Completed Successfully"
						#Set file finished date
						$FILE_TOTAL_TIME = $VMGRF.Finish - $VMGRF.Start
						"[" + (get-date -Format "dd/MM/yyyy hh:mm:ss tt") +  "] - Completed Backup of " + $VMGRF.Name + " in " + ("{0:D2}" -f $FILE_TOTAL_TIME.Days) + ":" + ("{0:D2}" -f $FILE_TOTAL_TIME.Hours) + ":" + ("{0:D2}" -f $FILE_TOTAL_TIME.Minutes) + ":" + ("{0:D2}" -f $FILE_TOTAL_TIME.Seconds) 
					}
				}#File backup loop end
			}
			
			if($CONTINUE_GUEST -eq 1) {
				#Remove snapshot if it was created
				if($VMG_SS_CREATED -eq 1) {
					try {
						""
						"[" + (get-date -Format "dd/MM/yyyy hh:mm:ss tt") +  "] - Removing Snapshot..."
						[void]($VMGO | Get-Snapshot -Name $VMH.Guests_SS_Name -ErrorAction Stop | Remove-Snapshot -Confirm:$False -ErrorAction Stop)
					}
					catch {
						$FAILURE = 1
						""
						"[" + (get-date -Format "dd/MM/yyyy hh:mm:ss tt") +  "] - (Error) " + $error[0].Exception.Message
					}
				}
								
				#Set VM guest finished date
				$VMGR.Finish = Get-Date
				$VMGR_TOTAL_TIME = $VMGR.Finish - $VMGR.Start
				#Set result for guest
				if($FAILURE -eq 1) {
					#There was one or more failures
					$VMGR.Result = "Completed With Failures"
					"[" + (get-date -Format "dd/MM/yyyy hh:mm:ss tt") +  "] - Completed Backup Procedure for Guest " + $VMGR.Name + " in " + ("{0:D2}" -f $VMGR_TOTAL_TIME.Days) + ":" + ("{0:D2}" -f $VMGR_TOTAL_TIME.Hours) + ":" + ("{0:D2}" -f $VMGR_TOTAL_TIME.Minutes) + ":" + ("{0:D2}" -f $VMGR_TOTAL_TIME.Seconds) + " With Failures"
				}
				else {
					$VMGR.Result = "Completed Successfully"
					"[" + (get-date -Format "dd/MM/yyyy hh:mm:ss tt") +  "] - Completed Backup Procedure for Guest " + $VMGR.Name + " in " + ("{0:D2}" -f $VMGR_TOTAL_TIME.Days) + ":" + ("{0:D2}" -f $VMGR_TOTAL_TIME.Hours) + ":" + ("{0:D2}" -f $VMGR_TOTAL_TIME.Minutes) + ":" + ("{0:D2}" -f $VMGR_TOTAL_TIME.Seconds) + " Successfully"
				}
			}
		} #VM guest backup loop end
	}
	
	if($CONTINUE_HOST -eq 1) {
		#Set and show result for VM host
		$VMHR[$VMHR.Count-1].Finish = Get-Date
		
		$VMH_TOTAL_TIME = $VMHR[$VMHR.Count-1].Finish - $VMHR[$VMHR.Count-1].Start
		
		if($FAILURE -eq 1) {
			#There was one or more failures during the backup procedure for this host
			$VMHR[$VMHR.Count-1].Result = "Completed With Failures"
			""
			"[" + (get-date -Format "dd/MM/yyyy hh:mm:ss tt") +  "] - Completed Backup Procedure for Host @ " + $VMHR[$VMHR.Count-1].Address + " in " + ("{0:D2}" -f $VMH_TOTAL_TIME.Days) + ":" + ("{0:D2}" -f $VMH_TOTAL_TIME.Hours) + ":" + ("{0:D2}" -f $VMH_TOTAL_TIME.Minutes) + ":" + ("{0:D2}" -f $VMH_TOTAL_TIME.Seconds) + " With Failures"
		}
		else {
			#There were no failures during the backup procedure for this host
			$VMHR[$VMHR.Count-1].Result = "Completed Successfully"
			""
			"[" + (get-date -Format "dd/MM/yyyy hh:mm:ss tt") +  "] - Completed Backup Procedure for Host @ " + $VMHR[$VMHR.Count-1].Address + " in " + ("{0:D2}" -f $VMH_TOTAL_TIME.Days) + ":" + ("{0:D2}" -f $VMH_TOTAL_TIME.Hours) + ":" + ("{0:D2}" -f $VMH_TOTAL_TIME.Minutes) + ":" + ("{0:D2}" -f $VMH_TOTAL_TIME.Seconds) + " Successfully"
			
		}
	}
} #VM backup loop end

#Remove destination Powershell Drive
[void](Remove-PSDrive -Name DEST)

#Set end date
$END_DATE = Get-Date
$TOTAL_TIME = $END_DATE - $START_DATE
""
""
if($FAILUER -eq 1) {
	"[" + (get-date -Format "dd/MM/yyyy hh:mm:ss tt") +  "] - Completed Backup Procedure for all Hosts and Guests in " + ("{0:D2}" -f $TOTAL_TIME.Days) + ":" + ("{0:D2}" -f $TOTAL_TIME.Hours) + ":" + ("{0:D2}" -f $TOTAL_TIME.Minutes) + ":" + ("{0:D2}" -f $TOTAL_TIME.Seconds) + " With Failures"
	""
	""
}
else {
	"[" + (get-date -Format "dd/MM/yyyy hh:mm:ss tt") +  "] - Completed Backup Procedure for all Hosts and Guests in " + ("{0:D2}" -f $TOTAL_TIME.Days) + ":" + ("{0:D2}" -f $TOTAL_TIME.Hours) + ":" + ("{0:D2}" -f $TOTAL_TIME.Minutes) + ":" + ("{0:D2}" -f $TOTAL_TIME.Seconds)  + " Successfully"
	""
	""
}

#Initialize Summary Results Array 
$VMGB_RES = @()

#Generate result summary
$VMGB_RES += "[Backup Summary]"
$VMGB_RES += ""

Foreach ($VMH_RES in $VMHR) {
		$VMGB_RES += ""
		$VMH_TOTAL_TIME = $VMH_RES.Finish - $VMH_RES.Start
		$VMGB_RES += $VMH_RES.Address + " - " + $VMH_RES.Result 
		
		foreach ($VMG_RES in $VMH_RES.Guests) { 
			$VMG_TOTAL_TIME = [void]($VMG_RES.Finish - $VMG_RES.Start)
			$VMGB_RES += "    >  " + $VMG_RES.Name + " - " + $VMG_RES.Result
			
			foreach ($VMGF_RES in $VMG_RES.Files) {
				[void]($VMGF_TOTAL_TIME = $VMGF_RES.Finish - $VMGF_RES.Start)
				
				#Add file size to total data backed up size if it didn't fail
				if(!($VMGF_RES.Result -eq "Failed")) {
					$TOTAL_SIZE = $TOTAL_SIZE + $VMGF_RES.Size
				}
				
				#Format the file size
				if(!([int]($VMGF_RES.Size / 1GB) -eq 0)) {
					$SIZE = ($VMGF_RES.Size / 1GB) 
					$SIZE = ("{0:N2}" -f $SIZE)
					$SIZE_TYPE = " GB"
				}
				elseif(!([int]($VMGF_RES.Size / 1MB) -eq 0)) {
					$SIZE = ($VMGF_RES.Size / 1MB)
					$SIZE = ("{0:N2}" -f $SIZE)
					$SIZE_TYPE = " MB"
				}
				elseif(!([int]($VMGF_RES.Size / 1KB) -eq 0)) {
					$SIZE = ($VMGF_RES.Size / 1KB)
					$SIZE = ("{0:N2}" -f $SIZE)
					$SIZE_TYPE = " KB"
				}
				
				$VMGB_RES += "        *  " + $VMGF_RES.Name + " (" + $SIZE + $SIZE_TYPE + ")"
			}
			$VMGB_RES += ""
		}
		$VMGB_RES += ""
}

$VMGB_RES += ""
$VMGB_RES += "Backup Started: " + $START_DATE.ToString("dd/MM/yyyy hh:mm:ss tt")
$VMGB_RES += "Backup Finished: " + $END_DATE.ToString("dd/MM/yyyy hh:mm:ss tt")
$VMGB_RES += ""
$VMGB_RES += "Total Running Time: " + ("{0:D2}" -f $TOTAL_TIME.Days) + ":" + ("{0:D2}" -f $TOTAL_TIME.Hours) + ":" + ("{0:D2}" -f $TOTAL_TIME.Minutes) + ":" + ("{0:D2}" -f $TOTAL_TIME.Seconds)
$VMGB_RES += "Total Data Backed Up: " + ("{0:N2}" -f ($TOTAL_SIZE / 1GB)) + " GB"
$VMGB_RES += ""
$VMGB_RES += "Backup Destination: " + $Destination_Path
$VMGB_RES 

[void](Stop-Transcript)

#Remove powershell header and footer from log
$TMP_FILE = Get-Content $LOG_FILE
$FILE_END = $TMP_FILE.count - 5
$TMP_BODY = (Get-Content $LOG_FILE)[6 .. $FILE_END]
[void](Set-Content -Path $LOG_FILE -Value $TMP_BODY)

#Send report email
Email-Report