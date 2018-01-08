. .\functions.ps1

$Workdir=Get-ScriptDirectory

[xml]$ModuleList = Get-Content -Path $Workdir\configurations\modules.xml
$Modules = $ModuleList.Modules.Module

ForEach ($Module in $Modules)
{
    Write-Output "Downloading Module $($Module.Name)"
    Save-Module -Name $Module.Name -Path $Workdir\Modules -Force
}

