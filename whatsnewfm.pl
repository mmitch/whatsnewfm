#!/usr/bin/perl -w
#############################################################################
#
my $id="whatsnewfm.pl  v0.2.5  2000-11-25";
#   Filters the fresmeat newsletter for 'new' or 'interesting' entries.
#   
#   Copyright (C) 2000  Christian Garbs <mitch@uni.de>
#                       Joerg Plate <Joerg@Plate.cx>
#                       Dominik Brettnacher <dominik@brettnacher.org>
#
#   This program is free software; you can redistribute it and/or modify
#   it under the terms of the GNU General Public License as published by
#   the Free Software Foundation; either version 2 of the License, or
#   (at your option) any later version.
#
#   This program is distributed in the hope that it will be useful,
#   but WITHOUT ANY WARRANTY; without even the implied warranty of
#   MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
#   GNU General Public License for more details.
#
#   You should have received a copy of the GNU General Public License
#   along with this program; if not, write to the Free Software
#   Foundation, Inc., 675 Mass Ave, Cambridge, MA 02139, USA.
#
#############################################################################
#
# v0.2.5
# 2000/11/25--> Freshmeat editorials are included in the list of new
#               applications.
#
# v0.2.4
# 2000/11/10--> Removed warnings that only appeared on Perl 5.6
#
# v0.2.3
# 2000/10/30--> Reacted to a change in the newsletter format (item name).
# 2000/10/08--> "add" and "del" give more verbose messages.
#
# v0.2.2
# 2000/09/20--> Added scoring of newsletters.
# 2000/09/19--> "add" and "del" produce affirmative messages.
#
# v0.2.1
# 2000/09/08--> BUGFIX: Statistic calculations at the end of a
#           |   newsletter were broken.
#           |-> You can "view" all entries in the 'hot' database.
#           `-> Configuration is read from a configuration file. The
#               script doesn't need to be edited any more.
#
# v0.2.0
# 2000/08/22--> BUGFIX: freshmeat has changed the newsletter format
# 2000/08/05--> Updates can be sent as one big or several small mails.
#
# v0.0.3
# 2000/08/04--> BUGFIX: No empty mails are sent any more.
#           `-> Display of help text
# 2000/08/03--> BUGFIX: Comments in the 'hot' database were deleted
#           |   after every run.
#           |-> Major code cleanup.
#           `-> You can "add" and "del" entries from the 'hot' database.
#
# v0.0.2
# 2000/08/03--> A list of interesting applications is kept and you are
#           |   informed of updates of these applications.
#           `-> Databases are locked properly.
#
# v0.0.1
# 2000/07/17--> generated Appindex link is wrong, thus it is removed.
#               The link can't be generated offline, because there is not
#               enough information contained in the newsletter.
# 2000/07/14--> removed the dot because "sendmail" will treat it as end 
#               of mail in the middle of the newsletter...
# 2000/07/12--> a dot before the separator line to allow copy'n'paste to
#               the "mail" program - bad idea[TM] (see 2000/07/14)
# 2000/07/11--> statistics are generated
# 2000/07/07--> it works
# 2000/07/06--> first piece of code
#
#
# $Id: whatsnewfm.pl,v 1.24 2000/11/25 12:10:20 mitch Exp $
#
#
#############################################################################



##########################[ import modules ]#################################


use strict;                     # strict syntax checking
use Fcntl ':flock';             # import LOCK_* constants


#####################[ declare global variables ]############################


# where to look for the configuration file:
my $configfile = "~/.whatsnewfmrc";

# global configuration hash:
my %config;

sub read_config ($);

###########################[ main routine ]##################################


if ($ARGV[0]) {

    if ($ARGV[0] eq "add") {

	shift @ARGV;
	read_config($configfile);
	add_entry(@ARGV);

    } elsif ($ARGV[0] eq "del") {

	shift @ARGV;
	read_config($configfile);
	remove_entry(@ARGV);

    } elsif ($ARGV[0] eq "view") {

	shift @ARGV;
	read_config($configfile);
	view_entries(@ARGV);

    } else {

	display_help();

    }

} else {

    read_config($configfile);
    parse_newsletter();

}

exit 0;


########################[ display help text ]################################


sub display_help
{
    print << "EOF";
$id

filter mode for newsletters (stdin -> stdout):
    whatsnewfm.pl

print the "hot" list to stdout:
    whatsnewfm.pl view

add one new application to the "hot" list:
    whatsnewfm.pl add <magic-id> [comment]
add multiple new applications to the "hot" list (from stdin):
    whatsnewfm.pl add

remove applications from the "hot" list:
    whatsnewfm.pl del <magic-id> [magic-id2] [magic-id3] [...]
or a list from stdin:
    whatsnewfm.pl del
EOF
}


##############[	view the entries in the 'hot' database ]#####################


sub view_entries
{
    my %db = read_hot();

    foreach my $project (keys %db) {

	print "$project\t$db{$project}\n";

    }

}


################[ add an entry to the 'hot' database ]#######################


sub add_entry
{
    lock_hot();

    my %hot = read_hot();

    if (@_) {

	my $project = lc shift @_;
	my $comment = join " ", @_;
	$comment = "" unless $comment;
	if (exists $hot{$project}) {
	    print "$project updated.\n";
	} else {
	    $hot{$project} = $comment;
	    print "$project added.\n";
	}

    } else {

	while (my $line=<STDIN>) {
	    chomp $line;
	    my ($project, $comment) = split /\s/, $line, 2;
	    $comment = "" unless $comment;
	    $project = lc $project;
	    if (exists $hot{$project}) {
		print "$project updated.\n";
	    } else {
		$hot{$project} = $comment;
		print "$project added.\n";
	    }
	}
	
    }
    
    my $hot_written = write_hot(%hot);

    release_hot();

    print "You now have $hot_written entries in your hot database.\n";
}


#############[ remove an entry from the 'hot' database ]#####################


sub remove_entry
{
    lock_hot();

    my %hot = read_hot();

    if (@_) {

	foreach my $project (@_) {
	    $project = lc $project;
	    if (exists $hot{$project}) {
		delete $hot{$project};
		print "$project deleted.\n";
	    } else {
		print "$project not in database.\n";
	    }
	}

    } else {

	while (my $line=<STDIN>) {
	    chomp $line;
	    my @projects = split /\s/, $line;
	    foreach my $project (@projects) {
		$project = lc $project;
		if (exists $hot{$project}) {
		    delete $hot{$project};
		    print "$project deleted.\n";
		} else {
		    print "$project not in database.\n";
		}
	    }
	}

    }

    my $hot_written = write_hot(%hot);

    release_hot();

    print "You now have $hot_written entries in your hot database.\n";
}


########################[ parse a newsletter ]###############################


sub parse_newsletter
{

    my $subject;
    my $header;
    my %database;
    my %new_app;
    my %interesting;

    my $hot_written = 0;
    my $db_written  = 0;
    my $db_expired  = 0;
    my $db_new      = 0;
    my $letter      = 0;
    my $letter_new  = 0;
    my $letter_article = 0;

    my @hot_applications = ();
    my @new_applications = ();

### generate current timestamp


    my $year = `$config{'DATE_CMD'} +%Y`;
    if ($? >> 8) {
	die "Could not get current date";
    }
    chomp $year;

    my $month = `$config{'DATE_CMD'} +%m`;
    if ($? >> 8) {
	die "Could not get current date";
    }
    chomp $month;

    my $timestamp = $month + $year*12;


### lock databases


    lock_old();
    lock_hot();


### read databases

    %database    = read_old();
    %interesting = read_hot();


### expire 'old' entries

    
    foreach my $number (keys %database) {
	if (($database{$number}+$config{'EXPIRE'}) < $timestamp) {
	    $db_expired++;
	    delete $database{$number};
	}
    }


### process email headers


    while (<STDIN>) {
	last if /^$/;
	if (/^Subject:\s/) {
	    $subject=$_;
	}
    }


### process email body


    $header=1;

    while (my $line=<STDIN>) {
	chomp $line;
	if (($header == 1) and ($line =~ /[ article details ]/)) {
	    $header=0;
	} else {
	    
### parse an entry

	    if ($line =~ /subject:\s/) {
		$line =~ s/^.*subject:\s//;
		$new_app{'subject'} = $line;

	    } elsif ($line =~ /name:\s/) {
		$line =~ s/^.*name:\s//;
		$new_app{'subject'} = $line;

	    } elsif  ($line =~ /added\sby:\s/) {
		$line =~ s/^.*added\sby:\s//;
		$new_app{'author'} = $line;

	    } elsif  ($line =~ /license:\s/) {
		$line =~ s/^.*license:\s//;
		$new_app{'license'} = $line;

	    } elsif  ($line =~ /category:\s/) {
		$line =~ s/^.*category:\s//;
		$new_app{'category'} = $line;

	    } elsif  ($line =~ /homepage:\s/) {
		$line =~ s/^.*homepage:\s//;
		$new_app{'homepage'} = lc $line;
		$line =~ s/^.*freshmeat\.net\/projects\///;
		$line =~ s/\/homepage\/$//;
		$new_app{'project_id'} = $line;

	    } elsif  ($line =~ /download:\s/) {
		$line =~ s/^.*download:\s//;
		$new_app{'download'} = lc $line;
		$line =~ s/^.*freshmeat\.net\/projects\///;
		$line =~ s/\/download\/$//;
		$new_app{'project_id'} = $line;

	    } elsif  ($line =~ /changelog:\s/) {
		$line =~ s/^.*changelog:\s//;
		$new_app{'changelog'} = lc $line;
		$line =~ s/^.*freshmeat\.net\/projects\///;
		$line =~ s/\/changelog\/$//;
		$new_app{'project_id'} = $line;

	    } elsif  ($line =~ /^description:$/) {
		while (my $line=<STDIN>) {
		    last if $line =~ /^$/;
		    $new_app{'description'} .= $line;
		}

	    } elsif  ($line =~ /^body:$/) {
		while (my $line=<STDIN>) {
		    last if $line =~ /^$/;
		    $new_app{'description'} .= $line;
		}
	    } elsif  ($line =~ /^changes:$/) {
		while (my $line=<STDIN>) {
		    last if $line =~ /^$/;
		    $new_app{'changes'} .= $line;
		}

	    } elsif  ($line =~ /^urgency:$/) {
		if (defined (my $line=<STDIN>)) {
		    chomp $line;
		    $new_app{'urgency'} .= $line;
		}

### this is for news articles and editorials
	    } elsif  ($line =~ /^\|\>\shttp:\/\/freshmeat.net\/news\//) {
		$line =~ s/^\|\>\s//;
		$new_app{'newslink'} = $line;
		undef $new_app{'project_id'};
		$letter_new++;
		$letter_article++;

		push @new_applications, { %new_app };
		%new_app=();

	    } elsif  ($line =~ /^\|\>\shttp:\/\/freshmeat.net\/projects\//) {
		$line =~ s/^\|\>\s//;
		$new_app{'newslink'} = $line;
		$letter++;

### save a 'hot' entry

		if (($new_app{'project_id'}) and (exists $interesting{$new_app{'project_id'}})) {

		    push @hot_applications, { %new_app };

		}

### save a 'new' entry if it is not already in the 'hot' list

		elsif ((! $new_app{'project_id'}) or ((! defined $database{$new_app{'project_id'}}) and (! exists $interesting{$new_app{'project_id'}}))) {

		    $letter_new++;

		    if (defined $new_app{'project_id'}) {
			$db_new++;
			$database{$new_app{'project_id'}} = $timestamp;
			push @new_applications, { %new_app };
		    }

		}
		
		%new_app=();
	    }
	}
    }


### write databases


    $db_written = write_old(%database);
    $db_new -= keys (%database) - $db_written;

    $hot_written = write_hot(%interesting);
    

### unlock databases


    release_hot();
    release_old();


### send mails

    mail_hot_apps(@hot_applications);
    mail_new_apps($subject, $letter, $letter_new, $letter_article, $hot_written, $db_new, $db_written, $db_expired, @new_applications);

}


#####################[ lock the 'old' database ]#############################


sub lock_old
{
    open LOCK_OLD, ">$config{'DB_OLD'}.LOCK" or die "can't create lockfile \"$config{'DB_OLD'}.LOCK\": $!";
    if (! flock(LOCK_OLD,LOCK_EX | LOCK_NB)) {
	print STDERR "Some other process has locked the 'old' database. I'll wait for my turn...\n";
	flock(LOCK_OLD,LOCK_EX) or die "can't lock lockfile: $!";
	print STDERR "...I\'ve got my lock, here we go\n";
    }
    seek(LOCK_OLD, 0, 2);
    select((select(LOCK_OLD), $| = 1)[0]);
    print LOCK_OLD "$$\n";
}


#####################[ lock the 'hot' database ]#############################


sub lock_hot
{
    open LOCK_HOT, ">$config{'DB_HOT'}.LOCK" or die "can't create lockfile\"$config{'DB_HOT'}.LOCK\": $!";
    if (! flock(LOCK_HOT,LOCK_EX | LOCK_NB)) {
	print STDERR "Some other process has locked the 'hot' database. I'll wait for my turn...\n";
	flock(LOCK_HOT,LOCK_EX) or die "can't lock lockfile: $!";
	print STDERR "...I\'ve got my lock, here we go\n";
    }
    seek(LOCK_HOT, 0, 2);
    select((select(LOCK_HOT), $| = 1)[0]);
    print LOCK_HOT "$$\n";
}


####################[ unlock the 'hot' database ]############################


sub release_hot
{
    flock(LOCK_HOT,LOCK_UN)          or die "can't unlock lockfile: $!";
    close LOCK_HOT                   or die "can't close lockfile: $!";
    unlink "$config{'DB_HOT'}.LOCK"  or die "can't remove lockfile: $!";
}


####################[ unlock the 'old' database ]############################


sub release_old
{
    flock(LOCK_OLD,LOCK_UN)          or die "can't unlock lockfile: $!";
    close LOCK_OLD                   or die "can't close lockfile: $!";
    unlink "$config{'DB_OLD'}.LOCK"  or die "can't remove lockfile: $!";
}


#####################[ read the 'hot' database ]#############################


sub read_hot
{
    my %db;
    open DB, "<$config{'DB_HOT'}" or die "couldn't open 'hot' database \"$config{'DB_HOT'}\": $!";
    while (my $line=<DB>) {
	chomp $line;
	my ($project, $comment) = split /\s/, $line, 2;
	if (defined $project) {
	    $db{lc $project} = $comment;
	}
    }
    close DB or die "couldn't close 'hot' database \"$config{'DB_HOT'}\": $!";

    return %db;
}


#####################[ read the 'old' database ]#############################


sub read_old
{
    my %db;

    open DB, "<$config{'DB_OLD'}" or die "couldn't open 'old' database \"$config{'DB_OLD'}\": $!";
    while (my $line=<DB>) {
	chomp $line;
	my ($project, $addition) = split /\s/, $line;
	if (defined $project) {
	    $db{lc $project} = $addition;
	}
    }
    close DB or die "couldn't close 'old' database \"$config{'DB_OLD'}\": $!";

    return %db;
}


#####################[ write the 'old' database ]############################


sub write_old
{
    my $written = 0;
    my %db = @_;
    rename $config{'DB_OLD'}, "$config{'DB_OLD'}~" or die "couldn't back up 'old' database \"$config{'DB_OLD'}\": $!";
    open DB, ">$config{'DB_OLD'}" or die "couldn't open 'old' database \"$config{'DB_OLD'}\": $!";
    foreach my $key (sort keys %db) {
	print DB (lc $key) . "\t$db{$key}\n";
	$written++;
    }
    close DB or die "couldn't close 'old' database \"$config{'DB_OLD'}\": $!";
    return $written;
}


#####################[ write the 'hot' database ]############################


sub write_hot
{
    my $written = 0;
    my %db = @_;
    rename $config{'DB_HOT'}, "$config{'DB_HOT'}~" or die "couldn't back up 'hot' database \"$config{'DB_HOT'}\": $!";
    open DB, ">$config{'DB_HOT'}" or die "couldn't open 'hot' database \"$config{'DB_HOT'}\": $!";
    foreach my $key (sort { $db{$a} cmp $db{$b} } keys %db) {
	$key = lc $key;
	print DB (lc $key) . "\t$db{$key}\n";
	$written++;
    }
    close DB or die "couldn't close 'hot' database \"$config{'DB_HOT'}\": $!";
    return $written;
}


######################[	close an "update" mail ]#############################

    
sub close_hot
{
    print MAIL_HOT << "EOF";
	
    This information has been brought to you by:
    $id
	    
EOF
    
    close MAIL_HOT or die "can't close mailer \"$config{'MAIL_CMD'}\": $!";
}


########################[ close a "new" mail ]###############################


sub close_new
{
    my ($letter, $letter_new, $letter_article, $hot_written, $db_new, $db_written, $db_expired) = @_;

    my $difference=$letter-$letter_new;
    print MAIL_NEW << "EOF";
	
    This newsletter has been filtered by:
    $id
	
    The newsletter originally contained $letter news items,
    $difference items have been filtered out, while $letter_article items were articles,
    so there are $letter_new items left in this mail.

    Your \'hot\' database has $hot_written entries.

    $db_expired entries from your 'old' database have expired,
    while $db_new items were added.
    Your 'old' database now has $db_written entries.
EOF
	    
    print MAIL_NEW "\n*" . "=" x 76 . "*\n";
    
    close MAIL_NEW or die "can't close mailer \"$config{'MAIL_CMD'}\": $!";
}


######################[	open an "update" mail ]##############################


sub open_hot
{
    my %new_app = @_;

    open MAIL_HOT, "|$config{'MAIL_CMD'} $config{'MAILTO'}" or die "can't open mailer \"$config{'MAIL_CMD'}\": $!";
    
    print MAIL_HOT "To: $config{'MAILTO'}\n";
    if ($config{'UPDATE_MAIL'} eq "single") {
	print MAIL_HOT "Subject: whatsnewfm.pl: Updates of interesting applications\n";
    } else {
	print MAIL_HOT "Subject: whatsnewfm.pl: Update: $new_app{'subject'}\n";
    }
    print MAIL_HOT "X-Loop: sent by whatsnewfm.pl script\n";
    print MAIL_HOT "\n";
    print MAIL_HOT "*" . "=" x 76 . "*\n";
}


########################[ open a "new" mail ]################################


sub open_new
{
    my $subject = $_[0];
    open MAIL_NEW, "|$config{'MAIL_CMD'} $config{'MAILTO'}" or die "can't open mailer \"$config{'MAIL_CMD'}\": $!";
    
    print MAIL_NEW "To: $config{'MAILTO'}\n";
    print MAIL_NEW $subject;
    print MAIL_NEW "X-Loop: sent by whatsnewfm.pl daemon\n";
    print MAIL_NEW "\n";
    print MAIL_NEW "*" . "=" x 76 . "*\n";
}


###################[ read the configuration file ]###########################


sub read_config($)
{
    my $config_file = $_[0];
    my @allowed_keys = ("MAILTO", "DB_OLD", "DB_HOT", "EXPIRE", "DATE_CMD",
			"MAIL_CMD", "UPDATE_MAIL");
    my @scores = ();

### look for config file
    $config_file =~ s/^~/$ENV{'HOME'}/;
    if (! -e $config_file) {
	die "configuration file \"$config_file\" not found!\n";
    }

### read the config file
    open CONF, "<$config_file" or
	die "could not open configuration file \"$config_file\": $!";

    while (my $line = <CONF>) {
	chomp $line;
	$line =~ s/\s+$//;
	$line =~ s/^\s+//;
	if (($line ne "") and ($line !~ /^\#/)) {
	    my ($key, $value) = split /=/, $line, 2;
	    if (exists $config{$key}) {
		warn "$0 warning:\n";
		warn "duplicate keyword \"$key\" in configuration file at line $.\n";
	    }
	    if ($value) {
		$key = uc $key;
		if (grep {/$key/} @allowed_keys) {
		    $config{$key} = $value;
		} elsif ($key eq "SCORE") {
		    
		    my ($score, $regexp) = split /\t/, $value, 2;
		    if ((! defined $regexp) or ($regexp eq "")) {
			warn "$0 warning:\n";
			warn "no REGEXP given in configuration file at line $.\n";
		    }
		    elsif ($score =~ /[+-]\d+/) {
			push @scores, { 'score' => $score, 'regexp' => $regexp };
		    } else {
			warn "$0 warning:\n";
			warn "SCORE value not numeric in configuration file at line $.\n";
		    }
		    
		} else {
		    warn "$0 warning:\n";
		    warn "unknown keyword \"$key\" in configuration file at line $.\n";
		}
	    } else {
		warn "$0 fatal error:\n";
		die "keyword \"$key\" has no value configuration file at line $.\n";
	    }
	}
	    
    }

    close CONF or die "could not close configuration file \"$config_file\": $!";

### is the config file complete?
    foreach my $key (@allowed_keys) {
	if (! exists $config{$key}) {
	    warn "$0 fatal error:\n";
	    die  "keyword \"$key\" is missing in configuration file \"$config_file\"\n";
	}
    }

### expand ~ to home directory
    $config{'DB_HOT'}   =~ s/^~/$ENV{'HOME'}/;
    $config{'DB_OLD'}   =~ s/^~/$ENV{'HOME'}/;
    $config{'DATE_CMD'} =~ s/^~/$ENV{'HOME'}/;
    $config{'MAIL_CMD'} =~ s/^~/$ENV{'HOME'}/;

    $config{'SCORE'} = \@scores;

}


######################[ mail all 'hot' entries ]#############################


sub mail_hot_apps()
{
    
    my @hot_applications = @_;
    my %new_app;
    my $first_hot = 1;

    while (@hot_applications) {
	
	%new_app = %{pop @hot_applications};
    
	
	if ($first_hot == 1) {
	    $first_hot=0;
	    open_hot(%new_app);
	}
	
	if (defined $new_app{'subject'}) {
	    print MAIL_HOT "\n   $new_app{'subject'}\n\n";
	}
	
	if (defined $new_app{'description'}) {
	    print MAIL_HOT "$new_app{'description'}\n";
	}
	
	if (defined $new_app{'changes'}) {
	    print MAIL_HOT "     changes:";
	    if (defined $new_app{'urgency'}) {
		print MAIL_HOT " ($new_app{'urgency'} urgency)";
	    }
	    print MAIL_HOT "\n$new_app{'changes'}\n";
	}
	
	if (defined $new_app{'author'}) {
	    print MAIL_HOT "    added by: $new_app{'author'}\n";
	}
	
	if (defined $new_app{'license'}) {
	    print MAIL_HOT "     license: $new_app{'license'}\n";
	}
	
	if (defined $new_app{'category'}) {
	    print MAIL_HOT "    category: $new_app{'category'}\n";
	}
	
	if (defined $new_app{'homepage'}) {
	    print MAIL_HOT "    homepage: $new_app{'homepage'}\n";
	}
	
	if (defined $new_app{'download'}) {
	    print MAIL_HOT "    download: $new_app{'download'}\n";
	}
	
	if (defined $new_app{'changelog'}) {
	    print MAIL_HOT "   changelog: $new_app{'changelog'}\n";
	}
	
	if (defined $new_app{'newslink'}) {
	    print MAIL_HOT "     details: $new_app{'newslink'}\n";
	}
	
	print MAIL_HOT "\n*" . "=" x 76 . "*\n";

	if ($config{'UPDATE_MAIL'} ne "single") {
	    close_hot();
	    $first_hot=1;
	}
	
    }

### close mailer
    if ($first_hot == 0) {
	close_hot();
    }
}


######################[ mail all 'new' entries ]#############################


sub mail_new_apps()
{

    my ($subject, $letter, $letter_new, $letter_article, $hot_written, $db_new, $db_written, $db_expired, @new_applications) = @_;
    my %new_app;
    my $first_new = 1;

### do the scoring
    foreach my $app (@new_applications) {

	$app->{'score'} = 0;

	if (defined $app->{'description'}) {
	    foreach my $score ( @{$config{'SCORE'}}) {
		if ($app->{'description'} =~ /$score->{'regexp'}/i) {
		    $app->{'score'} += $score->{'score'};
		}
	    }
	}
    }

### sort by score
    @new_applications = sort { %{$a}->{'score'} <=> %{$b}->{'score'} } @new_applications;

    while (@new_applications) {
	
	%new_app = %{pop @new_applications};
	
	if ($first_new == 1) {
	    $first_new = 0;
	    open_new($subject);
	}

	if (defined $new_app{'subject'}) {
	    print MAIL_NEW "\n   $new_app{'subject'}\n\n";
	}

	if (defined $new_app{'description'}) {
	    print MAIL_NEW "$new_app{'description'}\n";
	}

	if (defined $new_app{'changes'}) {
	    print MAIL_NEW "     changes:";
	    if (defined $new_app{'urgency'}) {
		print MAIL_NEW " ($new_app{'urgency'} urgency)";
	    }
	    print MAIL_NEW "\n$new_app{'changes'}\n";
	}

	if (defined $new_app{'author'}) {
	    print MAIL_NEW "    added by: $new_app{'author'}\n";
	}

	if (defined $new_app{'license'}) {
	    print MAIL_NEW "     license: $new_app{'license'}\n";
	}

	if (defined $new_app{'category'}) {
	    print MAIL_NEW "    category: $new_app{'category'}\n";
	}

	if (defined $new_app{'homepage'}) {
	    print MAIL_NEW "    homepage: $new_app{'homepage'}\n";
	}

	if (defined $new_app{'download'}) {
	    print MAIL_NEW "    download: $new_app{'download'}\n";
	}

	if (defined $new_app{'changelog'}) {
	    print MAIL_NEW "   changelog: $new_app{'changelog'}\n";
	}

	if (defined $new_app{'newslink'}) {
	    print MAIL_NEW "   news item: $new_app{'newslink'}\n";
	}

	if (defined $new_app{'project_id'}) {
	    print MAIL_NEW "  project id: $new_app{'project_id'}\n";
	}

	if (defined $new_app{'score'}) {
	    print MAIL_NEW "       score: $new_app{'score'}\n";
	}

	print MAIL_NEW "\n*" . "=" x 76 . "*\n";
	     
    }
    
### close mailer
    if ($first_new == 0) {
	close_new($letter, $letter_new, $letter_article, $hot_written, $db_new, $db_written, $db_expired);
    }

}
