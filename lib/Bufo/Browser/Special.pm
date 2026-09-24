package Bufo::Browser::GoldenBufo;
use strict;
use warnings;
use parent -norequire, 'Bufo::Browser::Component';

sub setup {
    my ($s) = @_;
    $s->{layer} = Bufo::Browser::DOM::createElement( 'div',
        { classes => 'golden-bufo-layer', parent => Bufo::Browser::DOM::document()->{body} } );
    $s->{frenzyLayer} = Bufo::Browser::DOM::createElement( 'div',
        { classes => 'frenzy-indicator-layer', parent => Bufo::Browser::DOM::document()->{body} } );
    $s->{badges} = {};
    $s->subscribeToEvent( 'GOLDEN_BUFO_SPAWNED', sub { $s->showBufo( $_[0] );          return; } );
    $s->subscribeToEvent( 'GOLDEN_BUFO_EXPIRED', sub { $s->removeBufo( $_[0]{id}, 1 ); return; } );
    $s->subscribeToEvent( 'GOLDEN_BUFO_COLLECTED',
        sub { $s->removeBufo( $_[0]{id}, 0 ); $s->showToast( $_[0] ); return; } );
    $s->subscribeToEvent( 'GAME_TICK', sub { $s->refreshFrenzyIndicators; return; } );
    return;
}

sub showBufo {
    my ( $s, $spawn ) = @_;
    $s->removeBufo( $s->{currentId}, 0 ) if defined $s->{current};
    my $el = Bufo::Browser::DOM::createElement(
        'button',
        {
            id         => 'golden-bufo',
            classes    => 'golden-bufo',
            attributes => { 'type' => 'button', 'aria-label' => 'Golden Bufo, click me!' },
            parent     => $s->{layer}
        }
    );
    $el->{innerHTML} =
      '<img src="./assets/images/generators/bufo-has-midas-touch.png" alt="Golden Bufo" draggable="false">';
    my $w    = Bufo::Browser::DOM::window();
    my $size = 92;
    $el->{style}->{left} = Bufo::Browser::clamp(
        $spawn->{position}{xPct} / 100 * $w->{innerWidth},
        $size / 2 + 6,
        $w->{innerWidth} - $size / 2 - 6
    ) . 'px';
    $el->{style}->{top} = Bufo::Browser::clamp(
        $spawn->{position}{yPct} / 100 * $w->{innerHeight},
        $size / 2 + 6,
        $w->{innerHeight} - $size / 2 - 6
    ) . 'px';
    $el->{style}->setProperty( '--ttl', $spawn->{ttl} . 'ms' );
    my $cb = sub {
        my ($e) = @_;
        $e->preventDefault;
        $e->stopPropagation;
        $Bufo::Browser::api->getGoldenBufoManager->collect( $spawn->{id} );
        return;
    };
    Bufo::Browser::DOM::listen( $el, 'click', $cb );
    $s->{current}          = $el;
    $s->{currentId}        = $spawn->{id};
    $s->{collect_callback} = $cb;
    return;
}

sub removeBufo {
    my ( $s, $id, $fade ) = @_;
    return unless defined $s->{current} && defined $id && $id == $s->{currentId};
    my $el = delete $s->{current};
    my $cb = delete $s->{collect_callback};
    Bufo::Browser::DOM::unlisten( $el, 'click', $cb );

    $s->{currentId} = undef;
    if ($fade) {
        $el->{classList}->add('golden-bufo--leaving');
        Bufo::Browser::DOM::later( 400, sub { $el->remove; return; } );
    } else {
        $el->remove;
    }
    return;
}

sub showToast {
    my ( $s, $r ) = @_;
    my $el = Bufo::Browser::DOM::createElement(
        'div',
        {
            classes => 'golden-bufo-toast golden-bufo-toast--' . ( $r->{rewardType} || '' ),
            parent  => $s->{layer}
        }
    );
    $el->{innerHTML} =
        '<span class="golden-bufo-toast__label">'
      . Bufo::Browser::escape_html( $r->{label} )
      . '</span><span class="golden-bufo-toast__detail">'
      . Bufo::Browser::escape_html( $r->{detail} )
      . '</span>';
    Bufo::Browser::DOM::later( 10, sub { $el->{classList}->add('is-visible'); return; } );
    Bufo::Browser::DOM::later(
        2600,
        sub {
            $el->{classList}->remove('is-visible');
            Bufo::Browser::DOM::later( 400, sub { $el->remove; return; } );
            return;
        }
    );
    return;
}

sub refreshFrenzyIndicators {
    my ($s) = @_;
    my $f = $Bufo::Browser::api->getGoldenBufoManager->getActiveFrenzies;
    $s->syncFrenzyBadge( 'production', $f->{production}, 'Bufo Frenzy',  'production' );
    $s->syncFrenzyBadge( 'click',      $f->{click},      'Click Frenzy', 'click' );
    return;
}

sub syncFrenzyBadge {
    my ( $s, $kind, $f, $label, $modifier ) = @_;
    if ( !$f ) { my $b = delete $s->{badges}{$kind}; $b->{element}->remove if $b; return; }
    my $remaining = $f->{endsAt} - Bufo::Browser::now();
    $remaining = 0 if $remaining < 0;
    my $b = $s->{badges}{$kind};
    unless ($b) {
        my $el = Bufo::Browser::DOM::createElement( 'div',
            { classes => 'frenzy-badge frenzy-badge--' . $modifier, parent => $s->{frenzyLayer} } );
        $el->{innerHTML} =
          '<span class="frenzy-badge__label"></span><span class="frenzy-badge__time"></span><span class="frenzy-badge__bar"><span class="frenzy-badge__bar-fill"></span></span>';
        $b = $s->{badges}{$kind} = { element => $el, total => $remaining || 1 };
    }
    Bufo::Browser::DOM::querySelector( '.frenzy-badge__label', $b->{element} )->{textContent} =
      $label . ' x' . $f->{multiplier};
    Bufo::Browser::DOM::querySelector( '.frenzy-badge__time', $b->{element} )->{textContent} =
      sprintf( '%.1fs', $remaining / 1000 );
    Bufo::Browser::DOM::querySelector( '.frenzy-badge__bar-fill', $b->{element} )->{style}->{width}
      = Bufo::Browser::clamp( $remaining / $b->{total} * 100, 0, 100 ) . '%';
    return;
}

sub destroy {
    my ($s) = @_;
    $s->removeBufo( $s->{currentId}, 0 );
    Bufo::Browser::DOM::removeElement( $s->{layer} );
    Bufo::Browser::DOM::removeElement( $s->{frenzyLayer} );
    $s->SUPER::destroy;
    return;
}

package Bufo::Browser::BossFight;
use parent -norequire, 'Bufo::Browser::Component';

sub setup {
    my ($s) = @_;
    $s->subscribeToEvent( 'GAME_TICK',          sub { $s->refreshBanner;            return; } );
    $s->subscribeToEvent( 'BOSS_FIGHT_STARTED', sub { $s->showFight( $_[0]{boss} ); return; } );
    $s->subscribeToEvent( 'BOSS_DAMAGED',
        sub { $s->updateHealth( $_[0]{health}, $_[0]{maxHealth} ); return; } );
    $s->subscribeToEvent( 'BOSS_TICK',     sub { $s->updateTimer( $_[0]{remainingMs} ); return; } );
    $s->subscribeToEvent( 'BOSS_DEFEATED', sub { $s->onDefeated( $_[0] );               return; } );
    $s->subscribeToEvent( 'BOSS_FIGHT_LOST',      sub { $s->onLost( $_[0]{boss} ); return; } );
    $s->subscribeToEvent( 'BOSS_FIGHT_RETREATED', sub { $s->teardownFight;         return; } );
    $s->refreshBanner;
    return;
}

sub syncBossStage {
    Bufo::Browser::DOM::document()->{body}
      ->setAttribute( 'data-boss-stage', $Bufo::Browser::api->getBossManager->getDefeatedCount );
    return;
}
sub refreshBanner    { $_[0]->syncBossStage;         Bufo::Browser::render_boss(); return; }
sub showFight        { Bufo::Browser::render_boss(); return; }
sub repositionSprite { Bufo::Browser::move_boss();   return; }

sub handleHit {
    my ( $s, $event ) = @_;
    $event->preventDefault;
    $event->stopPropagation;
    $Bufo::Browser::api->registerClick;
    my $damage = $Bufo::Browser::game->state->{resources}{clickPower};
    my $f      = $Bufo::Browser::api->getBossManager->hit($damage);
    my $sprite = Bufo::Browser::node('boss-sprite');
    if ( defined $sprite && $f ) {
        my $r = $sprite->getBoundingClientRect;
        $s->showDamageNumber( $r->{left} + $r->{width} / 2, $r->{top}, $damage );
        $sprite->{classList}->remove('boss-sprite--hit');
        my $width = $sprite->{offsetWidth};
        $sprite->{classList}->add('boss-sprite--hit');
    }
    return;
}

sub showDamageNumber {
    my ( $s, $x, $y, $amount ) = @_;
    my $parent = Bufo::Browser::DOM::querySelector('.boss-fight-overlay');
    return unless defined $parent;
    my $el = Bufo::Browser::DOM::createElement(
        'div',
        {
            classes => 'boss-damage-number',
            content => '-' . Bufo::Browser::number($amount),
            parent  => $parent
        }
    );
    $el->{style}->{left} = $x . 'px';
    $el->{style}->{top}  = $y . 'px';
    Bufo::Browser::DOM::later( 700, sub { $el->remove; return; } );
    return;
}

sub updateHealth {
    my ( $s, $health, $max ) = @_;
    my $fill = Bufo::Browser::node('boss-health-fill');
    return unless defined $fill;
    $fill->{style}->{width} =
      ( $max ? Bufo::Browser::clamp( $health / $max * 100, 0, 100 ) : 0 ) . '%';
    Bufo::Browser::put_text( 'boss-health-text',
        Bufo::Browser::number($health) . ' / ' . Bufo::Browser::number($max) . ' HP' );
    return;
}

sub updateTimer {
    my ( $s, $ms ) = @_;
    my $el = Bufo::Browser::node('boss-timer');
    return unless defined $el;
    $el->{textContent} = sprintf( '%.1fs', $ms > 0 ? $ms / 1000 : 0 );
    $el->{classList}->toggle( 'boss-fight-hud__timer--urgent', $ms <= 10000 );
    return;
}

sub onDefeated {
    my ( $s, $d ) = @_;
    Bufo::Browser::boss_result( $d->{boss}{id}, 1 );
    Bufo::Browser::persist(0);
    return;
}

sub onLost {
    my ( $s, $boss ) = @_;
    Bufo::Browser::boss_result( $boss->{id}, 0 );
    Bufo::Browser::persist(0);
    return;
}

sub guardAgainstStrayClicks {
    my ( $s, $modal ) = @_;
    $modal->{classList}->add('modal--input-locked');
    Bufo::Browser::DOM::later( 800,
        sub { $modal->{classList}->remove('modal--input-locked'); return; } );
    return;
}
sub teardownFight  { Bufo::Browser::render_boss();        return; }
sub clearMoveTimer { Bufo::Browser::stop_boss_movement(); return; }

sub destroy {
    my ($s) = @_;
    $s->clearMoveTimer;
    Bufo::Browser::put_html( 'boss-layer', '' );
    Bufo::Browser::DOM::document()->{body}->{classList}->remove('boss-fight-active');
    $s->SUPER::destroy;
    return;
}
1;
