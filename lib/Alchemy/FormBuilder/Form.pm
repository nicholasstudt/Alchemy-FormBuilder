package Alchemy::FormBuilder::Form;

use strict;
use POSIX qw( strftime );
use Time::Local;
use Apache2::Request qw();

use KrKit::Calendar;
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

	my @err;

	## Ident
	if ( ! is_ident( $$in{ident} ) ) {
		push( @err, ht_li( {}, 	'You must supply an ', ht_b( 'Ident' ), 
								'which contains no white space or symbols.') );
	}
	else {
		my $sth = db_query( $$k{'dbh'}, 'Search for a duplicate ident',
							'SELECT id FROM form_data WHERE ident = ' .
							sql_str( $$in{'ident'} ) );

		my $dup = db_next( $sth );

		db_finish( $sth );

		if ( $dup && $$k{uri} !~ /edit/ && 
			 ( ! defined $$in{form_id} || $dup ne $$in{form_id} ) ) {
			push( @err, ht_li( {}, 	'There is already a form with that ',
									ht_b( 'Ident.' ) ) );
		}
	}

	## Name
	if ( ! is_text( $$in{name} ) ) {
		push( @err, ht_li( {}, 'You must give the form a', ht_b( 'Name.') ) );
	}

	## Description
	if ( ! is_text( $$in{descr} ) ) {
		push( @err, ht_li( {}, 'You must supply a', ht_b( 'Description.') ) );
	}

	## Active
	if ( $$in{active} ) {
		if ( $$in{form_id} ) {
			my $count = $$in{pcount};
			my @pages;

			my $sth = db_query( $$k{dbh}, 'Get pages with submit',
								'SELECT form_element.page_number FROM ',
								'form_element, form_types WHERE ',
								'form_element.form_types_id = ',
								'form_types.id AND form_types.type = ',
								sql_str( 'submit' ) , 'AND' ,
								'form_element.form_data_id = ' ,
								sql_num( $$in{form_id} ) );

			while ( my $sub = db_next( $sth ) ) {
				$pages[$sub] = 1;
			}

			db_finish( $sth );

			my $counter = 0;
			for ( my $i = 0; $i <= $count; $i++ ) {
				$counter++ if ( $pages[$i] );
			}

			if ( $counter != $count ) {
				push( @err, ht_li( {}, 'Every page of the form must contain',
									'at least a submit button (element) to be',
									ht_b( 'Active.' ) ) );
			}
		}
		else {
			push( @err, ht_li( {}, 'Every page of the form must contain ',
								'at least a submit button (element) to be ',
								ht_b( 'Active.' ) ) );
		}
	}

	## Page Count
	if ( ! is_integer( $$in{pcount} ) ) {
		push( @err, ht_li( {}, 	'You must supply a', ht_b( 'Page Count' ),
								'and it must be an integer.' ) );
	}
	elsif ( $$in{pcount} < 1 ) {
		push( @err, ht_li( {}, 	'You must supply a', ht_b( 'Page Count' ),
								' of at least 1.' ) );
	}

	my ( $start, $stop ) = ( 0, 0 );
	my ( @start ) = split( /-/, defined $$in{start} ? $$in{start} : '' );
	my ( @stop ) = split( /-/, defined $$in{stop} ? $$in{stop} : '' );
		
	## Start Date
	if ( ! is_date( join( '-', (@start)[1,2,0] ) ) ) {
		push( @err, ht_li( {}, 	'You must supply a', ht_b( 'Start Date' ),
								' in the format: YYYY-MM-DD.' ) );
	}
	else {
		$start = timelocal( 0, 0, 12, $start[2], $start[1]-1, $start[0] );
	}
	
	## Stop Date 
	if ( ! is_date( join( '-', (@stop)[1,2,0] ) ) ) {
		push( @err, ht_li( {}, 	'You must supply a', ht_b( 'Stop Date' ),
								'in the format: YYYY-MM-DD.' ) );
	}
	else {
		$stop = timelocal( 0, 0, 12,  $stop[2], $stop[1]-1, $stop[0]  );
	}
	
	# Verify start is before stop
	if ( $start > 0 && $stop > 0 && $start > $stop ) {
		push( @err, ht_li( {},  'The', ht_b( 'Stop Date' ), 
								'selected occurs before the',
								ht_b( 'Start Date.' ) ) );
	}
	
	## Redirect Cancel
	if ( ! defined $$in{redircancel} || ( defined $$in{redircancel} && 
			$$in{redircancel} !~ /^http:\/\// ) ) {
		push( @err, ht_li( {}, 	'You must supply a valid URL for the ',
								ht_b( 'Redirect Cancel' ), 
								'location. A valid URL is of the form:',
								ht_i( 'http://domain.com.' ) ) );
	}
	else {
		$$in{redircancel} =~ /http:\/\/(.*)/;
		my $uri = $1;
		if ( ! is_text( $uri ) ) {
			push( @err, ht_li( {}, 	'You must supply a valid URL for the ',
									ht_b( 'Redirect Cancel' ), 
									'location. A valid URL is of the form:',
									ht_i( 'http://domain.com.' ) ) );
		}
	}

	# {confirm} || {redirconfirm}, not both but one is required.
	if ( ! is_text( $$in{confirm} ) && ! is_text( $$in{redirconfirm} )  ) {
		push( @err, ht_li( {}, 'You must supply a', ht_b( 'Redirect Confirm' ), 
								'or a ',  ht_b( 'Confirmation Page.' ) ) );
	}
	elsif ( is_text( $$in{confirm} ) && is_text( $$in{redirconfirm} )  ) {
		push( @err, ht_li( {}, 'You must supply either a',
								ht_b( 'Redirect Confirm' ), 'or a ',  
								ht_b( 'Confirmation Page' ), 'not both.' ) );
	}
	else { # We have one, which is it.
		if ( is_text( $$in{redirconfirm} ) ) {
			# Verify URL-ness	
			if ( $$in{redirconfirm} !~ /^http:\/\/\w+/ ) { 	
				push( @err, ht_li( {}, 'You must supply a valid URL for the',
										ht_b( 'Redirect Confirm' ), 
										'location.'  ) );
			}
		}
		else { 	# $in{confirm} # See if the file exists.
			if ( $$in{confirm} =~ /\.\./ ) {
				push( @err, ht_li( {}, 	'Confirmation Page may not ',
										'contain "..".' ) );
			}
			elsif ( ! -T "$$k{doc_root}/$$in{confirm}" ) {
				push( @err, ht_li( {}, 	'Confirmation Page file does not',
										'exist or is not a text file.'  ) );
			}
		}
	}

	## Filename
	if ( defined $$in{fname} && $$in{fname} ne '' &&
			( ! is_ident( $$in{fname} || $$in{fname} =~ /\// || 
			$$in{fname} =~ /\\/ || $$in{fname} =~ /\.\./ ) ) ) {
		push( @err, ht_li( {}, 'A', ht_b( 'Filename' ),
						'must contain valid text (no spaces or symbols).' ) );
	}
	elsif ( defined $$in{store} && 
			( $$in{store} eq 'scsv' || $$in{shtml} ) && 
			( ! is_text( $$in{fname} ) || ! $$in{fname} ) ) {
		push( @err, ht_li( {}, 'A', ht_b( 'Filename' ),
								'must be declared in order to accumulate ',
								'a results into a single file.' ) );
	}

	## Email Address
	if ( defined $$in{email} && $$in{email} ne '' ) {
		my @emails;
		$$in{email} =~ s/,$//g;

		if ( $$in{email} =~ /,/ ) {
			@emails = split( /,/, $$in{email} );
		}
		else {
			push( @emails, $$in{'email'} );
		}

		while ( my $addr = shift @emails ) {
			if ( ! is_email( $addr ) ) {
				push( @err, ht_li( {}, 	"$addr is not a valid ",
										ht_b( 'E-Mail Address.' ) ) );
			}
		}
	}
	elsif( $$in{send_email} ) {
		push( @err, ht_li( {}, 	'You must supply a valid',
								ht_b( 'E-Mail Address.' ) ) );
	}
	
	## Email Subject
	if ( ! is_text( $$in{subject} ) && defined $$in{send_email} &&
			$$in{send_email} ) {
		push( @err, ht_li( {}, 'You must supply an', 
								ht_b( 'E-Mail Subject.' ) ) );
	}

	## Delivery
	if ( defined $$in{sotre} ) { 
		if ( $$in{store} eq 'dns' && ! $$in{send_email} ) {
			push( @err,  ht_li( {}, 'You must choose a method of ',
									'recording/delivering the results - use ',
									ht_b( 'Store Locally As' ), 'or',
									ht_b( 'Send E-Mail' ), 'to do so.' ) );
		}
		elsif ( $$in{store} eq 'dns' && $$in{send_email} eq '2' ) {
			push( @err, ht_li( {}, 	'You must choose a method of saving the ',
									'results if you want to use', 
									ht_i( 'Notify Only.' ) ) );
		}
	}

	## Frame
	if ( ! is_text( $$in{frame} ) ) {
		push( @err, ht_li( {}, 	'You must select a', ht_b( 'Frame' ),
								'(template)' ) );
	}

	if ( @err ) {
		return( ht_div( { 'class' => 'error' },
						ht_h( 1, 'Errors' ), ht_ul( {}, @err ) ) );
	}

	return();
} # END $k->_checkvals( $in )

#-------------------------------------------------
# $k->_form( $in )
#-------------------------------------------------
sub _form {
	my ( $k, $in ) = @_;

	## Select Box Definitions
	my @templates = ( 'plain', 'No Template' );
	my @active	= ( '1', 'Active', '0', 'Disabled' );
	my @yesno	= ( '0', 'No', '1', 'Yes' );
	my @email	= ( '0', 'No', '1', 'Yes', '2', 'Notify Only' );
	my @mod 	= ( '&nbsp;' );
	my @sendas	= ( 'inline', 'Inline Text Only',
					'txt', 'Attached Text',
					'html', 'Attached HTML',
					'csv', 'Attached CSV' );
	my @store	= ( 'dns', 'Do Not Save',
					'stxt', 'Text File',
					'scsv', 'CSV File',
					'shtml', 'HTML File' );

	if ( $$in{modified} ) {
		push( @mod, 'Last Modified: ', 
					strftime( $$k{fmt_d}, localtime( $$in{modified} ) ) );
	}

	if ( opendir( TEMPLATES, $$k{template_dir} ) ) {
		
		while ( my $f = readdir( TEMPLATES ) ) {
			push( @templates, "template;$f", $f ) if ( $f =~ /\.tp$/ );
		}
	
		closedir( TEMPLATES );
	}
	
	## Prepare the form
	return( ht_form_js( $$k{'uri'}, 'name="dated"' ),
			q!<script type="text/javascript">!,
			q!  function SetDate( field, date ) {!,
			q!   eval( 'document.dated.' + field + '.value = date;' );!,
			q!  }!,

			q!  function datepopup( name ) {!,
			qq!    window.open('$$k{rootp}/cal/' + name, !,
			q!				'Shortcut', 'height=250, width=250' + !,
			q!				',screenX=' + (window.screenX + 150) + !,
			q!				',screenY=' + (window.screenY + 100) + !,
			q!				',scrollbars,resizable' );!,
			q!  }!,
			q!</script>!,

			ht_table(),

			ht_tr(),
			ht_td( { 'class' => 'hdr' }, 'Form Data' ),
			ht_td( { 'class' => 'rhdr' }, @mod ),
			ht_utr(),

			## Name
			ht_tr(),
			ht_td( { 'class' => 'shd' }, 'Name:' ),
			ht_td( {}, 	ht_input( 'name', 'text', $in ),
						ht_help( $$k{'help'}, 'item', 'a:fb:f:name' ) ),
			ht_utr(),

			## Ident
			ht_tr(),
			ht_td( { 'class' => 'shd' }, 'Ident:' ),
			ht_td( {}, 	ht_input( 'ident', 'text', $in ),
						ht_help( $$k{'help'}, 'item', 'a:fb:f:ident' ) ),
			ht_utr(),

			## Description
			ht_tr(),
			ht_td( { 'class' => 'shd' }, 'Description:' ),
			ht_td( {},
					ht_input( 'descr', 'textarea', $in,
								'rows="4" cols="60"' ),
					ht_help( $$k{'help'}, 'item', 'a:fb:f:description' ) ),
			ht_utr(),

			## Active
			ht_tr(),
			ht_td( { 'class' => 'shd' }, 'Active:' ),
			ht_td( {}, 	ht_select( 'active', 1, $in, '', '', @active ),
						ht_help( $$k{'help'}, 'item', 'a:fb:f:active' ) ),
			ht_utr(),

			## Page Count
			ht_tr(),
			ht_td( { 'class' => 'shd' }, 'Page Count:' ),
			ht_td( {},
					ht_input( 'pcount', 'text', $in,
								'size="3" maxlength="3"' ),
					ht_help( $$k{'help'}, 'item', 'a:fb:f:page_count' ) ),
			ht_utr(),

			## Start Date
			ht_tr(),
			ht_td( { 'class' => 'shd' }, 'Start Date:' ),
			ht_td( {},
					ht_input( 'start', 'text', $in ),
					'[', ht_a( 'javascript://', 'Set Date',
							q!onClick="datepopup('start')"! ), ']',
					ht_help( $$k{'help'}, 'item', 'a:fb:f:start_date' ) ),
			ht_utr(),

			## Stop Date
			ht_tr(),
			ht_td( { 'class' => 'shd' }, 'Stop Date:' ),
			ht_td( {},
					ht_input( 'stop', 'text', $in ),
					'[', ht_a( 'javascript://', 'Set Date',
							q!onClick="datepopup('stop')"! ), ']',
					ht_help( $$k{'help'}, 'item', 'a:fb:f:stop_date' ) ),
			ht_utr(),

			## Frame
			ht_tr(),
			ht_td( { 'class' => 'shd' }, 'Web-Page Template:' ),
			ht_td( {}, 	ht_select( 'frame', '1', $in, '', '', @templates ),
						ht_help( $$k{'help'}, 'item', 'a:fb:f:frame' ) ),
			ht_utr(),

			## Redirect Cancel
			ht_tr(),
			ht_td( { 'class' => 'shd' }, 'Redirect Cancel:' ),
			ht_td( {}, 	ht_input( 'redircancel', 'text', $in ),
						ht_help( $$k{'help'}, 'item', 
								'a:fb:f:redirect_cancel' ) ),
			ht_utr(),

			## Redirect Confirm
			ht_tr(),
			ht_td( { 'class' => 'shd' }, 'Redirect Confirm:' ),
			ht_td( {}, ht_input( 'redirconfirm', 'text', $in ),
						ht_help( $$k{'help'}, 'item',
								'a:fb:f:redirect_confirm' ) ),
			ht_utr(),

			## Confirmation Page
			ht_tr(),
			ht_td( { 'class' => 'shd' }, 'Confirmation Page:' ),
			ht_td( {}, 	ht_input( 'confirm', 'text', $in ),
						ht_help( $$k{'help'}, 'item', 'a:fb:f:confirm' ) ),
			ht_utr(),

			## SAVE LOCATION
			ht_tr(),
			ht_td( { 'class' => 'shd', 'colspan' => '2' },
					'Storing Locally in', 
					ht_a( $$k{'file_uri'}, $$k{'file_uri'} ), 'Directory' ),
			ht_utr(),

			## Store As
			ht_tr(),
			ht_td( { 'class' => 'shd' }, 'Store Locally As:' ),
			ht_td( {}, 	ht_select( 'store', 1, $in, '', '', @store ),
						ht_help( $$k{'help'}, 'item', 'a:fb:f:save_as' ) ),
			ht_utr(),

			## Filename
			ht_tr(),
			ht_td( { 'class' => 'shd' }, 'Filename:' ),
			ht_td( {}, 	ht_input( 'fname', 'text', $in ),
						ht_help( $$k{'help'}, 'item', 'a:fb:f:filename' ) ),
			ht_utr(),

			## EMAIL
			ht_tr(),
			ht_td( { 'class' => 'shd', 'colspan' => '2' },
					'E-mail Preferences' ),
			ht_utr(),

			## Send Email
			ht_tr(),
			ht_td( { 'class' => 'shd' }, 'Send E-Mail:' ),
			ht_td( {},
					ht_select( 'send_email', 1, $in, '', '', @email ),
					ht_help( $$k{'help'}, 'item', 'a:fb:f:send_email' ) ),
			ht_utr(),

			## Email Address
			ht_tr(),
			ht_td( { 'class' => 'shd' }, 'E-Mail Address:' ),
			ht_td( {},
					ht_input( 'email', 'text', $in ),
					ht_help( $$k{'help'}, 'item', 'a:fb:f:email_address' ) ),
			ht_utr(),

			## Email Subject
			ht_tr(),
			ht_td( { 'class' => 'shd' }, 'E-Mail Subject:' ),
			ht_td( {},
					ht_input( 'subject', 'text' , $in ),
					ht_help( $$k{'help'}, 'item', 'a:fb:f:email_subject' ) ),
			ht_utr(),

			## Send As
			ht_tr(),
			ht_td( { 'class' => 'shd' }, 'Send Data As:' ),
			ht_td( {},
					ht_select( 'send', 1, $in, '', '', @sendas ),
					ht_help( $$k{'help'}, 'item', 'a:fb:f:send_as' ) ),
			ht_utr(),
	
			## Submission
			ht_tr(),
			ht_td( { 'class' => 'rshd', 'colspan' => '2' },
					ht_submit( 'save', 'Save' ),
					ht_submit( 'cancel', 'Cancel' ) ),
			ht_utr(),
	
			ht_utable(), 
			ht_uform() );
} # END $k->_form( $in )

#-------------------------------------------------
# $k->do_cal( $r, $name, $year, $month ) 
#-------------------------------------------------
sub do_cal {
	my ( $k, $r, $name, $year, $month ) = @_;

	$$k{frame}		= $$k{cal_frame};
	$$k{page_title}	= $$k{cal_title};
	
	$name	= ''							if ( ! is_text( $name ) );
	$year	= ( 1900 + ( localtime() )[5] )	if ( ! is_number( $year ) );
	$month	= ( 1 + ( localtime() )[4] )	if ( ! is_number( $month ) );

	# Generate the day entry for cal_month.
	my $cday = sub {	my ( $y, $m, $d ) = @_;
						return( ht_a('javascript://', $d, 
								"onClick=\"SendDate( '$y-$m-$d')\"" ) ); };

	return( '<script type="text/javascript">',
			'<!-- ',
			'    function SendDate(d) { ',
			"        window.opener.SetDate( \"$name\", d ); window.close();",
			'    }',
			'//-->',
			'</script>',
			cal_month($r, "$$k{rootp}/cal/$name", $month, $year, 1, \&$cday) );
} # END $k->do_cal

#-------------------------------------------------
# $k->do_add( $r )
#-------------------------------------------------
sub do_add {
	my ( $k, $r ) = @_;
	
	my $in 			= $k->param( Apache2::Request->new( $r ) );
	$$k{page_title}	.=	'Add Form';

	return( $k->_relocate( $r, $$k{rootp} ) ) if ( $$in{cancel} );

	if ( ! ( my @err = $k->_checkvals( $in ) ) ) {

		$$in{confirm}	= '' if ( ! defined $$in{confirm} );
		$$in{email} =~ s/\s//g; ## strip spaces

		## Save the form data to the database
		db_run( $$k{dbh}, 'Create a new form',
				sql_insert( 'form_data',
							'active'		=> sql_bool( $$in{active} ),
							'send_email'	=> sql_bool( $$in{send_email} ),
							'page_count'	=> sql_num( $$in{pcount} ),
							'store_as'		=> sql_str( $$in{store} ),
							'filename'		=> sql_str( $$in{fname} ),
							'send_as'		=> sql_str( $$in{send} ),
							'created'		=> sql_str( 'now' ),
							'modified'		=> sql_str( 'now' ),
							'start_date'	=> sql_str( $$in{start} ),
							'stop_date'		=> sql_str( $$in{stop} ),
							'ident'			=> sql_str( $$in{ident} ),
							'name'			=> sql_str( $$in{name} ),
							'email_address'	=> sql_str( $$in{email} ),
							'email_subject'	=> sql_str( $$in{subject} ),
							'redirect_cancel'=> sql_str($$in{redircancel}),
							'redirect_confirm'=> sql_str($$in{redirconfirm}),
							'confirm_page'	=> sql_str( $$in{confirm} ),
							'frame'			=> sql_str( $$in{frame} ),
							'description'	=> sql_str( $$in{descr} ) ) );

		db_commit( $$k{dbh} );

		return( $k->_relocate( $r, $$k{rootp} ) );
	}
	else {
		$$in{active}	= 0			if ( ! defined $$in{active} );
		$$in{pcount}	= 1			if ( ! defined $$in{pcount} );
	
		if ( ! defined $$in{start} ) {
			$$in{start} = strftime( $$k{fmt_d}, localtime() );
		}

		if ( ! defined $$in{stop} ) {
			$$in{stop} = strftime( $$k{fmt_d}, localtime() );
		}

		return( ( $r->method eq 'POST' ? @err : '' ), $k->_form( $in ) );
	}
} # END $k->do_add

#-------------------------------------------------
# $k->do_dup( $r, $id )
#-------------------------------------------------
sub do_dup {
	my ( $k, $r, $id ) = @_;
	
	my $in 				= $k->param( Apache2::Request->new( $r ) );
	$$k{page_title} 	.= 'Edit Form';

	return( $k->_relocate( $r, $$k{rootp} ) ) if ( ! is_number( $id ) );
	return( $k->_relocate( $r, $$k{rootp} ) ) if ( $$in{cancel} );

	if ( ! ( my @err = $k->_checkvals( $in ) ) ) {

		## Save the form data to the database
		db_run( $$k{dbh}, 'Create a new form',
				sql_insert( 'form_data', 
							'active'		=> sql_bool( $$in{active} ),
							'send_email'	=> sql_bool( $$in{send_email} ),
							'page_count'	=> sql_num( $$in{pcount} ),
							'store_as'		=> sql_str( $$in{store} ),
							'filename'		=> sql_str( $$in{fname} ),
							'send_as'		=> sql_str( $$in{send} ),
							'created'		=> sql_str( 'now' ),
							'modified'		=> sql_str( 'now' ),
							'start_date'	=> sql_str( $$in{start} ),
							'stop_date'		=> sql_str( $$in{stop} ),
							'ident'			=> sql_str( $$in{ident} ),
							'name'			=> sql_str( $$in{name} ),
							'email_address'	=> sql_str( $$in{email} ),
							'email_subject'	=> sql_str( $$in{subject} ),
							'redirect_cancel'=> sql_str( $$in{redircancel} ),
							'redirect_confirm'=> sql_str( $$in{redirconfirm} ),
							'confirm_page'	=> sql_str( $$in{confirm} ),
							'frame'			=> sql_str( $$in{frame} ),
							'description'	=> sql_str( $$in{descr} ) ) );

		# FIXME: ZOMG ! Transaction, point moot.
		# Also, Can I not do this copy with 1 sql statement.

		## In order to avoid a race condition - we will avoid just
		## grabbing the next number in the sequence, there could be
		## a substantial number of elements to insert
		db_commit( $$k{dbh} );

		## get the new form's id
		my $rth = db_query( $$k{dbh}, 'Get the new form id',
							'SELECT id FROM form_data WHERE ident = ',
							sql_str( $$in{ident} ) );

		my $fid = db_next( $rth );

		db_finish( $rth );

		## retrieve the elements for the form
		my $qth = db_query( $$k{dbh}, 'Get the associated elements',
							'SELECT required, checked, readonly, multiple,',
							'form_types_id, form_validate_id, max_length, ',
							'tab_index, row_count, col_count, size_count, ',
							'page_number, question_number, name, value, ',
							'css_class, src, addition_params, alt, ',
							'pre_text, post_text, error_msg FROM ',
							'form_element WHERE form_data_id = ',
							sql_num( $id ) );

			## insert the elements
		while ( my ( $req, $check, $read, $mult, $type, $reqid, $max, $tab,
					$row, $col, $size, $page, $quest, $name, $value, $css, 
					$src, $param, $alt, $pre, $post, $error ) = 
					db_next( $qth ) ) {

			db_run( $$k{dbh}, 'Add elements',
					sql_insert( 'form_element',
								'required'			=> sql_bool( $req ),
								'checked'			=> sql_bool( $check ),
								'readonly'			=> sql_bool( $read ),
								'multiple'			=> sql_bool( $mult ),
								'form_data_id'		=> sql_num( $fid ),
								'form_types_id'		=> sql_num( $type ),
								'form_validate_id'	=> sql_num( $reqid ),
								'max_length'		=> sql_num( $max ),
								'tab_index'			=> sql_num( $tab ),
								'row_count'			=> sql_num( $row ),
								'col_count'			=> sql_num( $col ),
								'size_count'		=> sql_num( $size ),
								'page_number'		=> sql_num( $page ),
								'question_number'	=> sql_num( $quest ),
								'name'				=> sql_str( $name ),
								'value'				=> sql_str( $value ),
								'css_class'			=> sql_str( $css ),
								'src'				=> sql_str( $src ),
								'addition_params'	=> sql_str( $param ),
								'alt'				=> sql_str( $alt ),
								'pre_text'			=> sql_str( $pre ),
								'post_text'			=> sql_str( $post ),
								'error_msg'			=> sql_str( $error ) ) );
		}

		db_commit( $$k{dbh} );

		db_finish( $qth );
			
		return( $k->_relocate( $r, $$k{rootp} ) );
	}
	else {
		my $sth = db_query( $$k{dbh}, 'Get existing form',
							'SELECT id, name, active, page_count, ',
							'date_part( \'epoch\', start_date ), ',
							'date_part( \'epoch\', stop_date ), ',
							'email_address, email_subject, ',
							'redirect_cancel, redirect_confirm, frame, ',
							'description, ',
							'send_email, store_as, confirm_page, filename,',
							'send_as FROM form_data WHERE id = ', 
							sql_num( $id ) );

		if ( db_rowcount( $sth ) < 1 ) {
			return( 'Invalid ID.' );
		}
			
		my ( $id, $name, $active, $pcount, $start, $stop, $email,
			$subject, $cancel, $confirm, $frame, $descr, $send, $store,
			$pconfirm, $fname, $send_as ) = db_next( $sth );
	
		$$in{active}		= '0'		if ( ! defined $$in{active} );
		$$in{name}			= $name		if ( ! defined $$in{name} );
		$$in{pcount}		= $pcount	if ( ! defined $$in{pcount} );
		$$in{email}			= $email	if ( ! defined $$in{email} );
		$$in{subject}		= $subject	if ( ! defined $$in{subject} );
		$$in{frame}			= $frame	if ( ! defined $$in{frame} );
		$$in{descr}			= $descr	if ( ! defined $$in{descr} );
		$$in{ident}			= ''		if ( ! defined $$in{ident} );
		$$in{send_email}	= $send		if ( ! defined $$in{send_email} );
		$$in{store}			= $store	if ( ! defined $$in{store} );
		$$in{fname}			= $fname	if ( ! defined $$in{fname} );
		$$in{send}			= $send_as	if ( ! defined $$in{send} );
		$$in{redircancel}	= $cancel	if ( ! defined $$in{redircancel} );
		$$in{redirconfirm}	= $confirm 	if ( ! defined $$in{redirconfirm} );
		$$in{confirm}		= $pconfirm if ( ! defined $$in{confirm} );

		if ( ! defined $$in{start} ) {
			$$in{start} = strftime( "%Y-%m-%d", localtime( $start ) );
		}

		if ( ! defined $$in{stop} ) {
			$$in{stop} = strftime( "%Y-%m-%d", localtime( $stop ) );
		}

		return( ( $r->method eq 'POST' ? @err : '' ), $k->_form( $in ) );
	}
} # END $k->do_dup

#-------------------------------------------------
# $k->do_edit( $r, $id )
#-------------------------------------------------
sub do_edit {
	my ( $k, $r, $id ) = @_; 

	my $in 			= $k->param( Apache2::Request->new( $r ) );
	$$k{page_title}	.= 'Edit Form';
	$$in{form_id}	= $id;

	return( $k->_relocate( $r, $$k{rootp} ) ) if ( ! is_number( $id ) );
	return( $k->_relocate( $r, $$k{rootp} ) ) if ( $$in{cancel} );

	if ( ! ( my @err = $k->_checkvals( $in ) ) ) {

		$$in{email} =~ s/\s//g; # strip spaces 

		## Save the form data to the database
		db_run( $$k{dbh}, 'Create a new form',
				sql_update( 'form_data', 'WHERE id = '. sql_num( $id ),
							'active'		=> sql_bool( $$in{active} ),
							'send_email'	=> sql_bool( $$in{send_email} ),
							'page_count'	=> sql_num( $$in{pcount} ),
							'store_as'		=> sql_str( $$in{store} ),
							'filename'		=> sql_str( $$in{fname} ),
							'send_as'		=> sql_str( $$in{send} ),
							'modified'		=> sql_str( 'now' ),
							'start_date'	=> sql_str( $$in{start} ),
							'stop_date'		=> sql_str( $$in{stop} ),
							'ident'			=> sql_str( $$in{ident} ),
							'name'			=> sql_str( $$in{name} ),
							'email_address'	=> sql_str( $$in{email} ),
							'email_subject'	=> sql_str( $$in{subject} ),
							'redirect_cancel'=> sql_str( $$in{redircancel} ),
							'redirect_confirm'=> sql_str( $$in{redirconfirm} ),
							'confirm_page'	=> sql_str( $$in{confirm} ),
							'frame'			=> sql_str( $$in{frame} ),
							'description'	=> sql_str( $$in{descr} ) ) );

		db_commit( $$k{dbh} );

		return( $k->_relocate( $r, $$k{rootp} ) );
	}
	else {
		my $sth = db_query( $$k{'dbh'}, 'Get existing form',
								'SELECT id, name, active, page_count, ',
								'date_part( \'epoch\', modified ), ',
								'date_part( \'epoch\', start_date ), ',
								'date_part( \'epoch\', stop_date ), ',
								'email_address, email_subject, ',
								'redirect_cancel, redirect_confirm, frame, ',
								'description, ident, ',
								'send_email, store_as, confirm_page, ',
								'filename, send_as FROM form_data ',
								'WHERE id = ', sql_num( $id ) );

		my ( $id, $name, $active, $pcount, $mod, $start, $stop, $email,
			$subject, $cancel, $confirm, $frame, $descr, $ident,
			$send, $store, $pconfirm, $fname, $send_as ) = db_next( $sth );
			
		$$in{modified}		= $mod;
		$$in{active}		= $active	if ( ! defined $$in{active} );
		$$in{name}			= $name		if ( ! defined $$in{name} );
		$$in{pcount}		= $pcount	if ( ! defined $$in{pcount} );
		$$in{email}			= $email	if ( ! defined $$in{email} );
		$$in{subject}		= $subject	if ( ! defined $$in{subject} );
		$$in{frame}			= $frame	if ( ! defined $$in{frame} );
		$$in{descr}			= $descr	if ( ! defined $$in{descr} );
		$$in{ident}			= $ident	if ( ! defined $$in{ident} );
		$$in{send_email}	= $send		if ( ! defined $$in{send_email} );
		$$in{store}			= $store	if ( ! defined $$in{store} );
		$$in{fname}			= $fname	if ( ! defined $$in{fname} );
		$$in{send}			= $send_as	if ( ! defined $$in{send} );
		$$in{redircancel}	= $cancel	if ( ! defined $$in{redircancel} );
		$$in{redirconfirm}	= $confirm 	if ( ! defined $$in{redirconfirm} );
		$$in{confirm}		= $pconfirm	if ( ! defined $$in{confirm} );

		if ( ! defined $$in{start} ) {
			$$in{start} = strftime( "%Y-%m-%d", localtime( $start ) );
		}

		if ( ! defined $$in{stop} ) {
			$$in{stop} = strftime( "%Y-%m-%d", localtime( $stop ) );
		}
			
		return( ( $r->method eq 'POST' ? @err : '' ), $k->_form( $in ) );
	}
} # END $k->do_edit

#-------------------------------------------------
# $k->do_delete( $r, $id, $yes )
#-------------------------------------------------
sub do_delete {
	my ( $k, $r, $id, $yes ) = @_;

	my $in 			= $k->param( Apache2::Request->new( $r ) );
	$$k{page_title}	.= 'Delete Form';

	return( 'Invalid ID.' ) 					if ( ! is_integer( $id ) );
	return( $k->_relocate( $r, $$k{rootp} ) ) 	if ( $$in{cancel} );

	if ( defined $yes && $yes eq 'yes' ) {
		
		## delete the form and its children
		db_run( $$k{dbh}, 'Delete a forms children',
				'DELETE FROM form_element WHERE form_data_id = ',
				sql_num( $id ) );

		db_run( $$k{dbh}, 'Delete a form',
				'DELETE FROM form_data WHERE id = ', sql_num( $id ) );

		db_commit( $$k{dbh} );

		return( $k->_relocate( $r, $$k{rootp} ) );
	}
	else {
		my $sth = db_query( $$k{dbh}, 'Get the forms info',
							'SELECT name FROM form_data WHERE id = ',
							sql_num( $id ) );

		my $name = db_next( $sth );

		db_finish( $sth );

		return(	ht_form_js( "$$k{'uri'}/yes" ),
				ht_table(),

				ht_tr(),
				ht_td( { 'class' => 'dta' },
						'Delete the form ', ht_b( $name ),
						'? This will completely remove this form and all of ',
						'its elements.' ),
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

	$$k{'page_title'} .= 'Listing of Forms';

	my @lines = (	ht_table(),

					ht_tr(),
					ht_td( { 'class' => 'hdr' }, 'Name' ),
					ht_td( { 'class' => 'hdr' }, 'E-Mail' ),
					ht_td( { 'class' => 'hdr' }, 'Start Date' ),
					ht_td( { 'class' => 'hdr' }, 'Stop Date' ),
					ht_td( { 'class' => 'hdr' }, 'Status' ),
					ht_td( { 'class' => 'rhdr' }, '[',
							ht_a( "$$k{rootp}/add", 'Add' ), ']' ),
					ht_utr() );

	my $sth = db_query( $$k{dbh}, 'Get the list of forms',
						'SELECT id, ident, name, email_address, ',
						'date_part( \'epoch\', start_date ), ',
						'date_part( \'epoch\', stop_date ), active ',
						'FROM form_data ORDER BY active, start_date, name' );

	while ( my( $id, $ident, $name, $email, $start, $stop, 
				$active ) = db_next( $sth ) ) {

		my $cur = time;

		if ( $active && $cur >= $start && $cur <= $stop ) {
			$name = ht_a( "$$k{viewrootp}/view/$ident", $name );
		}

		$email =~ s/,/,\ /g;

		push( @lines,	ht_tr(),
						ht_td( {}, $name ),
						ht_td( {}, ht_a( "mailto:$email", $email ) ),
						ht_td( {}, strftime($$k{fmt_d}, localtime($start)) ),
						ht_td( {}, strftime($$k{fmt_d}, localtime($stop)) ),
						ht_td( {}, ( $active ? 'Active' : 'Disabled' ) ),
						ht_td( { 'class' => 'rdta' }, '[',
								ht_a("$$k{elemrootp}/main/$id", 'Details'),'|' ,
								ht_a( "$$k{rootp}/dup/$id", 'Copy' ), ']' ),
						ht_utr() );
	}

	if ( ! db_rowcount( $sth ) ) {
		push( @lines, 	ht_tr(),
						ht_td( { 'class' => 'cdta', 'colspan' => '6' },
								'There are no forms to display' ),
						ht_utr() );
	}

	db_finish( $sth );

	return( @lines, ht_utable() );
} # END $k->do_main

# EOF
1;

__END__

=head1 NAME 

Alchemy::FormBuilder::Form - FormBuilder Forms

=head1 SYNOPSIS

 use Alchemy::FormBuilder::Form;

=head1 DESCRIPTION

This module provides the inteface for list, edit, create and 
delete with respect to the forms listed in the database.

=head1 APACHE

This is a sample of the location required for this module to run.
Consult Alchemy::FormBuilder(3) to learn about the global configuration
options.

  <Location /admin/forms >
    SetHandler perl-script

	PerlSetVar  SiteTitle    "FormBuilder - "
	PerlSetVar  Frame        "template;FormBuilder.tp"

    PerlHandler Alchemy::FormBuilder::Form
  </Location>

=head1 DATABASE

This is the core table that this module manipulates:

  create table "form_data" (
    "id" integer primary key not null default nextval( 'form_data_sequence' ),
    "active" boolean,
    "send_email" boolean,
    "page_count" integer,
    "number_of_elements" integer default '0',
    "created" timestamp with time zone,
    "modified" timestamp with time zone,
    "start_date" timestamp with time zone,
    "stop_date" timestamp with time zone,
    "ident" varchar not null, -- name of form and uri 
    "name" varchar, -- display name of form (pretty)
    "email_address" varchar not null, -- to send results to
    "email_subject" varchar,
    "redirect_cancel" varchar not null, -- for cancel and conclusion
    "redirect_confirm" varchar,
    "frame" varchar,
    "store_as" varchar,
    "send_as" varchar,
    "filename" varchar,
    "description" text,
    "text" text,
  );

=head1 FUNCTIONS

This module provides the following functions:

  $k->do_cal( $r, $name, $year, $month )
    Creates a javascript calendar in a popup window - posts back to the 
	form in the cell with the name given

  $k->do_add( $r )
    Adds a new form to the database

  $k->do_dup( $r, $id )
    Adds a new form to the database, duplicating the form with the id 
	provided

  $k->do_edit( $r, $id )
    Edit an existing form of the provided id

  $k->do_delete( $r, $id, $yes )
    Delete an existing form with id - requires confirmation of delete

  $k->do_main( $r )
    Provides a listing of all available forms in the database - for 
	editing, deleting, adding, and form details (elements) 

=head1 SEE ALSO

Alchemy::FormBuilder(3), KrKit(3), perl(3)

=head1 LIMITATIONS

?

=head1 AUTHOR

Ron Andrews <ron.andrews@cognilogic.net>

=head1 COPYRIGHT AND LICENSE

Copyright (C) 2004 by Ron Andrews. All rights reserved.

You may distribute under the terms of either the GNU General Public
License or the Artistic License, as specified in the Perl README file.

=cut
