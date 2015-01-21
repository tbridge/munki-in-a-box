#!/bin/bash

# Munki In A Box
# By Tom Bridge, Technolutionary LLC

# Version: 1.0.1 - Munki 2 & 10.10 Edition

# This software carries no guarantees, warranties or other assurances that it works. It may wreck your entire environment. That would be bad, mmkay. Backup, test in a VM, and bug report.

# Approach this script like a swarm of bees: Unless you know what you are doing, keep your distance.

# The goal of this script is to deploy a basic munki repo in a simple script based on a set of common variables. There are default values in these variables, but they are easily overridden and you should decide where they go.

# This script is based upon the Demonstration Setup Guide for Munki, AutoPkg, and other sources. My sincerest thanks to Greg Neagle, Tim Sutton, Allister Banks, Rich Trouton, Charles Edge, Hannes Juutilainen, Sean Kaiser, Peter Bukowinski, Elliot Jordan and numerous others who have helped me assemble this script.

# Pre-Reqs for this script: 10.8/Server 2, 10.9/Server 3 or 10.10/Server 4.  Web Services should be turned on and PHP should be enabled.

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
AUTOPKGRUN="AdobeFlashPlayer.munki AdobeReader.munki Dropbox.munki Firefox.munki GoogleChrome.munki OracleJava7.munki TextWrangler.munki munkitools2.munki MakeCatalogs.munki"
DEFAULTS="/usr/bin/defaults"
MAINPREFSDIR="/Library/Preferences"
ADMINUSERNAME="ladmin"
SCRIPTDIR="/usr/local/bin"
AUTOPKGEMAIL="youraddress@domain.com"
AUTOPKGORGNAME="com.technolutionary"

echo "Welcome to Munki-in-a-Box. We're going to get things rolling here with a couple of tests"'!'

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
    [[ $osvers -lt 8 ]]; then
    ${LOGGER} "Could not run because the version of the OS does not meet requirements"
    echo "Sorry, this is for Mac OS 10.8 or later."
    exit 2 # 10.8+ for the Web Root Location.
fi

${LOGGER} "Mac OS X 10.8 or later is installed."

if
    [[ $webstatus == *STOPPED* ]]; then
    ${LOGGER} "Could not run because the Web Service is stopped"
    echo "Please turn on Web Services in Server.app"
    exit 3 # Sorry, turn on the webserver.
fi

${LOGGER} "Web service is running."

if
    [[ $EUID -ne 0 ]]; then
    $echo "This script must run as root. Type sudo $0, then press [ENTER]."
    exit 4 # Not running as root.
fi

${LOGGER} "Script is running as root."

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
    ${LOGGER} "Grabbing and Installing the Munki Tools Because They Aren't Present"
    curl -L "https://munkibuilds.org/munkitools2-latest.pkg" -o "$REPOLOC/munkitools2.pkg"

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

    /usr/sbin/installer -dumplog -verbose -applyChoiceChangesXML "/tmp/com.github.munki-in-a-box.munkiinstall.xml" -pkg "$REPOLOC/munkitools2.pkg" -target "/"

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

# Installing the Xcode command line tools on 10.7.x through 10.10.x
 
osx_vers=$(sw_vers -productVersion | awk -F "." '{print $2}')
cmd_line_tools_temp_file="/tmp/.com.apple.dt.CommandLineTools.installondemand.in-progress"
 
# Installing the latest Xcode command line tools on 10.9.x or 10.10.x
 
	if [[ "$osx_vers" -eq 9 ]] || [[ "$osx_vers" -eq 10 ]]; then
 
	# Create the placeholder file which is checked by the softwareupdate tool 
	# before allowing the installation of the Xcode command line tools.
	
	touch "$cmd_line_tools_temp_file"
	
	# Find the last listed update in the Software Update feed with "Command Line Tools" in the name
	
	cmd_line_tools=$(softwareupdate -l | awk '/\*\ Command Line Tools/ { $1=$1;print }' | tail -1 | sed 's/^[[ \t]]*//;s/[[ \t]]*$//;s/*//' | cut -c 2-)
	
	#Install the command line tools
	
	softwareupdate -i "$cmd_line_tools" -v
	
	# Remove the temp file
	
		if [[ -f "cmd_line_tools_temp_file" ]]; then
	  rm "$cmd_line_tools_temp_file"
		fi
	fi
 
# Installing the latest Xcode command line tools on 10.7.x and 10.8.x
 
# on 10.7/10.8, instead of using the software update feed, the command line tools are downloaded
# instead from public download URLs, which can be found in the dvtdownloadableindex:
# https://devimages.apple.com.edgekey.net/downloads/xcode/simulators/index-3905972D-B609-49CE-8D06-51ADC78E07BC.dvtdownloadableindex
 
	if [[ "$osx_vers" -eq 7 ]] || [[ "$osx_vers" -eq 8 ]]; then
 
		if [[ "$osx_vers" -eq 7 ]]; then
	    DMGURL=http://devimages.apple.com/downloads/xcode/command_line_tools_for_xcode_os_x_lion_april_2013.dmg
		fi
	
		if [[ "$osx_vers" -eq 8 ]]; then
	     DMGURL=http://devimages.apple.com/downloads/xcode/command_line_tools_for_xcode_os_x_mountain_lion_march_2014.dmg
		fi
 
		TOOLS=clitools.dmg
		curl "$DMGURL" -o "$TOOLS"
		TMPMOUNT=`/usr/bin/mktemp -d /tmp/clitools.XXXX`
		hdiutil attach "$TOOLS" -mountpoint "$TMPMOUNT" -nobrowse
		installer -pkg "$(find $TMPMOUNT -name '*.mpkg')" -target /
		hdiutil detach "$TMPMOUNT"
		rm -rf "$TMPMOUNT"
		rm "$TOOLS"

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

chmod -R a+rX "${REPONAME}"
chown -R :wheel "${REPONAME}"

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

# Hat Tip to Allister Banks!

VERS=$(curl https://github.com/autopkg/autopkg/releases/latest | cut -c 85-89) ; curl -L "https://github.com/autopkg/autopkg/releases/download/v$VERS/autopkg-$VERS.pkg" -o autopkg-latest1.pkg

installer -pkg autopkg-latest1.pkg -target /

${LOGGER} "AutoPkg Installed"
echo "AutoPkg Installed"

####
# Configure AutoPkg for use with Munki
####


${DEFAULTS} write com.github.autopkg MUNKI_REPO "$REPODIR"

autopkg repo-add http://github.com/autopkg/recipes.git

${DEFAULTS} write com.googlecode.munki.munkiimport editor "${TEXTEDITOR}"
${DEFAULTS} write com.googlecode.munki.munkiimport repo_path "${REPODIR}"
${DEFAULTS} write com.googlecode.munki.munkiimport pkginfo_extension .plist
${DEFAULTS} write com.googlecode.munki.munkiimport default_catalog testing

${LOGGER} "AutoPkg Configured"
echo "AutoPkg Configured"

# This makes AutoPkg useful on future runs for the admin user defined at the top. It copies & creates preferences for autopkg and munki into their home dir's Library folder, as well as transfers ownership for the ~/Library/AutoPkg folders to them.

cp /var/root/Library/Preferences/com.googlecode.munki.munkiimport.plist ~/Library/Preferences
cp /var/root/Library/Preferences/com.github.autopkg.plist ~/Library/Preferences
chmod 660 ~/Library/Preferences/com.googlecode.munki.munkiimport.plist
chmod 660 ~/Library/Preferences/com.github.autopkg.plist

plutil -convert xml1 ~/Library/Preferences/com.googlecode.munki.munkiimport.plist

####
# Get some Packages and Stuff them in Munki
####

autopkg run -v ${AUTOPKGRUN}

${LOGGER} "AutoPkg Run"
echo "AutoPkg has run"

# Bring it on home to the all-powerful, all-wise, local admin... (Thanks Luis)

chown -R ${ADMINUSERNAME} ~/Library/AutoPkg

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
# Install AutoPkg Automation Scripts by the amazing Sean Kaiser
####

cd "${REPOLOC}"
${GIT} clone https://github.com/seankaiser/automation-scripts.git
cd ./automation-scripts/autopkg/
sed -i.orig "s|>autopkg|>${ADMINUSERNAME}|" com.example.autopkg-wrapper.plist
sed -i.orig2 "s|com.example.autopkg-wrapper|${AUTOPKGORGNAME}.autopkg-wrapper|" com.example.autopkg-wrapper.plist
sed -i.orig "s|AdobeFlashPlayer.munki|${AUTOPKGRUN}|" autopkg-wrapper.sh
sed -i.orig2 "s|you@yourdomain.net|${AUTOPKGEMAIL}|" autopkg-wrapper.sh
sed -i.orig3 "s|user=[\"]autopkg[\"]|user=\"${ADMINUSERNAME}\"|" autopkg-wrapper.sh
mv autopkg-wrapper.sh ${SCRIPTDIR}
mv com.example.autopkg-wrapper.plist "/Library/LaunchDaemons/${AUTOPKGORGNAME}.autopkg-wrapper.plist"

launchctl load "/Library/LaunchDaemons/${AUTOPKGORGNAME}.autopkg-wrapper.plist"

####
# Install Munki Admin App by the amazing Hannes Juutilainen
####

cd "${REPOLOC}"
VERS=$(curl https://github.com/hjuutilainen/munkiadmin/releases/latest | cut -c 93-97) ; curl -L "https://github.com/hjuutilainen/munkiadmin/releases/download/v$VERS/munkiadmin-$VERS.dmg" -o "$REPOLOC/munkiadmin.dmg"
TMPMOUNT2=$(/usr/bin/mktemp -d /tmp/munkiadmin.XXXX)
hdiutil attach "$REPOLOC/munkiadmin.dmg" -mountpoint "$TMPMOUNT2" -nobrowse
cp -R "$TMPMOUNT2/MunkiAdmin.app" /Applications/Utilities
hdiutil detach "$TMPMOUNT2" -force

####
# Install Munki Enroll
####

cd "${REPODIR}"
${GIT} clone https://github.com/edingc/munki-enroll.git
mv munki-enroll munki-enroll-host
mv munki-enroll-host/munki-enroll munki-enroll
mv munki-enroll-host/Scripts/munki_enroll.sh munki-enroll
sed -i.orig "s|/munki/|/${HOSTNAME}/|" munki-enroll/munki_enroll.sh

####
#  Install MunkiReport-PHP
####

cd "${WEBROOT}"
${GIT} clone https://github.com/munkireport/munkireport-php.git
cp munkireport-php/config_default.php munkireport-php/config.php
chmod +a "_www allow add_file,delete_child" munkireport-php/app/db
echo "short_open_tag = On" >> "${PHPROOT}/php.ini"
echo "\$auth_config['root'] = '\$P\$BSQDsvw8vyCZxzlPaEiXNoP6CIlwzt/';" >> munkireport-php/config.php

# This creates a user "root" with password "root"
# Now to download the pkgsinfo file into the right place and add it to the catalogs and site_default manifest:

echo "Downloading the MunkiReport Info"

curl -k -L "https://$HOSTNAME/munkireport-php/index.php?/install/plist" -o "${REPODIR}/pkgsinfo/MunkiReport.plist"

echo "Downloaded the MunkiReport Info, Now Rebuilding Catalogs"

/usr/local/munki/makecatalogs

${MANU} add-pkg munkireport --manifest site_default

####
# Clean Up When Done
####

rm "$REPOLOC/autopkg-latest1.pkg"
rm "$REPOLOC/munkitools2.pkg"
rm "$REPOLOC/munkiadmin.dmg"

${LOGGER} "I put my toys away"'!'

echo "Thank you for flying Munki in a Box Air"'!'" You now have a working repo, go forth and install your clients"'!'

exit 0