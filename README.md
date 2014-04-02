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
2) Alter Lines 19-20 to reflect your choice for munki repo name and location  
3) Alter Line 106 to reflect your choice of AutoPKG installs  
4) sudo ./munkiinabox.sh

NEW in 0.2:

• AutoPKG is now downloaded from the latest trunk.  
• The site_default Manifest is established from the packages passed to autopkg.  
• If Munki is not installed, the script grabs the munki tools, mounts the dmg and installs munki_core and munki_admin packages from inside. 
• Munki Report is now installed. It still needs to have an admin account created, but it's added and configured. If your site does not load correctly, be sure PHP is active in Server.app

Immediate Future Plans:

√ 1) Replace hard-coded AutoPKG download with current release version retrieval links  
2) Allow check of plain apachectl for purposes of using on a non-Server.app platform.  
3) Install Sean Kaiser's Monitoring Scripts with configuration variables passed through

Other Good Suggestions:

√ 1) Creation of site_default Manifest  
√ 2) Generation of Client Configuration pkg or script - Thanks Nick McSpadden!  
√ 3) Install of Munki-Report PHP  - Thanks nbalonso, A.E. von Bochoven and Marnin Goldberg
√ 4) Replace Munkitools requirement with install of appropriate munki elements.


Questions? Comments? Suggestions? Jeers? Please email me at tom@technolutionary.com