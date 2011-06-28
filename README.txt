Virtual Machine Guest Backup for VMware vSphere Readme

Copyright 2011 Chris Gay

This program is free software: you can redistribute it and/or modify
it under the terms of the GNU General Public License as published by
the Free Software Foundation, either version 3 of the License, or
(at your option) any later version.

This program is distributed in the hope that it will be useful,
but WITHOUT ANY WARRANTY; without even the implied warranty of
MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
GNU General Public License for more details.

You should have received a copy of the GNU General Public License
along with this program.  If not, see <http://www.gnu.org/licenses/>.


Installation:

1. Extract the files from the archive.
2. Setup the Configuration Parameters for your environment.
3. Execute script with Windows Powershell as needed or setup a Scheduled Task.


Configuration Parameters:

$Destination_Path 				- This is the location where the backup will be created. This should either be a local drive or a UNC path. E.g. "\\server\share\VMGB"
						  The backup will store the files at this location under Host Address\Datastore\Host Name. Eg "\\server\share\VMGB\192.168.4.1\ESX_LOCAL\VM Guest"

$Email_Report					- This is used to enable or disable sending email reports. Use 1 to enable or 0 to disable.

$Smtp_Server					- Specify the IP Address of the SMTP server to use to send the email reports. E.g. "192.168.1.1"

$Email_From					- Specify the email address used for the From field of the email reports. E.g. "VMGB <administrator@domain.com.au>"

$Email_To					- Specify the email addresses to send the email reports to. Sepearte multiple email addresses with a comma. E.g. "user@domain.com.au,user2@domain.com.au"

$Email_Subject					- Specify the subject that will be used for the email reports. either ": Unsuccessful" or ": Successful" will be apended to it. E.g. "VM Guest Backup"

$VM_Host[$VM_Host.Count-1].Address		- Specify the IP Address of the VMware vSphere Host or VMware vCenter Server. E.g "192.168.4.1"

$VM_Host[$VM_Host.Count-1].Protocol		- This is used to sepecify the protocol to use when connecting to the VM Host. Use either "http" for a non-secure connection or "https" for a secure connection.

$VM_Host[$VM_Host.Count-1].Username		- Specify a username for an account that has access to create snapshots, remove snapshots, browse datastores and download files on the specified VM Host. E.g. "root"

$VM_Host[$VM_Host.Count-1].Password		- Specify the password for the above account. E.g "password"

$VM_Host[$VM_Host.Count-1].All_guests		- This is used to enable or disable backup of all VM guests on the specified host instead of using the Include_Guests parameter. Set to 1 to enable or 0 to disable.

$VM_Host[$VM_Host.Count-1].Exclude_Guests	- Specify the name of any VM guests on the specified host you want to exclude from the backup.

$VM_Host[$VM_Host.Count-1].Include_Guests	- Specify the VM guests on the specified host you want to include in the backup, seperated by commas. The VM guests will be backed up in the order specified here. This parameter is ignored if All_Guests is set to 1.

$VM_Host[$VM_Host.Count-1].Guests_SS_Name	- Specify the name to use when creating VM guest snapshots.


To include multiple VMware vSphere Hosts and/or VMware vCenter Servers in the backup copy everything between the lines "#Host 1 Configration Parameters START" and "#Host 1 Configration Parameters END" and paste below "#Host 1 Configration Parameters END"

E.g. 

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