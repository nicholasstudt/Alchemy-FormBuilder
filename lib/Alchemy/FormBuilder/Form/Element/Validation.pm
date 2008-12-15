package Alchemy::FormBuilder::Form::Element::Validation;

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

	## Name
	if ( ! is_text( $$in{name} ) ) {
		push( @errors, ht_li( {}, 	'A', ht_b( 'Name' ), 
									'must be given for it to be added.' ) );
	}
	else {
		my $sth = db_query( $$k{dbh}, 'Get duplicate valid name',
							'SELECT id FROM form_validate WHERE name = ',
							sql_str( $$in{name} ) );

		my $found = db_next( $sth ) || 0;

		if ( $found && $found ne $$in{eid} ) {
			push( @errors, ht_li( {}, 'A', ht_b('Name'), 'already exists.' ) );
		}

		db_finish( $sth );
	}

	## Regex or Function - not both, not neither
	if ( is_text( $$in{regex} ) && $$in{func} ) {
		push( @errors,  ht_li( {}, 'You must choose to use either a', 
								ht_b( 'Regular Expression' ), ' or a ',
								ht_b( 'Function' ), ', not both.' ) );
	}
	elsif ( ! is_text( $$in{regex} ) && ! $$in{func} ) {
		push( @errors, ht_li( {}, 'You must enter some form of validation.' ) );
	}

	## No un-escaped '/'
	if ( defined $$in{regex} && ! $$in{func} && $$in{regex} =~ /\// 
		 && $$in{regex} !~ /\\\// ) {
		push( @errors, ht_li( {}, 'Your', ht_b( 'Regular Expression' ),
								'may only contain escaped forward slashes.' ) );
	}

	## No escape characters at the end 
	if ( defined $$in{regex} && ! $$in{func} && $$in{regex} =~ /\\$/ 
		 && $$in{regex} !~ /\\\\$/ ) {
		push( @errors, ht_li( {}, 'Your', ht_b( 'Regular Expression' ),
							'may only escape characters in the expression.' ) );
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

	my @functions = (	'0',			'--Functions--',
						'is_date',		'is_date',
						'is_email',		'is_email',
						'is_float',		'is_float',
						'is_ident',		'is_ident',
						'is_integer',	'is_integer',
						'is_ip',		'is_ip',
						'is_mac',		'is_mac',
						'is_number',	'is_number',
						'is_text',		'is_text',
						'it_time',		'is_time' );
						
	return( ht_form_js( $$k{uri} ),
			ht_table(),

			ht_tr(),
			ht_td( { 'class' => 'shd' }, 'Name:' ),
			ht_td( {}, 	ht_input( 'name', 'text', $in ),
						ht_help( $$k{help}, 'item', 'a:fb:f:e:v:name' ) ),
			ht_utr(),

			ht_tr(),
			ht_td( { 'class' => 'shd' }, 'Regular Expression:' ),
			ht_td( {}, 	ht_b( '/' ),
						ht_input( 'regex', 'text', $in ), ht_b( ' /' ),
						ht_help( $$k{help}, 'item', 'a:fb:f:e:v:regex' ) ),
			ht_utr(),

			ht_tr(),
			ht_td( { 'class' => 'shd' }, 'Function:' ),
			ht_td( {}, 	ht_select( 'func', 1, $in, '', '', @functions ),
						ht_help( $$k{help}, 'item', 'a:fb:f:e:v:func' ) ),
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
	$$k{page_title}	.=	'Add Validation';

	return( $k->_relocate( $r, $$k{rootp} ) ) if ( $$in{cancel} );

	if ( ! ( my @err = $k->_checkvals( $in ) ) ) {
		
		$$in{regex}	= '' if ( ! $$in{regex} );
		$$in{func} 	= '' if ( ! $$in{func} );

		db_run( $$k{dbh}, 'Create a new Validation',
				sql_insert( 'form_validate',
							'name'		=> sql_str( $$in{name} ),
							'regex'		=> sql_str( $$in{regex} ),
							'func'		=> sql_str( $$in{func} ) ) );

		db_commit( $$k{dbh} );
		
		return( $k->_relocate( $r, $$k{rootp} ) );
	}
	else {
		return( ( $r->method eq 'POST' ? @err : '' ), $k->_form( $in ) );
	}
} # END $k->do_add

#-------------------------------------------------
# $k->do_edit( $r, $id )
#-------------------------------------------------
sub do_edit {
	my ( $k, $r, $id ) = @_;

	my $in 				= $k->param( Apache2::Request->new( $r ) );
	$$k{page_title}	.=	'Edit Validation';

	return( 'Invalid ID.' ) 					if ( ! is_integer( $id ) );
	return( $k->_relocate( $r, $$k{rootp} ) ) 	if ( $$in{cancel} );
	
	$$in{eid} = $id;

	if ( ! ( my @err = $k->_checkvals( $in ) ) ) {
		
		$$in{regex} = '' if ( ! $$in{regex} );
		$$in{func} 	= '' if ( ! $$in{func} );

		db_run( $$k{dbh}, 'Edit a validation',
				sql_update( 'form_validate', 'WHERE id = ' . sql_num( $id ),
							'name'		=> sql_str( $$in{name} ),
							'regex'		=> sql_str( $$in{regex} ),
							'func'		=> sql_str( $$in{func} ) ) );

		db_commit( $$k{dbh} );
		
		return( $k->_relocate( $r, $$k{rootp} ) );
	}
	else {
		my $sth = db_query( $$k{dbh}, 'Get validation info',
							'SELECT name, regex, func FROM form_validate ',
							'WHERE id = ', sql_num( $id ) );

		my ( $name, $regex, $func ) = db_next( $sth );

		db_finish( $sth );

		$$in{name}		= $name		if ( ! defined $$in{name} );
		$$in{regex}		= $regex	if ( ! defined $$in{regex} );
		$$in{func}		= $func		if ( ! defined $$in{func} );
		
		return( ( $r->method eq 'POST' ? @err : '' ), $k->_form( $in ) );
	}
} # END $k->do_edit

#-------------------------------------------------
# $k->do_delete( $r, $id, $yes )
#-------------------------------------------------
sub do_delete {
	my ( $k, $r, $id, $yes ) = @_;

	my $in 				= $k->param( Apache2::Request->new( $r ) );
	$$k{page_title}	.=	'Delete Validation';

	return( 'Invalid ID.' ) 					if ( ! is_integer( $id ) );
	return( $k->_relocate( $r, $$k{rootp} ) ) 	if ( defined $$in{cancel} );

	if ( defined $yes && $yes eq 'yes' ) {
		
		my $sth = db_query( $$k{dbh}, 'Look for elements using valid',
							'SELECT id FROM form_element WHERE ',
							'form_validate_id = ', sql_num( $id ),
							'AND NOT id = ' . sql_num( '0' ) );

		if ( db_rowcount( $sth ) > 0 ) {
			
			my $count = db_rowcount( $sth );

			db_finish( $sth );

			return( ht_form_js( "$$k{rootp}/delete/$id" ),
					ht_table(),

					ht_tr(),
					ht_td( {},
							'This validation cannot be deleted at this time.',
							ht_br(),
							'It is currently being used by ' .ht_b( $count ) .
							' elements. You must change the requirements of ' .
							'these elements before this type may be removed.' ),
					ht_utr(),

					ht_tr(),
					ht_td( { 'class' => 'rshd' }, ht_submit( 'cancel', 'OK' ) ),
					ht_utr(),

					ht_utable(),
					ht_uform() );
		}

		db_finish( $sth );

		db_run( $$k{dbh}, 'Delete a Validation',
				'DELETE FROM form_validate WHERE id = ', sql_num( $id ) );

		db_commit( $$k{dbh} );

		return( $k->_relocate( $r, $$k{rootp} ) );
	}
	else {
		my $sth = db_query( $$k{dbh}, 'Get validation info',
							'SELECT name FROM form_validate WHERE id = ',
							sql_num( $id ) );

		my $name = db_next( $sth );
		
		return( ht_form_js( "$$k{uri}/yes" ),
				ht_table(),
				ht_tr(),
				ht_td( {}, 	'Delete the validation: "'. ht_b( $name ). '"?',
							ht_br(), 
							'This will completely remove this validation.' ),
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

	$$k{page_title}	.=	'Validation';

	my @lines=( ht_table(),
				ht_tr(),
				ht_td( { 'class' => 'hdr', 'colspan' => '4' }, 
						'Element Validation' ),
				ht_utr(),

				ht_tr(),
				ht_td( { 'colspan' => '4' },
						ht_b( 'Note:' ),
						'It is important to note that the functions',
						'are defined within the code. Regular Expression are',
						'as given - be certain of the regex that you are',
						'considering introducing into the system!' ),
				ht_utr(),

				ht_tr(),
				ht_td( { 'class' => 'shd' }, 'Validation Name',
						ht_help( $$k{help}, 'item', 'a:fb:f:e:v:name' ) ),
				ht_td( { 'class' => 'shd' }, 'Regex',
						ht_help( $$k{help}, 'item', 'a:fb:f:e:v:regex' ) ),
				ht_td( { 'class' => 'shd' }, 'Function',
						ht_help( $$k{help}, 'item', 'a:fb:f:e:v:func' ) ),
				ht_td( { 'class' => 'rshd' },
						'[', ht_a( "$$k{rootp}/add", 'Add Validation' ),']'),
				ht_utr() );

	my $sth = db_query( $$k{dbh}, 'Get validation types',
						'SELECT id, name, regex, func FROM form_validate ',
						'ORDER BY name' );

	while ( my ( $id, $name, $regex, $func ) = db_next( $sth ) ) {
			
		$regex = '/'. $regex. '/' if ( is_text( $regex ) );

		push( @lines,
				ht_tr(),
				ht_td( {}, $name ),
				ht_td( {}, ht_qt( $regex ) ),
				ht_td( {}, $func ),
				ht_td( { 'class' => 'rdta' },
						'[', ht_a( "$$k{rootp}/edit/$id", 'Edit' ), '|',
						ht_a( "$$k{rootp}/delete/$id", 'Delete' ), ']' ),
				ht_utr() );
	}

	if ( db_rowcount( $sth ) < 1 ) {
		push( @lines,
			ht_tr(),
			ht_td( { 'class' => 'dta', 'colspan' => '4' },
					ht_b( 'There are no validations to display.' ) ),
			ht_utr() );
	}

	db_finish( $sth );

	return( @lines, ht_utable() );
} # END $k->do_main

#EOF
1;

__END__

=head1 NAME 

Alchemy::FormBuilder::Form::Element::Validation - FormBuilder Validation

=head1 SYNOPSIS

 use Alchemy::FormBuilder::Form::Element::Validation;

=head1 DESCRIPTION

This module provides the interface for list, edit, create, and delete
with respect to the form validation listed in the database. It is important
to note that the functions that are listed can be modified via the code base -
but the regex validation is available immediately.

=head1 APACHE

This is a sample of the location required for this module to run.
Consult Alchemy::FormBuilder(3) to learn about the configuration
options.

  <Location /admin/forms/validate >
    SetHandler perl-script

    PerlSetVar  SiteTitle    "FormBuilder - "
    PerlSetVar  Frame        "template;FormBuilder.tp"
    
    PerlHandler Alchemy::FormBuilder::Form::Element::Validation
  </Location>

=head1 DATABASE

This is the core table that this module manipulates:

  create table "form_validate" (
    "id" integer primary key not null
      default nextval( 'form_validate_sequence' ),
    "name" varchar not null,
    "regex" varchar,
    "func" varchar
  );

=head1 FUNCTIONS

This module provides the following functions:

  $k->do_add( $r )
    Adds a new validation type to the database

  $k->do_edit( $r, $id )
    Edits an existing validation type in the database with id

  $k->do_delete( $r, $id, $yes )
    Deletes an existing validation type from the database with id 
    - requires confirmation of delete - note: deletion of validation 
    techniques may cause existing forms to not function properly

  $k->do_main( $r )
    Provides a listing of available validation types - for editing, 
    adding, and deletion
    
=head1 SEE ALSO

Alchemy::FormBuilder(3), KrKit(3), perl(3)

=head1 LIMITATIONS

If a validation is removed - it may cause existing forms to not function 
properly. To add new functions to possible validation types - they must be
added to the code base first.

=head1 AUTHOR

Ron Andrews <ron.andrews@cognilogic.net>

=head1 COPYRIGHT AND LICENSE

Copyright (C) 2004 by Ron Andrews. All rights reserved.

You may distribute under the terms of either the GNU General Public
License or the Artistic License, as specified in the Perl README file.

=cut
