use v5.20;

package Module::Release::VerifyGPGSignature;
use strict;
use experimental qw(signatures);

use warnings;
no warnings;
use Exporter qw(import);

our @EXPORT = qw(check_all_gpg_signatures check_gpg_signature);

our $VERSION = '0.004';

=encoding utf8

=head1 NAME

Module::Release::VerifyGPGSignature - Verify GPG signatures in the distro

=head1 SYNOPSIS

	use Module::Release::VerifyGPGSignature;

=head1 DESCRIPTION

This requires several things.

First, you must have F<gpgv> installed in F</usr/local/bin>. If there
are other common, trusted, locations, I can add those. I developed
this using gpg2. If you need to upgrade from gpg1, be careful with
everything else you might disturb with gpg2's differences.

Second, you must have your public key that was used to sign the file
in the default keyring for F<gpgv>. This is not the same default
keyring for F<gpg>. It's likely F<~/.gnupg/trustedkeys.kbx>. You can
export your public key from your normal keyring into the new one:

	% gpg --export KEY_DIGEST |
		gpg --no-default-keyring --keyring ~/.gnupg/trustedkeys.kbx --import

Then, list the file pairs to check in F<.releaserc>:

    gpg_signatures \
    	file.txt file.txt.gpg \
    	file2.txt file2.txt.gpg


=over 4

=cut

sub _get_file_pairs ( $self ) {
	state $rc = require Getopt::Long;
	my $key = _key($self);
	my $string = $self->config->$key();

	my( $ret, $args ) = Getopt::Long::GetOptionsFromString($string);

	$self->_print( "Odd number of arguments in $key." ) if @$args % 2;

	my @pairs;
	while( @$args > 1 ) {
		push @pairs, [ splice @$args, 0, 2, () ];
		}
	push @pairs, [ @$args ] if @$args;

	\@pairs
	}

sub _key ( $self ) { 'gpg_signatures' }

=item * check_all_gpg_signatures

Go through all files and signature files listed in the C<gpg_signatures>
and verify that the signatures match.

=cut

sub check_all_gpg_signatures ( $self ) {
	my $pairs = $self->_get_file_pairs;
	foreach my $pair ( $pairs->@* ) {
		$self->check_gpg_signature( $pair->@* )
		}
	return 1;
	}

=item * check_gpg_signature( FILE, SIGNATURE_FILE )

Checks the PGP signature in SIGNATURE_FILE matches for FILE.

=cut

sub check_gpg_signature ( $self, $file, $signature_file ) {
	state $gpgv_bin = '/usr/local/bin/gpgv';
	state $bin_paths = qw(/usr/local/bin);

	$self->_debug( "Looking for $gpgv_bin in (@$bin_paths)" );
	my @paths = grep { -x -e } map { catfile $_, $gpgv_bin } $bin_paths->@*;

	{
	my $message = @paths ?
		"Found gpgv in (@paths)"
			:
		"Did not find gpgv in one of (@$bin_paths)";
	$self->_debug( $message );
	}

	$self->_print( "Checking GPG signature of <$file>...\n" );

	$self->_die( "\nERROR: Could not find an executable gpgv in one of (@$bin_paths)\n" )
		unless @paths;

	$self->_die( "\nERROR: Could not verify signature of <$file>: file does not exist\n" )
		unless -e $file;

	$self->_die( "\nERROR: Could not verify signature of <$file> with <$signature_file>: signature file does not exist\n" )
		unless -e $signature_file;

	my $rc = system $paths[0], $signature_file, $file;
	my $result = $rc == 0 ? 'Good signature' : 'Bad signature';
	$self->_debug( "Exit code of <$rc> for <$paths[0] $signature_file $file>" );
	$self->_print( $result );

	return $rc == 0;
	}

=back

=head1 TO DO


=head1 SEE ALSO

=over 4

=item * L<gpgv documentation|https://www.gnupg.org/documentation/manuals/gnupg/gpgv.html>

=item * L<Stateless OpenPGP CLI standard|https://www.openpgp.org/about/sop/>

=back

=head1 SOURCE AVAILABILITY

This source is in Github:

	http://github.com/briandfoy/module-release-verifygpgsignature

=head1 AUTHOR

brian d foy, C<< <briandfoy@pobox.com> >>

=head1 COPYRIGHT AND LICENSE

Copyright © 2022-2026, brian d foy, All Rights Reserved.

You may redistribute this under the terms of the Artistic License 2.0.

=cut

1;
