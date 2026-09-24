package Bufo::ExplorerModel;
use strict;
use warnings;
use JSON::PP    ();
use Time::HiRes ();

sub _clone { JSON::PP::decode_json( JSON::PP::encode_json( $_[0] ) ) }
sub _now   { defined( $_[0] ) ? $_[0] : Time::HiRes::time() * 1000 }

sub _random {
    my $rng = $_[0] || sub { rand() };
    return $rng->();
}
sub _min { $_[0] < $_[1] ? $_[0] : $_[1] }
sub _max { $_[0] > $_[1] ? $_[0] : $_[1] }

sub _floor {
    my $rounded = 0 + sprintf( '%.0f', $_[0] );
    return $rounded > $_[0] ? $rounded - 1 : $rounded;
}

sub _ceil {
    my $rounded = 0 + sprintf( '%.0f', $_[0] );
    return $rounded < $_[0] ? $rounded + 1 : $rounded;
}
sub _round { _floor( $_[0] + 0.5 ) }

sub states {
    return {
        Idle      => 'idle',
        Exploring => 'exploring',
        Fighting  => 'fighting',
        Resting   => 'resting',
        Injured   => 'injured'
    };
}

sub default_data {
    my ( $class, %args ) = @_;
    my %stats;
    for
      my $spec ( [ 'attack', 10, 2 ], [ 'defense', 5, 1.5 ], [ 'speed', 8, 1.2 ], [ 'luck', 5, 1 ] )
    {
        $stats{ $spec->[0] } = {
            value       => $spec->[1],
            growthRate  => $spec->[2],
            level       => 1,
            upgradeCost => 50,
            multiplier  => 1
        };
    }
    return {
        name                  => 'Explorer Frog',
        level                 => 1,
        experience            => 0,
        experienceToNextLevel => 100,
        state                 => 'idle',
        stateStartTime        => _now( $args{now} ),
        health                => 100,
        maxHealth             => 100,
        %stats,
        equipment                  => { weapon => undef, armor => undef, accessory => undef },
        explorationProgress        => 0,
        currentArea                => 'Pond',
        explorationsCompleted      => 0,
        lifetimeBufosFromExploring => 0
    };
}

sub _number {
    my ( $value, $label, $minimum, $integer ) = @_;
    die "Invalid explorer $label\n" if !defined($value) || ref($value);
    my $encoded = JSON::PP->new->allow_nonref->encode($value);
    die "Invalid explorer $label\n"
      unless $encoded =~ /\A-?(?:0|[1-9][0-9]*)(?:\.[0-9]+)?(?:[eE][+-]?[0-9]+)?\z/
      && $value >= $minimum
      && $value <= 1e200;
    die "Invalid explorer integer $label\n"
      if $integer && ( $value > 9007199254740991 || _floor($value) != $value );
    return 0 + $value;
}

# Restoration validates the stored values without healing, leveling, or recalculating them.
sub normalize {
    my ( $class, $raw, %args ) = @_;
    return $class->default_data(%args) unless defined $raw;
    die "Invalid explorer object\n"    unless ref($raw) eq 'HASH';
    my $result = $class->default_data(%args);
    for my $key (qw(name currentArea state)) {
        next                          unless exists $raw->{$key};
        die "Invalid explorer $key\n" unless defined( $raw->{$key} ) && !ref( $raw->{$key} );
        $result->{$key} = "$raw->{$key}";
    }
    die "Invalid explorer state\n"
      unless grep { $_ eq $result->{state} } values %{ $class->states };
    for my $key (
        qw(level experience experienceToNextLevel stateStartTime health maxHealth explorationProgress explorationsCompleted lifetimeBufosFromExploring)
      )
    {
        next unless exists $raw->{$key};
        my $minimum = $key eq 'level' ? 1 : 0;
        my $integer = $key =~ /\A(?:level|explorationsCompleted)\z/;
        $result->{$key} = _number( $raw->{$key}, $key, $minimum, $integer );
    }
    die "Invalid explorer health or experience threshold\n"
      unless $result->{maxHealth} > 0
      && $result->{health} <= $result->{maxHealth}
      && $result->{experienceToNextLevel} > 0;
    die "Invalid explorer progress\n" if $result->{explorationProgress} > 100;
    for my $stat (qw(attack defense speed luck)) {
        next                                  unless exists $raw->{$stat};
        die "Invalid explorer $stat object\n" unless ref( $raw->{$stat} ) eq 'HASH';
        for my $field (qw(value level growthRate upgradeCost multiplier)) {
            next unless exists $raw->{$stat}{$field};
            $result->{$stat}{$field} = _number(
                $raw->{$stat}{$field},     "$stat.$field",
                $field eq 'level' ? 1 : 0, $field eq 'level'
            );
        }
    }
    if ( exists $raw->{equipment} ) {
        die "Invalid explorer equipment\n" unless ref( $raw->{equipment} ) eq 'HASH';
        for my $slot (qw(weapon armor accessory)) {
            next unless exists $raw->{equipment}{$slot};
            die "Invalid explorer equipment $slot\n" if ref( $raw->{equipment}{$slot} );
            $result->{equipment}{$slot} =
              defined( $raw->{equipment}{$slot} ) ? "$raw->{equipment}{$slot}" : undef;
        }
    }
    for my $stat (qw(attack defense speed luck)) {
        _number($result->{$stat}{value} * $result->{$stat}{multiplier},
            "effective $stat", 0, 0);
    }
    _number($class->calculateDPS($result), 'derived DPS', 0, 0);
    _number($class->calculatePowerRating($result), 'derived power rating', 0, 0);
    return $result;
}

sub calculateDPS {
    my ( $class, $e ) = @_;
    return $e->{attack}{value} *
      $e->{attack}{multiplier} * _max( 0.5, $e->{speed}{value} * $e->{speed}{multiplier} / 20 );
}

sub calculateSurvivalTime {
    my ( $class, $e ) = @_;
    my $dps = ( 5 + $e->{level} * 2 ) *
      ( 1 - _min( 0.8, $e->{defense}{value} * $e->{defense}{multiplier} / 100 ) );
    return $dps <= 0 ? 999 : $e->{health} / $dps;
}

sub calculatePowerRating {
    my ( $class, $e ) = @_;
    return _floor( $class->calculateDPS($e) * $class->calculateSurvivalTime($e) / 10 +
          sqrt( $e->{luck}{value} * $e->{luck}{multiplier} ) );
}

sub calculateAreaEffectiveness {
    my ( $class, $e, $level ) = @_;
    return _min( 1, $class->calculatePowerRating($e) / ( $level * 25 ) );
}

sub calculateStatUpgradeCost {
    my ( $class, $level, $base ) = @_;
    $base = 50 unless defined $base;
    return _floor( $base * 1.15**( $level - 1 ) );
}

sub recalculateExplorerStats {
    my ( $class, $e ) = @_;
    my $new = _clone($e);
    $new->{maxHealth}             = 100 + ( $e->{level} - 1 ) * 20 + $e->{defense}{level} * 10;
    $new->{health}                = _min( $e->{health}, $new->{maxHealth} );
    $new->{experienceToNextLevel} = _ceil( 100 * 1.5**( $e->{level} - 1 ) );
    return $new;
}
sub canLevelUp { $_[1]{experience} >= $_[1]{experienceToNextLevel} }

sub levelUpExplorer {
    my ( $class, $e ) = @_;
    return $e unless $class->canLevelUp($e);
    my $new = _clone($e);
    $new->{level}++;
    $new->{experience} -= $e->{experienceToNextLevel};
    return $class->recalculateExplorerStats($new);
}

sub upgradeExplorerStat {
    my ( $class, $e, $name, $bufos ) = @_;
    return { success => 0, cost => 0, explorer => $e }
      unless defined($name) && $name =~ /\A(?:attack|defense|speed|luck)\z/;
    my $stat = $e->{$name};
    return { success => 0, cost => $stat->{upgradeCost}, explorer => $e }
      if $bufos < $stat->{upgradeCost};
    my $new = _clone($e);
    $new->{$name}{level}++;
    $new->{$name}{value} += $stat->{growthRate};
    $new->{$name}{upgradeCost} = $class->calculateStatUpgradeCost( $new->{$name}{level} );
    return {
        success  => 1,
        cost     => $stat->{upgradeCost},
        explorer => $class->recalculateExplorerStats($new)
    };
}

sub startExploration {
    my ( $class, $e, $area, %args ) = @_;
    return $e
      unless ( $e->{state} eq 'idle' || $e->{state} eq 'resting' )
      && $e->{health} >= $e->{maxHealth} * 0.2;
    return {
        %{ _clone($e) },
        state               => 'exploring',
        stateStartTime      => _now( $args{now} ),
        explorationProgress => 0,
        currentArea         => $area
    };
}

sub startCombat {
    my ( $class, $e, %args ) = @_;
    return $e unless $e->{state} eq 'exploring';
    return { %{ _clone($e) }, state => 'fighting', stateStartTime => _now( $args{now} ) };
}

sub getAreaLevel {
    my ( $class, $area ) = @_;
    my %levels = (
        Pond      => 1,
        Creek     => 2,
        Swamp     => 3,
        River     => 4,
        Lake      => 5,
        Forest    => 6,
        Mountains => 8,
        Dungeon   => 10
    );
    return $levels{$area} // 1;
}

sub calculateExplorationResult {
    my ( $class, $e, $elapsed, %args ) = @_;
    my $level    = $class->getAreaLevel( $e->{currentArea} );
    my $effect   = $class->calculateAreaEffectiveness( $e, $level );
    my $duration = $elapsed * ( 0.5 + 0.5 * $effect );
    my $survived = _random( $args{random} ) < ( $e->{health} / $e->{maxHealth} ) * $effect;
    my $base     = $level * 50 * $effect * ( $duration / 60 );
    my $xp       = $level * 10 * ( $duration / 60 );
    return {
        survived    => $survived ? 1 : 0,
        duration    => $duration,
        bufosGained => _floor(
              $survived
            ? $base * ( 1 + $e->{luck}{value} * $e->{luck}{multiplier} / 100 )
            : $base * 0.3
        ),
        experienceGained => _floor( $survived ? $xp : $xp * 0.5 ),
        itemsFound       => []
    };
}

sub completeExploration {
    my ( $class, $e, $result, %args ) = @_;
    my $new = _clone($e);
    $new->{health} =
      _max( 1, $e->{health} - $e->{maxHealth} * ( $result->{survived} ? 0.1 : 0.4 ) );
    $new->{state}          = $new->{health} < $e->{maxHealth} * 0.2 ? 'injured' : 'resting';
    $new->{stateStartTime} = _now( $args{now} );
    $new->{experience} += $result->{experienceGained};
    $new->{explorationsCompleted}++;
    $new->{lifetimeBufosFromExploring} += $result->{bufosGained};
    $new->{explorationProgress} = 0;
    return $class->levelUpExplorer($new);
}

sub restExplorer {
    my ( $class, $e, $seconds, %args ) = @_;
    return $e unless $e->{state} eq 'resting' || $e->{state} eq 'injured';
    my $new  = _clone($e);
    my $rate = $e->{state} eq 'injured' ? 0.05 : 0.1;
    $new->{health} =
      _min( $e->{maxHealth}, $e->{health} + $e->{maxHealth} * $rate * ( $seconds / 60 ) );
    $new->{state} = 'idle' if $new->{health} >= $e->{maxHealth};
    $new->{state} = 'resting'
      if $new->{health} < $e->{maxHealth}
      && $new->{health} >= $e->{maxHealth} * 0.2
      && $e->{state} eq 'injured';
    $new->{stateStartTime} = _now( $args{now} ) if $new->{state} ne $e->{state};
    return $new;
}

sub updateExplorer {
    my ( $class, $e, $delta, %args ) = @_;
    if ( $e->{state} eq 'exploring' ) {
        my $progress = $e->{explorationProgress} + ( $delta / 60 ) * 10;
        if ( $progress >= 100 ) {
            my $result = $class->calculateExplorationResult( $e,
                ( _now( $args{now} ) - $e->{stateStartTime} ) / 1000, %args );
            return {
                explorer => $class->completeExploration( $e, $result, %args ),
                result   => $result
            };
        }
        return { explorer => { %{ _clone($e) }, explorationProgress => $progress } };
    }
    return { explorer => $class->restExplorer( $e, $delta, %args ) }
      if $e->{state} eq 'resting' || $e->{state} eq 'injured';
    return { explorer => $e };
}
1;
