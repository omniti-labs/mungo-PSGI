use strict;
use warnings;
use Test::More;

my @modules = qw(
    Mungo::PSGI
    Mungo::PSGI::Request
    Mungo::PSGI::Response
    Mungo::PSGI::Script
    Mungo::PSGI::Script::File
    Mungo::PSGI::Script::Memory
    Mungo::PSGI::Server
    Plack::Middleware::Mungo
);

plan tests => scalar @modules;
for my $module (@modules) {
    require_ok $module;
}

if (! Test::More->builder->is_passing) {
    BAIL_OUT("Module failed to load!");
}


done_testing;
