munki-in-a-box
==============

Post Munki Install Simple Deployment Script


The goal of this script is to deploy a basic munki repo in a simple script based on a set of common variables. I have placed defaults in these variables, but they are easily overridden and you should decide where they go.

This script is based upon the Demonstration Setup Guide for Munki, AutoPKG, and other sources. My sincerest thanks to Greg Neagle, Tim Sutton, Allister Banks, Rich Trouton, Charles Edge and numerous others who have helped me assemble this script.

Pre-Requisites:

1) 10.8/Server 2 or 10.9/Server 3
2) Web Services Enabled

Directions for Use:

1) Download Script
2) Alter Lines 19-20 to reflect your choice for munki repo name and location
3) Alter Line 82 to reflect your choice of AutoPKG installs
4) sudo ./munkiinabox.sh

Questions? Comments? Suggestions? Jeers? Please email me at tom@technolutionary.com