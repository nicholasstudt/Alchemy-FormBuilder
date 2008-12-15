package Alchemy::FormBuilder::Form::Element::Types;

use strict;

use KrKit::DB;
use KrKit::HTML qw( :all );
use KrKit::SQL;
use KrKit::Validate;

use Alchemy::FormBuilder;

our @ISA = ( 'Alchemy::FormBuilder' );

############################################################
# Functions                                                #
############################################################

#-------------------------------------------------
# $k->_checkvals( $in )
#-------------------------------------------------
sub _checkvals {
	my ( $k, $in ) = @_;

	my @errors;

	## Type
	if ( ! is_text( $$in{type} ) ) {
		push( @errors, ht_li( {}, 	'A', ht_b( 'Type' ), 
									'must be given for it to be added.' ) );
	}
	else {
		my $sth = db_query( $$k{dbh}, 'Get duplicate type name',
							'SELECT id FROM form_types WHERE type = ',
							sql_str( $$in{'type'} ) );

		my $found = db_next( $sth ) || 0;

		if ( $found && $found ne $$in{eid} ) {
			push( @errors, ht_li( {}, 	'A', ht_b( 'Type' ), 
										'already exists with that name.' ) );
		}

		db_finish( $sth );
	}

	if ( @errors ) {
		return( ht_div( { 'class' => 'error' },
						ht_h( 1, 'Errors' ), ht_ul( {}, @errors ) ) );
	}

	return();
} # END $k->_checkvals

#-------------------------------------------------
# $k->_form( $in )
#-------------------------------------------------
sub _form {
	my ( $k, $in ) = @_;

	return( ht_form_js( $$k{uri} ),
			ht_table(),

			ht_tr(),
			ht_td( { 'class' => 'hdr', 'colspan' => '2' }, 
					'Element Type Information' ),
			ht_utr(),

			ht_tr(),
			ht_td( { 'colspan' => '2' },
					'Note: The existence of an Error Message implies that ',
					'the field is required for an element of this type.',
					'A', ht_i( 0 ), 'implies not required.' ),
			ht_utr(),

			## Type
			ht_tr(),
			ht_td( { 'class' => 'shd' }, 'Type:' ),
			ht_td( {}, 	ht_input( 'type', 'text', $in ),
						ht_help( $$k{help}, 'item', 'a:fb:f:e:t:type' ) ),
			ht_utr(),
			
			## Name 
			ht_tr(),
			ht_td( { 'class' => 'shd' }, 'Name Error Mesg:' ),
			ht_td( {}, 	ht_input( 'name', 'text', $in ),
						ht_help( $$k{help}, 'item', 'a:fb:f:e:t:name' ) ),
			ht_utr(),
			
			## Value
			ht_tr(),
			ht_td( { 'class' => 'shd' }, 'Value Error Msg:' ),
			ht_td( {}, 	ht_input( 'value', 'text', $in ),
						ht_help( $$k{help}, 'item', 'a:fb:f:e:t:value' ) ),
			ht_utr(),
			
			## Row Count
			ht_tr(),
			ht_td( { 'class' => 'shd' }, 'Row Count Error Msg:' ),
			ht_td( {}, 	ht_input( 'row', 'text', $in ),
						ht_help( $$k{help}, 'item', 'a:fb:f:e:t:row' ) ),
			ht_utr(),
			
			## Col Count
			ht_tr(),
			ht_td( { 'class' => 'shd' }, 'Col Count Error Msg:' ),
			ht_td( {}, 	ht_input( 'col', 'text', $in ),
						ht_help( $$k{help}, 'item', 'a:fb:f:e:t:col' ) ),
			ht_utr(),
			
			## Size Count
			ht_tr(),
			ht_td( { 'class' => 'shd' }, 'Size Count Error Msg:' ),
			ht_td( {}, 	ht_input( 'size', 'text', $in ),
						ht_help( $$k{help}, 'item', 'a:fb:f:e:t:size' ) ),
			ht_utr(),
			
			## Max Length
			ht_tr(),
			ht_td( { 'class' => 'shd' }, 'Max Length Error Msg:' ),
			ht_td( {}, 	ht_input( 'max', 'text', $in ),
						ht_help( $$k{help}, 'item', 'a:fb:f:e:t:max' ) ),
			ht_utr(),
			
			## Checked
			ht_tr(),
			ht_td( { 'class' => 'shd' }, 'Checked Error Msg:' ),
			ht_td( {}, 	ht_input( 'checkd', 'text', $in ),
						ht_help( $$k{help}, 'item', 'a:fb:f:e:t:check' ) ),
			ht_utr(),
			
			## Read Only
			ht_tr(),
			ht_td( { 'class' => 'shd' }, 'Read Only Error Msg:' ),
			ht_td( {}, 	ht_input( 'read', 'text', $in ),
						ht_help( $$k{help}, 'item', 'a:fb:f:e:t:read' ) ),
			ht_utr(),
			
			## Multiple Select 
			ht_tr(),
			ht_td( { 'class' => 'shd' }, 'Multiple Select Error Msg:' ),
			ht_td( {}, 	ht_input( 'mult', 'text', $in ),
						ht_help( $$k{help}, 'item', 'a:fb:f:e:t:mult' ) ),
			ht_utr(),
			
			## Tab Index
			ht_tr(),
			ht_td( { 'class' => 'shd' }, 'Tab Index Error Msg:' ),
			ht_td( {}, 	ht_input( 'tab', 'text', $in ),
						ht_help( $$k{help}, 'item', 'a:fb:f:e:t:tab' ) ),
			ht_utr(),
			
			## CSS Class
			ht_tr(),
			ht_td( { 'class' => 'shd' }, 'CSS Class Error Msg:' ),
			ht_td( {}, 	ht_input( 'css', 'text', $in ),
						ht_help( $$k{help}, 'item', 'a:fb:f:e:t:css' ) ),
			ht_utr(),
			
			## Source 
			ht_tr(),
			ht_td( { 'class' => 'shd' }, 'Source (src) Error Msg:' ),
			ht_td( {}, 	ht_input( 'src', 'text', $in ),
						ht_help( $$k{help}, 'item', 'a:fb:f:e:t:src' ) ),
			ht_utr(),
			
			## Alt 
			ht_tr(),
			ht_td( { 'class' => 'shd' }, 'Alt Error Msg:' ),
			ht_td( {}, 	ht_input( 'alt', 'text', $in ),
						ht_help( $$k{help}, 'item', 'a:fb:f:e:t:alt' ) ),
			ht_utr(),
			
			ht_tr(),
			ht_td( { 'class' => 'rshd', 'colspan' => '4' },
					ht_submit( 'submit', 'Save' ),
					ht_submit( 'cancel', 'Cancel' ) ),
			ht_utr(),
																			
			ht_utable(),
			ht_uform() );
} # END $k->_form

#-------------------------------------------------
# $k->do_add( $r )
#-------------------------------------------------
sub do_add {
	my ( $k, $r ) = @_;

	my $in 				= $k->param( Apache2::Request->new( $r ) );
	$$k{page_title}	.=	'Add Element Type';

	return( $k->_relocate( $r, $$k{rootp} ) ) if ( $$in{cancel} );

	if ( ! ( my @err = $k->_checkvals( $in ) ) ) {
		
		db_run( $$k{dbh}, 'Create a new Element Type',
				sql_insert( 'form_types',
							'type'		=> sql_str( $$in{type} ),
							'name'		=> sql_str( $$in{name} ),
							'value'		=> sql_str( $$in{value} ),
							'row'		=> sql_str( $$in{row} ),
							'col'		=> sql_str( $$in{col} ),
							'size'		=> sql_str( $$in{size} ),
							'max'		=> sql_str( $$in{max} ),
							'checkd'	=> sql_str( $$in{checkd} ),
							'read'		=> sql_str( $$in{read} ),
							'mult'		=> sql_str( $$in{mult} ),
							'tab'		=> sql_str( $$in{tab} ),
							'css'		=> sql_str( $$in{css} ),
							'src'		=> sql_str( $$in{src} ),
							'alt'		=> sql_str( $$in{alt} ) ) );

		db_commit( $$k{dbh} );

		return( $k->_relocate( $r, $$k{rootp} ) );
	}
	else {
		## Defaults
		$$in{name}		= 0 if ( ! defined $$in{name} );
		$$in{value}		= 0 if ( ! defined $$in{value} );
		$$in{row}		= 0 if ( ! defined $$in{row} );
		$$in{col}		= 0 if ( ! defined $$in{col} );
		$$in{size}		= 0 if ( ! defined $$in{size} );
		$$in{max}		= 0 if ( ! defined $$in{max} );
		$$in{checkd}	= 0 if ( ! defined $$in{checkd} );
		$$in{read}		= 0 if ( ! defined $$in{read} );
		$$in{mult}		= 0 if ( ! defined $$in{mult} );
		$$in{tab}		= 0 if ( ! defined $$in{tab} );
		$$in{css}		= 0 if ( ! defined $$in{css} );
		$$in{src}		= 0 if ( ! defined $$in{src} );
		$$in{alt}		= 0 if ( ! defined $$in{alt} );

		return( ( $r->method eq 'POST' ? @err : '' ), $k->_form( $in ) );
	}
} # END $k->do_add

#-------------------------------------------------
# $k->do_edit( $r, $id )
#-------------------------------------------------
sub do_edit {
	my ( $k, $r, $id ) = @_;

	my $in 				= $k->param( Apache2::Request->new( $r ) );
	$$k{page_title}	.=	'Edit Element Type';

	return( 'Invalid ID.' ) 					if ( ! is_integer( $id ) );
	return( $k->_relocate( $r, $$k{rootp} ) ) 	if ( $$in{cancel} );

	$$in{'eid'} = $id;

	if ( ! ( my @err = $k->_checkvals( $in ) ) ) {
		
		db_run( $$k{dbh}, 'Edit an Element Type',
				sql_update( 'form_types', 'WHERE id = '. sql_num( $id ),
							'type'		=> sql_str( $$in{type} ),
							'name'		=> sql_str( $$in{name} ),
							'value'		=> sql_str( $$in{value} ),
							'row'		=> sql_str( $$in{row} ),
							'col'		=> sql_str( $$in{col} ),
							'size'		=> sql_str( $$in{size} ),
							'max'		=> sql_str( $$in{max} ),
							'checkd'	=> sql_str( $$in{checkd} ),
							'read'		=> sql_str( $$in{read} ),
							'mult'		=> sql_str( $$in{mult} ),
							'tab'		=> sql_str( $$in{tab} ),
							'css'		=> sql_str( $$in{css} ),
							'src'		=> sql_str( $$in{src} ),
							'alt'		=> sql_str( $$in{alt} ) ) );

		db_commit( $$k{dbh} );

		return( $k->_relocate( $r, $$k{rootp} ) );
	}
	else {
		my $sth = db_query( $$k{dbh}, 'Get element type info',
							'SELECT type, name, value, row, col, size, max, ',
							'checkd, read, mult, tab, css, src, alt FROM ',
							'form_types WHERE id = ', sql_num( $id ) );

		my ( $type, $name, $value, $row, $col, $size, $max, $check, $read,
				$mult, $tab, $css, $src, $alt ) = db_next( $sth );

		db_finish( $sth );

		$$in{type}		= $type		if ( ! defined $$in{type} );
		$$in{name}		= $name		if ( ! defined $$in{name} );
		$$in{value}		= $value	if ( ! defined $$in{value} );
		$$in{row}		= $row		if ( ! defined $$in{row} );
		$$in{col}		= $col		if ( ! defined $$in{col} );
		$$in{size}		= $size		if ( ! defined $$in{size} );
		$$in{max}		= $max		if ( ! defined $$in{max} );
		$$in{checkd}	= $check	if ( ! defined $$in{checkd} );
		$$in{read}		= $read		if ( ! defined $$in{read} );
		$$in{mult}		= $mult		if ( ! defined $$in{mult} );
		$$in{tab}		= $tab		if ( ! defined $$in{tab} );
		$$in{css}		= $css		if ( ! defined $$in{css} );
		$$in{src}		= $src		if ( ! defined $$in{src} );
		$$in{alt}		= $alt		if ( ! defined $$in{alt} );

		return( ( $r->method eq 'POST' ? @err : '' ), $k->_form( $in ) );
	}
} # END $k->do_edit

#-------------------------------------------------
# $k->do_delete( $r, $id, $yes )
#-------------------------------------------------
sub do_delete {
	my ( $k, $r, $id ,$yes ) = @_;

	my $in 				= $k->param( Apache2::Request->new( $r ) );
	$$k{page_title}	.=	'Delete Element Type';

	return( 'Invalid ID.') 						if ( ! is_integer( $id ) );
	return( $k->_relocate( $r, $$k{rootp} ) ) 	if ( defined $$in{cancel} );

	if ( defined $yes && $yes eq 'yes' ) {
		
		## If some forms are using this type - they will need to be updated
		## first - else the form is left broken.....
		my $sth = db_query( $$k{dbh}, 'Look for elements using type',
							'SELECT id FROM form_element WHERE ',
							'form_types_id = ', sql_num( $id ), 
							'AND NOT id = ', sql_num( '0' ) ); 

		if ( db_rowcount( $sth ) > 0 ) {
			my $count = db_rowcount( $sth );

			db_finish( $sth );
			
			return( ht_form_js( "$$k{rootp}/delete/$id" ),
					ht_table(),

					ht_tr(),
					ht_td( { 'class' => 'dta' },
						'This element type cannot be deleted at this time.',
						ht_br(),
						'It is currently being used by ' . ht_b( $count ) . 
						' elements. You must change the form types of these ',
						'elements before this type may be removed.' ),
					ht_utr(),

					ht_tr(),
					ht_td( { 'class' => 'rshd' },
							ht_submit( 'cancel', 'OK' ) ),
					ht_utr(),

					ht_utable(),
					ht_uform() );
		}
			
		db_finish( $sth );

		db_run( $$k{dbh}, 'Delete an Element Type',
				'DELETE FROM form_types WHERE id = ', sql_num( $id ) );

		db_commit( $$k{dbh} );
		
		return( $k->_relocate( $r, $$k{rootp} ) );
	}
	else {
		my $sth = db_query( $$k{dbh}, 'Get element type info',
							'SELECT type FROM form_types WHERE id = ',
							sql_num( $id ) );

		my $name = db_next( $sth );

		db_finish( $sth );

		return( ht_form_js( "$$k{uri}/yes" ),
				ht_table(),
				ht_tr(),
				ht_td( {}, 	'Delete the element type: "'. ht_b( $name ). '"?',
							ht_br(), 'This will completely remove this type.' ),
				ht_utr(),

				ht_tr(),
				ht_td( { 'class' => 'rshd' },
						ht_submit( 'submit', 'Continue with Delete' ),
						ht_submit( 'cancel', 'Cancel' ) ),
				ht_utr(),

				ht_utable(),
				ht_uform() );
	}
} # END $k->do_delete

#-------------------------------------------------
# $k->do_main( $r )
#-------------------------------------------------
sub do_main {
	my ( $k, $r ) = @_;
	
	$$k{'page_title'}	.=	'Element Types and Validation';

	my @lines = (
		ht_div( { 'class' => 'box' } ),
		ht_table(),

		ht_tr(),
		ht_td( { 'class' => 'hdr', 'colspan' => '2' },
				'Element Types and their Error Messages' ),
		ht_utr(),
		ht_tr(),
		ht_td( { 'colspan' => '2' },
				ht_b( 'Note:' ), 'It is important to be aware that adding ',
				'a new type does not mean that the type will work. If a ',
				'type is added here it is accessible via the builder, but ',
				'is only usable by the viewer if it is added to the ',
				'code.' ),
		ht_utr(),

		ht_tr(),
		ht_td( { 'class' => 'shd' }, 'Type Name',
				ht_help( $$k{help}, 'item', 'a:fb:f:e:t:name' ) ),
		ht_td( { 'class' => 'rshd' },
				'[', ht_a( "$$k{rootp}/add", 'Add Type' ), ']' ),
		ht_utr() );

	my $sth = db_query( $$k{dbh}, 'Get element types',
						'SELECT id, type FROM form_types ORDER BY type' );

	while ( my ( $id, $name ) = db_next( $sth ) ) {
		push( @lines, 	ht_tr(),
						ht_td( {}, $name ),
						ht_td( { 'class' => 'rdta'},
								'[',
								ht_a( "$$k{rootp}/edit/$id", 'Edit' ), '|',
								ht_a( "$$k{rootp}/delete/$id", 'Delete' ), 
								']' ),
						ht_utr() );
	}

	if ( db_rowcount( $sth ) < 1 ) {
		push( @lines, 	ht_tr(),
						ht_td( { 'class' => 'cdta', 'colspan' => '2' },
								'There are no element types to display.' ),
						ht_utr() );
	}

	db_finish( $sth );

	return( @lines, ht_utable(), ht_udiv() );
} # END $k->do_main

#EOF
1;

__END__

=head1 NAME 

Alchemy::FormBuilder::Form::Element::Types - FormBuilder Element Types

=head1 SYNOPSIS

 use Alchemy::FormBuilder::Form::Element::Types;

=head1 DESCRIPTION

This module provides the interface for list, edit, create, and delete
with respect to the form element types listed in the database.

=head1 APACHE

This is a sample of the location required for this module to run.
Consult Alchemy::FormBuilder(3) to learn about the configuration
options.

  <Location /admin/forms/types >
    SetHandler perl-script

    PerlSetVar  SiteTitle    "FormBuilder - "
    PerlSetVar  Frame        "template;FormBuilder.tp"
    
    PerlHandler Alchemy::FormBuilder::Form::Element::Types
  </Location>

=head1 DATABASE

This is the core table this module manipulates:

  create table "form_types" (
    "id" integer primary key not null
      default nextval( 'form_types_sequence' ),
    "type" varchar,
    "name" varchar default '0',
    "value" varchar default '0',
    "row" varchar default '0',
    "col" varchar default '0',
    "size" varchar default '0',
    "max" varchar default '0',
    "checkd" varchar default '0',
    "read" varchar default '0',
    "mult" varchar default '0',
    "tab" varchar default '0',
    "css" varchar default '0',
    "src" varchar default '0',
    "alt" varchar default '0'
  );

Note: This table is used to identify required fields for different form element
types - the data to be inserted into a specific required field should be the
error message to give to the user if the field is not populated for the element.

=head1 FUNCTIONS

  $k->do_add( $r )
    Adds a new type to the database (note: not the code base)

  $k->do_edit( $r, $id )
    Edits the type in the database with id

  $k->do_delete( $r, $id, $yes )
    Delets the existing type in the database with id - requires 
    confirmation of delete

  $k->do_main( $r )
    Provides a listing of all types in the database - for editing, 
    deleting, and adding
    
=head1 SEE ALSO

Alchemy::FormBuilder(3), KrKit(3), perl(3)

=head1 LIMITATIONS

For an element type to 'truly' be added to the system, the code base will need 
to reflect the additional element in both Element.pm and Viewer.pm
If an element type is deleted - it will only cause issue to active forms if
also removed from the code base.

=head1 AUTHOR

Ron Andrews <ron.andrews@cognilogic.net>

=head1 COPYRIGHT AND LICENSE

Copyright (C) 2004 by Ron Andrews. All rights reserved.

You may distribute under the terms of either the GNU General Public
License or the Artistic License, as specified in the Perl README file.

=cut
