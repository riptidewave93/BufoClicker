package Bufo::Browser::View;
use strict;
use warnings;
use utf8;
use parent -norequire, 'Bufo::Browser::Component';
use Bufo::Browser::Component;
use Bufo::Browser::Container;
use Bufo::Browser::Animation;
use Bufo::Browser::Tooltip;
sub api   { return $Bufo::Browser::api; }
sub state { return $Bufo::Browser::state->getState; }
sub esc   { return Bufo::Browser::DOM::escape( $_[0] ); }
sub num   { return $Bufo::Browser::game->format_number( $_[0] ); }

sub icon {
    my ( $g, $class ) = @_;
    my %fallback = (
        basic     => '🐸',
        premium   => '✨',
        special   => '🔮',
        click     => '👆',
        generator => '🐸',
        global    => '🌍'
    );
    my $emoji = $fallback{ $g->{category} || '' } || '🐸';
    return '<span class="generator-icon-wrapper">'
      . (
        $g->{iconPath}
        ? '<img src="'
          . esc( $g->{iconPath} )
          . '" alt="'
          . esc( $g->{name} )
          . '" class="'
          . esc( $class || 'generator-icon-img' )
          . '" draggable="false"><span class="generator-icon-fallback" hidden>'
          . $emoji
          . '</span>'
        : '<span class="generator-icon-fallback">' . $emoji . '</span>'
      ) . '</span>';
}

sub bindImages {
    my ($s) = @_;
    for my $img ( @{ Bufo::Browser::DOM::querySelectorAll( 'img', $s->{element} ) } ) {
        my $cb = sub {
            $img->{hidden} = 1;
            my $next = $img->{nextElementSibling};
            $next->{hidden} = 0 if defined $next;
            return;
        };
        Bufo::Browser::DOM::listen( $img, 'error', $cb );
        push @{ $s->{image_handlers} }, [ $img, $cb ];
    }
    return;
}

sub detachImages {
    my ($s) = @_;
    for ( @{ $s->{image_handlers} || [] } ) {
        Bufo::Browser::DOM::unlisten( $_->[0], 'error', $_->[1] );

    }
    $s->{image_handlers} = [];
    return;
}
sub destroy { my ($s) = @_; $s->closeDetail; $s->detachImages; $s->SUPER::destroy; return; }

sub closeDetail {
    my ($s) = @_;
    for ( @{ $s->{detail_hooks} || [] } ) {
        Bufo::Browser::DOM::unlisten( Bufo::Browser::DOM::document(), $_->[0], $_->[1] );

    }
    $s->{detail_hooks} = [];
    Bufo::Browser::Tooltip::hideTooltip();
    return;
}

sub showDetail {
    my ( $s, $content, $event ) = @_;
    $s->closeDetail;
    Bufo::Browser::Tooltip::showTooltip( $content, $event );
    my $move = sub { Bufo::Browser::Tooltip::updateTooltipPosition( $_[0] ); return; };
    my $up   = sub { $s->closeDetail;                                        return; };
    $s->{detail_hooks} = [ [ 'mousemove', $move ], [ 'mouseup', $up ] ];
    for ( @{ $s->{detail_hooks} } ) {
        Bufo::Browser::DOM::listen( Bufo::Browser::DOM::document(), $_->[0], $_->[1] );
    }
    return;
}

package Bufo::Browser::ResourceDisplay;
use parent -norequire, 'Bufo::Browser::View';

sub new {
    my ( $c, $o ) = @_;
    return $c->SUPER::new(
        {
            id                 => 'resource-display',
            className          => 'resource-display',
            showProductionRate => 1,
            %{ $o || {} }
        }
    );
}

sub render {
    my ($s) = @_;
    return
      '<div class="resource-count"><span class="number-value">0</span><span class="number-label">Bufos</span></div>'
      . (
        $s->{options}{showProductionRate} ? '<div class="production-rate">0 bufos/sec</div>' : '' );
}

sub setup {
    my ($s) = @_;
    $s->setContent( $s->render ) unless $s->{options}{adopt};
    $s->connectToState(
        sub {
            my $r = $_[0]{resources};
            return { bufos => $r->{bufos}, productionRate => $r->{totalProduction} };
        },
        sub { $s->handleStateChange( $_[0] ); return; }
    );
    return;
}
sub handleStateChange { my ( $s, $d ) = @_; $s->update($d); return; }

sub updateBufoCount {
    my ( $s, $n ) = @_;
    if ( $s->{options}{adopt} ) { Bufo::Browser::render_resources(); return; }
    my $el = Bufo::Browser::DOM::querySelector( '.number-value', $s->{element} );
    if ( defined $el ) {
        my $value = sprintf( '%.0f', $n );
        $value -= 1 if $value > $n;
        $el->{textContent} = Bufo::Browser::View::num($value);
    }
    return;
}

sub updateProductionRate {
    my ( $s, $rate ) = @_;
    my $el = Bufo::Browser::DOM::querySelector( '.production-rate', $s->{element} );
    if ( defined $el ) {
        my $child = Bufo::Browser::DOM::querySelector( '#production-rate', $el );
        $child = $el unless defined $child;
        $child->{textContent} = Bufo::Browser::View::num($rate) . ' bufos/sec';
        $el->{classList}->add('production-updated');
        Bufo::Browser::DOM::later( 300,
            sub { $el->{classList}->remove('production-updated'); return; } );
    }
    return;
}

sub update {
    my ( $s, $d ) = @_;
    return unless $d;
    $s->updateBufoCount( $d->{bufos} )               if defined $d->{bufos};
    $s->updateProductionRate( $d->{productionRate} ) if defined $d->{productionRate};
    return;
}

package Bufo::Browser::ClickArea;
use parent -norequire, 'Bufo::Browser::View';
our @BUFO_IMAGES;

sub new {
    my ( $c, $o ) = @_;
    my $s = $c->SUPER::new(
        {
            id             => 'frog-display',
            className      => 'frog-display',
            imagePath      => './assets/images/bufo.png',
            maxComboClicks => 5,
            comboTimeout   => 1000,
            %{ $o || {} }
        }
    );
    $s->{recentClicks} = [];
    return $s;
}

sub render {
    my ($s) = @_;
    return
        '<img src="'
      . Bufo::Browser::View::esc( $s->{options}{imagePath} )
      . '" alt="Bufo" class="bufo-image" draggable="false"><div class="click-indicator-container"></div>';
}

sub setup {
    my ($s) = @_;
    $s->setContent( $s->render ) unless $s->{options}{adopt};
    $s->{effectLayer} = Bufo::Browser::DOM::createElement( 'div',
        { classes => 'click-effect-layer', parent => Bufo::Browser::DOM::document()->{body} } );
    $s->addEventListener( 'click', sub { $s->handleClick( $_[0] ); return; } );
    return;
}

sub handleClick {
    my ( $s, $e ) = @_;
    $e->preventDefault;
    $e->stopPropagation;
    return unless Bufo::Browser::interaction_allowed();
    my $now = Bufo::Browser::now();
    push @{ $s->{recentClicks} }, $now;
    shift @{ $s->{recentClicks} } while @{ $s->{recentClicks} } > $s->{options}{maxComboClicks};
    $s->clearOldClicks;
    my $r = Bufo::Browser::View::api()->click;
    $s->createClickEffects( $e->{clientX}, $e->{clientY}, $r );
    Bufo::Browser::render_resources();
    return;
}

sub clearOldClicks {
    my ($s) = @_;
    my $t = Bufo::Browser::now();
    $s->{recentClicks} = [ grep { $t - $_ < $s->{options}{comboTimeout} } @{ $s->{recentClicks} } ];
    return;
}

sub createClickEffects {
    my ( $s, $x, $y, $r ) = @_;
    my $img = Bufo::Browser::DOM::querySelector( '.bufo-image', $s->{element} );
    if ( defined $img ) {
        $img->{style}->{transform} = 'scale(0.95)';
        Bufo::Browser::DOM::cancel( $s->{squish} );
        $s->{squish} =
          Bufo::Browser::DOM::later( 90, sub { $img->{style}->{transform} = ''; return; } );
    }
    $s->createClickIndicator( $x, $y );
    $s->createFloatingNumber( $x, $y, $r );
    $s->createEmojiPop( $x, $y );
    return;
}

sub createClickIndicator {
    my ( $s, $x, $y ) = @_;
    my $el = Bufo::Browser::DOM::createElement( 'div',
        { classes => 'click-indicator', parent => $s->{effectLayer} } );
    $el->{style}->{left} = $x . 'px';
    $el->{style}->{top}  = $y . 'px';
    Bufo::Browser::DOM::later( 1000, sub { $el->remove; return; } );
    return;
}

sub createFloatingNumber {
    my ( $s, $x, $y, $r ) = @_;
    my $el = Bufo::Browser::DOM::createElement(
        'div',
        {
            classes => 'floating-number' . ( $r->{isCombo} ? ' combo' : '' ),
            parent  => $s->{effectLayer}
        }
    );
    $el->{innerHTML} =
      '<span class="value">+' . sprintf( '%.1f', $r->{bufosGained} || 0 ) . '</span>';
    my $width = Bufo::Browser::DOM::window()->{innerWidth};
    $x = Bufo::Browser::clamp( $x + rand(30) - 15, 6, $width - $el->{offsetWidth} - 6 );
    $el->{style}->{left} = $x . 'px';
    $el->{style}->{top}  = $y . 'px';
    my $drift = Bufo::Browser::clamp( $x + rand(40) - 20, 6, $width - $el->{offsetWidth} - 6 ) - $x;
    my $height = 50 + rand(20);
    Bufo::Browser::Animation::animate(
        1500,
        sub {
            my $p = $_[0];
            $el->{style}->{transform} =
                'translate('
              . ( $drift * $p ) . 'px,'
              . ( -$height * ( 1 - ( 1 - $p )**3 ) )
              . 'px) scale('
              . ( $p < .2 ? .7 + $p / .2 * .5 : 1.2 - ( $p - .2 ) / .8 * .4 ) . ')';
            $el->{style}->{opacity} = $p < .7 ? 1 : 1 - ( $p - .7 ) / .3;
            return;
        },
        { onComplete => sub { $el->remove; return; } }
    );
    return;
}

sub createEmojiPop {
    my ( $s, $x, $y ) = @_;
    return unless @BUFO_IMAGES;
    my $el = Bufo::Browser::DOM::createElement( 'div',
        { classes => 'click-emoji-pop', parent => $s->{effectLayer} } );
    $el->{style}->{left} =
      Bufo::Browser::clamp( $x, 22, Bufo::Browser::DOM::window()->{innerWidth} - 22 ) . 'px';
    $el->{style}->{top} = $y . 'px';
    $el->{innerHTML} =
      '<img src="' . $BUFO_IMAGES[ int( rand(@BUFO_IMAGES) ) ] . '" alt="" draggable="false">';
    my $height = 50 + rand(50);
    my $drift  = rand(140) - 70;
    my $spin   = rand(100) - 50;
    Bufo::Browser::Animation::animate(
        800 + rand(200),
        sub {
            my $t = $_[0];
            $el->{style}->{transform} =
                'translate('
              . ( $drift * $t ) . 'px,'
              . ( -4 * $height * $t * ( 1 - $t ) )
              . 'px) rotate('
              . ( $spin * $t ) . 'deg)';
            $el->{style}->{opacity} = 1 - ( $t - .5 ) / .5 if $t > .5;
            return;
        },
        { onComplete => sub { $el->remove; return; } }
    );
    return;
}

sub destroy {
    my ($s) = @_;
    Bufo::Browser::DOM::cancel( $s->{squish} );
    Bufo::Browser::DOM::removeElement( $s->{effectLayer} );
    $s->SUPER::destroy;
    return;
}

package Bufo::Browser::GeneratorItem;
use parent -norequire, 'Bufo::Browser::View';

sub setup {
    my ($s) = @_;
    $s->setContent( $s->render ) unless $s->{options}{adopt};
    $s->addEventListener( 'click', sub { $s->handleClick( $_[0] ); return; } );
    return;
}

sub handleClick {
    my ( $s, $e ) = @_;
    return unless $s->{generator};
    $e->stopPropagation;
    $s->showDetail( $s->generateTooltipContent, $e );
    return;
}
sub getGeneratorIconHtml { return Bufo::Browser::View::icon( $_[1] ); }

sub render {
    my ($s) = @_;
    my $g = $s->{generator} || { name => 'Unknown', count => 0, totalProduction => 0 };
    return
        '<div class="generator-icon">'
      . $s->getGeneratorIconHtml($g)
      . '</div><div class="generator-info"><div class="name-count-container"><span class="generator-name">'
      . Bufo::Browser::View::esc( $g->{name} )
      . '</span><span class="generator-count">x'
      . $g->{count}
      . '</span></div><div class="generator-production"><span class="production-value">'
      . Bufo::Browser::View::num( $g->{totalProduction} )
      . '</span>/sec</div></div>';
}

sub update {
    my ( $s, $g ) = @_;
    $s->{generator} = $g;
    $s->detachImages;
    $s->setContent( $s->render );
    $s->removeClass('category-basic category-premium category-special');
    $s->addClass( 'category-' . $g->{category} );
    $s->bindImages;
    return;
}

sub generateTooltipContent {
    my ($s) = @_;
    my $g = $s->{generator};
    return '' unless $g;
    my $html =
        '<div class="tooltip-header"><strong>'
      . Bufo::Browser::View::esc( $g->{name} )
      . '</strong> <span class="tooltip-count">x'
      . $g->{count}
      . '</span></div><div class="tooltip-description">'
      . Bufo::Browser::View::esc( $g->{detailedDescription} || $g->{description} )
      . '</div><div class="tooltip-section"><div class="tooltip-section-title">Production</div>';
    for my $row (
        [ 'Base production',    $g->{baseProduction},    ' per unit' ],
        [ 'Current production', $g->{currentProduction}, ' per unit' ],
        [ 'Total production',   $g->{totalProduction},   '' ]
      )
    {
        $html .=
            '<div class="tooltip-production-item"><span class="tooltip-label">'
          . $row->[0]
          . ':</span><span class="tooltip-value">'
          . Bufo::Browser::View::num( $row->[1] ) . '/sec'
          . $row->[2]
          . '</span></div>';
    }
    for my $b ( grep { $_->{active} } @{ $g->{boosts} || [] } ) {
        $html .=
            '<div class="tooltip-boost-item '
          . ( $b->{multiplier} > 1 ? 'positive' : 'negative' )
          . '"><span class="tooltip-label">'
          . Bufo::Browser::View::esc( $b->{source} )
          . ':</span><span class="tooltip-value">x'
          . sprintf( '%.2f', $b->{multiplier} )
          . '</span></div>';
    }
    return $html . '</div>';
}

package Bufo::Browser::ShopItem;
use parent -norequire, 'Bufo::Browser::GeneratorItem';

sub setup {
    my ($s) = @_;
    $s->{purchaseAmount} = 1;
    $s->setContent( $s->render ) unless $s->{options}{adopt};
    $s->addEventListener(
        'click',
        sub {
            my $e = $_[0];
            my $b = $e->{target}->closest('.buy-button');
            defined($b) ? $s->handlePurchase($e) : $s->handleInfoClick($e);
            return;
        }
    );
    return;
}

sub handleInfoClick {
    my ( $s, $e ) = @_;
    $e->stopPropagation;
    return unless $s->{generator};
    $s->showDetail( $s->generateTooltipContent, $e );
    return;
}

sub handlePurchase {
    my ( $s, $e ) = @_;
    $e->preventDefault;
    $e->stopPropagation;
    return unless Bufo::Browser::interaction_allowed();
    return unless $s->{generator};
    my $ok = Bufo::Browser::View::api()->buyGenerator( $s->{generator}{id}, $s->{purchaseAmount} );
    Bufo::Browser::feedback( $s->{element}, $ok );
    if ( !$ok ) {
        my $b = Bufo::Browser::DOM::querySelector( '.buy-button', $s->{element} );
        Bufo::Browser::Animation::shake( $b, 5, 500 );
    } else {
        Bufo::Browser::render();
    }
    return;
}

sub render {
    my ($s) = @_;
    my $g = $s->{generator} || { name => 'Unknown', currentProduction => 0, id => '' };
    return
        '<div class="generator-row"><div class="generator-left"><div class="generator-icon">'
      . $s->getGeneratorIconHtml($g)
      . '</div><div class="generator-info"><div class="generator-name">'
      . Bufo::Browser::View::esc( $g->{name} )
      . '</div><div class="generator-production">'
      . Bufo::Browser::View::num( $g->{currentProduction} )
      . '/sec per unit</div></div></div><button type="button" class="buy-button" data-generator-id="'
      . Bufo::Browser::View::esc( $g->{id} )
      . '">0 bufos</button></div>';
}

sub update {
    my ( $s, $data ) = @_;
    my $g = $data->{generator};
    return unless $g;
    $s->{generator}      = $g;
    $s->{purchaseAmount} = $data->{purchaseAmount} if defined $data->{purchaseAmount};
    $s->{canAfford}      = $data->{canAfford}      if defined $data->{canAfford};
    $s->updateDisplay;
    return;
}

sub updateDisplay {
    my ($s) = @_;
    my $g = $s->{generator};
    if ( ( $s->{rendered_id} || '' ) ne $g->{id} ) {
        $s->detachImages;
        $s->setContent( $s->render );
        $s->bindImages;
        $s->{rendered_id} = $g->{id};
    } else {
        my $name = Bufo::Browser::DOM::querySelector( '.generator-name', $s->{element} );
        $name->{textContent} = $g->{name} if defined $name;
        my $rate = Bufo::Browser::DOM::querySelector( '.generator-production', $s->{element} );
        $rate->{textContent} = Bufo::Browser::View::num( $g->{currentProduction} ) . '/sec per unit'
          if defined $rate;
    }
    $s->updateButtonCost;
    return;
}

sub updateButtonCost {
    my ($s) = @_;
    return unless $s->{generator};
    my $id   = $s->{generator}{id};
    my $q    = $s->{purchaseAmount} || 1;
    my $n    = $q == -1 ? $Bufo::Browser::game->max_affordable($id) : $q;
    my $cost = $Bufo::Browser::game->generator_cost( $id, $q );
    my $b    = Bufo::Browser::DOM::querySelector( '.buy-button', $s->{element} );
    return unless defined $b;
    $b->{textContent} = $n > 0 ? Bufo::Browser::View::num($cost) . ' bufos' : "Can't afford";
    $b->{className} =
      'buy-button '
      . (    defined($cost)
          && $n > 0
          && $cost <= $Bufo::Browser::game->state->{resources}{bufos} ? 'affordable' : 'disabled' );
    return;
}

sub generateTooltipContent {
    my ($s) = @_;
    my $g = $s->{generator};
    return '' unless $g;
    my $id = $g->{id};
    my $html =
        '<div class="tooltip-header"><strong>'
      . Bufo::Browser::View::esc( $g->{name} )
      . '</strong> <span class="tooltip-count">x'
      . $g->{count}
      . '</span></div><div class="tooltip-description">'
      . Bufo::Browser::View::esc( $g->{detailedDescription} || $g->{description} )
      . '</div><div class="tooltip-section"><div class="tooltip-section-title">Production</div>'
      . '<div class="tooltip-production"><div class="tooltip-production-item">'
      . '<span class="tooltip-label">Production:</span><span class="tooltip-value">'
      . Bufo::Browser::View::num( $g->{currentProduction} )
      . '/sec per unit</span></div></div></div><div class="tooltip-section">'
      . '<div class="tooltip-section-title">Purchase Info</div><div class="tooltip-costs">';
    for my $quantity ( 1, 10, 100 ) {
        my $label = $quantity == 1 ? 'Next:' : "Next $quantity:";
        $html .=
            '<div class="tooltip-cost-item"><span class="tooltip-label">'
          . $label
          . '</span><span class="tooltip-value">'
          . Bufo::Browser::View::num( $Bufo::Browser::game->generator_cost( $id, $quantity ) )
          . ' bufos</span></div>';
    }
    $html .=
      '<div class="tooltip-cost-item affordable"><span class="tooltip-label">You can afford:</span>'
      . '<span class="tooltip-value">'
      . $Bufo::Browser::game->max_affordable($id)
      . '</span></div></div></div>';
    return $html;
}

package Bufo::Browser::UpgradeItem;
use parent -norequire, 'Bufo::Browser::View';
our %FLAVOR;

sub setup {
    my ($s) = @_;
    $s->setContent( $s->render ) unless $s->{options}{adopt};
    $s->addEventListener( 'click',      sub { $s->handlePurchase( $_[0] ); return; } );
    $s->addEventListener( 'mouseenter', sub { $s->showTooltip;             return; } );
    $s->addEventListener( 'mouseleave', sub { $s->hideTooltip;             return; } );
    $s->connectToState(
        sub { return { bufos => $_[0]{resources}{bufos} } },
        sub { $s->checkAffordability( $_[0] ); return; }
    );
    return;
}

sub render {
    my ($s) = @_;
    return
        '<button type="button" class="upgrade-icon" data-id="'
      . Bufo::Browser::View::esc( $s->{upgrade}{id} || '' )
      . '" data-upgrade-id="'
      . Bufo::Browser::View::esc( $s->{upgrade}{id} || '' ) . '">'
      . $s->getUpgradeIconHtml
      . '</button>';
}

sub getUpgradeIconHtml {
    my ($s) = @_;
    my $u = $s->{upgrade};
    return '' unless $u;
    return Bufo::Browser::View::icon( $u, 'upgrade-icon-img' ) if $u->{iconPath};
    my %specific = (
        stronger_clicks_1   => '💪',
        stronger_clicks_2   => '✨👆',
        tadpole_boost_1     => '🥚',
        froglet_boost_1     => '🐸',
        global_production_1 => '🌿'
    );
    my %category = ( click => '👆', generator => '🐸', global => '🌍' );
    return
        '<div class="upgrade-icon-emoji">'
      . ( $specific{ $u->{id} } || $category{ $u->{category} } || '✨' )
      . '</div>';
}

sub update {
    my ( $s, $u ) = @_;
    $s->{upgrade} = $u;
    $s->{element}->{dataset}->{category} = $u->{category};
    $s->detachImages;
    $s->setContent( $s->render );
    $s->bindImages;
    $s->checkAffordability( { bufos => $Bufo::Browser::game->state->{resources}{bufos} } );
    return;
}

sub checkAffordability {
    my ( $s, $d ) = @_;
    return unless $s->{upgrade};
    my $can = $d->{bufos} >= $s->{upgrade}{cost};
    $s->toggleClass( 'affordable',     $can );
    $s->toggleClass( 'not-affordable', !$can );
    return;
}

sub handlePurchase {
    my ( $s, $e ) = @_;
    $e->preventDefault;
    $e->stopPropagation;
    return unless Bufo::Browser::interaction_allowed();
    return unless $s->{upgrade};
    my $ok = Bufo::Browser::View::api()->buyUpgrade( $s->{upgrade}{id} );
    Bufo::Browser::feedback( $s->{element}, $ok );
    $s->hideTooltip if $ok;
    Bufo::Browser::render();
    return;
}

sub getUpgradeFlavorText {
    my ($s) = @_;
    my $u = $s->{upgrade};
    return '' unless $u;
    return
         $u->{flavorText}
      || $FLAVOR{ $u->{id} }
      || $FLAVOR{ $u->{category} . '_default' }
      || 'A mysterious upgrade with untold powers. The frogs whisper of its potential.';
}

sub generateTooltipContent {
    my ($s) = @_;
    my $u = $s->{upgrade};
    return '' unless $u;
    my %names =
      ( click => 'Click Upgrade', generator => 'Generator Upgrade', global => 'Global Upgrade' );
    return
        '<div class="tooltip-upgrade tooltip-category-'
      . Bufo::Browser::View::esc( $u->{category} )
      . '"><div class="tooltip-header"><span class="tooltip-title">'
      . Bufo::Browser::View::esc( $u->{name} )
      . '</span><span class="tooltip-category">'
      . $names{ $u->{category} }
      . '</span></div><div class="tooltip-description">'
      . Bufo::Browser::View::esc( $u->{description} )
      . '</div><div class="tooltip-flavor">'
      . Bufo::Browser::View::esc( $s->getUpgradeFlavorText )
      . '</div><div class="tooltip-cost">'
      . Bufo::Browser::View::num( $u->{cost} )
      . ' bufos</div></div>';
}

sub showTooltip {
    my ($s) = @_;
    return if defined $s->{tooltip};
    return unless $s->{upgrade};
    my $el = Bufo::Browser::DOM::createElement( 'div',
        { classes => 'game-tooltip', parent => Bufo::Browser::DOM::document()->{body} } );
    $el->{innerHTML} = $s->generateTooltipContent;
    my $r = $s->{element}->getBoundingClientRect;
    my $w = Bufo::Browser::DOM::window()->{innerWidth};
    $el->{style}->{left} =
      Bufo::Browser::clamp( $r->{left} + $r->{width} / 2 - $el->{offsetWidth} / 2,
        6, $w - $el->{offsetWidth} - 6 ) . 'px';
    $el->{style}->{top} = Bufo::Browser::clamp( $r->{bottom} + 10,
        6, Bufo::Browser::DOM::window()->{innerHeight} - $el->{offsetHeight} - 6 ) . 'px';
    $s->{tooltip} = $el;
    Bufo::Browser::DOM::later( 10, sub { $el->{classList}->add('visible'); return; } );
    return;
}

sub hideTooltip {
    my ($s) = @_;
    return unless defined $s->{tooltip};
    my $el = delete $s->{tooltip};
    $el->{classList}->remove('visible');
    Bufo::Browser::DOM::later( 300, sub { $el->remove; return; } );
    return;
}
sub destroy { my ($s) = @_; $s->hideTooltip; $s->SUPER::destroy; return; }

@Bufo::Browser::ClickArea::BUFO_IMAGES = (
    q~./assets/images/bufo.png~,
    q~./assets/images/generators/bufo-smol.png~,
    q~./assets/images/generators/bufo-brain.png~,
    q~./assets/images/generators/bufo-cash-money.png~,
    q~./assets/images/generators/bufo-galaxy-brain.png~,
    q~./assets/images/generators/bufo-has-midas-touch.png~,
    q~./assets/images/generators/bufo-monstera.png~,
    q~./assets/images/generators/bufo-old.png~,
    q~./assets/images/generators/chonky-bufo-wants-to-be-held.png~,
    q~./assets/images/generators/hypnobufo.png~,
    q~./assets/images/generators/smol-bufo-feels-blessed.png~,
    q~./assets/images/upgrades/bufo-dapper.png~,
    q~./assets/images/upgrades/bufo-drake-yes.png~,
    q~./assets/images/upgrades/bufo-mindblown.png~,
    q~./assets/images/upgrades/bufo-simba.png~,
    q~./assets/images/upgrades/bufo-gives-star.png~,
    q~./assets/images/upgrades/bufo-give-money.png~,
    q~./assets/images/upgrades/bufo-chefkiss-with-hat.png~,
    q~./assets/images/upgrades/bufo-deal-with-it.png~,
    q~./assets/images/upgrades/bufo-gentleman.png~,
    q~./assets/images/upgrades/king-bufo.png~,
    q~./assets/images/upgrades/shut-up-and-take-my-bufo.png~,
    q~./assets/images/upgrades/bufo-caught-a-small-bufo.png~,
    q~./assets/images/upgrades/bufo-iron-throne.png~,
    q~./assets/images/upgrades/bufo-universe.png~,
    q~./assets/images/upgrades/confused-math-bufo.png~
);
%Bufo::Browser::UpgradeItem::FLAVOR = (
    q~stronger_clicks_1~ =>
      q~Your fingertips tingle with the power of a thousand taps. The frogs sense your newfound strength.~,
    q~stronger_clicks_2~ =>
      q~Advanced clicking techniques passed down from the ancient Bufo masters. Your fingers move with blinding speed.~,
    q~tadpole_boost_1~ =>
      q~A safe, nurturing environment for tadpoles to thrive. Happy tadpoles mean more bufos!~,
    q~froglet_boost_1~ =>
      q~An intensive training regimen that transforms ordinary froglets into bufo-producing champions.~,
    q~global_production_1~ =>
      q~A rising tide lifts all frogs. Your management skills benefit the entire operation.~,
    q~click_default~ =>
      q~Every click reverberates through the pond, sending ripples of power across the lily pads.~,
    q~generator_default~ =>
      q~Optimized production techniques allow your frogs to work smarter, not harder.~,
    q~global_default~ =>
      q~A rising tide lifts all frogs. Your management skills benefit the entire operation.~
);
1;
