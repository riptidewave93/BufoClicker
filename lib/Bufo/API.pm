package Bufo::API;
use strict;
use warnings;
use JSON::PP ();

sub new {
    my ( $class, %args ) = @_;
    die "API requires a Game provider and clock\n" unless $args{game} && $args{clock};
    bless { %args, hooks => $args{hooks} // {} }, $class;
}
sub _game  { $_[0]{game}->() }
sub _clone { JSON::PP::decode_json( JSON::PP::encode_json( $_[0] ) ) }

sub _hook {
    my ( $self, $name, @args ) = @_;
    die "Browser hook $name is not configured\n" unless $self->{hooks}{$name};
    $self->{hooks}{$name}->(@args);
}

sub init {
    my $s = shift;
    return $s->_hook('init') if $s->{hooks}{init};
    $s->checkUnlocks;
    $s->start;
}

sub start {
    my $s = shift;
    return $s->_hook('start') if $s->{hooks}{start};
    $s->_game->resume( $s->{clock}->() );
    $s->_game->getGoldenBufoManager->start;
    $s->_game->emit( 'GAME_STARTED', undef );
}

sub stop {
    my $s = shift;
    return $s->_hook('stop') if $s->{hooks}{stop};
    $s->_game->getGoldenBufoManager->stop;
    $s->_game->pause( $s->{clock}->() );
    $s->_game->emit( 'GAME_PAUSED', undef );
}
sub reset      { $_[0]->_hook('reset') }
sub resetState { $_[0]->_hook('resetState') }
sub save       { $_[0]->_hook('save') }
sub load       { $_[0]->_hook('load') }
sub exportSave { $_[0]->_hook('exportSave') }
sub importSave { $_[0]->_hook( 'importSave', $_[1] ) }

sub toggleAutoSave {
    my ( $s, $enabled ) = @_;
    $s->_game->set_auto_save($enabled);
    $s->{hooks}{toggleAutoSave}->($enabled) if $s->{hooks}{toggleAutoSave};
}
sub isAutoSaveEnabled { $_[0]->_game->state->{gameSettings}{autoSave} ? 1 : 0 }

sub click {
    my $s = shift;
    my $r = $s->_game->click( $s->{clock}->() );
    return { bufosGained => 0, isCombo => 0, comboMultiplier => 1 } unless $r->{ok};
    return { map { $_ => $r->{$_} } qw(bufosGained isCombo comboMultiplier) };
}
sub registerClick    { my $s = shift; $s->_game->_count_click; $s->_game->_check_achievements; }
sub getState         { _clone( $_[0]->_game->state ) }
sub getGenerators    { $_[0]->getGeneratorManager->getAllGenerators }
sub buyGenerator     { my ( $s, $id, $q ) = @_; $s->_game->buy_generator( $id, $q )->{ok} ? 1 : 0 }
sub getMaxAffordable { $_[0]->_game->max_affordable( $_[1] ) }

sub getAvailableUpgrades {
    my $s      = shift;
    my $state  = $s->_game->state;
    my %counts = map { $_ => $state->{generators}{$_}{count} } keys %{ $state->{generators} };
    return $s->getUpgradeManager->checkAvailableUpgrades( $state, \%counts );
}
sub buyUpgrade           { $_[0]->_game->buy_upgrade( $_[1] )->{ok} ? 1 : 0 }
sub getPurchasedUpgrades { $_[0]->getUpgradeManager->getPurchasedUpgrades }
sub getExplorer          { $_[0]->getExplorerManager->getExplorer }

sub startExploration {
    my ( $s, $area ) = @_;
    $s->_game->{now} = $s->{clock}->();
    $s->getExplorerManager->startExploration($area);
}
sub getAvailableAreas { $_[0]->getExplorerManager->getAvailableAreas }

sub upgradeExplorerStat {
    my ( $s, $stat ) = @_;
    my $g = $s->_game;
    my $result =
      $s->getExplorerManager->upgradeExplorerStat( $stat, $g->state->{resources}{bufos} );
    $g->state->{resources}{bufos} -= $result->{cost} if $result->{success};
    return $result;
}
sub getExplorerStats        { $_[0]->getExplorerManager->getExplorerStats }
sub on                      { $_[0]->getEventBus->on( $_[1], $_[2] ) }
sub off                     { $_[0]->getEventBus->off( $_[1], $_[2] ) }
sub getProductionStatistics { $_[0]->getGeneratorManager->getProductionStats }
sub getGameCore             { $_[0] }
sub getGameLoop             { $_[0]->_hook('getGameLoop') }
sub getUIManager            { $_[0]->_hook('getUIManager') }
sub getEventBus             { $_[0]{events}        // $_[0]->_hook('getEventBus') }
sub getStateManager         { $_[0]{state_manager} // $_[0]->_hook('getStateManager') }
sub getGeneratorManager     { $_[0]->_game->getGeneratorManager }
sub getUpgradeManager       { $_[0]->_game->getUpgradeManager }
sub getAchievementManager   { $_[0]->_game->getAchievementManager }
sub getExplorerManager      { $_[0]->_game->getExplorerManager }
sub getPrestigeManager      { $_[0]->_game->getPrestigeManager }
sub getGoldenBufoManager    { $_[0]->_game->getGoldenBufoManager }
sub getBossManager          { $_[0]->_game->getBossManager }

sub checkUnlocks {
    my $s = shift;
    $s->getGeneratorManager->checkUnlocks( $s->_game->state->{resources}{totalBufos} );
    $s->getAvailableUpgrades;
}

sub processTick {
    my ( $s, $delta ) = @_;
    my $g = $s->_game;
    $g->tick( $delta, $s->{clock}->() );
    $g->getGoldenBufoManager->update;
}
sub destroy { $_[0]->stop; $_[0]{hooks}{destroy}->() if $_[0]{hooks}{destroy}; }
1;
