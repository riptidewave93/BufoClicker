package Bufo::Managers::Generators;
use strict;
use warnings;
use Bufo::Util::General     ();
use Bufo::Model::Generators ();
sub new    { my ( $class, %args ) = @_; bless \%args, $class }
sub _game  { $_[0]{game}->() }
sub _clone { Bufo::Util::General::deepClone( $_[0] ) }

sub recalculateGenerator {
    my ( $self, $id ) = @_;
    my $game = $self->_game;
    my $g    = $game->state->{generators}{$id};
    return undef unless $g;
    my $r   = $game->state->{resources};
    my $new = Bufo::Model::Generators->recalculateGenerator( $g,
        $r->{productionMultiplier} *
          $game->prestige_multiplier *
          $game->boss_multiplier *
          ( $r->{frenzyProductionMultiplier} // 1 ) );
    $game->state->{generators}{$id} = $new;
    $game->{production} =
      Bufo::Model::Generators->calculateTotalProduction( $game->state->{generators} );
    $game->notify_state_change;
    return _clone($new);
}

sub recalculateAllGenerators {
    my $self = shift;
    $self->recalculateGenerator($_) for keys %{ $self->_game->state->{generators} };
    $self->_game->emit( 'GENERATOR_PRODUCTION_UPDATED',
        { totalProduction => $self->calculateTotalProduction } );
}

sub checkUnlocks {
    my ( $self, $total ) = @_;
    my $game  = $self->_game;
    my $all   = $game->state->{generators};
    my %owned = map { $_ => $all->{$_}{count} } keys %$all;
    my @new;
    for my $id ( sort keys %$all ) {
        my $g = $all->{$id};
        if ( !$g->{unlocked}
            && Bufo::Model::Generators->checkGeneratorUnlock( $g, $total, \%owned ) )
        {
            $g->{unlocked} = 1;
            push @new, _clone($g);
            $game->emit( 'GENERATOR_UNLOCKED', { generator => _clone($g) } );
        }
    }
    $self->recalculateAllGenerators;
    $game->emit( 'refreshUI', { force => 1 } ) if @new;
    return \@new;
}

# Managers update ownership; the public Game facade spends the returned cost once.
sub purchaseGenerator {
    my ( $self, $id, $quantity, $bank ) = @_;
    my $game = $self->_game;
    my $g    = $game->state->{generators}{$id};
    my $failed =
      { success => 0, cost => 0, generator => $g ? _clone($g) : undef, productionIncrease => 0 };
    return $failed unless $g && $g->{unlocked} && $g->{enabled};
    $quantity = $self->getMaxAffordable( $id, $bank ) if $quantity == -1;
    return $failed unless $quantity > 0 && $quantity == int($quantity);
    my $cost = Bufo::Model::Generators->calculateBulkCost( $g, $quantity );
    return $failed unless $cost <= $bank;
    my $old = $g->{totalProduction};
    $g->{count} += $quantity;
    my $final = $self->recalculateGenerator($id);
    $game->emit( 'GENERATOR_PURCHASED',
        { generator => $final, quantity => $quantity, cost => $cost } );
    $game->emit( 'GENERATOR_PRODUCTION_UPDATED',
        { totalProduction => $self->calculateTotalProduction } );
    return {
        success            => 1,
        cost               => $cost,
        generator          => $final,
        productionIncrease => $final->{totalProduction} - $old
    };
}

sub getMaxAffordable {
    my ( $self, $id, $bank ) = @_;
    my $g = $self->_game->state->{generators}{$id};
    return 0 unless $g && $g->{unlocked} && $g->{enabled};
    return Bufo::Model::Generators->calculateMaxAffordable( $g, $bank );
}

sub calculateTotalProduction {
    Bufo::Model::Generators->calculateTotalProduction( $_[0]->_game->state->{generators} );
}

sub calculateProductionForTime {
    my ( $self, $seconds, $multiplier ) = @_;
    $multiplier //= 1;
    $self->calculateTotalProduction * $seconds * $multiplier;
}

sub getProductionStats {
    my $self = shift;
    my $rate = $self->calculateTotalProduction;
    return {
        totalPerSecond         => $rate,
        totalPerMinute         => $rate * 60,
        totalPerHour           => $rate * 3600,
        activeBonusMultiplier  => $self->_game->state->{resources}{productionMultiplier},
        generatorContributions => [
            map {
                {
                    id         => $_->{id},
                    name       => $_->{name},
                    count      => $_->{count},
                    production => $_->{totalProduction},
                    percentage => $rate ? 100 * $_->{totalProduction} / $rate : 0
                }
              }
              grep { $_->{count} > 0 && $_->{totalProduction} > 0 } @{ $self->getAllGenerators }
        ]
    };
}

sub applyBoostToGenerator {
    my ( $self, $id, $boost, $multiplier, $source, $active ) = @_;
    $active = 1 unless defined $active;
    my $game = $self->_game;
    my $g    = $game->state->{generators}{$id};
    return unless $g;
    $game->state->{generators}{$id} =
      Bufo::Model::Generators->applyBoostToGenerator( $g, $boost, $multiplier, $source, $active );
    my $updated = $self->recalculateGenerator($id);
    $game->emit( 'GENERATOR_PRODUCTION_UPDATED',
        { totalProduction => $self->calculateTotalProduction } );
    $game->emit( 'BOOST_CHANGED', { generator => $updated, boostId => $boost, active => $active } );
}

sub toggleGeneratorBoost {
    my ( $self, $id, $boost, $active ) = @_;
    my $game = $self->_game;
    my $g    = $game->state->{generators}{$id};
    return unless $g;
    $game->state->{generators}{$id} = Bufo::Model::Generators->toggleBoost( $g, $boost, $active );
    my $updated = $self->recalculateGenerator($id);
    $game->emit( 'GENERATOR_PRODUCTION_UPDATED',
        { totalProduction => $self->calculateTotalProduction } );
    $game->emit( 'BOOST_CHANGED', { generator => $updated, boostId => $boost, active => $active } );
}

sub getAllGenerators {
    my $all = $_[0]->_game->state->{generators};
    return _clone(
        [ map { $all->{$_} } sort { $all->{$a}{baseCost} <=> $all->{$b}{baseCost} } keys %$all ] );
}

sub getUnlockedGenerators {
    [ grep { $_->{unlocked} } @{ $_[0]->getAllGenerators } ]
}
sub reset { $_[0]->recalculateAllGenerators }
1;
