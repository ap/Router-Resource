#!/usr/bin/env perl -w

package My::Router;

use strict;
use warnings;
use Router::Resource;
use Test::More;

my $reqmeth = 'GET';

resource '/' => sub {
    GET {
        is_deeply shift, { REQUEST_METHOD => $reqmeth, PATH_INFO => '/' },
            'Method first arg should be request env';
        is_deeply shift, {},
            'Method second arg should be the route hash';
        return 'get /'
    };
    PUT { 'put /' };
};

resource '/wiki/:page' => sub {
    GET {
        is_deeply shift, { REQUEST_METHOD => 'GET', PATH_INFO => '/wiki/Theory' },
            'Method first arg should be request env';
        is_deeply shift, { page => 'Theory' },
            'Method second arg should be the route hash';
        return 'get /wiki/:page'
    };

    POST {
        is_deeply shift, { REQUEST_METHOD => 'POST', PATH_INFO => '/wiki/Theory' },
            'Method first arg should be request env';
        is_deeply shift, { page => 'Theory' },
            'Method second arg should be the route hash';
        return 'post /wiki/:page'
    };

};

resource '/foo' => sub {
    GET     { 'get /foo'     };
    HEAD    { 'head /foo'    };
    POST    { 'post /foo'    };
    PUT     { 'put /foo'     };
    DELETE  { 'remove /foo'  };
    OPTIONS { 'options /foo' };
    GET     { 'get /foo'     };
};

package main;
use Test::More tests => 46;

can_ok 'Router::Resource', qw(resource GET HEAD POST PUT DELETE OPTIONS match routematch);
can_ok 'My::Router', qw(router);

ok my $router = My::Router->router, 'Get my router';
isa_ok $router, 'Router::Resource', 'it';
isa_ok $router, 'Router::Simple', 'it';

ok my $meth = $router->match({
    REQUEST_METHOD => "GET",
    PATH_INFO => "/",
}), 'Should match GET /';

isa_ok $meth, 'CODE', 'Route should be a code ref';
is $meth->(), 'get /', 'And it should be the correct code ref';

ok $meth = $router->match({
    REQUEST_METHOD => "GET",
    PATH_INFO => "/",
}), 'Should match GET / again';

isa_ok $meth, 'CODE', 'Route should again be a code ref';
is $meth->(), 'get /', 'And it should still be the correct code ref';

$reqmeth = 'HEAD';
ok $meth = $router->match({
    REQUEST_METHOD => "HEAD",
    PATH_INFO => "/",
}), 'Should match HEAD /';

isa_ok $meth, 'CODE', 'Route should be a code ref';
is $meth->(), 'get /', 'And it should be the correct code ref';

# Try a non-match.
is $router->match('/foo'), undef, 'Not found request should not match';

# Now try with Router::Simple stuff.
ok $meth = $router->match({
    REQUEST_METHOD => "GET",
    PATH_INFO => "/wiki/Theory",
}), 'Should match GET /wiki/Theory';

isa_ok $meth, 'CODE', 'Route should be a code ref';
is $meth->(), 'get /wiki/:page', 'And it should be the correct code ref';

# Try a POST method.
ok $meth = $router->match({
    REQUEST_METHOD => "POST",
    PATH_INFO => "/wiki/Theory",
}), 'Should match POST /wiki/Theory';

isa_ok $meth, 'CODE', 'Route should be a code ref';
is $meth->(), 'post /wiki/:page', 'And it should be the correct code ref';

# Try a POST method.
is $router->match({
    REQUEST_METHOD => "PUT",
    PATH_INFO => "/wiki/Theory",
}), undef, 'Should not match PUT /wiki/Theory';

# Make sure that all the methods work.
for my $meth (qw(get head post put remove options get)) {
    ok my $match = $router->match({
        REQUEST_METHOD => $meth eq 'remove' ? 'DELETE' : uc $meth,
        PATH_INFO => '/foo'
    }), "Send request for $meth /foo";
    is $match->(), "$meth /foo", 'And it should return the expected value';
}

use Class::MOP;
my $meta = Class::MOP::Class->initialize('My::Router');
diag for $meta->get_method_list;
