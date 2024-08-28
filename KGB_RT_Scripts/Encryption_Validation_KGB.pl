#!/usr/bin/perl
use strict;
use warnings;

#use IO::Uncompress::Unzip qw(unzip $UnzipError) ;

my $search_string = "build.number";
my $inputFile="/eniq/home/dcuser/Encryption_dir/install/version.properties";
my $temp_output   = "/eniq/home/dcuser/Encryption_dir";
my $path          = "/eniq/sw/installer";
my $zip_format    = ".zip";
my $tpi_format    = ".tpi";
my @array;
my $i;
my $strings;
my $r;
my $data_tp;
my $result;
my $cmd;
my $b;
my $techpack_without_format;
my $tmp;
my %perTPRes;
my $boRes;
my $installStatus;
my $eachTP;
my $techpack_without_exe;
my $tp_without_format;
my $RESULTPATH="/eniq/home/dcuser/ResultFiles";


print "*****Encryption Validation*****\n";										  
print "creating Encryption_dir temp folder \n";
system("mkdir -p Encryption_dir");
print "Created $temp_output temp folder \n";

open FILE, '<', 'data.txt'
  or die
  "Could not open 'data.txt', No such file found in the provided path $!\n";
@array = <FILE>;
my $count = @array;

print "\n--- List of TechPack in data.txt file : Total : $count TPs --- \n @array \n\n";

for ( $i = 0 ; $i < $count ; $i++ ) {
    undef $data_tp;
    $data_tp = shift @array;
    chomp $data_tp;
    $techpack_without_format = substr $data_tp, 0, index( $data_tp, '.' );
    $installStatus = '/eniq/sw/installer/TP_BO_Installation_Status.txt';
    open FILE1, '<', $installStatus
      or die
	"Could not open '$installStatus', No such file found in the provided path $!\n";
    my @tparray = <FILE1>;
	close(FILE1);

    foreach $eachTP (@tparray) {
        my ( $techPack, $insRes ) = split( ",", $eachTP );
        if ( $techPack eq $data_tp ) {
            chomp($insRes);
            chomp($techPack);
            if ( $insRes eq "PASSED" ) {
                if ( $techPack =~ m/(DC_\w*)/ ) {
                    foreach my $tp ($techPack) {

                        $techpack_without_exe = substr $tp, 0,
                          index( $tp, '.' );
						my $file = "$path/$techpack_without_exe$tpi_format";
						if ( -f $file ) {
							system("mv $path/$techpack_without_exe$tpi_format $path/$techpack_without_exe$zip_format");
							my $zipfile = "$path/$techpack_without_exe$zip_format";
							print "Renamed the techPack from .tpi to zip format : $zipfile \n";

							print "Extracting..! $zipfile \n";
							my $console = system("unzip $zipfile -d $temp_output");
							print "Extracted $zipfile \n";

							system("rm /eniq/sw/installer/*.zip");
						
							print "Removed .zip files from  /eniq/sw/installer/  Path";
						
							open( FILE1, $inputFile );
							$_ = <FILE1>;
							close(FILE1);
							if ( $_ =~ /$search_string/ ) {
								print "$search_string string Found \n";
								if ( $tp =~ m/(^DC_\w*)/ ) {
									( $strings, $r, $b ) =
									  $tp =~ m/(DC_\w*)(\_R.+\_b)(\d+)/;
									$perTPRes{$strings} = "FAIL";
								}
								elsif ( $tp =~ m/(^INTF_DC\w*)/ ) {
									( $strings, $r, $b ) =
									  $tp =~ m/(INTF_DC\w*)(\_R.+\_b)(\d+)/;
									$perTPRes{$strings} = "FAIL";
								}
								elsif ( $tp =~ m/(^BO_\w*)/ ) {
									( $strings, $r, $b ) =
									  $tp =~ m/(BO_\w*)(\_R.+\_b)(\d+)/;
									$perTPRes{$strings} = "FAIL";
								}
							}
							else {
								print "$search_string is not Found \n";

								if ( $tp =~ m/(^DC_\w*)/ ) {
									( $strings, $r, $b ) =
									  $tp =~ m/(DC_\w*)(\_R.+\_b)(\d+)/;
									$perTPRes{$strings} = "PASS";
								}
								elsif ( $tp =~ m/(^INTF_DC\w*)/ ) {
									( $strings, $r, $b ) =
									  $tp =~ m/(INTF_DC\w*)(\_R.+\_b)(\d+)/;
									$perTPRes{$strings} = "PASS";
								}
								elsif ( $tp =~ m/(^BO_\w*)/ ) {
									( $strings, $r, $b ) =
									  $tp =~ m/(BO_\w*)(\_R.+\_b)(\d+)/;
									$perTPRes{$strings} = "PASS";
								}
							}
						} else {
							print "Not able to find the file: $file \n";
						}
						system("rm -fr $temp_output/*");
                        print "Removed all temp files \n";
                    }
                }
            }
            elsif ( $insRes eq "FAILED" ) {
                if ( $techPack =~ m/(^DC_\w*)/ ) {
                    ( $strings, $r, $b ) =
                      $techPack =~ m/(DC_\w*)(\_R.+\_b)(\d+)/;
                    $perTPRes{$strings} = "FAIL";
                }
                elsif ( $techPack =~ m/(^INTF_DC\w*)/ ) {
                    ( $strings, $r, $b ) =
                      $techPack =~ m/(INTF_DC\w*)(\_R.+\_b)(\d+)/;
                    $perTPRes{$strings} = "FAIL";
                }
                elsif ( $techPack =~ m/(^BO_\w*)/ ) {
                    ( $strings, $r, $b ) =
                      $techPack =~ m/(BO_\w*)(\_R.+\_b)(\d+)/;
                    $perTPRes{$strings} = "FAIL";
                }
            }
        }
    }
    writeResult("Encryption");
}

sub writeResult {
    my $filename = "$RESULTPATH/" . $_[0] . ".txt";
    open( my $fhandle, ">", $filename ) or die "Couldn't open: $!";
    foreach my $tp ( keys %perTPRes ) {
        print "$tp=$perTPRes{$tp}\n";
        print $fhandle "$tp=$perTPRes{$tp}\n";
    }
    close $fhandle;
}


system("rmdir Encryption_dir");
print "removed temp Encryption_dir\n";