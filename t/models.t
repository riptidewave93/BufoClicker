use strict;
use warnings;
use Test::More;
use JSON::PP;
use lib 'lib';
use Bufo::Catalog;
use Bufo::Model::Generators;
use Bufo::Model::Upgrades;
use Bufo::Model::Achievements;
use Bufo::Model::Prestige;
use Bufo::Model::Boss;
sub data { open my $f, '<:raw', $_[0] or die $!; local $/; decode_json(<$f>) }
my $expected  = data('t/fixtures/models-oracle.json');
my $g         = 'Bufo::Model::Generators';
my $u         = 'Bufo::Model::Upgrades';
my $generator = $g->createGenerator( 'tadpole', 'Tadpole', 'Test', 0.1, 15, 1.15 );
$expected->{generator}{$_} = $expected->{generator}{$_} ? 1 : 0 for qw(unlocked enabled);
is_deeply( $generator, $expected->{generator}, 'generator creation matches original runtime' );
my $boosted = $g->applyBoostToGenerator( { %$generator, count => 10 }, 'custom', 3, 'Test' );

for my $case ( [ boosted => $boosted ], [ inactive => $g->toggleBoost( $boosted, 'custom', 0 ) ] ) {
    my $actual = $g->recalculateGenerator( $case->[1], 2 );
    my $oracle = $expected->{ $case->[0] };
    cmp_ok( abs( $actual->{totalProduction} - $oracle->{totalProduction} ),
        '<', 1e-12, "$case->[0] production matches original" );
    is( $actual->{currentCost}, $oracle->{currentCost}, "$case->[0] cost matches original" );
}
is_deeply( [ map { $g->calculateBulkCost( $generator, $_ ) } ( 1, 10, 100 ) ],
    $expected->{bulk}, 'bulk prices match original' );
is_deeply( [ map { $g->calculateMaxAffordable( $generator, $_ ) } ( 0, 15, 100, 1000 ) ],
    $expected->{max}, 'max affordable agrees at reference values' );
my $upgrade = {
    id      => 'test',
    effects => [
        { type => 'clickMultiplier',     multiplier => 2 },
        { type => 'globalMultiplier',    multiplier => 3 },
        { type => 'generatorProduction', target     => 'tadpole', multiplier => 5 }
    ],
    unlockConditions =>
      [ { type => 'upgrade', target => 'pre' }, { type => 'totalBufos', value => 100 } ]
};
is(
    $u->calculateUpgradeEffectForGenerator( $upgrade, 'tadpole' ),
    $expected->{upgrades}{generator},
    'generator and global upgrades compose'
);
is(
    $u->calculateClickMultiplier( [$upgrade] ),
    $expected->{upgrades}{click},
    'click multiplier matches original'
);
is(
    $u->calculateGlobalMultiplier( [$upgrade] ),
    $expected->{upgrades}{global},
    'global multiplier matches original'
);
ok( !$u->meetsUnlockConditions( $upgrade, 100, {}, {}, [] ), 'prerequisite blocks upgrade' );
ok( $u->meetsUnlockConditions( $upgrade,  100, {}, {}, ['pre'] ),
    'owned prerequisite unlocks upgrade' );
is_deeply( [ map { Bufo::Model::Prestige->prestigePointsFor($_) } ( 0, 1e9, 1e11, 1e13 ) ],
    $expected->{prestige}, 'prestige curve matches original' );
my $catalog = Bufo::Catalog->new( map { $_ => data("assets/data/$_.json") }
      qw(generators upgrades achievements) );
my $boss = Bufo::Model::Boss->new( catalog => $catalog );
is(
    $boss->getBossHealth(
        $catalog->bosses->[0],
        {
            prestige => { lifetimePoints => 10 },
            bosses   => { defeated       => ['one'], lifetimeDefeats => 3 }
        }
    ),
    $expected->{boss}{health},
    'boss health normalizes earned passive multipliers'
);
is(
    Bufo::Model::Achievements->getCategoryIcon('special'),
    $expected->{achievement}{icon},
    'achievement category icon retained'
);
ok(
    Bufo::Model::Achievements->checkAchievementRequirement(
        { requirement           => { type => 'explorationCount', value => 3 } },
        { explorationsCompleted => 3 }
    ),
    'exploration achievements have a functional predicate'
);
done_testing;
