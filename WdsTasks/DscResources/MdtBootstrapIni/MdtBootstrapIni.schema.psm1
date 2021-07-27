<#
    .DESCRIPTION
        This DSC configuration enables configuration and lifecycle management of the BootStrap.ini in MDT.
#>
#Requires -Module cMDTBuildLab

configuration MdtBootstrapIni
{
    param (
        [Parameter(Mandatory)]
        [ValidateNotNullOrEmpty()]
        [System.String]
        $Path,

        [Parameter()]
        [ValidateSet('Present', 'Absent')]
        [System.String]
        $Ensure,

        [Parameter()]
        [System.String]
        $Content
        
    )

    Import-DscResource -ModuleName cMDTBuildLab


    # if not specified, ensure 'Present'
    if ( $null -eq $Ensure )
    {
        Ensure = 'Present'
    }

    # create resource for MDT Bootstrap.ini
    cMDTBuildBootstrapIni AddMdtBootstrapIni
    {
        Ensure  = $Ensure
        Path    = $Path
        Content = @"
$($Content)
"@
    }
}