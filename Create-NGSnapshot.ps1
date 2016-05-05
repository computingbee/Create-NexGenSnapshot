<#
.SYNOPSIS
Uses ngscli to create and maange NexGen Storage snapshots
.DESCRIPTION
This script relies on NexGen's ngscli which should be installed prior to scheduling this script. To use this 
to create snapshots on NexGen Storage Array, you need to schedule this script using Windows Task Scheduler.
Requires PowerShell v2 or above.

.EXAMPLE
 Create-NexGenSnapshot.ps1 -VolumeName NexGen-LUN_Name -$Snaps2Keep 5
 
 .EXAMPLE
 Create-NexGenSnapshot.ps1 -VolumeName NexGen-LUN_Name -$Snaps2Keep 5 -$IOController <cntlr_ip_addr>
#>
param( 
 [Parameter(Mandatory=$true)] $VolumeName,
 [Parameter(Mandatory=$true)] [ValidateRange(1,99)] [int] $Snaps2Keep,
 $IOController="192.168.1.150"
)

# Update these specific to your envrionment
$IOC=$IOController
$USER="<cntlr_user_login>"
$PASSWD="<cntlr_user_passwd>"
$ngsclilogin = "login=$IOC username=$USER password=$PASSWD" 
$nsgscli = "C:\Program Files (x86)\Fusion-io\ioControl CLI\ngscli.exe"

$errEmailFr="NexGensnaphots@mydomain.com"
$errEmailTo="errors@mydomain.com"
$mailhost = "mail.mydomain.com"


#Helper functions for logging to Windows application log and notifying via email

function Log-Error($errmsg) {  
  
  $result = Get-EventLog -List | Where {$_.LogDisplayName -match "NexGenSnapshots"}
  if ($result -eq $null) {
   New-EventLog -LogName NexGenSnapshots -Source Manage-NexGenSnapshots.ps1
  } 
  Write-Eventlog -LogName NexGenSnapshots -Source Manage-NexGenSnapshots.ps1 -EventID 6500 -Message "$errmsg" -EntryType Error
  
  Send-MailMessage -From $errEmailFr -To $errEmailTo -SmtpServer $mailhost -Subject "NexGen Snapshot Error" -Body $errmsg
}

function Log-Info($msg) {  
  
  $result = Get-EventLog -List | Where {$_.LogDisplayName -match "NexGenSnapshots"}
  if ($result -eq $null) {
   New-EventLog -LogName NexGenSnapshots -Source Manage-NexGenSnapshots.ps1
  } 
  Write-Eventlog -LogName NexGenSnapshots -Source Manage-NexGenSnapshots.ps1 -EventID 6501 -Message "$msg" -EntryType Information
}

# Helper fucntion fo creating anonymous snapshot for a given volume 

function Create-Snapshot($volname) {
 $timestamp=Get-Date -Format "yyyy-MM-dd-hhmmss"
 $snapname = "$volname-$timestamp"
 $takesnap = "takesnapshot $ngsclilogin volumename=$volname snapshotname=$snapname"
 $result = & $nsgscli $takesnap
 $result = $result -join " "
 if ($result -notmatch "success") {
  Log-Error ("Unable to create NexGen snap: $snapname for volume: $volname at $timestamp")
 }
}

# Helper fucntion fo creating named snapshot for a given volume

function Create-SnapshotByName($volname,$snapname) {
 $timestamp=Get-Date -Format "yyyy-MM-dd-hhmmss"
 $takesnap = "takesnapshot $ngsclilogin volumename=$volname snapshotname=$snapname"
 $result = & $nsgscli $takesnap
 $result = $result -join " "
 if ($result -notmatch "success") {
  Log-Error ("Unable to create NexGen snap: $snapname for volume: $volname at $timestamp")
 }
}

# Helper fucntion to delete a snapshot

function Delete-Snapshot($snapname) {
 $timestamp=Get-Date -Format "yyyy-MM-dd-hhmmss"
 $delsnap = "deletesnapshot $ngsclilogin name=$snapname"
 $result = & $nsgscli $delsnap
 $result = $result -join " "
 if ($result -notmatch "success") {
  Log-Error ("Unable to delete NexGen snap: $snapname at $timestamp `n Results: $result")
 }
}

# Helper fucntion to list snapshots for a given colume

function Get-Snapshots($volname) {
 
 $timestamp=Get-Date -Format "yyyy-MM-dd-hhmmss"
 $getsnaps = "getsnapshots $ngsclilogin volumename=$volname"
 $result = & $nsgscli $getsnaps
 if ($($result -join " ") -notmatch "success") {
  Log-Error ("Unable to delete NexGen snap: $snapname at $timestamp `n Results: $result")
 }
 $names = $result -imatch "^Name*"
 $cdates = $result -imatch "^CreateDateTimeGMT*"
 $snaps = @{}
 $idxCDates = 0
 $names | % {
   $name = $(-split $_ )[1]
   $name = $name -replace '"',""
   $cdate = $cdates[$idxCDates++]
   $cdate = $($cdate -replace "CreateDateTimeGMT","") -replace '"',""
   $snaps.Add($name.Trim(),[datetime] $cdate.Trim())
 }
 return ($snaps.GetEnumerator() | sort -Property value)
}

# Do some sanity checks before starting

if (-not $(Test-Path $nsgscli)) {
  Log-Error ("$nsgscli not installed or path is incorrect, exiting...")
  exit
}

# Let's do what user asked for

$snapshots = Get-Snapshots -volname $VolumeName

if($snapshots -ne $null -and $snapshots.GetType() -match "DictionaryEntry" -and $Snaps2Keep -eq 1 ) {
  $snap = $snapshots
  Log-Info ("Found more than $Snaps2Keep snapshots, deleting " + $snap.Name) 
  Delete-Snapshot $snap.Name
}

if($snapshots -ne $null -and $snapshots.Count -ge $Snaps2Keep) { #delete old snaps.
 for ($i=0; $i -le $($snapshots.Count - $Snaps2Keep); $i++) {
  $snap = $snapshots[$i]
  Log-Info ("Found more than $Snaps2Keep snapshots, deleting " + $snap.Name) 
  Delete-Snapshot $snap.Name
 }
}

Create-Snapshot -volname $VolumeName
