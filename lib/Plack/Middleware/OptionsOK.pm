package Plack::Middleware::OptionsOK;

use strict;
use warnings;

use parent qw( Plack::Middleware );
use Plack::Util::Accessor
    qw(path cors allow_methods origin timeout credentials custom_headers default_headers);

our $VERSION = 0.01;

sub prepare_app {
    my ($self) = @_;
    $self->origin('*')    unless defined $self->origin;
    $self->path('/')      unless defined $self->path;
    $self->timeout(30)    unless defined $self->timeout;
    $self->credentials(1) unless defined $self->credentials;
    $self->allow_methods(
        [   qw(PROPFIND PROPPATCH COPY MOVE DELETE MKCOL LOCK UNLOCK
                PUT GETLIB VERSION-CONTROL CHECKIN CHECKOUT UNCHECKOUT REPORT
                UPDATE CANCELUPLOAD HEAD OPTIONS GET POST)
        ]
    ) unless defined $self->allow_methods;
    $self->custom_headers( [] ) unless defined $self->custom_headers;
    $self->default_headers(
        [   qw(Content-Type Depth User-Agent X-File-Size
                X-Requested-With If-Modified-Since X-File-Name Cache-Control)
        ]
    ) unless defined $self->default_headers;
}

sub call {
    my ( $self, $env ) = @_;

    my $res = $self->_handle_options($env);

    return $res if $res;

    # otherwise carry on as normal
    $self->app->($env);

}

sub _handle_options {
    my ( $self, $env ) = @_;

    # We only deal with 'OPTIONS'
    return unless $env->{REQUEST_METHOD} eq 'OPTIONS';

    # We only care about matching paths
    my $path_match = $self->path or return;
    return unless $env->{PATH_INFO} =~ /$path_match/;

    my $headers = [];

    if ( $self->cors() ) {

        # Preflight request: add in all the specified options.
        push(
            @$headers,
            'Access-Control-Allow-Methods' =>
                join( ', ', @{ $self->allow_methods } ),
            'Access-Control-Max-Age' => $self->timeout
        );
        push(
            @$headers,
            'Access-Control-Allow-Headers' => join( ', ',
                @{ $self->custom_headers },
                @{ $self->default_headers } )
        );

        push( @$headers, 'Content-Type' => 'text/plain' );
        return [ 200, $headers, [''] ];
    }

    if ( $env->{REQUEST_URI} eq '*' || $env->{REQUEST_URI} eq '/*' ) {

        # We match /* because of the tests
        return [ 200, [ 'Allow' => $self->allow_methods ], [] ];
    }

    my $r = $self->app->($env);

    if ( $self->cors() ) {

        # IF cors_active then always want these headers set
        # cross-origin resource sharing http://www.w3.org/TR/cors/

        my $origin = $self->origin;

        # This is mostly written in accordance with:
        # https://developer.mozilla.org/en/HTTP_access_control
        $origin = $env->{HTTP_ORIGIN}
            if ( $origin eq '*'
            && $self->credentials
            && defined $env->{HTTP_ORIGIN} );

        # What happens if we have several origins (proxy servers?)
        $headers = [ 'Access-Control-Allow-Origin' => $origin ];

        push( @$headers, 'Access-Control-Allow-Credentials' => 'true' )
            if $self->credentials();

        $self->response_cb(
            $r,
            sub {
                my $r = shift;
                push( @{ $r->[1] }, @$headers );
            }
        );

    }

    return $r;
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
      enable "Plack::Middleware::OptionsOK",
      $app;
  };

=head1 DESCRIPTION


Many reverse Proxy servers (such as L<Perlbal>) use an
'OPTIONS *' request to confirm if a server is running.

This middleware will respond with a '200' to this
request so you do not have to handle it in your
app. There will be no further processing after this

=head1 OPTIONS

=head2 allow
	
   allow_methods => 'GET POST PUT DELETE OPTIONS'

The the Allow header can be altered, it defaults to the list above

=head1 AUTHOR

Leo Lapworth, LLAP@cuckoo.org

=head1 Repository (git)

https://github.com/ranguard/Plack-Middleware-OptionsOK, git://github.com/ranguard/Plack-Middleware-OptionsOK.git

=head1 COPYRIGHT

Copyright (c) 2011 Leo Lapworth. All rights reserved.
This program is free software; you can redistribute
it and/or modify it under the same terms as Perl itself.

=head1 SEE ALSO

L<Plack> L<Plack::Builder> L<Perlbal>

=cut

