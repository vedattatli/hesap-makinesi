param(
    [string]$KeystorePath = "$env:USERPROFILE\upload-keystore.jks",
    [string]$KeyAlias = "upload",
    [string]$OutputPath = "android\key.properties"
)

$ErrorActionPreference = "Stop"

function Convert-SecureStringToPlainText {
    param([Security.SecureString]$SecureValue)

    $bstr = [Runtime.InteropServices.Marshal]::SecureStringToBSTR($SecureValue)
    try {
        [Runtime.InteropServices.Marshal]::PtrToStringBSTR($bstr)
    } finally {
        if ($bstr -ne [IntPtr]::Zero) {
            [Runtime.InteropServices.Marshal]::ZeroFreeBSTR($bstr)
        }
    }
}

if (-not (Test-Path -LiteralPath $KeystorePath)) {
    throw "Keystore file was not found: $KeystorePath"
}

$storePasswordSecure = Read-Host "Keystore password" -AsSecureString
$keyPasswordSecure = Read-Host "Key password (press Enter if same as keystore password)" -AsSecureString

$storePassword = Convert-SecureStringToPlainText $storePasswordSecure
$keyPassword = Convert-SecureStringToPlainText $keyPasswordSecure

if ([string]::IsNullOrWhiteSpace($keyPassword)) {
    $keyPassword = $storePassword
}

if ([string]::IsNullOrWhiteSpace($storePassword)) {
    throw "Keystore password cannot be empty."
}

$escapedStoreFile = $KeystorePath.Replace("\", "\\")
$content = @(
    "storePassword=$storePassword",
    "keyPassword=$keyPassword",
    "keyAlias=$KeyAlias",
    "storeFile=$escapedStoreFile"
) -join [Environment]::NewLine

Set-Content -LiteralPath $OutputPath -Value $content -NoNewline -Encoding UTF8
Write-Host "Wrote local Android signing properties to $OutputPath"
Write-Host "Do not commit this file. It is ignored by git."
