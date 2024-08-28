#!/usr/bin/perl -C0

use strict;
use warnings;
use Text::CSV;
use File::Slurp;
use POSIX qw(strftime);
use MCE::Grep Sereal => 1;
use MCE::Loop;
use MCE::Util;
use Data::Dumper;

MCE::Grep::init {
	chunk_size => '100M', max_workers => MCE::Util::get_ncpu,
	user_begin => sub {
	},
	user_end => sub {
	}
};

MCE::Loop::init {
	chunk_size => 1, max_workers => MCE::Util::get_ncpu,
};                         

my $LOGPATH = "/eniq/home/dcuser/RegressionLogs";
my %hash = ();
my $CUT = "/usr/bin/cut";
my $JAVAP = '/eniq/sw/runtime/jdk/bin/javap';
my $FIND = "/usr/bin/find";
my $SORT = "/usr/bin/sort";
my $UNIQ = "/usr/bin/uniq";
my $WGET = "/usr/sfw/bin/wget";
if ( $^O eq "linux" ) {
	$WGET = "/usr/bin/wget";
}

#######################################################

my $contents = qq{<br><table border="1">
				<tr>
				<th colspan="3"><font size="2" color=Blue><b><u>Contents</u></b></font></th>
				</tr>
				<tr>
				<th>No.</th>
				<th>Test Case</th>
				<th>Result</th>
				</tr>
				};
my $con_index = 0;

##################################################################################
#             The DATETIME value for the FILENAME of the HTML LOGS               #
##################################################################################

my ($sec,$min,$hour,$mday,$mon,$year,$wday,$yday,$isdst) = localtime(time);
$mon++;
$year = 1900 + $year;
my $datenew = sprintf("%4d%02d%02d%02d%02d%02d",$year,$mon,$mday,$hour,$min,$wday);

################################################REWRITE########################################################

#####################################################################
# The subroutine 'getMwsPath' will get the path to the platform and #
# feature modules which are stored in the MWS server for the        #
# current CI run													#
#####################################################################
sub getMwsPath{
	my $mwsPath = '/net/10.45.192.153/JUMP/ENIQ_STATS/ENIQ_STATS/';
	my $plat = "";
	my $feat = "";
	my $path = "";
	open(MWSPROPS, '< /eniq/home/dcuser/mws.properties') or warn("Cannot read mws.properties file!!\n");
	my @mwsFile = <MWSPROPS>;
	chomp(@mwsFile);
	close MWSPROPS;
	
	foreach $path (@mwsFile){
		$_ = $path;
		if(/^Platform=/){
			my @input = split("=",$path);
			$plat = $mwsPath.$input[1];
		}
		if(/^Feature=/){
			my @input = split("=",$path);
			$feat = $mwsPath.$input[1];
		}
	}
	return ($plat,$feat);
}

###################################################################
# getEndTimeHeader_Overall
# this subroutine returns the end time of each overall result page
# in a standard format
sub getEndTimeHeader_Overall{
	my $pass = shift;
	my $fail = shift;
	my $rep .= "<tr>";
	$rep .= qq{<tr>
		<th> <font size = 2 > END TIME </th>
		<td><font size = 2 ><b>};
	my $etime = getTime();
	$rep .= "$etime";
	$rep .= "<tr>";
	$rep .=qq{<tr>
		<th> <font size = 2 > RESULT SUMMARY </th>
		<td><font size = 2 ><b>};
	$rep .= "<a href=\"#t1\">PASS ($pass) / <a href=\"#t2\">FAIL ($fail)";
	$rep .= "</table>";
	$rep .= "<br>";
	return $rep;
}

############################################################
# WRITE HTML
# This is a utility for the log output file in HTML 
sub writeHtml{
	my $server = shift;
	my $out = shift;
	open(OUT," > $LOGPATH/$server.html");
	print OUT $out;
	close(OUT);
	return "$LOGPATH/$server.html\n";
}

###################################################################
# getEndTimeHeader_Log
# this subroutine returns the end time of each overall result page
# in a standard format
sub getEndTimeHeader_Log
{
	my $rep .= "<tr>";
	$rep .= qq{<tr>
		<th> <font size = 2 > END TIME </th>
		<td><font size = 2 ><b>};
	my $etime = getTime();
	$rep .= "$etime";
	$rep .= "<tr>";
	$rep .= "</table>";
	$rep .= "<br>";
	return $rep;
}

sub checkLogs {
	my $result = "";
	my @files = @{$_[0]};
	my @logfilters = undef;
	@logfilters = @{$_[1]};
	my $filterList = join('|',@logfilters);
	open(FH,"<readfile.txt") or die "Couldn't open file file.txt, $!";;
	my $string = do {local $/; <FH> };
	close (FH); 
	my @ignoreLogFilters = split(',',$string);
	my $ignoreList = join('|',@ignoreLogFilters);
	my @errData = undef;
	for my $file (@files){
		next if($file eq "");
		print "\nNew File : $file\n";
		if (@logfilters){
			@errData = mce_grep_f { /$filterList/i && not /$ignoreList/i } $file;
		}
		else {
			@errData = mce_grep_f { not /$ignoreList/i } $file;
			my $cnt1 = $#errData + 1;
			print "Type 2 : $cnt1\n";
		}
		chomp(@errData);
		my $cnt = $#errData + 1;
		print "Matched Lines : $cnt\n";
		if (@errData != 0) {
			$result .= "<h3><b>FILE : $file</b></h3>";
			for my $line (@errData) {
				$_ = $line;
                if(/java.lang.|ASA Error|SEVERE|reactivated/) {
                    $result .= "<font color=660000><b>$line</b></font><br>";
                }   
				else {
                    $result .= "$line<br>";
                }
			}
		}
		print "Done for $file\n";
	}
	return $result; 
}

sub verifyLogs{
	my $result = "";
	my $tp_name = "";
	my $file = '/eniq/home/dcuser/data.txt';
	open my $fh, '<', $file or die "Could not open '$file' $!\n";
	while (my $line = <$fh>) {
		chomp $line;
		if($line  =~ m/(^DC_E_\w*)/) {
			my ($strings,$r,$b) = $line  =~ m/(DC_E_\w*)(\_R.+\_b)(\d+)/;
			foreach ($strings) {
				$tp_name = "$strings";
				print "$tp_name\n";
				my @enginelogFilters=("error","exception","fatal","severe","warning","not found","cannot","not supported","reactivated","failed","fail","skip");
				my @svclogFilters=("error","exception","fatal","severe","warning","not found","cannot","not supported","reactivated","Unknown Source","NoClassDefFoundError","failed"); 
				my @iqmsgLogFilters=("Dump all thread stacks at","Abort","fatal","Error","Please report this to SAP IQ support","^E.","failed");

				my %basedirList;
				if ( $^O ne "linux" ) {
					$basedirList{'/var/svc/log'} = [ @svclogFilters ];
				}
				$basedirList{'/eniq/local_logs/iq'} = [ @iqmsgLogFilters ];
				$basedirList{'/eniq/log/sw_log/tp_installer'} = [ @enginelogFilters ];
				$basedirList{"/eniq/log/sw_log/engine/$tp_name"} = [ @enginelogFilters ];

				my @filters;
				my @fileList;
				for my $dirPath (keys %basedirList) {
					if ( $dirPath eq '/eniq/local_logs/iq' ) {
						@fileList = glob "$dirPath/*.*";
					}
					else {
						@fileList = glob "$dirPath/*.log";
					}
					
					if($dirPath eq "/eniq/log/sw_log/engine/$tp_name"){
						my $val = @fileList;
						@fileList = sort(@fileList);
						@fileList = (@fileList[$val-1]);
					}
					elsif($dirPath eq "/eniq/log/sw_log/tp_installer"){
						@fileList = grep /$line/, @fileList;
					}
					else{
						@fileList = grep { -M $_ < 1 } @fileList;
					}
					
					chomp(@fileList);
					print "File List : @fileList\n";
					if (exists $basedirList{$dirPath}) {
						@filters = @{$basedirList{$dirPath}};
						$result .= "<h3><b>PATH : $dirPath</b></h3>";
						print "PATH : $dirPath\n";
						$result .= checkLogs(\@fileList,\@filters);
					}
					my @subDirs = read_dir( $dirPath, prefix => 1 );
					for my $subDir (@subDirs){
						if ( (-d $subDir) && (index($subDir, '.') eq -1) ) {
							$result .= "<h3><b>PATH : $subDir</b></h3>";
							@fileList = glob "$subDir/*.log";
							@fileList = grep { -M $_ < 1 } @fileList;
							chomp(@fileList);
							print "SubDir : $subDir   File List : @fileList\n";
							for my $key (keys %basedirList) {
								if (index($subDir, $key) ne -1) {
									@filters = @{$basedirList{$key}};
									last;
								}
							}
							$result .= checkLogs(\@fileList,\@filters);
						}
						if ( $subDir eq '/eniq/log/sw_log/engine' ) {
							my @sub = read_dir( $subDir, prefix => 1 );
							for my $dir (@sub) {
								if ( (-d $dir) && (index($dir, '.') eq -1) ) {
									$result .= "<h3><b>PATH : $dir</b></h3>";
									@fileList = glob "$dir/*.log";
									@fileList = grep { -M $_ < 1 } @fileList;
									chomp(@fileList);
									print "SubDir : $dir   File List : @fileList\n";
									for my $key (keys %basedirList) {
										if (index($dir, $key) ne -1) {
											@filters = @{$basedirList{$key}};
											last;
										}
									}
									$result .= checkLogs(\@fileList,\@filters);
								}
							}
						}
					}
					$result .= "<br>\n";
				}
			}
		}
	}
	return $result; 
}

############################################################
# GET HTML TAIL
# This is a utility for the log output file in HTML 
sub getHtmlTail{
	return qq{
		</table>
		<br>
		</body>
		</html>
		};
}

############################################################
# getEndTimeHeader
# this subroutine returns the end time of each test case
# in a standard format
sub getEndTimeHeader{
	my $pass = shift;
	my $fail = shift;
	my $rep .= "<tr>";
	$rep .= qq{<tr>
		<th> <font size = 2 > END TIME </th>
		<td><font size = 2 ><b>};
	my $etime = getTime();
	my $server = getHostName();
	$rep .= "$etime";
	$rep .= "<tr>";
	$rep .=qq{<tr>
		<th> <font size = 2 > RESULT SUMMARY </th>
		<td><font size = 2 ><b>};
	$rep .= "<a href=\"#t1\">PASS ($pass) / <a href=\"#t2\">FAIL ($fail)";
	$rep .= qq{<tr>
		<th> <font size = 2 > DETAILED RESULT </th>
		<td><font size = 2 ><b>};
	$rep .= "<a href=\"$server\_$datenew.html\" target=\"_blank\">Click here</a>";
	$rep .= "</table>";
	$rep .= "<br>";
	$rep .= "<h3><font size=4 color=\"Blue\"><b><u>Note:</u> Only Failed TestCases shown, refer link above for Detailed Results</b></font></h3><br>";
	return $rep;
}

############################################################
# majorVersionCheck
# This subroutine checks the JDK version each class file has
# been compiled with
sub majorVersionCheck{
	my $target_file = '/eniq/home/dcuser/list_of_classes';
	my $find_cmd1 = `$FIND /eniq/sw/platform/ -name "*\.class" > $target_file`;
	my $find_cmd2 = `$FIND /eniq/sw/runtime/ -name "*.class" | grep -v "apache-tomcat-7.0.53"  >> $target_file`;
	my ($value,$majorversion,@failures) = 0;
	my ($data,$data_ex,$data_fail) = 0;
		
	open(INPUT,"< $target_file");
	my @input = <INPUT>;
	chomp(@input);
	close(INPUT);

	my $result = "";
 	$result	.=	qq{
		<br><table  BORDER="1" CELLSPACING="0" CELLPADDING="0" WIDTH="50%" >
		<tr>
		<th>CLASS FILES </th>
		<th>JDK USED</th>
		<th>RESULT</th>
		</tr>
		};
	my $result_fail = $result;
	foreach $value(@input){
		if ($value =~ /((.+)\/(.+))\.class/) {
			$majorversion = `$JAVAP -verbose -classpath $2 '$3' 2>/dev/null | grep "major"`;
			$data = $1;
			$data_ex = $data;
			if ( $majorversion !~ /52/ ){
				$result_fail .= "<tr> <td align=center><b>$data<\/b><\/font> <\/td> <td align=center>$majorversion<\/td> <td align=center><font color=660000><b>FAIL<\/b><\/font><\/td><\/tr> ";
				$result .= "<tr> <td align=center><b>$data<\/b><\/font> <\/td> <td align=center>$majorversion<\/td> <td align=center><font color=660000><b>_FAIL_<\/b><\/font><\/td><\/tr> ";
			}
			else{
				$result.= "<tr> <td align=center><b>$data<\/b><\/font> <\/td> <td align=center><b>JDK 8<\/b><\/td> <td align=center><font color=006600><b>_PASS_<\/b><\/font><\/td><\/tr>";
			}
		}
	}
	
	$result_fail .= "</table>\n";
	$result .= "</table>\n";
	return ($result , $result_fail);
}

##############################
#GET Active Interfaces
sub getActiveInterfaces{
	my @intfList1 =  @{$_[0]};
	my @intf;
	for my $intf1 (@intfList1){
		my ($strings,$r,$b) = $intf1  =~ m/(INTF_\w*)(\_R.+\_b)(\d+)/;
		if( defined $strings) {
			open(INTF,"su - dcuser -c /eniq/sw/installer/get_active_interfaces | $CUT -d\" \" -f 2 | $SORT | $UNIQ | grep $strings |" );
			my @intfs = <INTF>;
			chomp(@intfs);
			foreach (@intfs){
				push(@intf , $1);
			}
		}
		close(INTF);
	}
	return @intf;
}

################################
#GET BASE LINE INTERFACES
# This subroutine is a utility
# is in charge of getting a list of interfaces from the installation path
sub getINTFs{
	my $path = $_[0];
	my @intfList1 =  @{$_[1]};
	$_ = $path;
	$path =~ s/\s//;
	my @blintff;
	for my $intf (@intfList1){
		if ( defined $intf) {
			open(BLINTF,"cd $path/eniq_techpacks;ls | grep $intf|");
			my @blintf = <BLINTF>;
			chomp(@blintf);
			close(BLINTF);
			foreach (@blintf){
				if(/(.*)_R/){
					push(@blintff , $1);
				}
			}
		}
	}
	return @blintff;
}

############################################################################
#This subroutine compares baseline interfaces 
#with the one in get_active_interfaces
sub compareBaselineInterfaces{
	my $path = $_[0];
	my @intfList =  @{$_[1]};
	my @bi1 = getINTFs($path, \@intfList);
	my @bi= remSpace(\@bi1);
	my @interfaces1 = getActiveInterfaces(\@intfList);
	my @interfaces = remSpace(\@interfaces1);
	my %modres = compareBase(\@bi,\@interfaces);
	my $res = "";
	my $fail="";
	for my $intf (@intfList) {
		my ($strings,$r,$b) = $intf  =~ m/(INTF_\w*)(\_R.+\_b)(\d+)/;
		if ( !($strings ~~ @bi && $strings ~~ @interfaces) ) {
			$res .= "<tr><td>$strings</td><td> NOT FOUND IN BASELINE, NOT INSTALLED</td><td align=center><font color=660000><b>_FAIL_</b></font></td></tr>\n";
			$fail .= "<tr><td>$strings</td><td> NOT FOUND IN BASELINE, NOT INSTALLED</td><td align=center><font color=660000><b>FAIL</b></font></td></tr>\n";
		}
	}
	my $result .= qq{
		<h3>Compared with: $path</h3>
		<table align="center" BORDER="1" CELLSPACING="0" CELLPADDING="0" WIDTH="50%" >
		<tr>
		<th>INTERFACE</th>
		<th>DESCRIPTION</th>
		<th>STATUS</th>
		</tr>
		};
	my $result_fail .= $result;
	foreach my $interface(sort keys %modres){
		$_ = $interface;
		next if(/^$/);
		if($modres{$interface} == 3){
			my $string = sprintf("%-35s FOUND IN BASELINE, NOT INSTALLED: FAIL\n",$interface);
			$result .= "<tr><td>$interface</td><td>FOUND IN BASELINE, NOT INSTALLED</td><td align=center> <font color=660000><b>_FAIL_</b></font></td></tr>\n";
			$result_fail .= "<tr><td>$interface</td><td>FOUND IN BASELINE, NOT INSTALLED</td><td align=center> <font color=660000><b>FAIL</b></font></td></tr>\n";
		}
		if($modres{$interface} == 7){
			my $string = sprintf("%-35s FOUND INSTALLED, NOT IN BASELINE: FAIL\n",$interface);
			$result .= "<tr><td>$interface</td><td>FOUND INSTALLED, NOT IN BASELINE</td><td align=center><font color=660000><b>_FAIL_</b></font></td> </tr>\n";
			$result_fail .= "<tr><td>$interface</td><td>FOUND INSTALLED, NOT IN BASELINE</td><td align=center><font color=660000><b>FAIL</b></font></td> </tr>\n";
		}
		if($modres{$interface} == 10){
			my $string = sprintf("%-35s FOUND IN BASELINE, INSTALLED: PASS\n",$interface);
			$result .= "<tr><td>$interface</td><td>FOUND IN BASELINE, INSTALLED</td><td align=center><font color=006600><b>_PASS_</b></font></td></tr>\n";
		}
	}
	$result .= $res;
	$result_fail .= $fail;
	$result .= "</table> <br>\n";
	$result_fail .= "</table> <br>\n";
	return $result,$result_fail;
}

############################################################
# UTILITY TO EXECUTE ANY COMMAND AND GET RESULT IN ARRAY
sub executeThis{
	my $command = shift;
	my @res = `$command`; 
	return @res;
}

###############################
# GET INSTALLED TECHPACKS
# This subroutine is a utility
# is in charge of getting the installed techpacks from AdminUI (Monitoring Commands)
sub getInstalledTechpacks{
	my @tplist1 = @{$_[0]};
	system("$WGET --quiet  --no-check-certificate -O /dev/null  --keep-session-cookies --save-cookies /eniq/home/dcuser/cookies.txt --post-data \"action=/servlet/CommandLine&command=Installed+tech+packs&submit=Start\" \"https://localhost:8443/adminui/servlet/CommandLine\"");
	# SEND USR AND PASSWORD
	system("$WGET --quiet --no-check-certificate -O /dev/null --keep-session-cookies --load-cookies /eniq/home/dcuser/cookies.txt --save-cookies /eniq/home/dcuser/cookies2.txt --post-data 'action=j_security_check&j_username=eniq&j_password=eniq' https://localhost:8443/adminui/j_security_check");
	# post Information
	system("$WGET --quiet --no-check-certificate -O /eniq/home/dcuser/tps.html --keep-session-cookies --load-cookies /eniq/home/dcuser/cookies2.txt --post-data \"action=/servlet/CommandLine&command=Installed+tech+packs&submit=Start\" \"https://localhost:8443/adminui/servlet/CommandLine\"");
	
	my @status = executeThis("egrep '(Not active Tech Packs|					<tr>|						<td class=.basic.>)'  /eniq/home/dcuser/tps.html");
	chomp(@status);
	
	my @result = ();
	my $finalresult = 0;
	my $line = "";
	
	for my $tp (@tplist1){
		my ($strings,$b) = $tp  =~  m/(\w*)\.tpi/;
		if ( defined $strings) {
			foreach my $status (@status){
				$_ = $status;
				$status =~ s/                                                <td class=.basic.>//;
				$status =~ s/<.td>//;
				$status =~ s/\s//;
				$status =~ s/.*">//;
				if(/<tr>|Not active Tech Packs/){
					if ($strings ~~ $line) {
						push @result, $line;
					}
					$line = "";
				}
				last if(/Not active Tech Packs/);
				if(/.._._.*|AlarmInterfaces|\w_\w|R.*_\w/i){
					if ($line eq ""){
						$line = $status;
					}
					else{
						$line .= "_$status";
					}
				}
			} 
		}
	}
	#LOGOUT 
	system("$WGET --no-check-certificate -O /dev/null --quiet --cache=on --save-headers --server-response --keep-session-cookies --load-cookies /eniq/home/dcuser/cookies2.txt https://localhost:8443/adminui/servlet/Logout  ");
	return @result;
}

###############################
# GET BASE LINE TECH PACKS
# This subroutine is a utility
# is in charge of getting a list of techpacks from the installation path
sub getBLTPs{
	my $path = $_[0];
	my @tplist2 = @{$_[1]};
	$_ = $path;
	$path =~ s/\s//;
	my @bltp ="";
	for my $tp (@tplist2){
		my ($strings,$b) = $tp  =~  m/(\w*)\.tpi/ ;
		open(BLTP,"cd $path/eniq_techpacks; ls *.tpi | awk -F. '{print \$0}' | grep -v INTF | sed 's/.tpi//' | grep $strings |");
		my @bltp1 = <BLTP>;
		chomp(@bltp1);
		for my $b1 (@bltp1){
			push @bltp, $b1 ;
		}
		close(BLTP);
	}
	return @bltp;
}

############################################################################
# COMPARE BASELINE
# This subroutine is in charge or comparing 
# the installation path techpacks and the techpacks displayed in adminUI
# if equal then PASS, else FAIL
sub compareBaselineTechpacks{
	my $path = $_[0];
	my @tplist1 =  @{$_[1]};
	my $len = scalar @tplist1;
	my @bt1 = getBLTPs($path, \@tplist1);
	my @bt = remSpace(\@bt1);
	@bt1 = remSpace(\@bt);
	my @tps = getInstalledTechpacks(\@tplist1);
	my %modres = compareBase(\@bt,\@tps);
	my $res = "";
	my $fail="";
	for my $tp (@tplist1) {
		my ($strings,$b) = $tp  =~  m/(\w*)\.tpi/ ;
		if ( !($strings ~~ @bt && $strings ~~ @tps) ) {
			$res .= "<tr><td>$strings</td><td> NOT FOUND IN BASELINE, NOT INSTALLED</td><td align=center><font color=660000><b>_FAIL_</b></font></td></tr>\n";
			$fail .= "<tr><td>$strings</td><td> NOT FOUND IN BASELINE, NOT INSTALLED</td><td align=center><font color=660000><b>FAIL</b></font></td></tr>\n";
		}
	}
	my $result .= qq{
		<h3>Compared with: $path</h3>
		<table align="center" BORDER="1" CELLSPACING="0" CELLPADDING="0" WIDTH="50%" >
		<tr>
		<th>TECHPACK STATUS</th>
		<th>DESCRIPTION</th>
		<th>STATUS</th>
		</tr>
		};
	my $result_fail .= $result;
	foreach my $module (sort keys %modres){
		$_ = $module;
		next if(/^$/);
		if($modres{$module} == 3){
			my $string = sprintf("%-35s FOUND IN BASELINE, NOT INSTALLED: FAIL\n",$module);
			$result .= "<tr><td>$module</td><td> FOUND IN BASELINE, NOT INSTALLED</td><td align=center><font color=660000><b>_FAIL_</b></font></td></tr>\n";
			$result_fail .= "<tr><td>$module</td><td> FOUND IN BASELINE, NOT INSTALLED</td><td align=center><font color=660000><b>FAIL</b></font></td></tr>\n";
		}
		if($modres{$module} == 7){
			my $string = sprintf("%-35s FOUND INSTALLED, NOT IN BASELINE: FAIL\n",$module);
			$result .= "<tr><td>$module</td><td>FOUND INSTALLED, NOT IN BASELINE</td><td align=center><font color=660000><b>_FAIL_</b></font></td></tr>\n";
			$result_fail .= "<tr><td>$module</td><td>FOUND INSTALLED, NOT IN BASELINE</td><td align=center><font color=660000><b>FAIL</b></font></td></tr>\n";
		}
		if($modres{$module} == 10){
			my $string = sprintf("%-35s FOUND IN BASELINE, INSTALLED: PASS\n",$module);
			$result .= "<tr><td>$module</td><td>FOUND IN BASELINE, INSTALLED</td><td align=center><font color=006600><b>_PASS_</b></font></td></tr>\n";
		}
	}
	$result .=$res;
	$result_fail .= $fail;
	$result .= "</table> <br>\n";
	$result_fail .= "</table> <br>\n";
	return $result,$result_fail;
}

###################################################3
# COMPARE BASE AND INSTALLED MODULES OR TECHPACKS OR INTERFACE
# This subroutine is a utility
# is in charge of comparing a couple of arrays
# if the arrays contain equal values, then they are inserted in a
# hash, if equal the value is updated to 10
# if different then the value remains 3
sub compareBase{
	my ($ref_1,$ref_2) = @_;
	my @baseline = @{$ref_1};
	my @installed = @{$ref_2};
	my %result = ();
 
	foreach my $baseline (@baseline){
		if(defined $baseline) {
			if ($baseline =~m/^afj|^helpset/){
			$_ = $baseline;
			$_ =~s/[_]/-/;
			$baseline = $_;
			}
			$result{$baseline} = 3;
		}
	}
	foreach my $installed (@installed){
		if(defined $installed) {
		
			if( $installed =~m/^afj|^helpset/){
			$_ = $installed;
			$_ =~s/[_]/-/;
			$installed = $_;
			}
			$result{$installed} += 7;
		}
	}
	return %result; 
}

###############################
# GET INSTALLED MODULES
# This subroutine is a utility
# is in charge of getting the installed modules using
# grep module /eniq/sw/installer/versiondb.properties | sed 's/module.//'  | sed 's/=/-/'
sub getInstalledModules{
	open(MODULES,"grep module /eniq/sw/installer/versiondb.properties | sed 's/module.//'  | sed 's/=/-/' | sed 's/-/_/' |");
	my @modules = <MODULES>;
	close(MODULES);
	chomp(@modules);
	return @modules;
}

###############################
# This subroutine is a utility
# Removes Space
sub remSpace{
	my ($ref_1,$ref_2) = @_;
	my @arr = @{$ref_1};
	my @res = undef;
	foreach my $arr (@arr){
		if (defined $arr){
			$arr =~ s/\s+//;
			push @res, $arr;
		}
	}
	return @res;
}

###############################
# GET BASE LINE MODULES
# This subroutine is a utility
# is in charge of getting a list of modules from the input path
sub getBLmodules{
	my $path = shift;
	$_ = $path;
	$path =~ s/\s//;
	open(BSLN,"cd $path;ls *.zip  | grep -v eniq_config_R2B01.zip|");
	my @bsln = <BSLN>;
	chomp(@bsln);
	close(BSLN);
	my @result = undef;
	foreach my $bsln (@bsln){
		$_ = $bsln;
		$bsln =~ s/.zip//;
		#$bsln =~ s/_/-/;
		push @result, $bsln;
	}
	return @result;
}

############################################################################
# This subroutine is in charge of comparing the installation path modules 
# and the modules installed in the server if equal then PASS, else FAIL.
sub compareBaselineModules 
{
	my $PFpath = shift;
	my $Parserpath = shift;
	$PFpath = $PFpath."/eniq_base_sw/eniq_sw";
	$Parserpath = $Parserpath."/eniq_parsers/";
	my @bl1 = getBLmodules($PFpath);
	my @bl2 = getBLmodules($Parserpath);
	my @bl3 = (@bl1,@bl2);
	my @bl = remSpace(\@bl3);
	my @modules1 = getInstalledModules();
	my @modules = remSpace(\@modules1);
	my %modres = compareBase(\@bl,\@modules);
	my $result .= qq{
		<h3>Compared with: $PFpath </h3>
		<table  align="center" BORDER="1" CELLSPACING="0" CELLPADDING="0" WIDTH="50%" >
		<tr>
		<th>MODULE</th>
		<th>DESCRIPTION</th>
		<th>STATUS</th>
		</tr>
		};
	my $result_fail .= $result;
 
	foreach my $module (sort keys %modres){
		$_ = $module;
		next if(/^$/);
		if($modres{$module} == 3){
			my $string = sprintf("%-35s FOUND IN BASELINE, NOT INSTALLED: FAIL\n",$module);
			$result .= "<tr><td>$module</td><td>FOUND IN BASELINE, NOT INSTALLED</td><td align=center> <font color=660000><b>_FAIL_</b></font></td></tr>\n";
			$result_fail .= "<tr><td>$module</td><td>FOUND IN BASELINE, NOT INSTALLED</td><td align=center> <font color=660000><b>FAIL</b></font></td></tr>\n";
		}
		if($modres{$module} == 7){
			my $string = sprintf("%-35s FOUND INSTALLED, NOT IN BASELINE: FAIL\n",$module);
			$result .= "<tr><td>$module</td><td>FOUND INSTALLED, NOT IN BASELINE</td><td align=center><font color=660000><b>_FAIL_</b></font></td> </tr>\n";
			$result_fail .= "<tr><td>$module</td><td>FOUND INSTALLED, NOT IN BASELINE</td><td align=center><font color=660000><b>FAIL</b></font></td> </tr>\n";
		}
		if($modres{$module} == 10){
			my $string = sprintf("%-35s FOUND IN BASELINE, INSTALLED: PASS\n",$module);
			$result .= "<tr><td>$module</td><td>FOUND IN BASELINE, INSTALLED</td><td align=center><font color=006600><b>_PASS_</b></font></td></tr>\n";
		}
	}

	$result .= "</table> <br>\n";
	$result_fail .= "</table> <br>\n";
	return ($result,$result_fail);
}

############################################################
# GET DATE
# This is a utility
sub getDate{
	my ($sec,$min,$hour,$mday,$mon,$year,$wday, $yday,$isdst)=localtime(time);
	return sprintf "%4d%02d%02d%02d%02d%02d", $year+1900,$mon+1,$mday,$hour,$min,$sec;
}

############################################################
# TRIGGER TESTCASES
# This sub-routine will execute each 
# testcase and return result
sub parseParam{
	my $result = "";
	my $DATE = getDate();
	my $baselinePath = "";
	my $featureBaselinePath = "";
	my @tpList = ();
	my @interfaceList = ();
	{
		($baselinePath,$featureBaselinePath) = getMwsPath();
		print "PF Baseline Path - $baselinePath\n";
		print "Feature Baseline Path - $featureBaselinePath\n";
		$con_index++;
		$contents .= qq{<tr>
			<td>$con_index</td>
			<td><a href="#COMPAREBASELINE_$con_index">COMPARE BASELINE</a></td>
			};
		print "*****COMPAREBASELINE VERIFICATION*****\n";
		my $inputfile = '/eniq/home/dcuser/data.txt';
		open FILE, '<', $inputfile or die "Could not open '$inputfile', No such file found in the provided path $!\n";
		my @array = <FILE>;
		chomp @array;
		for my $line (@array) {
			if($line  =~ m/(^DC_\w*|^DIM_\w*)\.tpi/) {
				push @tpList, $line;
			}
			if ($line  =~ m/(^INTF_\w*)\.tpi/) {
				push @interfaceList, $line;
			}
		}

		my $report = getStartTimeHeader("compareBaseline");
		$result.= "<h2><a name=\"COMPAREBASELINE_$con_index\">$DATE COMPAREBASELINE</a></h2><br>\n";
		print "*****Compare Baseline Modules*****\n";
		my ($result1,$result1_fail) = compareBaselineModules($baselinePath,$featureBaselinePath);
		wait;
		my $result2 = "";
		my $result2_fail = "";
		my $result3 = "";
		my $result3_fail = "";
		my $tpLength = scalar @tpList;
		my $intfLength = scalar @interfaceList;
		print "\n@tpList\n";
		if ( $tpLength > 0 ) {
			print "*****Compare Baseline Techpacks*****\n";
			($result2,$result2_fail) = compareBaselineTechpacks($featureBaselinePath, \@tpList);
			wait;
		} 
		print "\n@interfaceList\n";
		if ( $intfLength > 0 ) {
			print "*****Compare Baseline Interfaces*****\n";
			($result3,$result3_fail) = compareBaselineInterfaces($featureBaselinePath, \@interfaceList);
			wait;
		} 
		print "*****Major Version Check*****\n";
		my ($result4,$result4_fail) = majorVersionCheck();
		wait;
		$result .= $result1;
		$result .= $result2;
		$result .= $result3;
		$result .= $result4;
		my $result_count .= $result1;
		$result_count .= $result2;
		$result_count .= $result3;
		$result_count .= $result4;
		my $fail =()= $result_count =~ /_FAIL_+/g;
		my $pass =()= $result_count =~ /_PASS_+/g;
		$contents .= qq{<td><a href=\"#t1\">PASS ($pass) / <a href=\"#t2\">FAIL ($fail)</td>
			</tr>
			};
		my $mod_fail =()= $result1_fail =~ /FAIL+/g;
		my $tp_fail =()= $result2_fail =~ /FAIL+/g;
		my $intf_fail =()= $result3_fail =~ /FAIL+/g;
		my $version_fail =()= $result4_fail =~ /FAIL+/g;
	 
		$report .= getEndTimeHeader($pass,$fail);
		if($fail == 0){
			$report .= "<p><font size=8 color=006600><b>NO FAILED TESTCASES</b></font></p>";
		}
		else{
			if ($mod_fail == 0){
				$report .= "<br><br><p><font size=8 color=006600><b>NO FAILED PLATFORM MODULES PRESENT</b></font></p><br><br>";
			}
			else{
				$report .= $result1_fail;
			}
			if ($tpLength <= 0 ) {
				$report .= "<br><br><p><font size=8 color=006600><b>No Techpacks are delivered</b></font></p><br><br>";
			}
			if ($tp_fail == 0 &&  $tpLength > 0 ){
				$report .= "<br><br><p><font size=8 color=006600><b>NO FAILED TECHPACKS PRESENT</b></font></p><br><br>";
			}
			else{
				$report .= $result2_fail;
			}
			if ($intfLength <= 0 ) {
				$report .= "<br><br><p><font size=8 color=006600><b>No Interfaces are delivered</b></font></p><br><br>";
			}
			if ($intf_fail == 0 && $intfLength > 0 ){
				$report .= "<br><br><p><font size=8 color=006600><b>NO FAILED INTERFACES PRESENT</b></font></p><br><br>";
			}
			else{
				$report .= $result3_fail;
			}
			if ($version_fail == 0){
				$report .= "<br><br><p><font size=3 color=006600><b>ALL CLASSES ARE WITH JDK1.8 IMPLEMENTATION</b></font></p><br><br>";
			}
			else{
				$report .= $result4_fail;
			}
		}
		$report .= getHtmlTail();
		my $file = writeHtml("COMPAREBASELINE_VERIFICATION",$report);
		print "PARTIAL FILE: $file\n";
	}
	{
		$con_index++;
		$contents .=	qq{<tr>
			<td>$con_index</td>
			<td><a href="#READLOG_$con_index">LOG VERIFICATION</a></td>
			};
		my $report = getStartTimeHeader("verifyLogs");
		$result .= "<h2><font color=Black><a name=\"READLOG_$con_index\">$DATE LOG VERIFICATION</a></font></h2><br>";
		print $DATE;
		print " LOG VERIFICATION\n";
		my $result1 .= verifyLogs();
		$result .= $result1;
		$contents .= qq{<td><a href="#READLOG_$con_index">Verify Logs</a></td>
			</tr>
			};
		$report .= getEndTimeHeader_Log();
		$report .= $result1;
		$report.= getHtmlTail(); 
		my $file = writeHtml("Log_Verification",$report);
		print "PARTIAL FILE: $file\n";
		MCE::Grep::finish;
	}
	$contents .= "</table><br>";
	return $result;
}

############################################################
# VERIFY THE INSTALLED VERSION
# This is a utility to get the version from the eniq_status file
sub verifyVersion{
	my $version = "";
	open(VER,"cat /eniq/admin/version/eniq_status |");
	my @version = <VER>;
	close(VER);
	foreach my $ver (@version){
		$version .= $ver;
	}
	return $version;
}

############################################################
# GET HOST NAME
# This is a utility to get the host name
sub getHostName{
	open(HOST,"hostname |");
	my @host = <HOST>;
	chomp(@host);
	close(HOST);
	return $host[0];
}

############################################################
# GET TIMESTAMP
# This is a utility 
sub getTime{
	my ($sec,$min,$hour,$mday,$mon,$year,$wday, $yday,$isdst) = localtime(time);
	return sprintf "%4d-%02d-%02d %02d:%02d:%02d\n", $year+1900,$mon+1,$mday,$hour,$min,$sec;
}

############################################################
# GET THE HTML HEADER
# This is a utility for the log output file in HTML 
sub getHtmlHeader{
	my $testCase = shift;
	if ($testCase eq ""){
		return qq{<!DOCTYPE HTML PUBLIC "-//W3C//DTD HTML 4.01 Transitional//EN">
			<html>
			<head>
			<title>
			ENIQ Regression Feature Test
			</title>
			<STYLE TYPE="text/css">
			<!--
			h3{font-family:tahoma;font-size:12px}
			body,td,tr,p,h{font-family:tahoma;font-size:11px}
			.pre{font-family:Courier;font-size:9px;color:#000
			}
			.h{font-size:9px}
			.td{font-size:9px}
			.tr{font-size:9px}
			.h{color:#3366cc
			}
			.q{color:#00c
			}
			table{
			border:0;
			cellspacing:0;
			cellpadding:0;
			}
			-->
			</STYLE>
			</head>
			<body>
			};
	}
	else{
		return qq{<!DOCTYPE HTML PUBLIC "-//W3C//DTD HTML 4.01 Transitional//EN">
			<html>
			<head>
			<title>
			$testCase
			</title>
			<STYLE TYPE="text/css">
			<!--
			h3{font-family:tahoma;font-size:12px}
			body,td,tr,p,h{font-family:tahoma;font-size:11px}
			.pre{font-family:Courier;font-size:9px;color:#000
			}
			.h{font-size:9px}
			.td{font-size:9px}
			.tr{font-size:9px}
			.h{color:#3366cc
			}
			.q{color:#00c
			}
			table{
			border:0;
			cellspacing:0;
			cellpadding:0;
			}
			-->
			</STYLE>
			</head>
			<body>
			};
	}
}

#############################################################
# getStartTimeHeader
# this subroutine returns the start time of each test case
# in a standard format
sub getStartTimeHeader
{
	my $testCase = shift;
	my %testCaseHeading = (
		"verifyLogs","Log Verification",
		"OVERALL","ENIQ Regression Feature Test",
		"compareBaseline","COMPAREBASELINE VERIFICATION",
		);
	my $testCaseHead = $testCaseHeading{$testCase};
	my $rep .= getHtmlHeader($testCaseHead);
	$rep .= "<h1> <font color=MidnightBlue><center> <u> $testCaseHead </u> </font> </h1>";
	$rep .= qq{<body bgcolor=GhostWhite> </body> <center> <table  BORDER="3" CELLSPACING="2" CELLPADDING="3" WIDTH="50%" >
					<tr>
					<th> <font size = 2 >START TIME </th>
					<td> <font size = 2 > <b>};
	my $stime = getTime();
	$rep .= "$stime";
	return $rep;
}

#####################################################################################
sub getdatetime{
	my $yesterdaysTime = strftime "%Y%m%d-%H:%M:%S",localtime(time() - 24*60*60);
	my $hour = `echo $yesterdaysTime -s| $CUT -c 10,11`;
	chomp($hour);
	my $day = `echo $yesterdaysTime -s| $CUT -c 7,8`;
	chomp($day);
	my $month = `echo $yesterdaysTime -s| $CUT -c 5,6`;
	chomp($month);
	my $year = `echo $yesterdaysTime -s| $CUT -c 1-4`;
	chomp($year);
	return sprintf "%02d-%02d-%4d",$day,$month,$year;
}

############################################################
# MAIN
# This is a simple main that starts the generation of the HTML log file and 
# calls the parseParam subroutine that controls the execution of the script
# Then when all tests are finished writes the log HTML file in the same directory 
# where this script is executed
{
	my $contents = "";
	my $d = getdatetime();

	mkdir("$LOGPATH");
	my $report = getStartTimeHeader("OVERALL");
	$report .= qq{<tr>
		<th> <font size = 2 > HOST </th>
		<td><font size = 2 ><b>};
	my $host = getHostName();
	$report .= "$host";
	$report .= "<tr>";
	$report.= qq{<tr>
		<th> <font size = 2 > VERSION </th>
		<td><font size = 2 ><b>};
  	my $version = verifyVersion();  #."</h2>";
	$report .= "$version";
	$report .= "<tr>";
  	my $tot_report .= parseParam();
	my $fail =()= $tot_report =~ /_FAIL_+/g;
	my $pass =()= $tot_report =~ /_PASS_+/g;
	$tot_report =~s/_PASS_/PASS/g;
	$tot_report =~s/_FAIL_/FAIL/g;
	$report.= getEndTimeHeader_Overall($pass,$fail);
	$report .= $contents;
	$report.= $tot_report;
  	$report.= getHtmlTail(); 
  	my $file = writeHtml($host,$report);

	print "\n-------------------------------------END-------------------------------------------------------\n";
}

###############################################################################################################################################################

