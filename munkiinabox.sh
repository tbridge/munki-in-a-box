#!/bin/bash

# Munki In A Box
# By Tom Bridge, Technolutionary LLC

# Version: 0.4.2

# This software carries no guarantees, warranties or other assurances that it works. It may wreck your entire environment. That would be bad, mmkay. Backup, test in a VM, and bug report. 

# Approach this script like a swarm of bees: Unless you know what you are doing, keep your distance.

# The goal of this script is to deploy a basic munki repo in a simple script based on a set of common variables. I have placed defaults in these variables, but they are easily overridden and you should decide where they go.

# This script is based upon the Demonstration Setup Guide for Munki, AutoPKG, and other sources. My sincerest thanks to Greg Neagle, Tim Sutton, Allister Banks, Rich Trouton, Charles Edge, Hannes Juutilainen, Sean Kaiser, Peter Bukowinski and numerous others who have helped me assemble this script.

# Pre-Reqs for this script: 10.8/Server 2 or 10.9/Server 3.  Web Services should be turned on.

# Establish our Basic Variables:

REPOLOC="/Users/Shared/"
REPONAME="munki_repo"
REPODIR=${REPOLOC}${REPONAME}
LOGGER="/usr/bin/logger -t Munki-in-a-Box"
MUNKILOC="/usr/local/munki"
WEBROOT="/Library/Server/Web/Data/Sites/Default"
PHPROOT="/Library/Server/Web/Config/php"
GIT="/usr/bin/git"
MANU="/usr/local/munki/manifestutil"
TEXTEDITOR="TextWrangler.app"
osvers=$(sw_vers -productVersion | awk -F. '{print $2}') # Thanks Rich Trouton
webstatus=$(serveradmin status web | awk '{print $3}') # Thanks Charles Edge
AUTOPKGRUN="AdobeFlashPlayer.munki AdobeReader.munki Dropbox.munki Firefox.munki GoogleChrome.munki OracleJava7.munki TextWrangler.munki munkitools.munki MakeCatalogs.munki"
DEFAULTS="/usr/bin/defaults"
MAINPREFSDIR="/Library/Preferences"
ADMINUSERNAME="ladmin"
SCRIPTDIR="/usr/local/bin"
AUTOPKGEMAIL="youraddress@domain.com"
AUTOPKGORGNAME="com.technolutionary"

echo "Welcome to Munki-in-a-Box. We're going to get things rolling here with a couple of tests!"

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
	${LOGGER} "Web Server is Stopped, trying to start"
	echo "Web Server is off, Going to try to Enable It with PHP Support."
	sed -i.orig "s/^#LoadModule php5_module/LoadModule php5_module/g" /etc/apache2/httpd.conf
	${LOGGER} "Enabled PHP Support"
	serveradmin start web
	webstatus=$(serveradmin status web | awk '{print $3}')
	if
		[[ $webstatus == *STOPPED* ]]; then
		${LOGGER} "Web Server is Stopped, Was unable to Start, Quiting"
		echo "Web Server is off, Was unable to Start, Please start Yourself"
		exit 0 # Sorry, turn on the webserver.	
	fi
	${LOGGER} "Web Server Started"
	echo "Web Server Started"
fi

if

	[[ ! -f $MUNKILOC/munkiimport ]]; then
	${LOGGER} "Installing Munki Tools Because They Aren't Present"
	curl -L https://munkibuilds.org/munkitools-latest.dmg -o $REPOLOC/munkitools.dmg
	hdiutil attach $REPOLOC/munkitools.dmg -nobrowse -mountpoint /Volumes/munkitools
	
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

	/usr/sbin/installer -dumplog -verbose -applyChoiceChangesXML /tmp/com.github.munki-in-a-box.munkiinstall.xml -pkg "$(/usr/bin/find /Volumes/munkitools -maxdepth 1 \( -iname \*\.pkg -o -iname \*\.mpkg \))" -target "/" 

	${LOGGER} "Installed Munki Admin and Munki Core packages"
	echo "Installed Munki packages"	 
	 
fi	

# Check created here by Tim Sutton, for which I owe him a beer. Or six.

if 

	[[ ! -d /Applications/Xcode.app ]]; then
	echo "You need to install the Xcode command line tools. Let me get that for you, it'll just take a minute."
# Get and install Xcode CLI tools
OSX_VERS=$(sw_vers -productVersion | awk -F "." '{print $2}')
 
# on 10.9, we can leverage SUS to get the latest CLI tools
	if [ "$OSX_VERS" -ge 9 ]; then

    # create the placeholder file that's checked by CLI updates' .dist code 
    # in Apple's SUS catalog
    	touch /tmp/.com.apple.dt.CommandLineTools.installondemand.in-progress

    # find the update with "Developer" in the name
    	PROD=$(softwareupdate -l | grep -B 1 "Developer" | head -n 1 | awk -F"*" '{print $2}')

    # install it
    # amazingly, it won't find the update if we put the update ID in double-quotes
    	softwareupdate -i $PROD -v
 
# on 10.7/10.8, we instead download from public download URLs, which can be found in
# the dvtdownloadableindex:
# https://devimages.apple.com.edgekey.net/downloads/xcode/simulators/index-3905972D-B609-49CE-8D06-51ADC78E07BC.dvtdownloadableindex
		else
    	[ "$OSX_VERS" -eq 7 ] && DMGURL=http://devimages.apple.com/downloads/xcode/command_line_tools_for_xcode_os_x_lion_april_2013.dmg
    	[ "$OSX_VERS" -eq 8 ] && DMGURL=http://devimages.apple.com/downloads/xcode/command_line_tools_for_xcode_os_x_mountain_lion_march_2014.dmg

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

echo "Great! All Tests are passed, so let's create the Munki Repo!"

# Create the repo.

cd $REPOLOC
mkdir ${REPONAME}
mkdir ${REPONAME}/catalogs
mkdir ${REPONAME}/manifests
mkdir ${REPONAME}/pkgs
mkdir ${REPONAME}/pkgsinfo

chmod -R a+rX ${REPONAME}
chown -R :admin ${REPONAME}

${LOGGER} "Repo Created"
echo "Repo Created"


####

# Create a client installer pkg pointing to this repo

####

if 
	[[ ! -f /usr/bin/pkgbuild ]]; then
	${LOGGER} "Pkgbuild is not installed."
	echo "Please install Xcode command line tools first."
	exit 0 # Gotta install the command line tools.
fi

mkdir -p /tmp/ClientInstaller/Library/Preferences/

HOSTNAME=`/bin/hostname`
${DEFAULTS} write /tmp/ClientInstaller/Library/Preferences/ManagedInstalls.plist SoftwareRepoURL "http://$HOSTNAME/${REPONAME}"

/usr/bin/pkgbuild --identifier com.munkibox.client.pkg --root /tmp/ClientInstaller ClientInstaller.pkg

${LOGGER} "Client install pkg created."
echo "Client install pkg is created. It's in the base of the repo."
	
####

# Get AutoPKG

####

# Hat Tip to Allister Banks!

VERS=`curl https://github.com/autopkg/autopkg/releases/latest | cut -c 85-89` ; curl -L https://github.com/autopkg/autopkg/releases/download/v$VERS/autopkg-$VERS.pkg -o autopkg-latest1.pkg

installer -pkg autopkg-latest1.pkg -target /

${LOGGER} "AutoPKG Installed"
echo "AutoPKG Installed!"

####

# Configure AutoPKG for use with Munki

####


${DEFAULTS} write com.github.autopkg MUNKI_REPO $REPODIR

autopkg repo-add http://github.com/autopkg/recipes.git

${DEFAULTS} write com.googlecode.munki.munkiimport editor ${TEXTEDITOR}
${DEFAULTS} write com.googlecode.munki.munkiimport repo_path ${REPODIR}
${DEFAULTS} write com.googlecode.munki.munkiimport pkginfo_extension .plist
${DEFAULTS} write com.googlecode.munki.munkiimport default_catalog testing

${LOGGER} "AutoPKG Configured"
echo "AutoPKG Configured"

# This makes AutoPKG useful on future runs for the admin user defined at the top. It copies & creates preferences for autopkg and munki into their home dir's Library folder, as well as transfers ownership for the ~/Library/AutoPkg folders to them.

cp /var/root/Library/Preferences/com.googlecode.munki.munkiimport.plist ~/Library/Preferences
cp /var/root/Library/Preferences/com.github.autopkg.plist ~/Library/Preferences
chmod 660 ~/Library/Preferences/com.googlecode.munki.munkiimport.plist
chmod 660 ~/Library/Preferences/com.github.autopkg.plist

plutil -convert xml1 ~/Library/Preferences/com.googlecode.munki.munkiimport.plist

####

# Get some Packages and Stuff them in Munki

####

autopkg run -v ${AUTOPKGRUN}

${LOGGER} "AutoPKG Run"
echo "AutoPKG has run"

# Bring it on home to the all-powerful, all-wise, local admin... (Thanks Luis)

chown -R ${ADMINUSERNAME} ~/Library/AutoPkg

####

# Create new site_default manifest and add imported packages to it

####

${MANU} new-manifest site_default
echo "Site_Default created"
${MANU} add-catalog testing --manifest site_default
echo "Testing Catalog added to Site_Default"

listofpkgs=(`${MANU} list-catalog-items testing`)
echo "List of Packages for adding to repo:" ${listofpkgs[*]}

# Thanks Rich! Code for Array Processing borrowed from First Boot Packager
# Original at https://github.com/rtrouton/rtrouton_scripts/tree/master/rtrouton_scripts/first_boot_package_install/scripts

tLen=${#listofpkgs[@]} 
echo $tLen " packages to install"

for (( i=0; i<${tLen}; i++));
do 
	${LOGGER} "Adding "${listofpkgs[$i]}" to site_default"
	${MANU} add-pkg ${listofpkgs[$i]} --manifest site_default
	${LOGGER} "Added "${listofpkgs[$i]}" to site_default"
done

####

# Install AutoPKG Automation Scripts by the amazing Sean Kaiser [[ NOW IN BETA ]]

####

cd ${REPOLOC}
git clone https://github.com/seankaiser/automation-scripts.git
cd ./automation-scripts/autopkg/
sed -i.orig "s|>autopkg|>${ADMINUSERNAME}|" com.example.autopkg-wrapper.plist
sed -i.orig2 "s|com.example.autopkg-wrapper|${AUTOPKGORGNAME}.autopkg-wrapper|" com.example.autopkg-wrapper.plist
sed -i.orig "s|AdobeFlashPlayer.munki|${AUTOPKGRUN}|" autopkg-wrapper.sh
sed -i.orig2 "s|you@yourdomain.net|${AUTOPKGEMAIL}|" autopkg-wrapper.sh
sed -i.orig3 "s|user=[\"]autopkg[\"]|user=\"${ADMINUSERNAME}\"|" autopkg-wrapper.sh
mv autopkg-wrapper.sh ${SCRIPTDIR}
mv com.example.autopkg-wrapper.plist /Library/LaunchDaemons/${AUTOPKGORGNAME}.autopkg-wrapper.plist

launchctl load /Library/LaunchDaemons/${AUTOPKGORGNAME}.autopkg-wrapper.plist

####

# Install Munki Admin App by the amazing Hannes Juutilainen

####

cd ${REPOLOC}
VERS=`curl https://github.com/hjuutilainen/munkiadmin/releases/latest | cut -c 93-97` ; curl -L https://github.com/hjuutilainen/munkiadmin/releases/download/v$VERS/munkiadmin-$VERS.dmg -o $REPOLOC/munkiadmin.dmg
hdiutil attach $REPOLOC/munkiadmin.dmg -nobrowse
cd /Volumes/MunkiAdmin-$VERS/
cp -R /Volumes/MunkiAdmin-$VERS/MunkiAdmin.app /Applications/Utilities
hdiutil detach /Volumes/MunkiAdmin-$VERS -force

####

# Install Munki Enroll

####

cd ${REPODIR}
git clone https://github.com/edingc/munki-enroll.git
mv munki-enroll munki-enroll-host
mv munki-enroll-host/munki-enroll munki-enroll
mv munki-enroll-host/Scripts/munki_enroll.sh munki-enroll
sed -i.orig "s|/munki/|/${HOSTNAME}/|" munki-enroll/munki_enroll.sh

####

#  Install MunkiReport-PHP

####

cd ${WEBROOT}
git clone https://github.com/munkireport/munkireport-php.git
cp munkireport-php/config_default.php munkireport-php/config.php
chmod +a "_www allow add_file,delete_child" munkireport-php/app/db
echo "short_open_tag = On" >> ${PHPROOT}/php.ini
echo "\$auth_config['root'] = '\$P\$BSQDsvw8vyCZxzlPaEiXNoP6CIlwzt/';" >> munkireport-php/config.php 

# This creates a user "root" with password "root"


####

# Clean Up When Done

####

rm $REPOLOC/autopkg-latest1.pkg
rm $REPOLOC/munkitools.dmg
rm $REPOLOC/munkiadmin.dmg

${LOGGER} "I put my toys away!"

echo "Thank you for flying Munki in a Box Air! You now have a working repo, go forth and install your clients!"

exit
