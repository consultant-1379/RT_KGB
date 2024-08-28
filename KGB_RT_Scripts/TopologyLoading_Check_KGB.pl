#!/usr/bin/perl

use strict;
use warnings;
no warnings 'uninitialized';

use DBI;
use Data::Dumper;
use Text::CSV;

my $topoloading = "true";
my $result;
my $report="";
my $num = 0;
my $num1 = 0;

my $LOGPATH="/eniq/home/dcuser/RegressionLogs";
my $RESULTPATH="/eniq/home/dcuser/ResultFiles";

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
VERIFY_TOPOLOGY_DATA_LOADING
</title>
<STYLE TYPE="text/css">
<!--
h3{font-family:tahoma;font-size:12px}
body,td,tr,p,h{font-family:tahoma;font-size:11px}
.pre{font-family:Courier;font-size:9px;color:#000}
.h{font-size:9px}
.td{font-size:9px}
.tr{font-size:9px}
.h{color:#3366cc}
.q{color:#00c}
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
else
{
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
.pre{font-family:Courier;font-size:9px;color:#000}
.h{font-size:9px}
.td{font-size:9px}
.tr{font-size:9px}
.h{color:#3366cc}
.q{color:#00c}
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
my $server = shift;
my $out    = shift;
open(OUT," > $LOGPATH/$server.html");
print  OUT $out;
close(OUT);
return "$LOGPATH/$server.html\n";
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
																							
sub uniq {
			return keys  %{{ map { $_ => 1 } @_ }};
	}

############################################################
# Dataloading MO this will verify whether the data is matching with the EPFG input file.
# 

sub topoloading{
				
	my @array;
	my @tp_name_array;
	my ($strings,$r,$b);
	my ($line);
	my $i;
		
	my ($sec,$min,$hour,$mday,$mon,$year,$wday, $yday,$isdst)=localtime(time);
    my $today = sprintf "%4d-%02d-%02d ", $year+1900,$mon+1,$mday;
	print "$today\n";
	my @tp_name ="";
	my $file = 'data.txt';
	open FILE, '<', $file or die "Could not open '$file', No such file found in the provided path $!\n";
	@array = <FILE>;
	print "@array\n";
	my $count = @array;
	print "$count\n";
				
	for ($i=0;$i<$count;$i++) {
		undef $line;
	    $line = shift @array;
		chomp $line;
		print "$line\n";
		($strings,$r,$b) = $line  =~ m/(^DC_\w*|^DIM_E_\w*)(\_R.+\_b)(\d+)/;
		my $final_str = $strings.":((".$b."))";
				
		if ($strings=~ m/(^DIM_E_\w*)/ || $strings=~ m/(^DC_E_LLE\w*)/)
		{
			foreach my $tp ($final_str) {
					
				$result .= "<tr><td align=left><font color=black><font size=5px><b>TP NAME:</b></font></font></td><td align=left><font color=blue><font size=5px><b>$tp</b></font></font></td></tr>";
				$result .= "<tr><td align=left><font color=000000><b>TABLE NAME</b></font></td><td align=left><font color=000000><b>RESULT</b></font></td></tr>";					
					
				my $tp_query = "select TYPENAME from ReferenceTable where VERSIONID like '$tp' and TYPENAME like 'DIM%'";
				my ($tp_names) = executeSQL("repdb",2641,"dwhrep",$tp_query,"ALL");
					
				undef @tp_name_array;
					
				for my $rows ( @$tp_names ) {
					for my $field ( @$rows ) {
						if ( $field !~ m/^dc*/ || $field !~ m/^DC*/ )
						{
							push @tp_name_array, $field;
						}
					}
				}
					
				foreach ( @tp_name_array ){
					my $tab_name = $_;
					$tab_name =~ s/ //g;
					print "$tab_name\n";
					
					my $query2 = "select count(*) from $tab_name" ;
					my ($res2) = executeSQL("dwhdb",2640,"dc",$query2,"ROW");
					
					$result .= "<tr><td align=left><font color=4169E1><b>$tab_name</b></font></td><td align=left><font color=4169E1><b>COUNT:$res2</b></font></td></tr>";
					#print "$tab_name = $res2\n";
					
					if ($res2 == '0'){
						
						$result .= "<tr><td align=left><font color=FF0000><b>$tab_name</b></font></td><td align=left><font color=FF0000><b>DATA NOT LOADED</b></font></td></tr>";
						$num++;
						print "$num\n";
					}
					else{
					
						$result .= "<tr><td align=left><font color=008000><b>$tab_name</b></font></td><td align=left><font color=008000><b>DATA LOADED</b></font></td></tr>";
						#print "DATA LOADED\n";
						$num1++;
						print "$num1\n";
					}
				}
			}
			my $final_file = "$RESULTPATH/TOPOLOGY_DATA_LOADING.txt";
			open (my $finale , '>>', $final_file ) or die "ERROR: Couldn't open file for writing '$final_file' $! \n";
					
			if ($num > 0) {
				print $finale "$strings=FAIL\n";
			}
			else{
				print $finale "$strings=PASS\n";
			}
		}
		elsif ($strings=~ m/(^DC_\w*)/ && $strings!~ m/(^DC_E_LLE\w*)/) {
			$result .= "<tr><td align=left><font color=black><font size=5px><b>TP NAME:</b></font></font></td><td align=left><font color=blue><font size=5px><b>$strings</b></font></font></td></tr>";
			$result .= "<tr><td align=left><font color=000000><b>TABLE NAME</b></font></td><td align=left><font color=000000><b>RESULT</b></font></td></tr>";	
			my $transformationQuery = "SELECT DISTINCT SUBSTRING(CONFIG,CHARINDEX('BASETABLE=',CONFIG)+10,100) AS a FROM TRANSFORMATION WHERE CONFIG LIKE '%DIM_E_%' AND CONFIG NOT LIKE '%DIM_E_%site%' AND TRANSFORMERID LIKE '$strings:%'";
			my @tp_Names = executeSQL("repdb",2641,"dwhrep",$transformationQuery,"ROW");
			my $failSize = 0;
			for my $eachTP ( @tp_Names ) {
				$eachTP =~ s/ //g;
				print "$eachTP\n";
				my $query = "select count(*) from $eachTP" ;
				my ($res1) = executeSQL("dwhdb",2640,"dc",$query,"ROW");
					
				$result .= "<tr><td align=left><font color=4169E1><b>$eachTP</b></font></td><td align=left><font color=4169E1><b>COUNT:$res1</b></font></td></tr>";	
				if ($res1 == '0'){
					$result .= "<tr><td align=left><font color=FF0000><b>$eachTP</b></font></td><td align=left><font color=FF0000><b>DATA NOT LOADED</b></font></td></tr>";
					$num++;
					$failSize++;
					print "$num\n";
				}
				else{
					$result .= "<tr><td align=left><font color=008000><b>$eachTP</b></font></td><td align=left><font color=008000><b>DATA LOADED</b></font></td></tr>";
					$num1++;
					print "$num1\n";
				}
			}
			my $final_file = "$RESULTPATH/TOPOLOGY_DATA_LOADING.txt";
			open (my $finale , '>>', $final_file ) or die "ERROR: Couldn't open file for writing '$final_file' $! \n";
					
			if ($failSize > 0) {
				print $finale "$strings=FAIL\n";
			}
			else{
				print $finale "$strings=PASS\n";
			}
		} 
		else {
			print "$line: This is not a Topology TP. This testcase is only for Topology TP.\n\n\n";
		}
	}
	return $result;
}


##############################################################################################################################################

if($topoloading eq "true")
   {
     my $report =getHtmlHeader();
	$report.="<h1> <font color=MidnightBlue><center> <u> VERIFY TOPOLOGY DATA LOADING </u> </font> </h1>";
	
	$report.=qq{<body bgcolor=GhostWhite> </body> <center> <table  BORDER="3" CELLSPACING="2" CELLPADDING="3" WIDTH="80%" >};
	$report.= "<tr>";
	$report.= "<td><font size = 2 ><b>START TIME:\t</td>";
	my $stime = getTime();
	 $report.= "<td><b>$stime\t</td>";
	 
	 my $result1=topoloading();
	    	 
	 $report.= "<tr>";
	 $report.= "<td><font size = 2 ><b>END TIME:\t</td>";
     my $etime = getTime();
	 $report.= "<td><b>$etime\t</td>";
	 
	 $report.= "<tr>";
	 $report.= "<td><font size = 2 ><b>RESULT:\t</td>";
	 $report.= "<td><a href=\"#t1\"><font size = 2 color=green><b>PASS ($num1) / <a href=\"#t2\"><font size = 2 color=red><b>FAIL ($num)</td>";
	 
	 $report.= "</table>";
	 $report.= "<br>";
	 
	 #$result.="<h2> $result1 </h2>";
	 $report.=qq{<body bgcolor=GhostWhite> </body> <center> <table  BORDER="3" CELLSPACING="2" CELLPADDING="3" WIDTH="80%" >};
	 $report.= $result1;
	 $report.= "</table>";
	 
     $report.= getHtmlTail();
	 if ($num1 != 0 && $num != 0) {
		my $file = writeHtml("VERIFY_TOPOLOGY_DATA_LOADING",$report);
		print "PARTIAL FILE: $file\n"; 
	 }
     $topoloading ="false";
   }