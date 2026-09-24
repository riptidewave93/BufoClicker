package Bufo::Browser;
use strict;
use warnings;
use utf8;
use WebPerl  qw/js js_new/;
use JSON::PP qw/decode_json/;
use Bufo::Catalog;
use Bufo::Game;
use Bufo::Save;

my $document = js('document');
my $window   = js('window');
my $date     = js('Date');
my $root     = $document->getElementById('game-container');
our ( $game, $catalog, $save );
my ( %catalog_data, @requests, %nodes, %displayed, %upgrades, %achievements, %bosses );
my ( $started, $failed, $blocked, $blocked_raw, $storage_error )              = ( 0, 0, 0, '', 0 );
my ( $quantity, $last_tick, $last_render, $last_save, $hidden_at )            = ( 1, 0, 0, 0, 0 );
my ( $tree_signature, $sources_signature, $banner_id, $fight_id )             = ( '', '', '', '' );
my ( $snoozed_until, $next_move, $golden_at, $golden_until, $golden_outcome ) = ( 0, 0, 0, 0, '' );
my ( $modal_id, $modal_backdrop, $modal_unlock, $previous_focus )             = ( '', 1, 0, undef );
my ( @expiring, @feedback );
my $frenzy_signature = '';

sub now { return $date->now; }

sub escape_html {
    my ($value) = @_;
    $value = '' unless defined $value;
    $value =~ s/&/&amp;/g;
    $value =~ s/</&lt;/g;
    $value =~ s/>/&gt;/g;
    $value =~ s/"/&quot;/g;
    $value =~ s/'/&#39;/g;
    return $value;
}

sub node {
    my ($id) = @_;
    return $nodes{$id} if exists $nodes{$id};
    my $found = $document->getElementById($id);
    $nodes{$id} = $found if defined $found;
    return $found;
}

sub put_text {
    my ( $id, $text ) = @_;
    $text = '' unless defined $text;
    return if exists $displayed{$id} && $displayed{$id} eq "$text";
    my $element = node($id);
    return unless defined $element;
    $element->{textContent} = "$text";
    $displayed{$id} = "$text";
    return;
}

sub put_html {
    my ( $id, $html ) = @_;
    my $element = node($id);
    return unless defined $element;
    $element->{innerHTML} = $html;
    %nodes                = ();
    %displayed            = ();
    return;
}
sub number { return $game->format_number( $_[0], defined $_[1] ? $_[1] : 1 ); }

sub image_html {
    my ( $path, $name, $class ) = @_;
    return
        '<img src="'
      . escape_html($path)
      . '" alt="'
      . escape_html($name)
      . '" class="'
      . escape_html( $class || '' )
      . '" draggable="false">';
}

sub button_html {
    my ( $action, $label, $class, $id ) = @_;
    return
        '<button type="button" data-action="'
      . escape_html($action)
      . '" class="'
      . escape_html( $class || 'modal-button' ) . '"'
      . ( defined $id ? ' id="' . escape_html($id) . '"' : '' ) . '>'
      . escape_html($label)
      . '</button>';
}
sub clamp { my ( $n, $min, $max ) = @_; return $n < $min ? $min : $n > $max ? $max : $n; }

sub shell {
    $root->{innerHTML} = <<'HTML';
<main class="game-content" aria-label="BufoClicker">
 <div class="three-column-layout">
  <section class="column left-column" aria-label="Your pond">
   <div id="resource-display" class="resource-display"><div class="resource-count"><span id="bufo-count" class="number-value">0</span><span id="bufo-label" class="number-label">BUFOS</span></div><div class="production-rate"><span id="production-rate">0 bufos/sec</span></div></div>
   <button type="button" id="frog-display" class="frog-display" data-action="click" aria-label="Click Bufo"><img src="./assets/images/bufo.png" alt="Bufo" class="bufo-image" draggable="false"></button>
   <div id="production-stats" class="production-stats panel"><div class="panel-content"><div class="contributions"><h3>Production Sources</h3><div id="production-sources" class="contributions-list"></div></div></div></div>
  </section>
  <section class="column center-column" aria-label="Your frogs and game menu">
   <nav id="game-menu" class="game-menu" aria-label="Game menu">
    <button id="stats-button" class="menu-button" data-action="stats">Stats</button><button id="achievements-button" class="menu-button" data-action="achievements">Achievements</button><button id="transcend-button" class="menu-button menu-button--prestige" data-action="prestige" hidden>Transcend</button><button id="save-button" class="menu-button" data-action="save">Save</button><button id="reset-button" class="menu-button" data-action="reset">Reset</button>
   </nav>
   <div id="owned-generators" class="owned-generators-container panel"><div class="panel-header"><h2 id="owned-heading">Your Frogs</h2></div><div id="owned-list" class="panel-content generators-container"></div></div>
  </section>
  <section class="column right-column" aria-label="Upgrades and frog shop">
   <div id="upgrades-panel" class="upgrades-panel panel"><div class="panel-header"><h2 id="upgrades-heading">Upgrades</h2></div><div class="panel-content"><div id="upgrades-container" class="upgrades-grid"></div></div></div>
   <div id="shop-panel" class="shop-panel panel"><div class="panel-header"><h2>Frog Shop</h2></div><div class="panel-content"><div id="purchase-controls" class="purchase-controls"><div class="purchase-amount-buttons" role="group" aria-label="Purchase quantity"><button class="purchase-amount-button active" data-action="quantity" data-amount="1" aria-pressed="true">1</button><button class="purchase-amount-button" data-action="quantity" data-amount="10" aria-pressed="false">10</button><button class="purchase-amount-button" data-action="quantity" data-amount="100" aria-pressed="false">100</button><button class="purchase-amount-button" data-action="quantity" data-amount="-1" aria-pressed="false">Max</button></div></div><div id="buildings-container" class="buildings-container"></div></div></div>
  </section>
 </div>
</main>
<div id="save-status" class="save-status" role="status" hidden></div>
<div id="modal-container" class="modal-container"></div>
<div id="notification-container" class="notification-container" aria-live="polite"></div>
<div id="click-effects" class="click-effect-layer" aria-hidden="true"></div>
<div id="boss-layer" class="boss-layer"></div>
<div id="golden-layer" class="golden-bufo-layer"></div>
<div id="frenzy-layer" class="frenzy-indicator-layer"></div>
<div id="detail-tooltip" class="tooltip bufo-tooltip" role="tooltip" hidden></div>
HTML
    %nodes     = ();
    %displayed = ();
    return;
}

sub ordered_generators {
    return sort { $catalog->generators->{$a}{baseCost} <=> $catalog->generators->{$b}{baseCost} }
      keys %{ $catalog->generators };
}

sub contributions_html {
    my @ids = sort {
        $game->state->{generators}{$b}{totalProduction}
          <=> $game->state->{generators}{$a}{totalProduction}
    } grep { $game->state->{generators}{$_}{totalProduction} > 0 } ordered_generators();
    return '<div class="empty-contributions">No production sources yet.</div>' unless @ids;
    my $total = $game->production;
    return join '', map {
        my $g = $game->state->{generators}{$_};
        '<div class="contribution-item"><span class="contribution-name">'
          . escape_html( $g->{name} ) . ' (x'
          . $g->{count}
          . ')</span><span class="contribution-value">'
          . number( $g->{totalProduction} )
          . '/sec ('
          . sprintf( '%.1f', $total > 0 ? 100 * $g->{totalProduction} / $total : 0 )
          . '%)</span></div>'
    } @ids;
}

sub render_resources {
    my $amount = $game->state->{resources}{bufos};
    my $text;
    my $label = 'Bufos';
    if ( $amount < 1e12 ) {
        my $rounded = 0 + sprintf( '%.0f', $amount );
        $rounded -= 1 if $rounded > $amount;
        $text = sprintf( '%.0f', $rounded );
        $text =~ s/(\d)(?=(\d{3})+$)/$1,/g;
    } else {
        my @suffix = qw/T Qa Qi Sx Sp Oc No Dc/;
        my @names =
          qw/Trillion Quadrillion Quintillion Sextillion Septillion Octillion Nonillion Decillion/;
        my $tier   = 0;
        my $scaled = $amount / 1e12;
        while ( $scaled >= 1000 && $tier < $#suffix ) { $scaled /= 1000; ++$tier; }
        my $limited = $scaled > 999999 ? 999999 : $scaled;
        $text  = sprintf( '%.3f', $limited ) . $suffix[$tier] . ( $scaled > $limited ? '+' : '' );
        $label = $names[$tier] . ' Bufos';
    }
    put_text( 'bufo-count',      $text );
    put_text( 'bufo-label',      $label );
    put_text( 'production-rate', number( $game->production ) . ' bufos/sec' );
    return;
}

sub render_tree {
    my $state     = $game->state;
    my @ids       = ordered_generators();
    my @available = @{ $state->{upgrades}{available} };
    my $signature = join(
        '|',
        map {
            $_ . ':' . $state->{generators}{$_}{count} . ':' . $state->{generators}{$_}{unlocked}
        } @ids
      )
      . '/'
      . join( ',', @available );
    if ( $signature ne $tree_signature ) {
        my @owned   = grep { $state->{generators}{$_}{count} > 0 } @ids;
        my @visible = grep { $state->{generators}{$_}{unlocked} } @ids;
        put_html(
            'owned-list',
            @owned
            ? join(
                '',
                map {
                    my $g = $state->{generators}{$_};
                    '<button type="button" class="owned-generator category-'
                      . escape_html( $g->{category} )
                      . '" data-action="generator-detail" data-id="'
                      . $_
                      . '"><div class="generator-icon">'
                      . image_html( $g->{iconPath}, $g->{name}, 'generator-icon-img' )
                      . '</div><div class="generator-info"><div class="name-count-container"><span class="generator-name">'
                      . escape_html( $g->{name} )
                      . '</span><span class="generator-count">x'
                      . $g->{count}
                      . '</span></div><div class="generator-production"><span id="owned-rate-'
                      . $_ . '">'
                      . number( $g->{totalProduction} )
                      . '</span>/sec</div></div></button>'
                } @owned
              )
            : '<div class="empty-generators">No frogs yet! Buy some from the shop.</div>'
        );
        put_text( 'owned-heading', 'Your Frogs' . ( @owned ? ' (' . scalar(@owned) . ')' : '' ) );
        put_html(
            'buildings-container',
            join '',
            map {
                my $g = $state->{generators}{$_};
                '<div class="building-item shop-item" id="shop-item-'
                  . $_
                  . '"><div class="generator-row"><div class="generator-left"><div class="generator-icon">'
                  . image_html( $g->{iconPath}, $g->{name}, 'generator-icon-img' )
                  . '</div><div class="generator-info"><div class="generator-name-section"><span class="generator-name">'
                  . escape_html( $g->{name} )
                  . '</span><span class="generator-count">x'
                  . $g->{count}
                  . '</span></div><div class="generator-production"><span id="shop-rate-'
                  . $_
                  . '"></span>/sec per unit</div></div></div><button type="button" id="buy-'
                  . $_
                  . '" class="buy-button" data-action="buy" data-id="'
                  . $_
                  . '" aria-label="Buy '
                  . escape_html( $g->{name} ) . '">'
                  . number( $g->{currentCost} )
                  . ' bufos</button></div></div>'
            } @visible
        );
        put_html(
            'upgrades-container',
            @available
            ? join(
                '',
                map {
                    my $u = $upgrades{$_};
                    '<div class="upgrade-item" id="upgrade-'
                      . $_
                      . '"><button type="button" class="upgrade-icon" data-action="upgrade" data-id="'
                      . $_
                      . '" data-tooltip="'
                      . $_
                      . '" aria-label="Buy '
                      . escape_html( $u->{name} )
                      . '" title="'
                      . escape_html( $u->{name} ) . '">'
                      . image_html( $u->{iconPath}, $u->{name}, 'upgrade-icon-img' )
                      . '</button></div>'
                } @available
              )
            : '<div class="empty-upgrades">No upgrades available yet.</div>'
        );
        put_text( 'upgrades-heading',
            'Upgrades' . ( @available ? ' (' . scalar(@available) . ')' : '' ) );
        $tree_signature = $signature;
    }
    for my $id (@ids) {
        my $g = $state->{generators}{$id};
        put_text( 'owned-rate-' . $id, number( $g->{totalProduction} ) ) if $g->{count} > 0;
        next unless $g->{unlocked};
        put_text( 'shop-rate-' . $id, number( $g->{currentProduction} ) );
        my $cost   = $game->generator_cost( $id, $quantity );
        my $amount = $quantity == -1 ? $game->max_affordable($id) : $quantity;
        put_text(
            'buy-' . $id,
            defined $cost && $amount > 0
            ? number( $cost, 0 ) . ' bufos' . ( $quantity == -1 ? ' (' . $amount . ')' : '' )
            : 'Not enough bufos'
        );
        my $buy = node( 'buy-' . $id );
        $buy->{className} =
          'buy-button'
          . (    !defined $cost
              || $amount <= 0
              || $cost > $state->{resources}{bufos} ? ' unaffordable' : ' affordable' );
    }
    for my $id (@available) {
        my $u  = $upgrades{$id};
        my $el = node( 'upgrade-' . $id );
        $el->{className} = 'upgrade-item '
          . ( $state->{resources}{bufos} >= $u->{cost} ? 'can-afford' : 'cannot-afford' );
    }
    my $sources = contributions_html();
    if ( $sources ne $sources_signature ) {
        put_html( 'production-sources', $sources );
        $sources_signature = $sources;
    }
    my $pending  = $game->pending_prestige;
    my $prestige = node('transcend-button');
    $prestige->{hidden} = ( $pending < 1 && $state->{prestige}{lifetimePoints} < 1 ) ? 1 : 0;
    put_text( 'transcend-button', $pending > 0 ? 'Transcend (+' . $pending . ')' : 'Transcend' );
    $prestige->{className} =
      'menu-button menu-button--prestige' . ( $pending > 0 ? ' is-ready' : '' );
    $document->{body}->setAttribute( 'data-boss-stage', scalar @{ $state->{bosses}{defeated} } );
    return;
}
sub render { render_resources(); render_tree(); render_boss(); render_frenzies(); return; }

sub notification {
    my ( $message, $type, $duration ) = @_;
    my $element = $document->createElement('div');
    $element->{className}   = 'notification visible notification-' . ( $type || 'info' );
    $element->{textContent} = $message;
    node('notification-container')->appendChild($element);
    push @expiring, { element => $element, at => now() + ( $duration || 4500 ) };
    return;
}

sub feedback {
    my ( $element, $success ) = @_;
    return unless defined $element;
    my $class = $success ? 'purchase-success' : 'purchase-error';
    $element->{classList}->add($class);
    push @feedback, { element => $element, class => $class, at => now() + 500 };
    return;
}

sub click_effect {
    my ( $event, $text, $boss ) = @_;
    my $el = $document->createElement('div');
    $el->{className}   = $boss ? 'boss-damage-number' : 'perl-click-number';
    $el->{textContent} = $text;
    my $x = $event->{clientX};
    my $y = $event->{clientY};
    if ( !$x && !$y ) {
        my $r = node('frog-display')->getBoundingClientRect;
        $x = $r->{left} + $r->{width} / 2;
        $y = $r->{top} + $r->{height} / 2;
    }
    $el->{style}->{left} = clamp( $x, 55, $window->{innerWidth} - 55 ) . 'px';
    $el->{style}->{top}  = clamp( $y, 40, $window->{innerHeight} - 20 ) . 'px';
    node('click-effects')->appendChild($el);
    push @expiring, { element => $el, at => now() + 750 };
    return;
}

sub clean_effects {
    my $time = now();
    @expiring = grep {
        if ( $_->{at} <= $time ) { $_->{element}->remove; 0 }
        else                     { 1 }
    } @expiring;
    @feedback = grep {
        if ( $_->{at} <= $time ) { $_->{element}->{classList}->remove( $_->{class} ); 0 }
        else                     { 1 }
    } @feedback;
    return;
}

sub show_modal {
    my ( $id, $title, $body, $footer, $backdrop, $lock ) = @_;
    $previous_focus = $document->{activeElement} unless $modal_id;
    $modal_id       = $id;
    $modal_backdrop = defined $backdrop ? $backdrop : 1;
    $modal_unlock   = now() + ( $lock || 0 );
    put_html( 'modal-container',
            '<div id="'
          . escape_html($id)
          . '" class="modal visible'
          . ( $lock ? ' modal--input-locked' : '' )
          . '" data-backdrop="true"><section class="modal-content" role="dialog" aria-modal="true" aria-labelledby="modal-title" tabindex="-1"><header class="modal-header"><h2 id="modal-title">'
          . escape_html($title)
          . '</h2><button type="button" class="modal-close" data-action="close" aria-label="Close dialog">×</button></header><div class="modal-body">'
          . $body
          . '</div>'
          . ( $footer ? '<footer class="modal-footer">' . $footer . '</footer>' : '' )
          . '</section></div>' );
    my $content = $document->querySelector('.modal-content');
    $content->focus;
    hide_tooltip();
    return;
}

sub close_modal {
    return if now() < $modal_unlock;
    put_html( 'modal-container', '' );
    $modal_id = '';
    if ( defined $previous_focus && $previous_focus->{isConnected} ) { $previous_focus->focus; }
    $previous_focus = undef;
    return;
}

sub stat_html {
    return
        '<div class="stat-item"><div class="stat-label">'
      . escape_html( $_[0] )
      . '</div><div class="stat-value">'
      . escape_html( $_[1] )
      . '</div></div>';
}

sub duration {
    my ($seconds) = @_;
    $seconds = int($seconds);
    my $days    = int( $seconds / 86400 );
    my $hours   = int( $seconds / 3600 ) % 24;
    my $minutes = int( $seconds / 60 ) % 60;
    return
        ( $days    ? $days . 'd '    : '' )
      . ( $hours   ? $hours . 'h '   : '' )
      . ( $minutes ? $minutes . 'm ' : '' )
      . ( $seconds % 60 ) . 's';
}

sub show_stats {
    my $s        = $game->state;
    my $r        = $s->{resources};
    my $earned   = scalar @{ $s->{achievements}{unlocked} };
    my $total    = scalar @{ $catalog->achievements };
    my $owned    = 0;
    my $unlocked = 0;
    for my $g ( values %{ $s->{generators} } ) {
        $owned += $g->{count};
        ++$unlocked if $g->{unlocked};
    }
    my $body =
      '<div class="stats-modal-content"><div class="stats-container"><h3 class="stats-section-title">Resources</h3><div class="stats-row">'
      . stat_html( 'Total Bufos Produced', number( $r->{totalBufos} ) )
      . stat_html( 'Current Bufos',        number( $r->{bufos} ) )
      . '</div><div class="stats-row">'
      . stat_html( 'Total Bufos Spent',  number( $r->{totalBufos} - $r->{bufos} ) )
      . stat_html( 'Current Production', number( $game->production ) . '/sec' )
      . '</div><h3 class="stats-section-title">Game Progress</h3><div class="stats-row">'
      . stat_html( 'Time Played',
        duration( ( now() - $s->{gameSettings}{firstStartTime} ) / 1000 ) )
      . stat_html( 'Total Clicks', number( $r->{clickCount}, 0 ) )
      . '</div><div class="stats-row">'
      . stat_html( 'Achievements',       "$earned/$total (" . int( $earned * 100 / $total ) . '%)' )
      . stat_html( 'Upgrades Purchased', scalar @{ $s->{upgrades}{purchased} } )
      . '</div><div class="stats-row">'
      . stat_html( 'Generators Unlocked', $unlocked . '/' . scalar( keys %{ $s->{generators} } ) )
      . stat_html( 'Total Generators Owned', $owned )
      . '</div><h3 class="stats-section-title">Production Details</h3><div class="stats-row production-details">'
      . stat_html( 'Per Second', number( $game->production ) )
      . stat_html( 'Per Minute', number( $game->production * 60 ) )
      . stat_html( 'Per Hour',   number( $game->production * 3600 ) )
      . '</div></div><div class="contributions-container"><h3 class="stats-section-title">Production Sources</h3><div class="contributions-list">'
      . contributions_html()
      . '</div></div></div>';
    show_modal( 'stats-modal', 'Game Statistics',
        $body, button_html( 'saves', 'Save tools' ) . button_html( 'close', 'Close' ) );
    return;
}

sub reward_text {
    my ($reward) = @_;
    return '' unless ref $reward eq 'HASH';
    my %labels = (
        productionBoost => 'production boost',
        clickBoost      => 'click boost',
        generatorBoost  => 'generator boost',
        bufoBonus       => 'Bufos',
        unlockGenerator => 'generator unlocked',
        unlockUpgrade   => 'upgrade unlocked',
        unlockFeature   => 'feature unlocked'
    );
    return 'Reward: '
      . (
        defined $reward->{value}
        ? $reward->{value} . ( $reward->{type} =~ /Boost$/ ? 'x ' : ' ' )
        : ''
      )
      . ( $labels{ $reward->{type} } || 'Special bonus' )
      . ( defined $reward->{target} ? ' (' . $reward->{target} . ')' : '' );
}

sub show_achievements {
    my @ids     = @{ $game->state->{achievements}{unlocked} };
    my %icons   = ( generators => '🏭', production => '💰', clicks => '👆', special => '🎮' );
    my $total   = scalar @{ $catalog->achievements };
    my $percent = int( @ids * 100 / $total );
    my $body =
      '<div class="achievements-container"><div class="achievement-progress-bar"><div class="achievement-progress-text">'
      . scalar(@ids) . ' of '
      . $total
      . ' Achievements Unlocked ('
      . $percent
      . '%)</div><div class="achievement-progress-outer"><div class="achievement-progress-inner" style="width:'
      . $percent
      . '%"></div></div></div><div class="achievements-list">';
    $body .= @ids
      ? join(
        '',
        map {
            my $a = $achievements{$_};
            '<div class="achievement-item category-'
              . escape_html( $a->{category} )
              . '" data-id="'
              . $_
              . '"><div class="achievement-icon">'
              . (
                defined $a->{iconPath}
                ? image_html( $a->{iconPath}, $a->{name}, 'achievement-icon-img' )
                : '<div class="achievement-icon-emoji">'
                  . ( $icons{ $a->{category} } || '🏆' )
                  . '</div>'
              )
              . '</div><div class="achievement-info"><div class="achievement-name">'
              . escape_html( $a->{name} )
              . '</div><div class="achievement-description">'
              . escape_html( $a->{description} )
              . '</div>'
              . (
                ref $a->{reward} eq 'HASH'
                ? '<div class="achievement-reward">'
                  . escape_html( reward_text( $a->{reward} ) )
                  . '</div>'
                : '' )
              . '</div></div>'
        } @ids
      )
      : '<div class="empty-achievements"><p>No achievements unlocked yet.</p><p>Keep playing to unlock achievements!</p></div>';
    show_modal( 'achievements-modal', 'Achievements', $body . '</div></div>' );
    return;
}

sub show_prestige {
    my $pending = $game->pending_prestige;
    my $p       = $game->state->{prestige};
    my $body =
      '<div class="prestige-modal"><p class="prestige-modal__blurb">Transcend to fold this run into the <strong>Transcendence Bufoplier</strong>. Your bufos, generators, upgrades and current boss ladder reset. Each Bufoplier point permanently adds 10% to all production and click power. Achievements and earned boss bonuses remain.</p><div class="prestige-modal__stats"><div><span>Bufoplier points</span><strong>'
      . $p->{lifetimePoints}
      . '</strong></div><div><span>Times transcended</span><strong>'
      . $p->{transcendences}
      . '</strong></div><div><span>Current multiplier</span><strong>x'
      . sprintf( '%.2f', $game->prestige_multiplier )
      . '</strong></div><div class="is-gain"><span>Points if you transcend now</span><strong>+'
      . $pending
      . '</strong></div><div class="is-gain"><span>New multiplier</span><strong>x'
      . sprintf( '%.2f', 1 + ( $p->{lifetimePoints} + $pending ) * .1 )
      . '</strong></div></div>'
      . (
        $pending < 1
        ? '<p class="prestige-modal__locked">Reach 1,000,000,000 total bufos this run to earn your first point.</p>'
        : ''
      ) . '</div>';
    show_modal(
        'prestige-modal',
        'Transcendence Bufoplier',
        $body,
        button_html( 'close', 'Not yet', 'modal-button cancel-button' )
          . (
            $pending > 0
            ? button_html(
                'confirm-prestige',
                'Transcend for +' . $pending,
                'modal-button confirm-button'
              )
            : ''
          )
    );
    return;
}

sub generator_detail {
    my ($id) = @_;
    my $g = $game->state->{generators}{$id};
    return unless $g;
    show_modal( 'generator-modal', $g->{name},
            '<p>'
          . escape_html( $g->{detailedDescription} || $g->{description} )
          . '</p><div class="stats-row">'
          . stat_html( 'Owned',            $g->{count} )
          . stat_html( 'Base production',  number( $g->{baseProduction} ) . '/sec' )
          . stat_html( 'Current per unit', number( $g->{currentProduction} ) . '/sec' )
          . stat_html( 'Total production', number( $g->{totalProduction} ) . '/sec' )
          . '</div>' );
    return;
}

sub show_tooltip {
    my ( $id, $target ) = @_;
    my $u = $upgrades{$id};
    return unless $u;
    my $tooltip = node('detail-tooltip');
    $tooltip->{innerHTML} =
        '<strong>'
      . escape_html( $u->{name} )
      . '</strong><p>'
      . escape_html( $u->{description} )
      . '</p><p class="tooltip-cost">'
      . number( $u->{cost}, 0 )
      . ' bufos</p>';
    $tooltip->{hidden} = 0;
    my $r     = $target->getBoundingClientRect;
    my $width = clamp( $window->{innerWidth} - 24, 180, 300 );
    $tooltip->{style}->{width} = $width . 'px';
    $tooltip->{style}->{left} =
      clamp( $r->{left} - $width, 12, $window->{innerWidth} - $width - 12 ) . 'px';
    $tooltip->{style}->{top} = clamp( $r->{top}, 12, $window->{innerHeight} - 160 ) . 'px';
    return;
}

sub hide_tooltip {
    my $tooltip = node('detail-tooltip');
    $tooltip->{hidden} = 1 if defined $tooltip;
    return;
}

sub render_boss {
    my $time  = now();
    my $fight = $game->active_boss;
    if ( defined $fight ) {
        my $boss = $fight->{boss};
        if ( $fight_id ne $boss->{id} ) {
            $fight_id  = $boss->{id};
            $banner_id = '';
            $next_move = 0;
            put_html( 'boss-layer',
                '<div class="boss-fight-overlay"><div class="boss-fight-hud"><div class="boss-fight-hud__name">'
                  . escape_html( $boss->{name} )
                  . '</div><div class="boss-health-bar"><div id="boss-health-fill" class="boss-health-bar__fill"></div><div id="boss-health-text" class="boss-health-bar__text"></div></div><div id="boss-timer" class="boss-fight-hud__timer"></div>'
                  . button_html( 'retreat', 'Retreat', 'boss-fight-hud__retreat' )
                  . '</div><button type="button" id="boss-sprite" class="boss-sprite" data-action="boss-hit" aria-label="Click '
                  . escape_html( $boss->{name} ) . '">'
                  . image_html( $boss->{iconPath}, $boss->{name} )
                  . '</button></div>' );
            $document->{body}->{classList}->add('boss-fight-active');
        }
        put_text( 'boss-health-text',
            number( $fight->{health} ) . ' / ' . number( $fight->{maxHealth} ) . ' HP' );
        node('boss-health-fill')->{style}->{width} =
          clamp( 100 * $fight->{health} / $fight->{maxHealth}, 0, 100 ) . '%';
        put_text( 'boss-timer', sprintf( '%.1fs', clamp( $fight->{remainingMs} / 1000, 0, 30 ) ) );
        node('boss-timer')->{className} = 'boss-fight-hud__timer'
          . ( $fight->{remainingMs} <= 10000 ? ' boss-fight-hud__timer--urgent' : '' );
        if ( $time >= $next_move ) {
            my $sprite = node('boss-sprite');
            my $size   = $window->{innerWidth} <= 1024 ? 88 : 110;
            $sprite->{style}->{left} = clamp(
                ( .1 + rand(.75) ) * $window->{innerWidth},
                $size / 2 + 8,
                $window->{innerWidth} - $size / 2 - 8
            ) . 'px';
            $sprite->{style}->{top} = clamp( ( .15 + rand(.65) ) * $window->{innerHeight},
                170, $window->{innerHeight} - $size / 2 - 8 ) . 'px';
            $next_move = $time + 3000;
        }
        return;
    }
    if ($fight_id) {
        put_html( 'boss-layer', '' );
        $fight_id = '';
        $document->{body}->{classList}->remove('boss-fight-active');
    }
    my $boss = $game->available_boss;
    if ( !defined $boss || $time < $snoozed_until || $modal_id ) {
        if ($banner_id) { put_html( 'boss-layer', '' ); $banner_id = ''; }
        return;
    }
    if ( $banner_id ne $boss->{id} ) {
        $banner_id = $boss->{id};
        my $health = $boss->{baseHealth} * $game->prestige_multiplier * $game->boss_multiplier;
        put_html(
            'boss-layer',
            '<div class="boss-banner">'
              . image_html( $boss->{iconPath}, $boss->{name}, 'boss-banner__portrait' )
              . '<div class="boss-banner__body"><div class="boss-banner__title">A Boss Has Appeared!</div><div class="boss-banner__name">'
              . escape_html( $boss->{name} )
              . '</div><div class="boss-banner__flavor">'
              . escape_html( $boss->{flavorText} )
              . '</div></div><div class="boss-banner__actions">'
              . button_html( 'fight', 'Fight! (' . number($health) . ' HP, 30s)',
                'boss-banner__fight' )
              . button_html( 'later', 'Not yet', 'boss-banner__later' )
              . '</div></div>'
        );
    }
    return;
}

sub boss_result {
    my ( $id, $won ) = @_;
    my $boss = $bosses{$id};
    return unless $boss;
    my $body =
        '<div class="boss-result boss-result--'
      . ( $won ? 'win' : 'lose' ) . '">'
      . image_html( $boss->{iconPath}, $boss->{name}, 'boss-result__portrait' );
    $body .=
      $won
      ? '<p>Your bufos will remember this croak for generations.</p><p class="boss-result__area">The world around you has changed. You have entered a new area.</p><p class="boss-result__reward">Permanent multiplier is now <strong>x'
      . sprintf( '%.2f', $game->boss_multiplier )
      . '</strong> to all bufo production and click power.</p>'
      : '<p>Your bufos scatter, and your bufo stash resets to 0.</p><p class="boss-result__hint">Your generators, upgrades and prestige are untouched. Buy more click upgrades and try again whenever you are ready.</p>';
    render_boss();
    show_modal(
        $won ? 'boss-victory-modal'         : 'boss-defeat-modal',
        $won ? $boss->{name} . ' Defeated!' : 'Defeated by ' . $boss->{name} . '...',
        $body . '</div>',
        button_html( 'close', $won ? 'Nice!' : 'Try again later', 'modal-button confirm-button' ),
        0,
        800
    );
    return;
}

sub process_events {
    my $events = $game->drain_events;
    for my $event (@$events) {
        if ( $event->{type} eq 'achievement' ) {
            my $a = $achievements{ $event->{id} };
            next unless $a;
            notification(
                'Achievement unlocked: ' . $a->{name} . '. ' . reward_text( $a->{reward} ),
                'success', 6000 );
        } elsif ( $event->{type} eq 'boss_won' || $event->{type} eq 'boss_lost' ) {
            boss_result( $event->{id}, $event->{type} eq 'boss_won' );
            persist(0);
        }
    }
    return;
}

sub spawn_golden {
    return if $golden_until || $hidden_at || !$started;
    $golden_outcome = $game->golden_outcome( rand() );
    $golden_until   = now() + 13000;
    put_html( 'golden-layer',
        '<button type="button" id="golden-bufo" class="golden-bufo" data-action="golden" aria-label="Golden Bufo, click me!">'
          . image_html( './assets/images/generators/bufo-has-midas-touch.png', 'Golden Bufo' )
          . '</button>' );
    my $el   = node('golden-bufo');
    my $size = $window->{innerWidth} <= 1024 ? 76 : 92;
    $el->{style}->{left} =
      clamp( ( .08 + rand(.76) ) * $window->{innerWidth}, 8, $window->{innerWidth} - $size - 8 )
      . 'px';
    $el->{style}->{top} =
      clamp( ( .14 + rand(.64) ) * $window->{innerHeight}, 8, $window->{innerHeight} - $size - 8 )
      . 'px';
    $el->{style}->setProperty( '--ttl', '13000ms' );
    return;
}

sub clear_golden {
    put_html( 'golden-layer', '' );
    $golden_until   = 0;
    $golden_outcome = '';
    $golden_at      = now() + 90000 + rand(100000);
    return;
}

sub render_frenzies {
    my $f         = $game->active_frenzies( now() );
    my @active    = grep { defined $f->{$_} } qw/production click/;
    my $signature = join( ',', @active );
    if ( $signature ne $frenzy_signature ) {
        put_html(
            'frenzy-layer',
            join(
                '',
                map {
                        '<div class="frenzy-badge frenzy-badge--'
                      . $_
                      . '"><span id="frenzy-label-'
                      . $_
                      . '" class="frenzy-badge__label"></span><span id="frenzy-time-'
                      . $_
                      . '" class="frenzy-badge__time"></span><span class="frenzy-badge__bar"><span id="frenzy-fill-'
                      . $_
                      . '" class="frenzy-badge__bar-fill"></span></span></div>'
                } @active
            )
        );
        $frenzy_signature = $signature;
    }
    for my $kind (@active) {
        my $duration  = $kind eq 'production' ? 30000 : 15000;
        my $remaining = clamp( $f->{$kind}{endsAt} - now(), 0, $duration );
        put_text(
            'frenzy-label-' . $kind,
            ( $kind eq 'production' ? 'Bufo Frenzy' : 'Click Frenzy' ) . ' x'
              . $f->{$kind}{multiplier}
        );
        put_text( 'frenzy-time-' . $kind, sprintf( '%.1fs', $remaining / 1000 ) );
        node( 'frenzy-fill-' . $kind )->{style}->{width} = ( 100 * $remaining / $duration ) . '%';
    }
    return;
}

sub storage { return $window->{localStorage}; }

sub save_warning {
    my ($message) = @_;
    my $status = node('save-status');
    $status->{hidden}      = 0;
    $status->{textContent} = $message;
    return;
}

sub persist {
    my ($manual) = @_;
    if ($blocked) { show_recovery() if $manual; return 0; }
    my $time = now();
    my $ok   = eval {
        storage()->setItem( Bufo::Save->key, $save->serialize( $game->state, now => $time ) );
        1;
    };
    if ( !$ok ) {
        save_warning(
            'Saving is unavailable. Keep this tab open and export your progress from Stats > Save tools.'
        );
        notification( 'Could not save. Your game is still in this tab.', 'error' )
          if $manual || !$storage_error;
        $storage_error = 1;
        return 0;
    }
    $game->mark_saved($time);
    $last_save     = $time;
    $storage_error = 0;
    node('save-status')->{hidden} = 1;
    notification( 'Game saved successfully.', 'success' ) if $manual;
    return 1;
}
sub export_codec { my ($raw) = @_; return $window->btoa( $window->encodeURIComponent($raw) ); }

sub import_codec {
    my ($text) = @_;
    $text =~ s/^\s+|\s+$//g;
    die 'The save is empty.' unless length $text;
    die 'The save is too large.' if length($text) > 4_000_000;
    return $text                 if $text =~ /^\{/;
    return $window->decodeURIComponent( $window->atob($text) );
}

sub show_saves {
    show_modal(
        'save-tools-modal',
        'Save tools',
        '<p>Export a backup or import a save. Imports replace this browser’s current game only after validation and a successful save.</p><label for="save-transfer">Save data</label><textarea id="save-transfer" rows="7" spellcheck="false" placeholder="Paste an exported save or JSON here"></textarea><p id="save-transfer-status" role="status"></p>',
        button_html( 'export', 'Export current game' )
          . button_html( 'import', 'Import save', 'modal-button confirm-button' )
          . button_html( 'close',  'Close' )
    );
    return;
}

sub show_recovery {
    show_modal(
        'save-recovery-modal',
        'Saved game needs attention',
        '<p>The saved game could not be loaded. Automatic saving is paused so the original data stays intact.</p><p>Export the stored data for safekeeping, import a valid backup, or explicitly start a new game.</p><label for="save-transfer">Save data</label><textarea id="save-transfer" rows="7" spellcheck="false" placeholder="Paste a valid backup here"></textarea><p id="save-transfer-status" role="status"></p>',
        button_html( 'export-raw', 'Export stored data' )
          . button_html( 'import', 'Import backup' )
          . button_html( 'reset',  'Start a new game', 'modal-button cancel-button' ),
        0
    );
    return;
}

sub accept_game {
    my ($candidate) = @_;
    my $time = now();
    storage()->setItem( Bufo::Save->key, $save->serialize( $candidate->state, now => $time ) );
    $candidate->mark_saved($time);
    $game              = $candidate;
    $blocked           = 0;
    $blocked_raw       = '';
    $storage_error     = 0;
    $last_save         = $time;
    $last_tick         = $time;
    $tree_signature    = '';
    $sources_signature = '';
    $banner_id         = '';
    $fight_id          = '';
    $snoozed_until     = 0;
    put_html( 'boss-layer', '' );
    $document->{body}->{classList}->remove('boss-fight-active');
    clear_golden();
    node('save-status')->{hidden} = 1;
    render();
    return;
}

sub import_save {
    my $area = node('save-transfer');
    return unless defined $area;
    my $ok = eval {
        my $time      = now();
        my $state     = $save->parse( import_codec( $area->{value} ), now => $time );
        my $candidate = Bufo::Game->new( catalog => $catalog, now => $time, state => $state );
        $candidate->credit_elapsed(
            $save->elapsed_seconds(
                last_tick  => $state->{gameSettings}{lastTick},
                now        => $time,
                minimum_ms => 60000
            ),
            $time
        );
        accept_game($candidate);
        1;
    };
    if ( !$ok ) {
        put_text( 'save-transfer-status',
            'Import failed. Your current game is unchanged. ' . clean_error($@) );
        return;
    }
    close_modal();
    notification( 'Save imported successfully.', 'success' );
    return;
}

sub clean_error {
    my ($error) = @_;
    $error =~ s/\s+at\s+\S+\s+line\s+\d+.*//s;
    $error =~ s/[\r\n]+/ /g;
    return substr( $error, 0, 240 );
}

sub show_reset {
    show_modal(
        'reset-confirmation-modal',
        'Reset Game',
        '<p>Are you sure you want to reset your game?</p><p>All progress in this Perl game will be lost. Any original legacy save remains untouched.</p>',
        button_html( 'close', 'Cancel', 'modal-button cancel-button' )
          . button_html( 'confirm-reset', 'Reset Game', 'modal-button confirm-button' )
    );
    return;
}

sub reset_game {
    my $ok = eval { accept_game( Bufo::Game->new( catalog => $catalog, now => now() ) ); 1 };
    if ( !$ok ) {
        notification(
            'Reset failed because the new game could not be saved. Your current game is unchanged.',
            'error'
        );
        return;
    }
    close_modal();
    notification( 'Game reset successfully.', 'success' );
    return;
}

sub load_game {
    my $time = now();
    my $ok   = eval {
        my $store  = storage();
        my $new    = $store->getItem( Bufo::Save->key );
        my $legacy = defined $new ? undef : $store->getItem( Bufo::Save->legacy_key );
        $blocked_raw = defined $new ? $new : defined $legacy ? $legacy : '';
        my $loaded    = $save->choose_load( new_raw => $new, legacy_raw => $legacy, now => $time );
        my $candidate = Bufo::Game->new(
            catalog => $catalog,
            now     => $time,
            defined $loaded->{state} ? ( state => $loaded->{state} ) : ()
        );
        if ( defined $loaded->{state} ) {
            my $seconds = $save->elapsed_seconds(
                last_tick  => $loaded->{state}{gameSettings}{lastTick},
                now        => $time,
                minimum_ms => 60000
            );
            my $credit = $candidate->credit_elapsed( $seconds, $time );
            notification(
                'Welcome back! Your frogs earned '
                  . number_from( $candidate, $credit->{production} || 0 )
                  . ' bufos while you were away.',
                'success', 6500
            ) if $seconds > 0 && ( $credit->{production} || 0 ) > 0;
        }
        $game = $candidate;
        if ( $loaded->{source} eq 'legacy' ) {
            $store->setItem( Bufo::Save->key, $save->serialize( $candidate->state, now => $time ) );
            $game->mark_saved($time);
            notification( 'Your existing game was imported. The original save is unchanged.',
                'success', 6500 );
        }
        $blocked_raw = '';
        1;
    };
    if ( !$ok ) {
        $game    = Bufo::Game->new( catalog => $catalog, now => $time ) unless defined $game;
        $blocked = 1;
        save_warning('The stored save needs attention. Automatic saving is paused.');
        show_recovery();
    }
    return;
}
sub number_from { return $_[0]->format_number( $_[1] ); }

sub on_click {
    my ($event) = @_;
    my $target = $event->{target};
    return unless defined $target;
    my $control = $target->closest('[data-action]');
    if ( !defined $control ) {
        if ( $modal_id && $modal_backdrop && defined $target->getAttribute('data-backdrop') ) {
            close_modal();
        }
        return;
    }
    my $action = $control->getAttribute('data-action');
    if ( $action eq 'reload' ) { $window->{location}->reload; return; }
    return unless $started;
    $event->preventDefault;
    if ( $modal_id && now() < $modal_unlock ) { return; }
    my $id = $control->getAttribute('data-id');
    if    ( $action eq 'close' )         { close_modal(); }
    elsif ( $action eq 'stats' )         { show_stats(); }
    elsif ( $action eq 'achievements' )  { show_achievements(); }
    elsif ( $action eq 'prestige' )      { show_prestige(); }
    elsif ( $action eq 'save' )          { persist(1); }
    elsif ( $action eq 'saves' )         { $blocked ? show_recovery() : show_saves(); }
    elsif ( $action eq 'reset' )         { show_reset(); }
    elsif ( $action eq 'confirm-reset' ) { reset_game(); }
    elsif ( $action eq 'import' )        { import_save(); }
    elsif ( $action eq 'export' || $action eq 'export-raw' ) {
        my $raw =
          $action eq 'export-raw' ? $blocked_raw : $save->serialize( $game->state, now => now() );
        my $area = node('save-transfer');
        $area->{value} = export_codec($raw);
        $area->focus;
        $area->select;
        put_text( 'save-transfer-status', 'Copy this save and keep it somewhere safe.' );
    } elsif ($blocked) {
        show_recovery();
    } elsif ( $action eq 'click' ) {
        my $result = $game->click( now() );
        if ( $result->{ok} ) {
            click_effect( $event, '+' . number( $result->{bufosGained} ), 0 );
            feedback( $control, 1 );
            render_resources();
            process_events();
        }
    } elsif ( $action eq 'quantity' ) {
        $quantity = 0 + $control->getAttribute('data-amount');
        my $buttons = $document->querySelectorAll('.purchase-amount-button');
        for my $i ( 0 .. $buttons->{length} - 1 ) {
            my $b      = $buttons->item($i);
            my $active = $b->getAttribute('data-amount') == $quantity;
            $b->{className} = 'purchase-amount-button' . ( $active ? ' active' : '' );
            $b->setAttribute( 'aria-pressed', $active ? 'true' : 'false' );
        }
        render_tree();
    } elsif ( $action eq 'buy' || $action eq 'upgrade' ) {
        my $result =
          $action eq 'buy' ? $game->buy_generator( $id, $quantity ) : $game->buy_upgrade($id);
        if ( $result->{ok} ) {
            hide_tooltip();
            render();
            feedback( node( $action eq 'buy' ? 'shop-item-' . $id : 'upgrades-panel' ), 1 );
            process_events();
            persist(0);
        } else {
            feedback( $control, 0 );
            notification( $result->{error}, 'warning', 2200 );
        }
    } elsif ( $action eq 'generator-detail' ) {
        generator_detail($id);
    } elsif ( $action eq 'confirm-prestige' ) {
        my $candidate = Bufo::Game->new(
            catalog => $catalog,
            now     => now(),
            state   => $save->parse( $save->serialize( $game->state, now => now() ), now => now() )
        );
        my $result = $candidate->prestige;
        if ( $result->{ok} ) {
            my $ok = eval { accept_game($candidate); 1 };
            if ($ok) {
                close_modal();
                process_events();
                notification( 'Transcended! +' . $result->{gained} . ' Bufoplier points.',
                    'success', 6000 );
            } else {
                notification( 'Could not save transcendence. Your current run is unchanged.',
                    'error' );
            }
        }
    } elsif ( $action eq 'fight' ) {
        my $r = $game->start_boss( now() );
        render_boss();
        notification( $r->{error}, 'warning' ) unless $r->{ok};
    } elsif ( $action eq 'later' ) {
        $snoozed_until = now() + 60000 + rand(120000);
        render_boss();
    } elsif ( $action eq 'retreat' ) {
        $game->retreat_boss;
        render_boss();
    } elsif ( $action eq 'boss-hit' ) {
        my $r = $game->hit_boss( now() );
        click_effect( $event, '-' . number( $r->{damage} ), 1 ) if $r->{ok};
        process_events();
        render_boss();
    } elsif ( $action eq 'golden' ) {
        if ( $golden_until > now() ) {
            my $r = $game->collect_golden( $golden_outcome, now() );
            clear_golden();
            notification( $r->{label} . ' ' . $r->{detail}, 'success', 6000 ) if $r->{ok};
            process_events();
            render();
            persist(0);
        }
    }
    return;
}

sub on_pointer_over {
    my ($event) = @_;
    return unless $started;
    my $target = $event->{target}->closest('[data-tooltip]');
    show_tooltip( $target->getAttribute('data-tooltip'), $target ) if defined $target;
    return;
}
sub on_pointer_out { hide_tooltip() if $started; return; }

sub on_keydown {
    my ($event) = @_;
    return unless $modal_id;
    if ( $event->{key} eq 'Escape' ) {
        if ($modal_backdrop) { $event->preventDefault; close_modal(); }
        return;
    }
    return unless $event->{key} eq 'Tab';
    my $buttons = $document->querySelectorAll('.modal-content button, .modal-content textarea');
    return unless $buttons->{length};
    my $first  = $buttons->item(0);
    my $last   = $buttons->item( $buttons->{length} - 1 );
    my $active = $document->{activeElement};
    if ( $event->{shiftKey} ) {
        if ( $active->isSameNode($first) || $active->{className} eq 'modal-content' ) {
            $event->preventDefault;
            $last->focus;
        }
    } elsif ( $active->isSameNode($last) ) {
        $event->preventDefault;
        $first->focus;
    }
    return;
}

sub on_dragstart {
    my ($event) = @_;
    my $target = $event->{target}->closest('.bufo-image, .boss-sprite, .golden-bufo');
    $event->preventDefault if defined $target;
    return;
}

sub on_visibility {
    return unless $started;
    my $time = now();
    if ( $document->{hidden} ) {
        return if $hidden_at;
        $hidden_at = $time;
        $game->pause($time);
        clear_golden();
        persist(0);
    } elsif ($hidden_at) {
        my $seconds =
          $save->elapsed_seconds( last_tick => $hidden_at, now => $time, minimum_ms => 0 );
        $game->credit_elapsed( $seconds, $time );
        $game->resume($time);
        $hidden_at = 0;
        $last_tick = $time;
        $golden_at = $time + 45000 + rand(45000);
        process_events();
        render();
        persist(0);
    }
    return;
}

sub on_pagehide {
    return unless $started;
    if ( !$hidden_at ) { $hidden_at = now(); $game->pause($hidden_at); }
    persist(0);
    return;
}
sub on_pageshow { on_visibility(); return; }
sub on_resize { hide_tooltip(); $next_move = 0; render_boss() if $started; return; }

sub on_tick {
    return unless $started && !$hidden_at;
    my $time = now();
    if ( !$blocked ) { $game->tick( ( $time - $last_tick ) / 1000, $time ); }
    $last_tick = $time;
    clean_effects();
    process_events();
    if ( $modal_id && $time >= $modal_unlock ) {
        my $modal = node($modal_id);
        $modal->{classList}->remove('modal--input-locked') if defined $modal;
    }
    if ( $time - $last_render >= 250 ) { render(); $last_render = $time; }
    if ( !$blocked && !$modal_id ) {
        if    ( $golden_until && $time >= $golden_until ) { clear_golden(); }
        elsif ( !$golden_until && $time >= $golden_at )   { spawn_golden(); }
    }
    if ( !$blocked && $game->state->{gameSettings}{autoSave} && $time - $last_save >= 60000 ) {
        persist(0);
        $last_save = $time;
    }
    return;
}

sub fatal {
    my ($message) = @_;
    $failed = 1;
    $root->{innerHTML} =
        '<div class="startup-status" role="alert"><h1>The pond could not open</h1><p>'
      . escape_html($message)
      . '</p><p>Your saved game has not been changed.</p>'
      . button_html( 'reload', 'Try again', 'menu-button' )
      . '</div>';
    $root->setAttribute( 'aria-busy', 'false' );
    return;
}

sub start {
    return if $started || $failed;
    my $ok = eval {
        $catalog      = Bufo::Catalog->new(%catalog_data);
        %upgrades     = map { $_->{id} => $_ } @{ $catalog->upgrades };
        %achievements = map { $_->{id} => $_ } @{ $catalog->achievements };
        %bosses       = map { $_->{id} => $_ } @{ $catalog->bosses };
        $save         = Bufo::Save->new( catalog => $catalog );
        shell();
        load_game();
        $started   = 1;
        $last_tick = now();
        $last_save = $last_tick;
        $golden_at = $last_tick + 45000 + rand(45000);
        render();
        $root->setAttribute( 'aria-busy',  'false' );
        $root->setAttribute( 'data-ready', 'true' );
        $window->setInterval( \&on_tick, 100 );
        1;
    };
    fatal( clean_error($@) ) unless $ok;
    return;
}

sub on_catalog_load {
    my ($event) = @_;
    return if $failed;
    my $request = $event->{target};
    if ( $request->{status} != 200 ) {
        fatal('A required game catalog could not be downloaded. Please retry.');
        return;
    }
    my $ok =
      eval { $catalog_data{ $request->{bufoCatalog} } = decode_json( $request->{responseText} ); 1 };
    if ( !$ok ) { fatal('A required game catalog is invalid. Please retry.'); return; }
    start() if keys(%catalog_data) == 3;
    return;
}

sub on_catalog_error {
    fatal('A required game catalog could not be downloaded. Check your connection and retry.');
    return;
}

$document->addEventListener( 'click',            \&on_click );
$document->addEventListener( 'pointerover',      \&on_pointer_over );
$document->addEventListener( 'pointerout',       \&on_pointer_out );
$document->addEventListener( 'keydown',          \&on_keydown );
$document->addEventListener( 'dragstart',        \&on_dragstart );
$document->addEventListener( 'visibilitychange', \&on_visibility );
$window->addEventListener( 'pagehide', \&on_pagehide );
$window->addEventListener( 'pageshow', \&on_pageshow );
$window->addEventListener( 'resize',   \&on_resize );

for my $name (qw/generators upgrades achievements/) {
    my $request = js_new('XMLHttpRequest');
    $request->{bufoCatalog} = $name;
    $request->open( 'GET', './assets/data/' . $name . '.json', 1 );
    $request->{timeout} = 20000;
    $request->addEventListener( 'load',    \&on_catalog_load );
    $request->addEventListener( 'error',   \&on_catalog_error );
    $request->addEventListener( 'timeout', \&on_catalog_error );
    push @requests, $request;
    $request->send;
}
1;
