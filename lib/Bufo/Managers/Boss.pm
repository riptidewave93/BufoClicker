package Bufo::Managers::Boss;
use strict;
use warnings;
use JSON::PP          ();
use Bufo::Model::Boss ();
sub new              { my ( $class, %args ) = @_; bless \%args, $class }
sub _game            { $_[0]{game}->() }
sub _now             { $_[0]{clock} ? $_[0]{clock}->() : $_[0]->_game->{now} }
sub getAvailableBoss { $_[0]->_game->available_boss }

sub getActiveFight {
    my $f = $_[0]->_game->active_boss;
    return $f ? { map { $_ => $f->{$_} } qw(boss health maxHealth remainingMs) } : undef;
}
sub getScaledHealth  { Bufo::Model::Boss->getBossHealth( $_[1], $_[0]->_game->state ) }
sub getMultiplier    { $_[0]->_game->boss_multiplier }
sub getDefeatedCount { scalar @{ $_[0]->_game->state->{bosses}{defeated} } }
sub startFight { my $self = shift; return $self->_game->start_boss( $self->_now )->{ok} ? 1 : 0; }

sub hit {
    my ( $self, $amount ) = @_;
    my $g = $self->_game;
    return $self->getActiveFight unless $g->active_boss && $amount > 0;
    $g->damage_boss($amount);
    return $self->getActiveFight;
}
sub retreat { $_[0]->_game->retreat_boss; }
sub pause   { $_[0]->_game->{boss_paused} = 1; }

sub resume {
    my $self = shift;
    $self->_game->{boss_paused} = 0;
    $self->_game->{fight}{lastAt} = $self->_now if $self->_game->{fight};
}
sub reset { my $self = shift; $self->_game->{fight} = undef; $self->_game->{boss_paused} = 0; }
sub win  { my $self = shift; $self->hit( $self->_game->{fight}{health} ) if $self->_game->{fight}; }
sub lose { $_[0]->_game->lose_boss; }
1;
