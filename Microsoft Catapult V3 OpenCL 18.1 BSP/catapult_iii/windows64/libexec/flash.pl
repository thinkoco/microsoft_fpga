
my $bin_file = $ARGV[1];
my $SFL_SOF = "$ENV{AOCL_BOARD_PACKAGE_ROOT}\\windows64\\libexec\\Catapult_v3_sfl.sof";

if ( $bin_file =~ m/\.bin$/i ) {
  -f $bin_file or print "Error: can't find $binfile file needed for flashing.\n" and exit 1;
} else {
  print "Error: Currently only .bin files are accepted.\n";
  print "       Please use the .bin from the original compiled project\n";
  exit 1;
}

if (-e $SFL_SOF){
}else{
    printf "Error: can't find $SFL_SOF file needed for flashing.\nPress any key to continue...\n";
    <STDIN>;
 	  exit 1;
}


&flash_programming($bin_file);

exit;

############################################
# Menu to select target page 
############################################

sub	flash_programming
{
	my $bin_file =  $_[0];	
	my $sof_file = "flash.sof";	
	my $jic_file = "flash.jic";	

	printf "Flash Programming...\n";		
		
	# extract .sof from fpga.bin
	&extract_sof($bin_file, $sof_file);	

	# generate jic
	system ("quartus_cpf -c -d EPCQL1024 -s 10AXF40AA -m ASx4 $sof_file $jic_file");
		$? == 0  or die "Error: quartus_cpf generate JIC failed \n";	

	# programming SFL"
	system ("quartus_pgm.exe -m jtag -c 1 -o \"p;$SFL_SOF\"");
		$? == 0  or die "Error: quartus_pgm SFL failed \n";			
		
	# programming EPCQ with .jic"
	system ("quartus_pgm.exe -m jtag -c 1 -o \"p;$jic_file\"");
		$? == 0  or die "Error: quartus_pgm JIC failed \n";
	
	# delete temporal files
	unlink $sof_file;
	unlink $jic_file;
	
	printf "press <Enter> to continue...";
	<STDIN>;

} # END of flash_programming

#############################
# extract .sof from .bin
sub	extract_sof
{

	my $bin_file = $_[0];
	my $sof_file = $_[1];
	
	system ("aocl binedit $bin_file get .acl.sof $sof_file");
	$? == 0  or die "Error: aocl binedit failed\n";

} #extract_sof
