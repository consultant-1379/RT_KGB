#!/usr/bin/perl

use strict;
use warnings;
#no warnings 'uninitialized';
use DBI;
use Data::Dumper;
use Text::CSV;

my $LOGPATH="/eniq/home/dcuser/RegressionLogs";
my $RESULTPATH="/eniq/home/dcuser/ResultFiles";
my $pass = 0;
my $fail = 0;
my $validTechPackCount = 0;
my %perTPRes;

my ($sec,$min,$hour,$mday,$mon,$year,$wday, $yday,$isdst)=localtime( time - 86400 );
$mon++;
$year=1900+$year;
my $today = sprintf "%4d-%02d-%02d", $year,$mon,$mday;
print "Checking for Yesterday's date - $today\n";

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
Busy Hour
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
# ExecuteSQL
# This will give the resultset data for the queries passed

sub executeSQL{
	my $dbname = $_[0];
    my $port = $_[1];
    my $cre = $_[2];
    my $arg = $_[3];
    my $type = $_[4];
	my $password= getDBPassword($cre);
	#print "executeSQL : $arg  $type $cre $port $dbname\n\n";
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

################################################################################################################
#Enter descriptions for all
#

sub check_aggStatus{
	my $type_id = $_[0];
	my $status_query = "SELECT AGGREGATION,STATUS FROM LOG_AggregationStatus WHERE TIMELEVEL='DAYBH' AND TYPENAME='$type_id' AND DATADATE='$today'";
	my $status = executeSQL("dwhdb",2640,"dc",$status_query,"ALL");
	return $status;
}

sub getDayBHTablesFromTP{
	my $techPack = $_[0];
	my $versionID = $_[1];
	my $dayBHAgg_query = "select distinct B.TYPENAME, a.typeid, b.DELTACALCSUPPORT from MeasurementObjBHSupport as A, MeasurementType as B where a.OBJBHSUPPORT IN (select distinct BHOBJECT from Busyhour WHERE ENABLE=1 and VERSIONID='$versionID') AND a.typeid in (SELECT TYPEID FROM MeasurementType WHERE VERSIONID='$versionID' AND TOTALAGG = 1 AND RANKINGTABLE = 0) and a.typeid=b.typeid";
	my $dayBHAgg = executeSQL("repdb",2641,"dwhrep",$dayBHAgg_query,"ALL");
	return $dayBHAgg;
}

sub getVersionDetails{
	my $pack = $_[0];
	my $pm_query = "SELECT TYPE,VERSIONID FROM TPActivation WHERE TECHPACK_NAME='$pack'";
	my @type = executeSQL("repdb",2641,"dwhrep",$pm_query,"ROW");
	if (@type){
		if ($type[0] eq "PM"){
			return 1,$type[1];
		}
	}
	return 0,undef;
}

sub getRawData{
	my $keys = $_[0];
	my $counters = $_[1];
	my $rawTable = $_[2];
	my $countAgg = $_[3];
	if ($countAgg eq "0"){
		$rawTable .= "_RAW";
	}
	else{
		$rawTable .= "_COUNT";
	}
	my $result;
	my @keysList = ();
	my @dupConList = ();
	my @counterList = ();
	foreach my $key ( @$keys ){
		my ($keyName,$unique) = @$key;
		if ($unique eq "0"){
			push @keysList, "MIN(".$keyName.")";
		}
		else{
			push @keysList, $keyName;
			push @dupConList, $keyName;
		}
	}
	foreach my $counter ( @$counters ){
		my ($counterName,$timeAgg) = @$counter;
		push @counterList, "$timeAgg($counterName)";
	}
	my $columns = join(",",(@keysList,@counterList));
	my $dupKeys = join(",",(@dupConList));
	my $getRawData_query = "select $columns from $rawTable where ROWSTATUS not in ('DUPLICATE','SUSPECTED') and DATE_ID = '$today' group by $dupKeys";
	$result = executeSQL("dwhdb",2640,"dc",$getRawData_query,"ALL");
	return $result;
}

sub getDayData{
	my $keys = $_[0];
	my $counters = $_[1];
	my $dayTable = $_[2]."_DAY";
	my $result;
	my @keysList = ();
	my @dupConList = ();
	my @counterList = ();
	foreach my $key ( @$keys ){
		my ($keyName,$unique) = @$key;
		if ($unique eq "0"){
			push @keysList, "MIN(".$keyName.")";
		}
		else{
			push @keysList, $keyName;
			push @dupConList, $keyName;
		}
	}
	foreach my $counter ( @$counters ){
		my ($counterName,$timeAgg) = @$counter;
		push @counterList, "$timeAgg($counterName)";
	}
	my $columns = join(",",(@keysList,@counterList));
	my $dupKeys = join(",",(@dupConList));
	my $getDayData_query = "select $columns from $dayTable where ROWSTATUS not in ('DUPLICATE','SUSPECTED') and DATE_ID = '$today' group by $dupKeys";
	$result = executeSQL("dwhdb",2640,"dc",$getDayData_query,"ALL");
	return $result;
}

sub getBusyHourByAgg{
	my $aggregation = $_[1];
	
}
############################################################
# Enter valid description
# 

sub busyHour_status{
	my $result;
	my $tp_name;
	my @array;
	my ($line);
	my $typename = undef;
	my $typeid = undef;
	my $delta = undef;
	my $versionid = undef;
	my $checkIfPm = 0;
	my @tblname;
	my $RAW_DATA = undef;
	my $DAY_DATA = undef;
	
	my $file = 'data.txt';
	open FILE, '<', $file or die "Could not open '$file', No such file found in the provided path $!\n";
	@array = <FILE>;
	my $count = @array;
	for (my $i=0;$i<$count;$i++) {
		undef $line;
	    $line = shift @array;
		chomp $line;
		($tp_name) = $line  =~ /(\w*)_R\d+[A-Z]_b\d+\.tpi/;
		print "Package - $line\n";
		#print "Package - $tp_name\n";
		($checkIfPm,$versionid) = getVersionDetails($tp_name);
		if ($checkIfPm){
			$validTechPackCount++;
			my $tp_fail = 0;
			$result.=qq{<body bgcolor=GhostWhite> </body> <center> <table id="$tp_name" BORDER="3" CELLSPACING="2" CELLPADDING="3" WIDTH="80%" >};
			$result .= "<tr><th colspan=3 align=left><font color=black><font size=5px><b>TP NAME: $tp_name</b></font></font></th></tr>";
			$result .= "<tr><th align=left><font color=000000><b>BH AGGREGATION NAME</b></font></th><th align=left><font color=000000><b>RESULT</b></font></th><th align=left><font color=000000><b>STATUS</b></font></th></tr>";
			my $table_names = getDayBHTablesFromTP($tp_name,$versionid);
			if(@$table_names){
			foreach my $tbl( @$table_names ){
				undef $typename;
				undef $typeid;
				undef $delta;
				($typename, $typeid, $delta) = @$tbl;
				my $aggs = check_aggStatus($typename);
				foreach my $agg ( @$aggs ){
					my ($aggregation,$agg_status) = @$agg;
					$result .= "<tr><td align=left><font color=0000FF><b>$aggregation</b></font></td>";
					if ($agg_status eq "AGGREGATED"){
						$result .= "<td align=left><font color=green><b>PASS</b></font></td><td align=left><font color=green><b>$agg_status</b></font></td></tr>";
						$pass++;
					}
					else{
						$result .= "<td align=left><font color=FF4500><b>FAIL</b></font></td><td align=left><font color=FF4500><b>$agg_status</b></font></td></tr>";
						$tp_fail++;
						$fail++;
					}
				}
			}
			}
			else{
				$result .= "<td colspan=3 align=center><font color=green><b>BUSY HOUR AGGREGATIONS NOT ENABLED</b></font></td></tr>";
				$pass++;
			}
			$result.= "</table>";
			if ($tp_fail == 0){
				$perTPRes{$tp_name} = "PASS";
			}
			else{
				$perTPRes{$tp_name} = "FAIL";
			}
		}
		else{
			print "$line: This is not a PM TP. This testcase is only for PM TP.\n";
		}
	}
	return $result;
}
##############################################################################################################################################

print "*****BUSY HOUR*****\n";
my $report = getHtmlHeader();
$report .= "<h1> <font color=MidnightBlue><center> <u> BUSY HOUR </u> </font> </h1>";
$report .= qq{<body bgcolor=GhostWhite> </body> <center> <table  BORDER="3" CELLSPACING="2" CELLPADDING="3" WIDTH="80%" >};
$report .= "<tr>";
$report .= "<td><font size = 2 ><b>START TIME:\t</td>";
my $stime = getTime();
$report .= "<td><b>$stime\t</td>";
my $result1 = busyHour_status();
$report .= "<tr>";
$report .= "<td><font size = 2 ><b>END TIME:\t</td>";
my $etime = getTime();
$report .= "<td><b>$etime\t</td>";
$report .= "<tr><td><b>RESULT</td><td><b>Pass:$pass/Fail:$fail</td></tr>";
$report .= "</table>";
$report .= "<br>";
if ($result1 ne "") {
	$report .= $result1;
}
$report .= getHtmlTail();
if ( $validTechPackCount != 0 ) {
	my $file = writeHtml("Busy_Hour",$report);
	writeResult("Busy_Hour");
	print "BUSY HOUR FILE: $file\n";
}
