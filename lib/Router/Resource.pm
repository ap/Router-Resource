package Router::Resource;

use strict;
use 5.8.1;
use parent 'Router::Simple';
use Sub::Exporter -setup => {
    exports => [ qw(resource GET POST PUT DELETE HEAD OPTIONS), router => \&_router ],
    groups  => { default => [ qw(resource router GET POST PUT DELETE HEAD OPTIONS) ] }
};

our $VERSION = '0.10';

sub _router {
    sub {
        my $class = shift;
        no strict 'refs';
        no warnings 'once';
        ${"$class\::ROUTER"} ||= __PACKAGE__->new;
    };
}

our (%METHS);

sub resource ($&) {
    my $caller = caller;
    my ($path, $code) = @_;
    local %METHS = ();
    $code->();

    # Let HEAD use GET if not specified.
    $METHS{HEAD} ||= $METHS{GET};

    while (my ($meth, $code) = each %METHS) {
        $caller->router->connect($path, {code => $code}, {method => $meth });
    }
}

sub GET(&)     { $METHS{GET}     = shift };
sub HEAD(&)    { $METHS{HEAD}    = shift };
sub POST(&)    { $METHS{POST}    = shift };
sub PUT(&)     { $METHS{PUT}     = shift };
sub DELETE(&)  { $METHS{DELETE}  = shift };
sub OPTIONS(&) { $METHS{OPTIONS} = shift };

sub match {
    (shift->routematch(@_))[0]
}

sub routematch {
    my ($self, $req) = @_;
    my ($match, $route) = $self->SUPER::routematch($req);
    return unless $match;
    my $code = delete $match->{code};
    sub { $code->( $req, $match ) }, $route;
}

1;
__END__

=head1 Name

Router::Resource - REST-inspired routers on Router::Simple

=head1 Synopsis

First, define your routes in a module:

  package My::Router;
  use Router::Resource;
  use My::Controller;

  resource '/' => sub {
      GET  { My::Controller->root(@_) };
  };

  resource '/blog/{year}/{month}' => sub {
      GET    { My::Controller->show_post(@_)   };
      POST   { My::Controller->create_post(@_) };
      PUT    { My::Controller->update_post(@_) };
      DELETE { My::Controller->delete_post(@_) };
  };

Then use those routes in a Plack app:

  package My::App;
  use My::Router;
  use Plack::Builder;

  sub app {
      my $router = My::Router->router;
      builder {
          sub {
              my $env = shift;
              if (my $method = $class->router->match($env)) {
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
which C<Router::Resource> subclasses. Check out its useful L<routing
rules|Router::Simple/HOW TO WRITE A ROUTING RULE> for flexible declaration of
resource paths.

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

The value returned by C<match()> (and the first value returned by
C<matchroute()>) on a successful match is a code reference. To execute the
method, just execute the code reference:

  if (my $method = $class->router->match($env)) {
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

L<Router::Simple::Sinatraish> was an inspiration for this module I even stole
some of its code.

=item *

L<Plack> is B<the> way to write your Perl web apps. Router::Resource is built
on top of L<Router::Simple>, which is fully Plack-aware.

=item *

L<Router::Resource|http://wtf> - The Ruby module whose interface inspired this
module's interface.

=back

=head1 Support

This module is stored in an open L<GitHub
repository|http://github.com/theory/router-resource/tree/>. Feel free to fork and
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
