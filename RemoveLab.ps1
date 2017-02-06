cls

Import-Module .\LabBuilder.psm1 -Force
Uninstall-Lab -ConfigPath D:\labsetup\Combo-Lab-Setup-Config.xml -labpath d:\labs -Verbose -RemoveVMFolder 
Uninstall-Lab -ConfigPath D:\labsetup\DC-Lab-Setup-Config.xml -labpath d:\labs -Verbose -RemoveSwitch -RemoveVMFolder 