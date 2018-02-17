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
# This software is published under the MIT license.
#
# MIT License
#
# Permission is hereby granted, free of charge, to any person obtaining a copy
# of this software and associated documentation files (the ""Software""), to
# deal in the Software without restriction, including without limitation the
# rights to use, copy, modify, merge, publish, distribute, sublicense, and/or
# sell copies of the Software, and to permit persons to whom the Software is
# furnished to do so, subject to the following conditions:
# The above copyright notice and this permission notice shall be included in all
# copies or substantial portions of the Software.
# THE SOFTWARE IS PROVIDED *AS IS*, WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
# IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
# FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
# AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
# # LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
# OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE
# SOFTWARE.
#
#  pbl_Test001_HelloWorld - The traditional first program.
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
