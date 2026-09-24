package Bufo::Model::Prestige;
use strict;
use warnings;
use Scalar::Util ();
use constant PRESTIGE_BONUS_PER_POINT => 0.1;
use constant PRESTIGE_MIN_TOTAL_BUFOS => 1e9;
sub default_state { { points => 0, lifetimePoints => 0, transcendences => 0 } }

sub prestigePointsFor {
    my ( $class, $total ) = @_;
    return 0
      unless defined($total)
      && !ref($total)
      && Scalar::Util::looks_like_number($total)
      && "$total" !~ /nan|inf/i
      && $total >= 1e9;
    my $n       = sqrt( $total / 1e9 );
    my $rounded = 0 + sprintf( '%.0f', $n );
    return $rounded > $n ? $rounded - 1 : $rounded;
}

sub getPrestigeMultiplier {
    my $n = $_[1]{prestige}{lifetimePoints} // 0;
    return 1 + ( $n > 0 ? $n : 0 ) * 0.1;
}
1;
