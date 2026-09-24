package Bufo::Model::State;
use strict;
use warnings;
use Bufo::Util::State      ();
use Bufo::Util::Validation ();

# game/gameState.ts predates achievement updates; stateUtils.ts owns that variant.
sub updateState {
    my ( $class, $current, $updates ) = @_;
    my %patch = %$updates;
    delete $patch{achievements};
    return Bufo::Util::State::updateState( $current, \%patch );
}
sub calculateDerivedState { Bufo::Util::State::calculateDerivedState( $_[1] ) }

sub default_state {
    my ( $class, %args ) = @_;
    my $state = Bufo::Util::State->new(%args)->createDefaultState;
    $state->{resources}{clickCount} = 0;
    return $state;
}

sub validateState {
    my ( $class, $s ) = @_;
    return 0 unless ref($s) eq 'HASH';
    for my $name (qw(resources generators explorer upgrades gameSettings)) {
        return 0 unless ref( $s->{$name} ) eq 'HASH';
    }
    for my $name (qw(bufos totalBufos clickPower)) {
        return 0 unless Bufo::Util::Validation::isValidNumber( $s->{resources}{$name} );
    }
    for my $name (qw(purchased available)) {
        return 0 unless ref( $s->{upgrades}{$name} ) eq 'ARRAY';
    }
    for my $name (qw(lastSaved lastTick version)) {
        return 0 unless defined( $s->{gameSettings}{$name} );
    }
    return 1;
}

sub getProductionStatistics {
    my ( $class, $s ) = @_;
    my $total = 0;
    my @rows;
    for my $id (
        sort { $s->{generators}{$a}{baseCost} <=> $s->{generators}{$b}{baseCost} }
        keys %{ $s->{generators} }
      )
    {
        my $g = $s->{generators}{$id};
        next unless $g->{count} > 0 && $g->{totalProduction} > 0;
        $total += $g->{totalProduction};
        push @rows,
          {
            id         => $g->{id},
            name       => $g->{name},
            production => $g->{totalProduction},
            percentage => 0,
            count      => $g->{count}
          };
    }
    $_->{percentage} = 100 * $_->{production} / $total for @rows;
    return {
        currentRate            => $total,
        perMinute              => $total * 60,
        perHour                => $total * 3600,
        generatorContributions => \@rows
    };
}

sub getResourceDisplay {
    my ( $class, $s ) = @_;
    my $rate = 0;
    $rate += $_->{totalProduction} for values %{ $s->{generators} };
    return {
        map( ( $_ => $s->{resources}{$_} ), qw(bufos totalBufos clickPower) ),
        productionRate => $rate
    };
}
1;
