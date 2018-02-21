#!/usr/bin/perl
#
##
# pbl-lib.pl - Perl library for web cgi processing.
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

my $PBL_TRACE;
$PBL_TRACE = 'D:/temp/PBL_TRACE.LOG';

##
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

##
# Returns the magic line needed for each HTML document
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
	local ( $INCNAME, $FILE, $VARNAME );
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
			if ( ($VARNAME) = m/<!--#ENDIF\s+\"(.*)\"\s*-->/ )
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
			# See whether there is an IFDEF statement
			if ( ($VARNAME) = m/<!--#IFDEF\s+\"(.*)\"\s*-->/ )
			{
				if ( !( defined( $Replace{$VARNAME} ) ) )
				{
					# The variable is not defined we ignore all lines till the
					# corresponding endif line
					$IGNOREFLAG = 1;
					$IGNORENAME = $VARNAME;

					&PBL_TRACE(
"Var $VARNAME not defined, ignoring till ENDIF $IGNORENAME\n"
					);
				}
			}
			elsif ( ($VARNAME) = m/<!--#IFNDEF\s+\"(.*)\"\s*-->/ )
			{
				# Ff the variable is defined
				if ( defined( $Replace{$VARNAME} ) )
				{
					# The variable is defined we ignore all lines till the
					# corresponding endif line
					$IGNOREFLAG = 1;
					$IGNORENAME = $VARNAME;
					&PBL_TRACE(
"Var $VARNAME defined, ignoring till ENDIF $IGNORENAME\n"
					);
				}
			}
		}

		# For non-html templates we do not print the comments
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
		if ( ($VARNAME) = m/<!--#FOR\s+\"(.*)\"\s*-->/ )
		{
			# read the lines of the loop
			@LOOPLINES = &pblReadFor( $FILE, $VARNAME );

			# print the lines of the loop
			&pblPrintFor( $FH, $VARNAME, @LOOPLINES );

			# done printing the loop
			next;
		}

		# Replace all occurrences of all variables
		while ( ($VARNAME) = m/<\$([A-Z_a-z0-9]+)>/ )
		{
			if ( defined( $Replace{$VARNAME} ) )
			{
				s/<\$$VARNAME>/$Replace{$VARNAME}/g;
			}
			else
			{
				s/<\$$VARNAME>//g;
			}
		}

		while ( ($VARNAME) = m/<!--\s*([A-Z_a-z0-9]+)\s*-->/ )
		{
			if ( defined( $Replace{$VARNAME} ) )
			{
				s/<!--\s*$VARNAME\s*-->/$Replace{$VARNAME}/g;
			}
			else
			{
				s/<!--\s*$VARNAME\s*-->//g;
			}
		}

		# Handle include files by a recursive call to this function
		#
		if ( ($INCNAME) = m/<!--#INCLUDE\s+\"(.*)\"\s*-->/ )
		{
			if ($PrintComments)
			{
				printf( $FH "<!-- INCLUDE \"%s\" -->\n", $INCNAME );
			}

			# Recursive call to this function
			&pblPrintTemplateToFile( $FH, "$INCNAME", $templateDir,
				$templateDir );

			if ($PrintComments)
			{
				printf( $FH "\n<!-- ENDINCLUDE \"%s\" -->\n", $INCNAME );
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

##
# Print all lines of a for loop
#
sub pblPrintFor
{
	local ( $FH, $loopname, @looplines ) = @_;
	local ($done);
	local ($line);
	local ($VARNAME);
	local ($incarnation);
	local ($i);
	local ($loopvar);

	# Print a line telling that this is a loop to the file
	print $FH "<!--#FOR \"$loopname\" -->\n";

	# Print the lines
	$incarnation = -1;
	while (1)
	{
		$incarnation++;
		$done    = 1;
		$loopvar = "$loopname" . "_" . "$incarnation";
		if ( defined( $Replace{"$loopvar"} ) )
		{
			&PBL_TRACE("pblPrintFor: \"$loopvar\" set\n");
			$done = 0;
		}
		else
		{
			&PBL_TRACE("pblPrintFor: \"$loopvar\" not set\n");
		}

		# See whether we are done
		if ( $done == 1 )
		{
			print $FH "<!--#ENDFOR \"$loopname\" -->\n";
			return 1;
		}

		# Print a line to the file
		print $FH "<!-- i=$incarnation -->\n";

		# Print all lines of the for loop
		foreach $i ( 0 .. $#looplines )
		{
			$line = $looplines[$i];

			# Replace all occurrences of all variables
			while ( ($VARNAME) = $line =~ m/<\$([A-Z_a-z0-9]+)>/ )
			{
				# If this is a loopvar
				$loopvar = "$VARNAME" . "_" . "$incarnation";
				if ( defined( $Replace{"$loopvar"} ) )
				{
					$line =~ s/<\$$VARNAME>/$Replace{ "$loopvar" }/g;
				}
				else
				{
					if ( defined( $Replace{$VARNAME} ) )
					{
						$line =~ s/<\$$VARNAME>/$Replace{$VARNAME}/g;
					}
					else
					{
						$line =~ s/<\$$VARNAME>//g;
					}
				}
			}

			while ( ($VARNAME) = $line =~ m/<!--\s*([A-Z_a-z0-9]+)\s*-->/ )
			{
				# If this is a loopvar
				$loopvar = "$VARNAME" . "_" . "$incarnation";
				if ( defined( $Replace{"$loopvar"} ) )
				{
					$line =~ s/<!--\s*$VARNAME\s*-->/$Replace{ "$loopvar" }/g;
				}
				else
				{
					if ( defined( $Replace{$VARNAME} ) )
					{
						$line =~ s/<!--\s*$VARNAME\s*-->/$Replace{ $VARNAME }/g;
					}
					else
					{
						$line =~ s/<!--\s*$VARNAME\s*-->//g;
					}
				}
			}

			# print the line
			print $FH "$line";
		}
	}
}

##
# Read all lines until the corresponding ENDFOR line of a for loop
#
sub pblReadFor
{
	local ( $IN, $loopname ) = @_;
	local ( $VARNAME, $IGNOREFLAG, $IGNORENAME, @LINELIST );

	&PBL_TRACE("pblReadFor: $loopname\n");

	$IGNOREFLAG = 0;
	while (<$IN>)
	{
		# If we are currently ignoring the lines because an ifdef or ifndef
		# evaluated to FALSE
		if ( $IGNOREFLAG == 1 )
		{
			# See whether we found an endif
			if ( ($VARNAME) = m/<!--#ENDIF\s+\"(.*)\"\s*-->/ )
			{
				&PBL_TRACE(
					"found endif $VARNAME looking for endif $IGNORENAME\n");

				# See whether it is the right endif
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
			# See whether there is an ifdef statement
			if ( ($VARNAME) = m/<!--#IFDEF\s+\"(.*)\"\s*-->/ )
			{
				# If the variable is not defined
				if ( !( defined( $Replace{$VARNAME} ) ) )
				{
					# The variable is not defined we ignore all lines till the
					# corresponding endif line
					$IGNOREFLAG = 1;
					$IGNORENAME = $VARNAME;

					&PBL_TRACE(
"Var $VARNAME not defined, ignoring till endif $IGNORENAME\n"
					);
				}
			}
			elsif ( ($VARNAME) = m/<!--#IFNDEF\s+\"(.*)\"\s*-->/ )
			{
				# If the variable is defined
				if ( defined( $Replace{$VARNAME} ) )
				{
					# The variable is defined we ignore all lines till the
					# corresponding endif line
					$IGNOREFLAG = 1;
					$IGNORENAME = $VARNAME;
					&PBL_TRACE(
"Var $VARNAME defined, ignoring till endif $IGNORENAME\n"
					);
				}
			}
		}

		# If we are in ignore mode we don't do anything
		$IGNOREFLAG && next;

		# see wether we found the endfor
		if ( ($VARNAME) = m/<!--#ENDFOR\s+\"(.*)\"\s*-->/ )
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

##
# Save a string for later replacement, the string is saved in the global
# associative array Replace.
# If more than one string is saved for the same replacement variable
# the contents of the strings are concatenated.
#
sub pblSaveForReplace
{
	local ( $key, $value ) = @_;

	&PBL_TRACE("SavedForReplace \"$key\"=\"$value\"\n");
	$Replace{$key} .= $value;
}

1;    # For require
