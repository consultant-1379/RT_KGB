#!/usr/bin/perl

use strict;
use warnings;
no warnings 'uninitialized';
use Data::Dumper;

my ($secs,$mins,$hours,$mdays,$mons,$years,$wdays, $ydays,$isdsts)=localtime( time - 86400 );
$mons++;
$years=1900+$years;
my $yesterdayDate = sprintf "%02d-%02d-%4d", $mdays,$mons,$years;

############################################################### Copying Files from Storage(TopologyFiles) to Server(Predefined Path)
sub copyFilesFromTopoToServer{
	my $topologyFile = $_[0];
	my $string = $_[1];
	my $dir = $_[2];
	my $srcPath = $topologyFile.$string;
	my $targetPath = '/eniq/data/pmdata/eniq_oss_1/'.$dir;
	print "SourcePath : $srcPath \n TargetPath: $targetPath \n";
	system ("mkdir -p $targetPath ") == 0 or die "failed to create a directory $targetPath\n";
	system ("cp -R $srcPath $targetPath");
}

sub epfgdataGeneration{
	my ($line);
	my $i;
	my @array;
	my @query_array;
	my $key;
	my $path;
	my $epfgpropertiesfile = '/eniq/home/dcuser/epfg/config/epfg.properties';
	my $topologyFile = '/eniq/home/dcuser/TopologyFiles/';
	
	my $file = '/eniq/home/dcuser/data.txt';
	open FILE, '<', $file or die "Could not open '$file', No such file found in the provided path $!\n";
	@array = <FILE>;
	print "@array\n";
	close(FILE);
	my $count = @array;

###############################################################
	
	for ($i=0;$i<$count;$i++) {
		undef $line;
		$line = shift @array;
		chomp $line;
		print "$line\n";
		my ($d,$string,$r,$b) = $line  =~ m/(DC_\w_|DIM_\w_)(\w*)(\_R.+\_b)(\d+)/;
		print "$d";
		print "$string\n";
		################################ List of gen flags from epfg.properties file 
		my %PmGenNodes = (
				"GGSN" => ["ggsnGenFlag" , "ggsnMpgGenFlag" , "ggsnPgwGenFlag" , "ggsnSgwGenFlag" , "ggsnNodeGenFlag" , "epgMbmSgwGenFlag" , "epgyangGenFlag" , "epgyang2GenFlag"],
				"SGSN" => ["enable3gppGenFlag" ,"ebssSgsnGenFlag" , "sgsnGenFlag"],
				"SGSNMME" => ["sgsnMmeGenFlag" , "sgsnmmecomGenFlag"],
				"SNMP" => ["snmpNtpGenFlag" , "snmpMgcGenFlag" , "snmpIpRouterGenFlag" , "snmpHpMrfpGenFlag" ,"snmpHotsipGenFlag","snmpDnsServerGenFlag","snmpDhcpServerGenFlag","snmpCsMsGenFlag","snmpCsDsGenFlag","snmpCsCdsGenFlag","snmpCsAsGenFlag","snmpLanSwitchGenFlag","snmpGgsnGenFlag","snmpFirewallGenFlag","snmpAcmeGenFlag"],
				"MGW"  => ["mrsGenFlag","mgwGenFlag" , "mgw2fdGenFlag"],
				"SASN" => ["sasnGenFlag" , "sasnSaraGenFlag" , "sasn3gppGenFlag"],
				"SAPC" => ["sapcGenFlag" ,"sapcECIMGenFlag","sapcTSPGenFlag"],
				"IMSGW_SBG" => ["sbgGenFlag","ISSBGGenFlag",],
				"IMS" => ["cscfGenFlag","imsWuigmGenFlag" ,"imsGenFlag","imsMGenFlag","imsTSPGenFlag"],
				"HSS" => ["hssTSPGenFlag","hssGenFlag" ,"hssECIMGenFlag"],
				"RNC" => ["rncGenFlag"],
				"BSS" => ["bscApgGenFlag" , "bscIogGenFlag" , "ebagBscGenFlag" , "bssEventGenFlag" , "GSMMixModeOffGenFlag"],
				"RBS" => ["wranRBSGenFlag"],
				"STN" => ["stnPicoGenFlag" , "stnSiuGenFlag" , "stnTcuGenFlag" ],
				"CPG" => ["cpgGenFlag"],
				"DSC" => ["dscGenFlag"],
				"EPDG" => ["epdgGenFlag"],
				"TCU" => ["Tcu03GenFlag" , "vTIFGenFlag" , "twampSlGenFlag" , "RadioNodeMixedGenFlag" , "RBSG2GenFlag" , "GSMG2GenFlag" , "5GRadioNodeGenFlag" , "nrEventsGenFlag", "vPPGenFlag"],
				"REDBACK" => ["edgeRtrGenFlag" , "RedbComEcimGenFlag"],
				"MTAS" => ["mtasGenFlag"."mtasTSPGenFlag"],
				"CUDB" => ["cudbGenFlag"],
				"IMS_IPW" => ["ipworksGenFlag"],
				"CSCF" => ["vcscfGenFlag"],
				"SMPC" => ["smpcGenFlag"],
				"GMPC" => ["gmpcGenFlag"],
				"ERBS" => ["lteEventGenFlag","wranLteGenFlag"],
				"REDB" => ["smartMetroGenFlag"],
				"MGC" => ["mgcGenFlag"], 
				"CNAXE" => ["hlrBsGenFlag" , "mscApgGenFlag" , "mscApgOmsGenFlag" , "mscIogGenFlag" , "mscIogOmsGenFlag" , "mscBcGenFlag" , "mscBcOmsGenFlag" , "hlrApgGenFlag" , "hlrIogGenFlag"],
				"BBSC" => ["bbscGenFlag"],
				"CCDM" => ["CCDMGenFlag"],
				"CCRC" => ["CCRCGenFlag"],
				"CCSM" => ["CCSMGenFlag"],
				"CISCO" => ["CISCOGenFlag"],
				"CCPC" => ["CCPCGenFlag"],
				"CCES" => ["CCESGenFlag"],
				"IPTRANSPORT" => ["spitfireGenFlag","ipTransportGenFlag","FrontHaulGenFlag","MinilinkOutdoorGenFlag","MiniLinkIndoorSNMPGenFlag" , "MinilinkoutdoorSwitchGenFlag"],
				"JUNOS" => ["JUNIPERGenFlag"],
				"MRS" => ["mrsGenFlag","MRSvGenFlag"],
				"NETOP" => ["mrrGenFlag","NCSGenFlag"],
				"NR" => ["5GRadioNodeGenFlag","nrEventsGenFlag", "RadioNodeMixedGenFlag"],
				"PCC" => ["PCCGenFlag"],
				"AFG" => ["afgGenFlag"],
				"BSP" => ["bspGenFlag"],
				"WMG" => ["WmgGenFlag" , "wmgyangGenFlag"],
				"ESC" => ["EscGenFlag"],
				"PCG" => ["PCGGenFlag"],
				"SMSF" => ["SMSFGenFlag"],
				"SC" => ["SCGenFlag"],
				"CUDB" => ["cudbGenFlag" , "EirFeGenFlag"],
				"SCEF" => ["scefGenFlag"],
				"ERBSG2" => ["erbsg2GenFlag" , "RadioNodeMixedGenFlag"],
				"RBSG2" => ["RadioNodeMixedGenFlag" , "RBSG2GenFlag"],
				"BTSG2" => ["RadioNodeMixedGenFlag" , "GSMG2GenFlag"],
				"RNC" => ["rncGenFlag"],
				"CPP" => ["rncGenFlag" , "wranRXIGenFlag" , "wranRBSGenFlag","wranLteGenFlag"],
				"RXI" => ["wranRXIGenFlag"],
				"TSSAXE" => ["TSSAXEASNAPGGenFlag" , "TSSAXEASNIOGGenFlag" , "TSSAXEASNOmsGenFlag" , "TSSAXE3gppGenFlag"],
				"UDM" => ["UdmGenFlag"],
				"CONTROLLER" => ["ControllerGenFlag"],
				"CMN_STS" => ["GSMMixModeOffGenFlag"],
				"UPG" => ["upgGenFlag"],
				"WCG" => ["WcgGenFlag"],
				"vEME" => ["vEMEGenFlag"],
				"vPP" => ["vPPGenFlag"],
				"IMSGW_MGC" => ["mgcGenFlag"],
				"PRBS_ERBS" => ["PRBSGenFlag"],
				"PRBS_RBS" => ["PRBSGenFlag"],
				"REDB" =>["smartMetroGenFlag" ,"mlpppGenFlag","edgeRtrGenFlag","cpgGenFlag","edgeRtrGenFlag","RedbComEcimGenFlag"],
				"REDBACK" => ["smartMetroGenFlag","mlpppGenFlag","edgeRtrGenFlag","cpgGenFlag","edgeRtrGenFlag","RedbComEcimGenFlag"],
				"RAN" => ["rncGenFlag"],
				"SOEM_MBH" => ["emMtnGenFlag","emMspGenFlag","emSpoGenFlag","emXsaGenFlag","emMdrsGenFlag","emAxxGenFlag","emSmaGenFlag","emSmxGenFlag","emEtuGenFlag","emMleGenFlag","emMhcGenFlag","emMbaGenFlag","emImtGenFlag","emPmhGenFlag","emMetGenFlag","emSprGenFlag"],
				"TSS_TGC" => ["tssTgcGenFlag"],
				"IMSGW_MGW" => ["mgwGenFlag"],
				"IPPROBE" => ["TwampGenTopology"],
			);
		
		my %PmDirList = (
				"LTE" => ["lte/topologyData"],                                                           
				"ERBS" => ["lte/topologyData/ERBS"],                                                        
				"NR"  => ["nr/topologyData/5GRadioNode"],                                                    
				"CSCF" => ["core/topologyData/CoreNetwork"],
				"MTAS" => ["core/topologyData/CoreNetwork"],
				"WMG" => ["core/topologyData/CoreNetwork"],
				"CCSM" => ["5GCORE"],
				"CCRC" => ["5GCORE"],
				"CCDM" => ["5GCORE"],
				"CCPC" => ["5GCORE"],
				"PCC" => ["5GCORE"],
				"PCG" => ["5GCORE"],
				"NRFAGENT" => ["5GCORE"],
				"IPTRANSPORT" => ["transport/topologyData"],
				"BSP" => ["core/topologyData/CoreNetwork"],
				"IMSGW_SBG" => ["core/topologyData/CoreNetwork"],
				"LLE" => ["LLEConfig"],
				"BTSG2" => ["gsm/topologyData/RADIO"],
				"AFG" => ["core/topologyData/CoreNetwork"],
				"CUDB" => ["core/topologyData/CoreNetwork"],
				"ESC" => ["transport/topologyData/ESC"],
				"SAPC" => ["core/topologyData/CoreNetwork"],
				"IMS_IPW" => ["core/topologyData/CoreNetwork"],
				"MRS" => ["core/topologyData/CoreNetwork"], 
				"RNC" => ["utran/topologyData/RNC"],
				"RBS" => ["utran/topologyData/RBS"],
				"RXI" => ["utran/topologyData/RXI"],
				"CPP" => ["utran/topologyData" , "lte/topologyData/ERBS"],
				"CNAXE" => ["core/topologyData/AXE"],
				"vPP" => ["5G/topologyData/vPP"],
				"TSSAXE" => ["tss/topologyData/AXE"],
				"CCES" => ["5GCORE"],
				"ERBSG2" => ["lte/topologyData/ERBS"],
				"vEME" => ["core/topologyData/CoreNetwork"],
				"CN" => ["core"],
				"JUNOS" =>["transport/topologyData/JUNOS_XML"],
				"BSS" => ["gran/topologyData/GranNetwork"],
				"CISCO" => ["transport/topologyData/CISCO_XML"],
				"GGSN" => ["core/topologyData/CoreNetwork"], 
				"HSS" => ["core/topologyData/CoreNetwork"],	
				"SGSN" => ["core/topologyData/CoreNetwork"],	 	
				"SGSNMME" => ["core/topologyData/CoreNetwork"],
				"RBSG2" => ["utran/topologyData/RBS"],
				"TCU"	=> ["utran/topologyData/RBS" , "lte/topologyData/ERBS", "gsm/topologyData/RADIO", "nr/topologyData/5GRadioNode", "nr/topologyData/vTIF", "5G/topologyData/vPP", "ipran/topologyData/TCUxml"],
				"BBSC" => ["core/topologyData/CoreNetwork"],	 		 	
				"CSCFV"	=> ["core/topologyData/CoreNetwork"],	 		 		 	
				"DSC" => ["core/topologyData/CoreNetwork/dsc"],	
				"MGC" => ["core/topologyData/CoreNetwork/mgc"], 
				"NSDS" => ["core/topologyData/CoreNetwork"],
				"SCEF" => ["core/topologyData/CoreNetwork"],
				"UPG" => ["core/topologyData/CoreNetwork"],	
				"WCG" => ["core/topologyData/CoreNetwork/WCG"],
				"FFAXW"	=> ["utran/topologyData/RBS"],
				"PRBS_RBS" => ["utran/topologyData/RBS"],
				"UTRAN_TOP" => ["utran/topologyData/RBS"], 
				"SC" 	=> ["5GCORE"],		 			 			 		 		 		
				"IPRAN"	=> ["ipran/topologyData/TCUxml"],		 			 	 		 	 	
				"MGW"	=> ["core/topologyData/CELLO"],		 		 		 		 	
				"PRBS_CPP" => ["lte/topologyData/ERBS, utran/topologyData/RBS"],		 	
				"PRBS_ERBS"	=> ["lte/topologyData/ERBS"],
				"FFAX" => ["lte/topologyData/ERBS"],
				"GRAN_TOP" => ["gsm/topologyData/RADIO"],
				"NETOP" => ["gran/topologyData/GranNetwork"],	 			 			 			 	
				"REDB" => ["core/topologyData/CoreNetwork"],	 			 			 			 			 			 	
				"CMN_STS" => ["core/topologyData:AXE", "gran/topologyData:GranNetwork"],	
				"CMN_STS_PC"	=> ["core/topologyData/AXE", "tss/topologyData/AXE"],
				"IMS" => ["core/topologyData/CoreNetwork"],
				"IMSGW_MGW" => 	["core/topologyData/CoreNetwork"],  	
				"IMSGW_SBG_ECIM"	=>	["core/topologyData/CoreNetwork"], 
				"CN_TOP" => ["core/topologyData/CoreNetwork"],
				"IPTNMS_TOP" => [""], 		 	
				"IPTRANSPORT_TOP" => [""],
				"OCC" => [""],				 	
				"SOEM_MBH" => [""],		 			 			 		 	
				"TSS" => [""],	 	
				"TSSAXD" => [""],	 		 	
				"TSS_TGC" => [""],	 	
				"TSS_TOP" => [""],		 	
				"UDM" => [""],	 	
			);
		my @keys = keys %PmGenNodes;
			
			###########################################################	Checking DC Techpack
		my $tpName = $d.$string ;
		if ( $d =~ m/(^DC_\w*)/  && $tpName !~ m/(^DC_E_LLE\w*)/) {	
			
			opendir my $tpDir, $topologyFile or die "Cannot open directory:$topologyFile $!";
			my @tpDirList = readdir $tpDir;
			closedir $tpDir;
			
			if ($string ~~ @tpDirList){
				
				my $storage = $topologyFile.$string.'/';
				opendir my $dirs, $storage."/" or die "Cannot open directory:$topologyFile.$string $!";
				my @dirList = grep { !/^\.\.?$/ } readdir $dirs;
				closedir $dirs;
				my $dirSize = scalar @dirList;
				if ( $dirSize > 0 ) {
					my @dirArray = @{$PmDirList{$string}};
					my $size = scalar @dirArray;
					if ($size == 1) {
						copyFilesFromTopoToServer($topologyFile,$string."/*",$dirArray[0]);
					} 
					if ( $size > 1 ) {
						my @seprateDir;
						for my $dir (@dirArray) {
							my @dirName = split(':', $dir); 
							if( defined $dirName[1]) {
								push(@seprateDir, $dirName[1]);
							}
						}
						for my $dir (@dirArray) {
							my @dirName = split(':', $dir); 
							if( defined $dirName[1]) {
								for my $folder (@dirList) {
									if( $folder ~~ @seprateDir) {
										copyFilesFromTopoToServer($topologyFile,$string."/".$folder."/",$dirName[0]);
									}
								}
							} else {
								for my $folder (@dirList) {
									if ( !($folder ~~ @seprateDir) ) {
										copyFilesFromTopoToServer($topologyFile,$string."/".$folder."/",$dirName[0]);
									}
								}
							}
						}
					}
				} else {
					print "$string directory is not exists under the $topologyFile";
				}
			}
			if ($string ~~ @keys){

				print "From hash : @{$PmGenNodes{$string}}\n";
				@query_array = @{$PmGenNodes{$string}};
				print "From condition : @query_array\n";				
				my ($count1,$j);
				$count1 = @{$PmGenNodes{$string}};
				print "$count1\n";
				
				##################################################### Changing the GenFlag, StartTime and EndTime
				for ($j=0;$j<$count1;$j++){
					my $genflag = $query_array[$j];
					my $flagName = substr($genflag,0, -7);
					print "$j : $genflag\n";
					
					my $pattern = $genflag."=NO";
					my $new_pattern = $genflag."=YES";
					print "Pattern in epfg is $pattern\n";
					
					my $oldStartTime = $flagName."StartTime=";
					my $newStartTime = $flagName."StartTime=".$yesterdayDate."-10:00\n";
					
					my $oldEndTime = $flagName."EndTime=";
					my $newEndTime = $flagName."EndTime=".$yesterdayDate."-11:00\n";
					open EPFGFILE, '<', $epfgpropertiesfile or die "Could not open '$epfgpropertiesfile', No such file found in the provided path $!\n";
					
					my @epfg_lines = <EPFGFILE>;
					close(EPFGFILE);

					my @epfg_newlines;
					foreach(@epfg_lines) {
						$_ =~ s/$pattern/$new_pattern/g;
						if($_ =~ m/(^$oldStartTime)/ ) {
							$_ =~ s/$_/$newStartTime/g;
						}
						if($_ =~ m/(^$oldEndTime)/ ) {
							$_ =~ s/$_/$newEndTime/g;
						}
						push(@epfg_newlines,$_);
					}
					open(EPFGFILE, ">/eniq/home/dcuser/epfg/config/epfg.properties") || die "File not found";
					print EPFGFILE @epfg_newlines;
					close(EPFGFILE);
				}
			}
		} 
		
		
		###########################################################	Checking DIM Techpack
		if ( $d =~ m/(^DIM_\w*)/ || $tpName =~ m/(DC_E_LLE\w*)/) {
			
			opendir my $tpDir, $topologyFile or die "Cannot open directory:$topologyFile $!";
			my @tpDirList = readdir $tpDir;
			closedir $tpDir;
			
			if ($string ~~ @tpDirList){
				
				opendir my $dir, $topologyFile.$string or die "Cannot open directory:$topologyFile.$string $!";
				my @files = readdir $dir;
				closedir $dir;
				
				my $subDirpath = '/eniq/data/pmdata/eniq_oss_1/';
				my $sourceDir = $topologyFile.$string.'/';
				if (-d $sourceDir) {
					my $src = $sourceDir."*";
					print "SourcePath : $src \n TargetPath: $subDirpath \n";
					system ("cp -R $src $subDirpath");
				}
			}
		}
	}
}
	
	epfgdataGeneration();