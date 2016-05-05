#### A generic PowerShell wrapper for creating and scheduling NexGen Storage snapshots

This script relies on NexGen's ngscli which should be installed prior to running this script. 

I wrote this interface to schedule snapshots on our NexGen arrays since the firmware at the time didn't have a web interface for scheduling snapshots and we were only provided with this CLI tool. 

This software comes with absolutely no warranty and use it at your own risk. I don't represent NexGen Storage and have no association with them whatsoever other than being a customer. I take no responsiblty for anything. 

I am publishing this work to make it easier for others who need scheduling functionality for snapshots on their NexGen array.

This was tested with N5-150 arrays only. 

#### Examples
```sh
Create-NexGenSnapshot.ps1 -VolumeName NexGen-LUN_Name -$Snaps2Keep 5
 
Create-NexGenSnapshot.ps1 -VolumeName NexGen-LUN_Name -$Snaps2Keep 5 -$IOController <cntlr_ip_addr>
```

#### Software & Hardware Requirements
```sh
PowerShell v2 or newer, NexGen CLI tool (ngscli)
```

#### Usage
```sh
To use this to create snapshots on NexGen Storage Array, you need to schedule this script using Windows Task Scheduler.
Requires PowerShell v2 or above.  Create a new task and run the commands as shown in the examples above. You can use this wrapper to schedule daily, weekly, hourly snapshots, etc. 

```
