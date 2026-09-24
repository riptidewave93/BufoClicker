package Bufo::Model::Boss;
use strict;
use warnings;
use Bufo::Model::Prestige ();
use constant BOSS_FIGHT_DURATION_MS => 30000;
use constant BOSS_BONUS_PER_DEFEAT  => 0.25;

sub new {
    my ( $class, %args ) = @_;
    bless { bosses => $args{bosses} // $args{catalog}->bosses }, $class;
}

sub findBoss {
    my ( $self, $id ) = @_;
    return ( grep { $_->{id} eq $id } @{ $self->{bosses} } )[0];
}

sub getAvailableBoss {
    my ( $self, $defeated, $total ) = @_;
    my %done = map { $_ => 1 } @$defeated;
    for my $b ( @{ $self->{bosses} } ) {
        next if $done{ $b->{id} };
        return $total >= $b->{threshold} ? $b : undef;
    }
    return undef;
}

sub getBossMultiplier {
    my ( $class, $s ) = @_;
    return 1 +
      ( @{ $s->{bosses}{defeated} // [] } + ( $s->{bosses}{lifetimeDefeats} // 0 ) ) * 0.25;
}

sub getBossHealth {
    my ( $class, $boss, $state ) = @_;
    my $hp =
      $boss->{baseHealth} *
      Bufo::Model::Prestige->getPrestigeMultiplier($state) *
      $class->getBossMultiplier($state);
    my $n = 0 + sprintf( '%.0f', $hp );
    $n++ if $n < $hp;
    return $n > 1 ? $n : 1;
}
1;
