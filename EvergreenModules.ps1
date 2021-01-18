<#PSScriptInfo

.VERSION 2101.4

.GUID 0f309416-1337-43d0-93dd-f44988136fe8

.AUTHOR Arjan Mensch

.COMPANYNAME IT-WorXX

.TAGS Modules Evergreen Automation

.LICENSEURI https://github.com/msfreaks/EvergreenModules/blob/main/LICENSE

.PROJECTURI https://github.com/msfreaks/EvergreenModules

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

#Requires -Modules @{ ModuleName="PowerShellGet"; ModuleVersion="2.2.4.1" }
#Requires -Version 5.1
#Requires -RunAsAdministrator

[CmdletBinding(SupportsShouldProcess)]
param(
    [Parameter(Mandatory = $false, Position = 0)]
    [String[]] $Include = @(),
    [Parameter(Mandatory = $false, Position = 1)]
    [String[]] $Exclude = @(),
    [Parameter(Mandatory = $false, Position = 2)]
    [switch] $IncludePreview,
    [Parameter(Mandatory = $false, Position = 3)]
    [switch] $KeepVersions,
    [Parameter(Mandatory = $false, Position = 4)]
    [switch] $ReportOnly
)

Write-Verbose -Message ('Include:        {0}' -f ($Include -join ','))
Write-Verbose -Message ('Exclude:        {0}' -f ($Exclude -join ','))
Write-Verbose -Message ('IncludePreview: {0}' -f $IncludePreview)
Write-Verbose -Message ('KeepVersions:   {0}' -f $KeepVersions)
Write-Verbose -Message ('ReportOnly:     {0}' -f $ReportOnly)

#region Functions

function Update-PowerShellModule {
    [CmdletBinding(SupportsShouldProcess)]
    param(
        [Parameter(Mandatory = $true)]
        [PSCustomObject[]] $Module,
        [Parameter(Mandatory = $true)]
        [PSCustomObject] $ModuleOnline,
        [switch] $KeepVersions,
        [switch] $ReportOnly
    )

    Write-Verbose -Message ('Module version: {0}' -f $Module[0].Version)
    Write-Verbose -Message ('Online version: {0}' -f $ModuleOnline.Version)
    Write-Verbose -Message ('KeepVersions:   {0}' -f $KeepVersions)
    Write-Verbose -Message ('ReportOnly:     {0}' -f $ReportOnly)

    $isPreview = $null
    if ($Module[0].Version -like '*-preview') { $isPreview = ' (preview)' }

    if ($Module[0].Version -eq $ModuleOnline.Version) {

        Write-Output -InputObject ('{0}{1}: Newest version already installed ({2}).' -f $Module[0].Name, $isPreview, $Module[0].Version)
    } else {
        Write-Output -InputObject ('{0}{1}: Newer version available: {2} (Current version: {3}).' -f $Module[0].Name, $isPreview, $ModuleOnline.Version, $Module[0].Version)
        if (-not $ReportOnly) {
            Write-Output -InputObject ('{0}{1}: Updating to version {2}' -f $Module[0].Name, $isPreview, $ModuleOnline.Version)
            try {
                if ($isPreview) {
                    if ($PSCmdlet.ShouldProcess(('{0}{1}' -f $Module[0].Name, $isPreview), ('Updating to {0}' -f $ModuleOnline.Version))) {
                        Update-Module -Name $Module[0].Name -AllowPrerelease -WhatIf:$WhatIfPreference
                    }
                } else {
                    if ($PSCmdlet.ShouldProcess($Module[0].Name, ('Updating to {0}' -f $ModuleOnline.Version))) {
                        Update-Module -Name $Module[0].Name -WhatIf:$WhatIfPreference
                    }
                }
            }
            catch {
                Write-Warning -Message ('{0}: Failed to update.' -f $Module[0].Name)
                throw $_
                break
            }
        }
    }
    if (-not $ReportOnly -and -not $KeepVersions) {
        $Module | Where-Object { $_.Version -ne $ModuleOnline.Version } | ForEach-Object {
            $current = $_
            Write-Output -InputObject ('{0}: Uninstalling version {1}' -f $current.Name, $current.Version)
            try {
                if ($PSCmdlet.ShouldProcess($Module[0].Name, ('Uninstalling {0}' -f $current.Version))) {
                    $current | Uninstall-Module -WhatIf:$WhatIfPreference
                }
            }
            catch {
                Write-Warning -Message ('{0}: Failed to uninstall {1}.' -f $current.Name, $current.Version)
                throw $_
            }
        }
    }
}
#endregion

# build module array
$modules = @()

# process includes
$Include | ForEach-Object { 
    $current = $_
    Write-Verbose -Message ('Including "{0}"' -f $current)
    if ($current -match '\*') {
        Get-InstalledModule | Where-Object { $_.Name -like $current } | ForEach-Object { $modules += $_ }
    } else {
        $modules += Get-InstalledModule -Name $current
    }
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
    $current = $_
    $module  = Get-InstalledModule -Name $current.Name -AllVersions | Where-Object { $_.Version -notlike '*-preview' } | Sort-Object -Property @{ Expression = { [System.Version]$_.Version }; Descending = $true }
    if ($module) {
        $moduleOnline  = Find-Module -Name $current.Name

        Update-PowerShellModule -Module $module -ModuleOnline $moduleOnline -KeepVersions:$KeepVersions -ReportOnly:$ReportOnly
    }

    if ($IncludePreview) {
        $preview = Get-InstalledModule -Name $current.Name -AllVersions -AllowPrerelease | Where-Object { $_.Version -like '*-preview' } | Sort-Object -Property @{ Expression = { [System.Version]($_.Version.Replace('-preview', '')) }; Descending = $true }
        if ($preview) { 
            $previewOnline = Find-Module -Name $current.Name -AllowPrerelease

            Update-PowerShellModule -Module $preview -ModuleOnline $previewOnline -KeepVersions:$KeepVersions -ReportOnly:$ReportOnly
        }
    }
}
