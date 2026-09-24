use strict;
use warnings;
use Test::More;
use JSON::PP     ();
use Scalar::Util qw(refaddr);
use lib 'lib';
use Bufo::ExplorerModel;
use Bufo::Explorer;
use Bufo::Enemies;
use Bufo::Combat;
open my $fh, '<', 't/fixtures/explorer-oracle.json' or die $!;
my $fixture = JSON::PP::decode_json( do { local $/; <$fh> } );
sub clone { Bufo::ExplorerModel::_clone( $_[0] ) }

sub differences {
    my ( $actual, $expected, $path ) = @_;
    $path //= '$';
    return ("$path: missing value") if defined($actual) != defined($expected);
    return () unless defined $expected;
    if ( ref($expected) eq 'HASH' ) {
        return ("$path: not a hash") unless ref($actual) eq 'HASH';
        my @bad;
        push @bad, "$path: key set differs"
          if join( ',', sort keys %$actual ) ne join( ',', sort keys %$expected );
        push @bad, differences( $actual->{$_}, $expected->{$_}, "$path.$_" ) for keys %$expected;
        return @bad;
    }
    if ( ref($expected) eq 'ARRAY' ) {
        return ("$path: not an array") unless ref($actual) eq 'ARRAY';
        my @bad;
        push @bad, "$path: array length differs" if @$actual != @$expected;
        push @bad, differences( $actual->[$_], $expected->[$_], "$path\[$_\]" )
          for 0 .. $#$expected;
        return @bad;
    }
    if (   !ref($actual)
        && "$expected" =~ /\A-?\d+(?:\.\d+)?(?:e[+-]?\d+)?\z/i
        && "$actual"   =~ /\A-?\d+(?:\.\d+)?(?:e[+-]?\d+)?\z/i )
    {
        return () if abs( $actual - $expected ) <= 1e-10 * ( abs($expected) || 1 );
    } elsif ( "$actual" eq "$expected" ) {
        return ();
    }
    return ("$path: $actual != $expected");
}

sub oracle {
    my ( $actual, $expected, $label ) = @_;
    my @bad = differences( $actual, $expected );
    ok( !@bad, $label );
    diag( join( "\n", @bad ) ) if @bad;
}
my $d = Bufo::ExplorerModel->default_data( now => 1000 );
oracle( $d, $fixture->{default}, 'default matches original TypeScript' );
oracle(
    {
        dps      => Bufo::ExplorerModel->calculateDPS($d),
        survival => Bufo::ExplorerModel->calculateSurvivalTime($d),
        power    => Bufo::ExplorerModel->calculatePowerRating($d),
        effect   => Bufo::ExplorerModel->calculateAreaEffectiveness( $d, 1 )
    },
    $fixture->{stats},
    'derived stat formulas match original'
);
for my $name (qw(attack defense speed luck invalid)) {
    oracle(
        Bufo::ExplorerModel->upgradeExplorerStat( $d, $name, 50 ),
        $fixture->{upgrades}{$name},
        "$name stat upgrade matches original"
    );
}
oracle(
    Bufo::ExplorerModel->upgradeExplorerStat( $d, 'attack', 49 ),
    $fixture->{poorUpgrade},
    'unaffordable stat result'
);
oracle(
    Bufo::ExplorerModel->levelUpExplorer( { %$d, experience => 250 } ),
    $fixture->{modelLevel},
    'pure model advances exactly one level'
);
for my $case ( [ 'success', 0 ], [ 'failure', .99 ] ) {
    my $r = Bufo::ExplorerModel->calculateExplorationResult( $d, 60, random => sub { $case->[1] } );
    oracle( $r, $fixture->{results}{ $case->[0] }, "model $case->[0] reward result" );
    oracle(
        Bufo::ExplorerModel->completeExploration( $d, $r, now => 1000 ),
        $fixture->{completions}{ $case->[0] },
        "model $case->[0] completion"
    );
}
for my $case (
    [ 'injured', 'injured', 15, 60 ],
    [ 'full',    'resting', 90, 60 ],
    [ 'partial', 'resting', 40, 30 ]
  )
{
    oracle(
        Bufo::ExplorerModel->restExplorer(
            { %$d, state => $case->[1], health => $case->[2] },
            $case->[3], now => 1000
        ),
        $fixture->{rest}{ $case->[0] },
        "rest $case->[0] transition"
    );
}
my $started = Bufo::ExplorerModel->startExploration( $d, 'Pond', now => 1000 );
oracle( $started, $fixture->{started}, 'model start exploration' );
oracle(
    Bufo::ExplorerModel->updateExplorer( $started, 600, now => 601000, random => sub { 0 } ),
    $fixture->{modelUpdate},
    'model updater keeps600-second algorithm'
);
for my $area (qw(Pond Creek Swamp River Lake Forest Mountains Dungeon)) {
    oracle(
        Bufo::Enemies->generateEnemy(
            $area, .4, Bufo::ExplorerModel->getAreaLevel($area),
            now    => 1000,
            random => sub { .5 }
        ),
        $fixture->{enemies}{$area},
        "$area enemy matches source"
    );
}
my @rolls = ( 0, .5, .5, .5, .5, .5 );
my $bug = Bufo::Enemies->generateEnemy( 'Pond', 0, 1, now => 1000, random => sub { shift @rolls } );
oracle( $bug, $fixture->{waterbug}, 'exact Water Bug generation' );
my $with_drops = clone($bug);
$with_drops->{dropTable}{guaranteedDrops} = ['guaranteed'];
oracle( Bufo::Enemies->calculateEnemyRewards( $with_drops, random => sub { .5 } ),
    $fixture->{rewards}, 'reward RNG and drop order' );
oracle(
    Bufo::Enemies->calculateRelativeDifficulty(
        { attack => 20, defense => 15, health => 100, speed => 5 },
        { attack => 10, defense => 5,  health => 100, speed => 8 }
    ),
    $fixture->{relative},
    'relative difficulty'
);
my $combat = Bufo::Combat->initializeCombat( $d, $bug, now => 1000 );
oracle( $combat, $fixture->{combat}{initial}, 'combat initialization' );

for my $action (qw(attack defend flee)) {
    oracle(
        Bufo::Combat->executeCombatAction(
            clone($combat), $action,
            now    => 1000,
            random => sub { .5 }
        ),
        $fixture->{combat}{$action},
        "combat action $action"
    );
}
oracle(
    Bufo::Combat->executeCombatAction( clone($combat), 'flee', now => 1000, random => sub { .99 } ),
    $fixture->{combat}{failedFlee},
    'failed flee counterattack'
);
my @actions;
my $fight = clone($combat);
while ( $fight->{status} eq 'inProgress' ) {
    my $result =
      Bufo::Combat->executeCombatAction( $fight, 'attack', now => 1000, random => sub { .5 } );
    push @actions, clone($result);
    $fight = $result->{newState};
}
oracle( \@actions, $fixture->{combat}{actions}, 'complete manual victory and logs' );
for my $rounds ( 2, 3 ) {
    oracle(
        Bufo::Combat->simulateCombat( $d, $bug, $rounds, random => sub { .5 } ),
        $fixture->{combat}{"sim$rounds"},
        "simulation$rounds round cap"
    );
}
my ( $now, $fallback ) = ( 1000, .999 );
my @events;
my @rng;
my $shared  = clone($d);
my $manager = Bufo::Explorer->new(
    state    => $shared,
    now      => sub { $now },
    random   => sub { @rng ? shift @rng : $fallback },
    on_event => sub { push @events, { name => $_[0], payload => clone( $_[1] ) } }
);
$manager->startExploration('Pond');
for ( 1 .. 10 ) { $now += 5000; $manager->update(5) }
oracle(
    {
        state  => { explorer => $shared, resources => { bufos => 123, totalBufos => 123 } },
        events => \@events
    },
    $fixture->{managerComplete},
    'manager completion state and ordered event payloads match original'
);
is( refaddr( $manager->getExplorer ), refaddr($shared), 'manager preserves shared state identity' );
$now      = 1000;
$fallback = .5;
@events   = ();
%$shared  = %{ clone($d) };
$manager->reset;
@events = ();
$manager->startExploration('Pond');
@rng = ( 0, 0, .5, .5, .5, .5, .5 );
$now = 2000;
$manager->update(1);
oracle(
    {
        explorer => $manager->getExplorer,
        enemy    => $manager->getCurrentEnemy,
        combat   => $manager->getCurrentCombat,
        events   => \@events
    },
    $fixture->{encounter},
    'manager encounter state and events'
);
@events = ();
$manager->performCombatAction('attack');
$manager->autoResolveCombat;
oracle(
    {
        state  => { explorer => $shared, resources => { bufos => 123, totalBufos => 123 } },
        events => \@events
    },
    $fixture->{managerMixed},
    'manual-to-auto preserves original manager outcome and events'
);
$now      = 1000;
$fallback = .999;
%$shared  = ( %{ clone($d) }, experience => 250 );
$manager->reset;
@events = ();
$manager->startExploration('Pond');
for ( 1 .. 10 ) { $now += 5000; $manager->update(5) }
oracle(
    {
        state  => { explorer => $shared, resources => { bufos => 123, totalBufos => 123 } },
        events => \@events
    },
    $fixture->{managerLevel},
    'manager multi-level behavior differs from pure model exactly as source'
);

for my $case ( @{ $fixture->{enemyMatrix} } ) {
    my @rolls = @{ $case->{rolls} };
    oracle(
        Bufo::Enemies->generateEnemy(
            $case->{area}, $case->{distance}, $case->{level},
            now    => 1000,
            random => sub { shift @rolls }
        ),
        $case->{expected},
        "enemy template $case->{template} type $case->{type} matches original"
    );
}
done_testing;
