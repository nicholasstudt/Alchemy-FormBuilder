package Alchemy::FormBuilder;

use strict;

use KrKit::Handler;

our $VERSION = '0.65';
our @ISA = ( 'KrKit::Handler' );

##-----------------------------------------------------------------##
## Functions                                                       ##
##-----------------------------------------------------------------##

##-------------------------------------
## $self->_init( $r )
##-------------------------------------
sub _init {
	my ( $k, $r ) = @_;
	
	$k->SUPER::_init( $r ); 
	
	$$k{'doc_root'}		= $r->document_root();
	$$k{'user'}			= $r->user();

	# Page Specific Variables
	$$k{'elemrootp'}	= $r->dir_config( 'ElementRoot' );
	$$k{'formrootp'}	= $r->dir_config( 'FormRoot' );
	$$k{'viewrootp'}	= $r->dir_config( 'ViewRoot' );

	$$k{'cal_frame'}	= $r->dir_config( 'Cal_Frame' ) || 'plain';
	$$k{'cal_title'}	= $r->dir_config( 'CalTitle' ) || '';
	
	$$k{'template_dir'}	= $r->dir_config( 'TemplateDir' );

	$$k{'form_from'}	= $r->dir_config( 'FB_From' );

	return();
} # END $self->_init

# EOF
1;

__END__

=head1 NAME

Alchemy::FormBuilder - A Web-based Form Management application

=head1 SYNOPSIS

  use Alchemy::FormBuilder

=head1 DESCRIPTION

This module provides a web-based admin utility to create, edit, and delete
Forms with/without validation. It also provides the end-user form - Viewer.
This particular module preloads or initializes the system for both the 
Viewer and the Admin modules.

=head1 MODULES

=over 2

=item Alchemy::FormBuilder::Form

This module provides the management of a form (Admin)

=item Alchemy::FormBuilder::Form::Element

This module provides the management of form elements (Admin)

=item Alchemy::FormBuilder::Form::Element::Defaults

This module provides the management of form default elements (Admin)

=item Alchemy::FormBuilder::Form::Element::Types

This module provides the management of form element types (Admin)
Note: in order for changes via this interface to work, the modifications need
also to be made in the code base - this interface only allows access to the 
database elements for ease of administration.

=item Alchemy::FormBuilder::Form::Element::Validation

This module provides the management of form element validation (Admin)
Note: in order for changes via this interface to work (except regex), the
modifications need also to be made in the code base - this interface allows
access to the database elements for ease of administration and the addition
of regex validation to the system.

=item Alchemy::FormBuilder::Viewer

This is the viewer for the forms, it allows end-users to interact with
a constructed form. Once the form is complete, the submission is emailed
to the address specified in the form's properties. If the output is designated
to be stored, it is done following the email submission. (Viewer)

=back

=head1 APACHE

This is a sample of the global configuration options needed by both the
Viewer and Admin interfaces. See the accompanying FormBuilder.conf
available in the distribution for an example apache conf.


<Location / >
  PerlSetVar  DatabaseType        Pg
  PerlSetVar  DatabaseName        turtle
  PerlSetVar  DatabaseUser        apache
  PerlSetVar  DatabaseCommit      off

  PerlSetVar  XpanderDB           "/var/www/xpander.db"

  PerlSetVar  HelpRoot            "/help"

  PerlSetVar  File_PostMax        "5242880"
  PerlSetVar  File_Temp           "/tmp"
  PerlSetVar  File_Path           "/var/www/html/tmp"
  PerlSetVar  File_URI            "/tmp"

  PerlSetVar  DateTime_Format     "%Y-%m-%dT%H:%M:%S"
  PerlSetVar  Time_Format         "%H:%M:%S"
  PerlSetVar  Date_Format         "%Y-%m-%d"

  PerlSetVar  Frame               "template;FormBuilder.tp"
  PerlSetVar  SiteTitle           "Turtle - "
  PerlSetVar  SMTP_Host           "127.0.0.1"

  PerlSetVar  ElementRoot         "/admin/forms/element"
  PerlSetVar  FormRoot            "/admin/forms"
  PerlSetVar  ViewRoot            "/form"

  PerlSetVar  Cal_Frame           "plain"
  PerlSetVar  CalTitle            "Set Date"
  PerlSetVar  FB_From             "turtle@cognilogic.net"
  PerlSetVar  TemplateDir         "/var/www/html/templates"
</Location>

## Note: for the Help System to be active - it must be set up via KrKit
## See perldoc KrKit::Helper for more information

## Further Note: to properly set up the templating system, see perldoc
## KrKit::Framing for more information

=head1 DATABASE

The following is list of all of the tables required by this module. See the
accompanying FormBuilder.postgresql.sql available in the distribution sql for
the details of the sql needed for this module.

  form_data
  form_element
  form_types
  form_validate
  help_categories
  help_items

=head1 METHODS

=item $self->_init( $r )

  Called by the core handler to initialize each page request

=head1 SEE ALSO

Alchemy::FormBuilder::Form(3), Alchemy::FormBuilder::Form::Element(3),
Alchemy::FormBuilder::Form::Element::Defaults(3), 
Alchemy::FormBuilder::Form::Element::Types(3),
Alchemy::FormBuilder::Form::Element::Validation(3), 
Alchemy::FormBuilder::Viewer(3), 
Alchemy::FormBuilder::Viewer::Output(3),
KrKit(3), perl(3)

=head1 LIMITATIONS

=head1 AUTHOR

Ron Andrews <ron.andrews@cognilogic.net>

=head1 COPYRIGHT AND LICENSE

Copyright (C) 2004 by Ron Andrews. All rights reserved.

You may distribute under the terms of either the GNU General Public
License or the Artistic License, as specified in the Perl README file.

=cut
