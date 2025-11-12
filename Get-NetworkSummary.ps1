Get-NetIPConfiguration |
  Where-Object { $_.IPv4DefaultGateway -ne $null } |
  ForEach-Object {
    $iface  = $_.InterfaceAlias
    $ip     = $_.IPv4Address.IPAddress
    $prefix = $_.IPv4Address.PrefixLength
    $gw     = $_.IPv4DefaultGateway.NextHop

    # Convert prefix length to subnet mask
    $maskBits = ("1" * $prefix).PadRight(32, "0")
    $mask = [string]::Join('.', (0..3 | ForEach-Object {
      [convert]::ToInt32($maskBits.Substring($_ * 8, 8), 2)
    }))

    [PSCustomObject]@{
      Interface  = $iface
      PrivateIP  = $ip
      SubnetMask = $mask
      Gateway    = $gw
      PublicIP   = (Invoke-RestMethod -Uri "https://api.ipify.org?format=json").ip
    }
  } | Format-Table -AutoSize
