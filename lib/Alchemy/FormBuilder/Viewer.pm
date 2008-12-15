package Alchemy::FormBuilder::Viewer;

use strict;
use Apache2::Request qw();
use File::Copy;
use POSIX qw( strftime );

use KrKit::DB;
use KrKit::HTML qw( :all );
use KrKit::SQL;
use KrKit::Validate;

use Alchemy::FormBuilder;
use Alchemy::FormBuilder::Viewer::Output;

our @ISA = ( 'Alchemy::FormBuilder' );

############################################################
# Functions                                                #
############################################################

#-------------------------------------------------
## $k->_checkvals( $in, $elem )
#-------------------------------------------------
sub _checkvals {
	my ( $k, $in, $elem ) = @_; # $elem - element data

	my ( %valid, @errors );

	my $sth = db_query( $$k{dbh}, 'Get all validation',
						'SELECT id, regex, func FROM form_validate' );
						
	while ( my ( $id, $regex, $func ) = db_next( $sth ) ) {
		$valid{$id} = { 'regex' => $regex, 'func' => $func };
	}

	db_finish( $sth );

	for my $key ( sort { $a <=> $b } keys %{$elem} ) {
		
		my $el = $$elem{$key};

		# If an element is required for the current page - check it
		next if ( ! $$el{req} || ( $$el{page} ne $$in{prev_page} ) );
		
		my $func	= $valid{$$el{reqid}}{func} || '';
		my $regex	= $valid{$$el{reqid}}{regex} || '';

		if ( $func eq 'is_date' && ! is_date( $$in{$$el{name}} ) ) {
			push( @errors, ht_li( {}, $$el{error} ) );
		}
		elsif ( $func eq 'is_email' && ! is_email( $$in{$$el{name}} ) ) {
			push( @errors, ht_li( {}, $$el{error} ) );
		}
		elsif ( $func eq 'is_float' && ! is_float( $$in{$$el{name}} ) ) {
			push( @errors, ht_li( {}, $$el{error} ) );
		}
		elsif ( $func eq 'is_ident' && ! is_ident( $$in{$$el{name}} ) ) {
			push( @errors, ht_li( {}, $$el{error} ) );
		}
		elsif ( $func eq 'is_integer' && ! is_integer( $$in{$$el{name}} ) ) {
			push( @errors, ht_li( {}, $$el{error} ) );
		}
		elsif ( $func eq 'is_ip' && ! is_ip( $$in{$$el{name}} ) ) {
			push( @errors, ht_li( {}, $$el{error} ) );
		}
		elsif ( $func eq 'is_mac' && ! is_mac( $$in{$$el{name}} ) ) {
			push( @errors, ht_li( {}, $$el{error} ) );
		}
		elsif ( $func eq 'is_number' && ! is_number( $$in{$$el{name}} ) ) {
			push( @errors, ht_li( {}, $$el{error} ) );
		}
		elsif ( $func eq 'is_text' && ! is_text( $$in{$$el{name}} ) ) {
			push( @errors, ht_li( {}, $$el{error} ) );
		}
		elsif ( $func eq 'is_time' && ! is_time( $$in{$$el{name}} ) ) {
			push( @errors, ht_li( {}, $$el{error} ) );
		}
		elsif ( $regex ne '' ) { ## A regex
			eval {
				if ( $$in{$$el{name}} !~ /$regex/ ) {
					push( @errors, ht_li( {}, $$el{error} ) );
				}
			};

			if ( $@ ) {
				push( @errors, ht_li( {}, 'Unable to validate: '. 
											ht_b( $$el{name} ) ) );
			}
		}
		elsif( ! $$in{$$el{name}} ) {
			push( @errors, ht_li( {}, $$el{error} ) );
		}
	}	

	## Done with checkvals - if there are errors, reset the page numbering
	if ( @errors ) {
		$$in{cur_page} 	= $$in{cur_page} - 1;
		$$in{prev_page} = $$in{prev_page} - 1;

		return( ht_div( { 'class' => 'error' },
						ht_h( 1, 'Errors:' ), ht_ul( {}, @errors ) ) );
	}

	return();
} # END $k->_checkvals

#-------------------------------------------------
# $k->_element( $in, $el )
#-------------------------------------------------
sub _element {
	my ( $k, $in, $el ) = @_; 	##	$el		- element data hash

	my ( @lines, @params );
	
	push( @params, 'readonly' )					if ( $$el{read} );
	push( @params, "rows=\"$$el{row}\"" ) 		if ( $$el{row} );
	push( @params, "cols=\"$$el{col}\"" ) 		if ( $$el{col} );
	push( @params, "sizes=\"$$el{size}\"" ) 	if ( $$el{size} );
	push( @params, "class=\"$$el{css}\"" ) 		if ( $$el{css} );
	push( @params, "src=\"$$el{src}\"" ) 		if ( $$el{src} );
	push( @params, "alt=\"$$el{alt}\"" ) 		if ( $$el{alt} );
	push( @params, "maxlength=\"$$el{max}\"" )	if ( $$el{max} );
	push( @params, $$el{param} )				if ( $$el{param} );

	my $name = $$el{name};

	## Replace date, time, timestamp
	my $time 	= strftime( $$k{fmt_t}, localtime( time ) );
	my $date 	= strftime( $$k{fmt_d}, localtime( time ) );
	my $ts 		= strftime( $$k{fmt_dt}, localtime( time ) );
	my $dfix 	= sub { my ( $a, $b, $c ) = @_; 
						return( $a ) if ( ! defined $a );	
					 	$a =~ s/$b/$c/i; 
						return($a); };

	## Is our value data or time?
	$$el{value} = &$dfix( $$el{value}, '##TIME##', $time );
	$$in{$name} = &$dfix( $$in{$name}, '##TIME##', $time );

	$$el{value} = &$dfix( $$el{value}, '##DATE##', $date );
	$$in{$name} = &$dfix( $$in{$name}, '##DATE##', $date );
	$$el{value} = &$dfix( $$el{value}, '##TIMESTAMP##', $ts );
	$$in{$name} = &$dfix( $$in{$name}, '##TIMESTAMP##', $ts );

	## Construction -----------------------------------------------------------
	if ( $$el{type} =~ /^textarea|reset|password|hidden$/i ) { 
		push( @lines, ht_input( $name, $$el{type}, $in, @params ) );
	}
	elsif ( $$el{type} =~ /^text_field$/i ) { 					## Text Field
		push( @lines, ht_input( $name, 'text', $in, @params ) );
	}
	elsif ( $$el{type} =~ /^submit$/i && $$el{src} ne '' ) {	## Submit-Img
		push( @lines, ht_input( $name, 'image', $$el{value}, @params ) );
	}
	elsif ( $$el{type} =~ /^submit$/i ) { 						## Submit
		push( @lines, ht_input( $name, 'submit', $$el{value}, @params ) );
	}
	elsif ( $$el{type} =~ /^radio$/i ) { 						## Radio
		push( @lines, ht_radio( $name, $$el{value}, $in, @params ) );
	} 
	elsif ( $$el{type} =~ /^checkbox$/i ) { 					## Checkbox
		push( @lines, ht_checkbox( $name, $$el{value}, $in, @params ) );
	}
	elsif ( $$el{type} =~ /^select$/i ) { 						## Select

		my @items;
		
		$$el{value} =~ s/^"//;
		$$el{value} =~ s/"$//;

		for my $i ( split( /","/,  $$el{value} ) ) {
			push( @items, ( split( /::/, $i ) )[1,0] );
		}
		
		push( @lines, ht_select( $name, $$el{size}, $in, $$el{mult},
								join( ' ', @params ), @items ) );
	}
	elsif ( $$el{type} =~ /^button$/i && $$el{src} ne '' ) { 	## Button-Img
		push( @lines, ht_input( $name, 'image', $$el{value}, @params ) );
	}
	elsif ( $$el{type} =~ /^button$/i ) { 						## Button
		push( @lines, ht_input( $name, 'button', $$el{value}, @params ) );
	}
	elsif ( $$el{type} =~ /^upload$/i ) { 						## Upload
		push( @lines, ht_input( $name, 'file', $in, @params ) );
	}
	elsif( $$el{type} !~ /^html$/i ) {
		push( @lines, ht_b( $$el{type} ), 'is not defined.', ht_br() );
	}
	
	return( $$el{pre}, @lines, $$el{post} );
} # END $k->_element

#-------------------------------------------------
## $k->_form( $in, $elem );
#-------------------------------------------------
sub _form {
	my ( $k, $in, $elem ) = @_;
	# $elem - element data hash 
	
	my @lines;
	my $file = 0;
	my %used; ## no duplicates.....

	## Current page Elements
	for my $e ( sort { $a <=> $b } keys( %{$elem} ) ) {
		next if ( $$elem{$e}{page} ne $$in{cur_page} );
		
		push( @lines, $k->_element( $in, $$elem{$e} ) );

		$file = 1 if ( $$elem{$e}{type} =~ /^upload$/i );
	}

	# Hidden Elements. (Elements not on the current page -- with data)
	for my $key ( keys %$in ) {
		next if ( ! defined $$elem{$key}{name} );
		next if ( ! defined $$elem{$key}{type} );
		next if ( $$elem{$key}{name} =~ /^prev_page|cur_page$/i );
		next if ( $$elem{$key}{type} =~ /^submit|reset$/i );

		my $disp = 0;
		for my $e ( keys %{$elem} ) {
			if ( $$elem{$e}{name} eq $key && 
					$$elem{$e}{page} ne $$in{cur_page} ) {

				$disp = 1;
			}
		}

		if ( ( $disp || $key =~ /^savedfile/ ) && ! defined $used{$key} ) {
			push( @lines, ht_input( $key, 'hidden', $in ) );
		}	
			
		$used{$key} = 1; ## duplicates..
	}

	## Finish
	return( ht_form_js( $$k{uri}, 
						( $file ? 'enctype="multipart/form-data"' : '' )  ),
			@lines, 
			ht_input( 'prev_page', 'hidden', $in ),
			ht_input( 'cur_page', 'hidden', $in ),
			ht_uform() );
} # END $k->_form

#-------------------------------------------------
# $k->do_main( $r )
#-------------------------------------------------
sub do_main {
	my ( $k, $r ) = @_;

	$$k{page_title}	.=	'Main Listing of Viewable Forms';
	my $in			= $k->param( Apache2::Request->new( $r ) );

	my @lines 	= ( ht_table(),
					ht_tr(),
					ht_td( { 'class' => 'hdr' }, 'Listing of Forms' ),
					ht_utr() );

	my $sth = db_query( $$k{dbh}, 'Get list of active of forms',
						'SELECT ident, name, description FROM form_data ',
						'WHERE active = \'t\' AND \'now\' BETWEEN start_date',
						'AND stop_date ORDER BY start_date, name' );

	while ( my ( $ident, $name, $descr ) = db_next( $sth ) ) {
		push( @lines, 	ht_tr(),
						ht_td( { 'class' => 'shd' },
								ht_a( "$$k{rootp}/view/$ident", $name ) ),
						ht_utr(),

						ht_tr(),
						ht_td( {}, $descr ),
						ht_utr() );
	}

	if ( db_rowcount( $sth ) < 1 ) {
		push( @lines, 	ht_tr(),
						ht_td( 	{ 'class' => 'cdta' },
								'There are no active forms to display.' ),
						ht_utr() );
	}

	db_finish( $sth );

	return( @lines, ht_utable() );
} # END $k->do_main

#-------------------------------------------------
# $k->do_view( $r, $ident )
#-------------------------------------------------
sub do_view {
	my ( $k, $r, $ident, $preview ) = @_;

	# FIXME: If preview, prevent saving of data.

	return( 'Invalid ID.' ) if ( ! is_ident( $ident ) );

	my $apr 	= Apache2::Request->new( $r, TEMP_DIR => $$k{file_tmp} );
	my $in 		= $k->param( $apr );

	## Defaults
	$$in{prev_page}	= $$in{cur_page} 		if ( defined $$in{cur_page} );
	$$in{cur_page}	= $$in{cur_page} + 1 	if ( defined $$in{cur_page} );
	$$in{prev_page}	= 0 					if ( ! defined $$in{prev_page} );
	$$in{cur_page}	= 1 					if ( ! defined $$in{cur_page} );

	my @where = (	'AND \'now\' BETWEEN start_date AND stop_date ',
					'AND active = \'t\'' );

	my $sth = db_query( $$k{dbh}, 'Get form values',
						'SELECT id, active, page_count, number_of_elements, ',
						'name, email_address, email_subject, redirect_cancel, ',
						'redirect_confirm, frame, store_as, send_as, ',
						'filename, description, confirm_page, ',
						'send_email FROM form_data WHERE ident = ',
						sql_str( $ident ), ( $preview ? '' : @where ) );

	## Bad form
	if ( db_rowcount( $sth ) < 1 ) {
		db_finish( $sth );
		return( $k->_decline() ); # Generate a 404 page.
	}

	my ( $id, $active, $pcount, $numel, $name, $email, $subject, $redircancel,
		$redirconfirm, $frame, $store, $send_as, $fname, $descr,
		$confirm, $send ) = db_next( $sth );

	db_finish( $sth );

	$confirm = '' if ( ! defined $confirm );

	my %form = ( 	'id'			=> $id,
					'active'		=> $active,
					'pcount'		=> $pcount,
					'numel'			=> $numel,
					'name'			=> $name,
					'email'			=> $email,
					'subject'		=> $subject,
					'redircancel'	=> $redircancel,
					'redirconfirm'	=> $redirconfirm,
					'confirm'		=> "$$k{doc_root}/$confirm",
					'store'			=> $store,
					'send_as'		=> $send_as,
					'fname'			=> $fname,
					'descr'			=> $descr,
					'send'			=> $send,
					'ident'			=> $ident, );

	## Site properties
	$$k{frame}		= $frame;
	$$k{page_title}	.= $name;
	
	## Defaults
	$form{confirm} =~ s/\/\//\//g;
	$form{confirm} = '' if ( ! -T $form{confirm} );

	if ( ! $form{confirm} && ! $form{redirconfirm} ) {
		$form{redirconfirm} = $form{redircancel};
	}
	
	## Cancel
	if ( $$in{cancel} || $$in{Cancel} || $$in{CANCEL} ) {
		return( $k->_relocate( $r, $form{redircancel} ) );
	}

	## Element Data -----------------------------------------------------------
	my $rth = db_query( $$k{dbh}, 'Get all element values',
						'SELECT e.id, e.required, e.checked, e.readonly,',
						'e.multiple, e.form_validate_id, e.max_length,',
						'e.tab_index, e.row_count, e.col_count, e.size_count,',
						'e.question_number, e.page_number, e.name, e.value,',
						'e.css_class, e.src, e.alt, e.addition_params, ',
						'e.pre_text, e.post_text, e.error_msg, t.type ',
						'FROM form_element AS e, form_types AS t WHERE ',
						'e.form_data_id = ', sql_num( $form{id} ), 
						'AND e.form_types_id = t.id ',
						'ORDER BY e.page_number, e.question_number, ',
						'e.tab_index' );

	my %elem;
	my $counter = 0;
	my @upnames; ## For file uploads
	
	while ( my( $id, $req, $check, $read, $mult, $reqid, $max, $tab, $row, 
				$col, $size, $quest, $page, $name, $value, $css, $src,
				$alt, $param, $pre, $post, $error, $type ) = db_next( $rth ) ) {
			
		$elem{$counter++} = {	'id'	=> $id,
								'req'	=> $req,
								'check'	=> $check,
								'read'	=> $read,
								'mult'	=> $mult,
								'reqid'	=> $reqid,
								'max'	=> $max,
								'tab'	=> $tab,
								'row'	=> $row,
								'col'	=> $col,
								'size'	=> $size,
								'quest'	=> $quest,
								'page'	=> $page,
								'name'	=> $name,
								'value'	=> $value,
								'css'	=> $css,
								'src'	=> $src,
								'alt'	=> $alt,
								'param'	=> $param,
								'pre'	=> $pre,
								'post'	=> $post,
								'error'	=> $error,
								'type'	=> $type	};

		## If there are file uploads - we need to track them
		if ( defined $type && $type =~ /^upload$/i && $$in{$name} ne '' ) {
			push( @upnames, $name );
		}
	}

	db_finish( $rth );

	## BEGIN
	if ( ( my @err = $k->_checkvals( $in, \%elem ) ) ) {
		return( ( $r->method eq 'POST' ? @err : '' ), $k->_form($in, \%elem) );
	}

	## If there is a file to upload - temp and move it upon success
	my $now = time;

	for my $n ( @upnames ) {
		## If the upload is for this page... then do it - otherwise don't...
		my $p;
		for my $k ( keys %elem ) {
			if ( $elem{$k}{name} eq $n ) {
				$p = $elem{$k}{page};
				last;
			}
		}

		if ( defined $$in{$n} && $$in{prev_page} eq $p ) {
			my $upload 			= $apr->upload( $n );
			my $type 			= $upload->type();
			my ( $t, $fname ) 	= $upload->filename =~ /^(.*\\|.*\/)?(.*?)?$/;
			$type 				=~ s/\//_/g;
			$fname 				=~ s/--/-/g;
			
			## if there already existed a file for this element - remove it
			if ( defined $$in{'savedfile'.$n} ) {
				unlink( "$$k{file_tmp}/$$in{'savedfile'.$n}" );
			}

			$upload->link( "$$k{file_tmp}/$now--$type--$fname" );

			$$in{'savedfile'.$n} = "$now--$type--$fname";
		}
	}

	if ( $$in{prev_page} eq $form{pcount} ) { ## last page - DONE
			
		my $out = Alchemy::FormBuilder::Viewer::Output->new();

		$out->prep_data( $k, $in, \%form, \%elem );

		## Figure out what to send 
		if ( $form{send} == 2 ) { 								## Notify
			$out->notify( $k );
		}
		elsif ( $form{send} && $form{send_as} eq 'inline' ) {	## Send
			$out->send_inline( $k );
		}
		elsif ( $form{send} ) {
			$out->email( $k );
		}
		
		$out->saveform( $k );

		## Save any/all uploaded files
		for my $n ( @upnames ) {
			next if ( ! defined $$in{$n} );
				
			# Copy from $$in{savefile.$n} to $path/$fname 
			if ( copy( 	"$$k{file_tmp}/$$in{'savedfile'.$n}", 
						"$$k{file_path}/$now--$$in{$n}" ) ) {
				unlink( "$$k{file_tmp}/$$in{'savedfile'.$n}" );
			}
		}
			
		if ( ! $form{confirm} ) {
			return( $k->_relocate( $r, $form{redirconfirm} ) );
		}
		else {
			open( FILE, "<$form{confirm}" ) or
				$r->log_error( 'Unable to open the confirmation file.' );

			my @contents;

			for my $line ( <FILE> ) {
				for my $key ( keys %$in ) {
					my $data = ht_qt( $$in{$key} );
					$line =~ s/##\s*$key\s*##/$data/g;
				}
				push( @contents, $line );
			}
			
			close( FILE );
			
			return( @contents );
		}
	}
			
	return( $k->_form( $in, \%elem ) ); ## next page
} # END $k->do_view

#EOF
1

__END__

=head1 NAME 

Alchemy::FormBuilder::Viewer - FormBuilder Form Listing and Viewer 

=head1 SYNOPSIS

 use Alchemy::FormBuilder::Viewer;

=head1 DESCRIPTION 

This module provides the interface for listing and viewing the forms
available in the database. It has a do_view function to provide access
to view and preview forms.
     
=head1 APACHE 
         
This is a sample of the location required for this module to run.
Consult Alchemy::FormBuilder(3) to learn about the global configuration 
options.

  <Location /form >
    SetHandler perl-script

    PerlHandler Alchemy::FormBuilder::Viewer
  </Location> 

Requires location information required for FormBuilder.pm

=head1 DATABASE

This module reads from the following tables, no manipulation occurs from
this module.

  form_data
  form_element
  form_types
  form_validate

=head1 FUNCTIONS

This module provides the following functions:

  $k->do_main( $r )
    Provides a listing of all active forms in the database - for viewing 
    forms

  $k->do_view( $r, $ident, $preview )
    Provides an active form for use - for validation and output
    
=head1 SEE ALSO

Alchemy::FormBuilder(3), Alchemy::FormBuilder::Viewer::Output(3), KrKit(3), 
perl(3)

=head1 LIMITATIONS

Currently, none are defined.

=head1 AUTHOR

Ron Andrews <ron.andrews@cognilogic.net>

=head1 COPYRIGHT AND LICENSE
Copyright (c) 2000-2004 by Ron Andrews. All rights reserved.

You may distribute under the terms of either the GNU General Public
License or the Artistic License, as specified in the Perl README file.

=cut
