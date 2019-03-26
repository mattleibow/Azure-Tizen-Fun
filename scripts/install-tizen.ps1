Param(
    [string] $version = "3.2"
)

$errorActionPreference = 'Stop'

if ($IsMacOS) {
    $platform = "macos-64"
    $ext = "bin"
} elseif ($IsLinux) {
    $platform = "ubuntu-64"
    $ext = "bin"
} else {
    $platform = "windows-64"
    $ext = "exe"
}

$ts = Join-Path "$HOME" "tizen-studio"
$tsTemp = Join-Path "$HOME" "tizen-temp"
$url = "http://download.tizen.org/sdk/Installer/tizen-studio_${version}/web-cli_Tizen_Studio_${version}_${platform}.${ext}"
$install = Join-Path "$tsTemp" "tizen-install.$ext"
$packages = "MOBILE-4.0,MOBILE-4.0-NativeAppDevelopment"

# make sure that JAVA_HOME/bin is in the PATH
if ($env:JAVA_HOME) {
    $javaBin = Join-Path "$env:JAVA_HOME" "bin"
    if(-not $env:PATH.Contains($javaBin)) {
        $splitPath = $env:PATH.Split([System.IO.Path]::PathSeparator)
        Write-Host "Removing the following Java locations from PATH:"
        $theJava = $splitPath | Where-Object { $_ -like "*Java*" }
        $javaPath = [String]::Join([System.IO.Path]::PathSeparator, $theJava)
        Write-Host "$javaPath"
        Write-Host "Adding $javaBin to PATH..."
        $noJava = $splitPath | Where-Object { $_ -notlike "*Java*" };
        $newPath = @( "$javaBin" ) + $noJava
        $env:PATH = [String]::Join([System.IO.Path]::PathSeparator, $newPath)
    }
}

# log the contents of PATH
Write-Host "Contents of PATH:"
Write-Host "$env:PATH"

# log the Java version
Write-Host "Using Java version:"
& "cmd" /c where java
& "java" -version

# download
Write-Host "Downloading SDK to '$install'..."
New-Item -ItemType Directory -Force -Path "$tsTemp" | Out-Null
(New-Object System.Net.WebClient).DownloadFile("$url", "$install")

# install
Write-Host "Installing SDK to '$ts'..."
if ($IsMacOS -or $IsLinux) {
    & "bash" "$install" --accept-license --no-java-check "$ts"
} else {
    & "$install" --accept-license --no-java-check "$ts"
}

# install packages
Write-Host "Installing Additional Packages: '$packages'..."
$packMan = Join-Path (Join-Path "$ts" "package-manager") "package-manager-cli.${ext}"
if ($IsMacOS -or $IsLinux) {
    & "bash" "$packMan" install --no-java-check --accept-license "$packages"
} else {
    & "$packMan" install --no-java-check --accept-license "$packages"
}

exit $LASTEXITCODE
