$urls = @(
    "https://fonts.gstatic.com/s/poppins/v20/pxiEyp8kv8JHgFVrJJbecnFHGPezSQ.woff2", # Poppins-Regular
    "https://fonts.gstatic.com/s/poppins/v20/pxiByp8kv8JHgFVrLGT9Z1xlFd2JQEk.woff2", # Poppins-Medium
    "https://fonts.gstatic.com/s/poppins/v20/pxiByp8kv8JHgFVrLEj6Z1xlFd2JQEk.woff2", # Poppins-SemiBold
    "https://fonts.gstatic.com/s/poppins/v20/pxiByp8kv8JHgFVrLCz7Z1xlFd2JQEk.woff2"  # Poppins-Bold
)

$fontNames = @(
    "Poppins-Regular.ttf",
    "Poppins-Medium.ttf",
    "Poppins-SemiBold.ttf",
    "Poppins-Bold.ttf"
)

# Ensure the directory exists
$fontDir = "assets\fonts"
if (-not (Test-Path $fontDir)) {
    New-Item -ItemType Directory -Force -Path $fontDir
}

# Download each font file
for ($i = 0; $i -lt $urls.Length; $i++) {
    $url = $urls[$i]
    $fontPath = Join-Path -Path $fontDir -ChildPath $fontNames[$i]
    
    Write-Host "Downloading $($fontNames[$i])..."
    Invoke-WebRequest -Uri $url -OutFile $fontPath
    
    if (Test-Path $fontPath) {
        Write-Host "Downloaded $($fontNames[$i]) successfully."
    } else {
        Write-Host "Failed to download $($fontNames[$i])."
    }
}

Write-Host "Font download complete." 