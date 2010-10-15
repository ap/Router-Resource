#!/usr/bin/env perl

use strict;
use Test::More;
eval "use Test::Spelling";
plan skip_all => "Test::Spelling required for testing POD spelling" if $@;

add_stopwords(<DATA>);
all_pod_files_spelling_ok();

__DATA__
Plack
RESTful
RESTy
Wiki
unfound
Acknowledgements
LeoNerd
Melo
Miyagawa
Pearcey
Ragwitz
Sinatraish
Tatsuhiko
mdule
melo
miyagawa
mst
rafl

