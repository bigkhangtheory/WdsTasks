<#
    .DESCRIPTION
        This DSC configuration enables the management of MDT persistent drives on a target node.
#>
#Requires -Module cMDTBuildLab


configuration MdtDeploymentShare
{
    param 
    (
        [Parameter(Mandatory)]
        [System.Collections.Hashtable]
        $PersistentDrive,

        [Parameter()]
        [ValidateNotNullOrEmpty()]
        [System.Collections.Hashtable]
        $BootImage
    )

    <#
        Import required module
    #>
    Import-DscResource -ModuleName cMDTBuildLab


    # must specify path for MDT drive
    if ([String]::IsNullOrWhiteSpace($PersistentDrive.Path))
    {
        throw 'ERROR: Must specify path for MDT drive.'
    }

    # store ShareName
    $shareName = $PersistentDrive.ShareName
    $PersistentDrive.Remove('ShareName')

    # remove case sensitivity for ordered Dictionary or Hashtable
    $PersistentDrive = @{ } + $PersistentDrive

    <#
    # if not specified, set MDT drive name to default
    if ([String]::IsNullOrWhiteSpace($PersistentDrive.Name))
    {
        $PersistentDrive.Name = 'DS001'
    }

    # if not specified, set default Description
    if ([String]::IsNullOrWhiteSpace($PersistentDrive.Description))
    {
        $PersistentDrive.Description = 'MDT Deployment Share'
    }

    # if not specified, set default MDT share name
    if ([String]::IsNullOrWhiteSpace($PersistentDrive.ShareName))
    {
        $PersistentDrive.ShareName = 'DeploymentShare$'
    }

    # if not specified, ensure 'Present'
    if ([String]::IsNullOrWhiteSpace($PersistentDrive.Ensure))
    {
        $PersistentDrive.Ensure = 'Present'
    }
    #>

    # create the Network Path name using the target node
    $networkPath = '\\{0}\{1}' -f $node.Name, $shareName

    $PersistentDrive.NetworkPath = $networkPath

    # create execution name for the resource
    $executionName = "$($PersistentDrive.Name -replace '[-().:\s]', '_')_$($shareName -replace '[-().:\s$]', '_')"

    # create DSC resource
    $Splatting = @{
        ResourceName  = 'cMDTBuildPersistentDrive'
        ExecutionName = $executionName
        Properties    = $PersistentDrive
        NoInvoke      = $true
    }
    (Get-DscSplattedResource @Splatting).Invoke($PersistentDrive)

    # set variable to call resource dependency
    $dependsOnMdtPersistentDrive = "[cMDTBuildPersistentDrive]$executionName"


    <#
        If specified, create DSC resource for MDT boot image
    #>
    if ($BootImage)
    {
        # remove case sensitivity for ordered dictionary or hashtables
        $BootImage = @{ } + $BootImage

        # append name of MDT drive
        $BootImage.PSDeploymentShare = $PersistentDrive.Name

        # append MDT path
        $BootImage.PSDrivePath = $PersistentDrive.Path
        
        # enable x64 boot image
        $BootImage.CreateISOx64 = $true

        # this resource depends on MDT persistent drive
        $BootImage.DependsOn = $dependsOnMdtPersistentDrive

        # create execution name for the resource
        $executionName = "$($BootImage.Version -replace '[-().:\s]', '_')"

        # create DSC resource
        $Splatting = @{
            ResourceName  = 'cMDTBuildUpdateBootImage'
            ExecutionName = $executionName
            Properties    = $BootImage
            NoInvoke      = $true
        }
        (Get-DscSplattedResource @Splatting).Invoke($BootImage)
    } #end if
} #end configuration