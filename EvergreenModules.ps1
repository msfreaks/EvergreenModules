<#PSScriptInfo

.VERSION 2101.1

.GUID 0f309416-1337-43d0-93dd-f44988136fe8

.AUTHOR Arjan Mensch

.COMPANYNAME IT-WorXX

.TAGS Modules  Evergreen Automation

.LICENSEURI https://github.com/msfreaks/EvergreenModules/blob/main/LICENSE

.PROJECTURI https://github.com/msfreaks/EvergreenModules

.DESCRIPTION
 Script to automatically update your installed PowerShell modules.
 Optionally keep old versions or process Preview versions.

#> 

<#
.SYNOPSIS
 Script to automatically update your installed PowerShell modules.

.DESCRIPTION
 Script to automatically update your installed PowerShell modules.
 Optionally keep old versions or process Preview versions.

.PARAMETER Include
 Optionally scopes the update process to one or more module names.
 If more than one module name need to be included, pass in an array of strings.
 Supports '*' wildcard.
 
.PARAMETER Exclude
 Optionally provide one or more module names to exclude from the update process.
 If more than one module name need to be excluded, pass in an array of strings.
 Supports '*' wildcard.

.PARAMETER IncludePreview
 Preview versions for modules are not processed by default.
 Use this switch parameter to include preview versions in the update process.
 This checks for modules that have '-preview' in their Version attributes.

.PARAMETER KeepVersions
 If used this switch ensures the script will not uninstall older versions if a new version is found and installed.

.PARAMETER ReportOnly
 If used this switch ensures no modules are updated but available updates are reported.

.EXAMPLE
 .\EvergreenModules.ps1
 Updates all installed PowerShell modules (excluding those that have '-preview' in their Version attribute).

.EXAMPLE
 .\EvergreenModules.ps1 -IncludePreview
 Updates all installed PowerShell modules, including those that have '-preview' in their Version attribute.

.EXAMPLE
 .\EvergreenModules.ps1 -ReportOnly
 Reports all available updates for all installed PowerShell modules, excluding modules that have '-preview' in their Version attribute.

.EXAMPLE
 .\EvergreenModules.ps1 -Include @('Az', 'Microsoft*') -Exclude 'Microsoft.Graph.Intune'
 Only updates the 'Az' module and modules starting with 'Microsoft', except the module 'Microsoft.Graph.Intune'

.LINK
 https://github.com/msfreaks/EvergreenModules
 https://msfreaks.wordpress.com

#>
[CmdletBinding()]
param(
    [Parameter(Mandatory = $false, Position = 0)]
    [String[]] $Include,
    [Parameter(Mandatory = $false, Position = 1)]
    [String[]] $Exclude,
    [Parameter(Mandatory = $false, Position = 2)]
    [switch] $IncludePreview,
    [Parameter(Mandatory = $false, Position = 3)]
    [switch] $KeepVersions,
    [Parameter(Mandatory = $false, Position = 4)]
    [switch] $ReportOnly
)

#region Functions

function Update-PowerShellModule {
    [CmdletBinding()]
    param(
        [PSCustomObject[]] $Module,
        [PSCustomObject] $ModuleOnline,
        [switch] $KeepVersions,
        [switch] $ReportOnly
    )

    Write-Verbose -Message ('Module version: {0}' -f $Module[0].Version)
    Write-Verbose -Message ('Online version: {0}' -f $ModuleOnline.Version)
    Write-Verbose -Message ('KeepVersions:   {0}' -f $KeepVersions)
    Write-Verbose -Message ('ReportOnly:     {0}' -f $ReportOnly)
    
    if ($Module[0].Version -eq $ModuleOnline.Version) {
        Write-Host ('{0} - {1}: Newest version already installed.' -f $Module[0].Name, $Module[0].Version) -ForegroundColor Green
    } else {
        Write-Host ('{0} - {1}: Newer version available: {2}.' -f $Module[0].Name, $Module[0].Version, $ModuleOnline.Version) -ForegroundColor Cyan
        if (-not $ReportOnly) {
            Write-Host ('{0} - {1}: Updating to {2}' -f $Module[0].Name, $Module[0].Version, $ModuleOnline.Version) -ForegroundColor Cyan
            Update-Module -Name $Module[0].Name -Force
        }

        $Module | ForEach-Object {
            if (-not $ReportOnly -and -not $KeepVersions) {
                Write-Host ('{0} - {1}: Uninstalling {2}' -f $Module[0].Name, $ModuleOnline.Version, $Module[0].Version) -ForegroundColor Cyan
                $_ | Uninstall-Module -Force
            }
        }
    }
}
#endregion

# build module array
$modules = $null

# process includes
$Include | ForEach-Object { 
    $current = $_
    Write-Verbose -Message ('Including "{0}"' -f $current)
    $modules += Get-InstalledModule | Where-Object { $_.Name -like $current }
}
if (-not $modules) { $modules = Get-InstalledModule }

# process excludes
$Exclude | ForEach-Object {
    $current = $_
    Write-Verbose -Message ('Excluding "{0}"' -f $current)
    $modules = $modules | Where-Object { $_.Name -notlike $current }
}

# process module array
($modules | Sort-Object Name) | ForEach-Object {
    $module  = Get-InstalledModule -Name $_.Name -AllVersions | Where-Object { $_.Version -notlike '*-preview' } | Sort-Object Version -Descending
    $moduleOnline  = Find-Module -Name $_.Name

    Update-PowerShellModule -Module $module -ModuleOnline $moduleOnline -KeepVersions:$KeepVersions -ReportOnly:$ReportOnly

    if ($IncludePreview) {
        $preview = Get-InstalledModule -Name $_.Name -AllVersions | Where-Object { $_.Version -like '*-preview' } | Sort-Object Version -Descending
        if ($preview) { 
            $previewOnline = Find-Module -Name $_.Name -AllowPrerelease

            Update-PowerShellModule -Module $preview -ModuleOnline $previewOnline -KeepVersions:$KeepVersions -ReportOnly:$ReportOnly
        }
    }
}
