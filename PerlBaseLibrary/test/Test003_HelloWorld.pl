#!/usr/bin/perl
#
# This software is a part of Peter Graf's perl base library - PBL
#
# Peter Graf's perl base library is hosted on GitHub,
# see http://github.com/peterGraf/pbl-lib/
#
# For more information on the author Peter Graf,
# see http://www.mission-base.com/
#
# Copyright (c) 2018 Peter Graf. All rights reserved.
#
# This software is published under the GNU General Public License, version 2.
#
# GNU General Public License, version 2:
#
# This program is free software; you can redistribute it and/or
# modify it under the terms of the GNU General Public License
# as published by the Free Software Foundation; either version 2
# of the License, or (at your option) any later version.
#
# This program is distributed in the hope that it will be useful,
# but WITHOUT ANY WARRANTY; without even the implied warranty of
# MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
# GNU General Public License for more details.
#
# You should have received a copy of the GNU General Public License
# along with this program; if not, write to the Free Software
# Foundation, Inc., 51 Franklin Street, Fifth Floor, Boston, MA  02110-1301, USA.
#

##
# Test03_HelloWorld - The first program printing a template using includes.
#

require '../src/pbl-lib.pl';

use strict;
use warnings;

&PBL_TRACE("\nSTARTED\n\n");

# Read any command line parameters of the form x1=y1&x2=y2
# and the parameters given with any GET or POST form
#
&pblParseQuery(@ARGV);

print &pblPrintHeader;

&pblPrintTemplate("Test003_HelloWorld.html", "../templates", "../templates");

&PBL_TRACE("\nFINISHED\n");
