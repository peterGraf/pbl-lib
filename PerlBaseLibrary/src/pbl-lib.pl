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
my $PBL_TRACE;
$PBL_TRACE = 'D:/temp/PBL_TRACE.LOG';

##
#
# Prints debug information to a file if $PBL_TRACE is set to a filename.
#
# $PBL_TRACE='/tmp/PBL_TRACE.LOG';
#
sub PBL_TRACE
{
	local ($i)   = 0;
	local ($str) = 0;

	if ( length($PBL_TRACE) )
	{
		open( FILEHANDLE, ">> $PBL_TRACE" );

		foreach $str (@_)
		{
			$i = 0;
			while ( $i < length($str) )
			{
				printf( FILEHANDLE substr( $str, $i, 1 ) );
				$i += 1;
			}
		}

		close FILEHANDLE;
	}
	return 1;
}

##
#
# Reads in GET or POST query data, converts it to non-escaped text,
# and saves each parameter in the query map.
#
#  If there's no variables that indicates GET or POST, it is assumed
#  that the CGI script was started from the command line, specifying
#  the query string like
#
#      script 'key1=value1&key2=value2'
#
sub pblParseQuery
{
	local ( $qin, $i, $loc, $key, $val );
	if ( $ENV{'REQUEST_METHOD'} eq "POST" )
	{
		local ($postData);
		for ( $i = 0 ; $i < $ENV{'CONTENT_LENGTH'} ; $i++ )
		{
			$postData .= getc;
		}
		$qin = $ENV{'QUERY_STRING'} . "&" . $postData;
	}
	else
	{
		if ( $ENV{'REQUEST_METHOD'} eq "GET" )
		{
			$qin = $ENV{'QUERY_STRING'};
		}
		else
		{
			$qin = $_[0];
		}
	}

	if ( length($qin) )
	{
		#&PBL_TRACE("qin:\"$qin\"\"\n");

		@qin = split( /&/, $qin );
		foreach $i ( 0 .. $#qin )
		{
			# Convert plus's to spaces
			$qin[$i] =~ s/\+/ /g;

			# Convert %XX from hex numbers to alphanumeric
			$qin[$i] =~ s/%(..)/pack("c",hex($1))/ge;

			# Split into key and value.
			$loc = index( $qin[$i], "=" );
			$key = substr( $qin[$i], 0, $loc );
			$val = substr( $qin[$i], $loc + 1 );
			$in{$key} = $val;

			&PBL_TRACE("key:\"$key\" val:\"$in{$key}\"\n");
		}
	}
	return 1;
}

# Returns the magic line which tells WWW that we're an HTML document
#
sub pblPrintHeader
{
	return "Content-type: text/html\n\n";
}

##
# Variable needed for filehandle in recursion
#
$pbl_FILEM = "PBLT000";

##
# Print a template replacing any variables that are set in the global associative
# array Replace to STDOUT.
#
# Parameters:
#   string templateName: The file name of the template to print
#   string docDir:       The full name of the document directory
#   string templateDir:  The full name of the templates directory
#                        used for includes in template files.
# Return 0 on failure, 1 on success
#
sub pblPrintTemplate
{
	local ( $templateName, $docDir, $templateDir ) = @_;

	&PBL_TRACE("pblPrintTemplate: $templateName, $docDir, $templateDir\n");
	&pblPrintTemplateToFile( STDOUT, $templateName, $docDir, $templateDir );
}

##
# The same as pblPrintTemplate with a file handle of an open file
#
sub pblPrintTemplateToFile
{
	local ( $FH, $templateName, $docDir, $templateDir ) = @_;

	local (@LOOPLINES);
	local ($FILENAME);
	local ( $INCNAME, $CMD, $FILE, $VARNAME, $LOOPVARS );
	local ( $IGNOREFLAG, $IGNORENAME );
	local ($PrintComments);

	&PBL_TRACE("pblPrintTemplateToFile: $templateName, ");
	&PBL_TRACE("$docDir, $templateDir\n");

	$PrintComments = 1;
	if ( !( $templateName =~ /\.html$/ ) )
	{
		&PBL_TRACE("Non-html file, not printing comments!\n");
		$PrintComments = 0;
	}

	$FILENAME = "$docDir/$templateName";
	if ( !( -f "$FILENAME" ) )
	{
		# Expect it to be in the template directory
		$FILENAME = "$templateDir/$templateName";
	}

# String increment of filehandle name (programming perl pg 163), to allow recursion
	$FILE = $pbl_FILEM++;

	# open the file
	&PBL_TRACE("opening $FILENAME\n");
	if ( !open( $FILE, $FILENAME ) )
	{
		&PBL_TRACE("\nERROR:Could not open file $FILENAME $!!\n");
		print $FH "\nERROR:Could not open file $FILENAME $!!\n";
		exit(1);
	}

	$IGNOREFLAG = 0;
	while (<$FILE>)
	{
# If we are currently ignoring the lines because an IFDEF or IFNDEF evaluated to FALSE
		if ( $IGNOREFLAG == 1 )
		{
			if ( ($VARNAME) = m/<!--#ENDIF\s+(.*)\s*-->/ )
			{
				&PBL_TRACE("ENDIF $VARNAME looking for ENDIF $IGNORENAME\n");

				if ( $VARNAME eq $IGNORENAME )
				{
					&PBL_TRACE("matches $IGNORENAME\n");

					$IGNOREFLAG = 0;
					$IGNORENAME = "";
					next;
				}
			}
		}
		else
		{
			# see whether there is an ifdef statement
			if ( ($VARNAME) = m/<!--#IFDEFf\s+(.*)\s*-->/ )
			{
				if ( !( defined( $Replace{$VARNAME} ) ) )
				{
					# The variable is not defined we ignore all lines till the
					# corressponding endif line
					$IGNOREFLAG = 1;
					$IGNORENAME = $VARNAME;

					&PBL_TRACE(
"Var $VARNAME not defined, ignoring till endif $IGNORENAME\n"
					);
				}
			}
			elsif ( ($VARNAME) = m/<!--#IFNDEF\s+(.*)\s*-->/ )
			{
				# if the variable is defined
				if ( defined( $Replace{$VARNAME} ) )
				{
					# the variable is defined we ignore all lines till the
					# corressponding endif line
					$IGNOREFLAG = 1;
					$IGNORENAME = $VARNAME;
					&PBL_TRACE(
"Var $VARNAME defined, ignoring till endif $IGNORENAME\n"
					);
				}
			}
		}

		# for vrml templates we do not print the comments
		if ( $PrintComments == 0 )
		{
			if (   /<!--#IFDEF\s+/
				|| /<!--#IFNDEF\s+/
				|| /<!--#ENDIF\s+/ )
			{
				next;
			}
		}

		# If we are in ignore mode we are done here
		$IGNOREFLAG && next;

		# Handle for loops
		if ( ( $VARNAME, $LOOPVARS ) =
			m/<!--#for\s+loopname=\s*\"(.*)\"\s*loopvars=\s*\"(.*)\"\s*-->/ )
		{
			# read the lines of the loop
			@LOOPLINES = &pblReadFor( $FILE, $VARNAME );

			# print the lines of the loop
			&pblPrintFor( $FH, $VARNAME, $LOOPVARS, @LOOPLINES );

			# done printing the loop
			next;
		}

		# replace all occurrences of all variables
		while ( ($VARNAME) = m/<\$([A-Z_a-z0-9]+)>/ )
		{
			# this will produce a replace by an empty string if the
			# variable is not defined
			s/<\$$VARNAME>/$Replace{$VARNAME}/g;
		}

		while ( ($VARNAME) = m/<\#(.+?)>/ )
		{
			# this will produce a replace by an empty string if the
			# variable is not defined
			s/<\#$VARNAME>/$Replace{$VARNAME}/g;
		}

		# handle include files by a recursive call to this function
		if ( ( $INCNAME ) = m/<!--#INCLUDE\s+(.*)\s*-->/ )
		{
			if ($PrintComments)
			{
				printf( $FH "<!-- START %s\"%s\" -->\n", $CMD, $INCNAME );
			}

			# recursive call to this function
			&pblPrintTemplateToFile( $FH, "$INCNAME", $templateDir,
				$templateDir );

			if ($PrintComments)
			{
				printf( $FH "<!-- END %s\"%s\" -->\n", $CMD, $INCNAME );
			}
		}
		else
		{

			print $FH $_;
		}
	}
	close($FILE);
	return 1;
}

# =DocStart= sub pblPrintFor
# Print all lines of a for loop
sub pblPrintFor
{
	local ( $FH, $loopname, $loopvars, @looplines ) = @_;

	# =DocEnd=
	local (@myloopvars);
	local ($done);
	local ($line);
	local ($loopvar);
	local ($VARNAME);
	local ($incarnation);
	local ($i);

	# print a line telling that this is a loop to the file
	print $FH "<!--#for loopname=\"$loopname\" loopvars=\"$loopvars\" -->\n";

	# get rid of blanks in the loopvars
	$loopvars =~ s/\s*//g;

	# split them into an array
	@myloopvars = split( ',', $loopvars );

	# now print the lines
	$incarnation = -1;
	while (1)
	{
		$incarnation++;
		$done = 1;

		# see if at least one of the loopvars is set for this incarnation
		foreach $i ( 0 .. $#myloopvars )
		{
			$loopvar = "$myloopvars[ $i ]" . "$incarnation";
			if ( defined( $Replace{"$loopvar"} ) )
			{
				&PBL_TRACE("pblPrintFor: \"$loopvar\" set\n");
				$done = 0;
				last;
			}
			else
			{
				&PBL_TRACE("pblPrintFor: \"$loopvar\" not set\n");
			}
		}

		# see whether we are done
		if ( $done == 1 )
		{
			print $FH "<!--#endfor loopname=\"$loopname\" -->\n";
			return 1;
		}

		# print a line to the file
		print $FH "<!-- i=$incarnation -->\n";

		# print all lines of the for loop
		foreach $i ( 0 .. $#looplines )
		{
			$line = $looplines[$i];

			# replace all occurrences of all variables
			while ( ($VARNAME) = $line =~ m/<\$([A-Z_a-z0-9]+)>/ )
			{
				# if this is a loopvar
				$loopvar = "$VARNAME" . "$incarnation";
				if ( defined( $Replace{"$loopvar"} ) )
				{
					$line =~ s/<\$$VARNAME>/$Replace{ "$loopvar" }/g;
				}
				else
				{
					# replace other variables
					$line =~ s/<\$$VARNAME>/$Replace{$VARNAME}/g;
				}
			}

			# print the line
			print $FH "$line";
		}
	}
}

# =DocStart= sub pblReadFor
# Read all lines until the corresponding enfor line of a for loop
sub pblReadFor
{
	local ( $IN, $loopname ) = @_;

	# =DocEnd=
	local ( $VARNAME, $IGNOREFLAG, $IGNORENAME, @LINELIST );

	&PBL_TRACE("pblReadFor: $loopname\n");

	$IGNOREFLAG = 0;
	while (<$IN>)
	{
		# if we are currently ignoring the lines because an ifdef or ifndef
		# evaluated to FALSE
		if ( $IGNOREFLAG == 1 )
		{
			# see whether we found an endif
			if ( ($VARNAME) = m/<!--#endif\s+variable=\s*\"(.*)\"\s*-->/ )
			{
				&PBL_TRACE(
					"found endif $VARNAME looking for endif $IGNORENAME\n");

				# see whether it is the right endif
				if ( $VARNAME eq $IGNORENAME )
				{
					&PBL_TRACE("matches $IGNORENAME\n");

					# it is the right one, turn ignore off
					#
					$IGNOREFLAG = 0;
					$IGNORENAME = "";
					next;
				}
			}
		}
		else
		{
			# see whether there is an ifdef statement
			if ( ($VARNAME) = m/<!--#ifdef\s+variable=\s*\"(.*)\"\s*-->/ )
			{
				# if the variable is not defined
				if ( !( defined( $Replace{$VARNAME} ) ) )
				{
					# the variable is not defined we ignore all lines till the
					# corressponding endif line
					$IGNOREFLAG = 1;
					$IGNORENAME = $VARNAME;

					&PBL_TRACE(
"Var $VARNAME not defined, ignoring till endif $IGNORENAME\n"
					);
				}
			}
			elsif ( ($VARNAME) = m/<!--#ifndef\s+variable=\s*\"(.*)\"\s*-->/ )
			{
				# if the variable is defined
				if ( defined( $Replace{$VARNAME} ) )
				{
					# the variable is defined we ignore all lines till the
					# corressponding endif line
					$IGNOREFLAG = 1;
					$IGNORENAME = $VARNAME;
					&PBL_TRACE(
"Var $VARNAME defined, ignoring till endif $IGNORENAME\n"
					);
				}
			}
		}

		# if we are in ignore mode we don't do anything
		$IGNOREFLAG && next;

		# see wether we found the endfor
		if ( ($VARNAME) = m/<!--#endfor\s+loopname=\s*\"(.*)\"\s*-->/ )
		{
			if ( $VARNAME eq $loopname )
			{
				&PBL_TRACE("pblReadFor: End $loopname $#LINELIST lines\n");

				# we found the end of our loop
				return (@LINELIST);
			}
		}

		# push the line to the stack
		push( @LINELIST, $_ );
	}
	return (@LINELIST);
}

# =DocStart= sub pblSaveForReplace
# Save a string for later replacement, the string is saved in the global
# associative array Replace.
# If more than one string is saved for the same replacement variable
# the contents of the strings are concatenated.
#
sub pblSaveForReplace
{
	local ( $key, $value ) = @_;

	# =DocEnd=
	&PBL_TRACE("SavedForReplace \"$key\"=\"$value\"\n");
	$Replace{$key} .= $value;
}

1;    # For require
