#!/bin/bash

# vim: set ts=4 sw=4 expandtab :

# TITLE: update-uv-ca-store.sh
# AUTH:  Austin Sabel
# DATE:  07/10/2015
#
# PROGRAM DESCRIPTION:
#    This script will automatically backup and update the u2rcs root Certificate Store 
#    using the Mozilla CA Store export hosted but the curl project
#
# MODIFICATION:
# mm-dd-yy	Username	Description
# 07-10-15	asabel		Initial coding

if [ $UID != 0 ]; then
	echo "Must be run as root"
	exit
fi

[ "$1" == "reset" ] && reset=true || reset=false

uvhome="`cat /.uvhome`"
uvbin="${uvhome}/bin"

# Delete old ca-bundle.pem
[ -d "/tmp/ca-bundle.pem" ] && /bin/rm /tmp/ca-bundlle.pem

BACKUP="${uvhome}/u2rcs.$(date +%Y%m%d)"

# Check if backup already exist for today
if [ -f "${BACKUP}" ]; then
	echo "It appears you have already run this once today."
	echo "This will overwrite your previous backup."
	echo "Are you sure you want to run it again? (y/N):"
	echo ""
	
	read ans

	case ${ans} in
		y|Y)    echo "Continuing..."
                echo ""
                ;;
		n|N|*) exit;;
	esac
fi

# Download ca-bundle.pem (exported from Mozilla CA Store)
curl -s -o /tmp/ca-bundle.pem http://curl.haxx.se/ca/cacert.pem -f 
RESULT=$?

if [ $RESULT == 0 ]; then
	# Download was successful

	# Back up .u2rcs
	echo "Creating backup of .u2rcs"
	echo ""
	cp ${uvhome}/.u2rcs ${BACKUP}

	# Reset if requested
	if $reset; then
		echo "reset option specified. Purging default u2rcs"
		echo ""
		/bin/rm ${uvhome}/.u2rcs
	fi

	# Load ca-bundle.pem
	echo "Importing ca-bundle.pem to default u2rcs"
	echo "========================================"

	${uvbin}/rcsman -import -file /tmp/ca-bundle.pem

	echo "========================================"

	echo
	echo "Import completed"

else 
	# Download was not so successful
	echo "Unable to download CA bundle from http://curl.haxx.se/ca/cacert.pem"
	echo "Please check your network connectivity and try again"
fi
