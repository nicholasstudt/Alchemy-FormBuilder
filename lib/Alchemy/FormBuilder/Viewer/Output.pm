package Alchemy::FormBuilder::Viewer::Output;

use strict;
use POSIX qw( strftime );
use Text::Wrap;
use Net::SMTP;
use MIME::Lite;
use File::Copy;

use KrKit::HTML qw( :all );
use KrKit::Validate;

##-----------------------------------------------------------------##
## Functions                                                       ##
##-----------------------------------------------------------------##

#-------------------------------------------------
# new( $proto )
#-------------------------------------------------
sub new ($) {
	my $proto = shift;

	my $class = ref( $proto ) || $proto;
	my $self = {};

	bless( $self, $class );

	return( $self );
} # END new

#-------------------------------------------------
# $self->prep_data( $k, $in, $form, $elem )
#-------------------------------------------------
sub prep_data {
	my ( $self, $k, $in, $form, $elem ) = @_;

	## Piece together the data
	## We need question number, name and value
	my %qa;			## Q&A hash - key is counter
	my %radio;		## Radio buttons (collection)
	my %cdata;		## Q&A hash - key is name
	my @uploads;	## Uploads
	
	for my $el ( sort {	$$elem{$a}->{quest} <=> $$elem{$b}->{quest} }
					keys ( %{$elem} ) ) {

		## Don't care about submits, resets, or html
		next if ( $$elem{$el}->{type} =~ /^submit$/i );
		next if ( $$elem{$el}->{type} =~ /^html$/i );
		next if ( $$elem{$el}->{type} =~ /^reset$/i );
		next if ( $$elem{$el}->{name} eq '' );

		my @data;
		
		## make sure it is not a radio duplicate
		if ( ! defined $radio{$$elem{$el}->{name}} ) {
		
			## No Data
			if ( ! is_text( $$in{$$elem{$el}->{name}} ) ) {
				@data = ( $$elem{$el}->{name}, '--no data--' );
				$cdata{$$elem{$el}->{name}} = '--no data--';
			}
			else {
				@data = ( $$elem{$el}->{name}, $$in{$$elem{$el}->{name}} );
				$cdata{$$elem{$el}->{name}} = $$in{$$elem{$el}->{name}};
			}

			$qa{$$elem{$el}->{quest}} = \@data;

			## Uploads
			if ( $$elem{$el}{type} =~ /^upload$/i ) {
				push( @uploads, $$in{$$elem{$el}{name}}, 
								$$in{'savedfile'.$$elem{$el}{name}} );
			}

			## Radio Buttons
			if ( $$elem{$el}->{type} =~ /^radio$/i ) {
				$radio{$$elem{$el}->{name}} = 1;
			}
		}
	}

	## Object Properties
	$self->{data}		= \%qa;
	$self->{cdata}		= \%cdata;
	$self->{uploads}	= \@uploads;

	## Form specifics
	$self->{ident}		= $$form{ident};
	$self->{name}		= $$form{name};
	$self->{fname}		= $$form{fname} || $$form{ident};
	$self->{email}		= $$form{email};
	$self->{subject}	= $$form{subject};
	$self->{send}		= $$form{send_as};
	$self->{store}		= $$form{store};

	return();
} # END $self->prep_data

##------------------------------------------------------------
## EMAIL
##------------------------------------------------------------

#-------------------------------------------------
## $self->notify( $k )
#-------------------------------------------------
sub notify {
	my ( $self, $k ) = @_;

	## Timestamp
	my $date = strftime( $$k{fmt_dt}, localtime() );

	my $body = 'There has been a submission to form: '. $self->{name}.
				"\n\n". 'The submission occured at: '. $date. "\n\n";

	## Uploads
	my @uploads = @{$self->{uploads}};
	
	if ( @uploads ) {
		$body .= "The following files were uploaded to $$k{file_path}:\n";
				
		while ( my ( $file, $name ) = shift( @uploads ) ) {
			$body .= "\t$name\n";
		}
	}
	
	## Recipients
	my @to = split( /,/, @{$self->{email}} );
	push( @to, @{$self->{email}} ) if ( ! @to );

	## Prepare message hash
	my %mesg = (	'From'			=> $$k{form_from},
					'Subject'		=> $self->{subject} . ' - ' . $date,
					'X-Mailer'		=> 'FormBuilder',
					'X-Origin-Ip:'	=> '',
					'Type'			=> 'text/plain; format=flowed',
					'Data'			=> [$body] );

	## Recipients
	for my $addr ( @to ) {
		$mesg{To} .= " ," . $addr if ( $addr );
	}

	$mesg{To} =~ s/^ ,//;
	$mesg{To} =~ s/,$//;
	
	## Make it and send it
	my $msg = MIME::Lite->build( %mesg );

	my $smtp = Net::SMTP->new( $$k{smtp_host} );

	$smtp->mail( $mesg{From} );

	for my $addr ( @to ) {
		$smtp->recipient( $addr ) if ( $addr );
	}
	
	$smtp->data();
	$smtp->datasend( $msg->stringify );
	$smtp->dataend();

	$smtp->quit;

	return();
} # END $self->notify

#-------------------------------------------------
# $self->send_inline( $k )
#-------------------------------------------------
sub send_inline {
	my ( $self, $k ) = @_;

	my $date = strftime( $$k{fmt_dt}, localtime() ); 	## Date
	my $body = $self->text( $k );
	my @uploads = @{$self->{uploads}}; 				## Uploads
	
	my @to = split( /,/, $self->{email} );
	push( @to, @{$self->{email}} ) if ( ! @to );

	## Prepare the message hash
	my %mesg = (	'From'			=> $$k{form_from},
					'Subject'		=> $self->{subject} . ' - ' . $date,
					'X-Mailer'		=> 'FormBuilder',
					'X-Origin-IP:'	=> '',
					'Type'			=> 'text/plain; format=flowed',
					'Data'			=> [$body] );

	## Recipients
	for my $addr ( @to ) {
		$mesg{To} .= " ," . $addr if ( $addr );
	}

	$mesg{To} =~ s/^ ,//;
	$mesg{To} =~ s/,$//;
	
	## Make it and send
	my $msg = MIME::Lite->build( %mesg );

	## Attachments
	while ( @uploads ) {
		my ( $name, $file ) = ( shift @uploads, shift @uploads );

		if ( $file ne '' && $name ne '' ) {
			$file =~ /^(.*)--(.*)--(.*)$/;
			my $enc = $2;
			$enc =~ s/_/\//;

			$msg->attach(	'Type'			=> $enc,
							'Path'			=> "$$k{file_tmp}/$file",
							'Filename'		=> $name,
							'Disposition'	=> 'attachment' );
		}
	}

	my $smtp = Net::SMTP->new ( $$k{smtp_host} );
	
	$smtp->mail( $mesg{From} );

	for my $addr ( @to ) {
		$smtp->recipient( $addr ) if ( $addr );
	}
	
	$smtp->data();
	$smtp->datasend( $msg->stringify );
	$smtp->dataend();

	$smtp->quit;

	return();
} # END $self->send_inline

#-------------------------------------------------
# $self->email( $k )
#-------------------------------------------------
sub email {
	my ( $self, $k ) = @_;
	
	## Date
	my $date = strftime( $$k{fmt_dt}, localtime() );

	my $body = 'There has been a submission to form: ' . $self->{name} .
				"\n\n" . 'The submission occured at: ' . $date . "\n\n"; 

	## Uploads
	my @uploads = @{$self->{uploads}};

	if ( @uploads ) {
		$body .= 'The file uploads have been attached as well.' . "\n";
	}
	
	## Data has been stored
	if ( $self->{store} ne 'dns' && $self->{store} ne 'shtml' &&
		 $self->{store} ne 'stxt' && $self->{store} ne 'scsv' ) {
		$body .= "The file $date-$self->{fname} has been saved.\n";
	}
	else {
		$body .= 'The file ' . "$self->{fname}" . ' has been saved.' . "\n";
	}
	
	## Recipients
	my @to = split( /,/, $self->{email} );
	push( @to, @{$self->{email}} ) if ( ! @to );

	## Prepare the message hash
	my %mesg = (	'From'			=> $$k{form_from},
					'Subject'		=> $self->{subject} . ' - ' . $date,
					'X-Mailer'		=> 'FormBuilder',
					'X-Origin-IP:'	=> '',
					'Type'			=> 'text/plain; format=flowed',
					'Data'			=> [$body] );

	## Recipients
	foreach my $addr ( @to ) {
		$mesg{To} .= " ," . $addr if ( $addr );
	}

	$mesg{To} =~ s/^ ,//;
	$mesg{To} =~ s/,$//;
	$mesg{To} =~ s/\ //g;
	
	## Make it and send
	my $msg = MIME::Lite->build( %mesg );

	if ( $self->{send} eq 'txt' ) { 					## Attach TXT

		$body .= 'The submission is attached as a text file.' . "\n\n";

		my $data = $self->text( $k );

		my $fname = $self->{fname};
		$fname = $fname . '.txt' if ( $fname !~ /\.txt$/ );

		## If this is a store - as a single file - include the current data
		if ( $self->{store} eq 'stxt' ) {
		
			## If it already exists
			if ( -f "$$k{file_path}/$fname" ) {
				if ( open( FILE, "$$k{file_path}/$fname" ) ) {
				
					my $contents = '';
					foreach my $line ( <FILE> ) {
						$data .= "\n" . $line;
					}
				}
			}
		}

		$msg->attach(	'Type'			=> 'TEXT',
						'Data'			=> $data,
						#'Path'			=> "$$k{file_path}/$fname",
						'Filename'		=> $fname,
						'Disposition'	=> 'attachment' );
	}
	elsif ( $self->{send} eq 'csv' ) { 					## Attach CSV

		$body .= 'The submission is attached as a CSV file.' . "\n\n";

		my ( $qdata, $adata ) = $self->csv( $k );

		my $fname = $self->{fname};
		$fname = $fname . '.csv' if ( $fname !~ /\.csv$/ );

		## If this is a store - as a single file - include the current data
		if ( $self->{store} eq 'scsv' ) {
		
			## If it already exists
			if ( -f "$$k{file_path}/$fname" ) {
			
				if ( open( FILE, "$$k{file_path}/$fname" ) ) {
				
					my @contents = <FILE>;

					shift( @contents );

					foreach my $line ( @contents ) {
						$adata .= "\n" . $line;
					}
				}
			}
		}
				
		$msg->attach(	'Type'			=> 'TEXT',
						'Data'			=> $qdata . "\n" . $adata,
						'Filename'		=> $fname,
						'Disposition'	=> 'attachment' );
	}
	## Attach HTML
	elsif ( $self->{send} eq 'html' ) {

		$body .= 'The submission is attached as a HTML file.' . "\n\n";
	
		my @dat = $self->html( $k );
		my $data = '';
		foreach ( @dat ) {
			$data .= $_ . "\n";
		}

		my $fname = $self->{fname};
		$fname = $fname . '.html' if ( $fname !~ /\.html$/ );

		## If this is a store - as a single file - include the current data
		if ( $self->{store} eq 'shtml' ) {
		
			## If it already exists
			if ( -f "$$k{file_path}/$fname" ) {
				if ( open( FILE, "$$k{file_path}/$fname" ) ) {
					foreach my $line ( <FILE> ) {
						$data .= $line . "\n";
					}
				}
			}
		}

		$msg->attach(	'Type'			=> 'HTML',
						'Data'			=> $data,
						'Filename'		=> $fname,
						'Disposition'	=> 'attachment' );
	}

	## Attachments
	while ( @uploads ) {  
		my ( $name, $file ) = ( shift @uploads, shift @uploads );

		if ( $file ne '' && $name ne '' ) {
		
			$file =~ /^(.*)--(.*)--(.*)$/;
			my $enc = $2;
			$enc =~ s/_/\//;

			$msg->attach(	'Type'			=> $enc,
							'Path'			=> "$$k{file_tmp}/$file",
							'Filename'		=> $name,
							'Disposition'	=> 'attachment' );
		}
	}

	## Make it and send it
	my $smtp = Net::SMTP->new ( $$k{smtp_host} );
	
	$smtp->mail( $mesg{From} );

	for my $addr ( @to ) {
		$smtp->recipient( $addr ) if ( $addr );
	}
	
	$smtp->data();
	$smtp->datasend( $msg->stringify );
	$smtp->dataend();

	$smtp->quit;

	return();
} # END $self->email

#-------------------------------------------------
# $self->saveform( $k )
#-------------------------------------------------
sub saveform {
	my ( $self, $k ) = @_;

	my $date = strftime( $$k{fmt_dt}, localtime() ); 	## Date

	## Path - if excel and not multiple files - this won't be used
	my $fname = $date . '-' . $self->{fname}; 		## Filename

	if ( $self->{store} eq 'stxt' ) { 				## Single Text File
		my $text = $self->text( $k );

		## Reset the filename and verify the extension
		$fname = $self->{fname};
		$fname = $fname . '.txt' if ( $fname !~ /\.txt$/ );
		
		if ( open( FILE, ">>$$k{file_path}/$fname" ) ) { 	## Append to file
				
			print FILE $text. "\n\n" . "-"x60 . "\n\n";

			close( FILE );
		}
		else {
			warn( "Unable to open $$k{file_path}/$fname: $!" );
		}
	}
	elsif ( $self->{store} eq 'scsv' ) { 				## Single CSV File
		my ( $qcsv, $acsv ) = $self->csv( $k );

		## Reset the filenane and verify the extension
		$fname = $self->{fname};
		$fname = $fname . '.csv' if ( $fname !~ /\.csv$/ );

		my $phead = ( -f "$$k{file_path}/$fname" ) ? 0 : 1;

		## If it already exists
		if ( open( FILE, ">>$$k{file_path}/$fname" ) ) {
			print FILE $qcsv . "\n" if ( $phead );
			print FILE $acsv . "\n";
			close( FILE );
		}
		else {
			warn( "Unable to open $$k{file_path}/$fname: $!" );
		}
	}
	elsif ( $self->{store} eq 'shtml' ) { 			## Single HTML files
		my @lines = $self->html( $k );

		## Reset the filename and verify the extension
		$fname = $self->{fname};
		$fname = $fname . '.html' if ( $fname !~ /\.html$/ );

		if ( open( FILE, ">>$$k{file_path}/$fname" ) ) {
			
			for my $line ( @lines ) {
				print FILE "$line\n";
			}

			print FILE ht_br() . "\n";
				
			close( FILE );
		}
		else {
			warn( "Unable to open $$k{file_path}/$fname: $!" );
		}
	}

	return();
} # END $self->saveform

##------------------------------------------------------------
## FORMATS
##------------------------------------------------------------

#-------------------------------------------------
# $self->text( $k )
#-------------------------------------------------
sub text {
	my ( $self, $k ) = @_;

	my $date = strftime( $$k{fmt_dt}, localtime() );
	
	my $text = $self->{name}. " "x35 . $date . "\n\n";
	
	my %data = %{$self->{data}};

	## For text - we want a 'proper count' - not the element numbers
	my $count = 1;

	for my $numb ( sort { $a <=> $b } keys( %data ) ) {
		my ( $name, $value ) = @{$data{$numb}};
		
		$value =~ s/"/\\"/g;
		$value =~ s/(\r\n|\r|\n)/\n/g;

		$text .= "$count) $name\n". wrap( "\t", "\t", $value ) . "\n\n";
		$count++;
	}
	
	return( $text );
} # END $self->text

#-------------------------------------------------
# $self->html( $k )
#-------------------------------------------------
sub html {
	my ( $self, $k ) = @_;

	my $date = strftime( $$k{fmt_dt}, localtime() );
	my %data = %{$self->{data}};

	my @lines = ( 	ht_table(),
					ht_tr(),
					ht_td( { 'class' => 'hdr' }, ht_b( $self->{'name'} ) ),
					ht_td( { 'class' => 'rhdr' }, $date ),
					ht_utr() );

	for my $numb ( sort { $a <=> $b } keys %data ) {
		my ( $name, $value ) = @{$data{$numb}};

		$value =~ s/"/\\"/g;
		$value =~ s/(\r\n|\r|\n)/\\n/g;

		my @html;
		for my $item ( split( /\\n/, $value ) ) {
			push( @html, ht_qt( $item ), ht_br() );
		}
	
		push( @lines, 	ht_tr(),
						ht_td( 	{ 'class' => 'shd', 'valign' => 'top' }, 
								ht_b( $name ) ),
						ht_td( { 'class' => 'dta', 'valign' => 'top' }, @html ),
						ht_utr() );
	}

	return( @lines, ht_utable() );
} # END $self->html

#-------------------------------------------------
# $self->csv( $k )
#-------------------------------------------------
sub csv {
	my ( $self, $k ) = @_;

	my $qrow	= '';
	my $arow	= '';
	my $csv		= '';
	
	my %data = %{$self->{data}};

	for my $numb ( sort { $a <=> $b } keys( %data ) ) {
		my ( $name, $value ) = @{$data{$numb}};

		$value =~ s/"/""/g;
		$name =~ s/"/""/g;

		$value = "\"$value\"" 	if ( $value =~ /,/ || $value =~ /"/ );
		$name = "\"$name\"" 	if ( $name =~ /,/ || $name =~ /"/ );
		

		$qrow .= "$name,";
		$arow .= "$value,";
	}
	
	$qrow =~ s/, $//;
	$arow =~ s/, $//;
	
	return( $qrow, $arow );
} # END $self->csv

#EOF
1;

__END__

=head1 NAME 

Alchemy::FormBuilder::Viewer::Output - FormBuilder Object for Sending/Creating
                                       Output

=head1 SYNOPSIS

 use Alchemy::FormBuilder::Viewer::Output;

=head1 DESCRIPTION 

This module provides the object for output by the FormBuilder. In order to 
create the object:

  my $out = Alchemy::FormBuilder::Viewer::Output->new();

To setup the environment for the object - pass it the global site hash, a
reference to the input hash, a reference to the form data hash from the 
database, and a reference to the element data hash from the database

  $out->prep_data( $k, \%in, \%form, \%elem );

Actions that the object performs, all take in the global site hash:

  $out->notify( $k );

  $out->send_inline( $k );

  $out->email( $k );
      
  $out->saveform( $k );

=head1 APACHE 

None.

=head1 DATABASE

None.

=head1 FUNCTIONS

  new()
    Creates a new output object
    
  prep_data( $k, $in, $form, $elem )
    Populates the environment for the output object. Sets information 
    regarding the:

      elements - a data hash that references each element by a 
                 counter in order to keep all elements in the 
                 order as arranged in the database
               - data hash that contains each element, referenced 
                 only by its name

      form     - a data hash that contains certain elements from 
                 the database
      
      input    - the input data from the form posting, referenced 
                 only by the name as provided by the submission
    
  notify( $k )
    This sends a notification to the user that a form submission has 
    occured. The format of the email is:

      There has been a submission to form: <form_name>

      The submission occured at: <fmt_dt>
      
    If there were any file uploads, the following line is also added 
    to the body of the message:

      The following files were uploaded to <File_Path/Directory>:
          <file 1>
          <file 2>
          ...
          <file n>

  send_inline( $k )
    This sends an email containing the name, value pairs upon submission
    of a form. The format of the email is text and is either defined by a
    text template by the user (see Alchemy::FormBuilder::Form(3), or is
    presented in the following format:

      <form_name>                         <fmt_dt>

      1) <name>
          <value>
    
      2) <name>
          <value>

      ...

      n) <name>
          <value>
        
    The count of 1), 2), etc., is incremental and is based on the 
    ordering of the data elements as found in the database.
    
  email( $k )
    This sends an email of the information posted in the way that is 
	specified in the form, be it attached text, or attached HTML. If it
	is attached text, it is done similarly to that of the send_inline
	function. If it is attached HTML it is done analagous to that of
	text, if there is no template to follow - the generic format is:

      <table>
        <tr>
          <td class="hdr">
            <b><form_name></b>
          </td>
          <td class="rhdr">
            <fmt_dt>
          </td>
        </tr>
        <tr>
          <td class="shd">
            <b><name></b>
          </td>
          <td class="dta">
            <value>
          </td>
        </tr>
        ...
        <tr>
          <td class="shd">
            <b><name></b>
          </td>
          <td class="dta">
            <value>
          </td>
        </tr>
      </table>
      
    Note: For all instances of output where the submissions are 
    maintained in a single file, the whole file is sent as an attachment.
    
  saveform( $k )
    This saves the form as specified in the form details in the specified
    location.
    
=head1 SEE ALSO

Alchemy::FormBuilder(3), Alchemy::FormBuilder::Viewer(3), 
Alchemy::FormBuilder::Form(3), KrKit(3), perl(3)

=head1 LIMITATIONS

?

=head1 AUTHOR

Ron Andrews <ron.andrews@cognilogic.net>

=head1 COPYRIGHT AND LICENSE

Copyright (C) 2004 by Ron Andrews. All rights reserved.

You may distribute under the terms of either the GNU General Public
License or the Artistic License, as specified in the Perl README file.

=cut
