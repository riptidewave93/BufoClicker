package Bufo::Managers::Upgrades;
use strict;
use warnings;
use JSON::PP              ();
use Bufo::Model::Upgrades ();
sub new    { my ( $class, %args ) = @_; bless \%args, $class }
sub _game  { $_[0]{game}->() }
sub _clone { JSON::PP::decode_json( JSON::PP::encode_json( $_[0] ) ) }

sub initialize {
    $_[0]->_game->refresh;
    $_[0]->_game->getGeneratorManager->recalculateAllGenerators;
}

sub checkAvailableUpgrades {
    my ( $self, $state, $counts ) = @_;
    my %done      = map { $_ => 1 } @{ $self->getPurchasedUpgrades };
    my %ach       = map { $_ => 1 } @{ $state->{achievements}{unlocked} // [] };
    my @available = grep {
        !$done{ $_->{id} }
          && Bufo::Model::Upgrades->meetsUnlockConditions( $_, $state->{resources}{totalBufos},
            $counts, \%ach, $self->getPurchasedUpgrades )
    } @{ $self->getAllUpgrades };
    $self->_game->state->{upgrades}{available} = [ map { $_->{id} } @available ];
    $self->_game->emit( 'UPGRADES_AVAILABLE', { upgrades => \@available } ) if @available;
    return \@available;
}

sub purchaseUpgrade {
    my ( $self, $id, $bank ) = @_;
    my $u = $self->findUpgradeById($id);
    return { success => 0, cost => 0 } unless $u;
    return { success => 0, cost => $u->{cost} }
      if $self->isUpgradePurchased($id) || $bank < $u->{cost};
    my $state = $self->_game->state;
    push @{ $state->{upgrades}{purchased} }, $id;
    $state->{upgrades}{available} = [ grep { $_ ne $id } @{ $state->{upgrades}{available} } ];
    $self->applyUpgradeEffects($u);
    my $payload =
      { upgrade => $u, cost => $u->{cost}, effects => [ map { $_->{type} } @{ $u->{effects} } ] };
    $self->_game->emit( 'UPGRADE_PURCHASED', $payload );
    return { success => 1, %$payload };
}

sub applyUpgradeEffects {
    my ( $self, $u ) = @_;
    my $game = $self->_game;
    my $ok   = eval {
        if ( $self->isUpgradePurchased( $u->{id} ) && $game->upgrade_definition( $u->{id} ) ) {
            $game->refresh;
        } else {
            for my $e ( @{ $u->{effects} } ) {
                if ( $e->{type} eq 'clickMultiplier' ) {
                    $game->state->{resources}{clickMultiplier} *= $e->{multiplier};
                }
                elsif ( $e->{type} eq 'globalMultiplier' ) {
                    $game->state->{resources}{productionMultiplier} *= $e->{multiplier};
                }
                elsif ( $e->{type} eq 'generatorProduction' && $e->{target} ) {
                    $game->getGeneratorManager->applyBoostToGenerator( $e->{target},
                        'upgrade_' . $u->{id},
                        $e->{multiplier}, $u->{name}, 1 );
                }
            }
        }
        $game->getGeneratorManager->recalculateAllGenerators;
        $game->emit( 'GENERATOR_PRODUCTION_UPDATED',
            { totalProduction => $game->production, source => 'upgrade', upgradeId => $u->{id} } );
        1;
    };
    return $ok ? 1 : 0;
}

sub calculateTotalMultiplierForGenerator {
    my ( $self, $type ) = @_;
    my $m = 1;
    for my $id ( @{ $self->getPurchasedUpgrades } ) {
        my $u = $self->findUpgradeById($id);
        $m *= Bufo::Model::Upgrades->calculateUpgradeEffectForGenerator( $u, $type ) if $u;
    }
    return $m;
}

sub calculateTotalClickMultiplier {
    my $self = shift;
    return Bufo::Model::Upgrades->calculateClickMultiplier(
        [ grep { defined } map { $self->findUpgradeById($_) } @{ $self->getPurchasedUpgrades } ] );
}
sub reapplyAllUpgrades { $_[0]->initialize }

sub getUpgradeEffects {
    my $u = $_[0]->findUpgradeById( $_[1] );
    return $u ? [ map { $_->{type} } @{ $u->{effects} } ] : undef;
}

sub findUpgradeById {
    my ( $self, $id ) = @_;
    Bufo::Model::Upgrades->findUpgradeById( $self->getAllUpgrades, $id );
}

sub getAvailableUpgrades {
    my $self = shift;
    my %ids  = map { $_ => 1 } @{ $self->_game->state->{upgrades}{available} };
    [ grep { $ids{ $_->{id} } } @{ $self->getAllUpgrades } ];
}
sub getPurchasedUpgrades { [ @{ $_[0]->_game->state->{upgrades}{purchased} } ] }

sub isUpgradePurchased {
    my ( $self, $id ) = @_;
    return scalar( grep { $_ eq $id } @{ $self->getPurchasedUpgrades } ) ? 1 : 0;
}

sub setUpgrades {
    my ( $self, $upgrades ) = @_;
    return unless ref($upgrades) eq 'ARRAY' && @$upgrades;
    my $base   = $self->_game->catalog;
    my %merged = map { $_->{id} => $_ } @{ $base->upgrades };
    $merged{ $_->{id} } = $_ for @$upgrades;
    Bufo::Catalog->new(
        generators   => $base->generators,
        upgrades     => [ values %merged ],
        achievements => $base->achievements
    );
    $self->_game->state->{upgrades}{definitions} = _clone($upgrades);
}

sub getAllUpgrades {
    my $self = shift;
    _clone( $self->_game->state->{upgrades}{definitions} // $self->_game->catalog->upgrades );
}

# The original manager has no transient state to reset; the Game owns purchases.
sub reset { return; }
1;
