#!/bin/bash

# Munki In A Box
# By Tom Bridge, Technolutionary LLC

# Version: Special Branch 1.0

# This software carries no guarantees, warranties or other assurances that it works. It may wreck your entire environment. That would be bad, mmkay. Backup, test in a VM, and bug report.

# Approach this script like a swarm of bees: Unless you know what you are doing, keep your distance.

# The goal of this script is to deploy a basic munki repo in a simple script based on a set of common variables. There are default values in these variables, but they are easily overridden and you should decide what they should be.

# This script is based upon the Demonstration Setup Guide for Munki, AutoPkg, and other sources. My sincerest thanks to Greg Neagle, Tim Sutton, Allister Banks, Rich Trouton, Charles Edge, Hannes Juutilainen, Sean Kaiser, Peter Bukowinski, Elliot Jordan, The Linde Group and numerous others who have helped me assemble this script.

# Pre-Reqs for this script: 10.10/Server 4 or 10.11/Server 5.  Web Services should be turned on and PHP should be enabled. 

# Establish our Basic Variables:

REPOLOC="/Users/Shared"
REPONAME="munki_repo"
REPODIR="${REPOLOC}/${REPONAME}"
LOGGER="/usr/bin/logger -t Munki-in-a-Box"
MUNKILOC="/usr/local/munki"
WEBROOT="/Library/Server/Web/Data/Sites/Default"
PHPROOT="/Library/Server/Web/Config/php"
GIT="/usr/bin/git"
MANU="/usr/local/munki/manifestutil"
TEXTEDITOR="TextWrangler.app"
osvers=$(sw_vers -productVersion | awk -F. '{print $2}') # Thanks Rich Trouton
webstatus=$(serveradmin status web | awk '{print $3}') # Thanks Charles Edge
AUTOPKGRUN="Firefox.munki GoogleChrome.munki MakeCatalogs.munki"
DEFAULTS="/usr/bin/defaults"
AUTOPKG="/usr/local/bin/autopkg"
MAINPREFSDIR="/Library/Preferences"
ADMINUSERNAME="ladmin"
SCRIPTDIR="/usr/local/bin"

echo "Welcome to Munki-in-a-Box. We're going to get things rolling here with a couple of tests"'!'

echo "First up: Are you an admin user? Enter your password below:"

#Let's see if this works...
#This isn't bulletproof, but this is a basic test.
sudo whoami > /tmp/quickytest

if
	[[  `cat /tmp/quickytest` == "root" ]]; then
	${LOGGER} "Privilege Escalation Allowed, Please Continue."
	else
	${LOGGER} "Privilege Escalation Denied, User Cannot Sudo."
	exit 6 "You are not an admin user, you need to do this an admin user."
fi

${LOGGER} "Starting up..."

echo "$webstatus"

${LOGGER} "Webstatus echoed."

####

# Checks

####

${LOGGER} "Starting checks..."

# Make sure the whole script stops if Control-C is pressed.
fn_terminate() {
    fn_log_error "Munki-in-a-Box has been terminated."
    exit 1
}
trap 'fn_terminate' SIGINT

if
    [[ $osvers -lt 10 ]]; then
    ${LOGGER} "Could not run because the version of the OS does not meet requirements"
    echo "Sorry, this is for Mac OS 10.10 or later."
    exit 2 # 10.8+ for the Web Root Location.
fi

${LOGGER} "Mac OS X 10.10 or later is installed."

if
    [[ $webstatus == *STOPPED* ]]; then
    ${LOGGER} "Could not run because the Web Service is stopped"
    echo "Please turn on Web Services in Server.app"
    exit 3 # Sorry, turn on the webserver.
fi

${LOGGER} "Web service is running."

if
    [[ $EUID -eq 0 ]]; then
   $echo "This script is NOT MEANT to run as root. This script is meant to be run as an admin user. I'm going to quit now. Run me without the sudo, please."
    exit 4 # Running as root.
fi

#${LOGGER} "Script is running as root."

if
    [[ ! -d "${WEBROOT}" ]]; then
    echo "No web root exists at ${WEBROOT}. This might be because you don't have Server.app installed and configured."
    exit 5 # Web Root folder doesn't exist.
fi

# If we pass this point, the Repo gets linked:

    ln -s "${REPODIR}" "${WEBROOT}"

    ${LOGGER} "The repo is now linked. ${REPODIR} now appears at ${WEBROOT}"

if
    [[ ! -f $MUNKILOC/munkiimport ]]; then
    cd ${REPOLOC}
    ${LOGGER} "Grabbing and Installing the Munki Tools Because They Aren't Present"
    MUNKI_LATEST=$(curl https://api.github.com/repos/munki/munki/releases/latest | python -c 'import json,sys;obj=json.load(sys.stdin);print obj["assets"][0]["browser_download_url"]')
    
    curl -L "${MUNKI_LATEST}" -o munki-latest1.pkg
    
# Write a Choices XML file for the Munki package. Thanks Rich and Greg!

     /bin/cat > "/tmp/com.github.munki-in-a-box.munkiinstall.xml" << 'MUNKICHOICESDONE'
     <!DOCTYPE plist PUBLIC "-//Apple//DTD PLIST 1.0//EN" "http://www.apple.com/DTDs/PropertyList-1.0.dtd">
<plist version="1.0">
    <array>
        <dict>
                <key>attributeSetting</key>
                <integer>1</integer>
                <key>choiceAttribute</key>
                <string>selected</string>
                <key>choiceIdentifier</key>
                <string>core</string>
        </dict>
        <dict>
                <key>attributeSetting</key>
                <integer>1</integer>
                <key>choiceAttribute</key>
                <string>selected</string>
                <key>choiceIdentifier</key>
                <string>admin</string>
        </dict>
        <dict>
                <key>attributeSetting</key>
                <integer>0</integer>
                <key>choiceAttribute</key>
                <string>selected</string>
                <key>choiceIdentifier</key>
                <string>app</string>
        </dict>
        <dict>
                <key>attributeSetting</key>
                <integer>0</integer>
                <key>choiceAttribute</key>
                <string>selected</string>
                <key>choiceIdentifier</key>
                <string>launchd</string>
        </dict>
</array>
</plist>
MUNKICHOICESDONE

    sudo /usr/sbin/installer -dumplog -verbose -applyChoiceChangesXML "/tmp/com.github.munki-in-a-box.munkiinstall.xml" -pkg "munki-latest1.pkg" -target "/"

    ${LOGGER} "Installed Munki Admin and Munki Core packages"
    echo "Installed Munki packages"

    else
        ${LOGGER} "Munki was already installed, I think, so I'm moving on"
        echo "/usr/local/munki/munkiimport existed, so I am not reinstalling. Hope you really had Munki installed..."

fi

# Check for 10.9 and 10.8 created here by Tim Sutton, for which I owe him a beer. Or six.

if
    [[ ! -d /Applications/Xcode.app ]]; then
    echo "You need to install the Xcode command line tools. Let me get that for you, it'll just take a minute."

###
# This section written by Rich Trouton and embedded because he's awesome. Diet Coke++, Rich.
###

# Installing the Xcode command line tools on 10.10.x and later
 
osx_vers=$(sw_vers -productVersion | awk -F "." '{print $2}')
cmd_line_tools_temp_file="/tmp/.com.apple.dt.CommandLineTools.installondemand.in-progress"
 
# Installing the latest Xcode command line tools on 10.9.x or 10.10.x
 
	if [[ "$osx_vers" -ge 10 ]] ; then
 
	# Create the placeholder file which is checked by the softwareupdate tool 
	# before allowing the installation of the Xcode command line tools.
	
	touch "$cmd_line_tools_temp_file"
	
	# Find the last listed update in the Software Update feed with "Command Line Tools" in the name
	
	cmd_line_tools=$(softwareupdate -l | awk '/\*\ Command Line Tools/ { $1=$1;print }' | tail -1 | sed 's/^[[ \t]]*//;s/[[ \t]]*$//;s/*//' | cut -c 2-)
	
	#Install the command line tools
	
	sudo softwareupdate -i "$cmd_line_tools" -v
	
	# Remove the temp file
	
		if [[ -f "$cmd_line_tools_temp_file" ]]; then
	  rm "$cmd_line_tools_temp_file"
		fi
	fi
 
fi

###
# Thanks again, Rich!
###

echo "Great. All Tests are passed, so let's create the Munki Repo"'!'
${LOGGER} "All Tests Passed! On to the configuration."

# Create the repo.

cd "$REPOLOC"
mkdir "${REPONAME}"
mkdir "${REPONAME}/catalogs"
mkdir "${REPONAME}/manifests"
mkdir "${REPONAME}/pkgs"
mkdir "${REPONAME}/pkgsinfo"

chmod -R a+rX,g+w "${REPONAME}" ## Thanks Arek!
chown -R ${ADMINUSERNAME}:admin "${REPONAME}" ## Thanks Arek!

${LOGGER} "Repo Created"
echo "Repo Created"


####
# Create a client installer pkg pointing to this repo. Thanks Nick!
####

if
    [[ ! -f /usr/bin/pkgbuild ]]; then
    ${LOGGER} "Pkgbuild is not installed."
    echo "Please install Xcode command line tools first."
    exit 0 # Gotta install the command line tools.
fi

mkdir -p /tmp/ClientInstaller/Library/Preferences/

HOSTNAME=$(/bin/hostname)
${DEFAULTS} write /tmp/ClientInstaller/Library/Preferences/ManagedInstalls.plist SoftwareRepoURL "http://$HOSTNAME/${REPONAME}"

/usr/bin/pkgbuild --identifier com.munkiinabox.client.pkg --root /tmp/ClientInstaller ClientInstaller.pkg

${LOGGER} "Client install pkg created."
echo "Client install pkg is created. It's in the base of the repo."

####
# Get AutoPkg
####

# Nod and Toast to Nate Felton!

AUTOPKG_LATEST=$(curl https://api.github.com/repos/autopkg/autopkg/releases | python -c 'import json,sys;obj=json.load(sys.stdin);print obj[0]["assets"][0]["browser_download_url"]')
curl -L "${AUTOPKG_LATEST}" -o autopkg-latest1.pkg

sudo installer -pkg autopkg-latest1.pkg -target /

${LOGGER} "AutoPkg Installed"
echo "AutoPkg Installed"

####
# Configure AutoPkg for use with Munki
####


${DEFAULTS} write com.github.autopkg MUNKI_REPO "$REPODIR"

${AUTOPKG} repo-add http://github.com/autopkg/recipes.git

${DEFAULTS} write com.googlecode.munki.munkiimport editor "${TEXTEDITOR}"
${DEFAULTS} write com.googlecode.munki.munkiimport repo_path "${REPODIR}"
${DEFAULTS} write com.googlecode.munki.munkiimport pkginfo_extension .plist
${DEFAULTS} write com.googlecode.munki.munkiimport default_catalog testing

${LOGGER} "AutoPkg Configured"
echo "AutoPkg Configured"

# This makes AutoPkg useful on future runs for the admin user defined at the top. It copies & creates preferences for autopkg and munki into their home dir's Library folder, as well as transfers ownership for the ~/Library/AutoPkg folders to them.

plutil -convert xml1 ~/Library/Preferences/com.googlecode.munki.munkiimport.plist

####
# Get some Packages and Stuff them in Munki
####

${AUTOPKG} run -v ${AUTOPKGRUN}

${LOGGER} "AutoPkg Run"
echo "AutoPkg has run"

####
# Create new site_default manifest and add imported packages to it
####

${MANU} new-manifest site_default
echo "Site_Default created"
${MANU} add-catalog testing --manifest site_default
echo "Testing Catalog added to Site_Default"

listofpkgs=($(${MANU} list-catalog-items testing))
echo "List of Packages for adding to repo:" ${listofpkgs[*]}

# Thanks Rich! Code for Array Processing borrowed from First Boot Packager
# Original at https://github.com/rtrouton/rtrouton_scripts/tree/master/rtrouton_scripts/first_boot_package_install/scripts

tLen=${#listofpkgs[@]}
echo "$tLen" " packages to install"

for (( i=0; i<tLen; i++));
do
    ${LOGGER} "Adding ${listofpkgs[$i]} to site_default"
    ${MANU} add-pkg ${listofpkgs[$i]} --manifest site_default
    ${LOGGER} "Added ${listofpkgs[$i]} to site_default"
done

####
# Install AutoPkgr from the awesome Linde Group!
####

${AUTOPKG} run AutoPkgr.install

${LOGGER} "AutoPkgr Installed"
echo "AutoPkgr Installed"

mkdir ~/Library/Application\ Support/AutoPkgr
touch ~/Library/Application\ Support/AutoPkgr/recipe_list.txt

echo "com.github.autopkg.munki.firefox-rc-en_US
com.github.autopkg.munki.google-chrome
com.github.autopkg.munki.makecatalogs" > ~/Library/Application\ Support/AutoPkgr/recipe_list.txt

####
# Install Munki Admin App by the amazing Hannes Juutilainen
####

${AUTOPKG} repo-add jleggat-recipes

${AUTOPKG} run MunkiAdmin.install

####
# Clean Up When Done
####

# Give the owner rights to the repo again, just in case we missed something along the way...
chmod -R a+rX,g+w "${REPONAME}"
chown -R ${ADMINUSERNAME}:admin "${REPONAME}"

rm "$REPOLOC/autopkg-latest1.pkg"
rm "$REPOLOC/munki-latest1.pkg"
rm "$REPOLOC/munkireport-"*.pkg

${LOGGER} "I put my toys away."

echo "#########"
echo "Thank you for flying Munki in a Box Air. You now have a working repo, go forth and install your clients."
echo "#########"
echo "MunkiAdmin and AutoPkgr are ready to go, please launch them to complete their setup."
echo "#########"
echo "MunkiAdmin needs to know where your repo is, and AutoPkgr needs to have its helper tool installed."
echo "#########"

exit 0