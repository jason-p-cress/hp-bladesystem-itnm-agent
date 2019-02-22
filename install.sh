#!/bin/bash

##########################
#
# Installation for the VMWareSnmpEsxi agent
#
# 8/29/14
# Jason Cress
# jcress@us.ibm.com 
#
###########################################################

##########################
#
# Subroutines
#
###########################################################
docopy()
{
	if [ -f "$2/$1" ];
	then

		while true; do
			read -p "Warning: $2/$1 already exists, overwrite? ([y]es/[n]o/[c]ancel)" YESNO
			case $YESNO in
				[Yy]* ) echo "Overwriting $2/$1"; cp data/$VERDIR/$1 $2/$1; break;; 
				[Nn]* ) echo "Skipping install of $1"; break;;
				[Cc]* ) echo "Cancelling install"; exit;;
				* ) echo "Please answer y, n, or c";;
			esac
		done
	else
		cp data/$VERDIR/$1 $2
	fi
}

############################
#
# Set up environment
#
#############################################################

if [ -n "$NCHOME" ];
then
	echo "Setting up environment"
else
	echo "NCHOME not set"
	exit
fi

PRECISION_HOME=$NCHOME/precision
ITNM_BIN_DIR=${NCHOME}/precision/bin
    ITNM_CONTROL_FUNCS=${ITNM_BIN_DIR}/itnm_control_functions.sh

    if [ -z "$PRECISION_DOMAIN" ]; then
        PRECISION_DOMAIN=NCOMS
    fi


############################
#
# Obtain ITNM version
#
#######################################################

ITNMVER=`$PRECISION_HOME/bin/ncp_ctrl -version | grep Version |awk '{print $6}'`
echo "ITNM is version $ITNMVER"

case $ITNMVER in
	4.1.1) 
		CHK=852cc31e13a6c2292ceb8ef8bdb7c073
		VERDIR=41
		;; 
	4.1) 
		CHK=852cc31e13a6c2292ceb8ef8bdb7c073
		VERDIR=41
		;;
	3.9) 
		CHK=2a70dae75d6f798c6e97f4562c35e32d
		VERDIR=39
		;;
	* ) echo "This version of ITNM is not supported at this time";;
esac

############################
#
# Begin installation...
#
#############################################################

while true; do
	read -p "This installation program will install the HP Chassis perl-based discovery agent. Do you wish to continue? ([y]yes/[n]o)" INST
	case $INST in
                        [Yy]* ) echo "Installing....."; break;;
                        [Nn]* ) echo "Cancelling install"; exit;;
                        * ) echo "Please answer y or n";;
        esac
done

###########################
#
# Verify required MIBs are installed
#
####################################

if [ -f "$PRECISION_HOME/mibs/CPQRACK.mib" ] && [ -f "$PRECISION_HOME/mibs/CPQHOST.mib" ]  
then
	:
else
	while true; do
		read -p "Warning: Required MIB files do not appear to be installed (CPQHOST-MIB.mib, CPQRACK-MIB.mib). Do you wish to continue install anyway? ([y]es/[n]o)" CONT
		case $CONT in
			[Yy]* ) echo "Continuing with install - ensure that you obtain and install the required VMWare MIBs before activating the agent"; break;;
			[Nn]* ) echo "Cancelling install"; exit;;
			* ) echo "Please answer y or n";;
		esac
	done
fi

############################
#
# Copy files
#
#############################################################

echo "***************************************"
echo "* Installing the HP BladeSystem agent *"
echo "***************************************"

docopy "HPBladeSystem.stch" "$PRECISION_HOME/disco/stitchers"
docopy "HPBladeSystem.pl" "$PRECISION_HOME/disco/agents/perlAgents/"
docopy "HPBladeSystem.agnt" "$PRECISION_HOME/disco/agents"

############################
#
# Register agent
#
#############################################################

$NCHOME/precision/bin/ncp_agent_registrar -register HPBladeSystem

############################
#
# Check to see if PostLayerProcessing stitcher is customized 
#
#############################################################

PLPSMD5=`md5sum $PRECISION_HOME/disco/stitchers/PostLayerProcessing.stch | awk '{print $1}'`
if [ "$PLPSMD5" == "$CHK" ];
then
	echo "*****************************************"
	echo "* Updating PostLayerProcessing stitcher *"
	echo "*****************************************"
	cp data/$VERDIR/PostLayerProcessing.stch $PRECISION_HOME/disco/stitchers
else
	echo "********************************************************************************"
	echo "*                                                                              *"
	echo "* NOTICE: Your PostLayerProcessing.stch is not the default provided with ITNM. *"
	echo "*                                                                              *"
	echo "* Perhaps it has been modified or customized.                                  *"
	echo "*                                                                              *"
	echo "* Please manually add call to HPBladeSystem agent to the PostLayerProcessing   *"
	echo "* stitcher. See the included README for details.                               *"
	echo "*                                                                              *"
	echo "* example:                                                                     *"
	echo "* ExecuteStitcher('HPBladeSystem', isRediscovery);                            *"
	echo "*                                                                              *"
	echo "********************************************************************************"
fi

echo
echo
while true; do
	read -p "Do you wish to install the HPBladeSystem active object class (aoc) file? (not required but recommended) ([y]es/[n]o)" CONT
		case $CONT in
			[Yy]* ) echo "installing AOC file..."; break;;
			[Nn]* ) echo "skipping AOC file install"; exit;;
			* ) echo "Please answer y or n";;
		esac
done
docopy "HPBladeSystem.aoc" "$PRECISION_HOME/aoc/"
