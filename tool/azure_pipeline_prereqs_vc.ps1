<#
Code by MSP-Greg
Azure Pipeline vc build 'Build variable' setup and prerequisite install items:
7zip, OpenSSL, zlib, bison, gperf, and sed
#>

#—————————————————————————————————————————————————————————  Check for VC version
$p_temp = (Get-Content ("env:VS" + "$env:VS" + "COMNTOOLS"))
$p_temp += "..\..\VC\vcvarsall.bat"
$VSCOMNTOOLS = [System.IO.Path]::GetFullPath($p_temp)
# below is same as File.exist?
if ( !(Test-Path -Path $VSCOMNTOOLS -PathType Leaf) ) {
  Write-Host "Path $VSCOMNTOOLS is not found."
  Write-Host "Please install or select another version of VS/VC."
  exit 1
}

$cd   = $pwd
$path = $env:path
$src  = $env:BUILD_SOURCESDIRECTORY

$base_path = "C:\Windows\system32;C:\Windows;C:\Windows\System32\Wbem"

$PSDefaultParameterValues['*:Encoding'] = 'utf8'

$7z_file = "7zip_ci.zip"
$7z_uri  = "https://dl.bintray.com/msp-greg/VC-OpenSSL/7zip_ci.zip"

$vs = $env:vs.substring(0,2)

$openssl_file = "openssl-1.1.1_vc$vs" + ".7z"
$openssl_uri  = "https://dl.bintray.com/msp-greg/VC-OpenSSL/$openssl_file"

$ruby_base = "rubyinstaller-2.5.1-2"
$ruby_uri  = "https://github.com/oneclick/rubyinstaller2/releases/download/$ruby_base/$ruby_base-x64.7z"

# zip version has no dots in version
$zlib_file = "zlib1211.zip"
$zlib_uri  = "https://zlib.net/$zlib_file"

# problems with sf, don't know how to open one connection and download multiple
# files with PS.  Might not help anyway...
$msys2_uri  = "https://sourceforge.net/projects/msys2/files/REPOS/MSYS2/x86_64"
$msys2_uri  = "http://repo.msys2.org/msys/x86_64"


[System.Net.ServicePointManager]::SecurityProtocol = [System.Net.SecurityProtocolType]::Tls12
$wc  = $(New-Object System.Net.WebClient)

$drv = (get-location).Drive.Name + ":"

$dl_path = "$drv/prereq"

# put all downloaded items in this folder
New-Item -Path $dl_path -ItemType Directory 1> $null




# make a temp folder on $drv
$tmpdir_w = "$drv\temp"
$tmpdir   = "$drv/temp"
New-Item  -Path $tmpdir_w -ItemType Directory 1> $null
(Get-Item -Path $tmpdir_w).Attributes = 'Normal'

#—————————————————————————————————————————————————————————————————————————  7Zip
$wc.DownloadFile($7z_uri, "$dl_path/$7z_file")
Expand-Archive -Path "$dl_path/$7z_file" -DestinationPath "$drv/7zip"
$env:path = "$drv/7zip;$base_path"
Write-Host "7zip installed"

#——————————————————————————————————————————————————————————————————————  OpenSSL
$fp = "$dl_path/$openssl_file"
$wc.DownloadFile($openssl_uri, $fp)
$dir = "-o$drv\openssl"
7z.exe x $fp $dir 1> $null
Write-Host "OpenSSL installed"
$env:path = "$drv/openssl/bin;$env:path"
openssl.exe version

#—————————————————————————————————————————————————————————————————————————  Ruby
$fp = "$dl_path/$ruby_base-x64.7z"
$wc.DownloadFile($ruby_uri, $fp)
$dir = "-o$drv\"
7z.exe x $fp $dir 1> $null
Rename-Item -Path "$drv/$ruby_base-x64" -NewName "$drv/ruby"
$env:ruby_path = "$drv\ruby"
Write-Host "Ruby installed"
$env:path = "$drv/ruby/bin;$env:path"
ruby -v

#————————————————————————————————————————————————————————————  bison, gperf, sed
# updated 2018-10-01, some needed for build, some needed for
# test-spec
$files = "msys2-runtime-2.11.1-2",
         "gcc-libs-7.3.0-3",
         "libintl-0.19.8.1-1",
         "libiconv-1.15-1",
         "coreutils-8.30-1",
         "bash-4.4.019-3",
         "bison-3.0.5-1",
         "gmp-6.1.2-1",
         "gperf-3.1-1",
         "m4-1.4.18-2",
         "patch-2.7.6-1",
         "sed-4.5-1"

$dir1 = "-o$dl_path"
$dir2 = "-o$drv\msys64"
$suf  = "-x86_64.pkg.tar"

foreach ($file in $files) {
  $fn = "$file$suf"
  $fp = "$dl_path\$fn"    + ".xz"
  $uri = "$msys2_uri/$fn" + ".xz"
  $wc.DownloadFile($uri, $fp)
  Write-Host "Processing $file"
  7z.exe x $fp $dir1 1> $null
  $fp = "$dl_path/$fn"
  7z.exe x $fp $dir2 -ttar -aoa 1> $null
}

#—————————————————————————————————————————————————————————————————————————  zlib
$file = "$dl_path/$zlib_file"
$wc.DownloadFile($zlib_uri, $file)
$dir = "$src\ext\zlib"
Expand-Archive -Path $file -DestinationPath $dir

$env:path = $path

#——————————————————————————————————————————————————  Setup Job Variables & State

$platform = $env:Platform + "-mswin_" + $env:vs
New-Item  -Path $src\$platform -ItemType Directory 1> $null

# set variable BASERUBY
echo "##vso[task.setvariable variable=BASERUBY]$drv/ruby/bin/ruby.exe"

# set variable BUILD
echo "##vso[task.setvariable variable=BUILD]$src\$platform"

# set variable BUILD_PATH used in each step
$t = "\usr\local\bin;$drv\ruby\bin;$drv\msys64\usr\bin;$drv\git\cmd;$env:path"
echo "##vso[task.setvariable variable=BUILD_PATH]$t"

# set variable GIT pointing to the exe, RubyGems tests use it (path with no space)
New-Item -Path $drv\git -ItemType Junction -Value $env:ProgramFiles\Git 1> $null
echo "##vso[task.setvariable variable=GIT]$drv/git/cmd/git.exe"

# set variable INSTALL_PATH
$t = "\usr\bin;\usr\local\bin;$drv\msys64\usr\bin;$drv\git\cmd;$env:path"
echo "##vso[task.setvariable variable=INSTALL_PATH]$t"

# set variable JOBS
echo "##vso[task.setvariable variable=JOBS]$env:NUMBER_OF_PROCESSORS"

# set variable OPENSSL_DIR
echo "##vso[task.setvariable variable=OPENSSL_DIR]$drv\openssl"

# set variable SRC
echo "##vso[task.setvariable variable=SRC]$src"

# set variable TMPDIR
echo "##vso[task.setvariable variable=TMPDIR]$tmpdir"

# set variable TMPDIR_W
echo "##vso[task.setvariable variable=TMPDIR_W]$tmpdir_w"

# set variable VC_VARS to the bat file
echo "##vso[task.setvariable variable=VC_VARS]$VSCOMNTOOLS"
