package Router::Resource;

use strict;
use 5.8.1;
use Router::Simple::Route;
use Sub::Exporter -setup => {
    exports => [ qw(router resource GET POST PUT DELETE HEAD OPTIONS)],
    groups  => { default => [ qw(resource router GET POST PUT DELETE HEAD OPTIONS) ] }
};

our $VERSION = '0.10';

sub new { bless { routes => [] } };

our (%METHS, $ROUTER);

sub router(&) {
    local $ROUTER = __PACKAGE__->new;
    shift->();
    return $ROUTER;
}

sub resource ($&) {
    my ($path, $code) = @_;
    local %METHS = ();
    $code->();

    # Let HEAD use GET if not specified.
    $METHS{HEAD} ||= $METHS{GET};

    # Add the route.
    push @{ $ROUTER->{routes} }, Router::Simple::Route->new($path, {});
    $ROUTER->{routes}[-1]->{meths} = { %METHS }; # HACK!
}

sub GET(&)     { $METHS{GET}     = shift };
sub HEAD(&)    { $METHS{HEAD}    = shift };
sub POST(&)    { $METHS{POST}    = shift };
sub PUT(&)     { $METHS{PUT}     = shift };
sub DELETE(&)  { $METHS{DELETE}  = shift };
sub OPTIONS(&) { $METHS{OPTIONS} = shift };

sub match {
    my ($self, $env) = @_;

    my $meth = uc($env->{REQUEST_METHOD} || '') or return;

    for my $route (@{ $self->{routes} }) {
        my $match = $route->match($env) or next;
        my $code = $route->{meths}{$meth} or next;
        return sub { $code->( $env, $match ) };
    }
    return undef;
}

1;
__END__

=head1 Name

Router::Resource - Build REST-inspired routing tables

=head1 Synopsis

  use Router::Resource;
  use My::Controller;
  use Plack::Builder;
  use namespace::autoclean;

  my $router = router {
      resource '/' => sub {
          GET  { My::Controller->root(@_) };
      };

      resource '/blog/{year}/{month}' => sub {
          GET    { My::Controller->show_post(@_)   };
          POST   { My::Controller->create_post(@_) };
          PUT    { My::Controller->update_post(@_) };
          DELETE { My::Controller->delete_post(@_) };
      };
  };

  sub app {
      builder {
          sub {
              my $env = shift;
              if (my $method = $router->match($env)) {
                  return $method->();
              } else {
                  return [404, [], ['not found']];
              }
          };
      };
  }

=head1 Description

There are a bunch of path routers on CPAN, but they tend not to be very RESTy.
A basic idea of a RESTful API is that URIs point to resources and the standard
HTTP methods indicate the actions to be taken on those resources. So to
encourage you to think about it that way, Router::Resource requires that you
declare resources and then the HTTP methods that are implemented for those
resources.

The paths are subject to the variable treatments offered by L<Router::Simple>,
which is used internally by C<Router::Resource> do do the actual work of
matching routes. Check out its useful L<routing rules|Router::Simple/HOW TO
WRITE A ROUTING RULE> for flexible declaration of resource paths.

=head2 Resource Methods

The HTTP methods supported for a resource are defined by the following HTTP
methods:

=over

=item C<GET>

=item C<HEAD>

=item C<POST>

=item C<PUT>

=item C<DELETE>

=item C<OPTIONS>

=back

When you define these methods, they should expect to take two arguments: the
matched request (a Plack C<$env> hash or simply a URI path) and a hash of the
matched data as created by Router::Simple. For example, in a L<Plack>-powered
Wiki app you might do something like this:

  resource '/wiki/:name' => sub {
      GET {
          my $req = Plack::Request->new(shift);
          my $params = shift;
          my $wiki = Wiki->lookup( $parmas->{name} );
          return [200, [], [$wiki]];

      };
  };

=head2 Matches

The value returned by C<match()> on a successful match is a code reference. To
execute the method, just execute the code reference:

  if (my $method = $router->match($env)) {
      return $method->();
  } else {
      return [404, [], ['not found']];
  }

Simple, right? But note that this value is different than that returned by
L<Router::Simple>'s C<match()> method. That hash is the value passed as the
second argument to the method.

=head1 See Also

=over

=item *

L<Router::Simple> is the foundation on which this module is built. See its
documentation for the cool path syntax.

=item *

L<Router::Simple::Sinatraish> was an inspiration for this module. It's nice,
though perhaps a bit too magical.

=item *

L<Plack> is B<the> way to write your Perl web apps. Router::Resource is built
on top of L<Router::Simple>, which is fully Plack-aware.

=item *

L<Router::Resource|http://wtf> - The Ruby module whose interface inspired this
module's interface.

=back

=head1 Support

This module is stored in an open L<GitHub
repository|http://github.com/theory/router-resource/>. Feel free to fork and
contribute!

Please file bug reports via L<GitHub
Issues|http://github.com/theory/router-resource/issues/> or by sending mail to
L<bug-Router-Resource@rt.cpan.org|mailto:bug-Router-Resource@rt.cpan.org>.

=head1 Author

David E. Wheeler <david@kineticode.com>

=head1 Copyright and License

Copyright (c) 2010 David E. Wheeler. Some Rights Reserved.

This module is free software; you can redistribute it and/or modify it under
the same terms as Perl itself.

=cut
