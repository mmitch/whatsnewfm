#!/usr/bin/perl -w
#############################################################################
#
my $id="whatsnewfm.pl  v0.0.2  2000-08-03";
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
# 2000/08/03 -> BUGFIX: Comments in the "hot" database were deleted
#               after every run.
# 2000/08/03 -> A list of interesting applications is kept and you are
#               informed of updates of these applications.
#            -> Databases are locked properly.
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
#my $mailto="joe.user\@some.host";
my $mailto="mitch\@localhost";
#
#
# *==> Where are the databases located?
#
#my $db_old="/home/joeuser/database-old";
#my $db_hot="/home/joeuser/database-hot";
my $db_old="/home/mitch/perl/whatsnewfm/database-old";
my $db_hot="/home/mitch/perl/whatsnewfm/database-hot";
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
#############################################################################

#
# YOU DON'T NEED TO EDIT ANYTHING BEYOND...
#

#################[ define global variables (yuck!) ]#########################


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


####################[ generate current timestamp ]###########################


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


########################[ lock the databases ]###############################


open LOCK_OLD, ">$db_old.LOCK" or die "can't create lockfile \"$db_old.LOCK\": $!";
if (! flock(LOCK_OLD,LOCK_EX | LOCK_NB)) {
    print STDERR "Some other process has locked the 'old' database. I'll wait for my turn...\n";
    flock(LOCK_OLD,LOCK_EX) or die "can't lock lockfile: $!";
    print STDERR "...I\'ve got my lock, here we go\n";
}
seek(LOCK_OLD, 0, 2);
select((select(LOCK_OLD), $| = 1)[0]);
print LOCK_OLD "$$\n";

open LOCK_HOT, ">$db_hot.LOCK" or die "can't create lockfile\"$db_hot.LOCK\": $!";
if (! flock(LOCK_HOT,LOCK_EX | LOCK_NB)) {
    print STDERR "Some other process has locked the 'hot' database. I'll wait for my turn...\n";
    flock(LOCK_HOT,LOCK_EX) or die "can't lock lockfile: $!";
    print STDERR "...I\'ve got my lock, here we go\n";
}
seek(LOCK_HOT, 0, 2);
select((select(LOCK_HOT), $| = 1)[0]);
print LOCK_HOT "$$\n";


######################[	read the old database ]##############################


open DB, "<$db_old" or die "couldn't open 'old' database \"$db_old\": $!";
while (my $line=<DB>) {
    chomp $line;
    my ($number, $addition) = split /\t/, $line;
    if (defined $number) {
	$db_read++;
	if (($addition+$expire) >= $timestamp) {
	    $database{$number} = $addition;
	} else {
	    $db_expired++;
	}
    }
}
close DB or die "couldn't close 'old' database \"$db_old\": $!";


######################[	read the hot database ]##############################


open DB, "<$db_hot" or die "couldn't open 'hot' database \"$db_hot\": $!";
while (my $line=<DB>) {
    chomp $line;
    my ($number, $comment) = split /\t/, $line, 2;
    if ($number =~ /^[0-9]+$/) {
	$interesting{$number} = $comment;
	$db_read++;
	if (exists $database{$number}) {
	    delete $database{$number};
	    $db_read--;
	}
    }
}
close DB or die "couldn't close 'hot' database \"$db_hot\": $!";


####################[ process the email headers ]############################


while (<STDIN>) {
    last if /^$/;
    if (/^Subject:\s/) {
	$subject=$_;
    }
}


###########################[ open mailer ]###################################


open MAIL_NEW, "|$mail_cmd $mailto" or die "can't open mailer \"$mail_cmd\": $!";
open MAIL_HOT, "|$mail_cmd $mailto" or die "can't open mailer \"$mail_cmd\": $!";


######################[ process the email body ]#############################


$header=1;
$first_hot=1;
$first_new=1;

while (my $line=<STDIN>) {
    chomp $line;
    if (($header == 1) && ($line =~ /[ article details ]/)) {
	$header=0;
    } else {
	
	##################[ parse an entry ]#################################

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
	    $line =~ s/^.*freshmeat\.net\/redir\/homepage\///;
	    $line =~ s/\/$//;
	    $new_app{'app_id'} = $line;

	} elsif  ($line =~ /download:\s/) {
	    $line =~ s/^.*download:\s//;
	    $new_app{'download'} = $line;
	    $line =~ s/^.*freshmeat\.net\/redir\/download\///;
	    $line =~ s/\/$//;
	    $new_app{'app_id'} = $line;

	} elsif  ($line =~ /changelog:\s/) {
	    $line =~ s/^.*changelog:\s//;
	    $new_app{'changelog'} = $line;
	    $line =~ s/^.*freshmeat\.net\/redir\/changelog\///;
	    $line =~ s/\/$//;
	    $new_app{'app_id'} = $line;

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

	} elsif  ($line =~ /^\|\>\shttp:\/\/freshmeat.net\/news\//) {
	    $line =~ s/^\|\>\s//;
	    $new_app{'newslink'} = $line;
	    $letter++;

	    ############[ print a hot entry ]################################

	    if (exists $interesting{$new_app{'app_id'}}) {

		if ($first_hot == 1) {
		    $first_hot=0;
		    print MAIL_HOT "To: $mailto\n";
		    print MAIL_HOT "Subject: whatsnewfm.pl: Updates of interesting applications\n";
		    print MAIL_HOT "X-Loop: sent by whatsnewfm.pl daemon\n";
		    print MAIL_HOT "\n";
		    print MAIL_HOT "*" . "=" x 76 . "*\n";
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
		
	    }

	    ############[ print a new entry ]################################

	    elsif (! defined $database{$new_app{'app_id'}}) {

		$db_new++;
		$letter_new++;
		$database{$new_app{'app_id'}} = $timestamp;
		
		if ($first_new == 1) {
		    $first_new=0;
		    print MAIL_NEW "To: $mailto\n";
		    print MAIL_NEW $subject;
		    print MAIL_NEW "X-Loop: sent by whatsnewfm.pl daemon\n";
		    print MAIL_NEW "\n";
		    print MAIL_NEW "*" . "=" x 76 . "*\n";
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

		print MAIL_NEW "    magic id: $new_app{'app_id'}\n";

		print MAIL_NEW "\n*" . "=" x 76 . "*\n";
		
	    }
	    
	    %new_app=();
	}
    }
}


######################[	write the old database ]#############################


rename $db_old, "$db_old~" or die "couldn't back up 'old' database \"$db_old\": $!";
open DB, ">$db_old" or die "couldn't open 'old' database \"$db_old\": $!";
foreach my $key (sort keys %database) {
    if ($key =~ /^[0-9]+$/) {
	print DB "$key\t$database{$key}\n";
	$db_written++;
    } else {
	$db_new--;
    }
}
close DB or die "couldn't close 'old' database \"$db_old\": $!";


######################[	write the hot database ]#############################


rename $db_hot, "$db_hot~" or die "couldn't back up 'hot' database \"$db_hot\": $!";
open DB, ">$db_hot" or die "couldn't open 'hot' database \"$db_hot\": $!";
foreach my $key (sort { $interesting{$a} cmp $interesting{$b} } keys %interesting) {
    print DB "$key\t$interesting{$key}\n";
}
close DB or die "couldn't close 'hot' database \"$db_hot\": $!";


#######################[ unlock the databases ]##############################


flock(LOCK_HOT,LOCK_UN) or die "can't unlock lockfile: $!";
close LOCK_HOT          or die "can't close lockfile: $!";
unlink "$db_hot.LOCK"   or die "can't remove lockfile: $!";

flock(LOCK_OLD,LOCK_UN) or die "can't unlock lockfile: $!";
close LOCK_OLD          or die "can't close lockfile: $!";
unlink "$db_old.LOCK"   or die "can't remove lockfile: $!";


#########################[ print statistics ]################################


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


print MAIL_HOT << "EOF";

   This information has been brought to you by:
   $id

EOF

###########################[ close mailer ]##################################


close MAIL_NEW or die "can't close mailer \"$mail_cmd\": $!";
close MAIL_HOT or die "can't close mailer \"$mail_cmd\": $!";


###############################[ end ]#######################################

exit 0;
