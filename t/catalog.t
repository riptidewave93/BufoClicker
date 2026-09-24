use strict;
use warnings;
use Test::More;
use JSON::PP;
use lib 'lib';
use Bufo::Catalog;
sub data { open my $fh, '<', "assets/data/$_[0].json" or die $!; local $/; decode_json(<$fh>) }

sub args {
    return (
        generators   => data('generators'),
        upgrades     => data('upgrades'),
        achievements => data('achievements')
    );
}
my $catalog = Bufo::Catalog->new( args() );
is( scalar keys %{ $catalog->generators }, 14, 'all generator tiers retained' );
is( scalar @{ $catalog->upgrades },        91, 'all upgrades retained' );
is( scalar @{ $catalog->achievements },    50, 'all achievements retained' );
is( scalar @{ $catalog->bosses },          7,  'complete ordered boss ladder' );
ok( $catalog->achievement('10_generators'), 'numeric-leading original achievement ID supported' );
is_deeply(
    [ map { $_->{baseHealth} } @{ $catalog->bosses } ],
    [ 975, 53800, 38700000, 65600000, 7070000000, 78200000000, 1670000000000 ],
    'all seven calibrated baseline health values'
);

for my $case (
    [ 'unknown effect',    sub { $_[0]{upgrades}[0]{effects}[0]{type} = 'clickBpsBonus' } ],
    [ 'unknown condition', sub { $_[0]{upgrades}[0]{unlockConditions}[0]{type} = 'surprise' } ],
    [
        'unknown prerequisite',
        sub { $_[0]{upgrades}[0]{unlockConditions} = [ { type => 'upgrade', id => 'missing' } ] }
    ],
    [ 'unknown generator target', sub { $_[0]{upgrades}[2]{effects}[0]{target} = 'missing' } ],
    [ 'duplicate upgrade',        sub { push @{ $_[0]{upgrades} }, $_[0]{upgrades}[0] } ],
    [ 'negative cost',            sub { $_[0]{generators}{tadpole}{baseCost} = -1 } ],
    [ 'zero multiplier',          sub { $_[0]{upgrades}[0]{effects}[0]{multiplier} = 0 } ],
    [ 'missing catalog',          sub { delete $_[0]{achievements} } ],
    [ 'unknown achievement type', sub { $_[0]{achievements}[0]{requirement}{type} = 'surprise' } ],
    [
        'missing target',
        sub { $_[0]{generators}{giant_bufo}{unlockRequirements}[1]{target} = 'missing' }
    ],
  )
{
    my %args = args();
    $case->[1]->( \%args );
    my $ok = eval { Bufo::Catalog->new(%args); 1 };
    ok( !$ok, "$case->[0] fails closed" );
}
done_testing;
