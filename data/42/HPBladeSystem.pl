#------------------------------------------------------------------
#
# This is a perl discovery agent that discovers the connectivity
# between HP c7000 chassis system and the blade cards that are
# installed and running. It creates slot entries on the discovered
# chassis and attaches the discovered hosts to the slot entries.
#
# This agent has been built using the CiscoSwitchInPerl.pl perl 
# agent structure example.
#
# Special thanks to Jim Kovach at Allstate for providing assistance
# in building this agent.
#
# v1 release 8/22/14
# Jason Cress - IBM SWG
# jcress@us.ibm.com
#
#------------------------------------------------------------------
use strict;
use warnings;
use Data::Dumper;


use RIV;
use RIV::Param;
use RIV::Record;
use RIV::Agent;
use Socket;

$| =1 ;

my $agent;
my $agentName = "HPBladeSystem";

#---------------------------------------------------------------------
#Initiation
#
#---------------------------------------------------------------------
sub Init{
    my $param=new RIV::Param();
    $agent=new RIV::Agent($param, $agentName);
}

#---------------------------------------------------------------------
# ProcessPhase
#
# Do any phase dependent processing. 
#
#---------------------------------------------------------------------
sub ProcessPhase($){
	my $phaseNumber = shift;

	if($RIV::DebugLevel >= 1)
	{
		print "Phase number is $phaseNumber\n";
	}
}

#---------------------------------------------------------------------
# ProcessPhase1
#
# Do processing of the NE necessary during phase 1
#
#---------------------------------------------------------------------
sub ProcessPhase1($){
	my $TestNE = shift;
	if($RIV::DebugLevel >= 1)
	{
		print "Processing Phase 1\n";
		print Dumper($TestNE);
	}


	if($RIV::DebugLevel >= 1)
	{
		print "Entity now .\n";
		print Dumper($TestNE);
	}

	$agent->SendNEToNextPhase($TestNE);
}


#---------------------------------------------------------------------
# ProcessPhase2
#
# Do processing of the NE necessary during phase 2
#
#---------------------------------------------------------------------
sub ProcessPhase2($){
	my $TestNE = shift;
	if($RIV::DebugLevel >= 1)
	{
		print "Processing Phase 2\n";
		print Dumper($TestNE);
	}

	$agent->SendNEToNextPhase($TestNE);
}

#---------------------------------------------------------------------
# ProcessPhase3
#
# Do processing of the NE necessary during phase 3
#
#---------------------------------------------------------------------
sub ProcessPhase3($){
	my $TestNE = shift;
	if($RIV::DebugLevel >= 1)
	{
		print "Processing Phase 3\n";
		print Dumper($TestNE);
	}

   my $blades=$agent->SnmpGetNext($TestNE,'cpqRackServerBladeName');


  for (my $j=0;$j<=$#$blades;$j++)
  {


        my $bladeindex = $blades->[$j]->{ASN1};;
        my $bladename = $blades->[$j]->{VALUE};

	my $slotPosition = $bladeindex;
	my $ifIndex = "655" . $slotPosition;
	my $remoteIp = "";


	# Create a card slot entry for the chassis. The blade will attach here
	
	my %localNbr;
        $localNbr{m_IfIndex} = $ifIndex;
        my $ifDescr = "Card Slot $slotPosition";
        $localNbr{m_IfDescr} = $ifDescr;
        $TestNE->AddLocalNeighbour(\%localNbr);

	# Check to see if there is a host installed in this card slot. If a host is installed, the $bladename variable will contain the host name.
	# If a host is not installed, it will return "Unknown"
	# If a host is installed, we do a gethostbyname on the returned host name, create a remote neighbor record, and attach it to the card slot index

	if($bladename ne "Unknown") 
	{
		if (my ($bladename,$alias,$addrtype,$length,@addrs) = gethostbyname($bladename)) 
		{
			$remoteIp = inet_ntoa($addrs[0]);
		}

		my %remoteNbr;
        	$remoteNbr{m_RemoteNbrIpAddr} = $remoteIp;
        	if($remoteIp)
        	{
                	AttachLocalNbrByIfIndex($TestNE, \%remoteNbr, $ifIndex);
                	print Dumper(\%remoteNbr);
        	}
	}

  }

    delete $TestNE->{'__NcpDiscoAgentNePhase__'};
    $TestNE->{'m_LastRecord'}=1;
    $TestNE->{'m_UpdAgent'}=$agentName;

	print "Sending record to disco: \n";
		print Dumper($TestNE);
	$agent->SendNEToDisco($TestNE,0);
}

#---------------------------------------------------------------------
#
# Find the appropriate local neighbour to connect the remote neighbour to
#
#---------------------------------------------------------------------
sub AttachLocalNbrByIfIndex ($)
{
	my ($TestNE, $refR, $ifIndex) = @_;

	my $foundIt = 0;
	if( ($ifIndex) && ($TestNE) && ($refR) )
	{
		my @localN = $TestNE->GetLocalNeighbours();
		foreach my $lnbr (@localN)
		{
			# Look for the local neighbour that has the same ifIndex as earlier
			if ( ($lnbr->{m_IfIndex}) && ($lnbr->{m_IfIndex} eq $ifIndex) )	
			{
				if($RIV::DebugLevel >= 1)
				{
					print " Matched ifIndex $lnbr->{m_IfIndex} to $ifIndex \n";
					print "Adding to device $TestNE->{m_Name}\n";
					print "via local neighbour \n";
					print Dumper($lnbr);
					print " connection to remote record\n";
					print Dumper($refR);
				}
				$TestNE->AddRemoteNeighbour($lnbr, $refR);
				$foundIt = 1;
			}
		}
	}

	if($foundIt == 0)
	{
		if(!$ifIndex)
		{
			$ifIndex = "NULL";
		}
		print "Failed to find interface with ifIndex $ifIndex for device $TestNE->{m_Name}\n";
		print " to add remote record\n";
		print Dumper($refR);
	}
}

#------------------------------------------------------------------
# create a new agent object
#------------------------------------------------------------------
if($RIV::DebugLevel >= 1)
{
	print "Creating a new agent\n";
}
Init();

#-----------------------------------------------------------------
#
# We are now ready to receive records from the Disco
#
#-----------------------------------------------------------------
print "Entering infinite loop wait for devices for Disco\n";

INFINITE: while (1)
{
	my ($tag,$data)=RIV::GetInput(-1);
	if ($tag ne 'NE')
	{
		print "Data is not a Network entity Ignoring it!\n";
		next INFINITE;
	}

	my $TestNE=new RIV::Record($data);

    if ($TestNE->{m_TerminateAgent})
    {
        print "Exit Main Loop\n";
        exit(0);
    }

	$TestNE->{m_LastRecord}=1;
	$TestNE->{m_UpdAgent}=$agentName;

	# Is the record a phase tag. If it is then process it differently
	if($TestNE->{m_NewPhase})
	{
		ProcessPhase($TestNE->{m_NewPhase});
		next INFINITE;
	}
	else
	{
		# Retrieve the phase
		my $phase = $TestNE->{__NcpDiscoAgentNePhase__};
		if($phase == 1)
		{
			ProcessPhase1($TestNE);
		}
		elsif($phase == 2)
		{
			ProcessPhase2($TestNE);
		}
		elsif($phase == 3)
		{
			ProcessPhase3($TestNE);
		}
		else
		{
			# do nothing;
			print "Unexpected phase, doing nothing\n";
		}
	}
} # the main loop ends

