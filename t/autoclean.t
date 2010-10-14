#!/usr/bin/env perl -w

use Test::More;

BEGIN {
    eval 'use namespace::autoclean';
    plan skip_all => 'namespace::autoclean not installed' if $@;
}

package My::Router;

use strict;
use warnings;
use Router::Resource;
use namespace::autoclean;

resource '/' => sub {
    GET { 'whatever' };
};

package main;

use strict;
use warnings;
use Test::More tests => 7;

for my $fn (qw(GET HEAD POST PUT REMOVE OPTIONS)) {
    is +My::Router->can($fn), undef, "$fn() should be autocleaned";
}

ok +My::Router->can('router'), 'But router() shoud not be autocleaned';




