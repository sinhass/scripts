#!/usr/bin/perl -w
use strict;
#standard stuff

# This program is suppossed to be GPL software
# you should get a README and a CHANGELOG along with this
# Created by Bill Barry

#TODO: look up how you are suppossed to distribute GPL (what needs to be written at the top of files and such)


##################################################################################################
#Program Header: sets up command line arguments, and declares 
#functions and variables for future use
#
#

#Misc todo's
#TODO: Make program read default host and service configuration options from a file with the name $subnet.template


#IO::Socket is used to retrieve the ip address for some given fdqn
use IO::Socket;

#this is intended to be a Nagios plugin
use lib "nagios/plugins";

#All perl Nagios plugins should use these values:
use utils qw(%ERRORS &print_revision &support);
use vars qw($PROGNAME);

#All Nagios plugins should have a timeout
my ($TIMEOUT) = 20; #needs to be this long, might even need to be bigger

#Set up variables for command line arguments
my ($verbose,$nowrite,$writescreen) = (0,0,0);
my ($opt_V,$opt_h) = (0,0);

#TODO: talk to Nagios plugin developers (This is be a var that utils should provide)
my ($REVISION);
my ($PATH_TO_TRACEROUTE) = "/usr/sbin/traceroute ";
my ($PATH_TO_FPING) = "/usr/sbin/fping ";

# This defines where very verbose mode ends and very-very-verbose mode begins
my ($verbose_threshold) = 2;

my ($error_redirect) = "/dev/null";

$PROGNAME = "check_find_new_hosts";
$REVISION = 'Version: 1.0.2 $ ';

#foward declarations to make the code easier to read
sub print_help ();
sub print_usage ();

#These were in check-rpc, so I copied them over here, I am not sure why I have them here
#The code runs perfectly fine without them.
$ENV{'BASH_ENV'}=''; 
$ENV{'ENV'}='';
$ENV{'PATH'}='';
$ENV{'LC_ALL'}='C';

#finally a little code: Getopt parses the command line for the arguments it provides
#and Getopt::Long makes more sense to me than the normal Getopt does.
#TODO: add timeout options
use Getopt::Long;
Getopt::Long::Configure('bundling');
GetOptions(
	"V"   => \$opt_V,   "version"    => \$opt_V,
	"h"   => \$opt_h,   "help"       => \$opt_h,
 	"v+"  => \$verbose, "verbose+"   => \$verbose,
	"x"   => \$nowrite, "nowrite"	 => \$nowrite,
	"s"   => \$writescreen, "stdout"	 => \$writescreen,
);

#don't go on if there is an unknown option(print usage statement and quit)
if ($Getopt::Long::error) {
	print_usage();
	exit $ERRORS{'UNKNOWN'}; 
}

# -h means display help screen (more verbose than usage, but can be made more verbose by using -v)
if ($opt_h) { 
	print_help(); 
	exit $ERRORS{'OK'}; 
}

# -V means display version number
if ($opt_V) { 
	print_revision($PROGNAME,$REVISION); 
	exit $ERRORS{'OK'}; 
}

if ($verbose > $verbose_threshold) {
	$error_redirect = "&1";
}

#Just in case of problems, let's not hang Nagios, instead configure a timeout
 $SIG{'ALRM'} = sub {
         print ("ERROR: Program timed out (set a higher timeout or use a higher netmask) (alarm)\n");
         exit $ERRORS{"UNKNOWN"};
 };
 alarm($TIMEOUT);

#there should be 4 more arguments here, in the following order:
# /directory address netmask contact_group
#TODO: make code more robust and figure out which argument is which
if($#ARGV != 3 ) {
	print_usage();
	exit $ERRORS{"UNKNOWN"};
}
my ($address_list_dir,$subnet,$netmask,$contact_group) = @ARGV;

##################################################################################################
#Function implementations
#
#

#Function:
#	exit_error
#Reason for existance:
#	for exiting the program prematurely upon an error in some code
#Preconditions:
#	First (only) argument is a string containing the error
#Postconditions:
#	Program is ended
#Side effects:
#	Information printed to the screen
sub exit_error {
	print shift;
	exit $ERRORS{"UNKNOWN"};
}

#Function:
#	print_help
#Reason for existance:
#	Prints the help screen
#Preconditions:
#	$verbose may be set and does different things depending on value
#	$PROGNAME must be set and would only make sense to be the name of the program
#	$REVISION must be set
#Postconditions:
#	None
#Side effects:
#	Information printed to the screen
sub print_help() {
	print_revision($PROGNAME,$REVISION); 
	print "Copyright (c) 2005 Bill Barry\n";
	print "\n";
	print "Use the following to find new hosts on the network and write them to cfg files\n";
	print "\n";
	print_usage();
	print "\n";
	print "  /cfg_directory    The directory containing host and services for \n";
	print "                    the subnet you want to search.\n";
	print "  ip                An ip address in that subnet.\n";
	print "  netmask           A value [0..31] for the number of 1s in the netmask\n";
	print "                    e.g. 255.255.255.0 is 24 and 255.255.255.128 is 25\n";
	print "                        I wouldn't suggest a value below 24\n";
	if(!$verbose) {
		print "For more help try [-v -h] or [-v -v -h] or [-v -v -v -h]\n";
	}
	print "  [-v]            Verbose \n";
	print "  [-v -v]         Very Verbose \n";
	print "  [-v -v -v]      Very Very Verbose \n";
	print "  [-x]            Don't write config files\n";
	print "  [-s]            Write them to STDOUT\n";
	if($verbose) {
		print "\nFiles with the extension .skip are read and parsed by this program\n";
		print "so if you want to not include some ip address, let the program find it\n";
		print "and rename the file as a .skip extension\n\n";
		print "This program returns a warning as long as there are names in the\n";
		print "unknown group so delete them (from the group) to get rid of the warning.\n";
	}
	if($verbose > 1) {
		print "\n You can combine options like this to make it easier to type:\n";
		print "  $PROGNAME -vvh                  <= gives you this help screen.\n";
		print " Long options:\n";
		print "       -v  =  --verbose\n       -h  =  --help\n       -V  =  --version\n";
		print "       -x  =  --nowrite\n       -s  =  --stdout\n";
	}
	if($verbose > 2) {
		print "\nIf you need to contact me you can:\n";
		print "     post to the meulie.net forums\n";
		print "     contact me at http://after-fallout.deviantart.com/\n";
		print "     email me at after.fallout\@gmail.com\n";
		print "     AIM : after fallout\n\n";
		print "\n Email me with bugs / enhancements that you can think of.\n";
		print "\n For Current TO","DO list type: cat $PROGNAME | grep TO","DO\n";
# 		print "    Make program read default host and service configuration options from a file\n";
# 		print '    with the name $subnet.template',"\n\n";
	}
	print "\n";
# 	support();
}

#Function:
#	print_usage
#Reason for existance:
#	Prints the usage statements
#Preconditions:
#	$PROGNAME must be set and would only make sense to be the name of the program
#Postconditions:
#	None
#Side effects:
#	Information printed to the screen
sub print_usage () {
	print "Usage: \n";
	print " $PROGNAME [-v+] [-x] [-s] config_directory ip_address netmask contacts\n";
	print " $PROGNAME [-v+] [-h]\n";
	print " $PROGNAME [-V]\n";
}



#Function:
#	get_addresses
#Reason for existance:
#	Gets every computer that Nagios knows is currently on the network
#Preconditions:
#	$verbose may be set and has various side effects
#	arguments are a list of directories that have parsable files inside of them
#		whether they are .cfg files or .skip files
#Postconditions:
#	Scalar context:
#		returns a string containing "$resolved_name:$ip_address#$resolved_name:$ip_address#..."
#	List context:
#		returns a list of strings each containing "$resolved_name:$ip_address"
#Side effects:
#	If very-very-verbose mode is set, this prints some information to the screen
sub get_addresses { #(directory with cfgfiles)
	#this function will only be used where a return value is requested (no side effects)
	return unless defined wantarray;
	
	#initializing everything
	my ($dir,$computers,$addresses,@cfgfiles,$file,@computers,@addresses,$retval,@retval);
	$computers = "";
	$addresses = "";
	$retval = "";
	
	#parse each directory
	while (defined ($dir = shift)) {
		
		#open the directory, get the config files that are in the directory, 
		#and close the dir
		opendir(DIR, $dir) or exit_error "ERROR: can't opendir $dir: $!\n";
		@cfgfiles = grep { /\.cfg$/ or /\.skip$/ } readdir(DIR);
		closedir DIR;
		
		#parse each config file
		for $file (@cfgfiles) {
			#open the file, and look for lines containing the string "host{"
			open CONFIG, "$dir/$file" or exit_error "ERROR: can't open $dir/$file: $!\n";
			while(<CONFIG>) {
				if (/host{/) {
					#grab the next line
					# it is suppossed to look like this
					# host_name		name
					$_ = <CONFIG>;
					chomp;
					$_ =~ /((\w*[\-\.])*\w*\w)\s*$/;
					
					#add the name to , seperated a list of computers
					$computers=sprintf "%s,%s", $computers,$1;
					
					#skip a line and grab the ip address or the fdqn
					$_ = <CONFIG>;
					$_ = <CONFIG>;
					chomp;
					/((\w*[\-\.])*\w*\w)\s*$/;
					if ($verbose > $verbose_threshold) {
						print "$file $_\n";
					}
					$addresses=sprintf "%s,%s", $addresses,$1;
				}
			}
			#done with the config file
			close CONFIG;
		}
	}
	#get rid of the first value in the list store it in an array
	@computers = split /,/ , $computers;
	($_,@computers)=@computers;
	@addresses = split /,/ , $addresses;
	($_,@addresses)=@addresses;
	
	#begin creating the 2d array containing computer names and ip addresses
	for (0..$#computers) {
		if($addresses[$_] =~ /\..*\..*\./) {
			#it is an ip address
			$retval = sprintf "%s#%s:%s", $retval, $computers[$_],$addresses[$_];
		} else {
			#gets the address for a server that supplied a fdqn rather
			#than an ip address
			#This is why the line 
			#use IO::Socket;
			#is at the beginning of the program
			if ($verbose > $verbose_threshold) {
				print "$addresses[$_]\n";
			}
			my($addr)=inet_ntoa((gethostbyname($addresses[$_]))[4]);
			$retval = sprintf "%s#%s:%s", $retval, $computers[$_], $addr
		}
	}
	
	#get rid of the first value in the list store it in an array
	@retval = split /#/ , $retval;
	($_,@retval)=@retval;
	#if subroutine was called in scaler context then return a string with #'s seperating
	#the rows and : seperating the columns
	$retval = join "#", @retval;
	return wantarray ? @retval : $retval;
}

#Function:
#	cmpip
#Reason for existance:
#	numerically compares 2 ip addresses
#Preconditions:
#	the 2 arguments are both strings containing ipv4 addresses in x.x.x.x notation
#Postconditions:
#	returns -1 if the first argument is before the second, 0 if they are the same
#		and 1 if the first comes after the second (I think)
#Side effects:
#	None
sub cmpip {
	my ($ip1,$ip2) = @_;
	
	#split the addresses into 2 sets of 4 numbers
	my ($ip1a,$ip1b,$ip1c, $ip1d, $ip2a,$ip2b,$ip2c, $ip2d);
	($ip1a,$ip1b,$ip1c, $ip1d) = split /\./, $ip1;
	($ip2a,$ip2b,$ip2c, $ip2d) = split /\./, $ip2;
	
	#a monster return statement
	return ($ip1a <=> $ip2a or $ip1b <=> $ip2b or $ip1c <=> $ip2c or $ip1d <=> $ip2d);
}

#Function:
#	in
#Reason for existance:
#	says if a list has a value in it (compares as strings)
#Preconditions:
#	A list and a string are sent in in that order
#Postconditions:
#	returns 1 if the string is found in the list, 0 otherwise
#Side effects:
#	None
sub in {#parameters: (@list,$val_to_find)
	my ($tofind) = pop;
	for (@_) {
		return 1 if ($_ eq $tofind);
	}
	0;
}

#Function:
#	find_new
#Reason for existance:
#	finds new addresses on the network that Nagios doesn't know about
#Preconditions:
#	arguments are as follows: ip, netmask, sorted_list
#		ip is an ip address on the subnet that the user wants to discover
#		netmask is a value 0-31 that says how large the network is
#			see man fping for more information
#		sorted_list has a list of "name:ip" (sorted numerically by ip)
#	$verbose may be set and causes certain side effects
#	fping must be installed and located at /usr/sbin/fping
#Postconditions:
#	Scalar context:
#		returns a : seperated list of ip addresses
#	List context:
#		returns a list of ip addresses
#Side effects:
#	Network traffic is generated via /usr/sbin/fping
#	If $verbose is set some information may be printed to STDOUT
sub find_new {
	#this function will only be used where a return value is requested
	return unless defined wantarray;
	
	my ($subnet,$netmask,@list) = @_;
	#for splitting the ip addresses off of the list
	my (@used) = @list;
	#other variables needed
	my ($next_to_skip,$useless,$list,$error_redirect)=(0,0,"","/dev/null");
	
	#split them off
	for (0..$#list) {
		($useless,$used[$_]) = split /:/, $list[$_];
	}
	
	#the initial list has all ip's that respond and the final list doesn't have any that are in the other list
	my (@responsive_list_initial,@responsive_list_final);
	#the real work has already happened, props to whoever wrote fping
	#redirect standard error to null

#ATTEMPT TO FIX
#	@responsive_list_initial = `/usr/sbin/fping -a -r 1 -g $subnet/$netmask 2>/dev/null` or exit_error "ERROR: Cannot execute fping\n";
	open CMD , "$PATH_TO_FPING a -r 1 -g $subnet/$netmask 2>$error_redirect |" or exit_error "ERROR: Cannot execute fping\n";
	print "$PATH_TO_FPING a -r 1 -g $subnet/$netmask 2>$error_redirect |\n";
	#get rid of addresses that are in the other list
	@responsive_list_initial = <CMD>;
	for (@responsive_list_initial) {
#	while (<CMD>) {
		chomp;
		
		print "found : $_ \n" if ($verbose > $verbose_threshold);
		while (cmpip($used[$next_to_skip],$_) == -1) {
		
			print "comparing : $_ and $used[$next_to_skip]\n" if ($verbose > $verbose_threshold); #for very-very verbose mode
			$next_to_skip++;
		}
		if (cmpip($used[$next_to_skip],$_) == 0) {
		
			print "skipped : $_ \n" if ($verbose > $verbose_threshold);#for very-very verbose mode
			next;
		}
		
		print "added: $_ \n" if ($verbose > $verbose_threshold);#for very-very verbose mode
		#if it passed all those tests it can be added to the final list
		push @responsive_list_final,$_;
	}
	
	close CMD;
	#when called in scalar context return a : seperated list
	$list=join ':',@responsive_list_final;
	return wantarray ? @responsive_list_final : $list;
}


#Function:
#	get_info_from_ip
#Reason for existance:
#	retrieves information about a host using traceroute
#Preconditions:
#	a list of ip addresses is sent in as the arguments
#	$verbose may be set
#	traceroute is installed at /usr/sbin/traceroute
#Postconditions:
#	Scalar context:
#		returns a string containing "name:ip_address:parentname:parentip_address#name:ip_address:parentname:parentip_address#..."
#	List context:
#		returns a list of strings each containing "name:ip_address:parentname:parentip_address"
#Side effects:
#	Network traffic is generated via /usr/sbin/traceroute
#	If $verbose is set some information may be printed to STDOUT
#TODO: get information about running services on host (nmap)
sub get_info_from_ip {
	#this function will only be used where a return value is requested (no side effects)
	return unless defined wantarray;
	
	#these values are what is eventually returned
	my(@infolist,$infostring);
	
	#for each ip address
	for (@_) {
		#this is the information that the function looks for
		my ($name,$longname,$ip_addr,$parentname,$parentlongname,$parentip_addr);
# 		print "$_\n";
		#get each line from traceroute's standard output and redirect standard error to null
		my (@information) = ();
#OLD CODE
#		@information = `/usr/sbin/traceroute $_ 2>/dev/null`  or exit_error "ERROR: Cannot execute traceroute\n";
#		if ($verbose > $verbose_threshold) {
#			@information = `/usr/sbin/traceroute $_ `  or exit_error "ERROR: Cannot execute traceroute\n";
#			print @information;
#		}
		open CMD , "$PATH_TO_TRACEROUTE $_ 2>$error_redirect |"  or exit_error "ERROR: Cannot execute traceroute\n";
		@information = <CMD>;
		close CMD;
		print @information if ($verbose > $verbose_threshold);

		#get the longname (fdqn) and the ip or 2 copies of the ip, depending on what was returned
		$information[-1] =~ /\s\s(.*)\s\((.*)\)/;
		$longname = $1;
		$ip_addr = $2;
		
		#self explanitory
		if($longname eq $ip_addr) {
			#the longname is an ip address
			$longname =~ /.*\..*\.(.*\..*)/;
			#the resolved name should be the number pair of the 2 least significant numbers (0.1 in 10.0.0.1)
			$name = $1;
		} else {
			#it is a fdqn
			$longname =~ /(.*)\..*\..*/;
			#the resolved name is the computer name registered on the domain (asdf on asdf.jkl.com)
			$name = $1;
		}
		
		#if the host has a parent
		if($#information) {
			#get the information for the parent also (same code as above)
			$information[-2] =~ /\s\s(.*)\s\((.*)\)/;
			$parentlongname = $1;
			$parentip_addr = $2;
			if($parentlongname eq $parentip_addr) {
				$parentlongname =~ /.*\..*\.(.*\..*)/;
				$parentname = $1;
			} else {
				$parentlongname =~ /(.*)\..*\..*/;
				$parentname = $1;
			}
		} else {
			#the host has no parent so...
			$parentname = "";
			$parentip_addr = "";
		}
		#finished with this host, push it onto the list
		push (@infolist, (sprintf "%s:%s:%s:%s:%s",$name,$longname,$ip_addr,$parentname,$parentip_addr));
	}
	
	#if called in scalar context we need to concatonate
	$infostring=join '#',@infolist;
	return wantarray ? @infolist : $infostring;
}

#Function:
#	byipaddress
#Reason for existance:
#	enables sort to sort ip addresses numerically
#Preconditions:
#	$a and $b are strings containing "name:ip_address"
#Postconditions:
#	returns -1 if $a is before the $b, 0 if they are the same
#		and 1 if $a comes after $b (I think)
#Side effects:
#	None
sub byipaddress {
	my ($name1,$ip1,$name2,$ip2);
	($name1,$ip1) = split /:/, $a;
	($name2,$ip2) = split /:/, $b;
	return cmpip ($ip1,$ip2);
}

#Function:
#	writeconf_host_and_services
#Reason for existance:
#	write the host/service configuration file
#Preconditions:
#	arguments: FILE,ip,name,fdqn,USEFDQN,parents,contact_groups, 
#		and optionally (not coded yet) a list of services to check
#	FILE must be an opened file handle that is ready for output
#Postconditions:
#	None
#Side effects:
#	Information is printed to FILE
#TODO: write better service options
sub writeconf_host_and_services { #FILE,ip,name,fdqn,USEFDQN,parents,contact_groups,check_ports_1 
	my ($file) = shift;
	my ($ip_address,$resolved_name,$fdqn,$use_fdqn,$parents,$contact_groups,@open_ports) = @_;
	#host
	print $file "define host{\n";
	print $file "	host_name			$resolved_name\n";
	print $file "	alias				$fdqn\n";
	if($use_fdqn) {
		print $file "	address				$fdqn\n";
	} else {
		print $file "	address				$ip_address\n";
	}
	if(defined $parents) {
		print $file "	parents				$parents\n";
	}
	print $file "	check_command			check-host-alive\n";
	print $file "	max_check_attempts		5\n";
	print $file "	contact_groups			$contact_groups\n";
	print $file "	notification_interval		30\n";
	print $file "	notification_period		24x7\n";
	print $file "	notification_options		n\n	}\n\n";
	
	#service
	print $file "define service{\n";
	print $file "	use			generic-service\n";
	print $file "	host_name		$resolved_name\n";
	print $file "	service_description	PING\n";
	print $file "	is_volatile		0\n";
	print $file "	check_period		24x7\n";
	print $file "	max_check_attempts	3\n";
	print $file "	normal_check_interval	5\n";
	print $file "	retry_check_interval	1\n";
	print $file "	contact_groups		admin-500\n";
	print $file "	notification_interval	120\n";
	print $file "	notification_period	24x7\n";
	print $file "	notification_options	c,r\n";
	print $file "	check_command		check_ping!100.0,20%!500.0,60%\n";
	print $file "	}\n\n";
}

#Function:
#	writeconf_hostgroup
#Reason for existance:
#	write the hostgroup configuration file
#Preconditions:
#	arguments: #FILE,name1,name2,...
#	FILE must be an opened file handle that is ready for output
#Postconditions:
#	None
#Side effects:
#	Information is printed to FILE
sub writeconf_hostgroup { #FILE,name1,name2,...
	my ($file) = shift;
	my ($last) = pop;
	my (@most) = @_;
	print $file "define hostgroup {\n";
	print $file "	hostgroup_name		undefined\n";
	print $file "	alias			Non-Configured\n";
	print $file "	members			";
	for (@most) {
		print $file "$_,";
	}
	print $file "$last\n	}\n\n";
}

##################################################################################################
#Main expects everything to be set up (command line params) and to be called with 3 arguments:
#address_list_dir, subnet, and netmask
#
#
#Function:
#	main
#Reason for existance:
#	runs the program
#Preconditions:
#	arguments: directory to address list, ip address, netmask, contact_group
#		all arguments must be set up correctly
#	$verbose may be set
#	other command line options all are aready set up
#Postconditions:
#	Program is exited with return values vased on what was found on the network
#Side effects:
#	Information is printed to STDOUT
#	Information is printed to various files
sub main {
	my ($address_list_dir,$subnet,$netmask, $contact_group) = @_;
	
	my (@ip_list,@used,@information,@resolved_names);
	
	#get addresses nagios already knows about and sort it numerically
	@used = get_addresses $address_list_dir;
	@used = sort byipaddress @used;
	
	#print for very-very-verbose
	if ($verbose >= $verbose_threshold) {
		print "used hosts:\n--------------------------------------------------------\n";
		for (@used) {
			printf "Name:	%s	IP: %s \n" , split /:/;
		}
	}
	#get new addresses on the network
	@ip_list = find_new $subnet,$netmask,@used;
	
	#print for very-very-verbose
	if ($verbose >= $verbose_threshold) {
		print "\n\n\nto be added hosts:\n--------------------------------------------------------\n";
		for (@ip_list) {
			print "$_\n";
		}
	}
	
	#get information about new addresses
	@information = get_info_from_ip @ip_list;
	
	if ($verbose >= $verbose_threshold) {
		print "\n\n\nhost information:\n--------------------------------------------------------\n";
	}
	for (@information) {
		my($ip_address,$resolved_name,$fdqn,$use_fdqn,$parents,$contact_groups,@therest);
		($resolved_name,$fdqn,$ip_address,$parents,@therest) = split /:/;
 		
		if ($verbose >= $verbose_threshold) {
			print "Name: $resolved_name	fdqn/ip: $fdqn / $ip_address	parent:",(defined $parents ? $parents: "");
			print "\n";
		}
		if(!$nowrite) {
			open NEWCONFIG, ">", "$address_list_dir/$resolved_name.cfg" or print "Couldn't open $address_list_dir/$resolved_name.cfg";
 			writeconf_host_and_services *NEWCONFIG,$ip_address,$resolved_name,$fdqn,1,$parents,$contact_group;
 			close NEWCONFIG;
		}
		if (($verbose > $verbose_threshold) or $writescreen) {#very-very-verbose or stdout
			writeconf_host_and_services *STDOUT,$ip_address,$resolved_name,$fdqn,1,$parents,$contact_group; #maybe print very-very-verbose?
		}
		if(!in(@resolved_names,$resolved_name)) {
			push @resolved_names,$resolved_name;
		}
	}
	if(@resolved_names) {
		#before this starts writing hostgroup; add any hostgroups that are already in the unknown hostgroup
		if( -e "$address_list_dir/nagios_hostgroup_unknown.cfg") {
		
			open GROUP, "$address_list_dir/nagios_hostgroup_unknown.cfg";
			$_ = <GROUP>;
			if(/define/) {
				$_ = <GROUP>;
				$_ = <GROUP>;
				$_ = <GROUP>;
				chomp;
				/members\s*(.*)/;
				for (split /,/,$1) {
					if(!in(@resolved_names,$_)) {
						push @resolved_names,$_;
					}
				}
			}
		}
	
		#write the hostgroup file
		if(!$nowrite) {
			open GROUP, ">", "$address_list_dir/nagios_hostgroup_unknown.cfg" ;
			writeconf_hostgroup *GROUP,@resolved_names;
			close GROUP;
		}
		
		if (($verbose > $verbose_threshold) or $writescreen) {#very-very-verbose or stdout
			writeconf_hostgroup *STDOUT,@resolved_names;
		}
		if($verbose) {
			print ("WARNING: Hosts: ",join (", ",@resolved_names)," need to be configured.\n");
		} else {
			print "WARNING: New host(s) found and need to be configured.\n";
		}
		exit $ERRORS{'WARNING'}; 
	} else {
		if( -e "$address_list_dir/nagios_hostgroup_unknown.cfg") {
			if($verbose) {
				open GROUP, "$address_list_dir/nagios_hostgroup_unknown.cfg";
				$_ = <GROUP>;
				if(/define/) {
					$_ = <GROUP>;
					$_ = <GROUP>;
					$_ = <GROUP>;
					chomp;
					/members\s*(.*)/;
					print "WARNING: Hosts: $1 are in the unknown group.\n";
				}
			} else {
				print "WARNING: Check nagios_hostgroup_unknown.cfg for new hosts.\n";
			}
			exit $ERRORS{'WARNING'}; 
		}
		print "OK: No network changes occurred.\n";
		exit $ERRORS{'OK'}; 
	}
}







#this should be almost the last line in the program, just to make sure that everything runs correctly
#really nothing should happen after main runs except output for what nagios needs to know for its check
main ($address_list_dir,$subnet,$netmask,$contact_group);

print ("ERROR: Something really bad happenned, the code should never get here\n");
exit $ERRORS{"UNKNOWN"};
