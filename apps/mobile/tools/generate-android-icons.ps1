param()

$ErrorActionPreference = "Stop"

$mobileDirectory = Split-Path -Parent $PSScriptRoot
$repositoryDirectory = Split-Path -Parent (Split-Path -Parent $mobileDirectory)
$sourceSvg = Join-Path $repositoryDirectory `
    "design\logo-concepts\viewfinder-reps\vf-b-nested.svg"
$resourceDirectory = Join-Path $mobileDirectory "android\app\src\main\res"
$generationDirectory = Join-Path $mobileDirectory "build\icon-generation"
$masterIcon = Join-Path $generationDirectory "ic_launcher_master.png"
$chrome = Join-Path $env:ProgramFiles "Google\Chrome\Application\chrome.exe"

if (-not (Test-Path -LiteralPath $chrome)) {
    throw "Google Chrome was not found at $chrome."
}
if (-not (Test-Path -LiteralPath $sourceSvg)) {
    throw "Launcher icon source was not found at $sourceSvg."
}

$sourceUri = [System.Uri]::new($sourceSvg).AbsoluteUri
$icons = @(
    @{ Density = "mdpi"; Size = 48 },
    @{ Density = "hdpi"; Size = 72 },
    @{ Density = "xhdpi"; Size = 96 },
    @{ Density = "xxhdpi"; Size = 144 },
    @{ Density = "xxxhdpi"; Size = 192 }
)

[System.IO.Directory]::CreateDirectory($generationDirectory) | Out-Null
if (Test-Path -LiteralPath $masterIcon) {
    Remove-Item -LiteralPath $masterIcon
}
$arguments = @(
    "--headless=new",
    "--disable-gpu",
    "--hide-scrollbars",
    "--force-device-scale-factor=1",
    "--default-background-color=FFF8F6F0",
    "--window-size=512,512",
    "--screenshot=$masterIcon",
    $sourceUri
)
$process = Start-Process `
    -FilePath $chrome `
    -ArgumentList $arguments `
    -Wait `
    -PassThru `
    -WindowStyle Hidden
if ($process.ExitCode -ne 0 -or -not (Test-Path -LiteralPath $masterIcon)) {
    throw "Chrome did not create the 512px master icon."
}

Add-Type -AssemblyName System.Drawing
$master = [System.Drawing.Image]::FromFile($masterIcon)
try {
    if ($master.Width -ne 512 -or $master.Height -ne 512) {
        throw "Unexpected master icon size: $($master.Width)x$($master.Height)."
    }
    foreach ($icon in $icons) {
        $directory = Join-Path $resourceDirectory "mipmap-$($icon.Density)"
        $launcher = Join-Path $directory "ic_launcher.png"
        $bitmap = [System.Drawing.Bitmap]::new(
            $icon.Size,
            $icon.Size,
            [System.Drawing.Imaging.PixelFormat]::Format32bppArgb
        )
        try {
            $graphics = [System.Drawing.Graphics]::FromImage($bitmap)
            try {
                $graphics.CompositingMode = [System.Drawing.Drawing2D.CompositingMode]::SourceCopy
                $graphics.CompositingQuality = [System.Drawing.Drawing2D.CompositingQuality]::HighQuality
                $graphics.InterpolationMode = [System.Drawing.Drawing2D.InterpolationMode]::HighQualityBicubic
                $graphics.SmoothingMode = [System.Drawing.Drawing2D.SmoothingMode]::HighQuality
                $graphics.PixelOffsetMode = [System.Drawing.Drawing2D.PixelOffsetMode]::HighQuality
                $graphics.DrawImage(
                    $master,
                    [System.Drawing.Rectangle]::new(0, 0, $icon.Size, $icon.Size)
                )
            } finally {
                $graphics.Dispose()
            }
            $bitmap.Save($launcher, [System.Drawing.Imaging.ImageFormat]::Png)
        } finally {
            $bitmap.Dispose()
        }
        Copy-Item `
            -LiteralPath $launcher `
            -Destination (Join-Path $directory "ic_launcher_round.png") `
            -Force
    }
} finally {
    $master.Dispose()
}

foreach ($icon in $icons) {
    $path = Join-Path `
        (Join-Path $resourceDirectory "mipmap-$($icon.Density)") `
        "ic_launcher.png"
    $image = [System.Drawing.Image]::FromFile($path)
    try {
        if ($image.Width -ne $icon.Size -or $image.Height -ne $icon.Size) {
            throw "Unexpected $($icon.Density) icon size: $($image.Width)x$($image.Height)."
        }
    } finally {
        $image.Dispose()
    }
}

Write-Host "Android launcher icons generated from $sourceSvg."
