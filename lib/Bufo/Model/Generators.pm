package Bufo::Model::Generators;
use strict;
use warnings;
use JSON::PP ();
sub _clone               { JSON::PP::decode_json( JSON::PP::encode_json( $_[0] ) ) }
sub _ceil                { my $n = 0 + sprintf( '%.0f', $_[0] ); $n < $_[0] ? $n + 1 : $n }
sub _floor               { my $n = 0 + sprintf( '%.0f', $_[0] ); $n > $_[0] ? $n - 1 : $n }
sub initializeGenerators { my ( $class, $catalog ) = @_; _clone( $catalog->generators ) }
sub updateGenerator      { my ( $class, $g, $updates ) = @_; return { %$g, %$updates }; }

sub recalculateGenerator {
    my ( $class, $g, $global, $additional ) = @_;
    my $boost = 1;
    $boost *= $_->{multiplier}
      for grep { $_->{active} } ( @{ $g->{boosts} }, @{ $additional // [] } );
    my $unit = $g->{baseProduction} * $boost * $global;
    return {
        %$g,
        currentProduction => $unit,
        totalProduction   => $unit * $g->{count},
        currentCost       => $g->{count}
        ? _ceil( $g->{baseCost} * $g->{costMultiplier}**$g->{count} )
        : $g->{baseCost}
    };
}

sub checkGeneratorUnlock {
    my ( $class, $g, $total, $owned, $achievements, $special ) = @_;
    return 1 if $g->{unlocked};
    $achievements //= {};
    $special      //= {};
    for my $r ( @{ $g->{unlockRequirements} } ) {
        my ( $type, $target ) = @$r{qw(type target)};
        return 0 if $type eq 'bufos' && $total < $r->{value};
        next unless $target;
        return 0 if $type eq 'generators'  && ( $owned->{$target} // 0 ) < $r->{value};
        return 0 if $type eq 'achievement' && !$achievements->{$target};
        return 0 if $type eq 'special'     && !$special->{$target};
    }
    return 1;
}

sub unlockGenerator {
    my ( $class, $g, @args ) = @_;
    return $class->checkGeneratorUnlock( $g, @args ) ? { %$g, unlocked => 1 } : $g;
}

sub calculateTotalProduction {
    my ( $class, $generators ) = @_;
    my $sum = 0;
    $sum += $_->{totalProduction} for values %$generators;
    return $sum;
}

sub calculateBulkCost {
    my ( $class, $g, $quantity ) = @_;
    return $g->{currentCost} if $quantity == 1;
    my $r = $g->{costMultiplier};
    return _ceil( $g->{currentCost} * $quantity ) if $r == 1;
    return _ceil( $g->{currentCost} * ( $r**$quantity - 1 ) / ( $r - 1 ) );
}

sub canAffordGenerator {
    my ( $class, $g, $bank, $q ) = @_;
    $q //= 1;
    return $bank >= $class->calculateBulkCost( $g, $q );
}

sub calculateMaxAffordable {
    my ( $class, $g, $bank ) = @_;
    return 0 if $bank < $g->{currentCost};
    my $r = $g->{costMultiplier};
    return _floor( $bank / $g->{currentCost} ) if $r == 1;
    my $n = _floor( log( 1 + $bank * ( $r - 1 ) / $g->{currentCost} ) / log($r) );
    $n-- while $n > 0 && $class->calculateBulkCost( $g, $n ) > $bank;
    $n++ if $class->calculateBulkCost( $g, $n + 1 ) <= $bank;
    return $n > 0 ? $n : 0;
}

sub createGenerator {
    my (
        $class,  $id,           $name,     $description, $production, $cost,
        $growth, $requirements, $category, $icon,        $detail
    ) = @_;
    $requirements //= [ { type => 'bufos', value => 0 } ];
    my $g = {
        id                 => $id,
        name               => $name,
        description        => $description,
        category           => $category // 'basic',
        count              => 0,
        baseProduction     => $production,
        currentProduction  => $production,
        totalProduction    => 0,
        baseCost           => $cost,
        currentCost        => $cost,
        costMultiplier     => $growth,
        unlockRequirements => $requirements,
        unlocked           => @$requirements == 1
          && $requirements->[0]{type} eq 'bufos'
          && $requirements->[0]{value} == 0 ? 1 : 0,
        enabled => 1,
        boosts  => []
    };
    $g->{iconPath}            = $icon   if defined $icon;
    $g->{detailedDescription} = $detail if defined $detail;
    return $g;
}

sub applyBoostToGenerator {
    my ( $class, $g, $id, $multiplier, $source, $active ) = @_;
    $active = 1 unless defined $active;
    my $copy = { %$g, boosts => _clone( $g->{boosts} ) };
    for my $b ( @{ $copy->{boosts} } ) {
        if ( $b->{id} eq $id ) {
            @$b{qw(multiplier active)} = ( $multiplier, $active );
            return $copy;
        }
    }
    push @{ $copy->{boosts} },
      { id => $id, multiplier => $multiplier, source => $source, active => $active };
    return $copy;
}

sub toggleBoost {
    my ( $class, $g, $id, $active ) = @_;
    my $copy = { %$g, boosts => _clone( $g->{boosts} ) };
    for my $b ( @{ $copy->{boosts} } ) { $b->{active} = $active if $b->{id} eq $id; }
    return $copy;
}

sub GeneratorType {
    return {
        Tadpole         => 'tadpole',
        Froglet         => 'froglet',
        Bufo            => 'bufo',
        GiantBufo       => 'giant_bufo',
        ChromaticBufo   => 'chromatic_bufo',
        CanopyBufo      => 'canopy_bufo',
        ProsperityBufo  => 'prosperity_bufo',
        GoldenBufo      => 'golden_bufo',
        CosmicBufo      => 'cosmic_bufo',
        AncientBufo     => 'ancient_bufo',
        QuantumBufo     => 'quantum_bufo',
        NebulaBufo      => 'nebula_bufo',
        OmegaBufo       => 'omega_bufo',
        SingularityBufo => 'singularity_bufo'
    };
}
sub GeneratorCategory { return { Basic => 'basic', Premium => 'premium', Special => 'special' }; }

sub UnlockType {
    return {
        Bufos       => 'bufos',
        Generators  => 'generators',
        Achievement => 'achievement',
        Special     => 'special'
    };
}
1;
