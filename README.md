# I GAVE UP 

### DO NOT USE THIS

I gave up. Fix one issue, 3 new ones appear and I do not have the patience nor the knowledge to fix all of them. <br>
Even if I would fix them, this script would evidently just _barely_ work. Too much incompatibility. To much broken stuff.<br>
For the sake of my sanity, I shall just accept that there is no way to run KDE Neon in WSL, even though it saddens me deeply. <br>
But fret not! I am currently working on a guide to install Kubuntu in KDE which appears to be way easier.<br><br>
You can check it out here: <br>
https://gist.github.com/NullDev/b727960ec955dd427896f7b607897b37 <br><br>
This repository shall remain as a memorial of the agony and suffering I went through. <br>
It shall also serve as a warning to anyone who may dare to try running KDE Neon on WSL. <br>
If this isn't enough to stop your brave soul, I just want to remind you that this repository is a fork of a fork. <br>
People failed before me, and people will fail after me.

---

# [kWSL.cmd - KDE Neon for WSL](https://github.com/NullDev/NeonWSL)

- Net-install of KDE Neon on WSL2 using xRDP.
- Runs on Windows 10 AMD64 and Server 2019/2022 (including Hyper-V Core)
- xRDP Display Server; no additional Xserver download/configuration required
- High-quality RDP audio playback; video playback and YouTube work well and maintains audio sync.
- If you want to access kWSL remotely, Chrome Remote Desktop is pre-installed (Never expose RDP servers to the Internet.) Configuration steps are [**here**](https://github.com/DesktopECHO/kWSL/wiki/Enable-Chrome-Remote-Desktop).

![image](https://user-images.githubusercontent.com/33142753/100149597-d3d57d80-2e74-11eb-899a-a7476b016e27.png)

**IMPORTANT!**

- Windows 11 requires 22H2 Update *(Sun Valley 2, September 2022)*
- Windows Server / Windows 10 require latest updates from Windows Update.

## INSTALL INSTRUCTIONS

From an elevated CMD.EXE prompt change to your desired install directory and type/paste the following command:

```batch
PowerShell -executionpolicy bypass -command "wget https://github.com/NullDev/NeonWSL/raw/master/kWSL.cmd -UseBasicParsing -OutFile kWSL.cmd ; .\kWSL.cmd"
```

It will ask you a number of questions. At this time you should go with the default. bionic and jammy have not been verified, but all the steps are implemented.

```text
[kWSL Installer: Modified December 14th, 2022]
Script started at TIME DATE

Enter a unique name for your kWSL distro or hit Enter to use default.
Port number for xRDP traffic or hit Enter to use default [3399]: 13399
Port number for SSHd traffic or hit Enter to use default [3322]: 13322
Set a custom DPI scale, or hit Enter for Windows default [1.5]: 1.25
[Not recommended!] Type X to eXclude from Windows Defender: X
Please specify if you want this instance to run as WSL1 or WSL2 [1]: 1
Which LTE version of Ubuntu do you want to use? Options are bionic (18.04), focal (20.04), or jammy (22.04) [focal]: focal
Please provide a path to install this. By default it installs in the user folder. [%USERPROFILE%]: 
Set a name for this KDE Neon instance.  Hit Enter to use default. 
Keep this name simple, no space or underscore characters [NeonWSL-focal]:
This will take a few minutes, please wait...
```

Near the end of the script you will be prompted to create a non-root user.  This user will be automatically added to sudo'ers.

```text
Open Windows Firewall Ports for xRDP, SSH, mDNS...
Building RDP Connection file, Console link, Init system...
Building Scheduled Task...
SUCCESS: The scheduled task "Neon" has successfully been created.

      Start: Thu 07/01/2021 @  2:46
        End: Thu 07/01/2021 @  2:58
   Packages: 1360

  - xRDP Server listening on port 13399 and SSHd on port 13322.

  - Links for GUI and Console sessions have been placed on your desktop.

  - (Re)launch init from the Task Scheduler or by running the following command:
    schtasks /run /tn Neon

 Neon Installation Complete!  GUI will start in a few seconds...
```

**When the script completes, Remote Desktop will be launched and it will automatically open your KDE Neon xRDP session!**

## Add configuration to Windows Terminal

- Open up the following file:
  - ````%localappdata%\Packages\Microsoft.WindowsTerminal_8wekyb3d8bbwe\LocalState\settings.json````
- Add the following JSON code to add three new profiles:
  - Here, we're adding a profile for root, the placeholder "whoopsie" user, and the init profile.  
    - The init profile is the same as the Windows Service created and can be ended by entering ```0``` and it will terminate that tab/window without needing to start/stop the service.  

```json
            {
                "guid": "{5f586e18-4020-5ce0-8544-13d847006eba}",
                "hidden": false,
                "name": "NeonWSL (root)",
                "source": "Windows.Terminal.Wsl"
            },
            {
                "colorScheme": "Campbell",
                "commandline": "C:\\WINDOWS\\system32\\WSL.exe ~ -u whoopsie -d NeonWSL",
                "guid": "{4228dd61-1063-4eb6-8366-424744fd0cd4}",
                "hidden": false,
                "icon": "ms-appx:///ProfileIcons/{9acb9455-ca41-5af7-950f-6bca1bc9722f}.png",
                "name": "NeonWSL",
                "startingDirectory": "~"
            },
            {
                "colorScheme": "Campbell",
                "commandline": "C:\\WINDOWS\\system32\\WSL.EXE ~ -u root -d NeonWSL -e initwsl 2",
                "guid": "{e70d6a43-997e-424c-abf0-5705c60a3b71}",
                "hidden": false,
                "icon": "ms-appx:///ProfileIcons/{9acb9455-ca41-5af7-950f-6bca1bc9722f}.png",
                "name": "NeonWSL Init",
                "startingDirectory": "~"
            }
```

## Configure kWSL to start at boot (like a service, no console window)

- Right-click the task in Task Scheduler, click properties
- Click the checkbox for **Run whether user is logged on or not** and click **OK**
- Enter your Windows credentials when prompted

 Reboot your PC when complete and kWSL will startup automatically.

## Convert WSL Instance

Example of conversion to WSL2:

- Stop WSL instance (Using default instance name *NeonWSL* in this example):
 ````wslconfig /t NeonWSL````
- Convert the instance to WSL2:
 ````wsl --set-version NeonWSL 2````
- Restart KDE Neon Instance:
 ````schtasks /run /tn NeonWSL````

Restart the instance when the conversion is complete: `schtasks.exe /run /tn NeonWSL`

Procedure is the same for switching back to WSL1: ````wsl --set-version NeonWSL 1````

## Make it your own

From a security standpoint, it would be best to fork this project so you (and only you) control the packages and files in the repository.

- Sign into GitHub and fork this project
- Edit ```kWSL.cmd```.  On line 2 you will see ```SET GITORG=NullDev``` - Change ```NullDev``` to the name of your own repository.
- Customize the script any way you like.
- Launch the script using your repository name:
 ```PowerShell -executionpolicy bypass -command "wget https://github.com/YOUR-REPO-NAME/NeonWSL/raw/master/kWSL.cmd -UseBasicParsing -OutFile kWSL.cmd ; .\kWSL.cmd"```

## Quirks / Limitations / Additional Info

- When you log out out of a KDE session the WSL instance is restarted.  This is the equivalent to having a freshly-booted desktop environment at every login, but the 'reboot' process only takes about 5 seconds.  
- kWSL should work fine with an X Server instead of xRDP but this has not been thoroughly tested.  The file ```/etc/profile.d/kWSL.sh``` contains WSL-centric environment variables that may need adjustment such as LIBGL_ALWAYS_INDIRECT.
- Plasma-discover doesn't work in Server 2019 / Win 10 v.1809 -- The installer will remove it if you're running an affected OS.
- WSL1 Doesn't work with PolicyKit.  Enabled kdesu for apps needing elevated rights (plasma-discover, ksystemlog, muon, root console.)
- KDE Lockscreen is disabled (due to policykit)  
- Patched KDE Activity Manager to disable WAL in sqlite3.
- Mozilla Seamonkey is included as a stable/maintained browser.
- QtWebEngine (Chromium-based) browsers like Falkon and Konqueror now work. (July/21)
- Installed image consumes approximately 3 GB of disk space.
- Apt-fast added to improve download speed and reliability.
- Default installation uses the Breeze theme and Windows fonts (Segoe UI / Cascadia Code)
- Compositor replaced with Picom for better RDP performance and includes the [Klassy](https://www.reddit.com/r/kde/comments/wju5g9/klassy_v40_window_decoration_application_style/) window decoration / application style plugin
- This is a base installation of KDE to save bandwidth.  If you want the full KDE Desktop environment **(OVER 3GB ADDITIONAL SPACE NEEDED!)** run ```sudo pkcon -y install neon-all```

![image](https://user-images.githubusercontent.com/33142753/100148485-33cb2480-2e73-11eb-932b-54e34b445575.png)

![image](https://user-images.githubusercontent.com/33142753/100385367-c21ce300-2ff8-11eb-9276-6f51b366839f.png)
