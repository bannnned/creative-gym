param(
    [string]$BackupDirectory = (
        Join-Path $env:USERPROFILE "Documents\CreativeGymReleaseSigningBackup"
    )
)

$ErrorActionPreference = "Stop"

$mobileDirectory = Split-Path -Parent $PSScriptRoot
$androidDirectory = Join-Path $mobileDirectory "android"
$keystorePath = Join-Path $androidDirectory "app\creative-gym-release.jks"
$propertiesPath = Join-Path $androidDirectory "key.properties"
$alias = "creative-gym-release"

if ((Test-Path -LiteralPath $keystorePath) -or
    (Test-Path -LiteralPath $propertiesPath)) {
    throw "Release signing files already exist. Refusing to overwrite them."
}

$keytoolCandidates = @(
    (Join-Path $env:ProgramFiles "Android\Android Studio\jbr\bin\keytool.exe"),
    (Get-Command keytool.exe -ErrorAction SilentlyContinue |
        Select-Object -ExpandProperty Source -ErrorAction SilentlyContinue)
) | Where-Object { $_ -and (Test-Path -LiteralPath $_) }

$keytool = $keytoolCandidates | Select-Object -First 1
if (-not $keytool) {
    throw "keytool.exe was not found. Install Android Studio or add a JDK to PATH."
}

$alphabet = "ABCDEFGHJKLMNPQRSTUVWXYZabcdefghijkmnopqrstuvwxyz23456789"
$randomBytes = [byte[]]::new(48)
$randomGenerator = [System.Security.Cryptography.RandomNumberGenerator]::Create()
try {
    $randomGenerator.GetBytes($randomBytes)
} finally {
    $randomGenerator.Dispose()
}
$passwordCharacters = foreach ($byte in $randomBytes) {
    $alphabet[$byte % $alphabet.Length]
}
$password = -join $passwordCharacters

$keytoolArguments = @(
    "-genkeypair",
    "-v",
    "-keystore", $keystorePath,
    "-storetype", "JKS",
    "-storepass", $password,
    "-keypass", $password,
    "-alias", $alias,
    "-keyalg", "RSA",
    "-keysize", "2048",
    "-validity", "10000",
    "-dname", "CN=Creative Gym, OU=Mobile, O=Creative Gym, L=Moscow, ST=Moscow, C=RU"
)
& $keytool @keytoolArguments
if ($LASTEXITCODE -ne 0) {
    throw "keytool failed with exit code $LASTEXITCODE."
}

$properties = @(
    "storePassword=$password",
    "keyPassword=$password",
    "keyAlias=$alias",
    "storeFile=creative-gym-release.jks"
)
[System.IO.File]::WriteAllLines(
    $propertiesPath,
    $properties,
    [System.Text.UTF8Encoding]::new($false)
)

[System.IO.Directory]::CreateDirectory($BackupDirectory) | Out-Null
$backupKeystorePath = Join-Path $BackupDirectory "creative-gym-release.jks"
if (Test-Path -LiteralPath $backupKeystorePath) {
    throw "Backup keystore already exists. Refusing to overwrite it."
}
Copy-Item -LiteralPath $keystorePath -Destination $backupKeystorePath

$encryptedPassword = ConvertTo-SecureString $password -AsPlainText -Force |
    ConvertFrom-SecureString
[System.IO.File]::WriteAllText(
    (Join-Path $BackupDirectory "key-password.dpapi"),
    $encryptedPassword,
    [System.Text.UTF8Encoding]::new($false)
)

$fingerprints = & $keytool `
    -list `
    -v `
    -keystore $keystorePath `
    -storepass $password `
    -alias $alias
[System.IO.File]::WriteAllLines(
    (Join-Path $BackupDirectory "certificate-fingerprints.txt"),
    $fingerprints,
    [System.Text.UTF8Encoding]::new($false)
)

$backupReadme = @"
Creative Gym Android release signing backup

Package ID: com.creativegym.mobile
Key alias: $alias

key-password.dpapi can only be decrypted by the Windows user that created it.
Keep another encrypted copy of the keystore on a different device or cloud
vault, and save the password from android/key.properties in a password manager.
Never commit the keystore or key.properties to Git.
"@
[System.IO.File]::WriteAllText(
    (Join-Path $BackupDirectory "README.txt"),
    $backupReadme,
    [System.Text.UTF8Encoding]::new($false)
)

Write-Host "Release signing configured."
Write-Host "Local keystore: $keystorePath"
Write-Host "Protected local backup: $BackupDirectory"
Write-Host "The generated password was not printed."
