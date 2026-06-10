# Target DC or server
$Target = ""

# Define ports
$Ports = @{
    "Kerberos"        = 88
    "LDAP"            = 389
    "LDAPS"           = 636
    "GlobalCatalog"   = 3268
    "GlobalCatalog01" = 3269
    "RPC (Endpoint)"  = 135
    "SMB"             = 445
    "DNS"             = 53
    
}

# Test function
function Test-TcpPort {
    param (
        [string]$Computer,
        [int]$Port,
        [int]$Timeout = 2000
    )

    try {
        $client = New-Object System.Net.Sockets.TcpClient
        $iar = $client.BeginConnect($Computer, $Port, $null, $null)

        if ($iar.AsyncWaitHandle.WaitOne($Timeout, $false)) {
            $client.EndConnect($iar)
            $client.Close()
            return "Open"
        } else {
            $client.Close()
            return "Filtered/Timeout"
        }
    }
    catch {
        return "Closed/Error"
    }
}

# Run tests
$Results = foreach ($p in $Ports.GetEnumerator()) {
    [PSCustomObject]@{
        Service = $p.Key
        Port    = $p.Value
        Status  = Test-TcpPort -Computer $Target -Port $p.Value
    }
}

# Output
$Results | Format-Table -AutoSize