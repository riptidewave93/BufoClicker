package Bufo::Util::State;
use strict;
use warnings;
use JSON::PP               ();
use Scalar::Util           qw(blessed);
use Bufo::Util::General    ();
use Bufo::Util::Validation ();
use Bufo::ExplorerModel    ();

sub new {
    my ( $class, %args ) = @_;
    bless { now => $args{now} // sub { time() * 1000 }, %args }, $class;
}

sub createDefaultState {
    my ($self)     = @_;
    my $now        = $self->{now}->();
    my $generators = $self->{generators} // {};
    $generators = $generators->() if ref($generators) eq 'CODE';
    my $explorer = $self->{explorer};
    $explorer = $explorer->() if ref($explorer) eq 'CODE';
    $explorer = Bufo::ExplorerModel->default_data( now => $now ) unless defined $explorer;
    return {
        resources => {
            bufos                      => 0,
            totalBufos                 => 0,
            baseClickPower             => 1,
            clickPower                 => 1,
            clickMultiplier            => 1,
            productionMultiplier       => 1,
            frenzyProductionMultiplier => 1,
            frenzyClickMultiplier      => 1
        },
        generators   => Bufo::Util::General::deepClone($generators),
        explorer     => Bufo::Util::General::deepClone($explorer),
        upgrades     => { purchased => [], available => [] },
        achievements => { unlocked  => [], progress  => {}, clickCount => 0, customEvents => {} },
        gameSettings =>
          { lastTick => $now, lastSaved => $now, autoSave => JSON::PP::true, version => '1.0.0' },
        prestige => { points   => 0,  lifetimePoints  => 0, transcendences => 0 },
        bosses   => { defeated => [], lifetimeDefeats => 0 }
    };
}

sub calculateDerivedState {
    my ($state)  = @_;
    my $next     = { %$state, resources => { %{ $state->{resources} } } };
    my $r        = $next->{resources};
    my $prestige = 1 + ( $state->{prestige}{lifetimePoints} // 0 ) * 0.1;
    my $boss     = 1 +
      ( @{ $state->{bosses}{defeated} // [] } + ( $state->{bosses}{lifetimeDefeats} // 0 ) ) * 0.25;
    $r->{clickPower} =
      $r->{baseClickPower} *
      $r->{clickMultiplier} *
      $prestige * $boss *
      ( $r->{frenzyClickMultiplier} // 1 );
    return $next;
}

sub updateState {
    my ( $current, $patch ) = @_;
    my $next = {%$current};
    for my $slice (qw(resources explorer gameSettings prestige)) {
        next unless exists $patch->{$slice} && defined $patch->{$slice};
        $next->{$slice} = { %{ $current->{$slice} // {} }, %{ $patch->{$slice} } };
    }
    if ( $patch->{generators} ) {
        $next->{generators} = { %{ $current->{generators} } };
        for my $id ( keys %{ $patch->{generators} } ) {
            next unless exists( $next->{generators}{$id} ) && defined( $patch->{generators}{$id} );
            $next->{generators}{$id} =
              { %{ $next->{generators}{$id} }, %{ $patch->{generators}{$id} } };
        }
    }
    for my $slice (qw(upgrades achievements bosses)) {
        next unless $patch->{$slice};
        my $old     = $current->{$slice} // {};
        my $changes = $patch->{$slice};
        $next->{$slice} = { %$old, %$changes };
        my @arrays =
            $slice eq 'upgrades'     ? qw(purchased available)
          : $slice eq 'achievements' ? ('unlocked')
          :                            ('defeated');
        for my $name (@arrays) {
            my $values = exists( $changes->{$name} ) ? $changes->{$name} : $old->{$name};
            $next->{$slice}{$name} = [ @{ $values // [] } ];
        }
        if ( $slice eq 'achievements' ) {
            for my $name (qw(progress customEvents)) {
                my $values = exists( $changes->{$name} ) ? $changes->{$name} : $old->{$name};
                $next->{$slice}{$name} = { %{ $values // {} } };
            }
        }
    }
    return calculateDerivedState($next);
}

sub validateState {
    my ($s) = @_;
    return 0 unless ref($s) eq 'HASH';
    for (qw(resources generators explorer upgrades gameSettings)) { return 0 unless $s->{$_} }
    return 0
      unless ref( $s->{resources} ) eq 'HASH'
      && ref( $s->{upgrades} ) eq 'HASH'
      && ref( $s->{gameSettings} ) eq 'HASH';
    for (qw(bufos totalBufos clickPower clickMultiplier productionMultiplier)) {
        my $value = $s->{resources}{$_};
        return 0 unless defined($value) && !ref($value);
        my $json = JSON::PP->new->allow_nonref->encode($value);
        return 0 if $json =~ /^\"/;
    }
    return 0
      unless ref( $s->{upgrades}{purchased} ) eq 'ARRAY'
      && ref( $s->{upgrades}{available} ) eq 'ARRAY';
    for (qw(lastSaved lastTick version)) {
        return 0 unless exists $s->{gameSettings}{$_};
        return 0
          if blessed( $s->{gameSettings}{$_} )
          && $s->{gameSettings}{$_}->isa('Bufo::Util::Undefined');
    }
    return 1;
}
1;
