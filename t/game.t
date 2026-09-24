use strict;
use warnings;
use Test::More;
use JSON::PP;
use lib 'lib';
require Bufo::Catalog;
require Bufo::Game;

sub data {
    open my $fh, '<', "assets/data/$_[0].json" or die $!;
    local $/;
    return decode_json(<$fh>);
}
my $catalog = Bufo::Catalog->new(
    generators   => data('generators'),
    upgrades     => data('upgrades'),
    achievements => data('achievements')
);
my $game = Bufo::Game->new( catalog => $catalog, now => 1000 );
is( $game->click(1000)->{bufosGained},     1,   'first click earns one bufo' );
is( $game->state->{resources}{clickCount}, 1,   'click counted once' );
is( $game->state->{resources}{clickPower}, 1.1, 'first achievement boosts future clicks' );
cmp_ok( abs( $game->click(1100)->{bufosGained} - 1.155 ), '<', 1e-9, 'rapid click applies combo' );
ok( !$game->buy_generator( 'tadpole', 1 )->{ok}, 'unaffordable purchase rejected' );
is( $game->state->{generators}{tadpole}{count}, 0, 'failed purchase leaves count unchanged' );
my $restored = Bufo::Game->new( catalog => $catalog, now => 2000, state => $game->state );
is( $restored->state->{resources}{clickPower},
    1.1, 'restore reconstructs achievement multiplier once' );
is(
    $restored->state->{resources}{bufos},
    $game->state->{resources}{bufos},
    'restore adds no currency'
);

sub plain_catalog {
    return Bufo::Catalog->new(
        generators   => data('generators'),
        upgrades     => data('upgrades'),
        achievements => [
            {
                id          => 'unearned',
                name        => 'Unearned',
                requirement => { type => 'totalBufos', value => 1e200 }
            }
        ]
    );
}
my $plain = plain_catalog();

sub seeded {
    my (%state) = @_;
    return Bufo::Game->new( catalog => $plain, now => 1000, state => \%state );
}

sub near {
    my ( $got, $expected, $name ) = @_;
    cmp_ok( abs( $got - $expected ), '<', 1e-8 * ( $expected || 1 ), $name );
}

my $economy = seeded( resources => { bufos => 10000, totalBufos => 10000 } );
is( $economy->generator_cost( 'tadpole', 1 ), 10, 'first generator base cost' );
my $purchase = $economy->buy_generator( 'tadpole', 10 );
ok( $purchase->{ok}, 'bulk purchase succeeds' );
is( $purchase->{cost},                        204,   'bulk price uses geometric series and ceil' );
is( $economy->state->{resources}{bufos},      9796,  'purchase charged once' );
is( $economy->state->{resources}{totalBufos}, 10000, 'purchase preserves run total' );
near( $economy->production, 1, 'ten tadpoles produce one per second' );
is( $economy->generator_cost( 'tadpole', 1 ),  41,  'next unit price rounds up' );
is( $economy->generator_cost( 'tadpole', 10 ), 833, 'bulk price starts from rounded current cost' );
ok( $economy->buy_upgrade('tadpole_boost_1')->{ok}, 'owned-ten generator upgrade available' );
near( $economy->production, 2, 'generator upgrade doubles production' );
ok( $economy->buy_upgrade('stronger_clicks_1')->{ok}, 'click upgrade purchase' );
near( $economy->state->{resources}{clickPower}, 2, 'click upgrade doubles clicks' );
near( $economy->production,                     2, 'click upgrade leaves production alone' );
my $before = encode_json( $economy->state );
ok( !$economy->buy_upgrade('stronger_clicks_1')->{ok}, 'duplicate upgrade rejected' );
is( encode_json( $economy->state ), $before, 'duplicate purchase is atomic' );

for my $qty ( 0, -2, 1.5, 'nope' ) {
    ok( !$economy->buy_generator( 'tadpole', $qty )->{ok}, "invalid quantity $qty rejected" );
}
ok( !$economy->buy_generator( 'singularity_bufo', 1 )->{ok}, 'locked generator rejected' );
my $prereq = seeded( resources => { bufos => 1e8, totalBufos => 1e8 } );
ok( !$prereq->buy_upgrade('ribbit_resonance')->{ok}, 'missing upgrade prerequisite fails' );
ok( $prereq->buy_upgrade('stronger_clicks_2')->{ok}, 'prerequisite purchased' );
ok( $prereq->buy_upgrade('ribbit_resonance')->{ok},  'prerequisite unlock now passes' );

for my $count ( 0, 1, 7, 50 ) {
    my $max = seeded(
        resources  => { bufos   => 10000, totalBufos => 10000 },
        generators => { tadpole => { count => $count, unlocked => 1 } }
    );
    my $n = $max->max_affordable('tadpole');
    cmp_ok( $max->generator_cost( 'tadpole', $n ),
        '<=', 10000, "max affordable fits bank at count $count" );
    cmp_ok( $max->generator_cost( 'tadpole', $n + 1 ),
        '>', 10000, "next quantity exceeds bank at count $count" );
    my $result = $max->buy_generator( 'tadpole', -1 );
    if ($n) { is( $result->{quantity}, $n, "max purchase buys computed count $count" ); }
    else    { ok( !$result->{ok}, "zero-affordable max purchase rejected at count $count" ); }
    cmp_ok( $max->state->{resources}{bufos}, '>=', 0, 'max purchase never overspends' );
}
my $clicker = seeded();
for my $i ( 0 .. 12 ) { $clicker->click( 1000 + $i * 10 ); }
near( $clicker->click(1140)->{comboMultiplier}, 1.5, 'combo capped at 1.5' );
near( $clicker->click(1640)->{comboMultiplier}, 1,   '500ms gap ends combo' );
is( $clicker->state->{resources}{clickCount}, 15, 'each rapid click counted once' );

for my $roll (
    [ 0,       'bufo_frenzy' ],
    [ 0.49999, 'bufo_frenzy' ],
    [ 0.5,     'lucky' ],
    [ 0.79999, 'lucky' ],
    [ 0.8,     'click_frenzy' ],
    [ 0.9999,  'click_frenzy' ]
  )
{
    is( $clicker->golden_outcome( $roll->[0] ),
        $roll->[1], "golden probability boundary $roll->[0]" );
}
my $gold = seeded(
    resources  => { bufos   => 1000, totalBufos => 1000 },
    generators => { tadpole => { count => 10, unlocked => 1 } }
);
ok( $gold->collect_golden( 'bufo_frenzy', 1000 )->{ok}, 'production frenzy collected' );
near( $gold->production, 7, 'frenzy production x7' );
$gold->collect_golden( 'bufo_frenzy', 2000 );
near( $gold->production, 7, 'recollection refreshes, does not stack strength' );
is( $gold->active_frenzies(2000)->{production}{endsAt}, 32000, 'frenzy duration refreshed' );
$gold->tick( 31, 33000 );
near( $gold->production, 1, 'frenzy expires' );
near( $gold->state->{resources}{bufos},
    1211, 'interval straddling frenzy expiry awards 30 boosted and one normal second' );
my $lucky = seeded(
    resources  => { bufos   => 1000, totalBufos => 1000 },
    generators => { tadpole => { count => 10, unlocked => 1 } }
);
$lucky->collect_golden( 'lucky', 1000 );
is( $lucky->state->{resources}{bufos}, 1163, 'lucky bank formula plus thirteen' );
my $empty = seeded();
$empty->collect_golden( 'lucky', 1000 );
is( $empty->state->{resources}{bufos}, 13, 'lucky works without production' );
my $frenzy = seeded();
$frenzy->collect_golden( 'click_frenzy', 1000 );
is( $frenzy->state->{resources}{clickPower}, 7, 'click frenzy x7' );
$frenzy->tick( 15, 16000 );
is( $frenzy->state->{resources}{clickPower}, 1, 'click frenzy expires at deadline' );

my $bosses = $plain->bosses;
for my $points ( 0, 100, 700, 5000 ) {
    for my $index ( 0 .. $#$bosses ) {
        my @defeated = map { $_->{id} } @$bosses[ 0 .. $index - 1 ];
        @defeated = () unless $index;
        my $boss    = $bosses->[$index];
        my $fighter = seeded(
            resources => {
                bufos          => 50,
                totalBufos     => $boss->{threshold},
                baseClickPower => $boss->{baseHealth} / 100
            },
            prestige =>
              { points => $points, lifetimePoints => $points, transcendences => $points ? 1 : 0 },
            bosses => { defeated => \@defeated, lifetimeDefeats => 7 }
        );
        ok( $fighter->start_boss(1000)->{ok}, "boss $index starts at prestige $points" );
        cmp_ok(
            abs(
                $fighter->active_boss->{maxHealth} - 100 * $fighter->state->{resources}{clickPower}
            ),
            '<', 1.01,
            "boss $index normalizes passive power within HP rounding at $points points"
        );
        $fighter->collect_golden( 'click_frenzy', 1000 );
        my $clicks = 0;
        while ( $fighter->active_boss && $clicks < 100 ) { $fighter->hit_boss(1000); $clicks++; }
        is( $clicks, 15, 'click frenzy remains an advantage against boss' );
        is( $fighter->state->{resources}{bufos},      50, 'boss hits earn no ordinary income' );
        is( $fighter->state->{resources}{clickCount}, 15, 'boss hits count toward clicks' );
        ok( $fighter->state->{achievements}{customEvents}{ 'boss_' . $boss->{id} },
            'boss win latches milestone' );
    }
}
my $fight = seeded( resources => { bufos => 400, totalBufos => 10000 } );
$fight->start_boss(1000);
ok( !$fight->click(1001)->{ok}, 'ordinary clicks blocked during fight' );
$fight->tick( 5, 6000 );
$fight->pause(6000);
is( $fight->active_boss->{remainingMs}, 25000, 'boss clock pauses with 25 seconds left' );
$fight->tick( 100, 106000 );
is( $fight->active_boss->{remainingMs}, 25000, 'background ticks do not advance fight' );
$fight->resume(106000);
$fight->tick( 1, 107000 );
is( $fight->active_boss->{remainingMs}, 24000, 'boss resumes remaining countdown' );
$fight->retreat_boss;
is( $fight->state->{resources}{bufos}, 400, 'retreat has no penalty' );
$fight->start_boss(107000);
$fight->tick( 30, 137000 );
is( $fight->state->{resources}{bufos},      0,     'timeout clears bank only' );
is( $fight->state->{resources}{totalBufos}, 10000, 'timeout preserves total' );
ok( grep( $_->{type} eq 'boss_lost', @{ $fight->drain_events } ), 'timeout emits result' );

my $prestige = Bufo::Game->new(
    catalog => $catalog,
    now     => 1000,
    state   => {
        resources    => { bufos => 100, totalBufos => 1e11, clickCount => 12 },
        achievements => {
            unlocked     => [ 'first_bufo', 'bufos_1000' ],
            customEvents => { golden_bufo_caught => 1 }
        },
        bosses     => { defeated  => ['furious_froglet'], lifetimeDefeats => 7 },
        generators => { tadpole   => { count => 10, unlocked => 1 } },
        upgrades   => { purchased => ['stronger_clicks_1'] },
    }
);
is( $prestige->pending_prestige, 10, 'prestige square-root curve' );
my $ascended = $prestige->prestige;
is( $ascended->{gained}, 10, 'prestige banks points' );
is( $prestige->state->{resources}{bufos},
    0, 'transcend clears bank without replaying bufo bonuses' );
is( $prestige->state->{resources}{totalBufos},      0,  'transcend clears run total' );
is( $prestige->state->{resources}{clickCount},      12, 'transcend preserves clicks' );
is( $prestige->state->{generators}{tadpole}{count}, 0,  'transcend clears generator count' );
is_deeply( $prestige->state->{upgrades}{purchased}, [], 'transcend clears upgrades' );
is( $prestige->state->{bosses}{lifetimeDefeats}, 8, 'boss defeats banked permanently' );
is_deeply( $prestige->state->{bosses}{defeated}, [], 'boss ladder reopens' );
cmp_ok( $prestige->state->{resources}{clickMultiplier},
    '>=', 1.1, 'achievement click effects survive prestige' );
my $reloaded = Bufo::Game->new( catalog => $catalog, now => 1000, state => $prestige->state );
near(
    $reloaded->state->{resources}{clickPower},
    $prestige->state->{resources}{clickPower},
    'prestige effects stable across reload'
);
is( $reloaded->state->{resources}{bufos}, 0, 'reload never replays one-time awards' );
my $offline = seeded( generators => { tadpole => { count => 10, unlocked => 1 } } );
$offline->collect_golden( 'bufo_frenzy', 1000 );
$offline->pause(1000);
my $credit = $offline->credit_elapsed( 43200, 43201000 );
is( $credit->{production}, 43200, 'offline credit uses permanent production' );
ok( !$offline->credit_elapsed( 43201, 86402000 )->{ok}, 'offline over cap rejected' );
$offline->resume(43201000);
$offline->tick( 1, 43202000 );
is( $offline->state->{resources}{bufos}, 43201, 'resume credits no duplicate offline production' );
is( $offline->active_frenzies(43202000)->{production}, undef, 'pause clears frenzy' );
my $console = Bufo::Game->new( catalog => $catalog, now => 1000 );
$console->trigger_custom_event('console_opened');
my $bonus_bank = $console->state->{resources}{bufos};
$console->trigger_custom_event('console_opened');
is( $console->state->{resources}{bufos}, $bonus_bank, 'console reward happens once' );
ok( $console->trigger_custom_event('invented')->{ok}, 'custom event API retains developer milestones' );
my $settings = seeded();
$settings->set_auto_save(0);
$settings->mark_saved(1234);
is( $settings->state->{gameSettings}{autoSave},  0,    'autosave preference stored' );
is( $settings->state->{gameSettings}{lastSaved}, 1234, 'successful save timestamp recorded' );

my $global = seeded(
    resources => { bufos => 10000, totalBufos => 10000 },
    generators => { tadpole => { count => 10, unlocked => 1 } },
);
ok($global->buy_upgrade('global_production_1')->{ok}, 'global production upgrade purchased');
near($global->production, 1.5, 'global upgrade boosts production');
is($global->state->{resources}{clickPower}, 1, 'global upgrade never boosts click power');

my $invalid = seeded();
my $invalid_before = JSON::PP->new->canonical->encode($invalid->state);
for my $call (
    sub { $invalid->collect_golden('made_up', 2000) },
    sub { $invalid->collect_golden('lucky', -1) },
    sub { $invalid->click(-1) },
    sub { $invalid->tick(-1, 2000) },
    sub { $invalid->hit_boss(2000) },
) {
    ok(!$call->()->{ok}, 'invalid action rejected');
    is(JSON::PP->new->canonical->encode($invalid->state), $invalid_before,
       'invalid action leaves durable state unchanged');
}
ok(!eval { $invalid->golden_outcome(1); 1 }, 'golden roll upper bound rejected');
ok(!eval { $invalid->golden_outcome(-0.1); 1 }, 'negative golden roll rejected');

my $large = seeded(resources => {bufos => 1e30, totalBufos => 1e30},
    generators => {singularity_bufo => {count => 1, unlocked => 1}});
cmp_ok($large->generator_cost('singularity_bufo', 1), '>', 2147483647,
       'late-game prices retain values above 32-bit integer range');
ok($large->buy_generator('singularity_bufo', 1)->{ok}, 'large purchase succeeds');
cmp_ok($large->production, '>', 2147483647, 'large production retained');
cmp_ok($large->pending_prestige, '>', 2147483647, 'large prestige award retained');

done_testing;
