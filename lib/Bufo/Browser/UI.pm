package Bufo::Browser::UI;
use strict;
use warnings;
use Bufo::Browser::UIManager;
use Bufo::Browser::Styles;
use Bufo::Browser::Constants;

sub initUI {
    my ($id) = @_;
    my $ui = Bufo::Browser::UIManager->getInstance;
    $ui->init( $id || 'game-container' );
    return $ui;
}
sub updateUI              { Bufo::Browser::UIManager->getInstance; return; }
sub createResourceDisplay { return Bufo::Browser::ResourceDisplay->new( $_[0] ); }
sub createClickArea       { return Bufo::Browser::ClickArea->new( $_[0] ); }

sub createGeneratorList {
    return Bufo::Browser::GeneratorList->new( defined( $_[0] ) ? { id => $_[0] } : {} );
}
sub createShop { return Bufo::Browser::Shop->new( defined( $_[0] ) ? { id => $_[0] } : {} ); }

sub createUpgradeList {
    return Bufo::Browser::UpgradeList->new( defined( $_[0] ) ? { id => $_[0] } : {} );
}

sub createProductionStats {
    return Bufo::Browser::ProductionStats->new( defined( $_[0] ) ? { id => $_[0] } : {} );
}

sub initializeUI {
    my $c = {
        resourceDisplay => createResourceDisplay(),
        clickArea       => createClickArea(),
        generatorList   => createGeneratorList(),
        shop            => createShop(),
        upgradeList     => createUpgradeList(),
        productionStats => createProductionStats()
    };
    $_->init for values %$c;
    return $c;
}
1;
