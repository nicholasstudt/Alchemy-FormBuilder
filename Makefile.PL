use ExtUtils::MakeMaker;
# See lib/ExtUtils/MakeMaker.pm for details of how to influence
# the contents of the Makefile that is written.
WriteMakefile(
    'NAME'              => 'Alchemy::FormBuilder',
    'VERSION_FROM'      => 'lib/Alchemy/FormBuilder.pm', # finds $VERSION
    'PREREQ_PM'         => {
								'KrKit'					=> '0',
								'POSIX'					=> '0',
								'Text::Wrap'			=> '0',
								'Net::SMTP'				=> '0',
								'MIME::Lite'			=> '3.01',
								'Apache2::Request'		=> '0',
								'File::Copy'			=> '0',
								'Date::Calc'			=> '0',
								'File::Path'			=> '0',
							},
);
