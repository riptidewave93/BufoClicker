package Bufo::Model::Achievements;
use strict;
use warnings;
use utf8;
sub initializeAchievements { my ( $class, $catalog ) = @_; return [ @{ $catalog->achievements } ]; }

sub checkAchievementRequirement {
    my ( $class, $a, $s ) = @_;
    my $r = $a->{requirement};
    my $t = $r->{type};
    return $r->{target} && ( $s->{generatorCounts}{ $r->{target} } // 0 ) >= $r->{value} ? 1 : 0
      if $t eq 'generatorType';
    return $s->{consoleOpened}                                ? 1 : 0 if $t eq 'consoleOpened';
    return $r->{target} && $s->{customEvents}{ $r->{target} } ? 1 : 0 if $t eq 'customEvent';
    my %field =
      ( upgradeCount => 'upgradesPurchased', explorationCount => 'explorationsCompleted' );
    my %direct = map { $_ => 1 }
      qw(totalBufos bufosPerSecond totalGenerators clickCount bossesDefeated transcendences prestigePoints);
    return 0 unless $direct{$t} || $field{$t};
    return ( $s->{ $field{$t} // $t } // 0 ) >= $r->{value} ? 1 : 0;
}

sub getCategoryIcon {
    my %icons = ( generators => '🏭', production => '💰', clicks => '👆', special => '🎮' );
    return $icons{ $_[1] } // '🏆';
}
sub getAchievementIcon { $_[1]{iconPath} || $_[0]->getCategoryIcon( $_[1]{category} ) }

sub AchievementCategory {
    return {
        Generators => 'generators',
        Production => 'production',
        Clicks     => 'clicks',
        Special    => 'special'
    };
}

sub RequirementType {
    return {
        TotalBufos       => 'totalBufos',
        BufosPerSecond   => 'bufosPerSecond',
        TotalGenerators  => 'totalGenerators',
        GeneratorType    => 'generatorType',
        ClickCount       => 'clickCount',
        ConsoleOpened    => 'consoleOpened',
        UpgradeCount     => 'upgradeCount',
        ExplorationCount => 'explorationCount',
        BossesDefeated   => 'bossesDefeated',
        Transcendences   => 'transcendences',
        PrestigePoints   => 'prestigePoints',
        CustomEvent      => 'customEvent'
    };
}

sub RewardType {
    return {
        ProductionBoost => 'productionBoost',
        ClickBoost      => 'clickBoost',
        GeneratorBoost  => 'generatorBoost',
        UnlockGenerator => 'unlockGenerator',
        UnlockUpgrade   => 'unlockUpgrade',
        UnlockFeature   => 'unlockFeature',
        BufoBonus       => 'bufoBonus'
    };
}
1;
