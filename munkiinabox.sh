#!/bin/bash

# Munki In A Box
# By Tom Bridge

# Version: 0.2

# This software carries no guarantees, warranties or other assurances that it works. It may wreck your entire environment. That would be bad, mmkay. Backup, test in a VM, and bug report. 
# Approach this script like a swarm of bees: Unless you know what you are doing, keep your distance.

# The goal of this script is to deploy a basic munki repo in a simple script based on a set of common variables. I have placed defaults in these variables, but they are easily overridden and you should decide where they go.

# This script is based upon the Demonstration Setup Guide for Munki, AutoPKG, and other sources. My sincerest thanks to Greg Neagle, Tim Sutton, Allister Banks, Rich Trouton, Charles Edge and numerous others who have helped me assemble this script.

# Pre-Reqs for this script: 10.8/Server 2 or 10.9/Server 3.  Web Services should be turned on.

# Establish our Basic Variables:

REPOLOC="/Users/Shared/"
REPODIR="/Users/Shared/munki_repo"
LOGGER="/usr/bin/logger"
MUNKILOC="/usr/local/munki"
WEBROOT="/Library/Server/Web/Data/Sites/Default"
osvers=$(sw_vers -productVersion | awk -F. '{print $2}') # Thanks Rich Trouton
webstatus=$(serveradmin status web | awk '{print $3}') # Thanks Charles Edge
AUTOPKGRUN="autopkg run -v AdobeFlashPlayer.munki AdobeReader.munki Dropbox.munki Firefox.munki GoogleChrome.munki OracleJava7.munki TextWrangler.munki munkitools.munki MakeCatalogs.munki"

echo $webstatus

####

# Checks 

####

if 
	[[ $osvers -ge 8 ]]; then sudo ln -s ${REPODIR} ${WEBROOT}
	else
		${LOGGER} "Could not run because the version of the OS does not meet requirements"
		echo "Sorry, this is for Mac OS 10.8 or later."
	 	exit 0 # 10.8+ for the Web Root Location.
	
fi

if
	[[ $webstatus == *STOPPED* ]]; then 
	${LOGGER} "Could not run because the Web Service is stopped"
	echo "Please turn on Web Services in Server.app"
	exit 0 # Sorry, turn on the webserver.	
fi

if

	[[ ! -f $MUNKILOC/munkiimport ]]; then
	${LOGGER} "Installing Munki Tools Because They Aren't Present"
	curl -L https://munki.googlecode.com/files/munkitools-1.0.0.1864.0.dmg -o munkitools.dmg
	hdiutil attach munkitools.dmg 
	cd /Volumes/munkitools-1.0.0.1864.0/munkitools-1.0.0.1864.0.mpkg/Contents/Packages/
	installer -pkg munkitools_admin-1.0.0.1864.0.pkg -target /
	installer -pkg munkitools_core-1.0.0.1864.0.pkg -target /
	hdituil detach /Volumes/munkitools-1.0.0.1864.0/
	
	${LOGGER} "Installed Munki Admin and Munki Core packages"
	 
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

# Get Munki Parts

####


	
####

# Get AutoPKG

####

# Hat Tip to Allister Banks!

VERS=`curl https://github.com/autopkg/autopkg/releases/latest | cut -c 85-89` ; curl -L https://github.com/autopkg/autopkg/releases/download/v$VERS/autopkg-$VERS.pkg -o autopkg-latest1.pkg

installer -pkg autopkg-latest1.pkg -target /

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

${AUTOPKGRUN}

${LOGGER} "AutoPKG Run"

####

# Create new site_default manifest and add imported packages to it

####

manifestutil new-manifest site_default

manifestutil add-catalog testing --manifest site_default

listofpkgs=(`manifestutil list-catalog-items testing`)

# Thanks Rich! Code for Array Processing borrowed from First Boot Packager
# Original at https://github.com/rtrouton/rtrouton_scripts/tree/master/rtrouton_scripts/first_boot_package_install/scripts

tLen=${#listofpkgs[@]} 

for (( i=0; i<${tLen}; i++));
do 
	${LOGGER} "Adding "${listofpkgs[$i]}" to site_default"
	manifestutil add-pkg ${listofpkgs[$i]} --manifest site_default
	${LOGGER} "Added "${listofpkgs[$i]}" to site_default"
done

####

# Install AutoPKG Automation [[ COMING SOON ]]

####

# curl -L https://github.com/seankaiser/automation-scripts/blob/master/autopkg/autopkg-wrapper.sh -o /usr/local/bin/autopkg-wrapper.sh



####

#  Install MunkiReport-PHP [[ COMING SOON ]]

####

# cd ${WEBROOT}
# git clone https://github.com/munkireport/munkireport-php.git
# cd munkireport-php


####

# Clean Up When Done

####

rm $REPOLOC/autopkg-latest1.pkg
rm $REPOLOC/munkitools.dmg

${LOGGER} "I put my toys away!"


exit
