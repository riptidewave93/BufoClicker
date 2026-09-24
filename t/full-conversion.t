use strict;
use warnings;
use Test::More;
use JSON::PP;
use lib 'lib';
use Bufo::Game;
use Bufo::Catalog;
use Bufo::Save;
use Bufo::API;
use Bufo::Loop;
use Bufo::Core::EventBus;
sub data { open my $f, '<:raw', $_[0] or die $!; local $/; decode_json(<$f>) }
my $catalog = Bufo::Catalog->new( map { $_ => data("assets/data/$_.json") }
      qw(generators upgrades achievements) );
my $time   = 1800000000000;
my $events = Bufo::Core::EventBus->new;
my $game =
  Bufo::Game->new( catalog => $catalog, now => $time, events => $events, random => sub { 0.99 } );
my $api    = Bufo::API->new( game => sub { $game }, clock => sub { $time }, events => $events );
my $save   = Bufo::Save->new( catalog => $catalog );
my $legacy = data('t/fixtures/legacy-captured.json');
is_deeply(
    $save->parse( encode_json($legacy), now => $time )->{explorer},
    $legacy->{state}{explorer},
    'captured legacy Explorer preserved'
);
my $snapshot = $api->getState;
$snapshot->{resources}{bufos} = 99;
is( $game->state->{resources}{bufos}, 0, 'facade snapshots cannot change live state' );
$game->_credit(1000);
$game->_check_achievements;
my $purchase_bank = $game->state->{resources}{bufos};
my @purchases;
$api->on( 'GENERATOR_PURCHASED', sub { push @purchases, $_[0] } );
ok( $api->buyGenerator( 'tadpole', 1 ), 'facade purchases generator' );
is( scalar @purchases, 1, 'one purchase event' );
is(
    $game->state->{resources}{bufos},
    $purchase_bank - $purchases[0]{cost},
    'facade deducts cost once'
);
$api->getGeneratorManager->applyBoostToGenerator( 'tadpole', 'custom', 3, 'Developer boost' );
$api->getGeneratorManager->applyBoostToGenerator( 'tadpole', 'inactive', 100, 'Inactive boost', 0 );
$game->state->{generators}{tadpole}{enabled} = 0;
$game->refresh;
cmp_ok( abs( $game->production - 0.3 ),
    '<', 1e-12, 'disabled owned generator produces with active custom boosts' );
ok( !$api->buyGenerator( 'tadpole', 1 ), 'disabled generator cannot be purchased' );
my $before = $game->state->{resources}{bufos};
$game->collect_golden( 'bufo_frenzy', $time );
$game->pause($time);
$time += 24 * 60 * 60 * 1000;
$game->credit_elapsed( 43200, $time );
cmp_ok( abs( $game->state->{resources}{bufos} - $before - 12960 ),
    '<', 1e-8, 'bulk income retains custom boosts and excludes cancelled Golden frenzy' );
$game->resume($time);
my $raw         = $save->serialize( $game->state, now => $time );
my $replacement = Bufo::Game->new(
    catalog => $catalog,
    state   => $save->parse( $raw, now => $time ),
    now     => $time,
    random  => sub { 0.99 }
);
$replacement->set_event_bus($events);
$game = $replacement;
is( $api->getState->{generators}{tadpole}{enabled},
    0, 'provider follows replacement and disabled state survives' );
is( scalar @{ $api->getState->{generators}{tadpole}{boosts} },
    2, 'both custom boosts survive save and replacement' );
my @started;
$api->on( 'EXPLORATION_STARTED', sub { push @started, $_[0] } );
ok( $api->startExploration('Pond'), 'Explorer facade starts after replacement' );
is( scalar @started, 1, 'shared bus delivers replacement Explorer event once' );
my $explorer = $api->getExplorer;
for ( 1 .. 10 ) { $time += 5000; $api->processTick(5); }
is( $api->getExplorer->{explorationsCompleted}, 1, 'integrated game tick completes exploration' );
my $post = $save->parse( $save->serialize( $game->state, now => $time ), now => $time );
is( $post->{explorer}{explorationsCompleted}, 1, 'post-replacement Explorer progress is durable' );
my $clock = 0;
my $ticks = 0;
my @ui;
my $cancelled;
my $loop = Bufo::Loop->new(
    now      => sub { $clock },
    tick     => sub { $ticks++ },
    emit     => sub { push @ui, $_[1] },
    schedule => sub { 7 },
    cancel   => sub { $cancelled = $_[0] }
);
$loop->setTargetFPS(10);
$loop->setTimeScale(5);
$loop->start;
is( $loop->frame( 24 * 60 * 60 * 1000 ), 10,
    '24h frame jump processes at most capped fixed steps' );
is( $ticks,     10, 'no unbounded catchup' );
is( scalar @ui, 1,  'one UI tick emitted for frame' );
$loop->stop;
is( $cancelled, 7, 'stop cancels scheduled browser frame' );
$clock = 24 * 60 * 60 * 1000;
$loop->start;
is( $loop->frame($clock), 0, 'resume resets accumulation' );
done_testing;
