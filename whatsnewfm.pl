#!/usr/bin/perl -w
#############################################################################
#
my $id="whatsnewfm.pl  v0.5.1-pre  2002-11-24";
#   Filters the freshmeat newsletter for 'new' or 'interesting' entries.
#   
#   Copyright (C) 2000-2002  Christian Garbs <mitch@cgarbs.de>
#                            Joerg Plate <Joerg@Plate.cx>
#                            Dominik Brettnacher <dominik@brettnacher.org>
#                            Pedro Melo Cunha <melo@isp.novis.pt>
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
# 2002/11/26--> Removed DATE_CMD backwards compatibility.
#
# v0.5.0
# 2002/11/24--> Removed file locking code.
#           |-> Changed all @arrays and %hashs to corresponding $references.
#           |-> Using BerkeleyDB::Hash for storage of databases.
#           |-> Added function prototypes.
#           `-> Added BerkeleyDB locking method.
# 2002/11/24--> Simpler computation of timestamp.  DATE_CMD not needed
#               any more.
# 2002/11/23--> Help text updates.
#
# v0.4.11
# 2002/11/19--> Removed warnings under Perl 5.8.0
#
# v0.4.10
# 2001/11/07--> BUGFIX: Newsletter format has changed.
#
# v0.4.9
# 2001/10/19--> BUGFIX: Corrected calculation of value $db_new in summary.
#           |   (bug is result of changes on 2001/10/01)
#           |-> Scoring of editorial articles is possible now.
#           `-> List of skipped articles can be shown.
# 2001/10/13--> Configuration file warnings are included in 'new' mails.
# 2001/10/01--> A news item that got filtered out because of a low score
#               is not added to the 'old' database so it will "reappear"
#               with the next release if you change your scoring rules.
# 2001/09/07--> BUGFIX: Test message didn't work.
#
# v0.4.8
# 2001/08/15--> BUGFIX: Categories were missing in 'hot' mails.
#
# v0.4.7
# 2001/08/10--> BUGFIX: Newsletter format has changed.
#
# v0.4.6
# 2001/07/28--> Scoring of Freshmeat Categories added.
# 2001/07/21--> Updated help text.
#
# v0.4.5
# 2001/07/19--> BUGFIX: Newsletter format has changed.
#
# v0.4.4
# 2001/06/23--> BUGFIX: Warning message about changed newsletter format
#               was not generated correctly.
# 2001/05/31--> "view" accepts optional regexp to filter the output.
#
# v0.4.3
# 2001/02/11--> Summary can be printed at top or bottom of a parsed
#               newsletter.
# 2001/02/08--> Comments from 'hot' database are included in 'hot' mails.
#           `-> BUGFIX: Existing comments in 'hot' database could not
#               be updated.
# 2001/02/07--> BUGFIX: URL was missing in articles.
#           `-> BUGFIX: Project ID was missing in 'hot' mails.
#
# v0.4.2
# 2001/02/05--> BUGFIX: freshmeat has changed the newsletter format.
#           |-> Improved detection of changes in newsletter format.
#           `-> Two releases of the same project within one newsletter
#               are handled correctly.
#
# v0.4.1
# 2001/02/02--> BUGFIX: A line with a single dot "." within freetext
#               fields (e.g. release details) caused sendmail to end
#               the mail at that point.
# 2001/01/31--> Changes in the newsletter format should be detected and
#               the user gets a warning mail telling him to update
#               whatsnewfm.
#
# v0.4.0
# 2001/01/31--> BUGFIX: freshmeat has changed the newsletter format.
#
# v0.2.6
# 2001/01/30--> New items with less than a specified score will not be shown.
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
# 2000/08/22--> BUGFIX: freshmeat has changed the newsletter format.
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
# $Id: whatsnewfm.pl,v 1.65 2002/12/02 21:55:13 mastermitch Exp $
#
#
#############################################################################



##########################[ import modules ]#################################


use strict;
use warnings;
use BerkeleyDB::Hash;


#####################[ declare global variables ]############################


# where to look for the configuration file:
my $configfile = "~/.whatsnewfmrc-dev";

# global configuration hash:
my $config;

# global database environment
my $db_env;

# information
my $whatsnewfm_homepages = [ "http://www.cgarbs.de/whatsnewfm.en.html" ,
			     "http://www.h.shuttle.de/mitch/whatsnewfm.en.html" ];
my $whatsnewfm_author = "Christian Garbs <mitch\@cgarbs.de>";

# configuration file
my $cfg_allowed_keys  = [
			 "DB_NAME",
			 "EXPIRE",
			 "LIST_SKIPPED",
			 "MAILTO",
			 "MAIL_CMD",
			 "SCORE_MIN",
			 "SUMMARY_AT",
			 "UPDATE_MAIL"
			 ];
my $cfg_optional_keys = [
			 "LIST_SKIPPED",
			 "SUMMARY_AT"
			 ];
my $cfg_warnings = [];

my $skipped_already_seen = [];
my $skipped_low_score = [];

my $separator = "*" . "="x76 . "*\n";

# main routine now at the bottom!


########################[ display help text ]################################


sub display_help()
{
    print << "EOF";
$id

filter mode for newsletters (reads from stdin):
    whatsnewfm.pl

print the "hot" list to stdout:
    whatsnewfm.pl view [regexp]

add one new application to the "hot" list:
    whatsnewfm.pl add <project id> [comment]
add multiple new applications to the "hot" list (from stdin):
    whatsnewfm.pl add

remove applications from the "hot" list:
    whatsnewfm.pl del <project id> [project id] [project id] [...]
or a list from stdin:
    whatsnewfm.pl del
EOF
}


##############[ view the entries in the 'hot' database ]#####################


sub view_entries(@)
{
    my $db = open_hot_db();

    if ($_[0]) {

	foreach my $project (keys %{$db}) {
	    my $line = "$project\t$db->{$project}";
	    if ($line =~ /$_[0]/i) {
		print "$line\n";
	    }
	}
	
    } else {
	
	foreach my $project (keys %{$db}) {
	    print "$project\t$db->{$project}\n";
	}

    }

    close_hot_db();

}


###############[ calculate the score for a news item ]#######################


sub do_scoring($)
{
    my $app = shift;

    $app->{'score'} = 0;

    if (defined $app->{'description'}) {
	foreach my $score ( @{$config->{'SCORE'}}) {
	    if ($app->{'description'} =~ /$score->{'regexp'}/i) {
		$app->{'score'} += $score->{'score'};
	    }
	}
    }
    
    if (defined $app->{'category'}) {
	foreach my $score ( @{$config->{'CATSCORE'}}) {
	    if ($app->{'category'} =~ /$score->{'regexp'}/i) {
		$app->{'score'} += $score->{'score'};
	    }
	}
    }
}


################[ add an entry to the 'hot' database ]#######################


sub add_entry(@)
{
    my $hot = open_hot_db();

    if (@_) {

	my $project = lc shift @_;
	my $comment = "";
	$comment = join " ", @_ if @_;
	if (exists $hot->{$project}) {
	    print "$project updated.\n";
	} else {
	    print "$project added.\n";
	}
	$hot->{$project} = $comment;

    } else {

	while (my $line=<STDIN>) {
	    chomp $line;
	    my ($project, $comment) = split /\s/, $line, 2;
	    $comment = "" unless $comment;
	    $project = lc $project;
	    if (exists $hot->{$project}) {
		print "$project updated.\n";
	    } else {
		print "$project added.\n";
	    }
	    $hot->{$project} = $comment;
	}
	
    }
    
    my $hot_written = close_hot_db($hot);

    print "You now have $hot_written entries in your hot database.\n";
}


#############[ remove an entry from the 'hot' database ]#####################


sub remove_entry(@)
{
    my $hot = open_hot_db();

    if (@_) {

	foreach my $project (@_) {
	    $project = lc $project;
	    if (exists $hot->{$project}) {
		delete $hot->{$project};
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
		if (exists $hot->{$project}) {
		    delete $hot->{$project};
		    print "$project deleted.\n";
		} else {
		    print "$project not in database.\n";
		}
	    }
	}

    }

    my $hot_written = close_hot_db($hot);

    print "You now have $hot_written entries in your hot database.\n";
}


########################[ parse a newsletter ]###############################


sub parse_newsletter()
{
    my $database;
    my $new_app;
    my $interesting;
    my $this_time_new;

    my $subject      = "Subject: Freshmeat Newsletter (no subject?)\n";
    my $position     = 3;
    # 3-> after mail header
    # 2-> within articles
    # 1-> after articles
    # 0-> within releases

    my $hot_written  = 0;
    my $db_written   = 0;
    my $db_expired   = 0;
    my $db_new       = 0;

    my $articles     = 0;
    my $releases     = 0;
    my $releases_new = 0;

    my $hot_applications = [];
    my $new_applications = [];



### generate current timestamp


    my ($sec,$min,$hour,$mday,$mon,$year,$wday,$yday,$isdst) =
	localtime(time);

    my $timestamp = ($mon+1) + ($year+1900)*12;


### read databases


    $database    = open_old_db();
    $interesting = open_hot_db();


### expire 'old' entries

    
    foreach my $number (keys %{$database}) {
	if (($database->{$number}+$config->{'EXPIRE'}) < $timestamp) {
	    $db_expired++;
	    delete $database->{$number};
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


    while (my $line=<STDIN>) {
	chomp $line;
	if (($position == 3) and ($line =~ /^::: A R T I C L E S \(\d+\) :::/)) {
	    $position = 2;
	} elsif (($position > 0) and ($line =~ /^::: R E L E A S E   D E T A I L S :::/)) {
	    $position = 0;
	} elsif ($position == 2) {
	    
### parse an article entry

	    # empty line
	    while ((defined $line) and ($line =~ /^\s*$/)) {
		$line=<STDIN>;
	    }
	    next unless defined $line;

	    # title
	    chomp $line;
	    $new_app->{'subject'} = $line;
	    $line=<STDIN>;
	    next unless defined $line;
	    
	    # from
	    if ($line =~ /^by /) {
		$line =~ s/^by //;
		chomp $line;
		$new_app->{'author'} = $line;
		$line=<STDIN>;
		next unless defined $line;
	    }

	    # section
	    if ($line =~ /^Section: /) {
		$line =~ s/^Section: //;
		chomp $line;
		$new_app->{'category'} = $line;
		$line=<STDIN>;
		next unless defined $line;
	    }

	    # date
	    chomp $line;
	    $new_app->{'date'} = $line;
	    $line=<STDIN>;
	    next unless defined $line;
	    
	    # empty line
	    while ((defined $line) and ($line =~ /^\s*$/)) {
		$line=<STDIN>;
	    }
	    next unless defined $line;

	    # text
	    $line =~ s/^\.$/. /; # sendmail fix
	    $new_app->{'description'} = $line;
	    while ($line=<STDIN>) {
		last if $line =~ /^\s$/;
		$line =~ s/^\.$/. /; # sendmail fix
		$new_app->{'description'} .= $line;
	    }

	    # empty line
	    while ((defined $line) and ($line =~ /^\s*$/)) {
		$line=<STDIN>;
	    }
	    next unless defined $line;

	    # URL
	    if ($line =~ /^\s*URL: /) {
		$line =~ s/^\s*URL: //;
		chomp $line;
		$new_app->{'newslink'} = $line;
		$line=<STDIN>;
		next unless defined $line;
	    }

	    # save it
	    undef $new_app->{'project_id'};
	    $articles++;
	    
	    do_scoring($new_app);

	    push @{$new_applications}, $new_app;
	    $new_app = {};

	    # wait for separator  (UGLY, change this routine somehow)
	    my $end = 0;
	    while ($end == 0) {
		chomp $line;
		if ($line =~ /- % -/) {
		    $end = 1;
		} else {
		    if ($line !~ /^\s*$/) {
			if (($line =~ tr/. -//c) == 0) {
			    $position = 1;
			    $end = 1;
			}		    
		    }
		}
		$line=<STDIN>;
		$end = 1 unless defined $line;
	    }

	} elsif ($position == 0) {
	    
### parse an release entry

	    # empty line
	    while ((defined $line) and ($line =~ /^\s*$/)) {
		$line=<STDIN>;
	    }
	    next unless defined $line;

	    my $release_nr;

	    # title
	    while ($line !~ /^\[\d+\] - /) {
		$line=<STDIN>;
		next unless defined $line;
	    }
	    $line =~ s/^(\[\d+\]) - //;
	    $release_nr = $1;
	    chomp $line;
	    $new_app->{'subject'} = $line;
	    $line=<STDIN>;
	    next unless defined $line;
	    
	    # from
	    if ($line =~ /^\s+by /) {
		$line =~ s/^\s+by //;
		chomp $line;
		$new_app->{'author'} = $line;
		$line=<STDIN>;
		next unless defined $line;
	    }

	    # date
	    chomp $line;
	    while ((defined $line) && ($line =~ /\(http:\/\/.*\)/ )) {
		# This is no date, but a multi-line "by" field!
		$new_app->{'author'} .= "\n              $line";
		$line=<STDIN>;
		chomp $line;
	    }
	    next unless defined $line;
	    $line =~ s/^\s+//;
	    $new_app->{'date'} = $line;
	    $line=<STDIN>;
	    next unless defined $line;
	    
	    # empty line
	    while ((defined $line) and ($line =~ /^\s*$/)) {
		$line=<STDIN>;
	    }
	    next unless defined $line;

	    # Category
	    if ($line !~ /^About: /) {
		chomp $line;
		$new_app->{'category'} = $line;
		while ($line=<STDIN>) {
		    last if $line =~ /^\s*$/;
		    chomp $line;
		    $new_app->{'category'} .= "," . $line;
		}
		$new_app->{'category'} = $line unless $line =~ /^\s*$/;
		$line=<STDIN>;
		next unless defined $line;

		# empty line
		while ((defined $line) and ($line =~ /^\s*$/)) {
		    $line=<STDIN>;
		}
		next unless defined $line;
	    }

	    # about
	    if ($line =~ /^About: /) {
		$line =~ s/^About: //;
		$line =~ s/^\.$/. /; # sendmail fix
		$new_app->{'description'} = $line;
		while ($line=<STDIN>) {
		    last if $line =~ /^\s*$/;
		    $line =~ s/^\.$/. /; # sendmail fix
		    $new_app->{'description'} .= $line;
		}
	    }

	    # empty line
	    while ((defined $line) and ($line =~ /^\s*$/)) {
		$line=<STDIN>;
	    }
	    next unless defined $line;

	    # changes
	    if ($line =~ /^Changes: /) {
		$line =~ s/^Changes: //;
		$line =~ s/^\.$/. /; # sendmail fix
		$new_app->{'changes'} = $line;
		while ($line=<STDIN>) {
		    last if $line =~ /^\s*$/;
		    $line =~ s/^\.$/. /; # sendmail fix
		    $new_app->{'changes'} .= $line;
		}
	    }

	    # empty line
	    while ((defined $line) and ($line =~ /^\s*$/)) {
		$line=<STDIN>;
	    }
	    next unless defined $line;

	    # License
	    if ($line =~ /^\s*License: /) {
		$line =~ s/^\s*License: //;
		chomp $line;
		$new_app->{'license'} = $line unless $line =~ /^\s*$/;
		$line=<STDIN>;
		next unless defined $line;
	    }

	    # empty line
	    while ((defined $line) and ($line =~ /^\s*$/)) {
		$line=<STDIN>;
	    }
	    next unless defined $line;

	    # URL
	    if ($line =~ /^\s*URL: /) {
		$line =~ s/^\s*URL: //;
		chomp $line;
		$new_app->{'project_link'} = $line;
		$line =~ s!/$!!;
		$line =~ s!^http://freshmeat.net/projects/!!;
		$new_app->{'project_id'} = $line;
		$line=<STDIN>;
		next unless defined $line;
	    }

	    $releases++;
	    do_scoring($new_app);
	    
	    ### save a 'hot' entry
	    
	    if (($new_app->{'project_id'}) and (exists $interesting->{$new_app->{'project_id'}})) {

		# also remember the comments from the hot database (if any)
		if ($interesting->{$new_app->{'project_id'}} !~ /^\s*$/) {
		    $new_app->{'comments'} = $interesting->{$new_app->{'project_id'}};
		}

		push @{$hot_applications}, $new_app;
		
	    } # LOOKOUT, there's an elsif coming!

	    ### save a 'new' entry if it is not already in the 'hot' list
	    ### if the same project appears twice in a newsletter, it is found
	    ### with %this_time_new (although %database is already set)
	    
	    elsif (((! exists $database->{$new_app->{'project_id'}}) or (exists $this_time_new->{$new_app->{'project_id'}})) and (! exists $interesting->{$new_app->{'project_id'}})) {
		
		$releases_new++;
		if ($new_app->{'score'} >= $config->{'SCORE_MIN'}) {
		    # only add when not scored out
		    $database->{$new_app->{'project_id'}} = $timestamp;
		    $this_time_new->{$new_app->{'project_id'}} = $timestamp;
		    $db_new++;
		}
		push @{$new_applications}, $new_app;
	    
	    } else {
		# already seen
		push @{$skipped_already_seen}, $new_app->{'subject'};
	    }

	    
	    # wait for separator  (UGLY, change this routine somehow)
	    my $end = 0;
	    while ($end == 0) {
		chomp $line;
		if ($line !~ /^\s*$/) {
		    if (($line =~ tr/- %//c) == 0) {
			$end = 1;
		    }	
		}
		$line=<STDIN>;
		$end = 1 unless defined $line;
	    }

	    $new_app = {};

	}
    }


### write databases


    $db_written = close_old_db($database);
    $db_new -= keys (%{$database}) - $db_written;

    $hot_written = close_hot_db($interesting);
    

### send mails

    mail_hot_apps($hot_applications);
    mail_new_apps($subject, $articles, $releases, $releases_new, $hot_written, $db_new, $db_written, $db_expired, $new_applications);

}


#################[ initialize database environment ]#########################


sub initialize_db_env()
{
    if (! defined $db_env) {
	$db_env = new BerkeleyDB::Env,
	{ -Flags => BerkeleyDB::DB_INIT_CDB
	  }
    }
}


#######################[ open 'hot' database ]###############################


sub open_hot_db()
{
    my %hash;

    initialize_db_env();

    tie %hash, 'BerkeleyDB::Hash',
    { -Filename => $config->{DB_NAME},
      -Subname => "hot",
      -Flags => BerkeleyDB::Hash::DB_CREATE
      };

    return \%hash;
}


#######################[ open 'old' database ]###############################


sub open_old_db()
{
    my %hash;

    initialize_db_env();

    tie %hash, 'BerkeleyDB::Hash',
    { -Filename => $config->{DB_NAME},
      -Subname => "old",
      -Flags => BerkeleyDB::Hash::DB_CREATE
      };

    return \%hash;
}


#####################[ write the 'old' database ]############################


sub close_old_db()
{
    my $db = shift;
    my $written = keys %{$db};
    untie %{$db};
    return $written;
}


#####################[ write the 'hot' database ]############################


sub close_hot_db()
{
    my $db = shift;
    my $written = keys %{$db};
    untie %{$db};
    return $written;
}


######################[ close an "update" mail ]#############################

    
sub close_hot()
{
    print MAIL_HOT << "EOF";
	
    This information has been brought to you by:
    $id
	    
EOF
    
    close MAIL_HOT or die "can't close mailer \"$config->{'MAIL_CMD'}\": $!";
}


##################[ format summary of a "new" mail ]#########################


sub get_summary($$$$$$$$)
{
    my ($articles, $releases, $releases_new, $hot_written, $db_new, $db_written, $db_expired, $score_killed) = @_;

    my $already_seen=@{$skipped_already_seen};
    my $difference=$releases-$releases_new-$already_seen;
    my $remaining=$releases_new+$articles-$score_killed;
    my $summary = << "EOF";
	
    This newsletter has been filtered by:
    $id

    It contained $articles articles and $releases releases.
EOF
    
    if ($releases > 1) {    # 1 release is not enough to ensure proper operation!

	$summary .= << "EOF";
    $already_seen releases have been skipped as 'already seen'.
    $score_killed articles or releases have been skipped as 'low score'.
    $remaining articles and releases are shown in this mail,
    while $difference releases have been sent separately as 'hot'.

EOF
    ;
	
    } else {
	$summary .= << "EOF";

 !! This mail did not contain more than 1 release.
 !! This is looks like an error.
 !! Perhaps the processed mail was no newsletter at all?
 !!
 !! If this error repeats within the next days then most likely the
 !! newsletter format has changed (or whatsnewfm is broken). You
 !! should then visit the whatsnewfm homepage and look for an 
 !! updated version of whatsnewfm.
 !!
 !! If there is neither a new version available nor a message that
 !! the error is already being fixed, please inform the author
 !! about the error you encountered.
 !!
 !! homepage:
EOF
    ;
	
	foreach my $whatsnewfm_homepage (@{$whatsnewfm_homepages}) {
	    $summary .= " !!     $whatsnewfm_homepage\n";
	}

	$summary .= << "EOF";
 !! author:
 !!     $whatsnewfm_author

EOF
    ;
    }
	
    $summary .= << "EOF";
    Your \'hot\' database has $hot_written entries.

    $db_expired entries from your 'old' database have expired,
    while $db_new items were added.
    Your 'old' database now has $db_written entries.
EOF
	    
    $summary .= "\n$separator";
    

    return $summary
}


######################[ open an "update" mail ]##############################


sub open_hot_mail($)
{
    my $new_app = shift;

    open MAIL_HOT, "|$config->{'MAIL_CMD'} $config->{'MAILTO'}" or die "can't open mailer \"$config->{'MAIL_CMD'}\": $!";
    
    print MAIL_HOT "To: $config->{'MAILTO'}\n";
    if ($config->{'UPDATE_MAIL'} eq "single") {
	print MAIL_HOT "Subject: whatsnewfm.pl: Updates of interesting applications\n";
    } else {
	print MAIL_HOT "Subject: whatsnewfm.pl: Update: $new_app->{'subject'}\n";
    }
    print MAIL_HOT "X-Loop: sent by whatsnewfm.pl script\n";
    print MAIL_HOT "\n";
    print MAIL_HOT "$separator";
}


########################[ open a "new" mail ]################################


sub open_new_mail($)
{
    my $subject = $_[0];
    open MAIL_NEW, "|$config->{'MAIL_CMD'} $config->{'MAILTO'}" or die "can't open mailer \"$config->{'MAIL_CMD'}\": $!";
    
    print MAIL_NEW "To: $config->{'MAILTO'}\n";
    print MAIL_NEW $subject;
    print MAIL_NEW "X-Loop: sent by whatsnewfm.pl daemon\n";
    print MAIL_NEW "\n";
    print MAIL_NEW "$separator";
}


###################[ read the configuration file ]###########################


sub read_config($)
{
    my $config_file = $_[0];
    my @scores = ();
    my @catscores = ();

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
	    if (exists $config->{$key}) {
		warn "$0 warning:\n";
		warn "duplicate keyword \"$key\" in configuration file at line $.\n";
		push @{$cfg_warnings}, "duplicate keyword \"$key\" at line $.";
	    }
	    if (defined $value) {
		$key = uc $key;

		if ($key eq "SCORE") {
		    
		    my ($score, $regexp) = split /\t/, $value, 2;
		    if ((! defined $regexp) or ($regexp eq "")) {
			warn "$0 warning:\n";
			warn "no REGEXP given in configuration file at line $.\n";
			push @{$cfg_warnings}, "no REGEXP given at line $.";
		    }
		    elsif ($score =~ /[+-]\d+/) {
			push @scores, { 'score' => $score, 'regexp' => $regexp };
		    } else {
			warn "$0 warning:\n";
			warn "SCORE value not numeric in configuration file at line $.\n";
			push @{$cfg_warnings}, "SCORE value not numeric at line $.";
		    }
		    
		} elsif ($key eq "CATSCORE") {
		    
		    my ($score, $regexp) = split /\t/, $value, 2;
		    if ((! defined $regexp) or ($regexp eq "")) {
			warn "$0 warning:\n";
			warn "no REGEXP given in configuration file at line $.\n";
			push @{$cfg_warnings}, "no REGEXP given at line $.";
		    }
		    elsif ($score =~ /[+-]\d+/) {
			push @catscores, { 'score' => $score, 'regexp' => $regexp };
		    } else {
			warn "$0 warning:\n";
			warn "SCORE value not numeric in configuration file at line $.\n";
			push @{$cfg_warnings}, "SCORE value not numeric at line $.";
		    }
		    
		} elsif (grep {$_ eq $key} @{$cfg_allowed_keys}) {
		    $config->{$key} = $value;
		} else {
		    warn "$0 warning:\n";
		    warn "unknown keyword \"$key\" in configuration file at line $.\n";
		    push @{$cfg_warnings}, "unknown keyword \"$key\" at line $.";
		}
	    } else {
		warn "$0 fatal error:\n";
		die "keyword \"$key\" has no value in configuration file at line $.\n";
	    }
	}
	    
    }

    close CONF or die "could not close configuration file \"$config_file\": $!";

### is the config file complete?
    foreach my $key (@{$cfg_allowed_keys}) {
	if (! exists $config->{$key}) {
	    if ( (grep { $_ eq $key } @{$cfg_optional_keys}) == 0) {
		warn "$0 fatal error:\n";
		die  "keyword \"$key\" is missing in configuration file \"$config_file\"\n";
	    } else {
		warn "$0 warning:\n";
		warn "using default value for \"$key\"\n";
		push @{$cfg_warnings}, "using default value for \"$key\"";
	    }
	}
    }

### default values
    $config->{'SUMMARY_AT'} = 'bottom' unless exists $config->{'SUMMARY_AT'}
                                                && $config->{'SUMMARY_AT'} 
                                                && lc($config->{'SUMMARY_AT'}) eq 'top';
    $config->{'LIST_SKIPPED'} = 'no'   unless exists $config->{'LIST_SKIPPED'}
                                                && $config->{'LIST_SKIPPED'} 
                                                && (
						    lc($config->{'LIST_SKIPPED'}) eq 'top' ||
						    lc($config->{'LIST_SKIPPED'}) eq 'bottom'
						    );

### lowercase some values
    $config->{'SUMMARY_AT'} = lc $config->{'SUMMARY_AT'};
    $config->{'LIST_SKIPPED'} = lc $config->{'LIST_SKIPPED'};


### expand ~ to home directory
    $config->{'DB_NAME'}  =~ s/^~/$ENV{'HOME'}/;
    $config->{'MAIL_CMD'} =~ s/^~/$ENV{'HOME'}/;

    $config->{'SCORE'}    = \@scores;
    $config->{'CATSCORE'} = \@catscores;

}


######################[ mail all 'hot' entries ]#############################


sub mail_hot_apps()
{
    my $hot_applications = shift;
    my $new_app;
    my $first_hot = 1;

    while (@{$hot_applications}) {
	
	$new_app = pop @{$hot_applications};
    
	
	if ($first_hot == 1) {
	    $first_hot=0;
	    open_hot_mail($new_app);
	}
	
	if (defined $new_app->{'subject'}) {
	    print MAIL_HOT "\n   $new_app->{'subject'}\n\n";
	}
	
	if (defined $new_app->{'description'}) {
	    print MAIL_HOT "$new_app->{'description'}\n";
	}
	
	if (defined $new_app->{'changes'}) {
	    print MAIL_HOT "     changes:";
	    if (defined $new_app->{'urgency'}) {
		print MAIL_HOT " ($new_app->{'urgency'} urgency)";
	    }
	    print MAIL_HOT "\n$new_app->{'changes'}\n";
	}
	
	if (defined $new_app->{'author'}) {
	    print MAIL_HOT "    added by: $new_app->{'author'}\n";
	}
	
	if (defined $new_app->{'category'}) {
	    my @categories = split /,/, $new_app->{'category'};
	    my $category = shift @categories;
	    print MAIL_HOT "    category: $category\n";
	    foreach my $category ( @categories ) {
		$category =~ s/^\s+// ;
		print MAIL_HOT "              $category\n";
	    }
	}
	
	if (defined $new_app->{'project_link'}) {
	    print MAIL_HOT "project page: $new_app->{'project_link'}\n";
	}

	if (defined $new_app->{'newslink'}) {
	    print MAIL_HOT "     details: $new_app->{'newslink'}\n";
	}
	
	if (defined $new_app->{'date'}) {
	    print MAIL_HOT "        date: $new_app->{'date'}\n";
	}
	
	if (defined $new_app->{'license'}) {
	    print MAIL_HOT "     license: $new_app->{'license'}\n";
	}
	
	if (defined $new_app->{'project_id'}) {
	    print MAIL_HOT "  project id: $new_app->{'project_id'}\n";
	}

	if (defined $new_app->{'comments'}) {
	    print MAIL_HOT "your comment: $new_app->{'comments'}\n";
	}

	print MAIL_HOT "\n$separator";

	if ($config->{'UPDATE_MAIL'} ne "single") {
	    close_hot();
	    $first_hot=1;
	}
	
    }

### close mailer
    if ($first_hot == 0) {
	close_hot();
    }
}


###################[ format list of skipped items ]##########################


sub get_skipped()
{
    my $skipped = "";

    if (@{$skipped_already_seen} > 0) {

	$skipped .= "\n These news items were skipped as 'already seen':\n\n";

	foreach my $item (@{$skipped_already_seen}) {
	    $skipped .= " *  $item\n";
	}

    }

    if (@{$skipped_low_score} > 0) {

	$skipped .= "\n These news items were skipped as 'low score':\n\n";

	foreach my $item (@{$skipped_low_score}) {
	    $skipped .= " *  $item\n";
	}

    }

    $skipped .= "\n$separator" unless $skipped eq "";

    return $skipped;
}


########[ format configuration file warnings for "new" mail ]################

sub get_warnings()
{
    my $warnings = "";

    if (@{$cfg_warnings} > 0) {

	$warnings .= "\n Your configuration file ~/.whatsnewfmrc "
	    . "produced the following warnings:\n\n";

	foreach my $warn (@{$cfg_warnings}) {
	    $warnings .= " *  $warn\n";
	}

	$warnings .= "\n Please see the whatsnewfm documentation "
	    . "for details.\n\n$separator";
    }

    return $warnings;
}


######################[ mail all 'new' entries ]#############################


sub mail_new_apps($$$$$$$$$)
{
    my ($subject, $articles, $releases, $releases_new, $hot_written, $db_new, $db_written, $db_expired, $new_applications) = @_;
    my $new_app;

### only keep applications with at least minimum score
    my $score_killed = @{$new_applications};
    $skipped_low_score = [ map { $_->{'subject'} } grep {$_->{'score'} < $config->{'SCORE_MIN'}} @{$new_applications} ];
    $new_applications = [ grep {$_->{'score'} >= $config->{'SCORE_MIN'}} @{$new_applications} ];
    $score_killed -= @{$new_applications};


### sort by score
    $new_applications = [ sort { $a->{'score'} <=> $b->{'score'} } @{$new_applications} ];


### get summary
    my $summary = get_summary($articles, $releases, $releases_new, $hot_written, $db_new, $db_written, $db_expired, $score_killed);


### get warnings
    my $warnings = get_warnings();


### get skipped list
    my $skipped = get_skipped();


### open mailer
    open_new_mail($subject);


### print warnings (if any)
    print MAIL_NEW $warnings;

### print summary if you want it at the beggining
    print MAIL_NEW $summary if $config->{'SUMMARY_AT'} eq 'top';

### list skipped items if you want them at the beggining
    print MAIL_NEW $skipped if $config->{'LIST_SKIPPED'} eq 'top';


    while (@{$new_applications}) {
	
	$new_app = pop @{$new_applications};
	
	if (defined $new_app->{'subject'}) {
	    print MAIL_NEW "\n   $new_app->{'subject'}\n\n";
	}

	if (defined $new_app->{'description'}) {
	    print MAIL_NEW "$new_app->{'description'}\n";
	}

	if (defined $new_app->{'changes'}) {
	    print MAIL_NEW "     changes:";
	    if (defined $new_app->{'urgency'}) {
		print MAIL_NEW " ($new_app->{'urgency'} urgency)";
	    }
	    print MAIL_NEW "\n$new_app->{'changes'}\n";
	}

	if (defined $new_app->{'author'}) {
	    print MAIL_NEW "    added by: $new_app->{'author'}\n";
	}

	if (defined $new_app->{'category'}) {
	    my @categories = split /,/, $new_app->{'category'};
	    my $category = shift @categories;
	    print MAIL_NEW "    category: $category\n";
	    foreach my $category ( @categories ) {
		$category =~ s/^\s+// ;
		print MAIL_NEW "              $category\n";
	    }
	}
	
	if (defined $new_app->{'project_link'}) {
	    print MAIL_NEW "project page: $new_app->{'project_link'}\n";
	}

	if (defined $new_app->{'newslink'}) {
	    print MAIL_NEW "   news item: $new_app->{'newslink'}\n";
	}

	if (defined $new_app->{'date'}) {
	    print MAIL_NEW "        date: $new_app->{'date'}\n";
	}
	
	if (defined $new_app->{'license'}) {
	    print MAIL_NEW "     license: $new_app->{'license'}\n";
	}
	
	if (defined $new_app->{'project_id'}) {
	    print MAIL_NEW "  project id: $new_app->{'project_id'}\n";
	}

	if (defined $new_app->{'score'}) {
	    print MAIL_NEW "       score: $new_app->{'score'}\n";
	}

	print MAIL_NEW "\n$separator";
	     
    }
    
### list skipped items if you want them at the bottom
    print MAIL_NEW $skipped if $config->{'LIST_SKIPPED'} eq 'bottom';

### print summary if you want it at the end
    print MAIL_NEW $summary if $config->{'SUMMARY_AT'} eq 'bottom';


### close mailer
    close MAIL_NEW or die "can't close mailer \"$config->{'MAIL_CMD'}\": $!";
}


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
