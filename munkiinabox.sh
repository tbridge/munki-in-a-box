#!/bin/bash

# Munki In A Box
# By Tom Bridge

# Version: 0.1.3

# This software carries no guarantees, warranties or other assurances that it works. It may wreck your entire environment. That would be bad, mmkay. Backup, test in a VM, and bug report. 
# Approach this script like a swarm of bees: Unless you know what you are doing, keep your distance.

# The goal of this script is to deploy a basic munki repo in a simple script based on a set of common variables. I have placed defaults in these variables, but they are easily overridden and you should decide where they go.

# This script is based upon the Demonstration Setup Guide for Munki, AutoPKG, and other sources. My sincerest thanks to Greg Neagle, Tim Sutton, Allister Banks, Rich Trouton, Charles Edge and numerous others who have helped me assemble this script.

# Pre-Reqs for this script: 10.8/Server 2 or 10.9/Server 3, Munki Tools installed. 

# Establish our Basic Variables:

REPOLOC="/Users/Shared/"
REPODIR="/Users/Shared/munki_repo"
LOGGER="/usr/bin/logger"
MUNKILOC="/usr/local/munki"
osvers=$(sw_vers -productVersion | awk -F. '{print $2}') # Thanks Rich Trouton
webrunning=$(serveradmin status web | awk '{print $3}') # Thanks Charles Edge

echo $webrunning

####

# Checks 

####

if 
	[[ $osvers -ge 8 ]]; then sudo ln -s /Users/Shared/munki_repo /Library/Server/Web/Data/Sites/Default
	else
		${LOGGER} "Could not run because the version of the OS does not meet requirements"
		echo "Sorry, this is for Mac OS 10.8 or later."
	 	exit 0 # 10.8+ for the Web Root Location.
	
fi

if
	[[ $webrunning == *STOPPED* ]]; then 
	${LOGGER} "Could not run because the Web Service is stopped"
	echo "Please turn on Web Services in Server.app"
	exit 0 # Sorry, turn on the webserver.	
fi

if

	[[ ! -f $MUNKILOC/munkiimport ]]; then
	${LOGGER} "Could not run because Munki Tools are not installed"
	echo "Sorry, Munki Tools are not installed."
	exit 0 # If munki import doesn't exist, this won't work. 
fi	

# Create the repo.

cd $REPOLOC
mkdir munki_repo
mkdir munki_repo/catalogs
mkdir munki_repo/manifests
mkdir munki_repo/pkgs
mkdir munki_repo/pkgsinfo

chmod -R a+rX munki_repo


${LOGGER} "Repo Created"
	
####

# Get AutoPKG

####

curl -L https://github.com/autopkg/autopkg/releases/download/v0.2.9/autopkg-0.2.9.pkg -o autopkg.pkg

installer -pkg autopkg.pkg -target /

${LOGGER} "AutoPKG Installed"

####

# Configure AutoPKG for use with Munki

####

defaults write com.github.autopkg MUNKI_REPO $REPODIR

autopkg repo-add http://github.com/autopkg/recipes.git

defaults write com.googlecode.munki.munkiimport editor TextWrangler.app
defaults write com.googlecode.munki.munkiimport repo_path $REPODIR
defaults write com.googlecode.munki.munkiimport pkginfo_extension .plist

${LOGGER} "AutoPKG Configured"

####

# Get some Packages and Stuff them in Munki

####

autopkg run -v AdobeFlashPlayer.munki AdobeReader.munki Dropbox.munki Firefox.munki GoogleChrome.munki OracleJava7.munki TextWrangler.munki munkitools.munki MakeCatalogs.munki

${LOGGER} "AutoPKG Run"

####

# Clean Up When Done

####

rm $REPOLOC/autopkg.pkg

${LOGGER} "I put my toys away!"


exit
