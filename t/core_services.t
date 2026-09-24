use strict;
use warnings;
use Test::More;
use lib 'lib';
use Bufo::Core::Logger;
use Bufo::Core::StateManager;
use Bufo::Core::EventBus;
use Bufo::Util::State;
use Bufo::Util::Validation;
use Bufo::Util::General;
my @log;
my $logger = Bufo::Core::Logger->new( now => sub { 1234 }, sink => sub { push @log, [@_] } );
$logger->error( 'broken', 42 );
is_deeply(
    $log[-1],
    [ 'error', '%c[00:00:01.234] [App] broken', 'color: #FF5252;', 42 ],
    'logger formats original UTC timestamp, CSS and extra arguments'
);
$logger->setLogLevel(0);
$logger->warn('hidden');
is( scalar @log, 1, 'NONE suppresses warnings' );
$logger->setLogLevel(5);
$logger->enableTimestamps(0);
$logger->enableConsoleColors(0);
$logger->createLogger('Child')->info('child');
$logger->info('parent');
is( $log[-2][1], '[Child] child', 'context logger prefixes its messages' );
is( $log[-1][1], '[App] parent',  'context logger restores shared context' );
$logger->groupEnd;
my $before = @log;
$logger->group('one');
$logger->groupCollapsed('two');
$logger->groupEnd;
$logger->groupEnd;
$logger->groupEnd;
is( scalar(@log) - $before, 4, 'nested groups close without underflow' );
$logger->enableGrouping(0);
$before = @log;
$logger->group('hidden');
is( scalar @log, $before, 'group toggle suppresses group' );
my $error = eval {
    $logger->time( 'danger', sub { die 'timed exception' } );
    1;
};
ok( !$error, 'timing rethrows original callback exception' );
is( $log[-1][0], 'timeEnd', 'timing always closes after exception' );
$logger->createLogger('Child')->time( 'inspect', sub { $logger->info('inner') } );
is( $log[-2][1], '[App] inner', 'contextual time retains original unmodified logger context' );

my $bus = Bufo::Core::EventBus->new( logger => $logger );
$bus->setDebugMode(1);
my @events;
my $a;
my $b = sub { push @events, 'b' };
my $c = sub { push @events, 'c' };
$a = sub { push @events, 'a'; $bus->off( 'live', $a ) };
$bus->on( 'live', $a );
$bus->on( 'live', $b );
$bus->on( 'live', $c );
$bus->emit('live');
is_deeply( \@events, [ 'a', 'c' ], 'dispatch preserves original live-array removal semantics' );
@events = ();
$bus->clearEvent('live');
$a = sub { push @events, 'a'; $bus->on( 'live', $c ) };
$bus->on( 'live', $a );
$bus->on( 'live', $b );
$bus->emit('live');
is_deeply(
    \@events,
    [ 'a', 'b', 'c' ],
    'dispatch observes appended callback in original iteration order'
);
$bus->setExcludedEvents( ['live'] );
$before = @log;
$bus->emit('live');
is( scalar @log, $before, 'excluded event delivers without emission logs' );
$bus->removeExcludedEvent('live');
$bus->emit('live');
ok( @log > $before, 'removing exclusion restores emission logging' );
$bus->clearAllEvents;
is_deeply( $bus->getEventNames, [], 'clear-all removes event names' );

my $utils = Bufo::Util::State->new(
    now        => sub { 100 },
    generators => { tadpole => { count => 1, enabled => 1 } }
);
my $live = $utils->createDefaultState;
my @changes;
my @errors;
my $state = Bufo::Core::StateManager->new(
    defaults => sub { $utils->createDefaultState },
    get      => sub { $live },
    set      => sub { $live = $_[0] },
    on_error => sub { push @errors, [@_] }
);
$state->subscribe( sub { push @changes, [ $_[0]{resources}{bufos}, $_[1]{resources}{bufos} ] } );
$live->{resources}{bufos} = 7;
$state->notifyStateChange;
is_deeply(
    $changes[-1],
    [ 7, 0 ],
    'external live mutation notifies new and prior observed snapshots'
);
$state->startBatch;
$live->{resources}{bufos} = 8;
$state->notifyStateChange;
$live->{resources}{bufos} = 9;
$state->notifyStateChange;
is( scalar @changes, 1, 'external mutation honors notification batch' );
$state->endBatch;
is_deeply( $changes[-1], [ 9, 9 ], 'batch retains original final-state old/new quirk' );
my $newgame = $utils->createDefaultState;
$newgame->{resources}{bufos} = 20;
$live = $newgame;
$state->notifyStateChange;
is_deeply( $changes[-1], [ 20, 9 ], 'provider follows replacement authoritative game' );
my $unchanged = $state->getState;
ok( !$state->loadState( { invalid => 1 } ), 'invalid load returns false' );
is_deeply( $state->getState, $unchanged, 'invalid load leaves live state unchanged' );
my $bad  = sub { die 'subscriber failed' };
my $seen = 0;
my $good = sub { $seen++ };
$state->subscribe($bad);
$state->subscribe($good);
$state->subscribe($good);
$state->resetState;
is( $seen,          2, 'state subscribers retain original duplicate subscriptions' );
is( scalar @errors, 1, 'state subscriber failure is isolated and reported' );
$state->unsubscribe($good);
$state->resetState;
is( $seen, 3, 'unsubscribe removes only first duplicate subscription' );
my $patch = {
    resources    => { baseClickPower => 2, clickMultiplier => 3, frenzyClickMultiplier => 7 },
    prestige     => { lifetimePoints => 10 },
    bosses       => { defeated       => ['a'],          lifetimeDefeats => 1 },
    generators   => { tadpole        => { count => 4 }, unknown         => { count => 1 } },
    achievements => { unlocked       => ['one'],        progress        => { click => 5 } }
};
my $updated = Bufo::Util::State::updateState( $live, $patch );
is( $updated->{resources}{clickPower},
    126, 'derived click power includes upgrades, prestige, boss and frenzy' );
is( $updated->{generators}{tadpole}{enabled},
    1, 'generator partial merge retains neighboring field' );
ok( !exists $updated->{generators}{unknown}, 'state utility ignores unknown generator IDs' );
$patch->{achievements}{unlocked}[0] = 'changed';
is( $updated->{achievements}{unlocked}[0], 'one', 'replacement achievement array is isolated' );
is_deeply(
    Bufo::Util::Validation::validateObject(
        { good => 2, bad => 'x' },
        {
            good    => \&Bufo::Util::Validation::isValidNumber,
            bad     => \&Bufo::Util::Validation::isValidNumber,
            missing => sub { 1 }
        }
    ),
    { isValid => JSON::PP::false, invalidProps => [ 'bad', 'missing' ] },
    'object validation records missing and invalid properties'
);
ok( Bufo::Util::Validation::hasRequiredProperties( { null => undef }, ['null'] ),
    'required property allows explicit null' );
ok(
    !Bufo::Util::Validation::hasRequiredProperties(
        { absent => Bufo::Util::Undefined->value },
        ['absent']
    ),
    'required property rejects explicit undefined sentinel'
);
ok( !Bufo::Util::Validation::isValidObject(JSON::PP::true), 'JSON boolean is not an object' );
Bufo::Core::EventBus->setInstance($bus);
is(Bufo::Core::EventBus::getEventBus(),$bus,'singleton event getter returns bound browser service');
Bufo::Core::StateManager->setInstance($state);
is(Bufo::Core::StateManager::getStateManager(),$state,'singleton state getter returns bound browser service');
done_testing;
