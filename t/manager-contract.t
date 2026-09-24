use strict;
use warnings;
use Test::More;
use JSON::PP;
use lib 'lib';
use Bufo::Game;
use Bufo::Save;
use Bufo::API;
use Bufo::Catalog;
use Bufo::Core::EventBus;
sub data { open my $f, '<:raw', "assets/data/$_[0].json" or die $!; local $/; decode_json(<$f>) }
my $catalog = Bufo::Catalog->new( map { $_ => data($_) } qw(generators upgrades achievements) );
my $time    = 1000;
my $bus     = Bufo::Core::EventBus->new;
my $game    = Bufo::Game->new( catalog => $catalog, now => $time, events => $bus );
my $api     = Bufo::API->new( game => sub { $game }, clock => sub { $time }, events => $bus );
my $custom  = {
    id               => 'custom_upgrade',
    name             => 'Custom Upgrade',
    description      => 'Test',
    category         => 'click',
    cost             => 10,
    effects          => [ { type => 'clickMultiplier', multiplier => 2 } ],
    unlockConditions => []
};
$game->_credit(100);
$api->getUpgradeManager->setUpgrades( [$custom] );
ok( $api->buyUpgrade('custom_upgrade'), 'facade buys configured custom upgrade' );
my $tick_ok = eval { $time += 1000; $api->processTick(1); 1 };
ok( $tick_ok, 'custom upgrade survives next tick' ) or diag $@;
my $save    = Bufo::Save->new( catalog => $catalog );
my $save_ok = eval {
    my $raw = $save->serialize( $game->state, now => $time );
    $game = Bufo::Game->new(
        catalog => $catalog,
        state   => $save->parse( $raw, now => $time ),
        now     => $time
    );
    1;
};
ok( $save_ok, 'custom definition and purchase survive reload' ) or diag $@;
is( $game->state->{resources}{clickMultiplier},
    2.2, 'custom effect and earned achievement reconstruct once' );
my ( @clicks, @ticks, @unlocks );
$bus->on( 'click',              sub { push @clicks,  $_[0] } );
$bus->on( 'tick',               sub { push @ticks,   $_[0] } );
$bus->on( 'GENERATOR_UNLOCKED', sub { push @unlocks, $_[0] } );
$game = Bufo::Game->new( catalog => $catalog, now => $time, events => $bus );
my $first  = $game->click($time);
my $second = $game->click( $time + 100 );
$game->tick( 0, $time + 200 );
is( $clicks[0]{clickPower}, $first->{bufosGained},  'click event reports actual first-click gain' );
is( $clicks[1]{clickPower}, $second->{bufosGained}, 'click event includes combo gain' );
is( ref( $ticks[0]{generators} ), 'ARRAY',          'tick event exposes unlocked generator array' );
$game->state->{resources}{bufos}      = 999;
$game->state->{resources}{totalBufos} = 999;
$game->click( $time + 1000 );
ok( @unlocks, 'threshold crossing emits generator unlock event' );
my $state = $game->state;
$state->{generators}{tadpole}{count} = 1;
$state->{generators}{tadpole}{boosts} =
  [ map { { id => $_, multiplier => 1e200, source => 'Test', active => 1 } } qw(a b) ];
my $invalid = eval { $save->serialize( $state, now => $time + 1000 ); 1 };
ok( !$invalid, 'aggregate production overflow rejected before persistence' );
done_testing;
