#!/usr/bin/perl -w
#############################################################################
#
my $id="whatsnewfm.pl  v0.2.0  2000-08-22";
#   Filters the fresmeat newsletter for 'new' or 'interesting' entries.
#   
#   Copyright (C) 2000  Christian Garbs <mitch@uni.de>
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
# v0.2.0
# 2000/08/22 -> BUGFIX: freshmeat has changed the newsletter format
# 2000/08/05 -> Updates can be sent as one big or several small mails.
# v0.0.3
# 2000/08/04 -> BUGFIX: No empty mails are sent any more.
#            -> Display of help text
# 2000/08/03 -> BUGFIX: Comments in the "hot" database were deleted
#               after every run.
#            -> Major code cleanup.
#            -> You can "add" and "del" entries from the hot database.
# v0.0.2
# 2000/08/03 -> A list of interesting applications is kept and you are
#               informed of updates of these applications.
#            -> Databases are locked properly.
# v0.0.1
# 2000/07/17 -> generated Appindex link is wrong, thus it is removed.
#               The link can't be generated offline, because there is not
#               enough information contained in the newsletter.
# 2000/07/14 -> removed the dot because "sendmail" will treat it as end 
#               of mail in the middle of the newsletter...
# 2000/07/12 -> a dot before the separator line to allow copy'n'paste to
#               the "mail" program - bad idea[TM] (see 2000/07/14)
# 2000/07/11 -> statistics are generated
# 2000/07/07 -> it works
# 2000/07/06 -> first piece of code
#
#############################################################################
use strict;                     # strict syntax checking
use Fcntl ':flock';             # import LOCK_* constants
#############################################################################
#
# Please edit the following variables to your needs:
#
#
# *==> Who should get the mail with new programs?
#      Remember: write \@ instead of @   
#
my $mailto="joe.user\@some.host";
#
#
# *==> Where are the databases located?
#
my $db_old="/home/joeuser/database-old";
my $db_hot="/home/joeuser/database-hot";
#
#
# *==> After how many months does an entry in the "old" database expire?
#
my $expire=12;
#
#
# *==> Location of external programs:
#
my $date_cmd="/bin/date";
my $mail_cmd="/usr/lib/sendmail";
#
#
# *==> Collect updates in a single mail or send multiple mails?
#
my $update_mail="single";
#my $update_mail="multiple";
#
#############################################################################
#
# YOU DON'T NEED TO EDIT ANYTHING BEYOND...
#
#############################################################################


# $Id: whatsnewfm.pl,v 1.9 2000/08/22 20:57:13 mitch Exp $


###########################[ main routine ]##################################


if ($ARGV[0]) {

    if ($ARGV[0] eq "add") {
	shift @ARGV;
	add_entry(@ARGV);
    } elsif ($ARGV[0] eq "del") {
	shift @ARGV;
	remove_entry(@ARGV);
    } else {
	display_help();
    }

} else {

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


################[ add an entry to the 'hot' database ]#######################


sub add_entry
{
    lock_hot();

    my %hot = read_hot();

    if (@_) {

	my $number = shift @_;
	my $comment = join " ", @_;
	$comment = "" unless $comment;
	$hot{$number} = $comment;

    } else {

	while (my $line=<STDIN>) {
	    chomp $line;
	    my ($number, $comment) = split /\s/, $line, 2;
	    if ($number =~ /^[0-9]+$/) {
		$comment = "" unless $comment;
		$hot{$number} = $comment;
	    }
	}
	
    }
    
    write_hot(%hot);

    release_hot();
}


#############[ remove an entry from the 'hot' database ]#####################


sub remove_entry
{
    lock_hot();

    my %hot = read_hot();

    if (@_) {

	foreach my $number (@_) {
	    delete $hot{$number} if exists $hot{$number};
	}

    } else {

	while (my $line=<STDIN>) {
	    chomp $line;
	    my @numbers = split /\s/, $line;
	    foreach my $number (@numbers) {
		delete $hot{$number} if exists $hot{$number};
	    }
	}

    }

    write_hot(%hot);

    release_hot();
}


########################[ parse a newsletter ]###############################


sub parse_newsletter
{

    my $subject;
    my $header;
    my $first_hot;
    my $first_new;
    my %database;
    my %new_app;
    my %interesting;

    my $db_read    = 0;
    my $db_written = 0;
    my $db_expired = 0;
    my $db_new     = 0;
    my $letter     = 0;
    my $letter_new = 0;


### generate current timestamp


    my $year = `$date_cmd +%Y`;
    if ($? >> 8) {
	die "Could not get current date";
    }
    chomp $year;

    my $month = `$date_cmd +%m`;
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
	$db_read++;
	if (($database{$number}+$expire) < $timestamp) {
	    $db_expired++;
	    delete $database{$number};
	}
    }


### remove 'hot' entries from 'old' database


    foreach my $number (keys %interesting) {
	$db_read++;
	if (exists $database{$number}) {
	    delete $database{$number};
	    $db_read--;
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
    $first_hot=1;
    $first_new=1;

    while (my $line=<STDIN>) {
	chomp $line;
	if (($header == 1) && ($line =~ /[ article details ]/)) {
	    $header=0;
	} else {
	    
### parse an entry

	    if ($line =~ /subject:\s/) {
		$line =~ s/^.*subject:\s//;
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
		$new_app{'homepage'} = $line;
		$line =~ s/^.*freshmeat\.net\/projects\///;
		$line =~ s/\/homepage\/$//;
		$new_app{'project_id'} = $line;

	    } elsif  ($line =~ /download:\s/) {
		$line =~ s/^.*download:\s//;
		$new_app{'download'} = $line;
		$line =~ s/^.*freshmeat\.net\/projects\///;
		$line =~ s/\/download\/$//;
		$new_app{'project_id'} = $line;

	    } elsif  ($line =~ /changelog:\s/) {
		$line =~ s/^.*changelog:\s//;
		$new_app{'changelog'} = $line;
		$line =~ s/^.*freshmeat\.net\/projects\///;
		$line =~ s/\/changelog\/$//;
		$new_app{'project_id'} = $line;

	    } elsif  ($line =~ /^description:$/) {
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

	    } elsif  ($line =~ /^\|\>\shttp:\/\/freshmeat.net\/projects\//) {
		$line =~ s/^\|\>\s//;
		$new_app{'newslink'} = $line;
		$letter++;

### print a 'hot' entry

		if (($new_app{'project_id'}) && (exists $interesting{$new_app{'project_id'}})) {

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
			print MAIL_HOT "   news item: $new_app{'newslink'}\n";
		    }

		    print MAIL_HOT "\n*" . "=" x 76 . "*\n";
		    
		    if ($update_mail ne "single") {
			close_hot();
			$first_hot=1;
		    }

		}

### print a 'new' entry

		elsif ((! $new_app{'project_id'}) || (! defined $database{$new_app{'project_id'}})) {

		    $db_new++;
		    $letter_new++;
		    if (defined $new_app{'project_id'}) {
			$database{$new_app{'project_id'}} = $timestamp;
		    }
		    
		    if ($first_new == 1) {
			$first_new=0;
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
			
		    print MAIL_NEW "\n*" . "=" x 76 . "*\n";
		    
		}
		
		%new_app=();
	    }
	}
    }


### write databases


    $db_written = write_old(%database);
    $db_new -= keys (%database) - $db_written;

    write_hot(%interesting);


### unlock databases


    release_hot();
    release_old();


### close mailers


    if ($first_new == 0) {
	close_new($letter, $letter_new, $db_read, $db_new, $db_written, $db_expired);
    }
    
    if ($first_hot == 0) {
	close_hot();
    }

}


#####################[ lock the 'old' database ]#############################


sub lock_old
{
    open LOCK_OLD, ">$db_old.LOCK" or die "can't create lockfile \"$db_old.LOCK\": $!";
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
    open LOCK_HOT, ">$db_hot.LOCK" or die "can't create lockfile\"$db_hot.LOCK\": $!";
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
    flock(LOCK_HOT,LOCK_UN) or die "can't unlock lockfile: $!";
    close LOCK_HOT          or die "can't close lockfile: $!";
    unlink "$db_hot.LOCK"   or die "can't remove lockfile: $!";
}


####################[ unlock the 'old' database ]############################


sub release_old
{
    flock(LOCK_OLD,LOCK_UN) or die "can't unlock lockfile: $!";
    close LOCK_OLD          or die "can't close lockfile: $!";
    unlink "$db_old.LOCK"   or die "can't remove lockfile: $!";
}


#####################[ read the 'hot' database ]#############################


sub read_hot
{
    my %db;
    open DB, "<$db_hot" or die "couldn't open 'hot' database \"$db_hot\": $!";
    while (my $line=<DB>) {
	chomp $line;
	my ($number, $comment) = split /\s/, $line, 2;
	if ($number =~ /^[0-9]+$/) {
	    $db{$number} = $comment;
	}
    }
    close DB or die "couldn't close 'hot' database \"$db_hot\": $!";

    return %db;
}


#####################[ read the 'old' database ]#############################


sub read_old
{
    my %db;

    open DB, "<$db_old" or die "couldn't open 'old' database \"$db_old\": $!";
    while (my $line=<DB>) {
	chomp $line;
	my ($number, $addition) = split /\s/, $line;
	if (defined $number) {
	    $db{$number} = $addition;
	}
    }
    close DB or die "couldn't close 'old' database \"$db_old\": $!";

    return %db;
}


#####################[ write the 'old' database ]############################


sub write_old
{
    my $written = 0;
    my %db = @_;
    rename $db_old, "$db_old~" or die "couldn't back up 'old' database \"$db_old\": $!";
    open DB, ">$db_old" or die "couldn't open 'old' database \"$db_old\": $!";
    foreach my $key (sort keys %db) {
	print DB "$key\t$db{$key}\n";
	$written++;
    }
    close DB or die "couldn't close 'old' database \"$db_old\": $!";
    return $written;
}


#####################[ write the 'hot' database ]############################


sub write_hot
{
    my $written = 0;
    my %db = @_;
    rename $db_hot, "$db_hot~" or die "couldn't back up 'hot' database \"$db_hot\": $!";
    open DB, ">$db_hot" or die "couldn't open 'hot' database \"$db_hot\": $!";
    foreach my $key (sort { $db{$a} cmp $db{$b} } keys %db) {
	print DB "$key\t$db{$key}\n";
	$written++;
    }
    close DB or die "couldn't close 'hot' database \"$db_hot\": $!";
    return $written;
}


######################[	close an "update" mail ]#############################

    
sub close_hot
{
    print MAIL_HOT << "EOF";
	
    This information has been brought to you by:
    $id
	    
EOF
    
    close MAIL_HOT or die "can't close mailer \"$mail_cmd\": $!";
}


########################[ close a "new" mail ]###############################


sub close_new
{
    my ($letter, $letter_new, $db_read, $db_new, $db_written, $db_expired) = @_;

    my $difference=$letter-$letter_new;
    print MAIL_NEW << "EOF";
	
    This newsletter has been filtered by:
    $id
	
    The newsletter originally contained $letter news items,
    $difference items have been filtered out,
    so there are $letter_new items left in this mail.

    Your databases had $db_read entries.
    $db_expired entries have expired,
    while $db_new items were added.
    Your databases now have $db_written entries.
EOF
	    
    print MAIL_NEW "\n*" . "=" x 76 . "*\n";
    
    close MAIL_NEW or die "can't close mailer \"$mail_cmd\": $!";
}


######################[	open an "update" mail ]##############################


sub open_hot
{
    my %new_app = @_;

    open MAIL_HOT, "|$mail_cmd $mailto" or die "can't open mailer \"$mail_cmd\": $!";
    
    print MAIL_HOT "To: $mailto\n";
    if ($update_mail eq "single") {
	print MAIL_HOT "Subject: whatsnewfm.pl: Updates of interesting applications\n";
    } else {
	print MAIL_HOT "Subject: whatsnewfm.pl: Update: $new_app{'subject'}\n";
    }
    print MAIL_HOT "X-Loop: sent by whatsnewfm.pl daemon\n";
    print MAIL_HOT "\n";
    print MAIL_HOT "*" . "=" x 76 . "*\n";
}


########################[ open a "new" mail ]################################


sub open_new
{
    my $subject = $_[0];
    open MAIL_NEW, "|$mail_cmd $mailto" or die "can't open mailer \"$mail_cmd\": $!";
    
    print MAIL_NEW "To: $mailto\n";
    print MAIL_NEW $subject;
    print MAIL_NEW "X-Loop: sent by whatsnewfm.pl daemon\n";
    print MAIL_NEW "\n";
    print MAIL_NEW "*" . "=" x 76 . "*\n";
}

