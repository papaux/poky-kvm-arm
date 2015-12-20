#!/bin/bash

# Catch errors
trap check_error ERR

# Configuration variables
SETUP_DIR=$PWD
BUILD_DIR="build"
BBLAYER_CONF_FILE=conf/bblayers.conf

POKY_GIT="git://git.yoctoproject.org/poky.git"
POKY_COMMIT_ID="3c66ad23bec2e69c2a69c8a66c20277c0a0deeb0" # poky daisy 11.0.0 #"ea90bd054c449a8e19c474c8bfa8c289f692c33f"
POKY_LOCAL_BRANCH="daisy-11.0.0"
POKY_DESTDIR="poky-daisy"

LAYERS_DIR=$SETUP_DIR/$POKY_DESTDIR

# Deps list
# Format: GIT_URL;LOCAL_DEST_DIR;COMMIT_ID;LOCAL_BRANCH
DEPS=" \
  git://git.yoctoproject.org/meta-ti;meta-ti;30dc05eb337ffe9f028a5cfd548080e65d97078c;daisy.2014.05.22 \
  git://git.yoctoproject.org/meta-virtualization;meta-virtualization;abf028895344a0e485fa194e5cac8bd7006c670b;master.2014.04.14 \
  git://github.com/openembedded/meta-openembedded.git;meta-oe;dca466c074c9a35bc0133e7e0d65cca0731e2acf;daisy.2014.05.12 \
  git://github.com/papaux/meta-kvm-arm.git;meta-kvm-arm;master"

# Patches
# Format: PATCH_FILE_PATH;APPLICATION_PATH
PATCHES=" \
  "

########################################################################
# Functions definition
########################################################################


function check_error () {
	echo "An error occured, exiting configuration script..."
	exit
}

function print_build_usage () {
	echo "Run the following commands to jump to your build dir"
	echo "   cd $POKY_DESTDIR"
	echo "   source oe-init-build-env"
	echo
	echo "And you can buidl the default kvm target with these commands"
	echo "   MACHINE=omap5-evm-kvm bitbake kvm-image-extended"
	echo "   MACHINE=odroidxu-kvm bitbake kvm-image-extended"
	echo "   MACHINE=odroidxu3-kvm bitbake kvm-image-extended"
}

function check_already_initialized () {
	if [ -d "$POKY_DESTDIR" ]; then
		echo "Your yocto workspace is already initialized..."
		print_build_usage
		exit
	fi
}

function check_working_directory () {
	if [ ! -f $PWD/$(basename $0) ]; then
		echo "This script has to be executed from the current directory, i.e"
		echo ./$(basename $0)
		exit
	fi
}


# First step is to fetch poky...
function fetch_poky () {
	git clone $POKY_GIT $POKY_DESTDIR
	cd $POKY_DESTDIR
	git checkout $POKY_COMMIT_ID -b $POKY_LOCAL_BRANCH
}


# Fetch depedencies defined in $DEPS variable
function fetch_dependencies () {

	for dep in $DEPS
	do
		info=(${dep//;/ })
		repo=${info[0]}
		dst=${info[1]}
		commit=${info[2]}
		localbranch=${info[3]}

		# if already exists...
		if [ -d "$dst" ]; then
			echo
			echo "ERROR: Repository $dst already exists... it seems you already initialized this working directory!"
			print_build_usage
			exit
		fi

		echo "Cloning at $commit from $repo into local branch $localbranch"
		git clone $repo $dst
		cd $dst

		# want to create a new local branch ?
		if [ -n "$localbranch" ]; then
			git checkout $commit -b $localbranch
		else
			git checkout $commit
		fi

		cd $LAYERS_DIR
	done

}


# Apply patches
function apply_patches () {
	for patch in $PATCHES
	do
		info=(${patch//;/ })
		file=${info[0]}
		target=${info[1]}
		echo "Applying patch basename($file) for $target..."
		cd $target
		git apply $file
		cd $LAYERS_DIR
	done

}


function configure_environment () {
	source oe-init-build-env > /dev/null

	# customize configuration
	generate_bblayer_conf
	echo
	echo "Done."
	print_build_usage
}


function generate_bblayer_conf () {

	# backup old file
	mv $BBLAYER_CONF_FILE ${BBLAYER_CONF_FILE}.bak

	# reset file
	> $BBLAYER_CONF_FILE

	# ugly but....
	# default values
	echo '
# LAYER_CONF_VERSION is increased each time build/conf/bblayers.conf
# changes incompatibly
LCONF_VERSION = "6"

BBPATH = "${TOPDIR}"
BBFILES ?= ""

BBLAYERS_NON_REMOVABLE ?= " \
  '"${LAYERS_DIR}"'/meta \
  '"${LAYERS_DIR}"'/meta-yocto \
  "
' > $BBLAYER_CONF_FILE


	# add layers
	echo '

BBLAYERS ?= " \
  '"${LAYERS_DIR}"'/meta \
  '"${LAYERS_DIR}"'/meta-yocto \
  '"${LAYERS_DIR}"'/meta-yocto-bsp \
  '"${LAYERS_DIR}"'/meta-oe/meta-oe \
  '"${LAYERS_DIR}"'/meta-oe/meta-networking \
  '"${LAYERS_DIR}"'/meta-virtualization \
  '"${LAYERS_DIR}"'/meta-ti \
  '"${LAYERS_DIR}"'/meta-kvm-arm \
  "
' >> $BBLAYER_CONF_FILE
}

########################################################################
# Entry code
########################################################################
echo "########################################################################"
echo "# Initialization script for setting up poky for KVM/ARM virtualization"
echo "# Created by Geoffrey Papaux <geoffrey.papaux gmail com>"
echo "########################################################################"
echo

# Check if already initialized
check_already_initialized

# Check if we are in the working directory...
check_working_directory

# First step is to fetch poky
echo
echo "Getting poky..."
echo "#########################"
fetch_poky

# Download required layers
echo
echo "Getting required layers..."
echo "#########################"
fetch_dependencies

# Apply patches needed for our target
echo
echo "Applying patches..."
echo "#########################"
apply_patches

# Configure environment as required for yocto build
echo
echo "Configuring build environment..."
echo "#########################"
configure_environment
