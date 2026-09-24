package Bufo::Model::Upgrades;
use strict;
use warnings;
sub initializeUpgrades { my ( $class, $catalog ) = @_; return [ @{ $catalog->upgrades } ]; }

sub findUpgradeById {
    my ( $class, $upgrades, $id ) = @_;
    return ( grep { $_->{id} eq $id } @$upgrades )[0];
}

sub meetsUnlockConditions {
    my ( $class, $upgrade, $total, $counts, $achievements, $purchased ) = @_;
    $achievements //= {};
    my %purchased = map { $_ => 1 } @{ $purchased // [] };
    for my $c ( @{ $upgrade->{unlockConditions} } ) {
        my ( $type, $target ) = @$c{qw(type target)};
        $target //= $c->{id};
        if    ( $type eq 'totalBufos' ) { return 0 if $total < $c->{value}; }
        elsif ( $type eq 'generatorCount' ) {
            return 0 if !$target || ( $counts->{$target} // 0 ) < $c->{value};
        }
        elsif ( $type eq 'achievements' ) { return 0 if !$target || !$achievements->{$target}; }
        elsif ( $type eq 'upgrade' )      { return 0 if !$target || !$purchased{$target}; }
        else                              { return 0; }
    }
    return 1;
}

sub calculateUpgradeEffectForGenerator {
    my ( $class, $upgrade, $type ) = @_;
    my $m = 1;
    for my $e ( @{ $upgrade->{effects} } ) {
        $m *= $e->{multiplier}
          if $e->{type} eq 'globalMultiplier'
          || ( $e->{type} eq 'generatorProduction' && ( $e->{target} // '' ) eq $type );
    }
    return $m;
}

sub _multiplier {
    my ( $upgrades, $type ) = @_;
    my $m = 1;
    for my $u (@$upgrades) {
        $m *= $_->{multiplier} for grep { $_->{type} eq $type } @{ $u->{effects} };
    }
    return $m;
}
sub calculateClickMultiplier  { _multiplier( $_[1], 'clickMultiplier' ) }
sub calculateGlobalMultiplier { _multiplier( $_[1], 'globalMultiplier' ) }
sub UpgradeCategory { return { Click => 'click', Generator => 'generator', Global => 'global' }; }

sub UnlockConditionType {
    return {
        TotalBufos     => 'totalBufos',
        GeneratorCount => 'generatorCount',
        Achievements   => 'achievements',
        Upgrade        => 'upgrade',
        Unknown        => 'unknown'
    };
}
1;
