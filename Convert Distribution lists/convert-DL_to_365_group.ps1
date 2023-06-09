<#
.SYNOPSIS
    Convert Distribution Lists to Microsoft 365 Groups
.DESCRIPTION
    This script converts distribution lists to Microsoft 365 groups
    while including all the delegates as members and keeping the same owner.  If the owner
    is specified in the -OriginalOwner parameter, the default owner is changed to the email address
    specified in the -NewOwner parameter. For example, if the owner is administrator@example.com, 
    the new owner like name@example.com
.AUTHOR
    Hydramus
.VERSION
    1.6
.NOTES
    This script requires Exchange Online Management Module and MFA support.
    To install the module, run 'Install-Module -Name ExchangeOnlineManagement'
.EXAMPLE
    .\ConvertDLto365Group.ps1 -DLList "distlist1@example.com, distlist2@example.com"
.EXAMPLE
    .\ConvertDLto365Group.ps1 -All
.EXAMPLE
    .\ConvertDLto365Group.ps1 -ListAll
#>

param(
    [Parameter(Mandatory = $false, HelpMessage = "Enter a comma-separated list of distribution list email addresses to convert.")]
    [string]$DLList,
    [Parameter(Mandatory = $false, HelpMessage = "Convert all eligible distribution lists.")]
    [switch]$All,
    [Parameter(Mandatory = $false, HelpMessage = "Perform a dry run of the conversion process without actually converting the distribution lists.")]
    [switch]$Test,
    [Parameter(Mandatory = $false, HelpMessage = "List all distribution lists, showing both eligible and non-eligible ones.")]
    [switch]$ListAll,
    [Parameter(Mandatory = $false, HelpMessage = "Enter the email address of the original owner to be replaced.")]
    [string]$OriginalOwner,
    [Parameter(Mandatory = $false, HelpMessage = "Enter the email address of the new owner.")]
    [string]$NewOwner,
    [switch]$Help
)
if ($Help) {
    Get-Help $MyInvocation.MyCommand.Name
    exit
}
# Import the shared functions module
Import-Module .\Modules\PSSharedFunctions.psm1
function Write-Log {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory = $true)]
        [string]$Message
    )
    $logDir = "C:\logs"
    if ([System.Environment]::OSVersion.Platform -eq [System.PlatformID]::Unix) {
        $logDir = "/var/log"
    }
    if (!(Test-Path $logDir)) {
        New-Item -Path $logDir -ItemType Directory -Force | Out-Null
    }
    $logFile = "$logDir\365ConversionLog_{0:yyyyMMdd}.txt" -f (Get-Date)
    $timeStamp = Get-Date -Format "yyyy-MM-dd HH:mm:ss"
    Add-Content -Path $logFile -Value "[$timeStamp] $Message" -ErrorAction SilentlyContinue
}
function Confirm-Conversion {
    param(
        [Parameter(Mandatory = $true)]
        [string]$DisplayName
    )
    $choice = Read-Host "Convert '$DisplayName'? (Y)es, (A)ll, or (N)o/other key to cancel"
    return $choice
}

function List-AllDLs {
    $allDLs = Get-DistributionGroup
    $eligibleDLs = Get-EligibleDistributionGroupForMigration
    $eligibleSMTPs = $eligibleDLs.PrimarySMTPAddress
    Write-Host "Distribution Lists:" -ForegroundColor Green
    foreach ($dl in $allDLs) {
        if ($dl.PrimarySMTPAddress -in $eligibleSMTPs) {
            Write-Host "  - $($dl.DisplayName) (Eligible for conversion)" -ForegroundColor Green
        } else {
            Write-Host "  - $($dl.DisplayName) (Not eligible for conversion)" -ForegroundColor Red
        }
    }
    Write-Host "`nReasons for ineligibility:" -ForegroundColor Yellow
    Write-Host "  - Nested distribution lists" -ForegroundColor Yellow
    Write-Host "  - Distribution lists with more than 100 owners" -ForegroundColor Yellow
    Write-Host "  - Dynamic distribution lists" -ForegroundColor Yellow
    Write-Host "  - Distribution lists with more than 100,000 members" -ForegroundColor Yellow
    Write-Host "  - Distribution lists with recipient"
    Write-Host "  - Distribution lists with recipient management delegation" -ForegroundColor Yellow
    Write-Host "  - Distribution lists with moderation enabled" -ForegroundColor Yellow
    Write-Host "  - Distribution lists with mail flow rules" -ForegroundColor Yellow
}
try {
    Write-Log "Starting process..."
    if (!(Get-Module -ListAvailable -Name ExchangeOnlineManagement)) {
        Write-Error "Exchange Online Management module not installed. Please install it using 'Install-Module -Name ExchangeOnlineManagement'"
        Write-Log "Exchange Online Management module not installed."
        exit
    }
    Write-Log "Authenticating to Exchange Online..."
    Connect-ExchangeOnline -ShowProgress $true -EnableErrorReporting
    Write-Log "Authenticated to Exchange Online."
    if ($ListAll) {
        List-AllDLs
        Disconnect-ExchangeOnline -Confirm:$false
        exit
    }
    $eligibleDLs = @()
    if ($DLList) {
        $dlAddresses = $DLList.Split(',')
        foreach ($address in $dlAddresses) {
            $dl = Get-DistributionGroup -Identity $address.Trim() -ErrorAction SilentlyContinue
            if ($dl) {
                $eligibleDLs += $dl
            } else {
                Write-Error "Distribution List $address not found."
                Write-Log "Distribution List $address not found."
            }
        }
    } elseif ($All) {
        $eligibleDLs = Get-EligibleDistributionGroupForMigration
    } else {
        Write-Error "Please provide -DLList, -All, or -ListAll parameter."
        Write-Log "No parameters provided."
        exit
    }
    $convertAll = $false
    foreach ($dl in $eligibleDLs) {
        if (-not $convertAll) {
            $choice = Confirm-Conversion -DisplayName $dl.DisplayName
            if ($choice -eq "A") {
                $convertAll = $true
            } elseif ($choice -ne "Y") {
                Write-Log "Skipped conversion for $($dl.DisplayName)."
                continue
            }
        }
        if ($Test) {
            Write-Host "Dry run: $($dl.DisplayName) would be converted." -ForegroundColor Cyan
        } else {
            Write-Log "Converting $($dl.DisplayName)..."
            Upgrade-DistributionGroup -DLIdentities $dl.PrimarySMTPAddress
            Change-OwnerIfAdmin -GroupId $dl.PrimarySMTPAddress
            Write-Log "Converted $($dl.DisplayName) to Microsoft 365 Group."
        }
    }
    Write-Log "Process completed."
    Disconnect-ExchangeOnline -Confirm:$false
} catch {
    Write-Error $_.Exception.Message
    Write-Log "Error: $($_.Exception.Message)"
    Write-Log "Process terminated due to error."
    Disconnect-ExchangeOnline -Confirm:$false
}
