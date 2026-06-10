# https://techcommunity.microsoft.com/blog/windows-itpro-blog/act-now-secure-boot-certificates-expire-in-june-2026/4426856
# https://directaccess.richardhicks.com/2025/12/04/windows-secure-boot-uefi-certificates-expiring-june-2026/
# Script is built based on the above articles. 
# **From MS** - requires no less than 2 reboots before confirming the computer is ok. 

# Put your list of servers that are UEFI and WinRM ready below:
$server = @()

$server += ""



# connect to the endpoint and collect the result of the UEFICA2023 status. Pass that result through a switch statement and based on result update the registry and start the scheduled task.
# Script requires a second run to confirm the status is "InProgress"
# after 2 system reboots, re-run script and status should be "Computer is all set!"
foreach ($s in $server) {
    write-host "SERVER NAME: $s"
    Write-Host "-------------"
    Invoke-Command -ComputerName $s -ScriptBlock {
        if ($env:firmware_type -eq "UEFI") {
            $result = Get-ItemProperty -Path HKLM:\SYSTEM\CurrentControlSet\Control\SecureBoot\Servicing\ -Name UEFICA2023Status -ErrorAction Ignore | Select-Object -ExpandProperty UEFICA2023Status
            Write-Host "Current Status:"
            $result
            switch ($result) {
                NotStarted {
                    Set-ItemProperty -Path ‘HKLM:\SYSTEM\CurrentControlSet\Control\SecureBoot’ -Name ‘AvailableUpdates’ -Value 0x5944
                    Start-ScheduledTask -TaskName ‘\Microsoft\Windows\PI\Secure-Boot-Update’
                    Get-ScheduledTask -TaskName 'Secure-Boot-Update' -TaskPath '\Microsoft\Windows\PI\' | Select-Object TaskName, State
                }
                InProgress { Write-Host "Computer is ready for restart" }
                Updated {
                    # Get the UEFIboot DB to ensure there is a match for 2023 certificate
                    if ([System.Text.Encoding]::ASCII.GetString((Get-SecureBootUEFI -Name db).Bytes) -match "2023") { Write-Host "$env:ComputerName is all set!" }
                }
                Default { "Registry entries are missing from server. Please verify server is UEFI and has most recent windows updates" }
            }
        }
        Write-Host "`n" }
}
