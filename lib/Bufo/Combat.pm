package Bufo::Combat;
use strict;
use warnings;
use Bufo::ExplorerModel ();
use Bufo::Enemies       ();
sub statuses { return { InProgress => 'inProgress', Victory => 'victory', Defeat => 'defeat' }; }
sub action_types { return { Attack => 'attack', Defend => 'defend', Flee => 'flee' }; }

sub initializeCombat {
    my ( $class, $explorer, $enemy, %args ) = @_;
    return {
        explorer       => $explorer,
        enemy          => $enemy,
        status         => 'inProgress',
        round          => 1,
        combatLog      => ["$explorer->{name} encounters $enemy->{name}!"],
        startTime      => Bufo::ExplorerModel::_now( $args{now} ),
        lastActionTime => Bufo::ExplorerModel::_now( $args{now} )
    };
}

sub _damage {
    my ( $attack, $defense, $random, $low, $high ) = @_;
    $low  = 0.9 unless defined $low;
    $high = 1.1 unless defined $high;
    return Bufo::ExplorerModel::_round( Bufo::ExplorerModel::_max( 1, $attack - $defense * 0.5 ) *
          ( $low + Bufo::ExplorerModel::_random($random) * ( $high - $low ) ) );
}

sub _enemy_attack {
    my ( $state, $multiplier, $random ) = @_;
    $multiplier = 1 unless defined $multiplier;
    my $e      = $state->{explorer};
    my $enemy  = $state->{enemy};
    my $damage = _damage( $enemy->{attack} * $multiplier,
        $e->{defense}{value} * $e->{defense}{multiplier}, $random );
    $e->{health} = Bufo::ExplorerModel::_max( 0, $e->{health} - $damage );
    push @{ $state->{combatLog} }, "$enemy->{name} attacks $e->{name} for $damage damage!";
    return $damage;
}

sub executeCombatAction {
    my ( $class, $state, $action, %args ) = @_;
    my $new = {
        %$state,
        explorer       => { %{ $state->{explorer} } },
        enemy          => { %{ $state->{enemy} } },
        round          => $state->{round} + 1,
        lastActionTime => Bufo::ExplorerModel::_now( $args{now} )
    };
    my $e     = $state->{explorer};
    my $enemy = $state->{enemy};
    my ( $to_enemy, $to_explorer, $message ) = ( 0, 0, '' );
    if ( $action eq 'attack' ) {
        $to_enemy = _damage( $e->{attack}{value} * $e->{attack}{multiplier},
            $enemy->{defense}, $args{random}, 0.8, 1.2 );
        $new->{enemy}{health} = Bufo::ExplorerModel::_max( 0, $enemy->{health} - $to_enemy );
        $message = "$e->{name} attacks $enemy->{name} for $to_enemy damage!";
        push @{ $new->{combatLog} }, $message;
        if ( $new->{enemy}{health} <= 0 ) {
            $new->{status} = 'victory';
            push @{ $new->{combatLog} }, "$enemy->{name} is defeated!";
            my $rewards = Bufo::Enemies->calculateEnemyRewards( $enemy, random => $args{random} );
            push @{ $new->{combatLog} },
              "Gained $rewards->{bufos} bufos and $rewards->{experience} experience!";
            push @{ $new->{combatLog} },
              'Found items: ' . join( ', ', @{ $rewards->{drops} } ) . '!'
              if @{ $rewards->{drops} };
            return {
                newState         => $new,
                damageToEnemy    => $to_enemy,
                damageToExplorer => 0,
                actionMessage    => $message,
                rewards          => $rewards
            };
        }
        $to_explorer = _enemy_attack( $new, 1, $args{random} );
    } elsif ( $action eq 'defend' ) {
        $to_explorer = _enemy_attack( $new, 0.5, $args{random} );
        $message     = "$e->{name} defends against $enemy->{name}'s attack!";
        push @{ $new->{combatLog} }, $message;
    } elsif ( $action eq 'flee' ) {
        my $chance = Bufo::ExplorerModel::_min( 0.75,
            0.5 + ( $e->{speed}{value} * $e->{speed}{multiplier} - $enemy->{speed} ) / 20 );
        if ( Bufo::ExplorerModel::_random( $args{random} ) < $chance ) {
            $message = "$e->{name} successfully fled from the battle!";
            push @{ $new->{combatLog} }, $message;
            $new->{status} = 'defeat';
            return {
                newState         => $new,
                damageToEnemy    => 0,
                damageToExplorer => 0,
                actionMessage    => $message
            };
        }
        $message = "$e->{name} failed to escape!";
        push @{ $new->{combatLog} }, $message;
        $to_explorer = _enemy_attack( $new, 1.2, $args{random} );
    }
    if ( $new->{explorer}{health} <= 0 ) {
        $new->{status} = 'defeat';
        push @{ $new->{combatLog} }, "$e->{name} has been defeated!";
    }
    return {
        newState         => $new,
        damageToEnemy    => $to_enemy,
        damageToExplorer => $to_explorer,
        actionMessage    => $message
    };
}

sub simulateCombat {
    my ( $class, $explorer, $enemy, $rounds, %args ) = @_;
    $rounds = 10 unless defined $rounds;
    my $e     = Bufo::ExplorerModel::_clone($explorer);
    my $foe   = Bufo::ExplorerModel::_clone($enemy);
    my $round = 0;
    while ( $round < $rounds && $e->{health} > 0 && $foe->{health} > 0 ) {
        $round++;
        my $damage =
          _damage( $e->{attack}{value} * $e->{attack}{multiplier}, $foe->{defense}, $args{random} );
        $foe->{health} = Bufo::ExplorerModel::_max( 0, $foe->{health} - $damage );
        last if $foe->{health} <= 0;
        $damage = _damage( $foe->{attack}, $e->{defense}{value} * $e->{defense}{multiplier},
            $args{random} );
        $e->{health} = Bufo::ExplorerModel::_max( 0, $e->{health} - $damage );
    }
    my $victory = $foe->{health} <= 0;
    my $reward =
      $victory
      ? Bufo::Enemies->calculateEnemyRewards( $enemy, random => $args{random} )
      : { bufos => 0, experience => 0, drops => [] };
    return {
        victory                 => $victory ? 1 : 0,
        explorerRemainingHealth => $e->{health},
        experienceGained        => $reward->{experience},
        bufosGained             => $reward->{bufos},
        itemsFound              => $reward->{drops},
        rounds                  => $round
    };
}
1;
