#!/usr/bin/perl -w
#############################################################################
#
my $id="watchfm_convert.pl  v0.2.0  2000-08-22";
#   Converts a watchfm database into a whatsnewfm "hot" database.
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
# 2000/08/22 -> no changes
#
# v0.0.3
# 2000/08/03 -> First piece of code.
#
#############################################################################
use strict;                     # strict syntax checking

while (my $line = <STDIN>) {
    chomp $line;
    my ($name, $appid, undef) = split /\t/, $line, 3;
    if ($appid) {
	$appid =~ s!^\d+/\d+/\d+/!!;
	if ($appid =~ /^\d+$/) {
	    print "$appid\t$name\n";
	} else {
	    print STDERR "error on line $.: $line\n";
	}
    } else {
	print STDERR "error on line $.: $line\n";
    }
}
