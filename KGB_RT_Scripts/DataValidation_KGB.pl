#!/usr/bin/perl

use strict;
use warnings;
no warnings 'uninitialized';

use DBI;
use Data::Dumper;
use Text::CSV;

my $dataloadingmo = "true";
my $result;
my $report="";

my $LOGPATH="/eniq/home/dcuser/RegressionLogs";
my $RESULTPATH="/eniq/home/dcuser/ResultFiles";

#` rm -rf $LOGPATH/MO_DATA*.html`;

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
                print "executeSQL : $arg  $type $cre $port $dbname\n\n";
                
                my $connstr = "ENG=$dbname;CommLinks=tcpip{host=localhost;port=$port};UID=$cre;PWD=$cre";
			print $connstr;
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
				my $result;
                my $field;
				my %hash1;
                my %hash2;
                my %hash3;
                my %hash4;
				my %hashh2;
                my $query2;
				my $key;
				my $values;
				my $tp_name_arr;
				my $tp_name_arra;
				my $table_nam;
				#### ARRAY's
                my @result2;
                my @s_col_name;
                my @s_col_value;
                my @output2;
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
                
                my ($sec,$min,$hour,$mday,$mon,$year,$wday, $yday,$isdst)=localtime(time);
                my $today = sprintf "%4d-%02d-%02d ", $year+1900,$mon+1,$mday;
                #my $today = "2016-08-30 ";
                
                print "Today  Date is $today \n";
				#my $tp_query = "select distinct substr(typeid,1,charindex(':((',typeid)-1) as a from measurementcounter where a not like '%DWH_MONITOR%' and a not like '%DC_Z_ALARM%'and a not like '%DC_X_HWUTIL%' and a not like '%BULK_CM%'";
				#my $tp_names = executeSQL("repdb",2641,"dwhrep",$tp_query,"ALL");
				
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
				($strings,$r,$b) = $line  =~ m/(DC_E_\w*)(\_R.+\_b)(\d+)/;
				print "$strings\n";
				
				if ($strings=~ m/(DC_E_\w*)/)
				{
				
				foreach my $tp_names ($strings) {
				
				$result .= "<tr><td align=left><font color=black><font size=5px><b>TP NAME:</b></font></font></td><td align=left><font color=blue><font size=5px><b>$tp_names</b></font></font></td></tr>";
				$result .= "<br>";
	
                print "The TechPack/Node name is $tp_names \n\n";
        		my $query = "select distinct i.tagid, i.DATAFORMATID, di.dataname, di.dataid from DataFormat d join InterfaceMeasurement i on d.dataformatid=i.dataformatid join DataItem di on di.dataformatid=d.dataformatid where d.dataformatid like '%$tp_names%' and di.dataname not in('NE_NAME','OSS_ID','DATETIME_ID','DATE_ID','YEAR_ID','MONTH_ID','DAY_ID','HOUR_ID','MIN_ID','TIMELEVEL','SESSION_ID','BATCH_ID','PERIOD_DURATION','ROWSTATUS','DC_RELEASE','DC_SOURCE','DC_TIMEZONE','UTC_DATETIME_ID','DC_SUSPECTFLAG') and d.dataformatid not like '%DIM%'";
                my $res = executeSQL("repdb",2641,"dwhrep",$query,"ALL");
                
                for my $row ( @$res ) 
                    {
                                                my ( $tagid , $dataformatid, $dataname , $dataid ) = @$row;
                                                #my ( $dataformatid, $tagid , $dataname , $dataid ) = @$row;
                                                # hash1 contains tagid as key and tablename from dataformat id as value
                                                push @{$hash1{$tagid}}, lc ((split  /:/, $dataformatid)[2]);
                
                                                # hash2 has Dataformat id as key and all column names as value
												push @{$hashh2{$dataformatid}}, $dataname;
                                                #push @{$hash2{$dataformatid}}, $dataname;

					} # for loop my $row ( @$res ) CLOSED 
                #### While loop to remove the duplicates column names in HASH1
                while ( my ( $key1 , $value1) = each (%hash1)){
                                                my @uniq_value;
                                                my @temp_array = @$value1;
                                                my %temp_hash = map { $_, 0 } @temp_array;
                                                @uniq_value = keys %temp_hash;
                                                push @{$hash4{$key1}} , @uniq_value;
                  } # While Loop Closed for uniq array in HASH1
					#print Dumper(\%hash2);
                  
                #### While loop to remove the duplicates column names in HASHH2
                while ( my ( $key2 , $value2) = each (%hashh2)){
												my @temp_array = @$value2;
												my @uniq_value=uniq(@temp_array) ;
                                                push @{$hash2{$key2}} , @uniq_value;
                  } # While Loop Closed for uniq array in HASHH2
				#print Dumper(\%hash2);
                        foreach my $key ( keys %hash2 ){
                                    my $table_name = lc ((split  /:/, $key)[2]);    
												#my @s_array = @{$hash2{$key}};
												#my @sorted_array = sort @s_array;
                                                my $query_array = join(',', @{$hash2{$key}});
                                                my $datetimeid = $today."10:00:00";
						chomp($table_name);
						$table_name =~ s/ //g;
						#print "The TABLEEEEEE NAME FOR 3rd Query is $table_name \n\n";
						if ( $table_name !~ m/^dim/ || $table_name !~ m/^DIM*/ )
						{
							$table_nam = $table_name."_raw";
							#print "The TABLE NAME for DWHDB ISSSS <<<<<<<<<<<<<<<<<<>>>>>>>>>>>>>>> $table_nam \n\n";
						}
							
                        $query2 = "select ".$query_array.",DATETIME_ID from ".$table_nam." WHERE DATETIME_ID ='$datetimeid'" ;
                        my @res2 = executeSQL("dwhdb",2640,"dc",$query2,"ROW");

						if ( "$#{ res2 }" != "-1" )
						{
                                                
                        push (@output2 ,@res2);
     
						my @outputt = join(';', @output2) ;
                       #print "My outputt after the entering is @outputt \n";
						 foreach my $f_key (keys %hash4)
        						{
            							my ($f_val) = @{$hash4{$f_key}};
            							chomp($f_val);
             							#print "First_val(KEY) is $f_val, Second Key is $table_name\n";
             
								if ( $f_val =~ $table_name )
                    						{
                         						#print "If loop passed for $f_val, **** $table_name \n\n\n";
									my @s_col_name = split /,/, $query_array;
                        			#	for my $scn ( @s_value ){ @s_col_name = split /;/, $scn;push @s_col_name,'DATETIME_ID';
									#print "s_col_name >>> @s_col_name\n\n";}
									push @s_col_name, 'DATETIME_ID';
									for my $scv ( @outputt ){
											@s_col_value = split /;/, $scv;
											#print "output2 >>> @outputt\n\n";
										}
                                                			for(my $i=0;$i<=$#s_col_name;$i++){
                                                                                #print "$s_col_name[$i] ===== $s_col_value[$i] \n\n";
                                                                                push @{$hash3{$f_key}} , "$s_col_name[$i]".":"."$s_col_value[$i]";
                                                                		} #for loop with [i] CLOSED
                                             
            							} #if ( $f_val =~ $table_name ) CLOSED
							} # foreach my $f_key(keys %hash4) CLOSED
							@output2 =();
						} # if closed
						else{
						print "There is no result set for ". uc ($table_name) . "\n\n";
						$result.= "<p align=center><font size=3 color=ff0000><b>There is no result set for $table_name </b></font></p>";
						} #else closed
					} # foreach my $key ( keys %hash2 ) CLOSED	
					my ($sec,$min,$hour,$mday,$mon,$year,$wday, $yday,$isdst)=localtime(time);
					my $date = sprintf "%4d-%02d-%02d ", $year+1900,$mon+1,$mday;
					$date =~ s/ //g;
					my $output_file2 = "$tp_names"."_"."$date".".csv";
					print "The output file name asdfdasf is $output_file2 \n";
					open (Outputfile , '>', $output_file2 ) or die "ERROR: Couldn't open file for writing '$output_file2' $! \n";
                                	foreach my  $k ( keys %hash3){
											#print "Inside the outputfile \n";
                                        	#print Outputfile "********************************\n";
                                        	print Outputfile "tagid:"."$k"." "."@{$hash3{$k}}\n";
                                     			}
                    close Outputfile;
		############################# Starting the Comparision Function #################################
				my $output_file="/eniq/home/dcuser/"."$output_file2";
				#print "The output file name is $output_file \n";
				my $node_name = (split /DC_E_/ ,$tp_names)[1];
				my $input_file="/eniq/home/dcuser/epfg/CounterComparison/"."CountersTxt_"."$node_name".".csv";
				#print "The input file is $input_file \n";
				if ( -f $input_file )
				{
				my @output_array1=undef;
				my @input_array1=undef;
				open (my $DBOUTPUT , $output_file )or die "Can not open OUTPUT FILE $! \n";
				while(<$DBOUTPUT>){
							chomp($_);
							push (@output_array1 , $_);
				}
				close $DBOUTPUT;
				open(my $INPUT, $input_file) or die "There is no EPFG input file $! \n";
				while (<$INPUT>){
							chomp($_);
							push (@input_array1, $_);
				}
				close $INPUT;

				foreach(@output_array1)
				{
						my $output = $_;
						chomp $output;
						my @output_array = (split / /,$output);
						my $ouput_value_0 = (split / /,$output)[0];
						
						my $output_tag_id = (split /:/, $ouput_value_0)[1];
						
						foreach ( @input_array1 ){
									my $input = $_;
									chomp($input);
									my @input_array = (split /,/,$input);	
									my $input_value_0 = (split /,/,$input)[0];
									my $input_tag_id = (split /:/, $input_value_0)[1];
									
										chomp($input_tag_id);
										chomp($output_tag_id);
										$input_tag_id =~ s/\s//g;
										$output_tag_id =~ s/\s//g;
										
										#if(( $input_tag_id !~ s/^\s+// ) && ( $output_tag_id !~ s/^\s+// ) && ( $input_tag_id ne " " ) && ( $output_tag_id ne " " ))
										if ( ($input_tag_id) && ($output_tag_id) )
										{
										if( "$input_tag_id" eq "$output_tag_id" )
										{
										my $input_tag_id2 = uc ($input_tag_id);
										$result .= qq{<body bgcolor=GhostWhite> </body> <center> <caption align="center"> $input_tag_id2 </caption> <table  BORDER="3" CELLSPACING="2" CELLPADDING="3" WIDTH="80%" > <tr> 	<th>COUNTER NAME</th> <th>STATUS</th> </tr>};
										
										#print "The input_tag_id  and output_tag_id are $input_tag_id , $output_tag_id \n";
										
										shift @input_array;
										shift @output_array;
										pop @output_array;
										pop @output_array;
									
										foreach ( @output_array ){
											
													my $ouput_counter_name = (split /:/,$_)[0];
													#print " My output counter NAme is $ouput_counter_name \n\n";
													my $output_counter_value = (split /:/,$_)[1];	
													#print " My output counter VALUE is $output_counter_value \n\n ";

												foreach ( @input_array ){
																					
														my $input_counter_name = (split/:/, $_)[0];
														#print " My input counter NAME is $input_counter_name \n\n";
														my $input_counter_value = (split /:/,$_)[1]; 
														#print "My input counter VALUE is $input_counter_value \n";
													chomp($input_counter_name);
													chomp($input_counter_value);
													chomp($ouput_counter_name);
													chomp($output_counter_value);
													$input_counter_name =~ s/\s//g;
													$input_counter_value =~ s/\s//g;
													$ouput_counter_name =~ s/\s//g;
													$output_counter_value =~ s/\s//g;
								if(  "$input_counter_name" eq "$ouput_counter_name" ){

									if ( ($output_counter_value) && (!$input_counter_value) )
									{
										$result .= "<tr><td align=center><b>$ouput_counter_name</b></td><td align=center><font color=DAA520><b>DEPRECATED</b></font></td></tr>";
									}
									elsif ("$input_counter_value" eq "$output_counter_value" ){

									$result .= "<tr><td align=center><b>$ouput_counter_name</b></td><td align=center><font color=green><b>PASSED</b></font></td></tr>";
											} 					#if ("$input_counter_value" eq "$output_counter_value" ) CLOSED
											else {
									$result .= "<tr><td align=center><b>$ouput_counter_name</b></td><td align=center><font color=red><b>FAILED</b></font></td></tr>";
										}
									}			# if( "$input_counter_name" eq "$ouput_counter_name" ) CLOSED	
								
							
						}					# foreach ( @input_array ) CLOSED	
												
					    }					# foreach ( @output_array ) CLOSED	
											
						} 					# if( $input_tag_id eq $output_tag_id ) CLOSED
						
						}				#if ( input and output) CLOSED
					 }						# foreach ( @input_array1 ) CLOSED
					 $result .= "</table>";
				}							# foreach ( @output_array1 ) CLOSED						
			
				} # if (-f filename) CLOSED
				else {
						print "The input file $input_file is not present.\n";
					}
				### Clearing the HASH's for next Run...
				%hash1=();
				%hash2=();
				%hashh2=();
				%hash3=();
				%hash4=();
				`rm -rf $output_file2`;
			}		 #For loop CLOSED for TABLE NAMES LIST 
			
}
else {
print "$line: This is not a PM TP. This testcase is only for PM TP.\n\n\n";
}
}
return $result;
}  # dataloadingmo CLOSED
#####################################################
if($dataloadingmo eq "true")
   {
     my $report =getHtmlHeader();
	$report.="<h1> <font color=MidnightBlue><center> <u> COUNTER LOADING TEST CASES </u> </font> </h1>";
	$result.="<h2> COUNTER LOADING TEST CASES </h2>";
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
	 #$report.= "<td><font size = 2 ><b>RESULT:\t</td>";
	 #$report.= "<td><a href=\"#t1\"><font size = 2 color=green><b>PASS ($pass) / <a href=\"#t2\"><font size = 2 color=red><b>FAIL ($fail) / <a href=\"#t3\"><font size = 2 color=DAA520><b>DEPRECATED ($depr)</td>";
	 #$report.= "<td><a href=\"#t1\"><font size = 2 color=660000><b>PASS ($pass) / <a href=\"#t2\"><font size = 2 color=006600><b>FAIL ($fail) </td>";
	 $report.= "</table>";
	 $report.= "<br>";
	 $report.= $result1;
	 $result.= $result1;
     $report.= getHtmlTail();
     my $file = writeHtml("MO_DATA_LOADING",$report);
	 print "PARTIAL FILE: $file\n"; 
     $dataloadingmo ="false";
   }
