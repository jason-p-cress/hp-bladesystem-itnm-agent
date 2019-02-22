------------------------------------------------------------------

 This is a perl discovery agent that discovers the connectivity
 between HP c3000/c7000 chassis system and the blade cards that are
 installed and running. It creates slot entries on the discovered
 chassis and attaches the discovered hosts to the slot entries.

 This agent has been built using the CiscoSwitchInPerl.pl perl 
 agent structure example.

 Special thanks to Jim Kovach at Allstate for providing assistance
 in building this agent.

 v1 release 8/22/14
 v1.2 release 10/18/17

 Jason Cress - IBM SWG
 jcress@us.ibm.com

------------------------------------------------------------------



Requirements
============

This agent requires that a resolvable name is configured for the blade card at
the blade chassis configuration (i.e. proper hostname). You can verify that this is
configured properly by walking the CPQRACK-MIB cpqRackServerBladeName table. Ensure
that each entry that is returned from this table contains a resolvable name.

The ITNM host on which the agent will be running must be able to resovle the blade card names.

The HP BladeSystem chassis IP address as well as the desired card IP addresses must be
in the discovery scope.

The BladeSystem C7000 chassis must have SNMP enabled, and you must have configured the
correct SNMP community string in the "Passwords" section of the ITNM discovery configuration.

Obtain and install the following HP BladeSystem SNMP MIB files in $NCHOME/precision/mibs directory:

CPQRACK-MIB
CPQHOST-MIB

These files can be obtained from HP.


Installation
============

Run the "install.sh" command to install the agent. Follow the prompts to install the agent.

The installation script will replace the default PostLayerProcessing.stch file. If the default PostLayerProcessing
stitcher has been modified or customized, you will be notified of this fact. In this case you will need to 
manually add the call to the HPBladeSystem.stch file as such:


---------------- begin example snippet ----------------
        ExecuteStitcher('RemoveOutOfBandConnectivity' , isRediscovery);

        // This stitcher is not essential, and is therefore commented out.
        // Uncomment it only if there is problem of RCA due to the
        // SUBNET_OBJECT connections to the devices.
        //
        //ExecuteStitcher('RemoveExcessSubnetLinks' , isRediscovery);

--->    ExecuteStitcher('HPBladeSystem', isRediscovery);


        if (inferPEsUsingBGP == 1)
        {
            ExecuteStitcher('CreateMPLSPE' , isRediscovery);
        }
	}
---------------- end example snippet ----------------


Configuring the agent
=====================

To enable the discovery agent, log into the Tivoli Integrated Portal as a user with discovery configuration rights, 
and navigate to Discovery->Network Discovery Configuration. Click on the "Full Discovery Agents" tab, and enable the
"HPBladeSystem" agent.

Running discovery
=================

Perform a full discovery and verify connectivity.


