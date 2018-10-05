<#
azure_pipeline_prereqs_msys2.ps1
Code by MSP-Greg
Azure Pipeline mingw build 'Build variable' setup and prerequisite install items:
7zip, msys2mingw system
#>

$cd   = $pwd
$path = $env:path
$src  = $env:BUILD_SOURCESDIRECTORY

$base_path = "C:\Windows\system32;C:\Windows;C:\Windows\System32\Wbem"

$PSDefaultParameterValues['*:Encoding'] = 'utf8'

$7z_file = "7zip_ci.zip"
$7z_uri  = "https://dl.bintray.com/msp-greg/VC-OpenSSL/7zip_ci.zip"

$ruby_base = "rubyinstaller-2.5.1-2"
$ruby_uri  = "https://github.com/oneclick/rubyinstaller2/releases/download/$ruby_base/$ruby_base-x64.7z"

# zip version has no dots in version
$zlib_file = "zlib1211.zip"
$zlib_uri  = "https://zlib.net/$zlib_file"

[System.Net.ServicePointManager]::SecurityProtocol = [System.Net.SecurityProtocolType]::Tls12
$wc  = $(New-Object System.Net.WebClient)

$drv = (get-location).Drive.Name + ":"

$dl_path = "$drv\prereq"

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

#—————————————————————————————————————————————————————————————————————————  zlib
$file = "$dl_path\$zlib_file"
$wc.DownloadFile($zlib_uri, $file)
# GJL $dir = "-o$src\ext\zlib"
# Expand-Archive -Path $file -DestinationPath $dir

#——————————————————————————————————————————————————————————————————  MSYS2/MinGW
# updated 2018-10-01
$file      = "msys2-base-x86_64-20180531.tar"
$msys2_uri = "http://repo.msys2.org/distrib/x86_64"

$dir1 = "-o$dl_path"
$dir2 = "-o$drv\msys64"

Write-Host "Downloading $file"
$fp = "$dl_path\$file" + ".xz"
$uri = "$msys2_uri/$file" + ".xz"
$wc.DownloadFile($uri, $fp)
Write-Host "Processing $file"
7z.exe x $fp $dir1 1> $null
$fp = "$dl_path/$file"
$dir2 = "-o$drv"
7z.exe x $fp $dir2 1> $null
Remove-Item $dl_path\*.*

$env:path =  "$drv\ruby\bin;$drv\msys64\usr\bin;$drv\git\cmd;$env:path"

if ($env:PLATFORM -eq 'x64') {
  $march = "x86-64" ; $carch = "x86_64" ; $rarch = "x64-mingw32"  ; $mingw = "mingw64"
} else {
  $march = "i686"   ; $carch = "i686"   ; $rarch = "i386-mingw32" ; $mingw = "mingw32"
}
$chost   = "$carch-w64-mingw32"

$pre = "mingw-w64-$carch-"

$tools =  "___gdbm ___gmp ___ncurses ___openssl ___readline".replace('___', $pre)

bash.exe -c `"pacman-key --init`"
bash.exe -c `"pacman-key --populate msys2`"
bash.exe -c `"pacman-key --refresh-keys`"

$dash = "-"

Write-Host "$($dash * 78)  pacman.exe -Syu"
try   { pacman.exe -Syu --noconfirm --needed --noprogressbar 2> $null } catch {}
Write-Host "$($dash * 78)  pacman.exe -Su"
try   { pacman.exe -Su  --noconfirm --needed --noprogressbar 2> $null } catch {}
Write-Host "$($dash * 78)  pacman.exe -S base-devel"
try   { pacman.exe -S   --noconfirm --needed --noprogressbar base-devel 2> $null }
catch {}
Write-Host "$($dash * 78)  pacman.exe -S toolchain"
try   { pacman.exe -S   --noconfirm --needed --noprogressbar $($pre + 'toolchain') 2> $null }
catch {}
Write-Host "$($dash * 78)  pacman.exe -S ruby depends"
try   { pacman.exe -S   --noconfirm --needed --noprogressbar $tools.split(' ') 2> $null }
catch {}

$env:path = $path

#——————————————————————————————————————————————————  Setup Job Variables & State

# set variable BASERUBY
echo "##vso[task.setvariable variable=BASERUBY]$drv/ruby/bin/ruby.exe"

# set variable BUILD
New-Item  -Path $src\..\build -ItemType Directory 1> $null
$t = (Resolve-Path -LiteralPath $src\..\build).tostring()
echo "##vso[task.setvariable variable=BUILD]$t"

# set variable BUILD_PATH used in each step
$t = "\usr\local\bin;$drv\ruby\bin;$drv\msys64\$mingw\bin;$drv\msys64\usr\bin;$drv\git\cmd;$env:path"
echo "##vso[task.setvariable variable=BUILD_PATH]$t"

# set variable GIT pointing to the exe, RubyGems tests use it (path with no space)
New-Item -Path "$drv\git" -ItemType Junction -Value "$env:ProgramFiles\Git" 1> $null
echo "##vso[task.setvariable variable=GIT]$drv/git/cmd/git.exe"

# set variable CHOST
echo "##vso[task.setvariable variable=CHOST]$chost"

# set variable INSTALL
New-Item -Path $src\..\install -ItemType Directory 1> $null
$t = (Resolve-Path -LiteralPath $src\..\install).tostring()
$tt = $t.replace('\', '/')
echo "##vso[task.setvariable variable=INSTALL]$tt"

# set variable INSTALL_PATH
$t = "$t\bin;$drv\msys64\$mingw\bin;$drv\msys64\usr\bin;$drv\git\cmd;$env:path"
echo "##vso[task.setvariable variable=INSTALL_PATH]$t"

# set variable JOBS
echo "##vso[task.setvariable variable=JOBS]$env:NUMBER_OF_PROCESSORS"

# set variable MARCH
echo "##vso[task.setvariable variable=MARCH]$march"

# set variable MSYSTEM
$t = $mingw.ToUpper()
echo "##vso[task.setvariable variable=MSYSTEM]$t"

# set variable SRC
echo "##vso[task.setvariable variable=SRC]$src"

# set variable TMPDIR
echo "##vso[task.setvariable variable=TMPDIR]$tmpdir"

# set variable TMPDIR_W
echo "##vso[task.setvariable variable=TMPDIR_W]$tmpdir_w"

#—————————————————————————————————————————————————— not sure if below are needed

# below two items appear in MSYS2 shell printenv
echo "##vso[task.setvariable variable=MSYSTEM_CARCH]$carch"
echo "##vso[task.setvariable variable=MSYSTEM_CHOST]$chost"

# not sure if below are needed, maybe just for makepkg scripts.  See
# https://github.com/Alexpux/MSYS2-packages/blob/master/pacman/makepkg_mingw64.conf
# https://github.com/Alexpux/MSYS2-packages/blob/master/pacman/makepkg_mingw32.conf
echo "##vso[task.setvariable variable=CARCH]$carch"
echo "##vso[task.setvariable variable=MINGW_PREFIX]/mingw$bits"
