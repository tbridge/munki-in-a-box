munki-in-a-box
==============

Post Munki Install Simple Deployment Script

The goal of this script is to deploy a basic munki repo in a simple script based on a set of common variables. I have placed defaults in these variables, but they are easily overridden and you should decide where they go.

This script is based upon the Demonstration Setup Guide for Munki, AutoPKG, and other sources. My sincerest thanks to Greg Neagle, Tim Sutton, Allister Banks, Rich Trouton, Charles Edge, Pepijn Bruienne, the Linde Group and numerous others who have helped me assemble this script. The Mac Admins Community is supportive and awesome.

###Pre-Requisites:

1) Mac OS X 10.10.5 or later

###Directions for Use:

1) Download Script  
2) Alter Lines 20-21 to reflect your choice for munki repo name and location  
3) Alter Line 31 to reflect your choice of AutoPKG installs  
4) Alter Line 35 to reflect your admin username (ladmin is default)  
5) Alter Lines 37-38 to reflect your desired hostname and the location of your copy of the Server.app Installation Package.
6) ./munkiinabox.sh  

*If you do not make changes to the script before running it, the script may not run as intended.* Please double-check to make sure that you are comfortable with the variables' values.

##Caveats: 

When you setup AutoPkgr, be sure to understand the security implications of giving that GUI app, and its associated launchdaemons, access to the keychain. You should really use a one-off account for those notifications, and not, say, the admin account to your Google Domain. Just sayin'.

### Included Tools & Projects:

##Munki

[Munki](https://github.com/munki/munki) is a client management solution for the Mac. I'm assuming you know a little bit about how Munki works by installing it via this script, but I would be remiss not to point you to [Munki's official documentation](https://github.com/munki/munki/wiki). It is mostly installed in /usr/local/munki

##MunkiAdmin

[MunkiAdmin](http://hjuutilainen.github.io/munkiadmin/) is Hannes Juutilainen's native GUI application for managing Munki repositories. It is super handy for those who prefer graphical interfaces to their inscrutable XML files.  It is installed in the /Application/Utilities directory.

##AutoPkg

[AutoPkg](http://autopkg.github.io/autopkg/) is an automated updates tool, used primarily from the command line, or through AutoPkgr, to keep a set of application installers up to date, and part of your Munki repository. AutoPkg is recipe-based, which means anyone can write their own recipe list and make it available. We are importing the main recipe repository, but if you want to add your own later, the AutoPkg docs will tell you how. Autopkg is installed in the /usr/local/bin directory.

##AutoPkgr

[AutoPkgr](http://www.lindegroup.com/autopkgr) is The Linde Group's native GUI application used for managing AutoPkg's command line functionality. Specifically, you can configure it to periodically check for new updates, import those into your Munki repository, then email you about what new versions have been imported for testing. It is installed in the /Application/Utilities directory.

##Munkireport-php

[Munkireport-php](https://github.com/munkireport/munkireport-php) is a lightweight reporting engine for your munki interface. It requires the installation of a nopkg item in Munki, which is already part of your site_default catalog. The webpage is viewable at http://YOURHOSTNAMEGOESHERE/munkireport-php/

The default user & pass are root:root. You can add a user by going to:

http://YOURHOSTNAMEGOESHERE/munkireport-php/index.php?/auth/generate

Then you must add that configuration line into the config.php file in $WEBROOT/munkireport-php/

For more information on munkireport-php, please be sure to [visit their documentation](https://github.com/munkireport/munkireport-php/blob/master/docs/setup.md).

##Munki-enroll

[Munki-enroll](https://github.com/edingc/munki-enroll) is a way to have your bootstrap munki clients end up with their very own manifest without you having to set it up yourself. This is not configured by default yet.


###Changelog

**NEW in 1.5.0 Beta 1:**

• This version is designed to install Server.app if you haven't already, as well as configure it _from the command line_ automagically. Please double check to make sure your DNS is good before running the script. Please report issues if you see them.  
• Please note that `server setup` will report an Unknown Error on completion. It still runs okay, so I'm not sure why we're getting that. I'll be filing a bug.

**NEW in 1.4.0:**

• No more running as root!

**NEW in 1.3.0:**

• Updated deployment technique for Munkireport-php, thanks to A.E. von Bochoven.  
• Additional permissions fixes thanks to Keith Mitnick  
• Syntactical changes

**NEW in 1.2.1:**

• Maintenance release, with suggested fixes from Arek Dreyer, Allister Banks and others. Thanks, everyone!

**NEW in 1.2.0:**

• Switch from direct download from Github of MunkiAdmin and AutoPkgr to install via AutoPkg.  
• Inclusion of Nate Felton's python code to download AutoPkg (Thanks Nate!)  
• Inclusion of -allowUntrusted for Mountain Lion Developer Tools, presaging the expiry of that particular certificate  
• Fix of permissions issue.

**NEW in 1.1.0:**

• Inclusion of Linde Group's AutoPkgr project, which is replacing Sean Kaiser's notification scripts. This isn't a statement of judgment on the quality of Sean's scripts -- which are amazing -- but rather a statement that you may want a GUI utility with more fiddly bits. I've left Sean's code in if you want a more simple environment, and you can choose to uncomment his code around lines 350 or so. Just uncomment that section.  
• Fixes to Documentation and Code Comments.  
 
**NEW in 1.0.2:**

• Updated Command Line Tools section with changes from Rich Trouton (Thanks Rich!)  
• Cleanup

**NEW in 1.0.1:**

• Integrated better tests and escapes (thanks Elliot Jordan)  
• Altered and fixed Developer Tools downloads (thanks Rich Trouton)

**NEW in 1.0.0:**

• Version: 1.0.0 - Munki 2 & Yosemite!  
• Works with Server 4 and OS X 10.10.  
• Updated checks with better logic and more comments in the code.

**NEW in 0.6.0:**

• Version: 0.6.0 - Munki 2 Edition!  
• Installs the latest and greatest Munki 2 tools instead of Munki 1. All future builds of Munki in a Box will reference the latest tools.

**NEW in 0.4.3:**

• Installs Munkireport-php plist to pkgsinfo and adds it to site_default manifest

**NEW in 0.4.2:**

• MunkiAdmin version is no longer hardcoded into the script. It will pull the latest release.

**NEW in 0.4.1:**

• Munki install code now based on Choices XML and is version independent.

**NEW in 0.4:**

• Inclusion of Munki-Enroll and Sean Kaiser's AutoPKG Automation Scripts  
• Be sure to change the new AutoPKG Automation settings.

**NEW in 0.3:** 

• Inclusion of Hannes Juutilainen's MunkiAdmin tool via Download & Install  
• Correctly working autopkg and munkiimport plist files


**Included from 0.2:**

• AutoPKG is now downloaded from the latest trunk.  
• The site_default Manifest is established from the packages passed to autopkg.  
• If Munki is not installed, the script grabs the munki tools, mounts the dmg and installs munki_core and munki_admin packages from inside.  
• Munki Report is now installed. It still needs to have an admin account created, but it's added and configured. If your site does not load correctly, be sure PHP is active in Server.app  


Questions? Comments? Suggestions? Jeers? Please email me at tom@technolutionary.com
