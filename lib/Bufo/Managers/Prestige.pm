package Bufo::Managers::Prestige;
use strict;
use warnings;
sub new              { my ( $class, %args ) = @_; bless \%args, $class }
sub _game            { $_[0]{game}->() }
sub getPendingPoints { $_[0]->_game->pending_prestige }
sub getMultiplier    { $_[0]->_game->prestige_multiplier }
sub getState         { +{ %{ $_[0]->_game->state->{prestige} } } }
sub getBonusPerPoint { 0.1 }
sub getMinTotalBufos { 1e9 }
sub canTranscend     { $_[0]->getPendingPoints >= 1 ? 1 : 0 }

sub transcend {
    my $self = shift;
    return $self->{transcend}->() if $self->{transcend};
    my $r = $self->_game->prestige;
    return $r->{ok} ? $r->{gained} : 0;
}

# Prestige has no transient manager state; its counters belong to the Game.
sub reset { return; }
1;
