munki-in-a-box
==============

Post Munki Install Simple Deployment Script


The goal of this script is to deploy a basic munki repo in a simple script based on a set of common variables. I have placed defaults in these variables, but they are easily overridden and you should decide where they go.

This script is based upon the Demonstration Setup Guide for Munki, AutoPKG, and other sources. My sincerest thanks to Greg Neagle, Tim Sutton, Allister Banks, Rich Trouton, Charles Edge, Pepijn Bruienne and numerous others who have helped me assemble this script.

Pre-Requisites:

1) 10.8/Server 2 or 10.9/Server 3  
2) Web Services Enabled
3) Munki Tools installed

Directions for Use:

1) Download Script  
2) Alter Lines 19-20 to reflect your choice for munki repo name and location  
3) Alter Line 106 to reflect your choice of AutoPKG installs  
4) sudo ./munkiinabox.sh

Future Features:

1) Replace hard-coded AutoPKG download with current release version retrieval links  
2) Allow check of plain apachectl for purposes of using on a non-Server.app platform.  
3) Install Sean Kaiser's Monitoring Scripts with configuration variables passed through

Questions? Comments? Suggestions? Jeers? Please email me at tom@technolutionary.com