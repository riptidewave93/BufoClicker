package Bufo::Util::Index;
use strict;
use warnings;
use Bufo::Util::Number     ();
use Bufo::Util::Validation ();
use Bufo::Util::General    ();
use Bufo::Util::Time       ();
use Bufo::Util::Math       ();
use Bufo::Core::Logger     ();
my %operations = (
    'roundTo'                   => [ 'Bufo::Util::Number',       0 ],
    'clamp'                     => [ 'Bufo::Util::Number',       0 ],
    'calculateExponentialCost'  => [ 'Bufo::Util::Number',       0 ],
    'formatNumber'              => [ 'Bufo::Util::Number',       0 ],
    'formatNumberWithPrecision' => [ 'Bufo::Util::Number',       0 ],
    'getNumberFullName'         => [ 'Bufo::Util::Number',       0 ],
    'formatDuration'            => [ 'Bufo::Util::Number',       0 ],
    'calculatePercentage'       => [ 'Bufo::Util::Number',       0 ],
    'formatPercentage'          => [ 'Bufo::Util::Number',       0 ],
    'sum'                       => [ 'Bufo::Util::Number',       0 ],
    'average'                   => [ 'Bufo::Util::Number',       0 ],
    'getCurrentTime'            => [ 'time',                     1 ],
    'calculateElapsedTime'      => [ 'time',                     1 ],
    'formatTimeAgo'             => [ 'time',                     1 ],
    'throttle'                  => [ 'time',                     1 ],
    'debounce'                  => [ 'time',                     1 ],
    'calculateFPS'              => [ 'time',                     1 ],
    'formatTimestamp'           => [ 'time',                     1 ],
    'createElement'             => [ 'Bufo::Browser::DOM',       0 ],
    'addClass'                  => [ 'Bufo::Browser::DOM',       0 ],
    'removeClass'               => [ 'Bufo::Browser::DOM',       0 ],
    'toggleClass'               => [ 'Bufo::Browser::DOM',       0 ],
    'setContent'                => [ 'Bufo::Browser::DOM',       0 ],
    'addEventListeners'         => [ 'Bufo::Browser::DOM',       0 ],
    'querySelector'             => [ 'Bufo::Browser::DOM',       0 ],
    'querySelectorAll'          => [ 'Bufo::Browser::DOM',       0 ],
    'removeElement'             => [ 'Bufo::Browser::DOM',       0 ],
    'setVisible'                => [ 'Bufo::Browser::DOM',       0 ],
    'isStorageAvailable'        => [ 'storage',                  1 ],
    'saveToStorage'             => [ 'storage',                  1 ],
    'loadFromStorage'           => [ 'storage',                  1 ],
    'clearStorage'              => [ 'storage',                  1 ],
    'clearAllStorage'           => [ 'storage',                  1 ],
    'exportToString'            => [ 'storage',                  1 ],
    'importFromString'          => [ 'storage',                  1 ],
    'getStorageSize'            => [ 'storage',                  1 ],
    'hasStorageKey'             => [ 'storage',                  1 ],
    'animate'                   => [ 'Bufo::Browser::Animation', 0 ],
    'animateElement'            => [ 'Bufo::Browser::Animation', 0 ],
    'fadeIn'                    => [ 'Bufo::Browser::Animation', 0 ],
    'fadeOut'                   => [ 'Bufo::Browser::Animation', 0 ],
    'pulse'                     => [ 'Bufo::Browser::Animation', 0 ],
    'shake'                     => [ 'Bufo::Browser::Animation', 0 ],
    'randomInt'                 => [ 'math',                     1 ],
    'randomFloat'               => [ 'math',                     1 ],
    'mapRange'                  => [ 'math',                     1 ],
    'inRange'                   => [ 'math',                     1 ],
    'lerp'                      => [ 'math',                     1 ],
    'inverseLerp'               => [ 'math',                     1 ],
    'distance'                  => [ 'math',                     1 ],
    'angle'                     => [ 'math',                     1 ],
    'toDegrees'                 => [ 'math',                     1 ],
    'toRadians'                 => [ 'math',                     1 ],
    'pointFromAngle'            => [ 'math',                     1 ],
    'smoothLerp'                => [ 'math',                     1 ],
    'weightedRandom'            => [ 'math',                     1 ],
    'factorial'                 => [ 'math',                     1 ],
    'chance'                    => [ 'math',                     1 ],
    'randomNormal'              => [ 'math',                     1 ],
    'isValidNumber'             => [ 'Bufo::Util::Validation',   0 ],
    'isValidInteger'            => [ 'Bufo::Util::Validation',   0 ],
    'isPositiveNumber'          => [ 'Bufo::Util::Validation',   0 ],
    'isNonNegativeNumber'       => [ 'Bufo::Util::Validation',   0 ],
    'isInRange'                 => [ 'Bufo::Util::Validation',   0 ],
    'isNonEmptyString'          => [ 'Bufo::Util::Validation',   0 ],
    'isValidArray'              => [ 'Bufo::Util::Validation',   0 ],
    'isNonEmptyArray'           => [ 'Bufo::Util::Validation',   0 ],
    'isValidDate'               => [ 'Bufo::Util::Validation',   0 ],
    'isValidObject'             => [ 'Bufo::Util::Validation',   0 ],
    'hasRequiredProperties'     => [ 'Bufo::Util::Validation',   0 ],
    'validateObject'            => [ 'Bufo::Util::Validation',   0 ],
    'isValidEmail'              => [ 'Bufo::Util::Validation',   0 ],
    'isValidUrl'                => [ 'Bufo::Util::Validation',   0 ],
    'createValidationResult'    => [ 'Bufo::Util::Validation',   0 ],
    'isOneOf'                   => [ 'Bufo::Util::Validation',   0 ],
    'validateSaveData'          => [ 'Bufo::Util::Validation',   0 ],
    'generateId'                => [ 'general',                  1 ],
    'isDefined'                 => [ 'Bufo::Util::General',      0 ],
    'isNullOrUndefined'         => [ 'Bufo::Util::General',      0 ],
    'defaultIfNullOrUndefined'  => [ 'Bufo::Util::General',      0 ],
    'deepClone'                 => [ 'Bufo::Util::General',      0 ],
    'isPlainObject'             => [ 'Bufo::Util::General',      0 ],
    'safeJsonParse'             => [ 'Bufo::Util::General',      0 ],
    'safeJsonStringify'         => [ 'Bufo::Util::General',      0 ],
    'delay'                     => [ 'general',                  1 ],
    'cancellableDelay'          => [ 'general',                  1 ],
    'attempt'                   => [ 'Bufo::Util::General',      0 ],
    'getRandomElement'          => [ 'general',                  1 ],
    'shuffleArray'              => [ 'general',                  1 ],
);

sub new {
    my ( $class, %args ) = @_;
    $args{time}    //= Bufo::Util::Time->new;
    $args{math}    //= Bufo::Util::Math->new;
    $args{general} //= Bufo::Util::General->new( time => $args{time} );
    $args{logger}  //= Bufo::Core::Logger->new;
    return bless \%args, $class;
}
sub Logger     { $_[0]{logger} }
sub Easing     { no strict 'refs'; return \%{'Bufo::Browser::Animation::Easing'} }
sub operations { return [ sort keys %operations ] }

sub call {
    my ( $self, $name, @args ) = @_;
    return $self->{is_valid_date}->(@args) if $name eq 'isValidDate' && $self->{is_valid_date};
    return $self->{is_valid_url}->(@args)  if $name eq 'isValidUrl'  && $self->{is_valid_url};
    my $operation = $operations{$name} or die "Unknown utility $name";
    my ( $target, $object ) = @$operation;
    if ($object) {
        my $instance = $self->{$target} or die "Utility $name requires the $target adapter";
        return $instance->$name(@args);
    }
    my $callback = $target->can($name) or die "Utility module $target is not loaded";
    return $callback->(@args);
}
our $AUTOLOAD;

sub AUTOLOAD {
    my ( $self, @args ) = @_;
    my ($name) = $AUTOLOAD =~ /::([^:]+)$/;
    return $self->call( $name, @args );
}
sub DESTROY { }
1;
