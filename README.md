# EvergreenModules

[![Release][github-release-badge]][github-release]
[![Codacy][code-quality-badge]][code-quality]
[![License][license-badge]][license]
[![Twitter][twitter-follow-badge]][twitter-follow]

After manually updating modules several times, and always forgetting one or more, I decided it was time to automate updating PowerShell modules.

This script:
*  Checks for newer versions of installed PowerShell modules and updates those modules
*  Optionally processes preview versions of installed PowerShell modules as well
*  Optionally runs in 'Reporting Only' mode

The name I chose for this script is an ode to the Evergreen module (https://github.com/aaronparker/Evergreen) by Aaron Parker (@stealthpuppy).

## How to use

Quick start:
*  Download the script to a location of your chosing (for example: C:\Scripts\EvergreenModules)
*  Run or schedule the script

You can also install the script from the PowerShell Gallery ([EvergreenModules][poshgallery-evergreenmodules]):
```powershell
Install-Script -Name EvergreenModules
```

I have scheduled the script to run daily:

```powershell
EvergreenModules.ps1 -IncludePreview
```

The above execution will keep all installed PowerShell modules up to date, including preview versions.

A sample .xml file that you can import in Task Scheduler is provided with this script.

This script processes all the installed PowerShell modules by default. You can scope this using the Include and Exclude parameters to you liking.

```
SYNTAX
    EvergreenModules.ps1 [[-Include] <String[]>] [[-Exclude] <String[]>] [[-IncludePreview]] [[-KeepVersions]] [[-ReportOnly]] [<CommonParameters>]

DESCRIPTION
    Script to automatically update your installed PowerShell modules.
    Optionally keep old versions or process Preview versions.

PARAMETERS
    -Include <String[]>
        Optionally scopes the update process to one or more module names.
        If more than one module name need to be included, pass in an array of strings.
        Supports '*' wildcard.

    -Exclude <String[]>
        Optionally provide one or more module names to exclude from the update process.
        If more than one module name need to be excluded, pass in an array of strings.
        Supports '*' wildcard.

    -IncludePreview [<SwitchParameter>]
        Preview versions for modules are not processed by default.
        Use this switch parameter to include preview versions in the update process.
        This checks for modules that have '-preview' in their Version attributes.

    -KeepVersions [<SwitchParameter>]
        If used this switch ensures the script will not uninstall older versions if a new version is found and
        installed.

    -ReportOnly [<SwitchParameter>]
        If used this switch ensures no modules are updated but available updates are reported.

    <CommonParameters>
        This cmdlet supports the common parameters: Verbose, Debug,
        ErrorAction, ErrorVariable, WarningAction, WarningVariable,
        OutBuffer, PipelineVariable, and OutVariable. For more information, see
        about_CommonParameters (https:/go.microsoft.com/fwlink/?LinkID=113216).

EXAMPLES
    -------------------------- EXAMPLE 1 --------------------------
    PS C:\>.\EvergreenModules.ps1

    Updates all installed PowerShell modules (excluding those that have '-preview' in their Version attribute).


    -------------------------- EXAMPLE 2 --------------------------

    PS C:\>.\EvergreenModules.ps1 -IncludePreview

    Updates all installed PowerShell modules, including those that have '-preview' in their Version attribute.


    -------------------------- EXAMPLE 3 --------------------------

    PS C:\>.\EvergreenModules.ps1 -ReportOnly

    Reports all available updates for all installed PowerShell modules, excluding modules that have '-preview' in
    their Version attribute.


    -------------------------- EXAMPLE 4 --------------------------

    PS C:\>.\EvergreenModules.ps1 -Include @('Az', 'Microsoft*') -Exclude 'Microsoft.Graph.Intune'

    Only updates the 'Az' module and modules starting with 'Microsoft', except the module 'Microsoft.Graph.Intune'

```

## Notes

If you get an error relating to PackageManagement or PowerShellGet, it's probably because of a known bug when using Known Folder Move with OneDrive (for Business) and thus moving your Documents folder to OneDrive, including the default location for Windows PowerShell modules in the CurrentUser scope.



[github-release-badge]: https://img.shields.io/github/release/msfreaks/EvergreenModules.svg?style=flat-square
[github-release]: https://github.com/msfreaks/EvergreenModules/releases/latest
[code-quality-badge]: https://app.codacy.com/project/badge/Grade/c0efab02b66442399bb16b0493cdfbef?style=flat-square
[code-quality]: https://www.codacy.com/gh/msfreaks/EvergreenModules/dashboard?utm_source=github.com&amp;utm_medium=referral&amp;utm_content=msfreaks/EvergreenModules&amp;utm_campaign=Badge_Grade
[license-badge]: https://img.shields.io/github/license/msfreaks/EvergreenModules.svg?style=flat-square
[license]: https://github.com/msfreaks/EvergreenModules/blob/master/LICENSE
[twitter-follow-badge]: https://img.shields.io/twitter/follow/menschab?style=flat-square
[twitter-follow]: https://twitter.com/menschab?ref_src=twsrc%5Etfw
[change-log]: https://github.com/msfreaks/EvergreenModules/blob/main/CHANGELOG.md
[poshgallery-evergreenmodules]: https://www.powershellgallery.com/packages/EvergreenModules/
