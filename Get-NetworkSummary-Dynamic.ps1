# Get-NetworkSummary-Dynamic.ps1
# Continuously refreshes network info every few seconds

while ($true) {
    Clear-Host
    Write-Host "=== Dynamic Network Information ===" -ForegroundColor Cyan
    Write-Host "(Last updated: $(Get-Date))`n"

    try {
        $publicIP = (Invoke-RestMethod -Uri "https://api.ipify.org?format=json" -TimeoutSec 3 -ErrorAction Stop).ip
    } catch {
        $publicIP = "Unavailable"
    }

    $adapters = Get-NetAdapter | Select-Object Name, InterfaceDescription, MacAddress, Status, LinkSpeed
    $configs  = Get-NetIPConfiguration | Where-Object { $_.IPv4Address -ne $null }

    foreach ($adapter in $adapters) {
        $conf = $configs | Where-Object { $_.InterfaceAlias -eq $adapter.Name }

        if ($conf) {
            $ip     = $conf.IPv4Address.IPAddress
            $prefix = $conf.IPv4Address.PrefixLength
            $gw     = $conf.IPv4DefaultGateway.NextHop

            $maskBits = ("1" * $prefix).PadRight(32, "0")
            $mask = [string]::Join('.', (0..3 | ForEach-Object {
                [convert]::ToInt32($maskBits.Substring($_ * 8, 8), 2)
            }))
        } else {
            $ip = "—"
            $mask = "—"
            $gw = "—"
        }

        [PSCustomObject]@{
            Name                 = $adapter.Name
            InterfaceDescription = $adapter.InterfaceDescription
            MacAddress           = $adapter.MacAddress
            Status               = $adapter.Status
            LinkSpeed            = $adapter.LinkSpeed
            PrivateIP            = $ip
            SubnetMask           = $mask
            Gateway              = $gw
            PublicIP             = $publicIP
        } | Format-List

        Write-Host ""
    }

    Start-Sleep -Seconds 10
}
