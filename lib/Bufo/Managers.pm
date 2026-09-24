package Bufo::Managers;
use strict;
use warnings;

sub new {
    my ( $class, %args ) = @_;
    die "Managers require a Game provider\n" unless $args{game};
    bless \%args, $class;
}

sub initializeManagers {
    my $self = shift;
    my $game = $self->{game}->();
    $game->getUpgradeManager->setUpgrades( $game->catalog->upgrades );
    $game->getGeneratorManager->recalculateAllGenerators;
    $game->getExplorerManager;
    $game->getAchievementManager;
    $game->getPrestigeManager;
    $game->getGoldenBufoManager;
    $game->getBossManager;
}

sub resetManagers {
    my $game = $_[0]{game}->();
    $game->getGeneratorManager->reset;
    $game->getExplorerManager->reset;
    $game->getUpgradeManager->reset;
    $game->getAchievementManager->reset;
    $game->getPrestigeManager->reset;
    $game->getGoldenBufoManager->reset;
    $game->getBossManager->reset;
}
1;
