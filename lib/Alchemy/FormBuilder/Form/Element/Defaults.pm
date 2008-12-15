package Alchemy::FormBuilder::Form::Element::Defaults;

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
# $k->do_add( $r )
#-------------------------------------------------
sub do_add {
	my ( $k, $r ) = @_;

	my $in 				= $k->param( Apache2::Request->new( $r ) );
	$$k{page_title}	.=	'Add Default Element';

	return( $k->_relocate( $r, $$k{rootp} ) ) if ( $$in{cancel} );

	if ( my @err = $k->_checkvals( $in ) ) {
		return( ( $r->method eq 'POST' ? @err : '' ), $k->_form( $in ) );
	}

	db_run( $$k{dbh}, 'Create a new Default Element',
			sql_insert( 'form_element',
						'isdefault'			=> sql_bool( 't' ),
						'required'			=> sql_bool( $$in{req} ),
						'checked'			=> sql_bool( $$in{checkd} ),
						'readonly'			=> sql_bool( $$in{read} ),
						'multiple'			=> sql_bool( $$in{mult} ),
						'form_data_id'		=> sql_num( '0' ),
						'form_types_id'		=> sql_num( $$in{type} ),
						'form_validate_id'	=> sql_num( $$in{reqid} ),
						'max_length'		=> sql_num( $$in{max} ),
						'tab_index'			=> sql_num( $$in{tab} ),
						'row_count'			=> sql_num( $$in{row} ),
						'col_count'			=> sql_num( $$in{col} ),
						'size_count'		=> sql_num( $$in{size} ),
						'created'			=> sql_str( 'now' ),
						'modified'			=> sql_str( 'now' ),
						'name'				=> sql_str( $$in{name} ),
						'value'				=> sql_str( $$in{value} ),
						'css_class'			=> sql_str( $$in{css} ),
						'src'				=> sql_str( $$in{src} ),
						'addition_params'	=> sql_str( $$in{param} ),
						'alt'				=> sql_str( $$in{alt} ),
						'pre_text'			=> sql_str( $$in{pre} ),
						'post_text'			=> sql_str( $$in{post} ),
						'error_msg'			=> sql_str( $$in{error} ) ));

	db_commit( $$k{dbh} );

	return( $k->_relocate( $r, $$k{rootp} ) );
} # END $k->do_add

#-------------------------------------------------
# $k->do_edit( $r, $id )
#-------------------------------------------------
sub do_edit {
	my ( $k, $r, $id ) = @_;

	my $in 				= $k->param( Apache2::Request->new( $r ) );
	$$k{page_title}	.=	'Edit Default Element';

	return( 'Invalid ID.' ) 					if ( ! is_integer( $id ) );
	return( $k->_relocate( $r, $$k{rootp} ) ) 	if ( $$in{cancel} );
	
	$$in{id} = $id;

#	if ( my @err = $k->_checkvals( $in ) ) {
#		return( ( $r->method eq 'POST' ? @err : '' ), $k->_form( $in ) );
#	}

	if ( ! ( my @err = $k->_checkvals( $in ) ) ) {
		
		db_run( $$k{dbh}, 'Edit a Default Element',
				sql_update( 'form_element', 'WHERE id = ' . sql_num( $id ),
							'required'			=> sql_bool( $$in{req} ),
							'checked'			=> sql_bool( $$in{checkd} ),
							'readonly'			=> sql_bool( $$in{read} ),
							'multiple'			=> sql_bool( $$in{mult} ),
							'form_data_id'		=> sql_num( '0' ),
							'form_types_id'		=> sql_num( $$in{type} ),
							'form_validate_id'	=> sql_num( $$in{reqid} ),
							'max_length'		=> sql_num( $$in{max} ),
							'tab_index'			=> sql_num( $$in{tab} ),
							'row_count'			=> sql_num( $$in{row} ),
							'col_count'			=> sql_num( $$in{col} ),
							'size_count'		=> sql_num( $$in{size} ),
							'modified'			=> sql_str( 'now' ),
							'name'				=> sql_str( $$in{name} ),
							'value'				=> sql_str( $$in{value} ),
							'css_class'			=> sql_str( $$in{css} ),
							'src'				=> sql_str( $$in{src} ),
							'addition_params'	=> sql_str( $$in{param} ),
							'alt'				=> sql_str( $$in{alt} ),
							'pre_text'			=> sql_str( $$in{pre} ),
							'post_text'			=> sql_str( $$in{post} ),
							'error_msg'			=> sql_str( $$in{error} ) ));

		db_commit( $$k{dbh} );
		
		return( $k->_relocate( $r, $$k{rootp} ) );
	}
	else {
		my $sth = db_query( $$k{dbh}, 'Get default element info',
							'SELECT required, checked, readonly, multiple, ',
							'form_types_id, form_validate_id, max_length, ',
							'tab_index, row_count, col_count, size_count, ',
							'modified, name, value, css_class, src, ',
							'addition_params, alt, pre_text, post_text, ',
							'error_msg FROM form_element WHERE id = ',
							sql_num( $id ) );

		my ( $req, $check, $read, $mult, $type, $reqid, $max, $tab, $row, $col,
			$size, $mod, $name, $value, $css, $src, $param, $alt, $pre, $post,
			$error ) = db_next( $sth );

		db_finish( $sth );

		$$in{req}		= $req		if ( ! defined $$in{req} );
		$$in{checkd}	= $check	if ( ! defined $$in{checkd} );
		$$in{read}		= $read		if ( ! defined $$in{read} );
		$$in{mult}		= $mult		if ( ! defined $$in{mult} );
		$$in{type}		= $type		if ( ! defined $$in{type} );
		$$in{reqid}		= $reqid	if ( ! defined $$in{reqid} );
		$$in{max}		= $max		if ( ! defined $$in{max} );
		$$in{tab}		= $tab		if ( ! defined $$in{tab} );
		$$in{row}		= $row		if ( ! defined $$in{row} );
		$$in{col}		= $col		if ( ! defined $$in{col} );
		$$in{size}		= $size		if ( ! defined $$in{size} );
		$$in{mod}		= $mod		if ( ! defined $$in{mod} );
		$$in{name}		= $name		if ( ! defined $$in{name} );
		$$in{value}		= $value	if ( ! defined $$in{value} );
		$$in{css}		= $css		if ( ! defined $$in{css} );
		$$in{src}		= $src		if ( ! defined $$in{src} );
		$$in{param}		= $param	if ( ! defined $$in{param} );
		$$in{alt}		= $alt		if ( ! defined $$in{alt} );
		$$in{pre}		= $pre		if ( ! defined $$in{pre} );
		$$in{post}		= $post		if ( ! defined $$in{post} );
		$$in{error}		= $error	if ( ! defined $$in{error} );
		
		return( ( $r->method eq 'POST' ? @err : '' ), $k->_form( $in ) );
	}
} # END $k->do_edit

#-------------------------------------------------
# $k->do_delete( $r, $id, $yes )
#-------------------------------------------------
sub do_delete {
	my ( $k, $r, $id, $yes ) = @_;

	my $in 				= $k->param( Apache2::Request->new( $r ) );
	$$k{page_title}	.=	'Delete Default Element';

	return( 'Invalid ID.' ) 					if ( ! is_integer( $id ) );
	return( $k->_relocate( $r, $$k{rootp} ) ) 	if ( defined $$in{cancel} );

	if ( defined $yes && $yes eq 'yes' ) {

		db_run( $$k{dbh}, 'Delete a default element',
				'DELETE FROM form_element WHERE id = ', sql_num( $id ) );

		db_commit( $$k{dbh} );

		return( $k->_relocate( $r, $$k{rootp} ) );
	}
	else {
		my $sth = db_query( $$k{dbh}, 'Get default element info',
							'SELECT name FROM form_element WHERE id = ',
							sql_num( $id ) );

		my $name = db_next( $sth );

		db_finish( $sth );

		return( ht_form_js( "$$k{uri}/yes" ),
				ht_table(),

				ht_tr(),
				ht_td( {}, 	"Delete the default element: \"$name\"?", ht_br(),
							'This will completely remove this element.' ),
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

	$$k{'page_title'}	.=	'Default Elements';

	my @lines=( ht_table(),
				ht_tr(),
				ht_td( { 'class' => 'shd' }, 'Name',
						ht_help( $$k{help}, 'item', 'a:fb:f:e:d:name' ) ),
				ht_td( { 'class' => 'shd' }, 'Type',
						ht_help( $$k{help}, 'item', 'a:fb:f:e:d:type' ) ),
				ht_td( { 'class' => 'rshd' },
						'[', ht_a( "$$k{rootp}/add", 'Add Element' ), ']' ),
				ht_utr() );

	my $sth = db_query( $$k{dbh}, 'Get default elements',
						'SELECT e.id, e.name, t.type FROM form_element AS e,',
						'form_types AS t WHERE isdefault = \'t\' ',
						'AND t.id = e.form_types_id ORDER BY e.name' );

	while ( my ( $id, $name, $type ) = db_next( $sth ) ) {
		push( @lines, 	ht_tr(),
						ht_td( {}, $name ),
						ht_td( {}, $type ),
						ht_td( { 'class' => 'rdta' },
								'[',
								ht_a( "$$k{rootp}/edit/$id", 'Edit' ), '|',
								ht_a( "$$k{rootp}/delete/$id", 'Delete' ),
								']' ),
						ht_utr() );
	}

	if ( db_rowcount( $sth ) < 1 ) {
		push( @lines, 	ht_tr(),
						ht_td( { 'colspan' => '3' },
								'There are no default elements to display.' ),
						ht_utr() );
	}

	db_finish( $sth );

	return( @lines, ht_utable() );
} # END $k->do_main

#-------------------------------------------------
# $k->_checkvals( $in )
#-------------------------------------------------
sub _checkvals {
    my ( $k, $in ) = @_;

	my @errors;
	
	## Required - HTML and Hidden
	my $sth = db_query( $$k{dbh}, 'Get non-requirable fields',
						'SELECT id FROM form_types WHERE type = ',
						sql_str( 'hidden' ), ' OR type = ',
						sql_str( 'html' ), ' ORDER BY type' );

	my ( $html, $hid ) = db_next( $sth );

	db_finish( $sth );

	$html   = $html ? $html : 0;
	$hid    = $hid ? $hid : 0;

	if ( defined $$in{type} && defined $$in{req} && $$in{req} ) {
		if ( $html && $$in{type} eq $html ) {
			push( @errors, ht_li( {},
							'The '. ht_b( 'Element Type:' ). ' '.
							ht_i( 'HTML' ). ' cannot be a required field.' ) );
		}
		elsif ( $hid && $$in{type} eq $hid ) {
			push( @errors, ht_li( {},
							'The '. ht_b( 'Element Type:' ). ' '.
							ht_i( 'Hidden' ). ' cannot be a required field.') );
		}
	}

	## Required - Read-Only
	if ( defined $$in{read} && $$in{read} && $$in{req} ) {
		push( @errors, ht_li( {},
						'An element that is '. ht_b( 'Read-Only' ).
						' cannot be required.' ) );
	}

	## Types
	if ( ! $$in{type} ) {
		push( @errors, ht_li( {}, 'You must select an '.ht_b('Element Type') ));
	}

	## Max Length
	if ( defined $$in{max} && ! is_integer( $$in{max} ) ) {
		push( @errors, ht_li( {}, 
						'A '. ht_b( 'Max Length' ). ' must be an integer.' ) );
	}

	## Tab Index
	if ( defined $$in{tab} && ! is_integer( $$in{tab} ) ) {
		push( @errors, ht_li( {},
						'A '. ht_b( 'Tab Index' ). ' must be an integer.' ) );
	}

	## Row Count
	if ( defined $$in{row} && ! is_integer( $$in{row} ) ) {
		push( @errors, ht_li( {},
						'A '. ht_b( 'Row Count' ). ' must be an integer.' ) );
	}

	## Col Count
	if ( defined $$in{col} && ! is_integer( $$in{col} ) ) {
		push( @errors, ht_li( {}, 
						'A '. ht_b( 'Col Count' ). ' must be an integer.' ) );
	}

	## Size Count
	if ( defined $$in{size} && ! is_integer( $$in{size} ) ) {
		push( @errors, ht_li( {},
						'A '. ht_b( 'Size Count' ). ' must be an integer.' ) );
	}

	## Name
	if ( ! is_ident( $$in{name} ) ) {
		push( @errors, ht_li( {}, 
						'A '. ht_b( 'Name' ). ' must not contain white '.
						'space or symbols.' ) );
	}

	## CSS Class
	if ( defined $$in{css} && ! is_ident( $$in{css} ) ) {
		push( @errors, ht_li( {},
						'A '. ht_b( 'CSS Class' ). ' must not contain white '.
						'space or symbols.' ) );
	}

	## Error Message
	if ( defined $$in{req} && $$in{req} && ! is_text( $$in{error} ) ) {
		push( @errors, ht_li( {},
						'An '. ht_b( 'Error Message' ). ' is required for '.
						'elements that are required.' ) );
	}

	## Element Type based requirements
	if ( defined $$in{type} ) {

		my $bth = db_query( $$k{dbh}, 'Get form_types',
							'SELECT name, value, row, col, size, max, ',
							'checkd, read, mult, tab, css, src, alt FROM ',
							'form_types WHERE id = ', sql_num($$in{type}) );

		if ( db_rowcount( $bth ) < 1 ) {
			db_finish( $bth );
		}
		else {
			my $result = db_nextvals( $bth );

			foreach my $key ( keys %{$result} ) {
				if ( $result->{$key} && ! defined $$in{$key} ) {
					push( @errors, ht_li( {}, $result->{$key} ) );
				}
			}
	
			db_finish( $bth );
		}
	}

	if ( @errors ) {
		return( ht_div( { 'class' => 'error' },
						ht_h( 1, 'Errors:' ), ht_ul( {}, @errors ) ) );
	}

	return();
} # END $k->_checkvals

#-------------------------------------------------
# $k->_form( $in )
#-------------------------------------------------
sub _form {
	my ( $k, $in ) =  @_;

	my @yesno = ( '0', 'No', '1', 'Yes' );
	my @etypes = ( '0', '--Types--' ); 		# Element Types
	my @valid = ( '0', 'None' ); 			# Validation

	my $sth = db_query( $$k{dbh}, 'Get list of types',
						'SELECT id, type FROM form_types ORDER BY type' );

	while ( my ( $id, $name ) = db_next( $sth ) ) {
		push( @etypes, $id, $name );
	}

	db_finish( $sth );

	my $rth = db_query( $$k{dbh}, 'Get list of validation',
						'SELECT id, name FROM form_validate ORDER BY name' );

	while ( my ( $id, $name ) = db_next( $rth ) ) {
		push( @valid, $id, $name );
	}

	db_finish( $rth );

	return(	ht_form_js( $$k{uri} ),
			ht_table(),

			## Element Data ----------------------------------------------
			ht_tr(),
			ht_td( { 'class' => 'shd', 'colspan' => '4' }, 'Element Data' ),
			ht_utr(),

			## Name
			ht_tr(),
			ht_td( { 'class' => 'shd' }, 'Name:' ),
			ht_td( { 'colspan' => '3' },
					ht_input( 'name', 'text', $in ),
					ht_help( $$k{help}, 'item', 'a:fb:f:e:name' ) ),
			ht_utr(),

			## Value
			ht_tr(),
			ht_td( { 'class' => 'shd' }, 'Value:' ),
			ht_td( { 'colspan' => '3' },
					ht_input( 'value', 'text', $in ),
					ht_help( $$k{help}, 'item', 'a:fb:f:e:value' ) ),
			ht_utr(),

			## Type
			ht_tr(),
			ht_td( { 'class' => 'shd' }, 'Element Type:' ),
			ht_td( {}, 	ht_select( 'type', 1, $in, '', '', @etypes ),
						ht_help( $$k{help}, 'item', 'a:fb:f:e:form_type' ) ),

			## Spacer ---
			ht_tr(),
			ht_td( { 'class' => 'shd' }, '&nbsp;' ),
			ht_td( { 'colspan' => '3' }, '&nbsp;' ),
			ht_utr(),

			## Vaildation Data -------------------------------------------
			ht_tr(),
			ht_td( { 'class' => 'shd', 'colspan' => '4' }, 'Validation Data' ),
			ht_utr(),

			## Required
			ht_tr(),
			ht_td( { 'class' => 'shd' }, 'Required Element:' ),
			ht_td( {}, 	ht_select( 'req', 1, $in, '', '', @yesno ),
						ht_help( $$k{help}, 'item', 'a:fb:f:e:required' ) ),

			## Form Requirements
			ht_td( { 'class' => 'shd' }, 'Element Requirements:' ),
			ht_td( {}, 	ht_select( 'reqid', 1, $in, '', '', @valid ),
						ht_help( $$k{help}, 'item', 
									'a:fb:f:e:requirements' ) ),
			ht_utr(),

			## Error Message
			ht_tr(),
			ht_td( { 'class' => 'shd' }, 'Error Message:' ),
			ht_td( { 'colspan' => '3' },
					ht_input( 'error', 'text', $in, 'size="40"' ),
					ht_help( $$k{help}, 'item', 'a:fb:f:e:error_msg' ) ),
			ht_utr(),

			## Spacer ---
			ht_tr(),
			ht_td( { 'class' => 'shd' }, '&nbsp;' ),
			ht_td( { 'colspan' => '3' }, '&nbsp;' ),
			ht_utr(),

			## HTML Data -------------------------------------------------
			ht_tr(),
			ht_td( { 'class' => 'shd', 'colspan' => '4' }, 'HTML Data' ),
			ht_utr(),

			## CSS Class
			ht_tr(),
			ht_td( { 'class' => 'shd' }, 'CSS Class:' ),
			ht_td( { }, '&nbsp;' ),
			ht_utr(),
			
			## Checked
			ht_tr(),
			ht_td( { 'class' => 'shd' }, 'Checked:' ),
			ht_td( {}, 	ht_select( 'checkd', 1, $in, '', '', @yesno ),
						ht_help( $$k{help}, 'item', 'a:fb:f:e:checked' ) ),
			
			## Read Only
			ht_td( { 'class' => 'shd' }, 'Read-Only:' ),
			ht_td( {}, 	ht_select( 'read', 1, $in, '', '', @yesno ),
						ht_help( $$k{help}, 'item', 'a:fb:f:e:readonly' ) ),
			ht_utr(),

			## Tab Index
			ht_tr(),
			ht_td( { 'class' => 'shd' }, 'Tab Index:' ),
			ht_td( {}, 	ht_input( 'tab', 'text', $in, 'size="10"' ),
						ht_help( $$k{help}, 'item', 'a:fb:f:e:tab_index' ) ),
			## Multiple Select
			ht_td( { 'class' => 'shd' }, 'Multiple Select:' ),
			ht_td( {}, 	ht_select( 'mult', 1, $in, '', '', @yesno ),
						ht_help( $$k{help}, 'item', 'a:fb:f:e:multiple' ) ),
			ht_utr(),

			## Size Count
			ht_tr(),
			ht_td( { 'class' => 'shd' }, 'Size Count:' ),
			ht_td( {}, 	ht_input( 'size', 'text', $in, 'size="5"' ),
						ht_help( $$k{help}, 'item', 'a:fb:f:e:size_count' ) ),
			## Max Length
			ht_td( { 'class' => 'shd' }, 'Max Length:' ),
			ht_td( {}, 	ht_input( 'max', 'text', $in, 'size="5"' ),
						ht_help( $$k{help}, 'item', 'a:fb:f:e:max_length' ) ),
			ht_utr(),

			## Row Count
			ht_tr(),
			ht_td( { 'class' => 'shd' }, 'Row Count:' ),
			ht_td( {}, 	ht_input( 'row', 'text', $in, 'size="5"' ),
						ht_help( $$k{help}, 'item', 'a:fb:f:e:row_count' ) ),

			## Col Count
			ht_td( { 'class' => 'shd' }, 'Col Count:' ),
			ht_td( {}, 	ht_input( 'col', 'text', $in, 'size="5"' ),
						ht_help( $$k{help}, 'item', 'a:fb:f:e:col_count' ) ),
			ht_utr(),

			## Source
			ht_tr(),
			ht_td( { 'class' => 'shd' }, 'Source:' ),
			ht_td( { 'colspan' => '3' },
					ht_input( 'src', 'text', $in, 'size="40"' ),
					ht_help( $$k{help}, 'item', 'a:fb:f:e:src' ) ),
			ht_utr(),

			## Alt
			ht_tr(),
			ht_td( { 'class' => 'shd' }, 'Alt:' ),
			ht_td( { 'colspan' => '3' },
					ht_input( 'alt', 'text', $in, 'size="40"' ),
					ht_help( $$k{help}, 'item', 'a:fb:f:e:alt' ) ),
			ht_utr(),

			## Additional Parameters
			ht_tr(),
			ht_td( { 'class' => 'shd' }, 'Additional Parameters:' ),
			ht_td( { 'colspan' => '3' },
					ht_input( 'param', 'text', $in, 'size="60"' ),
					ht_help( $$k{help}, 'item', 'a:fb:f:e:add_param' ) ),
			ht_utr(),

			## Pre-Text
			ht_tr(),
			ht_td( { 'class' => 'shd' }, 'Pre-Text:' ),
			ht_td( { 'colspan' => '3' },
					ht_input( 'pre', 'textarea', $in, 'rows="6" cols="60"' ),
					ht_help( $$k{help}, 'item', 'a:fb:f:e:pre_text' ) ),
			ht_utr(),

			## Post-Text
			ht_tr(),
			ht_td( { 'class' => 'shd' }, 'Post-Text:' ),
			ht_td( { 'colspan' => '3' },
					ht_input( 'post', 'textarea', $in, 'rows="6" cols="60"' ),
					ht_help( $$k{help}, 'item', 'a:fb:f:e:post_text' ) ),
			ht_utr(),

			ht_tr(),
			ht_td( { 'class' => 'rshd', 'colspan' => '4' },
					ht_submit( 'submit', 'Save' ),
					ht_submit( 'cancel', 'Cancel' ) ),
			ht_utr(),

			ht_utable(),
			ht_uform() );
} # END $k->_form

#EOF
1

__END__

=head1 NAME 
Alchemy::FormBuilder::Form::Element::Default - FormBuilder Default Elements 

=head1 SYNOPSIS

 use Alchemy::FormBuilder::Form::Element::Default;

=head1 DESCRIPTION

This module provides the interface for list, edit, create, and delete
with respect to the form default elements listed in the database.

=head1 APACHE

This is a sample of the location required for this module to run.
Consult Alchemy::FormBuilder(3) to learn about the configuration
options.

  <Location /admin/forms/defaults >
    SetHandler perl-script

    PerlSetVar  SiteTitle    "FormBuilder - "
    PerlSetVar  Frame        "template;FormBuilder.tp"
    
    PerlHandler Alchemy::FormBuilder::Form::Element::Default
  </Location>

=head1 DATABASE

The form_element table is modified.

=head1 FUNCTIONS

This module provides the following functions:

  $k->do_add( $r )
    Adds a new default element to the database

  $k->do_edit( $r, $id )
    Edits the default element with id

  $k->do_delete( $r, $id, $yes )
    Deletes an existing default element with id - requires confirmation 
    of delete - does not affect other elements in the database

  $k->do_main( $r )
    Provides a listing of all available default elements in the database 
    - for editing, adding, and deleting
    
=head1 SEE ALSO

Alchemy::FormBuilder(3), KrKit(3), perl(3)

=head1 LIMITATIONS

None specified thus far.....

=head1 AUTHOR

Ron Andrews <ron.andrews@cognilogic.net>

=head1 COPYRIGHT AND LICENSE

Copyright (C) 2004 by Ron Andrews. All rights reserved.

You may distribute under the terms of either the GNU General Public
License or the Artistic License, as specified in the Perl README file.

=cut
