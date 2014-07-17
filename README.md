munki-in-a-box
==============

Post Munki Install Simple Deployment Script


The goal of this script is to deploy a basic munki repo in a simple script based on a set of common variables. I have placed defaults in these variables, but they are easily overridden and you should decide where they go.

This script is based upon the Demonstration Setup Guide for Munki, AutoPKG, and other sources. My sincerest thanks to Greg Neagle, Tim Sutton, Allister Banks, Rich Trouton, Charles Edge, Pepijn Bruienne and numerous others who have helped me assemble this script.

Pre-Requisites:

1) 10.8/Server 2 or 10.9/Server 3  
2) Web Services Enabled

Directions for Use:

1) Download Script  
2) Alter Lines 20-21 to reflect your choice for munki repo name and location  
3) Alter Line 32 to reflect your choice of AutoPKG installs
4) Alter Line 35 to reflect your admin username (ladmin is default)
5) Alter Lines 37-38 to reflect AutoPKG Automation Scripts
6) sudo ./munkiinabox.sh

NEW in 0.4:

• Inclusion of Munki-Enroll and Sean Kaiser's AutoPKG Automation Scripts

NEW in 0.3: 

• Inclusion of Hannes Juutilainen's MunkiAdmin tool via Download & Install
• Correctly working autopkg and munkiimport plist files


Included from in 0.2:

• AutoPKG is now downloaded from the latest trunk.  
• The site_default Manifest is established from the packages passed to autopkg.  
• If Munki is not installed, the script grabs the munki tools, mounts the dmg and installs munki_core and munki_admin packages from inside. 
• Munki Report is now installed. It still needs to have an admin account created, but it's added and configured. If your site does not load correctly, be sure PHP is active in Server.app


Questions? Comments? Suggestions? Jeers? Please email me at tom@technolutionary.com