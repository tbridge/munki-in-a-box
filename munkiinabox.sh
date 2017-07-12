#!/bin/bash

# Munki In A Box
# By Tom Bridge, Technolutionary LLC

# Version: 1.5.1 - Basic Auth + AutoPkg 1.0/Trust

# This software carries no guarantees, warranties or other assurances that it works. It may wreck your entire environment. That would be bad, mmkay. Backup, test in a VM, and bug report.

# Approach this script like a swarm of bees: Unless you know what you are doing, keep your distance.

# The goal of this script is to deploy a basic munki repo, with SSL, and basic authentication, in a simple script based on a set of common variables. There are default values in these variables, but they are easily overridden and you should decide what they should be.

# This script is based upon the Demonstration Setup Guide for Munki, AutoPkg, and other sources. My sincerest thanks to Greg Neagle, Tim Sutton, Allister Banks, Rich Trouton, Charles Edge, Hannes Juutilainen, Sean Kaiser, Peter Bukowinski, Elliot Jordan, The Linde Group and numerous others who have helped me assemble this script.

# Pre-Reqs for this script: 10.11/Server 5.  Web Services should be turned on and PHP should be enabled. This script might work with 10.8 or later, but I'm only testing it on 10.11 or later.

# Establish our Basic Variables:

REPOLOC="/Library/Server/Web/Data/Sites/Default"
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
AUTOPKGARRAY=($AUTOPKGRUN)
DEFAULTS="/usr/bin/defaults"
AUTOPKG="/usr/local/bin/autopkg"
MAINPREFSDIR="/Library/Preferences"
ADMINUSERNAME="ladmin"
SCRIPTDIR="/usr/local/bin"
HTPASSWD="YouNeedToChangeThis"


echo "Welcome to Munki-in-a-Box. We're going to get things rolling here with a couple of tests"'!'

echo "First up: Are you an admin user? Enter your password below:"

#Let's see if this works...
#This isn't bulletproof, but this is a basic test.
sudo whoami > /tmp/quickytest

if [[  `cat /tmp/quickytest` == "root" ]]; then
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

if [[ $osvers -lt 8 ]]; then
    ${LOGGER} "Could not run because the version of the OS does not meet requirements"
    echo "Sorry, this is for Mac OS 10.8 or later."
    exit 2 # 10.8+ for the Web Root Location.
fi

if [[ $osvers -lt 10 ]]; then
    echo "##################################################"
    echo "This script is intended for OS X 10.10 or later. It may work on 10.8 or 10.9, but the ride may be a bit bumpy, and things may not go quite the way the script intended them to go. In short, this is not supported, but it probably won't light anything on fire. Be aware."
    echo "##################################################"
fi

${LOGGER} "Mac OS X 10.8 or later is installed."

if [[ $webstatus == *STOPPED* ]]; then
    ${LOGGER} "Could not run because the Web Service is stopped"
    echo "Please turn on Web Services in Server.app"
    exit 3 # Sorry, turn on the webserver.
fi

${LOGGER} "Web service is running."

if [[ $EUID -eq 0 ]]; then
    $echo "This script is NOT MEANT to run as root. This script is meant to be run as an admin user. I'm going to quit now. Run me without the sudo, please."
    exit 4 # Running as root.
fi

#${LOGGER} "Script is running as root."

if [[ ! -d "${WEBROOT}" ]]; then
    echo "No web root exists at ${WEBROOT}. This might be because you don't have Server.app installed and configured."
    exit 5 # Web Root folder doesn't exist.
fi


if [[ ! -f $MUNKILOC/munkiimport ]]; then
    cd ${REPOLOC}
    ${LOGGER} "Grabbing and Installing the Munki Tools Because They Aren't Present"
    MUNKI_LATEST=$(curl https://api.github.com/repos/munki/munki/releases/latest | python -c 'import json,sys;obj=json.load(sys.stdin);print obj["assets"][0]["browser_download_url"]')
    
    curl -L "${MUNKI_LATEST}" -o munki-latest1.pkg
    
    # Write a Choices XML file for the Munki package. Thanks Rich and Greg!
    
    /bin/cat > "/tmp/com.github.munki-in-a-box.munkiinstall.xml" << 'MUNKICHOICESDONE'
<?xml version="1.0" encoding="UTF-8"?>
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

if [[ ! -d /Applications/Xcode.app ]]; then
    echo "You need to install the Xcode command line tools. Let me get that for you, it'll just take a minute."
    
    ###
    # This section written by Rich Trouton and embedded because he's awesome. Diet Coke++, Rich.
    ###
    
    # Installing the Xcode command line tools on 10.7.x through 10.10.x
    
    osx_vers=$(sw_vers -productVersion | awk -F "." '{print $2}')
    cmd_line_tools_temp_file="/tmp/.com.apple.dt.CommandLineTools.installondemand.in-progress"
    
    # Installing the latest Xcode command line tools on 10.9.x, 10.10.x or 10.11.x
    
    if [[ "$osx_vers" -ge 9 ]] ; then
        
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
    
    # Installing the latest Xcode command line tools on 10.7.x and 10.8.x
    
    # on 10.7/10.8, instead of using the software update feed, the command line tools are downloaded
    # instead from public download URLs, which can be found in the dvtdownloadableindex:
    # https://devimages.apple.com.edgekey.net/downloads/xcode/simulators/index-3905972D-B609-49CE-8D06-51ADC78E07BC.dvtdownloadableindex
    
    if [[ "$osx_vers" -eq 7 ]] || [[ "$osx_vers" -eq 8 ]]; then
        
        if [[ "$osx_vers" -eq 7 ]]; then
            DMGURL=http://devimages.apple.com/downloads/xcode/command_line_tools_for_xcode_os_x_lion_april_2013.dmg
        fi
        
        if [[ "$osx_vers" -eq 8 ]]; then
            DMGURL=http://devimages.apple.com/downloads/xcode/command_line_tools_for_xcode_os_x_mountain_lion_april_2014.dmg
        fi
        
        TOOLS=clitools.dmg
        curl "$DMGURL" -o "$TOOLS"
        TMPMOUNT=`/usr/bin/mktemp -d /tmp/clitools.XXXX`
        hdiutil attach "$TOOLS" -mountpoint "$TMPMOUNT" -nobrowse
        sudo installer -allowUntrusted -pkg "$(find $TMPMOUNT -name '*.mpkg')" -target /
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
mkdir "${REPONAME}/icons"

chmod -R a+rX,g+w "${REPONAME}" ## Thanks Arek!
chown -R ${ADMINUSERNAME}:admin "${REPONAME}" ## Thanks Arek!

${LOGGER} "Repo Created"
echo "Repo Created"

####
#	Let's do some .htpasswd work here
####

/bin/cat > "${REPONAME}/.htaccess" << 'HTPASSWDDONE'
AuthType Basic
AuthName "Munki Repository"
AuthUserFile /Library/Server/Web/Data/Sites/Default/munki_repo/.htpasswd
Require valid-user
HTPASSWDDONE

cd ${REPONAME}

htpasswd -cb .htpasswd munki $HTPASSWD
HTPASSAUTH=$(python -c "import base64; print \"Authorization: Basic %s\" % base64.b64encode(\"munki:$HTPASSWD\")")
# Thanks to Mike Lynn for the fix

sudo chmod 640 .htaccess .htpasswd
sudo chown _www:wheel .htaccess .htpasswd

####
# Create a client installer pkg pointing to this repo. Thanks Nick!
####

if [[ ! -f /usr/bin/pkgbuild ]]; then
    ${LOGGER} "Pkgbuild is not installed."
    echo "Please install Xcode command line tools first."
    exit 0 # Gotta install the command line tools.
fi

mkdir -p /tmp/ClientInstaller/Library/Preferences/

HOSTNAME=$(/bin/hostname)
${DEFAULTS} write /tmp/ClientInstaller/Library/Preferences/ManagedInstalls SoftwareRepoURL "https://$HOSTNAME/${REPONAME}" && ${DEFAULTS} write /tmp/ClientInstaller/Library/Preferences/ManagedInstalls AdditionalHttpHeaders -array "$HTPASSAUTH"

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
${AUTOPKG} repo-add rtrouton-recipes
${AUTOPKG} repo-add jleggat-recipes
${AUTOPKG} repo-add timsutton-recipes
${AUTOPKG} repo-add nmcspadden-recipes
${AUTOPKG} repo-add jessepeterson-recipes

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

aLen=${#AUTOPKGARRAY[@]}
echo "$aLen" "overrides to create"

for (( j=0; j<aLen; j++));
do
    ${LOGGER} "Adding ${AUTOPKGARRAY[$j]} override"
    ${AUTOPKG} make-override ${AUTOPKGARRAY[$j]}
    ${LOGGER} "Added ${AUTOPKGARRAY[$j]} override"
done

${AUTOPKG} run -v ${AUTOPKGRUN}


${LOGGER} "AutoPkg Run"
echo "AutoPkg has run"

# Bring it on home to the all-powerful, all-wise, local admin... (Thanks Luis)

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
${AUTOPKG} make-override AutoPkgr.install

${AUTOPKG} run AutoPkgr.install

${LOGGER} "AutoPkgr Installed"
echo "AutoPkgr Installed"

mkdir /Users/$ADMINUSERNAME/Library/Application\ Support/AutoPkgr
touch /Users/$ADMINUSERNAME/Library/Application\ Support/AutoPkgr/recipe_list.txt

echo "com.github.autopkg.munki.munkitools2
com.github.autopkg.munki.makecatalogs" > /Users/$ADMINUSERNAME/Library/Application\ Support/AutoPkgr/recipe_list.txt

####
# Install Munki Admin App by the amazing Hannes Juutilainen
####

${AUTOPKG} make-override MunkiAdmin.install

${AUTOPKG} run MunkiAdmin.install

####
#  Install MunkiReport-PHP
####

cd "${WEBROOT}"
${GIT} clone https://github.com/munkireport/munkireport-php.git
MR_CONFIG="munkireport-php/config.php"
MR_BASEURL="https://$HOSTNAME/munkireport-php/index.php?"
MR_DB_DIR="/var/munkireport"

# Create database directory
sudo mkdir -p $MR_DB_DIR
sudo chmod +a "_www allow add_file,delete_child" $MR_DB_DIR

echo "<?php" > ${MR_CONFIG}
echo >> ${MR_CONFIG}
echo "\$conf['pdo_dsn'] = 'sqlite:$MR_DB_DIR/db.sqlite';" >> ${MR_CONFIG}

# This creates a user "root" with password "root"
echo "\$auth_config['root'] = '\$P\$BSQDsvw8vyCZxzlPaEiXNoP6CIlwzt/';" >> ${MR_CONFIG}

# Now to download the pkgsinfo file into the right place and add it to the catalogs and site_default manifest:

echo "Downloading available modules"

curl -k -L "$MR_BASEURL/install/dump_modules/config" >> ${MR_CONFIG}

echo "Creating the MunkiReport Client installer package"

bash -c "$(curl -k -L $MR_BASEURL/install)" bash -i ${REPOLOC}

echo "Importing the munkireport Client installer package"

$MUNKILOC/munkiimport -n "$REPOLOC/munkireport-"*.pkg

echo "Imported the MunkiReport Client installer package, Now Rebuilding Catalogs"

/usr/local/munki/makecatalogs

${MANU} add-pkg munkireport --manifest site_default

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
echo "Be sure to login to MunkiReport-PHP at http://localhost/munkireport-php and initiate the database, as well change the login password."

echo "Now go turn on Allow Overrides on in Advanced Settings in the Web Service."

exit 0
