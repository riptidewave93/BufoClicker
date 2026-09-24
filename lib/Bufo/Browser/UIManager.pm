package Bufo::Browser::UIManager;
use strict;
use warnings;
use utf8;
use Bufo::Browser::Lists;
use Bufo::Browser::Special;
use Bufo::Browser::Templates;
my $instance;

sub getInstance {
    return $instance ||= bless { components => {}, unsubscribers => [] }, __PACKAGE__;
}
sub getUIManager { return getInstance(); }

sub init {
    my ( $s, $id ) = @_;
    $id ||= 'game-container';
    my $root = Bufo::Browser::DOM::document()->getElementById($id);
    return unless defined $root;
    $s->destroy if keys %{ $s->{components} };
    $s->{root} = $root;
    $s->createBaseStructure;
    $s->initializeComponents;
    $s->initializeMenu;
    $s->setupEventListeners;
    $s->setupVisibilityTracking;
    $s->setupResizeHandling;
    $s->createAchievementNotificationContainer;
    $s->startUpdateLoop;
    return;
}
sub createBaseStructure { my ($s) = @_; Bufo::Browser::shell( $s->{root} ); return; }

sub initializeComponents {
    my ($s) = @_;
    my %spec = (
        resourceDisplay => [ 'ResourceDisplay', 'resource-display' ],
        clickArea       => [ 'ClickArea',       'frog-display' ],
        generatorList   => [ 'GeneratorList',   'owned-generators' ],
        shop            => [ 'Shop',            'buildings-container' ],
        upgradeList     => [ 'UpgradeList',     'upgrades-container' ],
        productionStats => [ 'ProductionStats', 'production-stats' ],
        goldenBufo      => [ 'GoldenBufo',      undef ],
        bossFight       => [ 'BossFight',       undef ]
    );
    for my $key (
        qw/resourceDisplay clickArea generatorList shop upgradeList productionStats goldenBufo bossFight/
      )
    {
        my ( $name, $id ) = @{ $spec{$key} };
        my $class = 'Bufo::Browser::' . $name;
        my $o     = { adopt => 1 };
        $o->{id} = $id if defined $id;
        my $c = $class->new($o);
        $s->{components}{$key} = $c;
        $c->init;
    }
    return;
}
sub getComponent { return $_[0]{components}{ $_[1] }; }

sub refresh {
    my ($s) = @_;
    $s->{components}{generatorList}->refreshGenerators;
    $s->{components}{shop}->refreshGenerators;
    $s->{components}{upgradeList}->refreshUpgrades;
    $s->{components}{productionStats}->refreshStats;
    $s->refreshTranscendButton;
    return;
}

sub initializeMenu {
    my ($s) = @_;
    Bufo::Browser::DOM::listen( Bufo::Browser::DOM::document(), 'click',
        \&Bufo::Browser::on_click );
    $s->refreshTranscendButton;
    return;
}

sub _listen {
    my ( $s, $event, $cb ) = @_;
    $Bufo::Browser::events->on( $event, $cb );
    push @{ $s->{unsubscribers} }, sub { $Bufo::Browser::events->off( $event, $cb ); return; };
    return;
}

sub setupEventListeners {
    my ($s) = @_;
    $s->_listen(
        'UPGRADES_AVAILABLE',
        sub {
            my $d     = $_[0];
            my $count = ref $d eq 'ARRAY' ? scalar @$d : scalar @{ $d->{upgrades} || [] };
            $s->updateTabNotification( 'upgrades', $count > 0 );
            return;
        }
    );
    $s->_listen(
        'ACHIEVEMENT_UNLOCKED',
        sub {
            $s->showAchievementNotification(
                { achievement => $_[0]{achievement}, duration => 5000 } );
            return;
        }
    );
    $s->_listen(
        'EXPLORATION_COMPLETED',
        sub {
            my $d = $_[0];
            $s->showNotification( { message => 'Exploration completed.', type => 'success' } );
            return;
        }
    );
    $s->_listen(
        'EXPLORER_LEVEL_UP',
        sub {
            $s->showNotification( { message => 'Explorer level up!', type => 'success' } );
            return;
        }
    );
    $s->_listen( 'GAME_TICK', sub { $s->refreshTranscendButton; return; } );
    my $error = sub {
        my ($e) = @_;
        $Bufo::Browser::events->emit(
            'ERROR',
            {
                message => $e->{message},
                source  => $e->{filename},
                lineno  => $e->{lineno},
                colno   => $e->{colno},
                error   => $e->{error}
            }
        );
        $s->showNotification(
            {
                message  => $e->{message} || 'An unexpected error occurred.',
                type     => 'error',
                duration => 5000
            }
        );
        return;
    };
    Bufo::Browser::DOM::listen( Bufo::Browser::DOM::window(), 'error', $error );
    $s->{error_handler} = $error;
    return;
}

sub setupVisibilityTracking {
    Bufo::Browser::DOM::listen( Bufo::Browser::DOM::document(),
        'visibilitychange', \&Bufo::Browser::on_visibility );
    return;
}

sub setupResizeHandling {
    my ($s) = @_;
    my $cb = sub {
        my ($entries) = @_;
        my $r = $s->{root}->getBoundingClientRect;
        $s->handleResize( $r->{width}, $r->{height} );
        return;
    };
    $s->{resize_callback} = $cb;
    $s->{observer}        = WebPerl::js_new( 'ResizeObserver', $cb );
    $s->{observer}->observe( $s->{root} );
    my $r = $s->{root}->getBoundingClientRect;
    $s->handleResize( $r->{width}, $r->{height} );
    return;
}

sub handleResize {
    my ( $s, $width, $height ) = @_;
    $s->{root}->{classList}->toggle( 'mobile-layout',  $width < 1024 );
    $s->{root}->{classList}->toggle( 'desktop-layout', $width >= 1024 );
    return;
}
sub startUpdateLoop { my ($s) = @_; $s->{updating} = 1; return; }

sub updateTabNotification {
    my ( $s, $id, $has ) = @_;
    my $el = Bufo::Browser::DOM::document()->getElementById( $id . '-panel' );
    $el->{classList}->toggle( 'has-notification', $has ) if defined $el;
    return;
}

sub showModal {
    my ( $s, $o ) = @_;
    my $footer = join(
        '',
        map {
            my $b = $_;
            Bufo::Browser::Templates::button(
                $b->{text},
                undef,
                sub { $b->{callback}->() if $b->{callback}; Bufo::Browser::close_modal(); return; },
                $b->{className} || 'modal-button'
            )
        } @{ $o->{buttons} || [] }
    );
    return Bufo::Browser::show_modal( $o->{id}, $o->{title}, $o->{content}, $footer,
        $o->{closeOnBackdrop} );
}
sub closeModal { Bufo::Browser::close_modal(); return; }

sub closeNotification {
    my ( $s, $el ) = @_;
    return unless defined $el;
    return if $el->getAttribute('data-closing');
    $el->setAttribute( 'data-closing', 'true' );
    $el->{classList}->remove('visible');
    Bufo::Browser::DOM::later( 300, sub { $el->remove; return; } );
    return;
}

sub showNotification {
    my ( $s, $o ) = @_;
    my $el = Bufo::Browser::DOM::createElement( 'div',
        { classes => 'notification notification-' . ( $o->{type} || 'info' ) } );
    $el->{innerHTML} =
        '<div class="notification-content"><span class="notification-message">'
      . Bufo::Browser::escape_html( $o->{message} )
      . '</span><button class="notification-close" aria-label="Dismiss notification">×</button></div>';
    my $parent = Bufo::Browser::node('notification-container');
    $parent = Bufo::Browser::DOM::document()->{body} unless defined $parent;
    $parent->appendChild($el);
    my $button = Bufo::Browser::DOM::querySelector( '.notification-close', $el );
    my $cb     = sub { $s->closeNotification($el); return; };
    Bufo::Browser::DOM::listen( $button, 'click', $cb );
    Bufo::Browser::DOM::later( 10, sub { $el->{classList}->add('visible'); return; } );
    Bufo::Browser::DOM::later(
        defined( $o->{duration} ) ? $o->{duration} : 3000,
        sub {
            Bufo::Browser::DOM::unlisten( $button, 'click', $cb );
            $s->closeNotification($el);
            return;
        }
    );
    return $el;
}

sub createAchievementNotificationContainer {
    my ($s) = @_;
    $s->{achievement_container} = Bufo::Browser::DOM::createElement(
        'div',
        {
            classes => 'achievement-notification-container',
            parent  => Bufo::Browser::DOM::document()->{body}
        }
    );
    return;
}

sub renderAchievementItem {
    my ( $s, $a, $unlocked ) = @_;
    my %icons = ( generators => '🏭', production => '💰', clicks => '👆', special => '🎮' );
    return
        '<div class="achievement-item category-'
      . Bufo::Browser::escape_html( $a->{category} )
      . '" data-id="'
      . Bufo::Browser::escape_html( $a->{id} )
      . '" data-category="'
      . Bufo::Browser::escape_html( $a->{category} )
      . '"><div class="achievement-icon">'
      . (
        $a->{iconPath}
        ? Bufo::Browser::image_html( $a->{iconPath}, $a->{name}, 'achievement-icon-img' )
        : '<div class="achievement-icon-emoji">' . ( $icons{ $a->{category} } || '🏆' ) . '</div>'
      )
      . '</div><div class="achievement-info"><div class="achievement-name">'
      . Bufo::Browser::escape_html( $a->{name} )
      . '</div><div class="achievement-description">'
      . Bufo::Browser::escape_html( $a->{description} )
      . '</div>'
      . (
        $a->{reward}
        ? '<div class="achievement-reward">'
          . Bufo::Browser::escape_html( Bufo::Browser::reward_text( $a->{reward} ) )
          . '</div>'
        : ''
      ) . '</div></div>';
}

sub showAchievementNotification {
    my ( $s, $o ) = @_;
    return unless $o->{achievement};
    my $el = Bufo::Browser::DOM::createElement( 'div',
        { classes => 'achievement-notification', parent => Bufo::Browser::DOM::document()->{body} }
    );
    my $a     = $o->{achievement};
    my %icons = ( generators => '🏭', production => '💰', clicks => '👆', special => '🎮' );
    my $icon =
      $a->{iconPath}
      ? Bufo::Browser::image_html( $a->{iconPath}, $a->{name}, 'achievement-icon-img' )
      : '<div class="achievement-icon-emoji">' . ( $icons{ $a->{category} } || '🏆' ) . '</div>';
    $el->{innerHTML} =
        '<div class="achievement-notification-icon">'
      . $icon
      . '</div><div class="achievement-notification-content"><div class="achievement-notification-title">Achievement Unlocked!</div><div class="achievement-notification-name">'
      . Bufo::Browser::escape_html( $a->{name} )
      . '</div><div class="achievement-notification-description">'
      . Bufo::Browser::escape_html( $a->{description} )
      . '</div>'
      . (
        $a->{reward}
        ? '<div class="achievement-notification-reward">'
          . Bufo::Browser::escape_html( Bufo::Browser::reward_text( $a->{reward} ) )
          . '</div>'
        : ''
      ) . '</div>';
    Bufo::Browser::DOM::later( 10, sub { $el->{classList}->add('visible'); return; } );
    Bufo::Browser::DOM::later(
        $o->{duration} || 1000,
        sub {
            $el->{classList}->remove('visible');
            Bufo::Browser::DOM::later( 300, sub { $el->remove; return; } );
            return;
        }
    );
    return $el;
}

sub updateAutoSaveStatus {
    my ( $s, $enabled ) = @_;
    my $el = Bufo::Browser::node('auto-save-toggle');
    return unless defined $el;
    $el->{checked} = $enabled;
    $s->showNotification(
        {
            message => $enabled
            ? 'Auto-save enabled - game will be saved every 5 minutes'
            : 'Auto-save disabled - remember to save manually!',
            type     => $enabled ? 'info' : 'warning',
            duration => 3000
        }
    );
    return;
}

sub showSaveNotification {
    my ( $s, $message ) = @_;
    my $el = Bufo::Browser::DOM::querySelector('.save-notification');
    $el =
      Bufo::Browser::DOM::createElement( 'div',
        { classes => 'save-notification', parent => Bufo::Browser::DOM::document()->{body} } )
      unless defined $el;
    $el->{textContent} = $message;
    Bufo::Browser::DOM::later( 10, sub { $el->{classList}->add('visible'); return; } );
    Bufo::Browser::DOM::later(
        2010,
        sub {
            $el->{classList}->remove('visible');
            Bufo::Browser::DOM::later( 300, sub { $el->remove; return; } );
            return;
        }
    );
    return;
}
sub showStatsModal        { Bufo::Browser::show_stats();        return; }
sub showAchievementsModal { Bufo::Browser::show_achievements(); return; }

sub refreshAchievementsModal {
    my ($s) = @_;
    $s->showAchievementsModal if defined Bufo::Browser::DOM::querySelector('#achievements-modal');
    return;
}

sub filterAchievementsByCategory {
    my ( $s, $category ) = @_;
    for my $el ( @{ Bufo::Browser::DOM::querySelectorAll('.achievement-item') } ) {
        $el->{style}->{display} =
          (     !$category
              || $category eq 'all'
              || ( $el->getAttribute('data-category') || '' ) eq $category ) ? '' : 'none';
    }
    return;
}

sub renderProductionSources {
    my ( $self, $contributions ) = @_;
    return Bufo::Browser::contributions_html() unless defined $contributions;
    return '<div class="empty-contributions">No production sources yet.</div>'
      unless @$contributions;
    return join(
        '',
        map {
                '<div class="contribution-item"><div class="contribution-name">'
              . Bufo::Browser::escape_html( $_->{name} ) . ' (x'
              . $_->{count}
              . ')</div><div class="contribution-value">'
              . Bufo::Browser::number( $_->{production} )
              . '/sec <span class="contribution-percentage">('
              . sprintf( '%.1f', $_->{percentage} )
              . '%)</span></div></div>'
        } sort { $b->{production} <=> $a->{production} } @$contributions
    );
}
sub showPrestigeModal      { Bufo::Browser::show_prestige();     return; }
sub refreshTranscendButton { Bufo::Browser::render_menu_state(); return; }
sub handleTranscend        { return Bufo::Browser::transcend_game(); }
sub handleSave             { return Bufo::Browser::persist(1); }
sub handleReset            { Bufo::Browser::show_reset(); return; }

sub destroy {
    my ($s) = @_;
    $_->() for @{ $s->{unsubscribers} };
    $s->{unsubscribers} = [];
    if ( defined $s->{observer} ) {
        $s->{observer}->disconnect;
        WebPerl::unregister( $s->{resize_callback} );
    }
    if ( $s->{error_handler} ) {
        Bufo::Browser::DOM::unlisten( Bufo::Browser::DOM::window(), 'error', $s->{error_handler} );
    }
    $_->destroy for values %{ $s->{components} };
    $s->{components} = {};
    Bufo::Browser::DOM::removeElement( $s->{achievement_container} );
    $s->{updating} = 0;
    return;
}
1;
