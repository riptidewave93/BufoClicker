use strict;
use warnings;
use Test::More;
use JSON::PP qw(decode_json);
use lib 'lib';
use Bufo::Catalog;
use Bufo::Game;
use Bufo::Core::StateManager;
use Bufo::Util::General;
sub data { open my $f, '<', "assets/data/$_[0].json" or die $!; local $/; decode_json(<$f>) }
my $catalog = Bufo::Catalog->new( map { $_ => data($_) } qw(generators upgrades achievements) );
sub fresh    { Bufo::Game->new( catalog => $catalog, now => 1000 ) }
sub close_to { cmp_ok( abs( $_[0] - $_[1] ), '<', 1e-10, $_[2] ) }
my $earned = fresh();
$earned->click(1000);
my $target = fresh();
$target->replace_state( $earned->state );
$target->refresh;
close_to( $target->state->{resources}{clickMultiplier},
    1.1, 'loading earned state does not apply achievement twice' );
$target->replace_state( fresh()->state );
$target->refresh;
close_to( $target->state->{resources}{clickMultiplier},
    1, 'loading fresh state does not divide by obsolete achievement boost' );

my $upgraded = Bufo::Game->new(
    catalog => $catalog,
    now     => 1000,
    state   => {
        generators   => { tadpole   => { count => 10 } },
        upgrades     => { purchased => [ 'stronger_clicks_1', 'global_production_1' ] },
        achievements => { unlocked  => [ 'first_bufo',        '10_generators' ] }
    }
);
my $incoming = Bufo::Util::General::deepClone( $upgraded->state );
$incoming->{resources}{clickMultiplier}      *= 3;
$incoming->{resources}{productionMultiplier} *= 4;
my $expected_click      = $incoming->{resources}{clickMultiplier};
my $expected_production = $incoming->{resources}{productionMultiplier};
my $observer_events     = 0;
$target->set_state_observer( sub { $observer_events++ } );
$target->replace_state($incoming);
is( $observer_events, 0,
    'replacement does not emit events before owning StateManager notification' );
$target->refresh;
close_to( $target->state->{resources}{clickMultiplier},
    $expected_click, 'replacement retains custom click factor on top of incoming durable boosts' );
close_to( $target->state->{resources}{productionMultiplier},
    $expected_production,
    'replacement retains custom production factor on top of incoming upgrade' );
close_to( $target->production, $expected_production,
    'production uses restored custom and durable factors once' );
$target->refresh;
close_to( $target->state->{resources}{clickMultiplier},
    $expected_click, 'repeated refresh preserves custom click ratio' );
close_to( $target->production, $expected_production,
    'repeated refresh preserves custom production ratio' );

my $manager = Bufo::Core::StateManager->new(
    get      => sub { $target->state },
    set      => sub { $target->replace_state( $_[0] ) },
    defaults => sub { fresh()->state },
    derive   => sub { $_[0] }
);
$manager->resetState;
$target->refresh;
close_to( $target->state->{resources}{clickMultiplier},
    1, 'StateManager reset clears permanent and custom click boosts' );
close_to( $target->state->{resources}{productionMultiplier},
    1, 'StateManager reset clears permanent and custom production boosts' );
ok( $manager->loadState($incoming), 'StateManager accepts full replacement state' );
$target->refresh;
close_to( $target->state->{resources}{clickMultiplier},
    $expected_click, 'StateManager load retains incoming click factor' );
close_to( $target->state->{resources}{productionMultiplier},
    $expected_production, 'StateManager load retains incoming production factor' );

my $custom = Bufo::Util::General::deepClone($incoming);
$custom->{upgrades}{definitions} = [
    {
        id      => 'dynamic',
        name    => 'Dynamic',
        effects => [
            { type => 'clickMultiplier',  multiplier => 5 },
            { type => 'globalMultiplier', multiplier => 7 }
        ],
        unlockConditions => []
    }
];
$custom->{upgrades}{purchased}             = ['dynamic'];
$custom->{achievements}{unlocked}          = [];
$custom->{resources}{clickMultiplier}      = 15;
$custom->{resources}{productionMultiplier} = 28;
$target->replace_state($custom);
$target->refresh;
close_to( $target->state->{resources}{clickMultiplier},
    15, 'replacement cache uses incoming custom upgrade definitions' );
close_to( $target->state->{resources}{productionMultiplier},
    28, 'incoming custom production upgrade preserves extra factor' );
done_testing;
