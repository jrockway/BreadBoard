#!/usr/bin/perl

use strict;
use warnings;

use Test::More tests => 28;
use Test::Moose;
use Test::Exception;

BEGIN {
    use_ok('Bread::Board::SetterInjection');    
    use_ok('Bread::Board::Literal');        
}

{
    package Needle;
    use Moose;
    
    package Mexican::Black::Tar;
    use Moose;
    
    package Addict;
    use Moose;
    
    has 'needle' => (is => 'rw');
    has 'spoon'  => (is => 'rw');
    has 'stash'  => (is => 'rw');        
}

my $s = Bread::Board::SetterInjection->new(
    name  => 'William',
    class => 'Addict',
    dependencies => {
        needle => Bread::Board::SetterInjection->new(name => 'spike', class => 'Needle'),
        spoon  => Bread::Board::Literal->new(name => 'works', value => 'Spoon!'),        
    },
    parameters => {
        stash => { isa => 'Mexican::Black::Tar' }
    }
);
isa_ok($s, 'Bread::Board::SetterInjection');
does_ok($s, 'Bread::Board::Service::WithClass');
does_ok($s, 'Bread::Board::Service::WithDependencies');
does_ok($s, 'Bread::Board::Service::WithParameters');
does_ok($s, 'Bread::Board::Service');

{
    my $i = $s->get(stash => Mexican::Black::Tar->new);

    isa_ok($i, 'Addict');
    isa_ok($i->needle, 'Needle');
    is($i->spoon, 'Spoon!', '... got our literal service');
    isa_ok($i->stash, 'Mexican::Black::Tar');


    {
        my $i2 = $s->get(stash => Mexican::Black::Tar->new);    
        isnt($i, $i2, '... calling it again returns an new object');
    }
}

is($s->name, 'William', '... got the right name');
is($s->class, 'Addict', '... got the right class');

my $deps = $s->dependencies;
is_deeply([ sort keys %$deps ], [qw/needle spoon/], '... got the right dependency keys');

my $needle = $s->get_dependency('needle');
isa_ok($needle, 'Bread::Board::Dependency');
isa_ok($needle->service, 'Bread::Board::SetterInjection');

is($needle->service->name, 'spike', '... got the right name');
is($needle->service->class, 'Needle', '... got the right class');

my $spoon = $s->get_dependency('spoon');
isa_ok($spoon, 'Bread::Board::Dependency');
isa_ok($spoon->service, 'Bread::Board::Literal');

is($spoon->service->name, 'works', '... got the right name');
is($spoon->service->value, 'Spoon!', '... got the right literal value');

my $params = $s->parameters;
is_deeply([ sort keys %$params ], [qw/stash/], '... got the right paramter keys');
is_deeply($params->{stash}, { isa => 'Mexican::Black::Tar' }, '... got the right parameter spec');

## some errors

dies_ok {
    $s->get;
} '... you must supply the required parameters';

dies_ok {
    $s->get(stash => []);
} '... you must supply the required parameters as correct types';

dies_ok {
    $s->get(stash => Mexican::Black::Tar->new, foo => 10);
} '... you must supply the required parameters (and no more)';




