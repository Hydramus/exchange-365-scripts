# PSSharedFunctions.psm1
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
Export-ModuleMember -Function Write-Log, Confirm-Action
