use strict;
use warnings;
use Test::More;
use lib 'lib';
use Bufo::Core::EventBus;
use Bufo::Core::StateManager;
use Bufo::Core::Logger;
use Bufo::Core::Events;
my @logs;
my $logger = Bufo::Core::Logger->new( sink => sub { push @logs, [@_] }, now => sub { 1234 } );
$logger->enableTimestamps(0);
$logger->enableConsoleColors(0);
$logger->debug('hidden');
is( scalar @logs, 0, 'default INFO suppresses debug' );
$logger->setLogLevel(4);
$logger->debug('visible');
is( $logs[-1][1], '[App] visible', 'logger adds context' );
my $bus = Bufo::Core::EventBus->new( logger => $logger );
my @received;
my $listener = sub { push @received, $_[0] };
$bus->on( 'a', $listener );
$bus->on( 'a', $listener );
$bus->emit( 'a', 42 );
is_deeply( \@received, [42], 'event subscriptions deduplicate callback identity' );
my $once = 0;
$bus->once( 'a', sub { $once++ } );
$bus->emit( 'a', 43 );
$bus->emit( 'a', 44 );
is( $once, 1, 'one-shot listener fires once' );
$bus->off( 'a', $listener );
is( $bus->getListenerCount('a'), 0, 'last unsubscribe removes event' );
$bus->on( 'bad', sub { die 'listener failed' } );
$bus->on( 'bad', sub { push @received, 'survived' } );
$bus->emit('bad');
is( $received[-1], 'survived', 'callback failures do not stop dispatch' );
my $live = {
    resources => {
        bufos                => 1,
        totalBufos           => 1,
        baseClickPower       => 1,
        clickMultiplier      => 1,
        productionMultiplier => 1,
        clickPower           => 1
    },
    generators   => { tadpole => { count => 0 } },
    explorer     => {},
    upgrades     => { purchased => [], available       => [] },
    achievements => { unlocked  => [], progress        => {}, customEvents   => {} },
    gameSettings => { lastSaved => 0,  lastTick        => 0,  version        => '1.0.0' },
    prestige     => { points    => 0,  lifetimePoints  => 0,  transcendences => 0 },
    bosses       => { defeated  => [], lifetimeDefeats => 0 }
};
my $state = Bufo::Core::StateManager->new(
    defaults => sub { $live },
    get      => sub { $live },
    set      => sub { $live = $_[0] },
    validate => sub { ref( $_[0] ) eq 'HASH' }
);
my $copy = $state->getState;
$copy->{resources}{bufos} = 999;
is( $live->{resources}{bufos}, 1, 'state snapshots are isolated' );
my @updates;
my $unsub = $state->subscribe( sub { push @updates, [@_] } );
$state->startBatch;
$state->setState( { resources => { bufos => 2 } } );
$state->setState( { resources => { bufos => 3 } } );
is( scalar @updates, 0, 'batch applies without notifying' );
$state->endBatch;
is( scalar @updates,           1, 'batch notifies once' );
is( $live->{resources}{bufos}, 3, 'injected setter updates authoritative state' );
$unsub->();
$state->setState( { resources => { bufos => 4 } } );
is( scalar @updates,                 1,           'unsubscribe closure works' );
is( Bufo::Core::Events::GAME_TICK(), 'GAME_TICK', 'event names preserve original strings' );
done_testing;
