#!/usr/bin/perl

use strict;
use warnings;
no warnings 'uninitialized';

use DBI;
use Data::Dumper;
use Text::CSV;
use POSIX qw(strftime);

my $result;
my $pass = 0;
my $fail = 0;
my $validTechPackCount = 0;
my %perTPRes;

my $LOGPATH="/eniq/home/dcuser/RegressionLogs";
my $RESULTPATH="/eniq/home/dcuser/ResultFiles";

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
Interface Input Directory
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
#####################

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
# ExecuteSQL
# This will give the resultset data for the queries passed

sub executeSQL{
	my $dbname = $_[0];
    my $port = $_[1];
    my $cre = $_[2];
    my $arg = $_[3];
    my $type = $_[4];
	my $password= getDBPassword($cre);
	
	my $connstr = "ENG=$dbname;CommLinks=tcpip{host=localhost;port=$port};UID=$cre;PWD=$password";
	my $dbh = DBI->connect( "DBI:SQLAnywhere:$connstr", '', '', {AutoCommit => 1} ) or warn $DBI::errstr;
    my $sel_stmt=$dbh->prepare($arg) or warn $DBI::errstr;
	if ( $type eq "ROW" ) {
		$sel_stmt->execute() or warn $DBI::errstr;
        my @result = $sel_stmt->fetchrow_array();
        $sel_stmt->finish();
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

sub getDBPassword{
	my $user = $_[0];
	my $connection = "";
	
	if($user eq "dc"){
		$connection = "dwh";
	}
	elsif($user eq "dwhrep"){
		$connection = "dwhrep";
	}
	elsif($user eq "etlrep"){
		$connection = "etlrep";
	}
	my $dbusers = "/eniq/sw/installer/dbusers";
	my $dbPassword = `$dbusers $user $connection`;

	return $dbPassword;
}

############################################################
# intfDirectoryCheck, CHECKS THE inDIR: THE DIRECTORIES FOR ALL ETLS
# This is a very simple test, just runs the query below and lists
# the results in a table
#

sub intfDirectoryCheck{
	my $result;
	my @array;
	my @activeInterfaces;
	my $intfname;
	my $indir;
	my $line;
	my $tp_name;
	my $ath;
	my $stat;
	my $tp_fail = 0;
	
	my $file = 'data.txt';
	open FILE, '<', $file or die "Could not open '$file', No such file found in the provided path $!\n";
	@array = <FILE>;
	my $count = @array;
	
	for (my $i=0;$i<$count;$i++) 
	{
		undef $line;
		$line = shift @array;
		chomp $line;
		if ($line=~ m/(^INTF_\w*)\.tpi/)
		{
			$validTechPackCount++;
			($tp_name) = $line  =~ /(\w*)_R\d+[A-Z]_b\d+\.tpi/;
			print "$tp_name\n";
			$result.=qq{<body bgcolor=GhostWhite> </body> <center> <table id="$tp_name" BORDER="3" CELLSPACING="2" CELLPADDING="3" WIDTH="80%" >};
			$result.="<tr>";
			$result.="<th align=left colspan=3><font color=black size=5px><b>Interface: $tp_name</b></th>";
			$result.="</tr>";
			$result.="<tr>";
			$result.="<th align=left><font size=4>Interface</font></th><th align=left><font size=4>Directory</font></th><th align=left><font size=4>Result</font></th>";
			$result.="</tr>";
			my ($tp_name_like) = $tp_name . "-%";
			my $sql = qq{
SELECT c.collection_set_name,
SUBSTRING(action_contents_01,
  CHARINDEX('inDir=', action_contents_01),
  CHARINDEX('interfaceName=',
  SUBSTRING(action_contents_01, CHARINDEX('inDir=', action_contents_01)))-2
)
FROM
etlrep.meta_transfer_actions a
JOIN etlrep.meta_collections b
ON (   a.version_number = b.version_number
AND a.collection_id = b.collection_id
AND a.collection_set_id = b.collection_set_id)
JOIN etlrep.meta_collection_sets c
ON (   b.version_number = c.version_number
AND b.collection_set_id = c.collection_set_id
and c.collection_set_name like "$tp_name_like")
WHERE
action_type = 'Parse' AND c.enabled_flag = 'Y'
order BY 1
};
			my $activeInterfaces = executeSQL("repdb",2641,"etlrep",$sql,"ALL");
			if (@$activeInterfaces){
				foreach my $intfRow( @$activeInterfaces){
					($intfname, $indir) = @$intfRow;
					$result .= "<tr><td align=left><font color=0000FF><b>$intfname</b></font></td><td align=left><font color=0000FF><b>$indir</b></font></td>";
					my ($subDir) = $indir  =~ /\w*\/\w*\/(\w*)\//;
					
					open (FL, "<eniq.xml") or die "Couldn't open file eniq.xml, $!";
					my @file = <FL>;
					my $found = 0;
					foreach my $file (@file){
						if ($file =~ m/>$subDir</){
							$result .= "<td align=left><font color=green><b>PASS</b></font></td>";
							$pass++;
							$found++;
							last;
						}
					}
					if ($found == 0){
						$result .= "<td align=left><font color=FF4500><b>FAIL (Not found!)</b></font></td>";
						$tp_fail++;
						$fail++;
					}
					close(FL) || die "Couldn't close file properly";
				}
			}
			else{
				$result .= "<td colspan=2 align=left><font color=FF4500><b>Interface not active!</b></font></td><td align=left><font color=FF4500><b>FAIL</b></font></td></tr>";
				$tp_fail++;
				$fail++;
			}
			$result.= "</table>";
			if ($tp_fail == 0){
				$perTPRes{$tp_name} = "PASS";
			}
			else{
				$perTPRes{$tp_name} = "FAIL";
			}
		} else {
			print "$line: This is not a Interface TP. This testcase is only for Interface TP.\n";
		}
	}
	return $result;
}


#################################################MAIN###################################################################

print "*****INTERFACE DIRECTORY CHECK*****\n";
my $report = getHtmlHeader();
$report.="<h1> <font color=MidnightBlue><center> <u> INTERFACE DIRECTORY CHECK </u> </font> </h1>";
$report.=qq{<body bgcolor=GhostWhite> </body> <center> <table  BORDER="3" CELLSPACING="2" CELLPADDING="3" WIDTH="80%" >};
$report.= "<tr>";
$report.= "<td><font size = 2 ><b>START TIME:\t</td>";
my $stime = getTime();
$report.= "<td><b>$stime\t</td>";
my $result1=intfDirectoryCheck();
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
if($validTechPackCount != 0) {
	my $file = writeHtml("InterfaceDirectory_Check",$report);
	writeResult("InterfaceDirectory_Check");
	print "INTERFACE DIRECTORY CHECK FILE: $file\n";
}