package Bufo::Explorer;
use strict;
use warnings;
use Time::HiRes         ();
use Bufo::ExplorerModel ();
use Bufo::Enemies       ();
use Bufo::Combat        ();

sub new {
    my ( $class, %args ) = @_;
    die "Explorer requires shared state\n" unless ref( $args{state} ) eq 'HASH';
    return bless {
        state    => $args{state},
        now      => $args{now}    || sub { Time::HiRes::time() * 1000 },
        random   => $args{random} || sub { rand() },
        on_event => $args{on_event},
        distance => 0,
        combat   => undef,
        enemy    => undef
    }, $class;
}
sub _now { $_[0]{now}->() }

sub _emit {
    my ( $self, $name, $payload ) = @_;
    $self->{on_event}->( $name, Bufo::ExplorerModel::_clone($payload) ) if $self->{on_event};
}

# Keep the outer hash shared with Game even when a model returns a new explorer.
sub _patch { my ( $self, $patch ) = @_; @{ $self->{state} }{ keys %$patch } = values %$patch; }

sub _updated {
    my $self = shift;
    $self->_emit( 'EXPLORER_UPDATED', { explorer => $self->{state} } );
}

sub _changed {
    my ( $self, $previous ) = @_;
    $self->_emit( 'EXPLORER_STATE_CHANGED',
        { explorer => $self->{state}, previousState => $previous } );
}
sub getExplorer       { $_[0]{state} }
sub getCurrentEnemy   { $_[0]{enemy}  ? Bufo::ExplorerModel::_clone( $_[0]{enemy} )  : undef }
sub getCurrentCombat  { $_[0]{combat} ? Bufo::ExplorerModel::_clone( $_[0]{combat} ) : undef }
sub getAvailableAreas { return [qw(Pond Creek Swamp River Lake Forest Mountains Dungeon)]; }

sub getExplorerStats {
    my $self = shift;
    my $e    = $self->{state};
    return {
        powerRating   => Bufo::ExplorerModel->calculatePowerRating($e),
        dps           => Bufo::ExplorerModel->calculateDPS($e),
        survivalTime  => Bufo::ExplorerModel->calculateSurvivalTime($e),
        healthPercent => $e->{health} / $e->{maxHealth} * 100
    };
}

sub startExploration {
    my ( $self, $area ) = @_;
    my $e = $self->{state};
    return 0 unless grep { $_ eq $area } @{ $self->getAvailableAreas };
    return 0 unless $e->{state} eq 'idle' || $e->{state} eq 'resting';
    $self->{distance} = 0;
    my $previous = $e->{state};
    $self->_patch( Bufo::ExplorerModel->startExploration( $e, $area, now => $self->_now ) );
    return 0 if $previous eq $e->{state};
    $self->_changed($previous);
    $self->_emit( 'EXPLORATION_STARTED', { explorer => $e, area => $area } );
    $self->_updated;
    return 1;
}

sub update {
    my ( $self, $delta ) = @_;
    my $e = $self->{state};
    return undef if $delta <= 0;
    return undef if $e->{state} eq 'fighting' && $self->{combat};
    if ( $e->{state} ne 'exploring' ) {
        my $previous = $e->{state};
        my $result   = Bufo::ExplorerModel->updateExplorer(
            $e, $delta,
            now    => $self->_now,
            random => $self->{random}
        );
        $self->_patch( $result->{explorer} );
        $self->_changed($previous) if $previous ne $e->{state};
        $self->_updated;
        if ( $result->{result} ) {
            $self->_emit( 'EXPLORATION_COMPLETED',
                { explorer => $e, result => $result->{result} } );
            return $result->{result};
        }
        return undef;
    }
    $self->{distance} += $delta * 0.2;
    if ( $self->{random}->() < 0.05 * $delta ) { $self->_encounter; return undef; }
    if ( $self->{distance} >= 10 ) {
        my $duration = ( $self->_now - $e->{stateStartTime} ) / 1000;
        my $level    = Bufo::ExplorerModel->getAreaLevel( $e->{currentArea} );
        my $effect   = Bufo::ExplorerModel::_min( 1, $e->{level} / $level );
        my $base     = $level * 50 * $effect * ( $duration / 60 );
        my $result   = {
            survived    => 1,
            duration    => $duration,
            bufosGained => Bufo::ExplorerModel::_floor(
                $base * ( 1 + $e->{luck}{value} * $e->{luck}{multiplier} / 100 )
            ),
            experienceGained => Bufo::ExplorerModel::_floor( $level * 10 * ( $duration / 60 ) ),
            itemsFound       => []
        };
        $self->_complete($result);
        $self->{distance} = 0;
        return $result;
    }
    $self->_patch( { explorationProgress => $self->{distance} / 10 * 100 } );
    $self->_updated;
    return undef;
}

sub _encounter {
    my $self = shift;
    my $e    = $self->{state};
    return unless $e->{state} eq 'exploring';
    my $enemy = eval {
        Bufo::Enemies->generateEnemy(
            $e->{currentArea}, $self->{distance} / 10,
            Bufo::ExplorerModel->getAreaLevel( $e->{currentArea} ),
            now    => $self->_now,
            random => $self->{random}
        );
    };
    return if !$enemy;
    $self->{enemy} = $enemy;
    my $previous = $e->{state};
    my $updated  = { %{ Bufo::ExplorerModel::_clone($e) }, state => 'fighting' };
    $self->_patch($updated);
    $self->{combat} = Bufo::Combat->initializeCombat( Bufo::ExplorerModel::_clone($updated),
        $enemy, now => $self->_now );
    $self->_changed($previous);
    $self->_emit( 'ENEMY_ENCOUNTERED', { explorer => $e, enemy => $enemy } );
    $self->_updated;
}

sub _levelups {
    my $self    = shift;
    my $e       = $self->{state};
    my $changed = 0;
    while ( $e->{experience} >= $e->{experienceToNextLevel} ) {
        $changed = 1;
        my $level = $e->{level} + 1;
        $self->_patch(
            {
                level                 => $level,
                experience            => $e->{experience} - $e->{experienceToNextLevel},
                maxHealth             => $e->{maxHealth} + 20 + $e->{defense}{level} * 5,
                experienceToNextLevel => Bufo::ExplorerModel::_ceil( 100 * 1.5**( $level - 1 ) )
            }
        );
        $self->_emit( 'EXPLORER_LEVEL_UP', { explorer => $e, newLevel => $level } );
    }
    $self->_updated if $changed;
}

sub _complete {
    my ( $self, $result ) = @_;
    my $e        = $self->{state};
    my $previous = $e->{state};
    my $health   = Bufo::ExplorerModel::_max( 1, $e->{health} - $e->{maxHealth} * 0.05 );
    my $state    = $health < $e->{maxHealth} * 0.2 ? 'injured' : 'resting';
    $self->_patch(
        {
            health                     => $health,
            state                      => $state,
            stateStartTime             => $self->_now,
            experience                 => $e->{experience} + $result->{experienceGained},
            explorationsCompleted      => $e->{explorationsCompleted} + 1,
            lifetimeBufosFromExploring => $e->{lifetimeBufosFromExploring} + $result->{bufosGained},
            explorationProgress        => 0
        }
    );
    $self->_levelups;
    $self->_changed($previous) if $previous ne $state;
    $self->_emit( 'EXPLORATION_COMPLETED', { explorer => $e, result => $result } );
}

sub _finish_combat {
    my ( $self, $victory, $rewards ) = @_;
    my $e = $self->{state};
    if ( $victory && $rewards ) {
        $self->_patch(
            {
                experience                 => $e->{experience} + $rewards->{experience},
                lifetimeBufosFromExploring => $e->{lifetimeBufosFromExploring} + $rewards->{bufos}
            }
        );
        $self->_levelups;
    }
    $self->_emit(
        'COMBAT_ENDED',
        {
            explorer => $e,
            enemy    => $self->{enemy},
            victory  => $victory ? 1 : 0,
            $victory ? ( rewards => $rewards ) : ()
        }
    );
    my $previous = $e->{state};
    my $state =
        $e->{health} < $e->{maxHealth} * 0.2 ? 'injured'
      : $e->{health} < $e->{maxHealth} * 0.5 ? 'resting'
      :                                        'exploring';
    $self->_patch( { state => $state, stateStartTime => $self->_now } );
    $self->{combat} = undef;
    $self->{enemy}  = undef;
    $self->_changed($previous);
    $self->_updated;
}

sub performCombatAction {
    my ( $self, $action ) = @_;
    return 0 unless $self->{combat} && $self->{enemy} && $self->{state}{state} eq 'fighting';
    my $result = Bufo::Combat->executeCombatAction(
        $self->{combat}, $action,
        now    => $self->_now,
        random => $self->{random}
    );
    $self->{combat} = $result->{newState};
    $self->_patch( { health => $self->{combat}{explorer}{health} } );
    $self->_emit( 'COMBAT_ACTION', $result );
    $self->_finish_combat( $self->{combat}{status} eq 'victory', $result->{rewards} )
      if $self->{combat}{status} ne 'inProgress';
    return 1;
}

sub autoResolveCombat {
    my $self = shift;
    return 0 unless $self->{combat} && $self->{enemy} && $self->{state}{state} eq 'fighting';
    my $result =
      Bufo::Combat->simulateCombat( $self->{state}, $self->{enemy}, 10, random => $self->{random} );
    $self->_patch( { health => $result->{explorerRemainingHealth} } );
    $self->_finish_combat(
        $result->{victory},
        {
            bufos      => $result->{bufosGained},
            experience => $result->{experienceGained},
            drops      => $result->{itemsFound}
        }
    );
    return 1;
}

sub upgradeExplorerStat {
    my ( $self, $name, $bank ) = @_;
    my $e      = $self->{state};
    my $result = Bufo::ExplorerModel->upgradeExplorerStat( $e, $name, $bank );
    if ( $result->{success} ) {
        my $previous = $e->{level};
        $self->_patch( $result->{explorer} );
        $self->_emit( 'EXPLORER_STAT_UPGRADED',
            { explorer => $e, statName => $name, newLevel => $e->{$name}{level} } );
        $self->_updated;
        $self->_emit( 'EXPLORER_LEVEL_UP', { explorer => $e, newLevel => $e->{level} } )
          if $previous != $e->{level};
    }
    return { success => $result->{success}, cost => $result->{cost} };
}

sub reset {
    my $self = shift;
    $self->{combat}   = undef;
    $self->{enemy}    = undef;
    $self->{distance} = 0;
    $self->_updated;
    return;
}
1;
