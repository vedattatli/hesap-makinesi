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

$outputFullPath = [System.IO.Path]::GetFullPath($OutputPath)
$outputDirectory = [System.IO.Path]::GetDirectoryName($outputFullPath)
if (-not [string]::IsNullOrWhiteSpace($outputDirectory) -and -not (Test-Path -LiteralPath $outputDirectory)) {
    New-Item -ItemType Directory -Force -Path $outputDirectory | Out-Null
}

$utf8NoBom = New-Object System.Text.UTF8Encoding -ArgumentList $false
[System.IO.File]::WriteAllText($outputFullPath, $content, $utf8NoBom)

Write-Host "Wrote local Android signing properties to $OutputPath"
Write-Host "Do not commit this file. It is ignored by git."
