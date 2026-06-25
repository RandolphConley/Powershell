function Export-WebCertificate {
<#
.SYNOPSIS
Exports a web certificate from the certificate store to a PFX file.

.DESCRIPTION
This function exports a certificate from the Windows certificate store
to a specified PFX file using Export-PfxCertificate. It uses a secure
string password and allows exporting only the end-entity certificate
without the full chain or extended properties.

The function is intended for scenarios where a web or service certificate
needs to be moved or backed up in a controlled and repeatable way.

.EXAMPLE
Export-WebCertificate -OutPath "C:\myexport.pfx"

Exports the certificate defined in the function to C:\myexport.pfx using
the configured password.

.EXAMPLE
Export-WebCertificate -Thumbprint '5F98EBBFE735CDDAE00E33E0FD69050EF9220254' -OutputPath 'C:\temp\site.pfx'

Exports the specified certificate to the given path.

.NOTES
- The certificate must have an exportable private key.
- The password is currently hardcoded for demonstration purposes and
  should be handled securely in production.
- By default, only the end-entity certificate is exported without the chain.
#>

[CmdletBinding()]
param (
    [Parameter(Mandatory=$true)]
    [string]
    $OutPath,
    [Parameter(Mandatory=$false)]
    [string]
    $Thumbprint
)

    try {

        if(Test-Path $OutPath){}else{throw "OutPath variable could not be resolved. Verify that it is defined and spelled correctly."}
        Write-Host "Please select the desired certificate Thumbprint"
        "`n"
        (get-childitem -path Cert:\LocalMachine\my) | Select-Object Subject,Thumbprint | Format-Table -Wrap
        if($Thumbprint){}else{$Thumbprint = Read-Host "Paste the desired thumbprint here"}
        "`n"
        # Build certificate path
        $certPath = "Cert:\LocalMachine\My\$Thumbprint"
        
        if(Get-ChildItem -Path $certPath){
        Write-Host "Confirmed thumbprint. Exporting now."  
        "`n"
        # Convert password to secure string
        $mypwd = Read-Host -Prompt "Enter your password" -AsSecureString
        "`n"
        # Prepare export parameters
        $params = @{
            Cert = $certPath
            FilePath = $OutPath
            ChainOption = 'EndEntityCertOnly'
            NoProperties = $true
            Password = $mypwd
        }

        Write-Host "Exporting Certificate now."
        # Export certificate
        Export-PfxCertificate @params

        Write-Output "Certificate exported successfully to $OutputPath"
    }
}
    catch {
        Write-Error "Failed to export certificate: $_"
    }
        
}