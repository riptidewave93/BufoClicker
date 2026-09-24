package Bufo::Core::Events;
use strict;
use warnings;
sub RESOURCE_ADDED ()               { 'RESOURCE_ADDED' }
sub RESOURCE_SPENT ()               { 'RESOURCE_SPENT' }
sub GENERATOR_PURCHASED ()          { 'GENERATOR_PURCHASED' }
sub GENERATOR_UNLOCKED ()           { 'GENERATOR_UNLOCKED' }
sub GENERATOR_PRODUCTION_UPDATED () { 'GENERATOR_PRODUCTION_UPDATED' }
sub EXPLORATION_STARTED ()          { 'EXPLORATION_STARTED' }
sub EXPLORATION_COMPLETED ()        { 'EXPLORATION_COMPLETED' }
sub EXPLORER_LEVEL_UP ()            { 'EXPLORER_LEVEL_UP' }
sub EXPLORER_STAT_UPGRADED ()       { 'EXPLORER_STAT_UPGRADED' }
sub EXPLORER_STATE_CHANGED ()       { 'EXPLORER_STATE_CHANGED' }
sub UPGRADE_PURCHASED ()            { 'UPGRADE_PURCHASED' }
sub UPGRADES_AVAILABLE ()           { 'UPGRADES_AVAILABLE' }
sub PRESTIGE_TRANSCENDED ()         { 'PRESTIGE_TRANSCENDED' }
sub GOLDEN_BUFO_SPAWNED ()          { 'GOLDEN_BUFO_SPAWNED' }
sub GOLDEN_BUFO_EXPIRED ()          { 'GOLDEN_BUFO_EXPIRED' }
sub GOLDEN_BUFO_COLLECTED ()        { 'GOLDEN_BUFO_COLLECTED' }
sub BOSS_AVAILABLE ()               { 'BOSS_AVAILABLE' }
sub BOSS_FIGHT_STARTED ()           { 'BOSS_FIGHT_STARTED' }
sub BOSS_DAMAGED ()                 { 'BOSS_DAMAGED' }
sub BOSS_TICK ()                    { 'BOSS_TICK' }
sub BOSS_DEFEATED ()                { 'BOSS_DEFEATED' }
sub BOSS_FIGHT_LOST ()              { 'BOSS_FIGHT_LOST' }
sub BOSS_FIGHT_RETREATED ()         { 'BOSS_FIGHT_RETREATED' }
sub ACHIEVEMENT_UNLOCKED ()         { 'ACHIEVEMENT_UNLOCKED' }
sub ACHIEVEMENTS_UPDATED ()         { 'ACHIEVEMENTS_UPDATED' }
sub GAME_TICK ()                    { 'GAME_TICK' }
sub GAME_SAVED ()                   { 'GAME_SAVED' }
sub GAME_LOADED ()                  { 'GAME_LOADED' }
sub GAME_RESET ()                   { 'GAME_RESET' }
sub GAME_STARTED ()                 { 'GAME_STARTED' }
sub GAME_PAUSED ()                  { 'GAME_PAUSED' }
sub UI_TAB_CHANGED ()               { 'UI_TAB_CHANGED' }
sub UI_SETTINGS_TOGGLED ()          { 'UI_SETTINGS_TOGGLED' }
sub UI_MODAL_OPENED ()              { 'UI_MODAL_OPENED' }
sub UI_MODAL_CLOSED ()              { 'UI_MODAL_CLOSED' }

sub names {
    [
        'RESOURCE_ADDED',               'RESOURCE_SPENT',
        'GENERATOR_PURCHASED',          'GENERATOR_UNLOCKED',
        'GENERATOR_PRODUCTION_UPDATED', 'EXPLORATION_STARTED',
        'EXPLORATION_COMPLETED',        'EXPLORER_LEVEL_UP',
        'EXPLORER_STAT_UPGRADED',       'EXPLORER_STATE_CHANGED',
        'UPGRADE_PURCHASED',            'UPGRADES_AVAILABLE',
        'PRESTIGE_TRANSCENDED',         'GOLDEN_BUFO_SPAWNED',
        'GOLDEN_BUFO_EXPIRED',          'GOLDEN_BUFO_COLLECTED',
        'BOSS_AVAILABLE',               'BOSS_FIGHT_STARTED',
        'BOSS_DAMAGED',                 'BOSS_TICK',
        'BOSS_DEFEATED',                'BOSS_FIGHT_LOST',
        'BOSS_FIGHT_RETREATED',         'ACHIEVEMENT_UNLOCKED',
        'ACHIEVEMENTS_UPDATED',         'GAME_TICK',
        'GAME_SAVED',                   'GAME_LOADED',
        'GAME_RESET',                   'GAME_STARTED',
        'GAME_PAUSED',                  'UI_TAB_CHANGED',
        'UI_SETTINGS_TOGGLED',          'UI_MODAL_OPENED',
        'UI_MODAL_CLOSED'
    ]
}
1;
