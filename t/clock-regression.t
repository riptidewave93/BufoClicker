use strict;
use warnings;
use Test::More;
use JSON::PP qw(decode_json);
use lib 'lib';
use Bufo::Catalog;
use Bufo::Game;
use Bufo::Util::General;

sub data {
    open my $file, '<', "assets/data/$_[0].json" or die $!;
    local $/;
    return decode_json(<$file>);
}
my $catalog = Bufo::Catalog->new(
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

sub fresh {
    return Bufo::Game->new(
        catalog => $catalog,
        now     => 10000,
        state   => {
            resources  => { bufos   => 20000, totalBufos => 20000 },
            generators => { tadpole => { count => 10 } }
        }
    );
}
my $game = fresh();
my $bank = $game->state->{resources}{bufos};
ok( $game->pause(10000)->{ok}, 'hide pauses at the current wall clock' );
my $offline = $game->credit_elapsed( 0, 9000 );
ok( $offline->{ok}, 'zero elapsed credit accepts a backward wall clock' );
is( $game->state->{resources}{bufos}, $bank, 'clock rollback grants no offline income' );
ok( $game->resume(9000)->{ok}, 'show resumes even when wall clock moved backward' );
is( $game->state->{gameSettings}{lastTick}, 10000, 'accepted game timestamp stays monotonic' );
ok( $game->click(9000)->{ok}, 'click works immediately after rollback resume' );
my $before_tick = $game->state->{resources}{bufos};
my $rate        = $game->production;
ok( $game->tick( 1, 9500 )->{ok}, 'live simulation tick accepts a clock that has not caught up' );
cmp_ok( abs( $game->state->{resources}{bufos} - $before_tick - $rate ),
    '<', 1e-9, 'live tick credits only the supplied simulation duration' );
is( $game->state->{gameSettings}{lastTick}, 10000, 'rollback tick does not lower saved timestamp' );
ok( $game->click(11000)->{ok},     'click remains active after clock catches up' );
ok( $game->tick( 1, 12000 )->{ok}, 'future ticks continue after clock catches up' );
is( $game->state->{gameSettings}{lastTick}, 12000, 'clock resumes advancing normally' );
my $unchanged = Bufo::Util::General::deepClone( $game->state );
ok( !$game->credit_elapsed( 43201, 12000 )->{ok}, 'twelve-hour elapsed cap remains enforced' );
is_deeply( $game->state, $unchanged, 'rejected excessive elapsed credit changes no state' );

my $fight = fresh();
ok( fresh()->start_boss(9000)->{ok}, 'fight can start during clock rollback' );
$fight->start_boss(10000);
my $boss = Bufo::Util::General::deepClone( $fight->active_boss );
ok( $fight->pause(9000)->{ok},               'fight can pause during rollback' );
ok( $fight->credit_elapsed( 0, 8000 )->{ok}, 'paused fight accepts zero elapsed rollback' );
ok( $fight->resume(8000)->{ok},              'paused fight resumes during rollback' );
is( $fight->active_boss->{remainingMs}, $boss->{remainingMs},
    'hide and resume preserve boss time' );
is( $fight->active_boss->{health}, $boss->{health}, 'hide and resume preserve boss health' );
ok( $fight->tick( 0, 10000 )->{ok}, 'returning to original clock adds no boss time' );
is( $fight->active_boss->{remainingMs},
    $boss->{remainingMs}, 'clock recovery does not charge the rolled-back interval' );
ok( $fight->tick( 0, 11000 )->{ok}, 'future clock advances active boss timer' );
is(
    $fight->active_boss->{remainingMs},
    $boss->{remainingMs} - 1000,
    'boss timer charges only new elapsed wall time'
);
ok( $fight->hit_boss(10000)->{ok}, 'boss hit accepts a later clock rollback' );
is(
    $fight->active_boss->{remainingMs},
    $boss->{remainingMs} - 1000,
    'rollback hit cannot rewind the boss timer'
);
cmp_ok( $fight->active_boss->{health},
    '<', $boss->{health}, 'rollback hit applies damage normally' );

my $golden = fresh();
ok( $golden->collect_golden( 'click_frenzy', 9000 )->{ok}, 'golden reward accepts clock rollback' );
is( ( $golden->active_frenzies->{click} // {} )->{endsAt},
    25000, 'frenzy deadline starts at monotonic game time' );
for my $invalid ( undef, -1, 'NaN', 'Inf' ) {
    my $copy = Bufo::Util::General::deepClone( $golden->state );
    ok( !$golden->resume($invalid)->{ok}, 'invalid timestamp remains rejected' );
    is_deeply( $golden->state, $copy, 'invalid timestamp does not change state' );
}
done_testing;
