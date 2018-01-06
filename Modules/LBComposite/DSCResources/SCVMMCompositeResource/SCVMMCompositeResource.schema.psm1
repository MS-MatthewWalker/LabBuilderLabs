Configuration SCVMMCompositeResource {
Param(
        # Title for Selection box
        [Parameter(Mandatory=$true, Position=0)]
        [String]$BasePath,

        # Informational Title 
        [Parameter(Mandatory=$true,Position=1)]
        [String]$DomainAdminCredential,

        # Source of choices to import to Selction box.
        [Parameter(Mandatory=$true,Position=2)]
        [String[]]$ListSource

)

    ### Insert composite resource code here
    ### NOTE: Composite resources do not include a NODE block

    Import-DscResource -ModuleName 'PSDesiredStateConfiguration' 
    Import-DscResource -ModuleName xSCVMM
    Import-DscResource -ModuleName SQLServerDsc

    WindowsFeature NET
    {
        Ensure = "Present" 
        Name = "NET-Framework-Core"
        Source = $NetSourcePath 
    }

    $BasePath = $SQLSourcePath
    $SQLServer2012NativeClient = "\Files\SQLNCli.msi"

    Package "SQLServer2012NativeClient"
    {
        Ensure = "Present"
        Name = "Microsoft SQL Server 2012 Native Client "
        ProductId = "49D665A2-4C2A-476E-9AB8-FCC425F526FC"
        Path = "$Basepath$SQLServer2012NativeClient"
        Arguments = "IACCEPTSQLNCLILICENSETERMS=YES ALLUSERS=2"
        Credential = $DomainAdminCredential
        DependsOn = "[xDisk]ToolsDrive"
    }

    $SQLServer2012CommandLineUtilities = "\Files\SQLCmdLnUtils.msi"

    Package "SQLServer2012CommandLineUtilities"
    {
        Ensure = "Present"
        Name = "Microsoft SQL Server 2012 Command Line Utilities "
        ProductId = "9D573E71-1077-4C7E-B4DB-4E22A5D2B48B"
        Path = "$Basepath$SQLServer2012CommandLineUtilities"
        Arguments = "ALLUSERS=2"
        Credential = $DomainAdminCredential
        DependsOn = "[Package]SQLServer2012NativeClient"

    }

    $WindowsADK = '\Files\ADK\adksetup.exe'

    Package "WindowsDeploymentTools"
    {
        Ensure = "Present"
        Name = "Windows Deployment Tools"
        ProductId = ""
        Path = "$Basepath$WindowsADK"
        Arguments = "/quiet /features OptionId.DeploymentTools"
        Credential = $DomainAdminCredential
        DependsOn = "[xDisk]ToolsDrive"
    }

    Package "WindowsPreinstallationEnvironment"
    {
        Ensure = "Present"
        Name = "Windows PE x86 x64"
        ProductId = ""
        Path = "$Basepath$WindowsADK"
        Arguments = "/quiet /features OptionId.WindowsPreinstallationEnvironment"
        Credential = $DomainAdminCredential
        DependsOn = "[xDisk]ToolsDrive"                
    }

    SqlSetup SCVMMSQLDB
    {
        DependsOn = "[WindowsFeature]NET"
        SourcePath = $SQLSourcePath
        SourceFolder = $SQLSourceFolder
        PSDscRunAsCredential = $DomainAdminCredential
        InstanceName = $SQLInstanceName
        Features = $SQLFeatures
        SQLSVCAccount = $SQLSA
        SQLSysAdminAccounts = $SQLSysAdminAccounts
        AgtSvcAccount = $SQLAgentSA
    }


    xSCVMMManagementServerSetup "VMMMS"
    {
        DependsOn = "[xSCVMMConsoleSetup]VMMC"
        Ensure = "Present"
        SourcePath = $SQLSourcePath
        SourceFolder = $SCVMMInstallPath
        SetupCredential = $DomainAdminCredential
        vmmService = $SCVMMSA
        SqlMachineName = $SCVMMDBServerName
        SqlInstanceName = $SQLInstanceName
    }

    xSCVMMConsoleSetup "VMMC"
    {
        DependsOn = "[SqlSetup]SCVMMSQLDB"
        Ensure = "Present"
        SourcePath = $SQLSourcePath
        SourceFolder = $SCVMMInstallPath
        SetupCredential = $DomainAdminCredential
    }



}