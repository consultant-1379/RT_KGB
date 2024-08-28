#!/usr/bin/perl

use strict;
use warnings;
no warnings 'uninitialized';

use DBI;
use Data::Dumper;
use Text::CSV;

my $dataloadingmo = "true";
my $result;
my $final_pass = 0;
my $final_fail = 0;

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
		 elsif ( $type eq "HASH" ) {
                $sel_stmt->execute() or warn $DBI::errstr;
                my $result = $sel_stmt->fetchrow_hashref();
                $sel_stmt->finish();
                return $result;
        }
        $dbh->disconnect;
}


																							
sub uniq {
			return keys  %{{ map { $_ => 1 } @_ }};
	}

############################################################
# Dataloading MO this will verify whether the data is matching with the EPFG input file.
# 

sub dataloadingmo{

				my $value; 
                my $row;
                my $ref;
				my @result;
                my $field;
				
				my %hash;
				my %hash1;
                my %hash_;
                my %hash1_;
                my %hash4;
				my %hashh2;
				my %hash_comp_P;
				my %hash_comp_F;
                my $query2;
				my ($not,$tag_tab);
				my $key;
				my $values;
				my $tp_name_arr;
				my $tp_name_arra;
				my $table_nam;
				my $first_line;
				#### ARRAY's
                my @result2;
                my @s_col_name;
                my @s_col_value;
                my @common = ();
                my @tag_id;
				my @tp_name_array;
				my @tp_name_arr;
				my @tp_name_arra;
				my @tp_name_ar;
				my %tagid_table_name;
				my $strings;
				my $r;
				my $b;
				my  $i;
				my @array;
				my ($line);
				my $sam;
				my $sam1;
				my $val;
                
                my ($sec,$min,$hour,$mday,$mon,$year,$wday, $yday,$isdst)=localtime(time);
                my $today = sprintf "%4d-%02d-%02d ", $year+1900,$mon+1,$mday;
				
								
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
				($strings,$r,$b) = $line  =~ m/(DC_\w*)(\_R.+\_b)(\d+)/;
				print "$strings\n";
				
				my $package = $strings.":((".$b."))";
				
if ($strings=~ m/(DC_\w*)/){
				
				foreach my $tp_names ($package){
				my $tp = substr $tp_names, 0, index($tp_names, ':');
				my ($non_csv,$csv) = $tp_names =~ m/(DC_\w*_)(\w*)/;
				print "$csv\n";
				$result.=qq{<body bgcolor=GhostWhite> </body> <center> <table id="$tp" BORDER="3" CELLSPACING="2" CELLPADDING="3" WIDTH="80%" >};
				$result .= "<tr><td align=left><font color=black><font size=5px><b>TP NAME:</b></font></font></td><td align=left><font color=blue><font size=5px><b>$tp_names</b></font></font></td></tr>";
				$result .= "<tr><td align=left><font color=000000><b>TABLE NAME</b></font></td><td align=left><font color=000000><b>RESULT</b></font></td></tr>";
							
				
				my $output_file2 = "$tp_names.csv";
				open (my $Outputfile , '>', $output_file2 ) or die "ERROR: Couldn't open file for writing '$output_file2' $! \n";
				
				
				print "The TechPack/Node name is $tp_names \n\n";
				my $query = "select substr(MeasurementCounter.typeid,charindex('))',MeasurementCounter.typeid)+3) as tab, dataname as counter from MeasurementCounter  where MeasurementCounter.TYPEID like '%".$tp_names."%'  order by tab";
				my $res = executeSQL("repdb",2641,"dwhrep",$query,"ALL");
				
				my $another_query = "select substr(substr(DATAFORMATID,charindex('))',DATAFORMATID)+3),1,charindex(':',substr(DATAFORMATID,charindex('))',DATAFORMATID)+3))-1) as tab, TAGID from DefaultTags where dataformatid like '%".$tp_names."%'  order by tab";
				my $res1 = executeSQL("repdb",2641,"dwhrep",$another_query,"ALL");
				
				undef %hash;
				undef %hash1;
				undef %hash_;
				undef %hash1_;
#______________________________________________________________________________________________________________________________________________________________________
				for my $data1 (@$res1){
				
				my ($table, $counter) = @$data1;
				push @{$hash{$table}}, $counter;
										
				}
				#### While loop to remove the duplicates column names in HASH1
                while ( my ( $k , $v) = each (%hash)){
                                                my @uniq_value;
                                                my @temp_array = @$v;
                                                my %temp_hash = map { $_, 0 } @temp_array;
                                                @uniq_value = keys %temp_hash;
                                                push @{$hash_{$k}} , @uniq_value;
                  } # While Loop Closed for uniq array in HASH1
				  #print Dumper(\%hash);
				
#______________________________________________________________________________________________________________________________________________________________________
				
				for my $data (@$res){
						
						my ($table, $counter) = @$data;
						push @{$hash1{$table}}, $counter;
						}

				#### While loop to remove the duplicates column names in HASH1
                while ( my ( $key1 , $value1) = each (%hash1)){
                                                my @uniq_value;
                                                my @temp_array = @$value1;
                                                my %temp_hash = map { $_, 0 } @temp_array;
                                                @uniq_value = keys %temp_hash;
                                                push @{$hash1_{$key1}} , @uniq_value;
                  } # While Loop Closed for uniq array in HASH1
				  #print Dumper(\%hash1);
				  
#______________________________________________________________________________________________________________________________________________________________________
				  
				  
				  foreach my $key ( keys %hash )
					
					{
					
					undef $table_nam;
					$table_nam = $key."_RAW";
					chomp($table_nam);
					print "Table name: *****$table_nam\n";
					#print $Outputfile "$table_nam\n";
					
					my $query_array = join(',', @{$hash1{$key}});
					#print "$query_array\n";
                    my $datetimeid = $today."10:00:00";
					
					#print $Outputfile "$query_array\n";
					
					if ($table_nam =~ m/\w*_V_RAW/)
					
					{
					 
							if ($table_nam =~ m/DC_E_ERBS_\w*_V_RAW/){
							$datetimeid = $today."11:00:00";
							$query2 = "select ".$query_array." from ".$table_nam." WHERE DATETIME_ID ='$datetimeid' and DCVECTOR_INDEX = 1;" ;
							}
							else {
							$datetimeid = $today."10:00:00";
							$query2 = "select ".$query_array." from ".$table_nam." WHERE DATETIME_ID ='$datetimeid' and DCVECTOR_INDEX = 1;" ;
							
							}
					
					}
					
					else {
							if ($table_nam =~ m/DC_E_ERBS_\w*_RAW/){
							$datetimeid = $today."11:00:00";
							$query2 = "select ".$query_array." from ".$table_nam." WHERE DATETIME_ID ='$datetimeid';" ;
							}
							else {
							$datetimeid = $today."10:00:00";
							$query2 = "select ".$query_array." from ".$table_nam." WHERE DATETIME_ID ='$datetimeid';" ;
					}
					}
					
						#print "$query2\n\n";
						my @res2 = executeSQL("dwhdb",2640,"dc",$query2,"ROW");
						
						                       
						
						if ( "$#{ res2 }" != "-1" )
						{
                        
						my @output2 = undef;
                        push (@output2 ,@res2);
						
						my @array11 = split (",",$query_array);
						my @array22 = split (" ","@output2");

						@result = map {( $_ , shift @array22 )} @array11;
						
											
						if (keys %hash = keys %hash1){
							my @quarray = @{$hash{$key}};
							my $final = "tagId:"."@quarray".","."@result \n";
							$final =~ s/ (([0-9]*[0-9]*)|([0-9]*[0-9]*.[0-9]*[0-9]*[0-9]*[0-9]*)) /:$1,/g;
							#$final =~ s/ (\d+)/:$1/g;
							
							print $Outputfile "$final";
							}
								else{
									print "FAIL\n";
										}
						
						
						#print "@result\n\n\n";
						#print $Outputfile "@result\n";						
												
						
						}
						else
						{
						$result .= "<tr><td align=left><font color=A52A2A><b>$table_nam</b></font></td><td align=left><font color=A52A2A><b>No Data present in the Table</b></font></td></tr>";
						}
						
				  }
				  close $Outputfile;
#______________________________________________________________________________________________________________________________________________________________________
					
					my $output_file1 = "/eniq/home/dcuser/epfg/CounterComparison/CountersTxt_$csv.csv";
					
					my $ta = ();
					
					open (DATA2_FILE , '<', $output_file2 ) or die "ERROR: Couldn't open file for writing '$output_file2' $! \n";
				
						while (<DATA2_FILE>) {
						
						chomp;
						
						my $brInt1 = 'notmodified';
						
						my @csv2 = split(/,/, $_);
						my $csv2_a = @csv2;
						#print "From 2nd file: $csv2[0]\n";

						open (DATA1_FILE , '<', $output_file1 ) or die "ERROR: Couldn't open file for writing '$output_file1' $! \n";
						while (<DATA1_FILE>) {
						
						chomp;
						
						my @csv1 = split(/,/, $_);
						my $csv1_a = @csv1;
						#print "From 1st file: $csv1[0]\n";

						if ( $csv1[0] eq $csv2[0] )
						{
						$brInt1 = 'modified';
						#print "$csv1[0]:$csv2[0]:$brInt1\n";
						my $pass = 0;
						my $fail = 0;
						
						
						for(my $match = 1; $match <= $csv1_a; ++$match)
						{
						
						my $check1 = $csv1[$match];
						#print "$check1\n";
						
						for(my $match = 1; $match <= $csv1_a; ++$match)
						{
						
						my $check2 = $csv2[$match];
						#print "$check2\n";
						
						if ($check1 eq $check2){
						$pass = $pass + 1;
						#print "$check1 and $check2 Comparison PASS\n";
						#print "$pass\n";
						
						}
						else{
						$fail = $fail + 1;
						#print "$check1 and $check2 Comparison FAIL\n";
						#print "$fail\n";
						}
						}
						}
						
						if ($csv1_a == $pass){
						$final_pass = $final_pass + 1;
						($not,$tag_tab) = $csv1[0] =~ m/(\w*:)(\w*)/;
							#%hash_comp_P = ($tag_tab => 'PASS');
							#print "$tag_tab:SUCCESS:$final_pass\n";
							#print Dumper(\%hash_comp_P);
							
							
							
							foreach $sam (keys %hash){
							
							$ta = $sam;
							my @sam1 = @{$hash{$sam}};
							my $new = "@sam1";
							#print "FROM POSITIVE : $new\n";
							if ($new eq $tag_tab){
							print "$ta:PASS\n";
							
							$result .= "<tr><td align=left><font color=008000><b>$ta</b></font></td><td align=left><font color=008000><b>PASS</b></font></td></tr>";
							}
							}
						
						}
						else{
						$final_fail = $final_fail + 1;
						($not,$tag_tab) = $csv1[0] =~ m/(\w*:)(\w*)/;
							%hash_comp_F = ($tag_tab => 'FAIL');
							#print "$tag_tab:FAILURE:$final_fail\n";
							#print Dumper(\%hash_comp_F);
						
							
							foreach $sam (keys %hash){
							
							$ta = $sam;
							my @sam1 = @{$hash{$sam}};
							my $new = "@sam1";
							#print "FROM NEGATIVE : $new\n";
							if ($new eq $tag_tab){
							print "$ta:FAIL\n";
							$result .= "<tr><td align=left><font color=FF0000><b>$ta</b></font></td><td align=left><font color=FF0000><b>FAIL</b></font></td></tr>";
							}
							}
						
						}
						}
						else {
						#print "$brInt1\n\n";
						}
						}
						close DATA1_FILE;
						}
				
#______________________________________________________________________________________________________________________________________________________________________
				
				my $final_file = "$RESULTPATH/COUNTER_DATA_VALIDATION.txt";
				open (my $finale , '>>', $final_file ) or die "ERROR: Couldn't open file for writing '$final_file' $! \n";
				
				 if ($final_fail > 0) {
				 print $finale "$strings=FAIL\n";
				 }
				 else{
				 print $finale "$strings=PASS\n";
				 }
#______________________________________________________________________________________________________________________________________________________________________
				$result .= "</table>";
				}
				
				
				}
elsif ($strings=~ m/(INTF_\w*)/){
print "$line: This is not a PM TP. This testcase is only for PM TP.\n\n\n";
}
else 
{
print "$line: This is not a PM TP. This testcase is only for PM TP.\n\n\n";
}				
				}

return $result;				
}

###################################################################################################################################################################

if($dataloadingmo eq "true")
   {
     my $report =getHtmlHeader();
	$report.="<h1> <font color=MidnightBlue><center> <u> COUNTER DATA VALIDATION </u> </font> </h1>";
	
	$report.=qq{<body bgcolor=GhostWhite> </body> <center> <table  BORDER="3" CELLSPACING="2" CELLPADDING="3" WIDTH="80%" >};
	$report.= "<tr>";
	$report.= "<td><font size = 2 ><b>START TIME:\t</td>";
	my $stime = getTime();
	 $report.= "<td><b>$stime\t</td>";
	 
	 my $result1=dataloadingmo();
	    	 
	 $report.= "<tr>";
	 $report.= "<td><font size = 2 ><b>END TIME:\t</td>";
     my $etime = getTime();
	 $report.= "<td><b>$etime\t</td>";
	 
	 $report.= "<tr>";
	 $report.= "<td><font size = 2 ><b>RESULT:\t</td>";
	 $report.= "<td><a href=\"#t1\"><font size = 2 color=green><b>PASS ($final_pass) / <a href=\"#t2\"><font size = 2 color=red><b>FAIL ($final_fail)</td>";
	 
	 $report.= "</table>";
	 $report.= "<br>";
	 
	 $report.="$result1";
	 # $report.=qq{<body bgcolor=GhostWhite> </body> <center> <table  BORDER="3" CELLSPACING="2" CELLPADDING="3" WIDTH="80%" >};
	 # $report.= "<tr>";
	 # $report.= "<td><font size = 2 ><b>$result1\t</td>";
	 # $report.= "</table>";
	 
     $report.= getHtmlTail();
     my $file = writeHtml("COUNTER_DATA_VALIDATION",$report);
	 print "PARTIAL FILE: $file\n"; 
     $dataloadingmo ="false";
   }