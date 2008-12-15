package Alchemy::FormBuilder::Form::Element;

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
# $k->do_add( $r, $fid )
#-------------------------------------------------
sub do_add {
	my ( $k, $r, $fid ) = @_;

	my $in 				= $k->param( Apache2::Request->new( $r ) );
	$$k{page_title}	.=	'Add Element';

	return( 'Invalid ID.' )	if ( ! is_integer( $fid ) );
	return( $k->_relocate( $r, "$$k{rootp}/main/$fid" ) ) if ( $$in{cancel} );

	$$in{fid} 	= $fid;
	$in 		= $k->_set_defaults( $in ) if ( defined $$in{default} );

#	if ( my @err = $k->_checkvals( $in ) ) {
#		return( ( $r->method eq 'POST' ? @err : '' ), $k->_form( $in ) );
#	}

	if ( ! ( my @err = $k->_checkvals( $in ) ) ) {
		
		db_run( $$k{dbh}, 'Create a new element',
				sql_insert( 'form_element',
							'required'			=> sql_bool( $$in{req} ),
							'checked'			=> sql_bool( $$in{checkd} ),
							'readonly'			=> sql_bool( $$in{read} ),
							'multiple'			=> sql_bool( $$in{mult} ),
							'form_data_id'		=> sql_num( $fid ),
							'form_types_id'		=> sql_num( $$in{type} ),
							'form_validate_id'	=> sql_num( $$in{reqid} ),
							'max_length'		=> sql_num( $$in{max} ),
							'tab_index'			=> sql_num( $$in{tab} ),
							'row_count'			=> sql_num( $$in{row} ),
							'col_count'			=> sql_num( $$in{col} ),
							'size_count'		=> sql_num( $$in{size} ),
							'created'			=> sql_str( 'now' ),
							'modified'			=> sql_str( 'now' ),
							'question_number'	=> sql_num( $$in{quest} ),
							'page_number'		=> sql_num( $$in{page} ),
							'name'				=> sql_str( $$in{name} ),
							'value'				=> sql_str( $$in{value} ),
							'css_class'			=> sql_str( $$in{css} ),
							'src'				=> sql_str( $$in{src} ),
							'addition_params'	=> sql_str( $$in{param} ),
							'alt'				=> sql_str( $$in{alt} ),
							'pre_text'			=> sql_str( $$in{pre} ),
							'post_text'			=> sql_str( $$in{post} ),
							'error_msg'			=> sql_str( $$in{error} )));

		db_commit( $$k{dbh} );

		my $where = ( $$in{add} ) ? 'add' : 'main';

		return( $k->_relocate( $r, "$$k{rootp}/$where/$fid" ) );
	}
	else {
		## Defaults
		$$in{req}		= 0 if ( ! $$in{req} );
		$$in{checkd}	= 0 if ( ! $$in{checkd} );
		$$in{read}		= 0 if ( ! $$in{read} );
		$$in{mult}		= 0 if ( ! $$in{mult} );
		$$in{type}		= 0 if ( ! $$in{type} );
		$$in{reqid}		= 0 if ( ! $$in{reqid} );
		$$in{default}	= 0 if ( ! $$in{default} );
		
		if ( $r->method eq 'POST' ) {
			return( @err, $k->_form( $in ) );
		}
		else {
			$$in{quest} = 1;

			my $sth = db_query( $$k{'dbh'}, 'Get next question number',
								'SELECT question_number FROM form_element ',
								'WHERE form_data_id = ', sql_num( $fid ),
								'ORDER BY question_number' );

			while ( my $cur = db_next( $sth ) ) {
				$$in{quest}++ if ( $cur == $$in{quest} );
			}

			db_finish( $sth );

			return( $k->_form( $in ) );
		}
	}				
} # END $k->do_add

#-------------------------------------------------
# $k->do_edit( $r, $fid, $id )
#-------------------------------------------------
sub do_edit {
	my ( $k, $r, $fid, $id ) = @_;

	my $in 				= $k->param( Apache2::Request->new( $r ) );
	$$k{page_title}	.=	'Edit Element';

	return( 'Invalid ID.' ) if ( ! is_integer( $fid ) );
	return( 'Invalid ID.' ) if ( ! is_integer( $id ) );
	return( $k->_relocate( $r, "$$k{rootp}/main/$fid" ) ) if ( $$in{cancel} );

	$$in{fid}	= $fid;
	$$in{eid}	= $id;
	$in 		= $k->_set_defaults( $in ) if ( defined $$in{default} );
	
	if ( ! ( my @err = $k->_checkvals( $in ) ) ) {

		my $validate = $$in{reqid} ? sql_num($$in{reqid}) : 'null';
		
		db_run( $$k{dbh}, 'Edit an element',
				sql_update( 'form_element', 'WHERE id = ' . sql_num( $id ),
							'required'			=> sql_bool( $$in{req} ),
							'checked'			=> sql_bool( $$in{checkd} ),
							'readonly'			=> sql_bool( $$in{read} ),
							'multiple'			=> sql_bool( $$in{mult} ),
							'form_data_id'		=> sql_num( $fid ),
							'form_types_id'		=> sql_num( $$in{type} ),
							'form_validate_id'	=> $validate,
							'max_length'		=> sql_num( $$in{max} ),
							'tab_index'			=> sql_num( $$in{tab} ),
							'row_count'			=> sql_num( $$in{row} ),
							'col_count'			=> sql_num( $$in{col} ),
							'size_count'		=> sql_num( $$in{size} ),
							'modified'			=> sql_str( 'now' ),
							'question_number'	=> sql_str( $$in{quest} ),
							'page_number'		=> sql_str( $$in{page} ),
							'name'				=> sql_str( $$in{name} ),
							'value'				=> sql_str( $$in{value} ),
							'css_class'			=> sql_str( $$in{css} ),
							'src'				=> sql_str( $$in{src} ),
							'addition_params'	=> sql_str( $$in{param} ),
							'alt'				=> sql_str( $$in{alt} ),
							'pre_text'			=> sql_str( $$in{pre} ),
							'post_text'			=> sql_str( $$in{post} ),
							'error_msg'			=> sql_str( $$in{error} ) ) );

		db_commit( $$k{dbh} );

		if ( defined $$in{prev} ) {
			## return to previous element
			my $rth = db_query( $$k{dbh}, 'Get elements',
								'SELECT id FROM form_element WHERE ',
								'form_data_id = ', sql_num( $fid ),
								'ORDER BY page_number, question_number' );

			if ( db_rowcount( $rth ) < 1 ) {
				db_finish( $rth );
				return( $k->_relocate( $r, "$$k{rootp}/main/$fid" ) );
			}
			
			my ( $nid, $pid ) = ( '', '' );

			while ( $nid = db_next( $rth ) ) {
				last if ( $nid == $id );
				$pid = $nid;
			}

			db_finish( $rth );
			
			if ( $pid eq '' ) {
				return( $k->_relocate( $r, "$$k{rootp}/main/$fid" ) );
			}
			
			return( $k->_relocate( $r, "$$k{rootp}/edit/$fid/$pid" ) );
		}
		elsif ( defined $$in{next} ) {
			## go to next element
			my $qth = db_query( $$k{dbh}, 'Get elements',
								'SELECT id FROM form_element WHERE ',
								'form_data_id = ', sql_num( $fid ),
								'ORDER BY page_number, question_number' );

			if ( db_rowcount( $qth ) < 1 ) {
				db_finish( $qth );
				return( $k->_relocate( $r, "$$k{rootp}/main/$fid" ) );
			}

			my ( $nid, $pid ) = ( '', '' );

			while ( $nid = db_next( $qth ) ) {
				last if ( $pid == $id );
				$pid = $nid;
			}

			db_finish( $qth );

			if ( $nid eq '' ) {
				return( $k->_relocate( $r, "$$k{rootp}/main/$fid" ) );
			}

			return( $k->_relocate( $r, "$$k{rootp}/edit/$fid/$nid" ) );
		}
		elsif( defined $$in{add} ) { 			## add another
			return( $k->_relocate( $r, "$$k{rootp}/add/$fid" ) );
		}

		return( $k->_relocate( $r, "$$k{rootp}/main/$fid" ) );
	}
	else {
		## Defaults
		my $sth = db_query( $$k{dbh}, 'Get element info',
							'SELECT required, checked, readonly, ',
							'multiple, form_types_id, form_validate_id, ',
							'max_length, tab_index, row_count, col_count, ',
							'size_count, modified, question_number, ',
							'page_number, name, value, css_class, src, ',
							'addition_params, alt, pre_text, post_text, ',
							'error_msg FROM form_element WHERE id = ',
							sql_num( $id ) );

		if ( db_rowcount( $sth ) < 1 ) {
			db_finish( $sth );
			return( 'Invalid ID.' );
		}
		
		my ( $req, $check, $read, $mult, $type, $reqid, $max, $tab,
			$row, $col, $size, $mod, $quest, $page, $name, $value, $css, 
			$src, $param, $alt, $pre, $post, $error ) = db_next( $sth );
		
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
		$$in{quest}		= $quest	if ( ! defined $$in{quest} );
		$$in{page}		= $page		if ( ! defined $$in{page} );
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
# $k->do_dup( $r, $fid, $id )
#-------------------------------------------------
sub do_dup {
	my ( $k, $r, $fid, $id ) = @_;

	my $in 				= $k->param( Apache2::Request->new( $r ) );
	$$k{page_title}	.=	'Duplicate Element';

	return( 'Invalid ID.' ) if ( ! is_integer( $fid ) );
	return( 'Invalid ID.' ) if ( ! is_integer( $id ) );
	return( $k->_relocate( $r, "$$k{rootp}/main/$fid" ) ) if ( $$in{cancel} );

	$$in{fid}	= $fid;
	$$in{eid}	= $id;
	$in 		= $k->_set_defaults( $in ) if ( defined $$in{default} );
	
	if ( ! ( my @err = $k->_checkvals( $in ) ) ) {
		
		my $validate = $$in{reqid} ? sql_num($$in{reqid}) : 'null';
		
		db_run( $$k{dbh}, 'Duplicate an element',
				sql_insert( 'form_element',
							'required'			=> sql_bool( $$in{req} ),
							'checked'			=> sql_bool( $$in{checkd} ),
							'readonly'			=> sql_bool( $$in{read} ),
							'multiple'			=> sql_bool( $$in{mult} ),
							'form_data_id'		=> sql_num( $fid ),
							'form_types_id'		=> sql_num( $$in{type} ),
							'form_validate_id'	=> $validate,
							'max_length'		=> sql_num( $$in{max} ),
							'tab_index'			=> sql_num( $$in{tab} ),
							'row_count'			=> sql_num( $$in{row} ),
							'col_count'			=> sql_num( $$in{col} ),
							'size_count'		=> sql_num( $$in{size} ),
							'modified'			=> sql_str( 'now' ),
							'question_number'	=> sql_num( $$in{quest} ),
							'page_number'		=> sql_num( $$in{page} ),
							'name'				=> sql_str( $$in{name} ),
							'value'				=> sql_str( $$in{value} ),
							'css_class'			=> sql_str( $$in{css} ),
							'src'				=> sql_str( $$in{src} ),
							'addition_params'	=> sql_str( $$in{param} ),
							'alt'				=> sql_str( $$in{alt} ),
							'pre_text'			=> sql_str( $$in{pre} ),
							'post_text'			=> sql_str( $$in{post} ),
							'error_msg'			=> sql_str( $$in{error} ) ) );

		db_commit( $$k{dbh} );

		if ( defined $$in{add} ) { 	# add another
			return( $k->_relocate( $r, "$$k{rootp}/add/$fid" ) );
		}

		return( $k->_relocate( $r, "$$k{rootp}/main/$fid" ) );
	}
	else {
		## Defaults
		my $sth = db_query( $$k{'dbh'}, 'Get element info',
							'SELECT required, checked, readonly, ',
							'multiple, form_types_id, form_validate_id, ',
							'max_length, tab_index, row_count, col_count, ',
							'size_count, modified, name, value, css_class, ',
							'src, addition_params, alt, pre_text, post_text, ',
							'error_msg FROM form_element WHERE id = ',
							sql_num( $id ) );

		if ( db_rowcount( $sth ) < 1 ) {
			db_finish( $sth );
			return( 'Invalid ID.' );
		}
		
		my ( $req, $check, $read, $mult, $type, $reqid, $max, $tab,
			$row, $col, $size, $mod, $name, $value, $css, 
			$src, $param, $alt, $pre, $post, $error ) = db_next( $sth );
		
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
		
		if ( $r->method eq 'POST' ) {
			return( @err, $k->_form( $in ) );
		}
		else {
			$$in{quest} = 1;

			my $rth = db_query( $$k{'dbh'}, 'Get next question number',
								'SELECT question_number FROM form_element ',
								'WHERE form_data_id = ', sql_num( $fid ),
								'ORDER BY question_number' );

			while ( my $cur = db_next( $rth ) ) {
				$$in{quest}++ if ( $cur == $$in{quest} );
			}

			db_finish( $rth );

			return( $k->_form( $in ) );
		}
	}				
} # END $k->do_dup

#-------------------------------------------------
# $k->do_delete( $r, $fid, $id, $yes )
#-------------------------------------------------
sub do_delete {
	my ( $k, $r, $fid, $id, $yes ) = @_;

	my $in 				= $k->param( Apache2::Request->new( $r ) );
	$$k{page_title}	.=	'Delete Element';

	return( 'Invalid ID.' ) if ( ! is_integer( $fid ) );
	return( 'Invalid ID.' ) if ( ! is_integer( $id ) );

	if ( defined ( $$in{cancel} ) ) {
		return( $k->_relocate( $r, "$$k{rootp}/main/$fid" ) );
	}

	if ( defined $yes && $yes eq 'yes' ) {
		
		db_run( $$k{dbh}, 'Delete an element',
				'DELETE FROM form_element WHERE id = ', sql_num( $id ),
				'AND form_data_id = ', sql_num( $fid ) );

		my $sth = db_query( $$k{dbh}, 'Check if form is active',
							'SELECT active, page_count FROM form_data WHERE ',
							'id = ', sql_num( $fid ) );

		if ( db_rowcount( $sth ) < 1 ) {
			db_finish( $sth );
			return( 'Invalid ID.' );
		}
		
		my ( $active, $pcount ) = db_next( $sth );

		db_finish( $sth );

		if ( $active ) {
			my $rth = db_query( $$k{'dbh'}, 'Get pages with submit',
								'SELECT form_element.page_number FROM ',
								'form_element JOIN form_types ON ',
								'form_element.form_types_id = ',
								'form_types.id AND form_types.type = ',
								sql_str( 'submit' ), ' AND ',
								'form_element.form_data_id = ', 
								sql_num( $fid ) );
			
			my @pages;
			while ( my $p = db_next( $rth ) ) {
				$pages[$p] = 1;
			}

			db_finish( $rth );

			my $count = 0;
			for ( 0 .. $pcount ) {
				$count++ if ( $pages[$_] );
			}

			if ( $count != $pcount ) {
				db_run( $$k{dbh}, 'Disable form',
						sql_update( 'form_data', 'WHERE id = '.sql_num( $fid ),
									'active'	=> sql_bool( 0 ),
									'modified'	=> sql_str( 'now' ) ) );
			}
		}
		
		db_commit( $$k{dbh} );
			
		return( $k->_relocate( $r, "$$k{rootp}/main/$fid" ) );
	}
	else {
		
		my $mth = db_query( $$k{dbh}, 'Get element info',
							'SELECT name, question_number, page_number ',
							'FROM form_element WHERE id = ', sql_num( $id ) );

		if ( db_rowcount( $mth ) < 1 ) {
			db_finish( $mth );
			return( 'Invalid ID.' );
		}

		my ( $name, $quest, $page ) = db_next( $mth );

		db_finish( $mth );

		return(	ht_form_js( "$$k{uri}/yes" ),

				ht_div( { 'class' => 'box' } ),
				ht_table(),

				ht_tr(),
				ht_td( { 'class' => 'dta' },
						'Delete the element: "' . $name . '"?', ht_br(),
						'This will completely remove this element from the ',
						'form.', ht_br(),
						ht_b( 'Note:' ), 'If this is a ' . ht_b( 'Submit' ),
						'type element, it may de-activate the form.' ),
				ht_utr(),

				ht_tr(),
				ht_td( { 'class' => 'dta' }, ht_b( 'Page: ' ), $page ),
				ht_utr(),
				
				ht_tr(),
				ht_td( { 'class' => 'dta' }, ht_b( 'Question: ' ), $quest ),
				ht_utr(),

				ht_tr(),
				ht_td( { 'class' => 'dta' }, ht_b( 'Name: ' ), $name ),
				ht_utr(),

				ht_tr(),
				ht_td( { 'class' => 'rshd' },
						ht_submit( 'submit', 'Continue with Delete' ),
						ht_submit( 'cancel', 'Cancel' ) ),
				ht_utr(),

				ht_utable(),
				ht_udiv(),
				ht_uform() );
	}
} # END $k->do_delete

#-------------------------------------------------
# $k->do_main( $r, $fid )
#-------------------------------------------------
sub do_main {
	my ( $k, $r, $fid ) = @_;

	$$k{page_title}	.=	'Form Details';

	return( 'Invalid ID.' ) if ( ! is_integer( $fid ) );

	my @info = $k->_form_info( $fid );

	return( 'Invalid ID.' ) if ( ! @info );
	
	my @lines = ( 
		@info,
		ht_div( { 'class' => 'box' } ),
		ht_table(),

		ht_tr(),
		ht_td( { 'class' => 'shd', 'colspan' => '7' },
				ht_b( 'Form Elements' ) ),
		ht_utr(),

		ht_tr(),
		ht_td( { 'class' => 'shd' }, 'Page',
				ht_help( $$k{'help'}, 'item', 'a:fb:f:e:page_col' ) ),
		ht_td( { 'class' => 'shd' }, 'Question',
				ht_help( $$k{'help'}, 'item', 'a:fb:f:e:question_col' ) ),
		ht_td( { 'class' => 'shd' }, 'Name',
				ht_help( $$k{'help'}, 'item', 'a:fb:f:e:name_col' ) ),
		ht_td( { 'class' => 'shd' }, 'Tab Index',
				ht_help( $$k{'help'}, 'item', 'a:fb:f:e:tab_col' ) ),
		ht_td( { 'class' => 'shd' }, 'Type',
				ht_help( $$k{'help'}, 'item', 'a:fb:f:e:type_col' ) ),
		ht_td( { 'class' => 'shd' }, 'CSS',
				ht_help( $$k{'help'}, 'item', 'a:fb:f:e:css_col' ) ),
		ht_td( { 'class' => 'rshd' },
				'[', ht_a( "$$k{rootp}/add/$fid", 'Add Element' ), ']' ),
		ht_utr() );
		
	my $sth = db_query( $$k{dbh}, 'Get elements',
						'SELECT e.id, e.name, e.tab_index, e.question_number, ',
						'e.page_number, e.required, e.css_class, t.type FROM ',
						'form_element AS e, form_types AS t ',
						'WHERE t.id = e.form_types_id AND form_data_id = ',
						sql_num( $fid ), 
						'ORDER BY e.page_number, e.question_number' );

	if ( db_rowcount( $sth ) < 1 ) {
		push( @lines,
			ht_tr(),
			ht_td( { 'class' => 'dta', 'colspan' => '7' },
					ht_b( 'There are no form elements to display.' ) ),
			ht_utr() );
	}
	else {
		while ( my ( $id, $name, $tab, $quest, $page, $req, $css, $type ) =
				db_next( $sth ) ) {
		
		## defaults
		$tab = '&nbsp;' if ( ! is_text( $tab ) );
		$css = '&nbsp;' if ( ! is_text( $css ) );
		my $class = $req ? 'required' : 'dta';
		
		push( @lines,
			ht_tr(),
			ht_td( { 'class' => 'dta' }, $page ),
			ht_td( { 'class' => 'dta' }, $quest ),
			ht_td( { 'class' => $class }, $name ),
			ht_td( { 'class' => 'dta' }, $tab ),
			ht_td( { 'class' => 'dta' }, $type ),
			ht_td( { 'class' => 'dta' }, $css ),
			ht_td( { 'class' => 'rdta' },
					'[',
					ht_a( "$$k{rootp}/dup/$fid/$id", 'Copy' ), '|',
					ht_a( "$$k{rootp}/edit/$fid/$id", 'Edit' ), '|',
					ht_a( "$$k{rootp}/delete/$fid/$id", 'Delete' ),
					']' ),
			ht_utr() );
		}
	}

	db_finish( $sth );

	return( @lines, ht_a( "bottom", '' ), ht_utable(), ht_udiv() );
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

	$html	= $html ? $html : 0;
	$hid	= $hid ? $hid : 0;

	## Required - not possible
	if ( $$in{type} && $$in{req} ) {
		if ( $html && $$in{type} eq $html ) {
			push( @errors, ht_li( {}, 'The', ht_b( 'Element Type:' ),
							ht_i( 'HTML' ), 'cannot be a required field.' ) ); 
		}
		elsif ( $hid && $$in{type} eq $hid ) {
			push( @errors, ht_li( {}, 
							'The ', ht_b( 'Element Type:' ), ht_i( 'Hidden' ),
							'cannot be a required field.') );
		}
	}

	## Required - Read-Only
	if ( $$in{read} && $$in{req} ) {
		push( @errors, ht_li( {}, 	
						'An element that is', ht_b( 'Read-Only' ), 
						'cannot be required.' ) );
	}

	## Default - no Default Element defined
	if ( defined $$in{type} && ! $$in{type} && ! $$in{default} ) {
		push( @errors, ht_li( {},
								ht_b( 'Element Type' ), 'can only be', 
								ht_i( 'Default' ), 'when using a',
								ht_b( 'Default Element.' ) ) );
	}

	## Max Length
	if ( $$in{max} && ! is_integer( $$in{max} ) ) {
		push( @errors, ht_li( {}, 
						'A', ht_b( 'Max Length' ), 'must be an integer.' ) );
	}

	## Tab Index
	if ( $$in{tab} && ! is_integer( $$in{tab} ) ) {
		push( @errors, ht_li( {}, 
						'A', ht_b( 'Tab Index' ), 'must be an integer.' ) );
	}

	## Row Count
	if ( $$in{row} && ! is_integer( $$in{row} ) ) {
		push( @errors, ht_li( {}, 
						'A', ht_b( 'Row Count' ), 'must be an integer.' ) );
	}

	## Col Count
	if ( $$in{col} && ! is_integer( $$in{col} ) ) {
		push( @errors, ht_li( {}, 
						'A', ht_b( 'Col Count' ), 'must be an integer.' ) );
	}

	## Size Count
	if ( $$in{size} && ! is_integer( $$in{size} ) ) {
		push( @errors, ht_li( {}, 
						'A', ht_b( 'Size Count' ), 'must be an integer.' ) );
	}

	## Question Number
	if ( ! is_float( $$in{quest} ) ) {
		push( @errors, ht_li( {}, 
						'A', ht_b( 'Question Number' ), 'is required and ',
						'must be a real number (e.g. 1, 1.2, etc.).' ) );
	}
	else {
		my $oth = db_query( $$k{dbh}, 'Check for duplicates',
							'SELECT id FROM form_element WHERE ',
							'question_number = ', sql_num( $$in{quest} ),
							'AND form_data_id = ', sql_num( $$in{fid} ) );
							
		my $found = db_next( $oth ) || 0;
		
		db_finish( $oth );

		if ( $found && $found ne $$in{eid} ) {
			push( @errors, ht_li( {}, 
							'There is already an element with that', 
							ht_b( 'Question Number' ) ) );
		}
	}
	
	## Name
	if ( ! is_ident( $$in{name} ) ) {
		push( @errors, ht_li( {}, 'A', ht_b( 'Name' ), 
								'must not contain white space or symbols.' ) );
	} 
	else {
		my $pth = db_query( $$k{dbh}, 'Look for dup name',
							'SELECT form_element.id, ',
							'form_element.form_types_id FROM form_element, ',
							'form_types WHERE form_types.id = ',
							'form_element.form_types_id AND ',
							'( NOT form_types.type = ', sql_str( 'radio' ),
							' ) AND ( NOT form_types.type = ',
							sql_str( 'RADIO' ), ' ) AND ',
							'( NOT form_types.type = ', sql_str( 'html' ),
							' ) AND ( NOT form_types.type = ',
							sql_str( 'HTML' ), ' ) AND ( NOT ',
							'form_types.type = ', sql_str( 'submit' ),
							' ) AND ( NOT form_types.type = ',
							sql_str( 'RESET' ), ' ) AND ',
							' ( NOT form_types.type = ', sql_str( 'reset' ),
							' ) AND form_element.form_data_id = ', 
							sql_num( $$in{fid} ), ' AND form_element.name ',
							' = ', sql_str( $$in{name} ) );

		if ( db_rowcount( $pth ) > 0 ) {
			my ( $id, $type ) = db_next( $pth );
			if ( defined $$in{eid} && $id ne $$in{eid} && 
				 $$in{type} eq $type ) {
				push( @errors, ht_li( {}, 
								'An element with that', ht_b( 'Name' ),
								'already exists - this will cause errors in',
								'your form output - choose another',
								ht_b( 'Name' ) ) );
			}
		}
	}

	## CSS Class
	if ( $$in{css} && ! is_ident( $$in{css} ) && $$in{css} ne '' ) {
		push( @errors, ht_li( {}, 'A', ht_b( 'CSS Class' ),
								'must not contain white space or symbols.' ) );
	}

	## Error Message
	if ( $$in{req} && ! is_text( $$in{error} ) ) {
		push( @errors, ht_li( {}, 
						'An', ht_b( 'Error Message' ), 'is required for',
						'elements that are required.' ) );
	}

	## Element Type based requirements
	if ( defined $$in{type} ) {
		
		my $bth = db_query( $$k{'dbh'}, 'Get form_types',
							'SELECT name, value, row, col, size, max, ',
							'checkd, read, mult, tab, css, src, alt FROM ',
							'form_types WHERE id =', sql_num( $$in{'type'} ) );

		if ( db_rowcount( $bth ) < 1 ) {
			db_finish( $bth );
		}
		else {
			my $result = db_nextvals( $bth );

			foreach my $key ( keys %{$result} ) {
				if ( $result->{$key} && ! defined $$in{$key} ) {
					push( @errors, $result->{$key}, ht_br() );
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

	my @yesno = ( '0', 'No', '1', 'Yes' ); 	# YesNo
	my @etypes = ( '0', 'Default' ); 		# Element Types
	my @valid = ( '', 'None' ); 			# Validation
	my @defaults = ( '0', 'None' ); 		# Default Elements

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

	my $qth = db_query( $$k{dbh}, 'Get list of defaults',
						'SELECT id, name FROM form_element ',
						'WHERE isdefault = \'t\' ORDER BY name' );

	while ( my ( $id, $name ) = db_next( $qth ) ) {
		push( @defaults, $id, $name );
	}

	db_finish( $qth );

	## Page Count
	my $mth = db_query( $$k{dbh}, 'Get page count',
						'SELECT page_count FROM form_data WHERE id = ',
						sql_num( $$in{'fid'} ) );

	my $pcount = db_next( $mth );

	db_finish( $mth );

	my @pages;
	for ( 1 .. $pcount ) {
		push( @pages, $_, $_ );
	}

	my @lines = (
		ht_form_js( $$k{uri} ),
		ht_div( { 'class' => 'box' } ),
		ht_table(),

		ht_tr(),
		ht_td( { 'class' => 'hdr' }, ht_h( 3, 'Element Information' ) ) );
		
	if ( defined $$in{mod} ) {
		push( @lines,
			ht_td( { 'class' => 'rhdr', 'colspan' => '3' }, 
					'Last Modified:', $$in{mod} ),
			ht_utr() );
	}
	else {
		push( @lines,
			ht_td( { 'class' => 'hdr', 'colspan' => '3' }, '&nbsp;' ),
			ht_utr() );
	}
	
	push( @lines,
		## Element Data ----------------------------------------------
		ht_tr(),
		ht_td( { 'class' => 'shd', 'colspan' => '4' },
				ht_b( 'Element Data' ) ),
		ht_utr(),

		## Name
		ht_tr(),
		ht_td( { 'class' => 'shd' }, 'Name:' ),
		ht_td( { 'class' => 'dta', 'colspan' => '3' },
				ht_input( 'name', 'text', $in, 'size="60"' ),
				ht_help( $$k{'help'}, 'item', 'a:fb:f:e:name' ) ),
		ht_utr(),

		## Value
		ht_tr(),
		ht_td( { 'class' => 'shd' }, 'Value:' ),
		ht_td( { 'class' => 'dta', 'colspan' => '3' },
				ht_input( 'value', 'text', $in, 'size="60"' ),
				ht_help( $$k{'help'}, 'item', 'a:fb:f:e:value' ) ),
		ht_utr(),

		## Page
		ht_tr(),
		ht_td( { 'class' => 'shd' }, 'Page Number:' ),
		ht_td( { 'class' => 'dta', 'colspan' => '3' },
				ht_select( 'page', 1, $in, '', '', @pages ),
				ht_help( $$k{'help'}, 'item', 'a:fb:f:e:page_number' ) ),
		ht_utr(),

		## Question
		ht_tr(),
		ht_td( { 'class' => 'shd' }, 'Question Number:' ),
		ht_td( { 'class' => 'dta', 'colspan' => '3' },
				ht_input( 'quest', 'text', $in, 'size="5"' ),
				ht_help( $$k{'help'}, 'item', 'a:fb:f:e:question_number' ) ),
		ht_utr(),

		## Type
		ht_tr(),
		ht_td( { 'class' => 'shd' }, 'Element Type:' ),
		ht_td( { 'class' => 'dta' },
				ht_select( 'type', 1, $in, '', '', @etypes ),
				ht_help( $$k{'help'}, 'item', 'a:fb:f:e:form_type' ) ),
		
		## Default Element
		ht_td( { 'class' => 'shd' }, 'Default Element:' ),
		ht_td( { 'class' => 'dta' },
				ht_select( 'default', 1, $in, '', '', @defaults ),
				ht_help( $$k{'help'}, 'item', 'a:fb:f:e:form_default' ) ),
		ht_utr(),
		
		## Spacer ---
		ht_tr(),
		ht_td( { 'class' => 'shd' }, '&nbsp;' ),
		ht_td( { 'class' => 'dta', 'colspan' => '3' }, '&nbsp;' ),
		ht_utr(),

		## Vaildation Data -------------------------------------------
		ht_tr(),
		ht_td( { 'class' => 'shd', 'colspan' => '4' }, 
				ht_b( 'Validation Data' ) ),
		ht_utr(),

		## Required
		ht_tr(),
		ht_td( { 'class' => 'shd' }, 'Required Element:' ),
		ht_td( { 'class' => 'dta' },
				ht_select( 'req', 1, $in, '', '', @yesno ),
				ht_help( $$k{'help'}, 'item', 'a:fb:f:e:required' ) ),
		
		## Form Requirements
		ht_td( { 'class' => 'shd' }, 'Element Requirements:' ),
		ht_td( { 'class' => 'dta' },
				ht_select( 'reqid', 1, $in, '', '', @valid ),
				ht_help( $$k{'help'}, 'item', 'a:fb:f:e:requirements' ) ),
		ht_utr(),

		## Error Message
		ht_tr(),
		ht_td( { 'class' => 'shd' }, 'Error Message:' ),
		ht_td( { 'class' => 'dta', 'colspan' => '3' },
				ht_input( 'error', 'text', $in, 'size="40"' ),
				ht_help( $$k{'help'}, 'item', 'a:fb:f:e:error_msg' ) ),
		ht_utr(),

		## Spacer ---
		ht_tr(),
		ht_td( { 'class' => 'shd' }, '&nbsp;' ),
		ht_td( { 'class' => 'dta', 'colspan' => '3' }, '&nbsp;' ),
		ht_utr(),

		## HTML Data -------------------------------------------------
		ht_tr(),
		ht_td( { 'class' => 'shd', 'colspan' => '4' }, ht_b( 'HTML Data' ) ),
		ht_utr(),

		## CSS Class
		ht_tr(),
		ht_td( { 'class' => 'shd' }, 'CSS Class:' ),
		ht_td( { 'class' => 'dta' }, 
				ht_input( 'css', 'text', $in, 'size="40"' ),
				ht_help( $$k{'help'}, 'item', 'a:fb:f:e:css_class' ) ),
		ht_utr(),
		
		## Checked
		ht_tr(),
		ht_td( { 'class' => 'shd' }, 'Checked:' ),
		ht_td( { 'class' => 'dta' },
				ht_select( 'checkd', 1, $in, '', '', @yesno ),
				ht_help( $$k{'help'}, 'item', 'a:fb:f:e:checked' ) ),

		## Read Only
		ht_td( { 'class' => 'shd' }, 'Read-Only:' ),
		ht_td( { 'class' => 'dta' },
				ht_select( 'read', 1, $in, '', '', @yesno ),
				ht_help( $$k{'help'}, 'item', 'a:fb:f:e:readonly' ) ),
		ht_utr(),

		## Tab Index
		ht_tr(),
		ht_td( { 'class' => 'shd' }, 'Tab Index:' ),
		ht_td( { 'class' => 'dta' },
				ht_input( 'tab', 'text', $in, 'size="10"' ),
				ht_help( $$k{'help'}, 'item', 'a:fb:f:e:tab_index' ) ),

		## Multiple Select
		ht_td( { 'class' => 'shd' }, 'Multiple Select:' ),
		ht_td( { 'class' => 'dta' },
				ht_select( 'mult', 1, $in, '', '', @yesno ),
				ht_help( $$k{'help'}, 'item', 'a:fb:f:e:multiple' ) ),
		ht_utr(),

		## Size Count
		ht_tr(),
		ht_td( { 'class' => 'shd' }, 'Size Count:' ),
		ht_td( { 'class' => 'dta' },
				ht_input( 'size', 'text', $in, 'size="5"' ),
				ht_help( $$k{'help'}, 'item', 'a:fb:f:e:size_count' ) ),

		## Max Length
		ht_td( { 'class' => 'shd' }, 'Max Length:' ),
		ht_td( { 'class' => 'dta' },
				ht_input( 'max', 'text', $in, 'size="5"' ),
				ht_help( $$k{'help'}, 'item', 'a:fb:f:e:max_length' ) ),
		
		## Row Count
		ht_tr(),
		ht_td( { 'class' => 'shd' }, 'Row Count:' ),
		ht_td( { 'class' => 'dta' },
				ht_input( 'row', 'text', $in, 'size="5"' ),
				ht_help( $$k{'help'}, 'item', 'a:fb:f:e:row_count' ) ),
		
		## Col Count
		ht_td( { 'class' => 'shd' }, 'Col Count:' ),
		ht_td( { 'class' => 'dta' },
				ht_input( 'col', 'text', $in, 'size="5"' ),
				ht_help( $$k{'help'}, 'item', 'a:fb:f:e:col_count' ) ),
		ht_utr(),
		
		## Source
		ht_tr(),
		ht_td( { 'class' => 'shd' }, 'Source:' ),
		ht_td( { 'class' => 'dta', 'colspan' => '3' },
				ht_input( 'src', 'text', $in, 'size="40"' ),
				ht_help( $$k{'help'}, 'item', 'a:fb:f:e:src' ) ),
		ht_utr(),
		
		## Alt
		ht_tr(),
		ht_td( { 'class' => 'shd' }, 'Alt:' ),
		ht_td( { 'class' => 'dta', 'colspan' => '3' },
				ht_input( 'alt', 'text', $in, 'size="40"' ),
				ht_help( $$k{'help'}, 'item', 'a:fb:f:e:alt' ) ),
		ht_utr(),
		
		## Additional Parameters
		ht_tr(),
		ht_td( { 'class' => 'shd' }, 'Additional Parameters:' ),
		ht_td( { 'class' => 'dta', 'colspan' => '3' },
				ht_input( 'param', 'text', $in, 'size="60"' ),
				ht_help( $$k{'help'}, 'item', 'a:fb:f:e:add_param' ) ),
		ht_utr(),

		## Pre-Text
		ht_tr(),
		ht_td( { 'class' => 'shd' }, 'Pre-Text:' ),
		ht_td( { 'class' => 'dta', 'colspan' => '3' },
				ht_input( 'pre', 'textarea', $in, 'rows="6" cols="60"' ),
				ht_help( $$k{'help'}, 'item', 'a:fb:f:e:pre_text' ) ),
		ht_utr(),
		
		## Post-Text
		ht_tr(),
		ht_td( { 'class' => 'shd' }, 'Post-Text:' ),
		ht_td( { 'class' => 'dta', 'colspan' => '3' },
				ht_input( 'post', 'textarea', $in, 'rows="6" cols="60"' ),
				ht_help( $$k{'help'}, 'item', 'a:fb:f:e:post_text' ) ),
		ht_utr() );

	my @buttons;
	my @links;
	if ( defined $$in{eid} ) {
		
		my $bth = db_query( $$k{'dbh'}, 'Get list of question numbers',
							'SELECT id FROM form_element ',
							'WHERE form_data_id = ', sql_num( $$in{fid} ),
							'ORDER BY page_number, question_number' );

		my ( $n, $p );

		while ( $n = db_next( $bth ) ) {
			last if ( $n == $$in{eid} );
			$p = $n;
		}

		$n = db_next( $bth );
		
		db_finish( $bth );
		
		## Are there prev elements?
		if ( $p ) {
			push( @links, ht_a( "$$k{rootp}/edit/$$in{fid}/$p", 'Previous' ) );
			push( @buttons, ht_submit( 'prev', 'Save and Previous' ) );
		}
		
		## Are there next elements?
		if ( $n ) {
			push( @links, ht_a( "$$k{rootp}/edit/$$in{fid}/$n", 'Next' ) );
			push( @buttons, ht_submit( 'next', 'Save and Next' ) );
		}
	}
	
	push( @lines,
		ht_tr(),
		ht_td( { 'class' => 'shd', 'colspan' => '2' }, @links ),
		ht_td( { 'class' => 'rshd', 'colspan' => '2' },
				ht_submit( 'save', 'Save' ),
				@buttons,
				ht_submit( 'add', 'Save and Add' ),
				ht_submit( 'cancel', 'Cancel' ) ),
		ht_utr() );

	return( @lines, ht_utable(), ht_udiv(), ht_uform() );
} # END $k->_form

#-------------------------------------------------
# $k->_set_defaults( $in )
#-------------------------------------------------
sub _set_defaults {
	my ( $k, $in ) = @_;

	my $sth = db_query( $$k{'dbh'}, 'Get the default element',
						'SELECT required, checked, readonly, multiple,',
						'form_types_id, form_validate_id, max_length,',
						'tab_index, row_count, col_count, size_count,',
						'name, value, css_class, src, addition_params,',
						'alt, pre_text, post_text, error_msg FROM',
						'form_element WHERE id = ', sql_num( $$in{default} ) );

	if ( db_rowcount( $sth ) < 1 ) {
		db_finish( $sth );
		return( $in );
	}

	my ( $req, $check, $read, $mult, $type, $reqid, $max, $tab, $row, $col,
		$size, $name, $value, $css, $src, $param, $alt, $pre, $post,
		$error ) = db_next( $sth );

	db_finish( $sth );

	$$in{type}	= $type;
	$$in{name}	= $name		if ( ! is_text( $$in{name} ) );
	$$in{req}	= $req		if ( ! $$in{req} );
	$$in{checkd}= $check	if ( ! $$in{check} );
	$$in{read}	= $read		if ( ! $$in{read} );
	$$in{mult}	= $mult		if ( ! $$in{mult} );
	$$in{reqid}	= $reqid	if ( ! $$in{reqid} );
	$$in{max}	= $max		if ( ! is_text( $$in{max} ) );
	$$in{tab}	= $tab		if ( ! is_text( $$in{tab} ) );
	$$in{row}	= $row		if ( ! is_text( $$in{row} ) );
	$$in{col}	= $col		if ( ! is_text( $$in{col} ) );
	$$in{size}	= $size		if ( ! is_text( $$in{size} ) );
	$$in{value}	= $value	if ( ! is_text( $$in{value} ) );
	$$in{css}	= $css		if ( ! is_text( $$in{css} ) );
	$$in{src}	= $src		if ( ! is_text( $$in{src} ) );
	$$in{param}	= $param	if ( ! is_text( $$in{param} ) );
	$$in{alt}	= $alt		if ( ! is_text( $$in{alt} ) );
	$$in{pre}	= $pre		if ( ! is_text( $$in{pre} ) );
	$$in{post}	= $post		if ( ! is_text( $$in{post} ) );
	$$in{error}	= $error	if ( ! is_text( $$in{error} ) );

	return( $in );
} # END $k->_set_defaults
	
#-------------------------------------------------
# $k->_form_info( $fid )
#-------------------------------------------------
sub _form_info {
	my ( $k, $fid ) = @_;

	my $sth = db_query( $$k{dbh}, 'Get the form data',
						'SELECT active, page_count, name, ident, frame ',
						'FROM form_data WHERE id = ', sql_num( $fid ) );

	if ( db_rowcount( $sth ) < 1 ) {
		db_finish( $sth );
		return();
	}

	my ( $active, $pcount, $name, $ident, $frame ) = db_next( $sth );

	db_finish( $sth );

	return( ht_table(),

			ht_tr(),
			ht_td( { 'class' => 'hdr' }, 'Form Details' ),
			ht_td( { 'class' => 'rhdr' },
					'[',
					ht_a( $$k{formrootp}, 'Main' ), '|',
					ht_a( "$$k{viewrootp}/view/$ident", 'View' ), '|',
					ht_a( "$$k{viewrootp}/view/$ident/1", 'Preview' ), '|',
					ht_a( "$$k{formrootp}/edit/$fid", 'Edit' ), '|',
					ht_a( "$$k{formrootp}/delete/$fid", 'Delete' ), '|',
					ht_a( '#bottom', 'End of Page' ), ']' ),
			ht_utr(),

			## Name
			ht_tr(),
			ht_td( { 'class' => 'shd' }, 'Name:' ),
			ht_td( {}, $name ),
			ht_utr(),

			## Active
			ht_tr(),
			ht_td( { 'class' => 'shd' }, 'Active:' ),
			ht_td( {}, ( $active ? 'Active' : 'Disabled' ) ),
			ht_utr(),

			## Page Count
			ht_tr(),
			ht_td( { 'class' => 'shd' }, 'Page Count:' ),
			ht_td( {}, $pcount, ( $pcount > 1 ? ' pages' : ' page' ) ),
			ht_utr(),

			## Frame
			ht_tr(),
			ht_td( { 'class' => 'shd' }, 'Frame:' ),
			ht_td( {}, $frame ),
			ht_utr(),

			ht_utable() );
} # END $k->_form_info

# EOF
1

__END__

=head1 NAME 

Alchemy::FormBuilder::Form::Element - FormBuilder Elements 

=head1 SYNOPSIS

 use Alchemy::FormBuilder::Form::Element;

=head1 DESCRIPTION

This module provides the interface for list, edit, create, and delete
with respect to the form elements listed in the database. Elements are
accessible via specific forms only.

=head1 APACHE

This is a sample of the location required for this module to run.
Consult Alchemy::FormBuilder(3) to learn about the configuration
options.

  <Location /admin/forms/element >
    SetHandler perl-script

    PerlSetVar  SiteTitle    "FormBuilder - "
    PerlSetVar  Frame        "template;FormBuilder.tp"
    
    PerlHandler Alchemy::FormBuilder::Form::Element
  </Location>

=head1 DATABASE

This is the core table that this module manipulates.

  create table "form_element" (
    "id" integer primary key not null
      default nextval( 'form_element_sequence' ),
	"isdefault"				boolean default 'false',
    "required" boolean default 'false',      /* element required */
    "checked" boolean default 'false',       /* html attrib */
    "readonly" boolean default 'false',      /* html attrib */
    "multiple" boolean default 'false',      /* html attrib */
    "form_data_id" integer,                  
    "form_types_id" integer,                 /* type of element */
    "form_validate_id" integer,          /* for validation */
    "max_length" integer,                    /* html attrib */
    "tab_index" integer,                     /* html attrib */
    "row_count" integer,                     /* html attrib */
    "col_count" integer,                     /* html attrib */
    "size_count" integer,                    /* html attrib */
    "page_number" integer,                   
    "created" timestamp with time zone,      /* creation date */
    "modified" timestamp with time zone,     /* modified date */
    "question_number" real,                  
    "name" varchar not null,                 /* html attrib */
    "value" varchar,                         /* html attrib */
    "css_class" varchar,                     /* html attrib */
    "src" varchar,                           /* html attrib */
    "addition_params" text,                  /* html attrib - extras */
    "alt" text,                              /* html attrib */
    "pre_text" text,                         /* element text - first */
    "post_text" text,                        /* element text - last */
    "error_msg" text                         /* error - for required's */
  );

=head1 FUNCTIONS

  $k->do_add( $r, $fid )
    Adds a new form element to the database for the specified form id

  $k->do_edit( $r, $fid, $id )
      Edit an existing form element for the specified form id

  $k->do_dup( $r, $fid, $id )
    Adds a new form element to the database, duplicating the element with 
    the id provided for the specified form id

  $k->do_delete( $r, $fid, $id, $yes )
    Delete an existing form element with id, from the specified form id - 
    requires confirmation of delete
    
  $k->do_main( $r, $fid )
    Provides a brief summary of the specified form id and a listing of 
    all associated form elements in the database for add, edit, and 
    delete of form elements
    
=head1 SEE ALSO

Alchemy::FormBuilder(3), Alchemy::FormBuilder::Form(3), KrKit(3), perl(3)

=head1 LIMITATIONS

None specified... yet...

=head1 AUTHOR

Ron Andrews <ron.andrews@cognilogic.net>

=head1 COPYRIGHT AND LICENSE

Copyright (C) 2004 by Ron Andrews. All rights reserved.

You may distribute under the terms of either the GNU General Public
License or the Artistic License, as specified in the Perl README file.

=cut

