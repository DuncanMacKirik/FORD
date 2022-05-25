# FORD
## File Open ReDirector for DOS
  
My hobby project from around 1998-1999.  
At the time the grass was green, the trees were tall, and HDD and RAM sizes were quite small compared to what we have today.
Apparently this was not true for every place, because game-creating companies began to copy more and more files from game CD-ROMs to the hard disk during the installations, contrary to what they used to do previously. The data was duplicated, wasting precious space on the hard disk, and CD-ROM drive speeds were already much better than 1X, IIRC, so there was no reason to waste disk space on a relatively small disk. To fix this issue, this program was written.  
  
By writing a simple config file for a game or an application, you could delete all (or almost all) files copied from CD-ROM, and FORD redirected all file operations to original files located on the CD, rewriting file paths according to specified rules. Also it could intercept and redirect program execution requests, and act as either a TSR (resident program), or a simple app launcher.  
  
Recently I found its source code and successfully used it on a restored retro 486DX2-80 (a copy of my first PC) to cut down hard disk usage. So I can't say it's completely useless :-)  
  
Also, it can be used even today for running legacy apps with different file quirks, on virtual or real machines. MS-DOS and its clones is still being used in embedded devices and small PCs. So old school still rules :-)  
  
Also, when used with USB drives/Compact Flash/etc instead of a CD drive, FORD can provide a simple method of software protection: move the sensitive files from the app directory to a removable drive, write a suitable configuration (if the app is normally expecting to find these files in its directory), and the app won't work until you insert the drive. After completing all the work, exit the app, remove the drive, and it won't run without it.  
  
  
## Technical details
  
FORD is written in Pascal, and can be compiled with Turbo Pascal / Borland Pascal / Free Pascal (needs verifying) for MS-DOS target.
  
Two modes are supported:
 1) TSR
 2) app launcher
In TSR mode, FORD stays resident and you run your app manually for it to do its thing.
In app launcher mode (useful for being called from a batch file), FORD 
  
In both modes it installs its own handler of INT 21h, intercepting calls of functions 3Dh (open file) and 4Bh (execute program) and changing their effect according to specified rules.
  
  
## Limitations
  
Obviously, won't work with Windows 95 and higher and Win 3.x in protected mode (but maybe could work in real mode? not sure). Works OK with DOS extenders, though (they usually use usual real-mode OS calls for file operations).
Won't work with apps not using function 3Dh of INT 21h for opening files. For example, there is an alternative function for this (0F) which uses FCBs. I did not see a single program using it after mid-90s, so I didn't implement its support.
  
  
## Usage
  
  
## Configuration files description
  
