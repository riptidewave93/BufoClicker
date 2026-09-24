package Bufo::Managers::Achievements;
use strict;
use warnings;
use JSON::PP ();
sub new                  { my ( $class, %args ) = @_; bless \%args, $class }
sub _game                { $_[0]{game}->() }
sub _clone               { JSON::PP::decode_json( JSON::PP::encode_json( $_[0] ) ) }
sub initialize           { my ( $self, $silent ) = @_; $self->checkAllAchievements unless $silent; }
sub saveToState          { $_[0]->_game->state->{achievements}{clickCount} = $_[0]->getClickCount; }
sub checkAllAchievements { $_[0]->_game->_check_achievements; }

sub checkAchievementCategory {
    my ( $self, $category ) = @_;
    $self->checkAllAchievements
      if grep { $_->{category} eq $category && !$self->isAchievementUnlocked( $_->{id} ) }
      @{ $self->getAllAchievements };
}

sub unlockAchievement {
    my ( $self, $id ) = @_;
    my $game = $self->_game;
    my $a    = $game->catalog->achievement($id);
    return 0 if !$a || $self->isAchievementUnlocked($id);
    push @{ $game->state->{achievements}{unlocked} }, $id;
    $game->_credit( $a->{reward}{value} ) if $a->{reward} && $a->{reward}{type} eq 'bufoBonus';
    $game->refresh;
    unless ( $self->{silent} ) {
        $game->emit( 'ACHIEVEMENT_UNLOCKED', { achievement => $a, timestamp => $game->{now} } );
        push @{ $game->{events} }, { type => 'achievement', id => $id };
    }
    return 1;
}
sub reapplyAllAchievementRewards { $_[0]->_game->refresh; }

sub silentUnlockAchievement {
    my ( $self, $id ) = @_;
    local $self->{silent} = 1;
    $self->unlockAchievement($id);
}
sub getAllAchievements { _clone( $_[0]->_game->catalog->achievements ) }

sub getUnlockedAchievements {
    my $self = shift;
    [ grep { $self->isAchievementUnlocked( $_->{id} ) } @{ $self->getAllAchievements } ];
}

sub getVisibleLockedAchievements {
    my $self = shift;
    [ grep { !$_->{secret} && !$self->isAchievementUnlocked( $_->{id} ) }
          @{ $self->getAllAchievements } ];
}
sub getAchievementProgress { $_[0]->_game->state->{achievements}{progress}{ $_[1] } // 0 }

sub isAchievementUnlocked {
    my ( $self, $id ) = @_;
    scalar( grep { $_ eq $id } @{ $self->_game->state->{achievements}{unlocked} } ) ? 1 : 0;
}
sub getTotalAchievementCount { scalar @{ $_[0]->_game->catalog->achievements } }
sub getUnlockedCount         { scalar @{ $_[0]->_game->state->{achievements}{unlocked} } }
sub getClickCount            { $_[0]->_game->state->{resources}{clickCount} }
sub setCustomEvents { $_[0]->_game->state->{achievements}{customEvents} = _clone( $_[1] ); }

sub setClickCount {
    my ( $self, $count ) = @_;
    $self->_game->state->{resources}{clickCount}    = $count;
    $self->_game->state->{achievements}{clickCount} = $count;
    $self->checkAchievementCategory('clicks');
}
sub triggerCustomEvent { $_[0]->_game->trigger_custom_event( $_[1] ); }
sub getCustomEvents    { _clone( $_[0]->_game->state->{achievements}{customEvents} ) }
sub getAllCustomEvents { $_[0]->getCustomEvents }

sub getAchievementDetails {
    my $a = $_[0]->_game->catalog->achievement( $_[1] );
    $a ? _clone($a) : undef;
}
sub hasCustomEventOccurred { $_[0]->_game->state->{achievements}{customEvents}{ $_[1] } ? 1 : 0 }

sub reset {
    my $self = shift;
    $self->_game->state->{achievements} =
      { unlocked => [], progress => {}, customEvents => {}, clickCount => 0 };
    $self->_game->state->{resources}{clickCount} = 0;
    $self->_game->refresh;
}
1;
