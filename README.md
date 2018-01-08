# LabBuilderLabs
Config files and support scripts for LabBuilder

You will need to download the Eval copies of Windows Server 2016, Windows Server 2012 R2 as well as updates related to them.  If you want to configure a Windows 10 system as a management host, you will also need an ISO for that as well.  If you are evaluating System Center VMM, then you will need the files for SQL 2014 SP2 (doesn't work with 2016 at this time) as well as the System center files.

For SCVMM you will also need the Assessment and Deployment Kit available at https://developer.microsoft.com/en-us/windows/hardware/windows-assessment-deployment-kit

All of operating system, SQL, and system center ISOs or install files are available via the Eval Center at https://www.microsoft.com/en-us/evalcenter/

For Windows Server 2016 you will need two updates as of December 2017.

The first is KB 4035631, the article with the link to download from the update catalog is https://support.microsoft.com/en-us/kb/4035631

The second is KB 4038782, the article with the link to download from the update catalog is https://support.microsoft.com/en-us/kb/4038782

Windows Server 2012 R2 is a bit more complex, as it may require a lot more updates.

I personally created a custom ISO that has a version of 2012 R2 that is patched up to June 26, 2016, there are numerous references that can be found through web searches if you want to create your own image. 

Configuration assumes that all needed updates will be in Resources folder

Most DSC modules can be downloaded from the PowerShell gallery, however a few like the xSCVMM module must be used from the LabBuilderLabs repository due to changes that have not been propagated yet or are not acceptable based on current format.

All required DSC resources can be downloaded using the DownloadModules.ps1 from LabBuilderLabs repository.

In order to have current help files available for PowerShell modules you will need to download them and save them in the Tools Folder.