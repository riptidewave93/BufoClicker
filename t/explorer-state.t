use strict;
use warnings;
use Test::More;
use JSON::PP ();
use lib 'lib';
use Bufo::ExplorerModel;
use Bufo::Explorer;
use Bufo::Combat;
use Bufo::Enemies;
sub clone { Bufo::ExplorerModel::_clone( $_[0] ) }
my $default = Bufo::ExplorerModel->default_data( now => 1800000000000 );
is_deeply( Bufo::ExplorerModel->normalize( undef, now => 1800000000000 ),
    $default, 'older Perl save without Explorer receives full defaults' );
my $saved = clone($default);
@$saved{
    qw(name level experience experienceToNextLevel state stateStartTime health maxHealth explorationProgress currentArea explorationsCompleted lifetimeBufosFromExploring)
} = ( 'Saved Frog', 3, 35, 250, 'fighting', 1790000000000, 72, 180, 43, 'Mountains', 8, 4567.5 );
$saved->{equipment} = { weapon => 'Moon staff', armor => 'Rare cloak', accessory => undef };
$saved->{attack} =
  { value => 17.5, level => 4, growthRate => 2.75, upgradeCost => 128, multiplier => 1.4 };
is_deeply( Bufo::ExplorerModel->normalize( $saved, now => 1800000000000 ),
    $saved, 'normalization preserves every field and does not recalculate saved stats' );

for my $case (
    [ 'invalid state',            sub { $_[0]{state}                 = 'teleporting' } ],
    [ 'negative HP',              sub { $_[0]{health}                = -1 } ],
    [ 'HP above maximum',         sub { $_[0]{health}                = 999 } ],
    [ 'zero next XP',             sub { $_[0]{experienceToNextLevel} = 0 } ],
    [ 'fractional level',         sub { $_[0]{level}                 = 1.5 } ],
    [ 'numeric string stat',      sub { $_[0]{attack}{value}         = '12' } ],
    [ 'invalid equipment object', sub { $_[0]{equipment}{weapon}     = { danger => 1 } } ],
    [ 'out of range progress',    sub { $_[0]{explorationProgress}   = 101 } ],
    [ 'negative stat multiplier', sub { $_[0]{speed}{multiplier}     = -1 } ],
    [ 'invalid stat object',      sub { $_[0]{luck}                  = [] } ],
    [ 'overflowing effective attack', sub { $_[0]{attack}{value} = 1e200; $_[0]{attack}{multiplier} = 1e200 } ],
  )
{
    my $bad = clone($saved);
    $case->[1]->($bad);
    ok( !eval { Bufo::ExplorerModel->normalize($bad); 1 }, "reject $case->[0]" );
}
my $now = 1000;
my $e   = Bufo::ExplorerModel->default_data( now => $now );
my @events;
my $m = Bufo::Explorer->new(
    state    => $e,
    now      => sub { $now },
    random   => sub { .999 },
    on_event => sub { push @events, $_[0] }
);
is_deeply(
    $m->getAvailableAreas,
    [qw(Pond Creek Swamp River Lake Forest Mountains Dungeon)],
    'all original areas in order'
);
ok( !$m->startExploration('Unknown'), 'manager rejects unknown area' );
$e->{health} = 19;
ok( !$m->startExploration('Pond'), 'below20percent HP cannot start' );
$e->{health} = 20;
ok( $m->startExploration('Pond'),  'exactly20percent HP can start' );
ok( !$m->startExploration('Pond'), 'already exploring cannot restart' );
my $snapshot = clone($e);
$m->update(0);
is_deeply( $e, $snapshot, 'zero delta unchanged' );
$e->{state}  = 'idle';
$e->{health} = 100;
$m->reset;
@events = ();
my $upgrade = $m->upgradeExplorerStat( 'attack', 50 );
is_deeply(
    $upgrade,
    { success => 1, cost => 50 },
    'manager stat upgrade returns original result shape'
);
is_deeply(
    \@events,
    [qw(EXPLORER_STAT_UPGRADED EXPLORER_UPDATED)],
    'stat events emitted once and in order'
);
is( $e->{attack}{value}, 12, 'shared state sees manager upgrade' );
my $stats = $m->getExplorerStats;
is( $stats->{dps}, 6, 'manager statistics use updated model DPS' );
is( $stats->{healthPercent}, 100 / 110 * 100,
    'manager health percent uses actual current maximum' );
ok( !$m->performCombatAction('attack'), 'no combat action without encounter' );
ok( !$m->autoResolveCombat,             'no auto resolution without encounter' );

# Hidden time does not advance distance but remains part of source reward duration.
$now = 1000;
%$e  = %{ Bufo::ExplorerModel->default_data( now => $now ) };
$m->reset;
$m->startExploration('Pond');
for ( 1 .. 5 ) { $now += 5000; $m->update(5) }
my $progress = $e->{explorationProgress};
$now += 100000;
is( $e->{explorationProgress}, $progress, 'wall-clock gap alone leaves progress untouched' );
my $result;
for ( 1 .. 5 ) { $now += 5000; $result = $m->update(5) }
is( $result->{duration},    150, 'completion duration includes wall-clock gap as original' );
is( $result->{bufosGained}, 131, 'wall-clock reward quirk retained' );

# Source saves restore fighting data without transient enemy/combat context.
%$e = %$saved;
$m->reset;
my $restored = clone($e);
$now = 1800000000000;
$m->update(10);
is_deeply( $e, $restored, 'restored fighting state retains original lack of automatic recovery' );
is( $m->getCurrentCombat, undef,        'combat context is transient' );
is( $m->getCurrentEnemy,  undef,        'enemy context is transient' );
is( $e->{name},           'Saved Frog', 'manager reset does not reset progression' );

my $fresh = Bufo::ExplorerModel->default_data( now => 1000 );
ok( !Bufo::ExplorerModel->canLevelUp($fresh), 'level-up eligibility false before threshold' );
ok( Bufo::ExplorerModel->canLevelUp( { %$fresh, experience => 100 } ),
    'level-up eligibility true at threshold' );
is( Bufo::ExplorerModel->calculateStatUpgradeCost(2),
    57, 'stat cost preserves source floating rounding' );
is( Bufo::ExplorerModel->getAreaLevel('Unknown'), 1, 'pure area helper retains fallback' );
is( Bufo::ExplorerModel->startCombat( $fresh, now => 2000 )->{state},
    'idle', 'pure combat start requires exploring' );
my $started = Bufo::ExplorerModel->startExploration( $fresh, 'Any model area', now => 2000 );
is(
    $started->{currentArea},
    'Any model area',
    'pure model start retains absence of manager area validation'
);
is( Bufo::ExplorerModel->startCombat( $started, now => 3000 )->{stateStartTime},
    3000, 'pure combat start stamps time' );
is_deeply(
    Bufo::ExplorerModel->updateExplorer( $fresh, 60, now => 4000 ),
    { explorer => $fresh },
    'idle model update unchanged'
);
is_deeply( Bufo::ExplorerModel->restExplorer( $fresh, 60 ),
    $fresh, 'idle explorer does not heal through rest helper' );
my $foe = {
    name      => 'Lethal foe',
    health    => 1000,
    attack    => 1000,
    defense   => 0,
    speed     => 0,
    dropTable => { baseBufos => 1, baseExperience => 1, possibleDrops => [] }
};
my $fight = Bufo::Combat->initializeCombat( $fresh, $foe, now => 1000 );
my $defeat =
  Bufo::Combat->executeCombatAction( $fight, 'attack', now => 2000, random => sub { .5 } );
is( $defeat->{newState}{status},           'defeat', 'lethal counterattack sets defeat' );
is( $defeat->{newState}{explorer}{health}, 0,        'damage clamps health tozero' );
ok( !exists $defeat->{rewards}, 'defeat awards nothing' );
my $original = clone($fresh);
Bufo::Combat->simulateCombat( $fresh, $foe, 1, random => sub { .5 } );
is_deeply( $fresh, $original, 'simulation leaves explorer input unchanged' );
ok(
    !eval {
        Bufo::Enemies->generateEnemy( 'Nowhere', 0, 1, random => sub { .5 } );
        1;
    },
    'no eligible enemy template reports error'
);
is( scalar @{ Bufo::Enemies->initial_enemy_templates },
    6, 'all original enemy templates accessible' );
is( scalar keys %{ Bufo::Enemies->base_drop_items }, 5,
    'all original drop definitions accessible' );
is_deeply(
    Bufo::Combat->statuses,
    { InProgress => 'inProgress', Victory => 'victory', Defeat => 'defeat' },
    'combat statuses retained'
);
is_deeply(
    Bufo::Combat->action_types,
    { Attack => 'attack', Defend => 'defend', Flee => 'flee' },
    'combat actions retained'
);
is_deeply(
    Bufo::Enemies->types,
    { Normal => 'normal', Elite => 'elite', Boss => 'boss' },
    'enemy variants retained'
);
done_testing;
