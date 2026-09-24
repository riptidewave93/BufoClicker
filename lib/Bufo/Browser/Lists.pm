package Bufo::Browser::GeneratorList;
use strict;
use warnings;
use parent -norequire, 'Bufo::Browser::Container';
use Bufo::Browser::Components;

sub new {
    my ( $c, $o ) = @_;
    return $c->SUPER::new(
        {
            id        => 'owned-generators',
            className => 'owned-generators-container panel',
            %{ $o || {} }
        }
    );
}

sub setup {
    my ($s) = @_;
    $s->setContent(
        '<div class="panel-header"><h2>Your Frogs</h2></div><div class="generators-container"></div>'
    ) unless $s->{options}{adopt};
    $s->connectToState( sub { return $_[0]{generators} }, sub { $s->refreshGenerators; return; } );
    for (qw/GENERATOR_PURCHASED GAME_LOADED refreshUI/) {
        $s->subscribeToEvent( $_, sub { $s->refreshGenerators; return; } );
    }
    return;
}

sub addChild {
    my ( $s, $child, $data ) = @_;
    my $holder = Bufo::Browser::DOM::querySelector( '.generators-container', $s->{element} );
    $holder = $s->{element} unless defined $holder;
    push @{ $s->{children} }, { component => $child, data => $data };
    $holder->appendChild( $child->getElement );
    $child->init;
    return $child;
}

sub refreshGenerators {
    my ($s) = @_;
    my $all = $Bufo::Browser::game->state->{generators};
    my @ids = Bufo::Browser::ordered_generators();
    $s->updateGenerators( [ map { $all->{$_} } grep { $all->{$_}{count} > 0 } @ids ] );
    return;
}

sub updateGenerators {
    my ( $s, $generators ) = @_;
    my %wanted = map { $_->{id} => $_ } @$generators;
    for my $record ( @{ $s->getChildren } ) {
        my $c = $record->{component};
        $s->removeChild($c) unless $wanted{ $c->{generator}{id} };
    }
    my $empty = Bufo::Browser::DOM::querySelector( '.empty-generators', $s->{element} );
    $empty->remove if defined $empty;
    for my $g (@$generators) {
        my $id = 'generator-' . $g->{id};
        my $c  = $s->getChildById($id);
        unless ($c) {
            $c = Bufo::Browser::GeneratorItem->new(
                { id => $id, className => 'owned-generator', tagName => 'button' } );
            $s->addChild( $c, $g );
        }
        $c->update($g);
    }
    if ( !@$generators ) {
        my $holder = Bufo::Browser::DOM::querySelector( '.generators-container', $s->{element} );
        $holder = $s->{element} unless defined $holder;
        Bufo::Browser::DOM::createElement(
            'div',
            {
                classes => 'empty-generators',
                content => 'No frogs yet! Buy some from the shop.',
                parent  => $holder
            }
        );
    }
    $s->updateGeneratorCountIndicator( scalar @$generators );
    return;
}

sub updateGeneratorCountIndicator {
    my ( $s, $count ) = @_;
    my $h = Bufo::Browser::DOM::querySelector( 'h2', $s->{element} );
    $h->{textContent} = 'Your Frogs' . ( $count ? ' (' . $count . ')' : '' ) if defined $h;
    return;
}

package Bufo::Browser::Shop;
use parent -norequire, 'Bufo::Browser::Container';

sub new {
    my ( $c, $o ) = @_;
    my $s = $c->SUPER::new(
        { id => 'buildings-container', className => 'buildings-container', %{ $o || {} } } );
    $s->{purchaseAmount} = 1;
    return $s;
}

sub setup {
    my ($s) = @_;
    $s->createPurchaseControls unless $s->{options}{adopt};
    $s->connectToState( sub { return $_[0]{generators} }, sub { $s->refreshGenerators; return; } );
    for (qw/GENERATOR_UNLOCKED GENERATOR_PURCHASED GAME_LOADED refreshUI/) {
        $s->subscribeToEvent( $_, sub { $s->refreshGenerators; return; } );
    }
    $s->subscribeToEvent( 'GAME_TICK', sub { $s->updateAffordability; return; } );
    return;
}

sub createPurchaseControls {
    my ($s) = @_;
    my $controls = Bufo::Browser::DOM::createElement( 'div',
        { classes => 'purchase-controls', parent => $s->{element} } );
    for my $q ( 1, 10, 100, -1 ) {
        my $b = Bufo::Browser::DOM::createElement(
            'button',
            {
                classes    => 'purchase-amount-button' . ( $q == 1 ? ' active' : '' ),
                content    => $q == -1 ? 'Max' : $q,
                attributes => { 'data-amount' => $q },
                parent     => $controls
            }
        );
        my $cb = sub { $s->setPurchaseAmount($q); return; };
        Bufo::Browser::DOM::listen( $b, 'click', $cb );
        push @{ $s->{control_handlers} }, [ $b, $cb ];
    }
    return;
}

sub setPurchaseAmount {
    my ( $s, $q ) = @_;
    return unless grep { $_ == $q } ( 1, 10, 100, -1 );
    $s->{purchaseAmount} = $q;
    for my $b ( @{ Bufo::Browser::DOM::querySelectorAll('.purchase-amount-button') } ) {
        my $active = $b->getAttribute('data-amount') == $q;
        $b->{classList}->toggle( 'active', $active );
        $b->setAttribute( 'aria-pressed', $active ? 'true' : 'false' );
    }
    $s->updateCosts;
    return;
}

sub refreshGenerators {
    my ($s) = @_;
    my $all = $Bufo::Browser::game->state->{generators};
    $s->updateGenerators(
        [ map { $all->{$_} } grep { $all->{$_}{unlocked} } Bufo::Browser::ordered_generators() ] );
    return;
}

sub updateGenerators {
    my ( $s, $list ) = @_;
    my %wanted = map { $_->{id} => 1 } @$list;
    for my $r ( @{ $s->getChildren } ) {
        my $c = $r->{component};
        $s->removeChild($c) unless $wanted{ $c->{generator}{id} };
    }
    for my $g (@$list) {
        my $id = 'shop-item-' . $g->{id};
        my $c  = $s->getChildById($id);
        unless ($c) {
            $c = Bufo::Browser::ShopItem->new(
                { id => $id, className => 'building-item shop-item category-' . $g->{category} } );
            $s->addChild( $c, $g );
        }
        $c->update( { generator => $g, purchaseAmount => $s->{purchaseAmount} } );
        my $b = Bufo::Browser::DOM::querySelector( '.buy-button', $c->getElement );
        $b->{id} = 'buy-' . $g->{id};
        $b->setAttribute( 'aria-label', 'Buy ' . $g->{name} );
    }
    return;
}

sub updateCosts {
    my ($s) = @_;
    for my $r ( @{ $s->{children} } ) {
        $r->{component}{purchaseAmount} = $s->{purchaseAmount};
        $r->{component}->updateButtonCost;
    }
    return;
}
sub updateAffordability { $_[0]->updateCosts; return; }

sub destroy {
    my ($s) = @_;
    for ( @{ $s->{control_handlers} || [] } ) {
        Bufo::Browser::DOM::unlisten( $_->[0], 'click', $_->[1] );

    }
    $s->{control_handlers} = [];
    $s->SUPER::destroy;
    return;
}

package Bufo::Browser::UpgradeList;
use parent -norequire, 'Bufo::Browser::Container';

sub new {
    my ( $c, $o ) = @_;
    return $c->SUPER::new(
        { id => 'upgrades-container', className => 'upgrades-grid', %{ $o || {} } } );
}

sub setup {
    my ($s) = @_;
    $s->connectToState( sub { return $_[0]{upgrades} }, sub { $s->refreshUpgrades; return; } );
    for (qw/UPGRADE_PURCHASED UPGRADES_AVAILABLE GAME_LOADED/) {
        $s->subscribeToEvent( $_, sub { $s->refreshUpgrades; return; } );
    }
    return;
}

sub refreshUpgrades {
    my ($s) = @_;
    my %all = map { $_->{id} => $_ } @{ $Bufo::Browser::catalog->upgrades };
    $s->updateUpgrades(
        [ map { $all{$_} } @{ $Bufo::Browser::game->state->{upgrades}{available} } ] );
    return;
}

sub addUpgradeItem {
    my ( $s, $u ) = @_;
    my $c = Bufo::Browser::UpgradeItem->new(
        { id => 'upgrade-item-' . $u->{id}, className => 'upgrade-item upgrade-icon-container' } );
    $s->addChild( $c, $u );
    $c->update($u);
    return $c;
}
sub removeUpgradeItem { my ( $s, $id ) = @_;  return $s->removeChild( 'upgrade-item-' . $id ); }
sub clearUpgradeItems { $_[0]->clearChildren; return; }

sub updateUpgrades {
    my ( $s, $list ) = @_;
    my %wanted = map { $_->{id} => $_ } @$list;
    for my $r ( @{ $s->getChildren } ) {
        my $c = $r->{component};
        $s->removeChild($c) unless $wanted{ $c->{upgrade}{id} };
    }
    my $empty = Bufo::Browser::DOM::querySelector( '.empty-upgrades', $s->{element} );
    $empty->remove if defined $empty;
    for my $u (@$list) {
        my $c = $s->getChildById( 'upgrade-item-' . $u->{id} );
        $c ? $c->update($u) : $s->addUpgradeItem($u);
    }
    if ( !@$list ) {
        Bufo::Browser::DOM::createElement(
            'div',
            {
                classes => 'empty-upgrades',
                content => 'No upgrades available yet.',
                parent  => $s->{element}
            }
        );
    }
    $s->updateUpgradeCountIndicator( scalar @$list );
    return;
}

sub updateUpgradeCountIndicator {
    my ( $s, $count ) = @_;
    my $panel = $s->{element}->closest('.panel');
    return unless defined $panel;
    my $h = Bufo::Browser::DOM::querySelector( 'h2', $panel );
    if ( defined $h ) {
        $h->{textContent} = 'Upgrades' . ( $count ? ' (' . $count . ')' : '' );
        $h->{classList}->toggle( 'has-new-upgrades', $count > 0 );
    }
    return;
}
sub destroy { my ($s) = @_; $s->clearUpgradeItems; $s->SUPER::destroy; return; }

package Bufo::Browser::ProductionStats;
use parent -norequire, 'Bufo::Browser::View';

sub new {
    my ( $c, $o ) = @_;
    return $c->SUPER::new(
        { id => 'production-stats', className => 'production-stats panel', %{ $o || {} } } );
}

sub render {
    return
      '<div class="panel-content"><div class="stats-container"></div><div class="contributions"><h3>Production Sources</h3><div class="contributions-list"><div class="empty-contributions">No production sources yet.</div></div></div></div>';
}

sub setup {
    my ($s) = @_;
    $s->setContent( $s->render ) unless $s->{options}{adopt};
    $s->connectToState( sub { return $_[0]{generators} }, sub { $s->refreshStats; return; } );
    for (qw/GENERATOR_PRODUCTION_UPDATED GENERATOR_PURCHASED/) {
        $s->subscribeToEvent( $_, sub { $s->refreshStats; return; } );
    }
    return;
}

sub refreshStats {
    my ($s) = @_;
    $s->updateStats( $Bufo::Browser::api->getProductionStatistics );
    return;
}

sub updateStats {
    my ( $s, $stats ) = @_;
    my $list = Bufo::Browser::DOM::querySelector( '.contributions-list', $s->{element} );
    return unless defined $list;
    my @c =
      sort { $b->{production} <=> $a->{production} } @{ $stats->{generatorContributions} || [] };
    $list->{innerHTML} = @c
      ? join(
        '',
        map {
                '<div class="contribution-item"><span class="contribution-name">'
              . Bufo::Browser::View::esc( $_->{name} ) . ' (x'
              . $_->{count}
              . ')</span><span class="contribution-value">'
              . Bufo::Browser::View::num( $_->{production} )
              . '/sec ('
              . sprintf( '%.1f', $_->{percentage} )
              . '%)</span></div>'
        } @c
      )
      : '<div class="empty-contributions">No production sources yet.</div>';
    my $items = Bufo::Browser::DOM::querySelectorAll( '.stat-item .stat-value', $s->{element} );
    if ( @$items >= 3 ) {
        $items->[0]->{textContent} = Bufo::Browser::View::num( $stats->{currentRate} ) . '/sec';
        $items->[1]->{textContent} = Bufo::Browser::View::num( $stats->{perMinute} );
        $items->[2]->{textContent} = Bufo::Browser::View::num( $stats->{perHour} );
    }
    return;
}
1;
