package Bufo::Managers::Golden;
use strict;
use warnings;

# Wall-clock deadlines are polled by the game loop; there is no second timer writer.
sub new {
    my ( $class, %args ) = @_;
    bless { %args, running => 0, next_id => 1, first => 0, active => undef }, $class;
}
sub _game   { $_[0]{game}->() }
sub _now    { $_[0]{clock}->() }
sub _random { $_[0]{random} ? $_[0]{random}->() : rand() }

sub _schedule {
    my $s = shift;
    $s->{next_at} =
      $s->_now + ( $s->{first} ? 90000 : 45000 ) + $s->_random * ( $s->{first} ? 100000 : 45000 );
}
sub start { my $s = shift; return if $s->{running}; $s->{running} = 1; $s->_schedule; }

sub stop {
    my $s = shift;
    return unless $s->{running};
    $s->{running} = 0;
    $s->_game->emit( 'GOLDEN_BUFO_EXPIRED', { id => $s->{active}{id} } ) if $s->{active};
    $s->{active}          = undef;
    $s->{next_at}         = undef;
    $s->_game->{frenzies} = { production => 0, click => 0 };
    $s->_game->refresh;
}
sub isActive          { defined( $_[0]{active} ) ? 1 : 0 }
sub getActiveFrenzies { $_[0]->_game->active_frenzies( $_[0]->_now ) }

sub collect {
    my ( $s, $id ) = @_;
    return undef unless $s->{active} && ( !defined($id) || $id == $s->{active}{id} );
    my $spawn = $s->{active};
    $s->{active} = undef;
    my $result = $s->_game->collect_golden( $spawn->{rewardType}, $s->_now );
    return undef unless $result->{ok};
    my $reward = { map { $_ => $result->{$_} } qw(rewardType label detail) };
    $s->_game->emit( 'GOLDEN_BUFO_COLLECTED', { id => $spawn->{id}, %$reward } );
    $s->_schedule if $s->{running};
    return $reward;
}
sub forceSpawn { my $s = shift; $s->start unless $s->{running}; $s->_spawn unless $s->{active}; }

sub _spawn {
    my $s = shift;
    return unless $s->{running};
    $s->{first}  = 1;
    $s->{active} = {
        id         => $s->{next_id}++,
        rewardType => $s->_game->golden_outcome( $s->_random ),
        position   => { xPct => 8 + $s->_random * 76, yPct => 14 + $s->_random * 64 },
        ttl        => 13000
    };
    $s->{expires_at} = $s->_now + 13000;
    $s->_game->emit( 'GOLDEN_BUFO_SPAWNED', $s->{active} );
}

sub update {
    my $s = shift;
    return unless $s->{running};
    if ( $s->{active} && $s->_now >= $s->{expires_at} ) {
        $s->_game->emit( 'GOLDEN_BUFO_EXPIRED', { id => $s->{active}{id} } );
        $s->{active} = undef;
        $s->_schedule;
    } elsif ( !$s->{active} && $s->_now >= $s->{next_at} ) {
        $s->_spawn;
    }
}
sub reset { my $s = shift; $s->stop; $s->{first} = 0; }
1;
