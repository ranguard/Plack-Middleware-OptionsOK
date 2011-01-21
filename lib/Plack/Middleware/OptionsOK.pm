package Plack::Middleware::OptionsOK;

use strict;
use warnings;

use parent qw( Plack::Middleware );

our $VERSION = 0.01;

sub call {
    my ( $self, $env ) = @_;

    if ( $env->{REQUEST_METHOD} eq 'OPTIONS'
        && ( $env->{REQUEST_URI} eq '*' || $env->{REQUEST_URI} eq '/*' ) )
    {

        # We match /* because of the tests
        return [ 200, [], [] ];
    }

    # Not an OPTIONS * request, carry on...
    return $self->app->($env);

}

1;

__END__

=head1 NAME

  Plack::Middleware::OptionsOK

=head1 SYNOPSIS

  # in app.psgi
  use Plack::Builder;

  my $app = sub { ... } # as usual

  builder {
      enable "Plack::Middleware::OptionsOK";
      $app;
  };

=head1 DESCRIPTION

Many reverse Proxy servers (such as L<Perlbal>) use an
'OPTIONS *' request to confirm if a server is running.

This middleware will respond with a '200' to this
request so you do not have to handle it in your
app. There will be no further processing after this

=head1 SEE ALSO

L<Plack> L<Plack::Builder> L<Perlbal>

=cut

