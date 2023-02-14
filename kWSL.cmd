@echo off & setlocal

:: Check if the current session is already elevated.
:: `net session` only succeeds in elevated sessions.
net session >NUL 2>&1 && goto :ELEVATED

:: Add -Wait before -Verb RunAs to wait for the reinvocation to exit.
set ELEVATE_CMDLINE=cd /d "%~dp0" ^& "%~f0" %*
powershell.exe -noprofile -c Start-Process -Verb RunAs cmd.exe \"/k $env:ELEVATE_CMDLINE\"
IF %ERRORLEVEL% == 0 (ECHO Administrator check passed...) ELSE (ECHO You need to run this command with administrative rights.  Is User Account Control enabled? && pause && goto ENDSCRIPT)

:ELEVATED
echo === Running in elevated session:
echo Script file : %~f0
echo Arguments   : %*
echo Working dir : %cd%
 
:BEGIN
COLOR 1F
SET GITORG=NullDev
SET GITPRJ=NeonWSL
SET BRANCH=master
SET BASE=https://github.com/%GITORG%/%GITPRJ%/raw/%BRANCH%
SET GETLXRUNOFFLINE=https://github.com/DDoSolitary/LxRunOffline/releases/download/v3.5.0/LxRunOffline-v3.5.0-msvc.zip
SET GETGISTCODE=https://gist.githubusercontent.com/noelbundick/9c804a710eb76e1d6a234b14abf42a52/raw/41a56a8fc20d360232b8735c322181a233f8ff5c/excludeWSL.ps1

REM ## Enable WSL if required
POWERSHELL -Command "$WSL = Get-WindowsOptionalFeature -Online -FeatureName 'Microsoft-Windows-Subsystem-Linux' ; if ($WSL.State -eq 'Disabled') {Enable-WindowsOptionalFeature -FeatureName $WSL.FeatureName -Online}"

REM ## Find system DPI setting and get installation parameters
rem IF NOT EXIST "%TEMP%\windpi.ps1" POWERSHELL.EXE -ExecutionPolicy Bypass -Command "wget '%BASE%/windpi.ps1' -UseBasicParsing -OutFile '%TEMP%\windpi.ps1'"
FOR /f "delims=" %%a in ('powershell -ExecutionPolicy bypass -command "%TEMP%\windpi.ps1" ') do set "WINDPI=%%a"
:DI
CLS && SET RUNSTART=%date% @ %time:~0,5%
IF EXIST .\CMD.EXE CD ..\..

ECHO [NeonWSL Installer: Modified Feb. 14th, 2022]
ECHO:
ECHO Script started at [%TIME:~0,8%] [%DATE%]
SET RDPPRT=3399& SET /p RDPPRT=Port number for xRDP traffic or hit Enter to use default [3399]: 
SET SSHPRT=3322& SET /p SSHPRT=Port number for SSHd traffic or hit Enter to use default [3322]: 
                 SET /p WINDPI=Set a custom DPI scale, or hit Enter for Windows default [%WINDPI%]: 
FOR /f "delims=" %%a in ('PowerShell -Command "%WINDPI% * 96" ') do set "LINDPI=%%a"
FOR /f "delims=" %%a in ('PowerShell -Command 40 * "%WINDPI%" ') do set "KPANEL=%%a"
SET DEFEXL=NONO& SET /p DEFEXL=[Not recommended, but speeds up the process] Type X to eXclude from Windows Defender: 
REM ## Ask for WSL 1 or 2
SET WSLVER=1& SET /p WSLVER=Please specify if you want this instance to run as WSL1 or WSL2 [1]: 
REM ## Download Ubuntu and install packages
SET NEONWSLVER=focal& SET /p NEONWSLVER=Which LTE version of Ubuntu do you want to use? Options are bionic (18.04), focal (20.04), or jammy (22.04) [focal]: 
:ope
rem ready for the path?
SET DISTRODESTINATION=%USERPROFILE%& SET /p DISTRODESTINATION=Please provide a path to install this. By default it installs in the user folder. [%USERPROFILE%]:
SET DISTROFULL=%DISTRODESTINATION%\%DISTRO%
SET _rlt=%DISTROFULL:~2,2%
rem not sure why we'd be using a remote folder
rem IF "%_rlt%"=="\\" SET DISTROFULL=%CD%%DISTRO%
ECHO Set a name for this KDE Neon instance.  Hit Enter to use default. 
SET DISTRO=NeonWSL-%NEONWSLVER%& SET /p DISTRO=Keep this name simple, no space or underscore characters [NeonWSL-%NEONWSLVER%]:
WSL.EXE -d %DISTRO% -e . > "%TEMP%\InstCheck.tmp"
FOR /f %%i in ("%TEMP%\InstCheck.tmp") do set CHKIN=%%~zi 
SET GO="%DISTROFULL%\LxRunOffline.exe" r -n "%DISTRO%" -c
IF %CHKIN% == 0 (ECHO. & ECHO There is a WSL distribution registered with that name; uninstall it or choose a new name. & PAUSE & GOTO ope)
IF %NEONWSLVER% == bionic (IF NOT EXIST "%TEMP%\bionic.tar.gz" POWERSHELL.EXE -Command "Start-BitsTransfer -source https://cloud-images.ubuntu.com/bionic/current/bionic-server-cloudimg-amd64-wsl.rootfs.tar.gz -destination '%TEMP%\bionic.tar.gz'")
IF %NEONWSLVER% == focal (IF NOT EXIST "%TEMP%\focal.tar.gz" POWERSHELL.EXE -Command "Start-BitsTransfer -source https://cloud-images.ubuntu.com/focal/current/focal-server-cloudimg-amd64-wsl.rootfs.tar.gz -destination '%TEMP%\focal.tar.gz'")
IF %NEONWSLVER% == jammy (IF NOT EXIST "%TEMP%\jammy.tar.gz" POWERSHELL.EXE -Command "Start-BitsTransfer -source https://cloud-images.ubuntu.com/wsl/jammy/current/ubuntu-jammy-wsl-amd64-wsl.rootfs.tar.gz -destination '%TEMP%\jammy.tar.gz'")
rem need to refactor the trap...
rem IF ELSE (ECHO. & ECHO Umm, your response did not match the versions listed. Please press enter and try again. & PAUSE & GOTO ope)

%DISTROFULL:~0,1%: & MKDIR "%DISTROFULL%" & CD "%DISTROFULL%" & MKDIR logs > NUL
(ECHO [kWSL Inputs] && ECHO. && ECHO.   Distro: %DISTRO% && ECHO.     Path: %DISTROFULL% && ECHO. RDP Port: %RDPPRT% && ECHO. SSH Port: %SSHPRT% && ECHO.DPI Scale: %WINDPI% && ECHO.) > ".\logs\%TIME:~0,2%%TIME:~3,2%%TIME:~6,2% kWSL Inputs.log"

ECHO:
ECHO [%TIME:~0,8%] Creating Removal Script

ECHO @COLOR 1F                                                                                                >  "%DISTROFULL%\Uninstall %DISTRO%.cmd"
ECHO @ECHO Uninstall %DISTRO%?                                                                                >> "%DISTROFULL%\Uninstall %DISTRO%.cmd"
ECHO @PAUSE                                                                                                   >> "%DISTROFULL%\Uninstall %DISTRO%.cmd"
ECHO @COPY /Y "%DISTROFULL%\LxRunOffline.exe" "%APPDATA%"                                                     >> "%DISTROFULL%\Uninstall %DISTRO%.cmd"
ECHO @POWERSHELL -Command "Remove-Item ([Environment]::GetFolderPath('Desktop')+'\%DISTRO% (*) Console.cmd')" >> "%DISTROFULL%\Uninstall %DISTRO%.cmd"
ECHO @POWERSHELL -Command "Remove-Item ([Environment]::GetFolderPath('Desktop')+'\%DISTRO% (*) Desktop.rdp')" >> "%DISTROFULL%\Uninstall %DISTRO%.cmd"
ECHO @SCHTASKS /Delete /TN:%DISTRO% /F                                                                        >> "%DISTROFULL%\Uninstall %DISTRO%.cmd"
ECHO @CLS                                                                                                     >> "%DISTROFULL%\Uninstall %DISTRO%.cmd"
ECHO @ECHO Uninstalling %DISTRO%, please wait...                                                              >> "%DISTROFULL%\Uninstall %DISTRO%.cmd"
ECHO @CD ..                                                                                                   >> "%DISTROFULL%\Uninstall %DISTRO%.cmd"
ECHO @WSLCONFIG /T %DISTRO%                                                                                   >> "%DISTROFULL%\Uninstall %DISTRO%.cmd"
ECHO @"%APPDATA%\LxRunOffline.exe" ur -n %DISTRO%                                                             >> "%DISTROFULL%\Uninstall %DISTRO%.cmd"
ECHO @NETSH AdvFirewall Firewall del rule name="%DISTRO% xRDP"                                                >> "%DISTROFULL%\Uninstall %DISTRO%.cmd"   
ECHO @NETSH AdvFirewall Firewall del rule name="%DISTRO% Secure Shell"                                        >> "%DISTROFULL%\Uninstall %DISTRO%.cmd"
ECHO @NETSH AdvFirewall Firewall del rule name="%DISTRO% KDE Connect"                                         >> "%DISTROFULL%\Uninstall %DISTRO%.cmd"
ECHO @NETSH AdvFirewall Firewall del rule name="%DISTRO% KDEinit"                                             >> "%DISTROFULL%\Uninstall %DISTRO%.cmd"
ECHO @RD /S /Q "%DISTROFULL%"                                                                                 >> "%DISTROFULL%\Uninstall %DISTRO%.cmd"


ECHO [%TIME:~0,8%] Fetching LXRunOffline
IF NOT EXIST "%DISTROFULL%\LxRunOffline-v3.5.0-msvc.zip" POWERSHELL.EXE -Command "Invoke-WebRequest -Uri %GETLXRUNOFFLINE% -OutFile '%DISTROFULL%\LxRunOffline-v3.5.0-msvc.zip'"
ECHO [%TIME:~0,8%] Extracting LXRunOffline
IF NOT EXIST "%DISTROFULL%\LxRunOffline\LxRunOffline.exe" POWERSHELL.EXE -ExecutionPolicy Bypass -Command "Expand-Archive -Path 'LxRunOffline-v3.5.0-msvc.zip' -DestinationPath '%DISTROFULL%\LxRunOffline'"
IF NOT EXIST "%DISTROFULL%\LxRunOffline.exe" POWERSHELL.EXE -Command "Copy-Item '%DISTROFULL%\LxRunOffline\LxRunOffline.exe' -Destination '%DISTROFULL%'"
POWERSHELL.EXE -Command "Copy-Item '%DISTROFULL%\LxRunOffline\LxRunOffline.exe' -Destination '%TEMP%'"
rem Whitelist folder for windows defender
IF %DEFEXL%==X (POWERSHELL.EXE -Command "wget %GETGISTCODE% -UseBasicParsing -OutFile '%DISTROFULL%\excludeWSL.ps1'" & START /WAIT /MIN "Add exclusions in Windows Defender" "POWERSHELL.EXE" "-ExecutionPolicy" "Bypass" "-Command" ".\excludeWSL.ps1" "%DISTROFULL%")
ECHO [%TIME:~0,8%] Installing kWSL Distro [%DISTRO%] to "%DISTROFULL%" & ECHO This will take a few minutes, please wait...
ECHO:& ECHO [%TIME:~0,8%] Importing distro userspace (~1m30s)
IF %NEONWSLVER% == bionic (START /WAIT /MIN "Installing Ubuntu Bionic Base..." "%TEMP%\LxRunOffline.exe" "i" "-n" "%DISTRO%" "-f" "%TEMP%\bionic.tar.gz" "-d" "%DISTROFULL%")
IF %NEONWSLVER% == focal (START /WAIT /MIN "Installing Ubuntu Focal Base..." "%TEMP%\LxRunOffline.exe" "i" "-n" "%DISTRO%" "-f" "%TEMP%\focal.tar.gz" "-d" "%DISTROFULL%")
IF %NEONWSLVER% == jammy (START /WAIT /MIN "Installing Ubuntu Jammy Base..." "%TEMP%\LxRunOffline.exe" "i" "-n" "%DISTRO%" "-f" "%TEMP%\jammy.tar.gz" "-d" "%DISTROFULL%")
(FOR /F "usebackq delims=" %%v IN (`PowerShell -Command "whoami"`) DO set "WAI=%%v")
ICACLS "%DISTROFULL:~0,-1%" /grant "%WAI%":(CI)(OI)F
(COPY /Y "%TEMP%\LxRunOffline.exe" "%DISTROFULL%" > NUL ) & "%DISTROFULL%\LxRunOffline.exe" sd -n "%DISTRO%"

IF %NEONWSLVER% == bionic (GOTO bionic-sources)
IF %NEONWSLVER% == focal (GOTO focal-sources)
IF %NEONWSLVER% == jammy (GOTO jammy-sources)
 
:bionic-sources
ECHO [%TIME:~0,8%] Update repositories and clone kWSL repo (~1m15s)
%GO% "echo 'deb http://archive.ubuntu.com/ubuntu/ bionic main restricted universe' > /etc/apt/sources.list"
%GO% "echo 'deb http://archive.ubuntu.com/ubuntu/ bionic-updates main restricted universe' >> /etc/apt/sources.list"
%GO% "echo 'deb http://security.ubuntu.com/ubuntu/ bionic-security main restricted universe' >> /etc/apt/sources.list"
%GO% "echo 'deb http://downloads.sourceforge.net/project/ubuntuzilla/mozilla/apt all main' > /etc/apt/sources.list.d/mozilla.list"
%GO% "echo 'deb http://archive.neon.kde.org/user/ bionic main' >>  /etc/apt/sources.list.d/neon.list"
%GO% "rm -rf /etc/apt/apt.conf.d/20snapd.conf /etc/rc2.d/S01whoopsie /etc/init.d/console-setup.sh" 

:focal-sources
ECHO [%TIME:~0,8%] Update repositories and clone kWSL repo (~1m15s)
%GO% "echo 'deb http://archive.ubuntu.com/ubuntu/ focal main restricted universe' > /etc/apt/sources.list"
%GO% "echo 'deb http://archive.ubuntu.com/ubuntu/ focal-updates main restricted universe' >> /etc/apt/sources.list"
%GO% "echo 'deb http://security.ubuntu.com/ubuntu/ focal-security main restricted universe' >> /etc/apt/sources.list"
%GO% "echo 'deb http://downloads.sourceforge.net/project/ubuntuzilla/mozilla/apt all main' > /etc/apt/sources.list.d/mozilla.list"
%GO% "echo 'deb http://archive.neon.kde.org/user/ focal main' >>  /etc/apt/sources.list.d/neon.list"
%GO% "rm -rf /etc/apt/apt.conf.d/20snapd.conf /etc/rc2.d/S01whoopsie /etc/init.d/console-setup.sh" 

:jammy-sources
ECHO [%TIME:~0,8%] Update repositories and clone kWSL repo (~1m15s)
%GO% "echo 'deb http://archive.ubuntu.com/ubuntu/ jammy main restricted universe' > /etc/apt/sources.list"
%GO% "echo 'deb http://archive.ubuntu.com/ubuntu/ jammy-updates main restricted universe' >> /etc/apt/sources.list"
%GO% "echo 'deb http://security.ubuntu.com/ubuntu/ jammy-security main restricted universe' >> /etc/apt/sources.list"
%GO% "echo 'deb http://downloads.sourceforge.net/project/ubuntuzilla/mozilla/apt all main' > /etc/apt/sources.list.d/mozilla.list"
%GO% "echo 'deb http://archive.neon.kde.org/user/ jammy main' >>  /etc/apt/sources.list.d/neon.list"
%GO% "rm -rf /etc/apt/apt.conf.d/20snapd.conf /etc/rc2.d/S01whoopsie /etc/init.d/console-setup.sh" 

:APTRELY
START /MIN /WAIT "Git Clone kWSL" %GO% "cd /tmp ; git clone -b %BRANCH% --depth=1 https://github.com/%GITORG%/%GITPRJ%.git"
START /MIN /WAIT "Acquire KDE Neon Keys" %GO% "apt-key adv --recv-keys --keyserver keyserver.ubuntu.com E6D4736255751E5D"
START /MIN /WAIT "Acquire Mozilla Seamonkey Keys" %GO% "apt-key adv --recv-keys --keyserver keyserver.ubuntu.com 2667CA5C"
START /MIN /WAIT "apt-get update" %GO% "apt-get update 2> /tmp/apterr" && pause
rem jammy breaks here...
rem FOR /F %%A in ("%DISTROFULL%\rootfs\tmp\apterr") do If %%~zA NEQ 0 GOTO APTRELY 

IF %NEONWSLVER% == bionic (GOTO apt-fast-bionic)
IF %NEONWSLVER% == focal (GOTO apt-fast-focal)
IF %NEONWSLVER% == jammy (GOTO apt-fast-jammy)

:apt-fast-bionic
START /MIN /WAIT "apt-fast" %GO% "DEBIAN_FRONTEND=noninteractive dpkg -i /tmp/kWSL/deb/aria2_1.35.0-1build1_amd64.deb /tmp/kWSL/deb/libaria2-0_1.35.0-1build1_amd64.deb /tmp/kWSL/deb/libssh2-1_1.8.0-2.1build1_amd64.deb /tmp/kWSL/deb/libc-ares2_1.15.0-1build1_amd64.deb ; chmod +x /tmp/kWSL/dist/usr/local/bin/apt-fast ; cp -p /tmp/kWSL/dist/usr/local/bin/apt-fast /usr/local/bin" > NUL

ECHO [%TIME:~0,8%] Remove un-needed packages (~1m30s)
%GO% "DEBIAN_FRONTEND=noninteractive apt-get -y purge apparmor apport bolt cloud-init cloud-initramfs-copymods cloud-initramfs-dyn-netconf cryptsetup cryptsetup-initramfs dmeventd finalrd fwupd initramfs-tools initramfs-tools-core irqbalance isc-dhcp-client klibc-utils kpartx libaio1 libarchive13 libdevmapper-event1.02.1 libdns-export1109 libefiboot1 libefivar1 libestr0 libfastjson4 libfwupd2 libfwupdplugin1 libgcab-1.0-0 libgpgme11 libgudev-1.0-0 libgusb2 libisc-export1105 libisns0 libjson-glib-1.0-0 libjson-glib-1.0-common libklibc liblvm2cmd2.03 libmspack0 libnuma1 libsgutils2-2 libsmbios-c2 libtss2-esys0 liburcu6 libxmlb1 libxmlsec1 libxmlsec1-openssl libxslt1.1 linux-base lvm2 lz4 mdadm multipath-tools open-iscsi open-vm-tools overlayroot plymouth plymouth-theme-ubuntu-text popularity-contest sbsigntool secureboot-db sg3-utils sg3-utils-udev snapd squashfs-tools thin-provisioning-tools tpm-udev zerofree ; apt-get -y autoremove --purge" > ".\logs\%TIME:~0,2%%TIME:~3,2%%TIME:~6,2% Remove un-needed packages.log" 2>&1

ECHO [%TIME:~0,8%] Remote Desktop Components (~2m45s)
%GO% "DEBIAN_FRONTEND=noninteractive apt-fast -y install /tmp/kWSL/deb/picom_9.1-1_amd64.deb /tmp/kWSL/deb/xrdp_0.9.19-1_amd64.deb /tmp/kWSL/deb/xorgxrdp_0.2.18-1_amd64.deb /tmp/kWSL/deb/libfdk-aac1_0.1.6-1_amd64.deb /tmp/kWSL/deb/fonts-cascadia-code_2102.03-1_all.deb x11-apps x11-session-utils x11-xserver-utils dialog dumb-init inetutils-syslogd xdg-utils binutils putty unzip zip unar unzip samba-common-bin base-files ubuntu-release-upgrader-core python3-distupgrade lhasa arj unace liblhasa0 apt-config-icons apt-config-icons-hidpi apt-config-icons-large apt-config-icons-large-hidpi libgtkd-3-0 libphobos2-ldc-shared90 libvte-2.91-0 libvte-2.91-common libvted-3-0 moreutils tilix tilix-common libdbus-glib-1-2 libgdk-pixbuf2.0-bin libgtk-3-bin python3-gpg samba-dsdb-modules xbitmaps xterm --no-install-recommends" > ".\logs\%TIME:~0,2%%TIME:~3,2%%TIME:~6,2% Remote Desktop Components.log" 2>&1

ECHO [%TIME:~0,8%] KDE Neon User Edition (~7m30s)
%GO% "DEBIAN_FRONTEND=noninteractive apt-fast -y install ieee-data d-feet apulse ark aspell-en breeze-gtk-theme desktop-file-utils gdb gdbserver gstreamer1.0-plugins-base hunspell-en-us im-config javascript-common kaccounts-providers kactivities-bin kde-config-gtk-style kde-config-gtk-style-preview kde-plasma-desktop kdeconnect kdiff3 kgamma5 khelpcenter kimageformat-plugins kinfocenter kio-extras kmenuedit kpackagelauncherqml kpackagetool5 krename krusader kscreen ksshaskpass ksysguard ksysguard-data kuserfeedback-doc kwalletmanager kwin-x11 kwrited libaacs0 libappstream-glib8 libbdplus0 libcanberra-gtk3-module libcc1-0 libc-dbg libfftw3-single3 libfwupd2 libjs-jquery libkf5baloowidgets-bin libkf5config-bin libkf5dbusaddons-bin libkf5iconthemes-bin libkf5kdelibs4support5-bin libkf5khtml-bin libkf5pulseaudioqt2 libkf5purpose-bin libkf5xmlgui-bin libmarkdown2 libmtp-runtime libostree-1-1 libpam-kwallet5 libproxy-tools libqt5designer5 libqt5help5 libqt5multimedia5-plugins libqt5test5 media-player-info mesa-utils mesa-va-drivers debconf-kde-data libdebconf-kde1 muon p11-kit p11-kit-modules p7zip-full pulseaudio pavucontrol plasma-discover plasma-discover-common plasma-workspace-wallpapers policykit-desktop-privileges poppler-data pulseaudio-equalizer python3-dbus.mainloop.pyqt5 python3-pyqt5 python3-sip qml-module-org-kde-runnermodel qml-module-org-kde-purpose qml-module-org-kde-prison qt5-gtk-platformtheme qtspeech5-speechd-plugin qttranslations5-l10n qtwayland5 libqt5waylandcompositor5 libwayland-client0 ruby sonnet-plugins systemsettings va-driver-all xdg-dbus-proxy apt-xapian-index libqapt3 libqapt3-runtime neon-apport python3-apport python3-problem-report python3-systemd python3-xapian qapt-batch debconf-kde-helper software-properties-qt ksystemlog ubuntu-drivers-common libcanberra-pulse plasma-pa pulseaudio-module-gsettings python3-psutil xbase-clients xinit xvfb dolphin kfind kwrite libdolphinvcs5 libkuserfeedbackwidgets1 fonts-urw-base35 libgs9 libgs9-common libijs-0.35 libjbig2dec0 libkf5kexiv2-15.0.0 libokular5core9 libpaper1 libqmobipocket2 libspectre1 qml-module-org-kde-syntaxhighlighting okular okular-backends kde-spectacle libkcolorpicker0 libkf5kipi-data libkf5kipi32.0.0 libkimageannotator-common libkimageannotator0 mesa-utils-extra khotkeys kaccounts-integration libkf5guiaddons-bin libpaper-utils libvlc-bin alsa-base alsa-utils anacron distro-release-notifier dolphin-plugins drkonqi-pk-debug-installer fonts-noto-color-emoji fonts-noto-core fonts-noto-hinted fonts-noto-ui-core ghostscript ghostscript-x gwenview inputattach kdegraphics-thumbnailers kdeplasma-addons-data kross ksystemstats kwin-addons libaio1 libappimage0 libatopology2 libcfitsio8 libglu1-mesa libiw30 libjasper4 libkf5krosscore5 libkf5krossui5 libkf5unitconversion-data libkf5unitconversion5 libmng2 libqt5script5 libqt5xmlpatterns5 libraw19 libtinyxml2-6a linux-sound-base neon-adwaita neon-configure-inotify neon-keyring neon-settings-2 neon-ubuntu-advantage-tools plasma-calendar-addons plasma-dataengines-addons plasma-runners-addons plasma-systemmonitor plasma-vault plasma-wallpapers-addons plasma-widgets-addons qml-module-org-kde-breeze qml-module-org-kde-kio qml-module-qt-labs-qmlmodels qml-module-qtquick-xmllistmodel qml-module-qtwebengine qt5-image-formats-plugins ubuntu-release-upgrader-qt xfonts-base xfonts-encodings xfonts-utils xinput --no-install-recommends" > ".\logs\%TIME:~0,2%%TIME:~3,2%%TIME:~6,2% KDE Neon User Edition.log" 2>&1

ECHO [%TIME:~0,8%] Install Web Browser and CRD (~1m30s)
%GO% "DEBIAN_FRONTEND=noninteractive apt-fast -y install falkon seamonkey-mozilla-build vlc vlc-bin vlc-l10n vlc-plugin-notify vlc-plugin-qt vlc-plugin-samba vlc-plugin-skins2 vlc-plugin-video-splitter vlc-plugin-visualization --no-install-recommends ; update-alternatives --install /usr/bin/www-browser www-browser /usr/bin/seamonkey 100 ; update-alternatives --install /usr/bin/gnome-www-browser gnome-www-browser /usr/bin/seamonkey 100 ; update-alternatives --install /usr/bin/x-www-browser x-www-browser /usr/bin/seamonkey 100 ; cd /tmp/kWSL/deb ; wget -q https://dl.google.com/linux/direct/chrome-remote-desktop_current_amd64.deb ; dpkg -i /tmp/kWSL/deb/chrome-remote-desktop_current_amd64.deb" > ".\logs\%TIME:~0,2%%TIME:~3,2%%TIME:~6,2% Web Browser and CRD.log" 2>&1

:apt-fast-focal
START /MIN /WAIT "apt-fast" %GO% "DEBIAN_FRONTEND=noninteractive dpkg -i /tmp/kWSL/deb/aria2_1.35.0-1build1_amd64.deb /tmp/kWSL/deb/libaria2-0_1.35.0-1build1_amd64.deb /tmp/kWSL/deb/libssh2-1_1.8.0-2.1build1_amd64.deb /tmp/kWSL/deb/libc-ares2_1.15.0-1build1_amd64.deb ; chmod +x /tmp/kWSL/dist/usr/local/bin/apt-fast ; cp -p /tmp/kWSL/dist/usr/local/bin/apt-fast /usr/local/bin" > NUL

ECHO [%TIME:~0,8%] Remove un-needed packages (~1m30s)
%GO% "DEBIAN_FRONTEND=noninteractive apt-get -y purge apparmor apport bolt cloud-init cloud-initramfs-copymods cloud-initramfs-dyn-netconf cryptsetup cryptsetup-initramfs dmeventd finalrd fwupd initramfs-tools initramfs-tools-core irqbalance isc-dhcp-client klibc-utils kpartx libaio1 libarchive13 libdevmapper-event1.02.1 libdns-export1109 libefiboot1 libefivar1 libestr0 libfastjson4 libfwupd2 libfwupdplugin1 libgcab-1.0-0 libgpgme11 libgudev-1.0-0 libgusb2 libisc-export1105 libisns0 libjson-glib-1.0-0 libjson-glib-1.0-common libklibc liblvm2cmd2.03 libmspack0 libnuma1 libsgutils2-2 libsmbios-c2 libtss2-esys0 liburcu6 libxmlb1 libxmlsec1 libxmlsec1-openssl libxslt1.1 linux-base lvm2 lz4 mdadm multipath-tools open-iscsi open-vm-tools overlayroot plymouth plymouth-theme-ubuntu-text popularity-contest sbsigntool secureboot-db sg3-utils sg3-utils-udev snapd squashfs-tools thin-provisioning-tools tpm-udev zerofree ; apt-get -y autoremove --purge" > ".\logs\%TIME:~0,2%%TIME:~3,2%%TIME:~6,2% Remove un-needed packages.log" 2>&1

ECHO [%TIME:~0,8%] Remote Desktop Components (~2m45s)
%GO% "DEBIAN_FRONTEND=noninteractive apt-fast -y install /tmp/kWSL/deb/picom_9.1-1_amd64.deb /tmp/kWSL/deb/xrdp_0.9.19-1_amd64.deb /tmp/kWSL/deb/xorgxrdp_0.2.18-1_amd64.deb /tmp/kWSL/deb/libfdk-aac1_0.1.6-1_amd64.deb /tmp/kWSL/deb/fonts-cascadia-code_2102.03-1_all.deb x11-apps x11-session-utils x11-xserver-utils dialog dumb-init inetutils-syslogd xdg-utils binutils putty unzip zip unar unzip samba-common-bin base-files ubuntu-release-upgrader-core python3-distupgrade lhasa arj unace liblhasa0 apt-config-icons apt-config-icons-hidpi apt-config-icons-large apt-config-icons-large-hidpi libgtkd-3-0 libphobos2-ldc-shared90 libvte-2.91-0 libvte-2.91-common libvted-3-0 moreutils tilix tilix-common libdbus-glib-1-2 libgdk-pixbuf2.0-bin libgtk-3-bin python3-gpg samba-dsdb-modules xbitmaps xterm --no-install-recommends" > ".\logs\%TIME:~0,2%%TIME:~3,2%%TIME:~6,2% Remote Desktop Components.log" 2>&1

ECHO [%TIME:~0,8%] KDE Neon User Edition (~7m30s)
%GO% "DEBIAN_FRONTEND=noninteractive apt-fast -y install ieee-data d-feet apulse ark aspell-en breeze-gtk-theme desktop-file-utils gdb gdbserver gstreamer1.0-plugins-base hunspell-en-us im-config javascript-common kaccounts-providers kactivities-bin kde-config-gtk-style kde-config-gtk-style-preview kde-plasma-desktop kdeconnect kdiff3 kgamma5 khelpcenter kimageformat-plugins kinfocenter kio-extras kmenuedit kpackagelauncherqml kpackagetool5 krename krusader kscreen ksshaskpass ksysguard ksysguard-data kuserfeedback-doc kwalletmanager kwin-x11 kwrited libaacs0 libappstream-glib8 libbdplus0 libcanberra-gtk3-module libcc1-0 libc-dbg libfftw3-single3 libfwupd2 libjs-jquery libkf5baloowidgets-bin libkf5config-bin libkf5dbusaddons-bin libkf5iconthemes-bin libkf5kdelibs4support5-bin libkf5khtml-bin libkf5pulseaudioqt2 libkf5purpose-bin libkf5xmlgui-bin libmarkdown2 libmtp-runtime libostree-1-1 libpam-kwallet5 libproxy-tools libqt5designer5 libqt5help5 libqt5multimedia5-plugins libqt5test5 media-player-info mesa-utils mesa-va-drivers debconf-kde-data libdebconf-kde1 muon p11-kit p11-kit-modules p7zip-full pulseaudio pavucontrol plasma-discover plasma-discover-common plasma-workspace-wallpapers policykit-desktop-privileges poppler-data pulseaudio-equalizer python3-dbus.mainloop.pyqt5 python3-pyqt5 python3-sip qml-module-org-kde-runnermodel qml-module-org-kde-purpose qml-module-org-kde-prison qt5-gtk-platformtheme qtspeech5-speechd-plugin qttranslations5-l10n qtwayland5 libqt5waylandcompositor5 libwayland-client0 ruby sonnet-plugins systemsettings va-driver-all xdg-dbus-proxy apt-xapian-index libqapt3 libqapt3-runtime neon-apport python3-apport python3-problem-report python3-systemd python3-xapian qapt-batch debconf-kde-helper software-properties-qt ksystemlog ubuntu-drivers-common libcanberra-pulse plasma-pa pulseaudio-module-gsettings python3-psutil xbase-clients xinit xvfb dolphin kfind kwrite libdolphinvcs5 libkuserfeedbackwidgets1 fonts-urw-base35 libgs9 libgs9-common libijs-0.35 libjbig2dec0 libkf5kexiv2-15.0.0 libokular5core9 libpaper1 libqmobipocket2 libspectre1 qml-module-org-kde-syntaxhighlighting okular okular-backends kde-spectacle libkcolorpicker0 libkf5kipi-data libkf5kipi32.0.0 libkimageannotator-common libkimageannotator0 mesa-utils-extra khotkeys kaccounts-integration libkf5guiaddons-bin libpaper-utils libvlc-bin alsa-base alsa-utils anacron distro-release-notifier dolphin-plugins drkonqi-pk-debug-installer fonts-noto-color-emoji fonts-noto-core fonts-noto-hinted fonts-noto-ui-core ghostscript ghostscript-x gwenview inputattach kdegraphics-thumbnailers kdeplasma-addons-data kross ksystemstats kwin-addons libaio1 libappimage0 libatopology2 libcfitsio8 libglu1-mesa libiw30 libjasper4 libkf5krosscore5 libkf5krossui5 libkf5unitconversion-data libkf5unitconversion5 libmng2 libqt5script5 libqt5xmlpatterns5 libraw19 libtinyxml2-6a linux-sound-base neon-adwaita neon-configure-inotify neon-keyring neon-settings-2 neon-ubuntu-advantage-tools plasma-calendar-addons plasma-dataengines-addons plasma-runners-addons plasma-systemmonitor plasma-vault plasma-wallpapers-addons plasma-widgets-addons qml-module-org-kde-breeze qml-module-org-kde-kio qml-module-qt-labs-qmlmodels qml-module-qtquick-xmllistmodel qml-module-qtwebengine qt5-image-formats-plugins ubuntu-release-upgrader-qt xfonts-base xfonts-encodings xfonts-utils xinput --no-install-recommends" > ".\logs\%TIME:~0,2%%TIME:~3,2%%TIME:~6,2% KDE Neon User Edition.log" 2>&1

ECHO [%TIME:~0,8%] Install Web Browser and CRD (~1m30s)
%GO% "DEBIAN_FRONTEND=noninteractive apt-fast -y install falkon seamonkey-mozilla-build vlc vlc-bin vlc-l10n vlc-plugin-notify vlc-plugin-qt vlc-plugin-samba vlc-plugin-skins2 vlc-plugin-video-splitter vlc-plugin-visualization --no-install-recommends ; update-alternatives --install /usr/bin/www-browser www-browser /usr/bin/seamonkey 100 ; update-alternatives --install /usr/bin/gnome-www-browser gnome-www-browser /usr/bin/seamonkey 100 ; update-alternatives --install /usr/bin/x-www-browser x-www-browser /usr/bin/seamonkey 100 ; cd /tmp/kWSL/deb ; wget -q https://dl.google.com/linux/direct/chrome-remote-desktop_current_amd64.deb ; dpkg -i /tmp/kWSL/deb/chrome-remote-desktop_current_amd64.deb" > ".\logs\%TIME:~0,2%%TIME:~3,2%%TIME:~6,2% Web Browser and CRD.log" 2>&1

:apt-fast-jammy
START /MIN /WAIT "apt-fast" %GO% "DEBIAN_FRONTEND=noninteractive dpkg -i /tmp/kWSL/deb/aria2_1.35.0-1build1_amd64.deb /tmp/kWSL/deb/libaria2-0_1.35.0-1build1_amd64.deb /tmp/kWSL/deb/libssh2-1_1.8.0-2.1build1_amd64.deb /tmp/kWSL/deb/libc-ares2_1.15.0-1build1_amd64.deb ; chmod +x /tmp/kWSL/dist/usr/local/bin/apt-fast ; cp -p /tmp/kWSL/dist/usr/local/bin/apt-fast /usr/local/bin" > NUL

ECHO [%TIME:~0,8%] Remove un-needed packages (~1m30s)
%GO% "DEBIAN_FRONTEND=noninteractive apt-get -y purge apparmor apport bolt cloud-init cloud-initramfs-copymods cloud-initramfs-dyn-netconf cryptsetup cryptsetup-initramfs dmeventd finalrd fwupd initramfs-tools initramfs-tools-core irqbalance isc-dhcp-client klibc-utils kpartx libaio1 libarchive13 libdevmapper-event1.02.1 libdns-export1109 libefiboot1 libefivar1 libestr0 libfastjson4 libfwupd2 libfwupdplugin1 libgcab-1.0-0 libgpgme11 libgudev-1.0-0 libgusb2 libisc-export1105 libisns0 libjson-glib-1.0-0 libjson-glib-1.0-common libklibc liblvm2cmd2.03 libmspack0 libnuma1 libsgutils2-2 libsmbios-c2 libtss2-esys0 liburcu6 libxmlb1 libxmlsec1 libxmlsec1-openssl libxslt1.1 linux-base lvm2 lz4 mdadm multipath-tools open-iscsi open-vm-tools overlayroot plymouth plymouth-theme-ubuntu-text popularity-contest sbsigntool secureboot-db sg3-utils sg3-utils-udev snapd squashfs-tools thin-provisioning-tools tpm-udev zerofree ; apt-get -y autoremove --purge" > ".\logs\%TIME:~0,2%%TIME:~3,2%%TIME:~6,2% Remove un-needed packages.log" 2>&1

ECHO [%TIME:~0,8%] Remote Desktop Components (~2m45s)
%GO% "DEBIAN_FRONTEND=noninteractive apt-fast -y install /tmp/kWSL/deb/picom_9.1-1_amd64.deb /tmp/kWSL/deb/xrdp_0.9.19-1_amd64.deb /tmp/kWSL/deb/xorgxrdp_0.2.18-1_amd64.deb /tmp/kWSL/deb/libfdk-aac1_0.1.6-1_amd64.deb /tmp/kWSL/deb/fonts-cascadia-code_2102.03-1_all.deb x11-apps x11-session-utils x11-xserver-utils dialog dumb-init inetutils-syslogd xdg-utils binutils putty unzip zip unar unzip samba-common-bin base-files ubuntu-release-upgrader-core python3-distupgrade lhasa arj unace liblhasa0 apt-config-icons apt-config-icons-hidpi apt-config-icons-large apt-config-icons-large-hidpi libgtkd-3-0 libphobos2-ldc-shared90 libvte-2.91-0 libvte-2.91-common libvted-3-0 moreutils tilix tilix-common libdbus-glib-1-2 libgdk-pixbuf2.0-bin libgtk-3-bin python3-gpg samba-dsdb-modules xbitmaps xterm --no-install-recommends" > ".\logs\%TIME:~0,2%%TIME:~3,2%%TIME:~6,2% Remote Desktop Components.log" 2>&1

ECHO [%TIME:~0,8%] KDE Neon User Edition (~7m30s)
%GO% "DEBIAN_FRONTEND=noninteractive apt-fast -y install ieee-data d-feet apulse ark aspell-en breeze-gtk-theme desktop-file-utils gdb gdbserver gstreamer1.0-plugins-base hunspell-en-us im-config javascript-common kaccounts-providers kactivities-bin kde-config-gtk-style kde-config-gtk-style-preview kde-plasma-desktop kdeconnect kdiff3 kgamma5 khelpcenter kimageformat-plugins kinfocenter kio-extras kmenuedit kpackagelauncherqml kpackagetool5 krename krusader kscreen ksshaskpass ksysguard ksysguard-data kuserfeedback-doc kwalletmanager kwin-x11 kwrited libaacs0 libappstream-glib8 libbdplus0 libcanberra-gtk3-module libcc1-0 libc-dbg libfftw3-single3 libfwupd2 libjs-jquery libkf5baloowidgets-bin libkf5config-bin libkf5dbusaddons-bin libkf5iconthemes-bin libkf5kdelibs4support5-bin libkf5khtml-bin libkf5pulseaudioqt2 libkf5purpose-bin libkf5xmlgui-bin libmarkdown2 libmtp-runtime libostree-1-1 libpam-kwallet5 libproxy-tools libqt5designer5 libqt5help5 libqt5multimedia5-plugins libqt5test5 media-player-info mesa-utils mesa-va-drivers debconf-kde-data libdebconf-kde1 muon p11-kit p11-kit-modules p7zip-full pulseaudio pavucontrol plasma-discover plasma-discover-common plasma-workspace-wallpapers policykit-desktop-privileges poppler-data pulseaudio-equalizer python3-dbus.mainloop.pyqt5 python3-pyqt5 python3-sip qml-module-org-kde-runnermodel qml-module-org-kde-purpose qml-module-org-kde-prison qt5-gtk-platformtheme qtspeech5-speechd-plugin qttranslations5-l10n qtwayland5 libqt5waylandcompositor5 libwayland-client0 ruby sonnet-plugins systemsettings va-driver-all xdg-dbus-proxy apt-xapian-index libqapt3 libqapt3-runtime neon-apport python3-apport python3-problem-report python3-systemd python3-xapian qapt-batch debconf-kde-helper software-properties-qt ksystemlog ubuntu-drivers-common libcanberra-pulse plasma-pa pulseaudio-module-gsettings python3-psutil xbase-clients xinit xvfb dolphin kfind kwrite libdolphinvcs5 libkuserfeedbackwidgets1 fonts-urw-base35 libgs9 libgs9-common libijs-0.35 libjbig2dec0 libkf5kexiv2-15.0.0 libokular5core9 libpaper1 libqmobipocket2 libspectre1 qml-module-org-kde-syntaxhighlighting okular okular-backends kde-spectacle libkcolorpicker0 libkf5kipi-data libkf5kipi32.0.0 libkimageannotator-common libkimageannotator0 mesa-utils-extra khotkeys kaccounts-integration libkf5guiaddons-bin libpaper-utils libvlc-bin alsa-base alsa-utils anacron distro-release-notifier dolphin-plugins drkonqi-pk-debug-installer fonts-noto-color-emoji fonts-noto-core fonts-noto-hinted fonts-noto-ui-core ghostscript ghostscript-x gwenview inputattach kdegraphics-thumbnailers kdeplasma-addons-data kross ksystemstats kwin-addons libaio1 libappimage0 libatopology2 libcfitsio8 libglu1-mesa libiw30 libjasper4 libkf5krosscore5 libkf5krossui5 libkf5unitconversion-data libkf5unitconversion5 libmng2 libqt5script5 libqt5xmlpatterns5 libraw19 libtinyxml2-6a linux-sound-base neon-adwaita neon-configure-inotify neon-keyring neon-settings-2 neon-ubuntu-advantage-tools plasma-calendar-addons plasma-dataengines-addons plasma-runners-addons plasma-systemmonitor plasma-vault plasma-wallpapers-addons plasma-widgets-addons qml-module-org-kde-breeze qml-module-org-kde-kio qml-module-qt-labs-qmlmodels qml-module-qtquick-xmllistmodel qml-module-qtwebengine qt5-image-formats-plugins ubuntu-release-upgrader-qt xfonts-base xfonts-encodings xfonts-utils xinput --no-install-recommends" > ".\logs\%TIME:~0,2%%TIME:~3,2%%TIME:~6,2% KDE Neon User Edition.log" 2>&1

ECHO [%TIME:~0,8%] Install Web Browser and CRD (~1m30s)
%GO% "DEBIAN_FRONTEND=noninteractive apt-fast -y install falkon seamonkey-mozilla-build vlc vlc-bin vlc-l10n vlc-plugin-notify vlc-plugin-qt vlc-plugin-samba vlc-plugin-skins2 vlc-plugin-video-splitter vlc-plugin-visualization --no-install-recommends ; update-alternatives --install /usr/bin/www-browser www-browser /usr/bin/seamonkey 100 ; update-alternatives --install /usr/bin/gnome-www-browser gnome-www-browser /usr/bin/seamonkey 100 ; update-alternatives --install /usr/bin/x-www-browser x-www-browser /usr/bin/seamonkey 100 ; cd /tmp/kWSL/deb ; wget -q https://dl.google.com/linux/direct/chrome-remote-desktop_current_amd64.deb ; dpkg -i /tmp/kWSL/deb/chrome-remote-desktop_current_amd64.deb" > ".\logs\%TIME:~0,2%%TIME:~3,2%%TIME:~6,2% Web Browser and CRD.log" 2>&1

REM ## Additional items to install can go here...
REM ## %GO% "cd /tmp ; wget https://files.multimc.org/downloads/multimc_1.4-1.deb"
REM ## %GO% "apt-get -y install supertuxkart /tmp/multimc_1.4-1.deb"

ECHO [%TIME:~0,8%] Cleaning-up... (~0m45s)
%GO% "dbus-uuidgen --ensure ; ln -s -f /var/lib/dbus/machine-id /etc/machine-id ; apt-get -y purge --autoremove wpasupplicant* libnetplan0* netplan.io* avahi-daemon libnss-mdns libimobiledevice6 libplist3 libupower-glib3 libusbmuxd6 wayland-utils ubuntu-advantage-tools distro-info upower mesa-vulkan-drivers gnustep-base-runtime libgnustep-base1.26 gnustep-base-common gnustep-common libgc1c2 libobjc4 powermgmt-base unar networkd-dispatcher ; apt-get -y clean" > ".\logs\%TIME:~0,2%%TIME:~3,2%%TIME:~6,2% Final clean-up.log"

SET /A SESMAN = %RDPPRT% - 50
%GO% "which schtasks.exe" > "%TEMP%\SCHT.tmp" & set /p SCHT=<"%TEMP%\SCHT.tmp"
rem restartwsl is missing?
%GO% "sed -i 's#SCHT#%SCHT%#g' /tmp/kWSL/dist/usr/local/bin/restartwsl ; sed -i 's#DISTRO#%DISTRO%#g' /tmp/kWSL/dist/usr/local/bin/restartwsl"
%GO% "sed -i 's/QQQ/%WINDPI%/g' /tmp/kWSL/dist/etc/skel/.config/kdeglobals"
%GO% "sed -i 's/QQQ/%LINDPI%/g' /tmp/kWSL/dist/etc/skel/.config/kcmfonts"
%GO% "sed -i 's/KPANEL/%KPANEL%/g' /tmp/kWSL/dist/etc/skel/.config/plasmashellrc"
%GO% "sed -i 's/ListenPort=3350/ListenPort=%SESMAN%/g' /etc/xrdp/sesman.ini"
%GO% "sed -i 's/thinclient_drives/.kWSL/g' /etc/xrdp/sesman.ini"
%GO% "sed -i 's/port=3389/port=%RDPPRT%/g' /tmp/kWSL/dist/etc/xrdp/xrdp.ini ; cp /tmp/kWSL/dist/etc/xrdp/xrdp.ini /etc/xrdp/xrdp.ini"
%GO% "sed -i 's/#Port 22/Port %SSHPRT%/g' /etc/ssh/sshd_config"
%GO% "sed -i 's/PasswordAuthentication no/PasswordAuthentication yes/g' /etc/ssh/sshd_config"
%GO% "sed -i 's/WSLINSTANCENAME/%DISTRO%/g' /tmp/kWSL/dist/usr/local/bin/initwsl"
%GO% "sed -i 's/\\h/%DISTRO%/g' /tmp/kWSL/dist/etc/skel/.bashrc ; ln -s /usr/lib/x86_64-linux-gnu/libexec/kf5/kdesu /usr/bin/kdesu ; rm /usr/lib/x86_64-linux-gnu/qt5/plugins/discover/fwupd-backend.so"
%GO% "sed -i 's#Exec=ksystemlog -qwindowtitle %%c#Exec=kdesu -n --noignorebutton -d -- bash -c +source /etc/profile.d/kWSL.sh ; ksystemlog -qwindowtitle %%c+#g' /usr/share/applications/org.kde.ksystemlog.desktop ; sed -i 's#+#\"#g' /usr/share/applications/org.kde.ksystemlog.desktop ; sed -i 's#X-KDE-SubstituteUID=true#X-KDE-SubstituteUID=false#g' /usr/share/applications/org.kde.ksystemlog.desktop"
%GO% "sed -i 's#Exec=plasma-discover %%F#Exec=kdesu -n --noignorebutton -d -- bash -c +source /etc/profile.d/kWSL.sh ; plasma-discover --backends packagekit-backend,kns-backend %%F+#g' /usr/share/applications/org.kde.discover.desktop"
%GO% "sed -i 's#Exec=plasma-discover --mode update#Exec=kdesu -n --noignorebutton -d -- bash -c +source /etc/profile.d/kWSL.sh ; plasma-discover --backends packagekit-backend,kns-backend --mode update+#g' /usr/share/applications/org.kde.discover.desktop ; sed -i 's#+#\"#g' /usr/share/applications/org.kde.discover.desktop"
%GO% "sed -i 's#Exec=plasma-discover --mode update#Exec=kdesu -n --noignorebutton -d -- bash -c +source /etc/profile.d/kWSL.sh ; plasma-discover --backends packagekit-backend,kns-backend --mode update+#g' /usr/share/applications/org.kde.discover.urlhandler.desktop ; sed -i 's#+#\"#g' /usr/share/applications/org.kde.discover.urlhandler.desktop"
%GO% "sed -i 's#Exec=plasma-discover --mode update#Exec=kdesu -n --noignorebutton -d -- bash -c +source /etc/profile.d/kWSL.sh ; plasma-discover --backends packagekit-backend,kns-backend --mode update+#g' /usr/share/applications/org.kde.discover.apt.urlhandler.desktop ; sed -i 's#+#\"#g' /usr/share/applications/org.kde.discover.apt.urlhandler.desktop"
%GO% "sed -i 's#Exec=muon#Exec=kdesu -n --noignorebutton -d -- bash -c +source /etc/profile.d/kWSL.sh ; muon+#g' /usr/share/applications/org.kde.muon.desktop ; sed -i 's#+#\"#g' /usr/share/applications/org.kde.muon.desktop"
%GO% "cp /mnt/c/Windows/Fonts/*.ttf /usr/share/fonts/truetype ; ln -s /usr/share/plasma/desktoptheme/breeze-light /usr/share/plasma/desktoptheme/breeze"
%GO% "ssh-keygen -A ; adduser xrdp ssl-cert" > NUL
%GO% "sed -i 's/adwaita//g' /usr/share/themes/Breeze/gtk-2.0/widgets/misc ; sed -i 's/adwaita//g' /usr/share/themes/Breeze-Dark/gtk-2.0/widgets/misc ; rm -rf /usr/share/themes/Default ; cp -Rp /usr/share/themes/Breeze-Dark /usr/share/themes/Default"
%GO% "chmod 644 /tmp/kWSL/dist/etc/wsl.conf ; chmod 644 /tmp/kWSL/dist/var/lib/xrdp-pulseaudio-installer/*.so"
%GO% "chmod +x /tmp/kWSL/dist/usr/local/bin/* ; chmod 755 /tmp/kWSL/dist/usr/local/bin/* ; cp /tmp/kWSL/dist/usr/local/bin/restartwsl /tmp/kWSL/dist/etc/skel/.config/plasma-workspace/shutdown/restartwsl ; chmod -R 700 /tmp/kWSL/dist/etc/skel/.config ; chmod -R 7700 /tmp/kWSL/dist/etc/skel/.local ; chmod -R 7700 /tmp/kWSL/dist/etc/skel/.cache ; chmod 700 /tmp/kWSL/dist/etc/skel/.mozilla"
%GO% "chmod 755 /tmp/kWSL/dist/etc/profile.d/kWSL.sh ; chmod +x /tmp/kWSL/dist/etc/profile.d/kWSL.sh ; chmod 755 /tmp/kWSL/dist/etc/xrdp/startwm.sh ; chmod +x /tmp/kWSL/dist/etc/xrdp/startwm.sh"
%GO% "unamestr=`uname -r` ; if [[ "$unamestr" == '4.4.0-17763-Microsoft' ]]; then apt-get purge -y plasma-discover ; sed -i 's/discover/muon/g' /tmp/kWSL/dist/etc/skel/.config/plasma-org.kde.plasma.desktop-appletsrc ; ln -s /usr/bin/software-properties-qt /usr/bin/software-properties-kde ; fi" > NUL
%GO% "cp -Rp /tmp/kWSL/dist/* / ; cp -Rp /tmp/kWSL/dist/etc/skel/.cache /root ; cp -Rp /tmp/kWSL/dist/etc/skel/.config /root ; cp -Rp /tmp/kWSL/dist/etc/skel/.local /root"
START /MIN /WAIT "Updates for WSL1 Compatibility" "%DISTROFULL%\LxRunOffline.exe" "r" "-n" "%DISTRO%" "-c" "dpkg -i /tmp/kWSL/deb/libkf5activitiesstats*.deb /tmp/kWSL/deb/kactivitymanagerd*.deb /tmp/kWSL/deb/kinfocenter*.deb /tmp/kWSL/deb/klassy*.deb"
START /MIN /WAIT "DBUS WSL1 Packages" "%DISTROFULL%\LxRunOffline.exe" "r" "-n" "%DISTRO%" "-c" "dpkg --purge --force-all dbus dbus-x11 libdbus-1-3 dbus-user-session ; dpkg -i --force-all /tmp/kWSL/deb-dbus/libdbus-1-3_*.deb /tmp/kWSL/deb-dbus/dbus_*.deb /tmp/kWSL/deb-dbus/dbus-x11_*.deb /tmp/kWSL/deb-dbus/xdg-desktop-portal_*.deb /tmp/kWSL/deb-dbus/libdconf1_*.deb"
rem %GO% "apt-mark hold dbus dbus-x11 kactivitymanagerd kinfocenter libdbus-1-3 libkf5activitiesstats1 xdg-desktop-portal libdconf1" > NUL

SET RUNEND=%date% @ %time:~0,5%
CD %DISTROFULL% 

ECHO:
ECHO [%TIME:~0,8%] Prompt for account creation
SET /p XU=Enter name of primary user for %DISTRO%: 
POWERSHELL -Command $prd = read-host "Enter password for %XU%" -AsSecureString ; $BSTR=[System.Runtime.InteropServices.Marshal]::SecureStringToBSTR($prd) ; [System.Runtime.InteropServices.Marshal]::PtrToStringAuto($BSTR) > .tmp & set /p PWO=<.tmp
%GO% "useradd -m -p nulltemp -s /bin/bash %XU%"
%GO% "(echo '%XU%:%PWO%') | chpasswd"
%GO% "echo '%XU% ALL=(ALL) NOPASSWD:ALL' >> /etc/sudoers"
rem kWSL needs generated
%GO% "echo 'session bpp:i:32' >> /tmp/kWSL/kWSL.rdp"
%GO% "echo 'allow desktop composition:i:1' >> /tmp/kWSL/kWSL.rdp"
%GO% "echo 'connection type:i:6' >> /tmp/kWSL/kWSL.rdp"
%GO% "echo 'networkautodetect:i:0' >> /tmp/kWSL/kWSL.rdp"
%GO% "echo 'bandwidthautodetect:i:1' >> /tmp/kWSL/kWSL.rdp"
%GO% "echo 'full address:s:COMPY:RDPPRT' >> /tmp/kWSL/kWSL.rdp"
%GO% "echo 'promptcredentialonce:i:1' >> /tmp/kWSL/kWSL.rdp"
%GO% "echo 'username:s:PLACEHOLDER' >> /tmp/kWSL/kWSL.rdp"
%GO% "echo 'password 51:b:' >> /tmp/kWSL/kWSL.rdp"
%GO% "sed -i 's/PLACEHOLDER/%XU%/g' /tmp/kWSL/kWSL.rdp"
%GO% "sed -i 's/COMPY/LocalHost/g' /tmp/kWSL/kWSL.rdp"
%GO% "sed -i 's/RDPPRT/%RDPPRT%/g' /tmp/kWSL/kWSL.rdp"
%GO% "cp /tmp/kWSL/kWSL.rdp ./kWSL._"

ECHO $prd = Get-Content .tmp > .tmp.ps1
ECHO ($prd ^| ConvertTo-SecureString -AsPlainText -Force) ^| ConvertFrom-SecureString ^| Out-File .tmp >> .tmp.ps1
POWERSHELL -ExecutionPolicy Bypass -Command ./.tmp.ps1
TYPE .tmp>.tmpsec.txt
COPY /y /b kWSL._+.tmpsec.txt "%DISTROFULL%\%DISTRO% (%XU%) Desktop.rdp" > NUL
DEL /Q kWSL._ .tmp*.* > NUL

ECHO:
ECHO [%TIME:~0,8%] Open Windows Firewall Ports for xRDP, SSH, mDNS...
NETSH AdvFirewall Firewall add rule name="%DISTRO% xRDP" dir=in action=allow protocol=TCP localport=%RDPPRT% > NUL
NETSH AdvFirewall Firewall add rule name="%DISTRO% Secure Shell" dir=in action=allow protocol=TCP localport=%SSHPRT% > NUL
NETSH AdvFirewall Firewall add rule name="%DISTRO% KDE Connect" dir=in action=allow program="%DISTROFULL%\rootfs\usr\lib\x86_64-linux-gnu\libexec\kdeconnectd" enable=yes > NUL
NETSH AdvFirewall Firewall add rule name="%DISTRO% KDEinit" dir=in action=allow program="%DISTROFULL%\rootfs\usr\bin\kdeinit5" enable=yes > NUL
START /MIN "%DISTRO% Init" WSL ~ -u root -d %DISTRO% -e initwsl 2

ECHO [%TIME:~0,8%] Building RDP Connection file, Console link, Init system...

ECHO @START /MIN "%DISTRO%" WSLCONFIG.EXE /t %DISTRO%                  >  "%DISTROFULL%\Init.cmd"
ECHO @Powershell.exe -Command "Start-Sleep 3"                          >> "%DISTROFULL%\Init.cmd"
ECHO @START /MIN "%DISTRO%" WSL.EXE ~ -u root -d %DISTRO% -e initwsl 2 >> "%DISTROFULL%\Init.cmd"

ECHO @WSL ~ -u %XU% -d %DISTRO% > "%DISTROFULL%\%DISTRO% (%XU%) Console.cmd"
POWERSHELL -Command "Copy-Item '%DISTROFULL%\%DISTRO% (%XU%) Console.cmd' ([Environment]::GetFolderPath('Desktop'))"
POWERSHELL -Command "Copy-Item '%DISTROFULL%\%DISTRO% (%XU%) Desktop.rdp' ([Environment]::GetFolderPath('Desktop'))"

ECHO [%TIME:~0,8%] Building %DISTRO% XML...
ECHO <?xml version="1.0" encoding="UTF-16"?> >  "%DISTROFULL%\kWSL.xml"
ECHO <Task version="1.4" xmlns="http://schemas.microsoft.com/windows/2004/02/mit/task" >>  "%DISTROFULL%\kWSL.xml"
ECHO  <RegistrationInfo >>  "%DISTROFULL%\kWSL.xml"
ECHO    <Date>2020-09-10T15:23:22</Date> >>  "%DISTROFULL%\kWSL.xml"
ECHO    <Author>AAAA</Author> >>  "%DISTROFULL%\kWSL.xml"
ECHO    <URI>\xWSL</URI> >>  "%DISTROFULL%\kWSL.xml"
ECHO  </RegistrationInfo> >>  "%DISTROFULL%\kWSL.xml"
ECHO  <Triggers> >>  "%DISTROFULL%\kWSL.xml"
ECHO    <BootTrigger> >>  "%DISTROFULL%\kWSL.xml"
ECHO      <StartBoundary>2020-09-10T15:23:00</StartBoundary> >>  "%DISTROFULL%\kWSL.xml"
ECHO      <Enabled>true</Enabled> >>  "%DISTROFULL%\kWSL.xml"
ECHO    </BootTrigger> >>  "%DISTROFULL%\kWSL.xml"
ECHO  </Triggers> >>  "%DISTROFULL%\kWSL.xml"
ECHO  <Principals> >>  "%DISTROFULL%\kWSL.xml"
ECHO    <Principal id="Author"> >>  "%DISTROFULL%\kWSL.xml"
ECHO      <UserId>AAAA</UserId> >>  "%DISTROFULL%\kWSL.xml"
ECHO      <LogonType>InteractiveToken</LogonType> >>  "%DISTROFULL%\kWSL.xml"
ECHO      <RunLevel>HighestAvailable</RunLevel> >>  "%DISTROFULL%\kWSL.xml"
ECHO    </Principal> >>  "%DISTROFULL%\kWSL.xml"
ECHO  </Principals> >>  "%DISTROFULL%\kWSL.xml"
ECHO  <Settings> >>  "%DISTROFULL%\kWSL.xml"
ECHO    <MultipleInstancesPolicy>StopExisting</MultipleInstancesPolicy> >>  "%DISTROFULL%\kWSL.xml"
ECHO    <DisallowStartIfOnBatteries>false</DisallowStartIfOnBatteries> >>  "%DISTROFULL%\kWSL.xml"
ECHO    <StopIfGoingOnBatteries>false</StopIfGoingOnBatteries> >>  "%DISTROFULL%\kWSL.xml"
ECHO    <AllowHardTerminate>true</AllowHardTerminate> >>  "%DISTROFULL%\kWSL.xml"
ECHO    <StartWhenAvailable>false</StartWhenAvailable> >>  "%DISTROFULL%\kWSL.xml"
ECHO    <RunOnlyIfNetworkAvailable>false</RunOnlyIfNetworkAvailable> >>  "%DISTROFULL%\kWSL.xml"
ECHO    <IdleSettings> >>  "%DISTROFULL%\kWSL.xml"
ECHO      <StopOnIdleEnd>true</StopOnIdleEnd> >>  "%DISTROFULL%\kWSL.xml"
ECHO      <RestartOnIdle>false</RestartOnIdle> >>  "%DISTROFULL%\kWSL.xml"
ECHO    </IdleSettings> >>  "%DISTROFULL%\kWSL.xml"
ECHO    <AllowStartOnDemand>true</AllowStartOnDemand> >>  "%DISTROFULL%\kWSL.xml"
ECHO    <Enabled>true</Enabled> >>  "%DISTROFULL%\kWSL.xml"
ECHO    <Hidden>true</Hidden> >>  "%DISTROFULL%\kWSL.xml"
ECHO    <RunOnlyIfIdle>false</RunOnlyIfIdle> >>  "%DISTROFULL%\kWSL.xml"
ECHO    <DisallowStartOnRemoteAppSession>false</DisallowStartOnRemoteAppSession> >>  "%DISTROFULL%\kWSL.xml"
ECHO    <UseUnifiedSchedulingEngine>true</UseUnifiedSchedulingEngine> >>  "%DISTROFULL%\kWSL.xml"
ECHO    <WakeToRun>false</WakeToRun> >>  "%DISTROFULL%\kWSL.xml"
ECHO    <ExecutionTimeLimit>PT0S</ExecutionTimeLimit> >>  "%DISTROFULL%\kWSL.xml"
ECHO    <Priority>7</Priority> >>  "%DISTROFULL%\kWSL.xml"
ECHO  </Settings> >>  "%DISTROFULL%\kWSL.xml"
ECHO  <Actions Context="Author"> >>  "%DISTROFULL%\kWSL.xml"
ECHO    <Exec> >>  "%DISTROFULL%\kWSL.xml"
ECHO      <Command>QQQQ\Init.cmd</Command> >>  "%DISTROFULL%\kWSL.xml"
ECHO    </Exec> >>  "%DISTROFULL%\kWSL.xml"
ECHO  </Actions> >>  "%DISTROFULL%\kWSL.xml"
ECHO </Task> >>  "%DISTROFULL%\kWSL.xml"

ECHO [%TIME:~0,8%] Building Scheduled Task...
POWERSHELL -C "$WAI = (whoami) ; (Get-Content .\rootfs\tmp\kWSL\kWSL.xml).replace('AAAA', $WAI) | Set-Content .\rootfs\tmp\kWSL\kWSL.xml"
POWERSHELL -C "$WAC = (pwd)    ; (Get-Content .\rootfs\tmp\kWSL\kWSL.xml).replace('QQQQ', $WAC) | Set-Content .\rootfs\tmp\kWSL\kWSL.xml"
SCHTASKS /Create /TN:%DISTRO% /XML .\rootfs\tmp\kWSL\kWSL.xml /F
ECHO:
ECHO:      Start: %RUNSTART%
ECHO:        End: %RUNEND%
%GO%  "echo -ne '   Packages:'\   ; dpkg-query -l | grep "^ii" | wc -l "
ECHO: 
ECHO:  - xRDP Server listening on port %RDPPRT% and SSHd on port %SSHPRT%.
ECHO: 
ECHO:  - Links for GUI and Console sessions have been placed on your desktop.
ECHO: 
ECHO:  - (Re)launch init from the Task Scheduler or by running the following command: 
ECHO:    schtasks /run /tn %DISTRO%
ECHO: 
ECHO: [%TIME:~0,8%] %DISTRO% Installation Complete! GUI will start in a few seconds...  
PING -n 6 LOCALHOST > NUL 
START "Remote Desktop Connection" "MSTSC.EXE" "/V" "%DISTROFULL%\%DISTRO% (%XU%) Desktop.rdp"
CD ..
:ENDSCRIPT
