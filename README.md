# LabBuilderLabs
Config files and support scripts for LabBuilder

You will need to download the Eval copies of Windows Server 2016, Windows Server 2012 R2 as well as updates related to them.  If you want to configure a Windows 10 system as a management host, you will also need an ISO for that as well.  If you are evaluating System Center VMM, then you will need the files for SQL 2014 SP2 (haven't tested with 2016 yet) as well as the System center files. 

For SCVMM you will also need the Assessment and Deployment Kit available at https://developer.microsoft.com/en-us/windows/hardware/windows-assessment-deployment-kit 

In addition to make the Windows 10 host a management system you will need the Remote Server Administration tools from https://www.microsoft.com/en-us/download/details.aspx?id=45520

All of operating system, SQL, and system center ISOs or install files are available via the Eval Center at https://www.microsoft.com/en-us/evalcenter/

For Windows Server 2016 you will need two updates as of Oct 8, 2016.

The first is KB 3176936, the article with the link to download from the update catalog is https://support.microsoft.com/en-us/kb/3176936

The second is KB 3192366, the article with the link to download from the update catalog is https://support.microsoft.com/en-us/kb/3192366


Windows Server 2012 R2 is a bit more complex, as it may require a lot more updates, Microsoft is currently updating the servicing process to reduce the total number of updates, but this has not been completed at the time of this writing. 

I personally created a custom ISO that has a version of 2012 R2 that is patched up to June 26, 2016, there are numerous references that can be found through web searches if you want to create your own image. 

Configuration assumes that all needed updates will be in Resources folder

If the updates or files can be downloaded from a MS download site without needing a login, or registration the files will be automatically downloaded.

Most DSC modules can be downloaded from the PowerShell gallery, however a few like the xSCVMM module must be used from the LabBuilderLabs repository due to changes that have not been propagated yet or are not acceptable based on current format. 

All required DSC resources are part of the LabBuilderLabs repository 