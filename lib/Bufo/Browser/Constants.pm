package Bufo::Browser::Constants;
use strict;
use warnings;
use utf8;
our $VALUES = {
    TABS => [
        { id => 'main',     label => 'Main',     icon => '🐸' },
        { id => 'shop',     label => 'Shop',     icon => '🛒' },
        { id => 'upgrades', label => 'Upgrades', icon => '⬆️' },
        { id => 'stats',    label => 'Stats',    icon => '📊' }
    ],
    DEFAULT_TAB => 'main',
    Z_INDEX     => { base   => 1,   content => 10,  notification => 100, modal => 1000 },
    ANIMATION   => { short  => 150, medium  => 300, long         => 500 },
    BREAKPOINTS => { mobile => 480, tablet  => 768, desktop      => 1024 },
    DEFAULT_NOTIFICATION_DURATION => 3000,
    DEFAULT_THEME                 => 'dark',
    THEMES                        => [ 'light', 'dark', 'forest' ],
    TOOLTIP_DELAY                 => 300
};
sub get { return $VALUES->{ $_[0] }; }
1;
