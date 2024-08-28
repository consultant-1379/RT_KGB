#!/usr/bin/perl

use strict;
use warnings;
no warnings 'uninitialized';

use DBI;
use Data::Dumper;
use Text::CSV;
use POSIX qw(strftime);

my $result;
my $LOGPATH="/eniq/home/dcuser/RegressionLogs";
my $boUnvFolder = "/eniq/sw/installer/bouniverses/";
my $RESULTPATH="/eniq/home/dcuser/ResultFiles";

my $pass = 0;
my $fail = 0;
my $validTechPackCount = 0;
my %perTPRes;

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
	return qq{<!DOCTYPE HTML PUBLIC "-//W3C//DTD HTML 4.01 Transitional//EN">
<html>
<head>
<title>
Universe Check
</title>
<STYLE TYPE="text/css">
</STYLE>
</head>
<body>
};
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
# WRITE Result
# This is a utility for result file for summary page

sub writeResult{
	my $filename = "$RESULTPATH/" . $_[0].".txt";
	open(my $fhandle, ">", $filename) or die "Couldn't open: $!";
	foreach my $tp (keys %perTPRes) {
		print "$tp=$perTPRes{$tp}\n";
		print $fhandle "$tp=$perTPRes{$tp}\n";
	}
	close $fhandle;
}


############################################################
# READ Result
# This is a utility for result file for universe page
sub cuidStat{
	my $packName = $_[0];
	my $res = 0;
	my $htmlRes = "<tr><td align=left><font size=2 color=blue><b>Installation and CUID Check</a></td>";
	my $boRes;
	my $installStatus = '/eniq/sw/installer/TP_BO_Installation_Status.txt';
	open FILE, '<', $installStatus or die "Could not open '$installStatus', No such file found in the provided path $!\n";
	my @tparray = <FILE>;
	foreach $boRes (@tparray){
		my ($boPack,$insRes) = split(",",$boRes);
		if( $boPack eq $packName ){
			chomp($insRes);
			if ( $insRes eq "PASSED" ){
				$htmlRes .= "<td align=left><font size=2 color=green><b>PASS</b></td></tr>";
				$pass++;
			}
			else{
				$fail++;
				$res++;
				$htmlRes .= "<td align=left><font size=2 color=red><b>FAIL</b></td></tr>";
			}
		}
	}	
	close FILE;
	return $res,$htmlRes;
}

sub checkUnvFolder {
	my $bo_del = $_[0];
	my $res = 0;
	my $htmlRes = "<tr><td align=left><font size=2 color=blue><b>Folder Structure</a></td>";
	my $bo_parent = $boUnvFolder . $bo_del;
	my $bo_unv = $bo_parent . "/unv/";
	my $bo_install = $bo_parent . "/install/";
	if ( -d $bo_parent ){
		if ( -d $bo_unv && -d $bo_install ){
			opendir(DIR, $bo_unv) or die $!;
			while ( my $file = readdir(DIR)){
				$file = $bo_unv . $file;
				if ( -f $file ){
				if ( $file =~ m/\.lcmbiar$/){
					$htmlRes .= "<td align=left><font size=2 color=green><b>PASS</b></td></tr>";
					$pass++;
				}
				else{
					$htmlRes .= "<td align=left><font size=2 color=red><b>FAIL</b></td></tr>";
					$res++;
					$fail++;
				}
				}
			}
			closedir(DIR);
		}
		else{
			$htmlRes .= "<td align=left><font size=2 color=red><b>FAIL</b></td></tr>";
			$res++;
			$fail++;
		}
	}
	else{
		$htmlRes .= "<td align=left><font size=2 color=red><b>FAIL</b></td></tr>";
		$res++;
		$fail++;
	}
	return $res,$htmlRes;
}

############################################################

sub universecheck
{
	my $result;
	my @array;
	my ($line);
	my $tp_name;
	my $bo_name;	
	
	my $file = 'data.txt';
	open FILE, '<', $file or die "Could not open '$file', No such file found in the provided path $!\n";
	@array = <FILE>;
	my $count = @array;
	
	for (my $i=0;$i<$count;$i++) 
	{
		undef $line;
		$line = shift @array;
		chomp $line;	
		if ($line=~ m/(^BO_\w*)\.tpi/)
		{
			$validTechPackCount++;
			($tp_name) = $line  =~ /(\w*)\.tpi/;
			($bo_name) = $line  =~ /(\w*)_R\d+[A-Z]_b\d+\.tpi/;
			print "$tp_name\n";
			$result.=qq{<body bgcolor=GhostWhite> </body> <center> <table id="$tp_name" BORDER="3" CELLSPACING="2" CELLPADDING="3" WIDTH="80%" >};
			$result.="<tr>";
			$result.="<th align=left colspan=2><font color=black size=5px><b>Universe Package: $bo_name</b></th>";
			$result.="</tr>";
			$result.="<tr>";
			$result.="<th align=left><font size=4>Test Scenario</th><th align=left><font size=4>Result</th>";
			$result.="</tr>";
			my ($cuidRes,$cuidHtml) = cuidStat($line);
			my ($folderRes,$folderHtml) = checkUnvFolder($tp_name);
			$result.= $cuidHtml;
			$result.= $folderHtml;
			$result.= "</table>";
			$result.= "<br>";
			
			if ($cuidRes == 0 && $folderRes == 0){
				$perTPRes{$bo_name} = "PASS";
			}
			else{
				$perTPRes{$bo_name} = "FAIL";
			}
		} else {
			print "$line: This is not a universe TP. This testcase is only for universe TP.\n";
		}
	}
	return $result;
}


#################################################MAIN#############################################################################################

print "*****UNIVERSE CHECK*****\n";
my $report = getHtmlHeader();
$report.="<h1> <font color=MidnightBlue><center> <u> UNIVERSE CHECK </u> </font> </h1>";
$report.=qq{<body bgcolor=GhostWhite> </body> <center> <table  BORDER="3" CELLSPACING="2" CELLPADDING="3" WIDTH="80%" >};
$report.= "<tr>";
$report.= "<td><font size = 2 ><b>START TIME:\t</td>";
my $stime = getTime();
$report.= "<td><b>$stime\t</td>";
my $result1=universecheck();
$report.= "<tr>";
$report.= "<td><font size = 2 ><b>END TIME:\t</td>";
my $etime = getTime();
$report.= "<td><b>$etime\t</td>";
$report.= "<tr><td><font size = 2 ><b>RESULT:\t</td>";
$report.= "<td><b>PASS ($pass) / FAIL ($fail)\t</td></tr>";
$report.= "</table>";
$report.= "<br>";
$report.= $result1;
$report.= getHtmlTail();
if ( $validTechPackCount != 0 ) {
	my $file = writeHtml("UNIVERSE_CHECK",$report);
	writeResult("UNIVERSE_CHECK");
	print "UNIVERSE CHECK FILE: $file\n"; 
}