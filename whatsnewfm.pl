#!/usr/bin/perl -w
#############################################################################
#
my $id='whatsnewfm.pl  v0.7.2  2011-11-01';
#   Filters the freecode newsletter for 'new' or 'interesting' entries.
#   
#   Copyright (C) 2000-2011  Christian Garbs <mitch@cgarbs.de>
#                            Joerg Plate <Joerg@Plate.cx>
#                            Dominik Brettnacher <dominik@brettnacher.org>
#                            Pedro Melo Cunha <melo@isp.novis.pt>
#                            Matthew Gabeler-Lee <msg2@po.cwru.edu>
#                            Bernd Rilling <brilling@ifsw.uni-stuttgart.de>
#                            Jost Krieger <Jost.Krieger@ruhr-uni-bochum.de>
#                            Francois Marier <francois@debian.org>
#
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
#   You should have received a copy of the GNU General Public License along
#   with this program; if not, write to the Free Software Foundation, Inc.,
#   51 Franklin Street, Fifth Floor, Boston, MA 02110-1301 USA.
#
#############################################################################
#
# v0.7.2
# 2011/11/01--> BUGFIX: Newsletter format has changed:
#                       Freshmeat has become Freecode.
#
# v0.7.1
# 2009/05/30--> BUGFIX: Newsletter format has changed.
#
# v0.7.0
# 2009/03/23--> Add scoring of licenses via LICSCORE.
# 2009/03/19--> BUGFIX: Support the new Newsletter format of FM3
#
# v0.6.6
# v0.6.5
# 2004/04/11--> Make score regexp match multiline as proposed in
#               Sourceforge request #930403.
#
# v0.6.4
# 2004/02/13--> Copy Content-type etc. to output mails as proposed in
#               Sourceforge bug #891520.
# 2003/08/24--> Fix typo in manpage.
#
# v0.6.3
# 2003/08/07--> Parameters of sendmail(1) call can be configured via MAIL_OPT
#               as wanted in Sourceforge bug #728895.
#
# v0.6.2
# 2003/04/27--> Changed expiration algorithm for 'old' entries.
#               Expiration after one day is not possible any more.
# 2003/04/23--> BUGFIX: Multiline release subjects were not handled
#                       correctly (Sourceforge bug #726261).
# 2003/03/09--> Call sendmail(1) as advised in `perldoc -q "send mail"`.
#               No need for the "sendmail fixes" regarding dot-lines any more.
# 2003/02/26--> Removed old filenames from documentation.
# 2003/02/03--> Use %hashes instead of @arrays for configuration file keys.
#
# v0.6.1
# 2003/01/05--> BUGFIX: Number of added projects to old database in
#           |           newsletter was wrong.
#           `-> Changed open("<") call to more secure three-parameter form.
#
# v0.6.0
# 2003/01/04--> No changes, v0.5.3 seems stable enough to be released.
#
# v0.5.3
# 2002/12/29--> Configuration file can be selected.
#
# v0.5.2
# 2002/12/04--> BUGFIX: 0.5.1 didn't run at all.  Silly mistake :-(
#
# v0.5.1
# 2002/12/03--> Inclusion of manpage from Debian package.
# 2002/11/26--> Removed DATE_CMD backwards compatibility.
#
# v0.5.0
# 2002/11/24--> Removed file locking code.
#           |-> Changed all @arrays and %hashes to corresponding $references.
#           |-> Using BerkeleyDB::Hash for storage of databases.
#           |-> Added function prototypes.
#           `-> Added BerkeleyDB locking method.
# 2002/11/24--> Simpler computation of timestamp.  DATE_CMD not needed
#               any more.
# 2002/11/23--> Help text updates.
#
# >> 0.4.x branch forked off
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
# $Id: whatsnewfm.pl,v 1.112 2009/03/26 20:55:14 mastermitch Exp $
#
#
#############################################################################



##########################[ documentation ]##################################



=head1 NAME

whatsnewfm - filter the daily newsletter from freecode.com

=head1 SYNOPSIS

B<whatsnewfm.pl> [ B<-c> F<config file> ]

B<whatsnewfm.pl> [ B<-c> F<config file> ] B<view> [ I<regexp> ]

B<whatsnewfm.pl> [ B<-c> F<config file> ] B<add> [ I<project id> [ I<comment> ] ]

B<whatsnewfm.pl> [ B<-c> F<config file> ] B<del> [ I<project id> ] [ I<project id> ] [ ... ]

=head1 DESCRIPTION

whatsnewfm is a utility to filter the daily newsletter from
freecode.com

The main purpose is to cut the huge newsletter to a smaller size by
only showing items that you didn't see before.

The items already seen will be stored in a database. After some time,
the items expire and will be shown again the next time they are
included in a newsletter.

If you find an item that you consider particularly useful, you can add
it to a "hot" list. Items in the hot list are checked for updates so
that you don't miss anything about your favourite programs.

=head1 OPTIONS

=over 5

=item B<-c> F<config file>

This optional parameter selects a different configuration file.
Default is F<~/.whatsnewfmrc>.

=item B<whatsnewfm.pl>

Standard mode of operation.  A mail containing a newsletter will be
read from stdin, parsed and the results mailed.

=item B<whatsnewfm.pl> B<view> [ I<regexp> ]

Prints the "hot" database.  If I<regexp> is given, only entries
matching that regular expression are printed.  Pattern matches are
always case-insensitive.

=item B<whatsnewfm.pl> B<add> [ I<project id> [ I<comment> ] ]

Adds I<project id> to the "hot" database.  An optional I<comment>
describing the project may be given.

If no I<project id> is given on the command line, data will be read
from stdin.  Each line must consist of a I<project id> optionally
followed by a whitespace and a I<comment>.

=item B<whatsnewfm.pl> B<del> [ I<project id> ] [ I<project id> ] [ ... ]

Removes I<project id> from the "hot" database.  Multiple I<project
id>s may be given.

If no I<project id> is given on the command line, data will be read
from stdin.  Each line must consist of one or more I<project id>s
(separated by whitespace) to be deleted.

=back

=head1 FILES

=over 5

=item I<~/.whatsnewfmrc>

Personal whatsnewfm configuration file.

=item I<~/.whatsnewfm.db>

Personal database with "hot" and "old" entries.

=back

=head1 BUGS

Please report bugs to <F<whatsnewfm-bugs@cgarbs.de>>.

=head1 AUTHOR

whatsnewfm was written by Christian Garbs <F<mitch@cgarbs.de>>.

=head1 AVAILABILITY

Look for updates at <F<http://www.cgarbs.de/whatsnewfm.en.html>>.

=head1 COPYRIGHT

whatsnewfm is licensed under the GNU GPL.

=cut



##########################[ import modules ]#################################


use strict;
use warnings;
use BerkeleyDB::Hash;


#####################[ declare global variables ]############################


# global configuration hash:
my $config;

# global database environment
my $db_env;

# where to look for the configuration file (default):
$config->{CONFIGFILE} = "~/.whatsnewfmrc";

# information
my $whatsnewfm_homepages = [ "http://www.cgarbs.de/whatsnewfm.en.html" ,
			     "http://github.com/mmitch/whatsnewfm",
			     "http://sourceforge.net/projects/whatsnewfm/" ];
my $whatsnewfm_author = "Christian Garbs <mitch\@cgarbs.de>";

# configuration file
my $cfg_allowed_keys  = {
    "DB_NAME"      => 0,
    "EXPIRE"       => 0,
    "LIST_SKIPPED" => 0,
    "MAILTO"       => 0,
    "MAIL_CMD"     => 0,
    "MAIL_OPT"     => 0,
    "SCORE_MIN"    => 0,
    "SUMMARY_AT"   => 0,
    "UPDATE_MAIL"  => 0,
};
my $cfg_optional_keys = {
    "LIST_SKIPPED" => 0,
    "SUMMARY_AT"   => 0,
};
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
    whatsnewfm.pl [-c <configfile>]

print the "hot" list to stdout:
    whatsnewfm.pl [-c <configfile>] view [regexp]

add one new application to the "hot" list:
    whatsnewfm.pl [-c <configfile>] add <project id> [comment]
add multiple new applications to the "hot" list (from stdin):
    whatsnewfm.pl [-c <configfile>] add

remove applications from the "hot" list:
    whatsnewfm.pl [-c <configfile>] del <project id> [project id] [project id] [...]
or a list from stdin:
    whatsnewfm.pl [-c <configfile>] del

the optional parameter -c <configfile> selects the configuration file to use
(default: ~/.whatsnewfmrc)
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
	    if ($app->{'description'} =~ /$score->{'regexp'}/is) {
		$app->{'score'} += $score->{'score'};
	    }
	}
    }
    
    if (defined $app->{'category'}) {
	foreach my $score ( @{$config->{'CATSCORE'}}) {
	    if ($app->{'category'} =~ /$score->{'regexp'}/is) {
		$app->{'score'} += $score->{'score'};
	    }
	}
    }

    if (defined $app->{'license'}) {
	foreach my $score ( @{$config->{'LICSCORE'}}) {
	    if ($app->{'license'} =~ /$score->{'regexp'}/is) {
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

    my $subject      = "Subject: Freecode Newsletter (no subject?)\n";
    my $encoding     = '';
    my $position     = 1;
    # 1-> after mail header
    # 0-> within releases

    my $hot_written  = 0;
    my $db_written   = 0;
    my $db_expired   = 0;
    my $db_new       = 0;

    my $releases     = 0;
    my $releases_new = 0;

    my $end = 0;

    my $hot_applications = [];
    my $new_applications = [];



### generate current timestamp

    my ($sec,$min,$hour,$mday,$mon,$year,$wday,$yday,$isdst) =
	localtime(time);

    my $timestamp = ($mon+1) + ($year+1900)*12;

    # Move comparison timestamp half a month into the past.  This way
    # an item added on 31.01. won't be expired on 01.02. if the
    # expiration is set to 1 month.  It will be expired on
    # 16.02. instead, which is better (error distribution).
    my $timestamp_cmp = $timestamp - ($mday < 16);


### read databases

    $database    = open_old_db();
    $interesting = open_hot_db();


### expire 'old' entries
    
    foreach my $number (keys %{$database}) {
	if (($database->{$number}+$config->{'EXPIRE'}) < $timestamp_cmp) {
	    $db_expired++;
	    delete $database->{$number};
	}
    }


### process email headers
 
    while (<STDIN>) {
	last if /^$/;
	if (/^Subject:\s/) {
	    $subject=$_;
	} elsif (/^MIME-version:\s/) {
	    $encoding .= $_;
	} elsif (/^Content-type:\s/) {
	    $encoding .= $_;
	} elsif (/^Content-transfer-encoding:\s/) {
	    $encoding .= $_;
	}
    }


### process email body

    while (my $line=<STDIN>) {
	chomp $line;
	if (($position > 0) and ($line =~ /^SOFTWARE:/)) {
	    $position = 0;
	    while ($end == 0) {
		chomp $line;
		if ($line !~ /^\s*$/) {
		    if ($line =~ /========================================================================/) {
			$end = 1;
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
	    while ((defined $line) and ($line !~ /^\[\d+\] /)) {
		$line=<STDIN>;
	    }
	    next unless defined $line;
	    $line =~ s/^(\[\d+\]) //;
	    $release_nr = $1;
	    chomp $line;

	    $new_app->{'subject'} = $line;
	    $line=<STDIN>;
	    while ((defined $line) and ($line !~ /^\s*$/)) {
		# multiline subject field!
		chomp $line;
		$new_app->{'subject'} .= ' ' . $line;
		$line=<STDIN>;
	    }
	    next unless defined $line;
	    


	    ### body: general tag-based parser ahead:

	    my %tags = ();
	    my $tag = undef;
	    my $text = '';

	    # read
	    while ($line = <STDIN>) {
		# skip empty lines
		next if $line =~ /^\s*$/;     
	      
		# check for new tag
		if ($line =~ /^(Changes|Description|License|Project Tags|Release Tags):\s*(.*)$/) {
		    # save old tag
		    $tags{$tag} = $text if defined $tag;
		    # start new tag
		    $tag = $1;
		    $text = defined $2 ? $2 : '';
		}

		# check for project url (last tag)
		elsif ($line =~ m!^http://freecode.com/projects/(.+)$!) {
		    # save old tag
		    $tags{$tag} = $text if defined $tag;
		    # save url
		    chomp $line;
		    $tags{'URL'} = $line;
		    # save project id
		    $tags{'ID'} = $1;
		    # and break the loop
		    last;
		}

		# or just save the line
		else {
		    $text .= $line;
		}
	    }

	    # map known tags to new_app hash
	    $new_app->{'changes'} = $tags{'Changes'};
	    $new_app->{'description'} = $tags{'Description'};
	    $new_app->{'license'} = $tags{'License'};
	    $new_app->{'project_id'} = $tags{'ID'};
	    $new_app->{'project_link'} = $tags{'URL'};
	    # unused: $tags{'Release Tags'};

	    if (defined $tags{'Project Tags'}) {
		$new_app->{'category'} = $tags{'Project Tags'};
		$new_app->{'category'} =~ s/\n/,/g;
		delete $new_app->{'category'} if $new_app->{'category'} eq '';
	    }




	    ### count it and do the scoring

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
	    # sorry (much more UGLY than original)
	    my $end = 0;
	    while ($end == 0) {
		chomp $line;
		if ($line !~ /^\s*$/) {
		    if ($line =~ /========================================================================/) {
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

    $db_written  = close_old_db($database);
    $hot_written = close_hot_db($interesting);
    

### send mails

    mail_hot_apps($hot_applications, $encoding);
    mail_new_apps($subject, $releases, $releases_new, $hot_written, $db_new, $db_written, $db_expired, $new_applications, $encoding);

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


sub format_summary($$$$$$$)
{
    my ($releases, $releases_new, $hot_written, $db_new, $db_written, $db_expired, $score_killed) = @_;

    my $already_seen=@{$skipped_already_seen};
    my $difference=$releases-$releases_new-$already_seen;
    my $remaining=$releases_new-$score_killed;
    my $summary = << "EOF";
	
    This newsletter has been filtered by:
    $id

    It contained $releases releases.
EOF
    
    if ($releases > 1) {    # 1 release is not enough to ensure proper operation!

	$summary .= << "EOF";
    $already_seen releases have been skipped as 'already seen'.
    $score_killed releases have been skipped as 'low score'.
    $remaining releases are shown in this mail,
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


sub open_hot_mail($$)
{
    my ($new_app, $encoding) = @_;

    open MAIL_HOT, "| $config->{'MAIL_CMD'} $config->{'MAIL_OPT'}"
	or die "can't fork mailer \"$config->{'MAIL_CMD'}\": $!";
    
    print MAIL_HOT "To: $config->{'MAILTO'}\n";
    if ($config->{'UPDATE_MAIL'} eq "single") {
	print MAIL_HOT "Subject: whatsnewfm.pl: Updates of interesting applications\n";
    } else {
	print MAIL_HOT "Subject: whatsnewfm.pl: Update: $new_app->{'subject'}\n";
    }
    print MAIL_HOT "X-Loop: sent by whatsnewfm.pl script\n";
    print MAIL_HOT $encoding;
    print MAIL_HOT "\n";
    print MAIL_HOT "$separator";
}


########################[ open a "new" mail ]################################


sub open_new_mail($$)
{
    my ($subject, $encoding) = @_;
    open MAIL_NEW, "| $config->{'MAIL_CMD'} $config->{'MAIL_OPT'}"
	or die "can't fork mailer \"$config->{'MAIL_CMD'}\": $!";
    
    print MAIL_NEW "To: $config->{'MAILTO'}\n";
    print MAIL_NEW $subject;
    print MAIL_NEW "X-Loop: sent by whatsnewfm.pl daemon\n";
    print MAIL_NEW $encoding;
    print MAIL_NEW "\n";
    print MAIL_NEW "$separator";
}


###########################[ fold a line ]##################################


sub fold_line($$$$)
{
    my ($string, $max, $separator, $prefix) = (@_);
    
    my $ret = ''; 

    while (length $string > $max) {
        my $pos = $max;
        while ($pos > 0) {
            if ( substr($string, $pos, 1) eq $separator ) {
                $ret .= substr($string, 0, $pos+1) . "\n" . $prefix;
                $string = substr($string, $pos+1);
                last;
            }
            $pos--;
        }  
        if ($pos == 0) {
          $pos = index($string, $separator);
          if ( $pos > 0) {
                $ret .= substr($string, 0, $pos+1) . "\n" . $prefix;
                $string = substr($string, $pos+1);
          } else {
            last;
            }
        }
    }
     
    return $ret . $string;

}


###################[ read the configuration file ]###########################


sub read_config()
{
    my $config_file = $config->{CONFIGFILE};
    my @scores = ();
    my @catscores = ();
    my @licscores = ();

### look for config file
    $config_file =~ s/^~/$ENV{'HOME'}/;
    if (! -e $config_file) {
	die "configuration file \"$config_file\" not found!\n";
    }

### read the config file
    open CONF, "<", "$config_file"
	or die "could not open configuration file \"$config_file\": $!";

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
		    
		} elsif ($key eq "LICSCORE") {
		    
		    my ($score, $regexp) = split /\t/, $value, 2;
		    if ((! defined $regexp) or ($regexp eq "")) {
			warn "$0 warning:\n";
			warn "no REGEXP given in configuration file at line $.\n";
			push @{$cfg_warnings}, "no REGEXP given at line $.";
		    }
		    elsif ($score =~ /[+-]\d+/) {
			push @licscores, { 'score' => $score, 'regexp' => $regexp };
		    } else {
			warn "$0 warning:\n";
			warn "SCORE value not numeric in configuration file at line $.\n";
			push @{$cfg_warnings}, "SCORE value not numeric at line $.";
		    }
		    
		} elsif ( exists $cfg_allowed_keys->{$key} ) {
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
    foreach my $key (keys %{$cfg_allowed_keys}) {
	if (! exists $config->{$key}) {
	    if ( exists $cfg_optional_keys->{$key} ) {
		warn "$0 fatal error:\n";
		die  "keyword \"$key\" is missing in configuration file \"$config_file\"\n";
	    } else {
		warn "$0 warning:\n";
		warn "using default value for \"$key\"\n";
		push @{$cfg_warnings}, "using default value for \"$key\"";
	    }
	}
    }

### lowercase some values
    $config->{'SUMMARY_AT'} = lc $config->{'SUMMARY_AT'};
    $config->{'LIST_SKIPPED'} = lc $config->{'LIST_SKIPPED'};


### default values
    $config->{'SUMMARY_AT'} = 'bottom' unless exists $config->{'SUMMARY_AT'}
                                                  && $config->{'SUMMARY_AT'} 
                                                  && $config->{'SUMMARY_AT'} eq 'top';
    $config->{'LIST_SKIPPED'} = 'no'   unless exists $config->{'LIST_SKIPPED'}
                                                  && $config->{'LIST_SKIPPED'} 
                                                  && (
						      $config->{'LIST_SKIPPED'} eq 'top' ||
						      $config->{'LIST_SKIPPED'} eq 'bottom'
						     );
    $config->{'MAIL_OPT'} = '-oi -t'   unless exists $config->{'MAIL_OPT'};


### expand ~ to home directory
    $config->{'DB_NAME'}  =~ s/^~/$ENV{'HOME'}/;
    $config->{'MAIL_CMD'} =~ s/^~/$ENV{'HOME'}/;

    $config->{'SCORE'}    = \@scores;
    $config->{'CATSCORE'} = \@catscores;
    $config->{'LICSCORE'} = \@licscores;

}


#####################[ format application entry ]############################


sub format_application($)
{
    my ($app) = (@_);

    my $text = '';

    if (defined $app->{'subject'}) {
	$text .= "\n   $app->{'subject'}\n\n";
    }
	
    if (defined $app->{'description'}) {
	$text .= "$app->{'description'}\n";
    }
	
    if (defined $app->{'changes'}) {
	$text .= "     changes:";
	if (defined $app->{'urgency'}) {
	    $text .= " ($app->{'urgency'} urgency)";
	}
	$text .= "\n$app->{'changes'}\n";
    }
    
    if (defined $app->{'author'}) {
	$text .= "    added by: $app->{'author'}\n";
    }
	
    if (defined $app->{'category'}) {
	$text .= "    category: " . fold_line($app->{'category'}, 57, ',', '             ') . "\n";
    }
	
    if (defined $app->{'project_link'}) {
	$text .= "project page: $app->{'project_link'}\n";
    }

    if (defined $app->{'newslink'}) {
	$text .= "     details: $app->{'newslink'}\n";
    }
	
    if (defined $app->{'date'}) {
	$text .= "        date: $app->{'date'}\n";
    }
	
    if (defined $app->{'license'}) {
	$text .= "     license: $app->{'license'}\n";
    }
	
    if (defined $app->{'project_id'}) {
	$text .= "  project id: $app->{'project_id'}\n";
    }

    if (defined $app->{'score'}) {
	$text .= "       score: $app->{'score'}\n";
    }

    if (defined $app->{'comments'}) {
	$text .= "your comment: $app->{'comments'}\n";
    }                                                                                                                                                                   

    $text .= "\n$separator";

    return $text;

}


######################[ mail all 'hot' entries ]#############################


sub mail_hot_apps($$)
{
    my ($hot_applications, $encoding) = @_;
    my $first_hot = 1;

    foreach my $new_app (@{$hot_applications}) {
	
	if ($first_hot == 1) {
	    $first_hot=0;
	    open_hot_mail($new_app, $encoding);
	}

	# don't show a score on hot entries
	delete $new_app->{'score'};

	print MAIL_HOT format_application($new_app);
	
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


sub format_skipped()
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

sub format_warnings()
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
    my ($subject, $releases, $releases_new, $hot_written, $db_new, $db_written, $db_expired, $new_applications, $encoding) = @_;
    my $new_app;

### only keep applications with at least minimum score
    my $score_killed = @{$new_applications};
    $skipped_low_score = [ map { $_->{'subject'} } grep {$_->{'score'} < $config->{'SCORE_MIN'}} @{$new_applications} ];
    $new_applications = [ grep {$_->{'score'} >= $config->{'SCORE_MIN'}} @{$new_applications} ];
    $score_killed -= @{$new_applications};


### sort by score
    $new_applications = [ sort { $b->{'score'} <=> $a->{'score'} } @{$new_applications} ];


### get summary
    my $summary = format_summary($releases, $releases_new, $hot_written, $db_new, $db_written, $db_expired, $score_killed);


### get warnings
    my $warnings = format_warnings();


### get skipped list
    my $skipped = format_skipped();


### open mailer
    open_new_mail($subject, $encoding);


### print warnings (if any)
    print MAIL_NEW $warnings;

### print summary if you want it at the beggining
    print MAIL_NEW $summary if $config->{'SUMMARY_AT'} eq 'top';

### list skipped items if you want them at the beggining
    print MAIL_NEW $skipped if $config->{'LIST_SKIPPED'} eq 'top';


### print application entries
    foreach my $new_app (@{$new_applications}) {
	print MAIL_NEW format_application($new_app);
    }
    
### list skipped items if you want them at the bottom
    print MAIL_NEW $skipped if $config->{'LIST_SKIPPED'} eq 'bottom';

### print summary if you want it at the end
    print MAIL_NEW $summary if $config->{'SUMMARY_AT'} eq 'bottom';


### close mailer
    close MAIL_NEW or die "can't close mailer \"$config->{'MAIL_CMD'}\": $!";
}


###########################[ main routine ]##################################


if (@ARGV>1) {
    if ($ARGV[0] eq "-c") {
	shift @ARGV;
	$config->{CONFIGFILE} = shift @ARGV;
    }
}

if ($ARGV[0]) {

    if ($ARGV[0] eq "add") {

	shift @ARGV;
	read_config();
	add_entry(@ARGV);

    } elsif ($ARGV[0] eq "del") {

	shift @ARGV;
	read_config();
	remove_entry(@ARGV);

    } elsif ($ARGV[0] eq "view") {

	shift @ARGV;
	read_config();
	view_entries(@ARGV);

    } else {

	display_help();

    }

} else {

    read_config();
    parse_newsletter();

}

exit 0;
