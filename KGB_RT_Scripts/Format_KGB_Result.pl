#!/usr/bin/perl

use strict;
use warnings;

my ($sec,$min,$hour,$mday,$mon,$year,$wday,$yday,$isdst) = localtime(time);
$mon++;
$year = 1900 + $year;
my $datenew = sprintf("%4d%02d%02d%02d%02d%02d",$year,$mon,$mday,$hour,$min,$wday);
my $ResultFile = "/eniq/home/dcuser/ResultFiles/KGB_RESULT_".$datenew;
my $RTResultFolder = "/eniq/home/dcuser/RegressionLogs/";
my $passRT = 0;
my $failRT = 0;
my $passKGB = 0;
my $failKGB = 0;

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

###################################################################################
# readRTResult
# Read testcase statistics from RT Regression Logs
sub readRTResult(){
	my $Hostname = getHostName();
	my $ReadResFile = $RTResultFolder.$Hostname.".html";
	open(RES,"cat $ReadResFile | grep '<a href=\"#t1\">PASS' |");
	my @resArray = <RES>;
	chomp(@resArray);
	close(RES);
	my $resScalar = join(" ",@resArray);
	($passRT,$failRT) = ($resScalar =~ m/<a href=\"#t1\">PASS \((\d+)\) \/ <a href=\"#t2\">FAIL \((\d+)\)/);
	print "PASS RT = ${passRT}\n";
	print "FAIL RT = ${failRT}\n";
}

###################################################################################
# readKGBResult
# Read testcase statistics from KGB Summary file
sub readKGBResult(){
	my $ReadResFile = $RTResultFolder."KGB_RT_SUMMARY.html";
	open(RES,$ReadResFile);
	my @resArray = <RES>;
	chomp(@resArray);
	close(RES);
	my $resScalar = join(" ",@resArray);
	$failKGB =()= $resScalar =~ /FAIL+/g;
	$passKGB =()= $resScalar =~ /PASS+/g;
	print "PASS KGB = $passKGB\n";
	print "FAIL KGB = $failKGB\n";
}

###################################################################################
# writeResultFile
# Write result statistics in ResultFile (KGB_RESULT_<timestamp>)
sub writeResultFile(){
	my $totalPass = $passRT + $passKGB;
	my $totalFail = $failRT + $failKGB;
	my $totalTCs = $totalPass + $totalFail;
	open(OUT," > $ResultFile");
	print OUT "TOTAL=$totalTCs\n";
	print OUT "PASS=$totalPass\n";
	print OUT "FAIL=$totalFail";
	close(OUT);
}

#########MAIN########
readRTResult();
readKGBResult();
writeResultFile();