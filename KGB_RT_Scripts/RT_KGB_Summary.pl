#!/usr/bin/perl

use strict;
use warnings;
no warnings 'uninitialized';

use DBI;
use Data::Dumper;
use Text::CSV;
use POSIX qw(strftime);

my $kgbsummary = "true";
my $result;
my $report="";
my $num = 0;
my $num1 = 0;
my $LOGPATH="/eniq/home/dcuser/RegressionLogs";
my $RESULTPATH="/eniq/home/dcuser/ResultFiles";


# open( my $read_first_line, "datetime.txt");
# my $firstline = <$read_first_line>;
# my $current_datetime = $firstline;

# my $datetime =$current_datetime;
# $datetime=trim($datetime);
# print "DATE AND TIME OF THE KGB RUN  :  $datetime" ;

# sub trim
# {
    # my $str = $_[0];
    # $str=~s/^\s+|\s+$//g;
    # return $str;
# }

##################################################################################
#             The DATETIME value for the FILENAME of the HTML LOGS               #
##################################################################################

my ($sec,$min,$hour,$mday,$mon,$year,$wday,$yday,$isdst) =localtime(time);
  $mon++;
  $year=1900+$year;
my $datenew =sprintf("%4d%02d%02d%02d%02d%02d",$year,$mon,$mday,$hour,$min,$wday);

############################################################
# GET TIMESTAMP
# This is a utility 
sub getTime{
  my ($sec,$min,$hour,$mday,$mon,$year,$wday, $yday,$isdst)=localtime(time);
  return sprintf "%4d-%02d-%02d %02d:%02d:%02d\n", $year+1900,$mon+1,$mday,$hour,$min,$sec;
}

############################################################
# GET THE HTML HEADER
# This is a utility for the log output file in HTML 
sub getHtmlHeader{
my $testCase = shift;
if ($testCase eq "")
{
return qq{<!DOCTYPE HTML PUBLIC "-//W3C//DTD HTML 4.01 Transitional//EN">
<html>
<head>
<title>
ENIQ Regression Feature Test
</title>
<STYLE TYPE="text/css">
h3{font-family:tahoma;font-size:12px}
body,td,tr,p,h{font-family:tahoma;font-size:11px}
.pre{font-family:Courier;font-size:9px;color:#000}
.h{font-size:9px}
.td{font-size:9px}
.tr{font-size:9px}
.h{color:#3366cc}
.q{color:#00c}

</STYLE>
</head>
<body>
};
}
else
{
return qq{<!DOCTYPE HTML PUBLIC "-//W3C//DTD HTML 4.01 Transitional//EN">
<html>
<head>
<title>
$testCase
</title>
<STYLE TYPE="text/css">
h3{font-family:tahoma;font-size:12px}
body,td,tr,p,h{font-family:tahoma;font-size:11px}
.pre{font-family:Courier;font-size:9px;color:#000}
.h{font-size:9px}
.td{font-size:9px}
.tr{font-size:9px}
.h{color:#3366cc}
.q{color:#00c}

</STYLE>
</head>
<body>
};
}
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
# WRITE HTML
# This is a utility for the log output file in HTML 

sub writeHtml{
my $testcase = shift;
my $out    = shift;
my $filename = "$LOGPATH/$testcase.html";
open(my $fhandle, ">", $filename) or die "Couldn't open: $!";
print $fhandle $out;
close $fhandle;
return $filename;
}

############################################################
# READ Result
# This is a utility for result file for summary page
my %statusMap;
my %bhMap;
my %counterMap;
my %dataMap;
my %encryptMap;
my %interfaceMap;
my %universeMap;
my %topologyMap;
sub writeResult{
	opendir(Dir, $RESULTPATH) or die "cannot open directory $RESULTPATH";
	my @docs = grep(/\.txt$/,readdir(Dir));
	foreach my $files (@docs) {
		my $file = "$RESULTPATH/$files";
		if(index($file, "Aggregation_Status.txt") != -1) {
			open FILE, '<', $file or die "Could not open '$file', No such file found in the provided path $!\n";
			my @tparray = <FILE>;
			my $tpcount = @tparray;
			my $fragment;
			my $fragment1;
			for( my $i = 0; $i < $tpcount; $i = $i + 1 ) {
				my $tpName = $tparray[$i];
				$fragment =  substr $tpName, 0, index($tpName, '=');
				$fragment1 =  substr ($tpName, index($tpName, '=')+1);
				$statusMap{$fragment} = $fragment1;
			}	
			close FILE;
		} elsif(index($file, "Busy_Hour.txt") != -1) {
			open FILE, '<', $file or die "Could not open '$file', No such file found in the provided path $!\n";
			my @bhtparray = <FILE>;
			my $tpcount1 = @bhtparray;
			my $bhfragment;
			my $bhfragment1;
			for( my $i = 0; $i < $tpcount1; $i = $i + 1 ) {
				my $tpName = $bhtparray[$i];
				$bhfragment =  substr $tpName, 0, index($tpName, '=');
				$bhfragment1 =  substr ($tpName, index($tpName, '=')+1);
				$bhMap{$bhfragment} = $bhfragment1;
			}	
			close FILE;
		} elsif(index($file, "TABLE_DATA_LOADING_CHECK.txt") != -1) {
			open FILE, '<', $file or die "Could not open '$file', No such file found in the provided path $!\n";
			my @dataarray = <FILE>;
			my $tpcount2 = @dataarray;
			my $datafragment;
			my $datafragment1;
			for( my $i = 0; $i < $tpcount2; $i = $i + 1 ) {
				my $tpName = $dataarray[$i];
				$datafragment =  substr $tpName, 0, index($tpName, '=');
				$datafragment1 =  substr ($tpName, index($tpName, '=')+1);
				$dataMap{$datafragment} = $datafragment1;
			}	
			close FILE;
		} elsif(index($file, "COUNTER_DATA_VALIDATION.txt") != -1) {
			open FILE, '<', $file or die "Could not open '$file', No such file found in the provided path $!\n";
			my @counterarray = <FILE>;
			my $tpcount3 = @counterarray;
			my $countfragment;
			my $countfragment1;
			for( my $i = 0; $i < $tpcount3; $i = $i + 1 ) {
				my $tpName = $counterarray[$i];
				$countfragment =  substr $tpName, 0, index($tpName, '=');
				$countfragment1 =  substr ($tpName, index($tpName, '=')+1);
				$counterMap{$countfragment} = $countfragment1;
			}	
			close FILE;
		} elsif(index($file, "Encryption.txt") != -1) {
			open FILE, '<', $file or die "Could not open '$file', No such file found in the provided path $!\n";
			my @encryptarray = <FILE>;
			my $tpcount4 = @encryptarray;
			my $encryptfragment;
			my $encryptfragment1;
			for( my $i = 0; $i < $tpcount4; $i = $i + 1 ) {
				my $tpName = $encryptarray[$i];
				$encryptfragment =  substr $tpName, 0, index($tpName, '=');
				$encryptfragment1 =  substr ($tpName, index($tpName, '=')+1);
				$encryptMap{$encryptfragment} = $encryptfragment1;
			}	
			close FILE;
		} elsif(index($file, "InterfaceDirectory_Check.txt") != -1) {
			open FILE, '<', $file or die "Could not open '$file', No such file found in the provided path $!\n";
			my @interfacearray = <FILE>;
			my $tpcount5 = @interfacearray;
			my $interfacefragment;
			my $interfacefragment1;
			for( my $i = 0; $i < $tpcount5; $i = $i + 1 ) {
				my $tpName = $interfacearray[$i];
				$interfacefragment =  substr $tpName, 0, index($tpName, '=');
				$interfacefragment1 =  substr ($tpName, index($tpName, '=')+1);
				$interfaceMap{$interfacefragment} = $interfacefragment1;
			}	
			close FILE;
		} elsif(index($file, "UNIVERSE_CHECK.txt") != -1) {
			open FILE, '<', $file or die "Could not open '$file', No such file found in the provided path $!\n";
			my @universearray = <FILE>;
			my $tpcount6 = @universearray;
			my $universefragment;
			my $universefragment1;
			for( my $i = 0; $i < $tpcount6; $i = $i + 1 ) {
				my $tpName = $universearray[$i];
				$universefragment =  substr $tpName, 0, index($tpName, '=');
				$universefragment1 =  substr ($tpName, index($tpName, '=')+1);
				$universeMap{$universefragment} = $universefragment1;
			}	
			close FILE;
		} elsif(index($file, "TOPOLOGY_DATA_LOADING.txt") != -1) {
			open FILE, '<', $file or die "Could not open '$file', No such file found in the provided path $!\n";
			my @topologyarray = <FILE>;
			my $tpcount7 = @topologyarray;
			my $topologyfragment;
			my $topologyfragment1;
			for( my $i = 0; $i < $tpcount7; $i = $i + 1 ) {
				my $tpName = $topologyarray[$i];
				$topologyfragment =  substr $tpName, 0, index($tpName, '=');
				$topologyfragment1 =  substr ($tpName, index($tpName, '=')+1);
				$topologyMap{$topologyfragment} = $topologyfragment1;
			}	
			close FILE;
		}
	}
}

# my $location1 = "/eniq/home/dcuser/ResultFiles";
# my $res1;
# sub writeAllResult{	
 # opendir(Dir, $location1) or die "Failed to load files!";
 # my @reports = grep(/\.txt$/,readdir(Dir));
 # foreach my $reports(@reports)
 # {
 # my $files = "$location1/$reports";
 # open ($res1,$files) or die "could not open $files";
 # print "$files\n";
 # }
# }	

# use File::Find::Rule;
# sub writeWholeResult {
# my @files = File::Find::Rule->file()
                            # ->name( '*.txt' )
                            # ->in( '/eniq/home/dcuser/' );
# for my $file (@files) {
    # print "file: $file\n";
# }
# }
	
############################################################
# ExecuteSQL
# This will give the resultset data for the queries passed

sub executeSQL{

	my $dbname = $_[0];
	my $port = $_[1];
	my $cre = $_[2];
	my $arg = $_[3];
	my $type = $_[4];
	#print "executeSQL : $arg  $type $cre $port $dbname\n\n";
			
	my $connstr = "ENG=$dbname;CommLinks=tcpip{host=localhost;port=$port};UID=$cre;PWD=$cre";
	#print $connstr;
	my $dbh = DBI->connect( "DBI:SQLAnywhere:$connstr", '', '', {AutoCommit => 1} ) or warn $DBI::errstr;
	my $sel_stmt=$dbh->prepare($arg) or warn $DBI::errstr;

	if ( $type eq "ROW" ) {
		$sel_stmt->execute() or warn $DBI::errstr;
		my @result = $sel_stmt->fetchrow_array();
		$sel_stmt->finish();
		#$dbh->disconnect;
		return @result;
	}       
	elsif ( $type eq "ALL" ) {
		$sel_stmt->execute() or warn $DBI::errstr;
		my $result = $sel_stmt->fetchall_arrayref();
		$sel_stmt->finish();
		return $result;
	}
	$dbh->disconnect;
}

################################################################################################################
																							
sub uniq {
	return keys  %{{ map { $_ => 1 } @_ }};
}

############################################################

sub kgbsummary{
}


# VERIFY THE INSTALLED VERSION
# This is a utility to get the version from the eniq_status file
sub verifyVersion{
	my $version="";
	open(VER,"cat /eniq/admin/version/eniq_status |");
	my @version=<VER>;
	close(VER);
	foreach my $ver (@version)
	{ 
	$version.=$ver;
	}
	return $version;
}

# GET HOST NAME
# This is a utility to get the host name
sub getHostName{
	open(HOST,"hostname |");
	my @host=<HOST>;
	chomp(@host);
	close(HOST);
	return $host[0];
}

##############################################################################################################################################

if($kgbsummary eq "true")
{
	#writeWholeResult();
	#writeAllResult();
	writeResult();
    my $report =getHtmlHeader();
	$report.="<h1> <font color=MidnightBlue><center> <u> KGB EXECUTION SUMMARY </u> </font> </h1>";
	
	$report.=qq{<body bgcolor=GhostWhite> </body> <center> <table  BORDER="3" CELLSPACING="2" CELLPADDING="3" WIDTH="80%" >};
	$report.= "<tr>";
	$report.= "<td><font size = 2 ><b>START TIME:\t</td>";
	my $stime = getTime();
	$report.= "<td><b>$stime\t</td>";
	  	
	$report.= "<tr>";
	$report.= "<td><font size = 2 ><b>HOST:\t</td>";
	my $host= getHostName();
	$report.= "<td><b>$host\t</td>";
	
	$report.= "<tr>";
	$report.= "<td><font size = 2 ><b>VERSION:\t</td>";
	my $version = verifyVersion();
	$report.= "<td><b>$version\t</td>";
	
	$report.= "<tr>";
	$report.= "<td><font size = 2 ><b>END TIME:\t</td>";
    my $etime = getTime();
	$report.= "<td><b>$etime\t</td>";
	 
	$report.= "</table>";
	$report.= "<br>";
	
	my $result1=tpdata();
	$report.= "$result1";
	 
    $report.= getHtmlTail();
    my $file = writeHtml("KGB_RT_SUMMARY",$report);
	print "SUMMARY FILE: $file\n"; 
    $kgbsummary ="false";
}

sub tpdata
{
	my @array;
	my @tp_name_array;
	my ($strings,$r,$b);
	my ($line);
	my $i;
	
	my ($sec,$min,$hour,$mday,$mon,$year,$wday, $yday,$isdst)=localtime(time);
	# my $today = sprintf "%4d-%02d-%02d ", $year+1900,$mon+1,$mday;
	# print "$today\n";
	my @tp_name ="";
	my $file = 'data.txt';
	open FILE, '<', $file or die "Could not open '$file', No such file found in the provided path $!\n";
	@array = <FILE>;
	my $count = @array;
	print "Tech pack count: $count\n";
	for ($i=0;$i<$count;$i++) {
		undef $line;
		$line = shift @array;
		chomp $line;
		($strings,$r,$b) = $line  =~ m/((DC_|INTF_|BO_|DWH_|DIM_)\w*)(\_R.+\_b)(\d+)/;
		print "$strings\n";			
				
		if ($strings=~ m/(^DC_\w*)/)
		{
			foreach my $tp ($strings)
			{
				$report.=qq{<body bgcolor=GhostWhite> </body> <center> <table  BORDER="3" CELLSPACING="2" CELLPADDING="3" WIDTH="80%" >};
				$report.="<tr>";
				$report.="<th colspan=2><font size=4>$tp</th>";
				$report.="</tr>";
				$report.="<tr>";
				$report.="<th><font size=4>Test Scenario</th><th><font size=4>Result</th>";
				$report.="</tr>";
				$report.= "<tr>";
				$report.= "<td><font size = 2 ><b>SANITY PRECHECK: INSTALLATION AND ENCRYPTION\t</td>";
				$report.= "<td><font size = 2 >$encryptMap{$tp}</td>";
				$report.= "</tr>";
				 
				# $report.= "<tr>";
				# $report.= "<td><font size = 2 ><b><a href=\"COUNTER_DATA_VALIDATION.html#$tp\" target=\"_blank\">TABLE VERIFICATION\t</td>";
				# $report.= "<td><font size = 2 >$counterMap{$tp}</td>";
				# $report.= "</tr>";
				 
				$report.= "<tr>";
				$report.= "<td><font size = 2 ><b><a href=\"VERIFY_TABLE_DATA_LOADING.html#$tp\" target=\"_blank\">TABLE DATA LOADING\t</td>";
				$report.= "<td><font size = 2 >$dataMap{$tp}</td>";
				$report.= "</tr>";
				
				$report.= "<tr>";
				$report.= "<td><font size = 2 ><b><a href=\"VERIFY_TOPOLOGY_DATA_LOADING.html#$tp\" target=\"_blank\">TOPOLOGY DATA LOADING\t</td>";
				$report.= "<td><font size = 2 >$topologyMap{$tp}</td>";
				$report.= "</tr>";
				
				$report.= "<tr>";
				$report.= "<td><font size = 2 ><b><a href=\"Aggregation_Status.html#$tp\" target=\"_blank\">AGGREGATION STATUS\t</td>";
				$report.= "<td><font size = 2 >$statusMap{$tp}</td>";
				$report.= "</tr>";
				 
				$report.= "<tr>";
				$report.= "<td><font size = 2 ><b><a href=\"Busy_Hour.html#$tp\" target=\"_blank\">BUSY HOUR\t</td>";
				$report.= "<td><font size = 2 >$bhMap{$tp}</td>";
				$report.= "</tr>";
				 
				# $report.= "<tr>";
				# $report.= "<td><font size = 2 ><b><a href=\"Log_Verification.html\" target=\"_blank\">SANITY POSTCHECK\t</td>";
				# $report.= "<td><font size = 2 >FAIL</td>";
				# $report.= "</tr>";
				
				$report.= "</table>";
				$report.= "<br>";	
		}
	}
	elsif ($strings=~ m/(DWH_\w*)/){
		foreach my $tp ($strings)
		{
			$report.=qq{<body bgcolor=GhostWhite> </body> <center> <table  BORDER="3" CELLSPACING="2" CELLPADDING="3" WIDTH="80%" >};
			$report.="<tr>";
			$report.="<th colspan=2><font size=4>$tp</th>";
			$report.="</tr>";
			$report.="<tr>";
			$report.="<th><font size=4>Test Scenario</th><th><font size=4>Result</th>";
			$report.="</tr>";
			$report.= "<tr>";
			$report.= "<td><font size = 2 ><b>SANITY PRECHECK: INSTALLATION AND ENCRYPTION\t</td>";
			$report.= "<td><font size = 2 >$encryptMap{$tp}</td>";
			$report.= "</tr>"; 
			# $report.= "<tr>";
			# $report.= "<td><font size = 2 ><b><a href=\"VERIFY_DATA_LOADING.html\" target=\"_blank\">DATA LOADING\t</td>";
			# $report.= "<td><font size = 2 ></td>";
			# $report.= "</tr>";
			
			$report.= "</table>";
			$report.= "<br>";
		}		
	}
	elsif ($strings=~ m/(^DIM_\w*)/){
		foreach my $tp ($strings)
		{
			$report.=qq{<body bgcolor=GhostWhite> </body> <center> <table  BORDER="3" CELLSPACING="2" CELLPADDING="3" WIDTH="80%" >};
			$report.="<tr>";
			$report.="<th colspan=2><font size=4>$tp</th>";
			$report.="</tr>";
			$report.="<tr>";
			$report.="<th><font size=4>Test Scenario</th><th><font size=4>Result</th>";
			$report.="</tr>";
			$report.= "<tr>";
			$report.= "<td><font size = 2 ><b>SANITY PRECHECK: INSTALLATION AND ENCRYPTION\t</td>";
			$report.= "<td><font size = 2 >$encryptMap{$tp}</td>";
			$report.= "</tr>"; 
			$report.= "<tr>";
			$report.= "<td><font size = 2 ><b><a href=\"VERIFY_TOPOLOGY_DATA_LOADING.html#$tp\" target=\"_blank\">TOPOLOGY DATA LOADING\t</td>";
			$report.= "<td><font size = 2 >$topologyMap{$tp}</td>";
			$report.= "</tr>";
			
			$report.= "</table>";
			$report.= "<br>";
		}		
	}
	elsif ($strings=~ m/(^INTF_\w*)/){
		foreach my $tp ($strings)
		{
			$report.=qq{<body bgcolor=GhostWhite> </body> <center> <table  BORDER="3" CELLSPACING="2" CELLPADDING="3" WIDTH="80%" >};
			$report.="<tr>";
			$report.="<th colspan=2><font size=4>$tp</th>";
			$report.="</tr>";
			$report.="<tr>";
			$report.="<th><font size=4>Test Scenario</th><th><font size=4>Result</th>";
			$report.="</tr>";
			$report.= "<tr>";
			$report.= "<td><font size = 2 ><b>SANITY PRECHECK: INSTALLATION AND ENCRYPTION\t</td>";
			$report.= "<td><font size = 2 >$encryptMap{$tp}</td>";
			$report.= "</tr>"; 
			$report.= "<tr>";
			$report.= "<td><font size = 2 ><b><a href=\"InterfaceDirectory_Check.html#$tp\" target=\"_blank\">INTERFACE\t</td>";
			$report.= "<td><font size = 2 >$interfaceMap{$tp}</td>";
			$report.= "</tr>";
			
			$report.= "</table>";
			$report.= "<br>";
		}		
	}
	elsif ($strings=~ m/(^BO_\w*)/){
		foreach my $tp ($strings)
		{
			$report.=qq{<body bgcolor=GhostWhite> </body> <center> <table  BORDER="3" CELLSPACING="2" CELLPADDING="3" WIDTH="80%" >};
			$report.="<tr>";
			$report.="<th colspan=2><font size=4>$tp</th>";
			$report.="</tr>";
			$report.="<tr>";
			$report.="<th><font size=4>Test Scenario</th><th><font size=4>Result</th>";
			$report.="</tr>";
			$report.= "<tr>";
			$report.= "<td><font size = 2 ><b><a href=\"Universe_Check.html#$tp\" target=\"_blank\">UNIVERSE\t</td>";
			$report.= "<td><font size = 2 >$universeMap{$tp}</td>";
			$report.= "</tr>";
			
			$report.= "</table>";
			$report.= "<br>";	
		}
	}
	else{
		print "$line: No Valid Data.\n\n\n";
	}
}
return $report;
}
