package Bufo::Core::Logger;
use strict;
use warnings;
sub NONE ()  { 0 }
sub ERROR () { 1 }
sub WARN ()  { 2 }
sub INFO ()  { 3 }
sub DEBUG () { 4 }
sub TRACE () { 5 }

sub new {
    my ( $class, %args ) = @_;
    bless {
        level      => 3,
        timestamps => 1,
        colors     => 1,
        grouping   => 1,
        context    => 'App',
        depth      => 0,
        now        => $args{now}  // sub { time() * 1000 },
        sink       => $args{sink} // sub {
            my ( $method, @args ) = @_;
            print STDERR join( ' ', map { defined($_) && !ref($_) ? $_ : '[data]' } @args ) . "\n";
        }
    }, $class;
}
sub setLogLevel         { $_[0]{level} = $_[1]; return }
sub getLogLevel         { $_[0]{level} }
sub enableTimestamps    { $_[0]{timestamps} = $_[1] ? 1 : 0; return }
sub enableConsoleColors { $_[0]{colors}     = $_[1] ? 1 : 0; return }
sub enableGrouping      { $_[0]{grouping}   = $_[1] ? 1 : 0; return }
sub setContext          { $_[0]{context}    = $_[1]; return }

sub _message {
    my ( $self, $text ) = @_;
    my $prefix = '';
    if ( $self->{timestamps} ) {
        my $ms   = $self->{now}->();
        my @time = gmtime( $ms / 1000 );
        $prefix = sprintf( '[%02d:%02d:%02d.%03d] ', $time[2], $time[1], $time[0], $ms % 1000 );
    }
    return $prefix . '[' . $self->{context} . '] ' . $text;
}

sub _write {
    my ( $self, $minimum, $method, $color, $text, @args ) = @_;
    return if $self->{level} < $minimum;
    my $formatted = $self->_message($text);
    $self->{colors}
      ? $self->{sink}->( $method, '%c' . $formatted, $color, @args )
      : $self->{sink}->( $method, $formatted, @args );
    return;
}
sub error { my $self = shift; $self->_write( 1, 'error', 'color: #FF5252;', @_ ) }
sub warn  { my $self = shift; $self->_write( 2, 'warn',  'color: #FFC107;', @_ ) }
sub log   { my $self = shift; $self->_write( 3, 'log',   'color: #4CAF50;', @_ ) }
sub info  { my $self = shift; $self->log(@_) }
sub debug { my $self = shift; $self->_write( 4, 'debug', 'color: #2196F3;', @_ ) }
sub trace { my $self = shift; $self->_write( 5, 'debug', 'color: #9E9E9E;', @_ ) }

sub group {
    my ( $self, $title ) = @_;
    return unless $self->{level} >= 4 && $self->{grouping};
    $self->_write( 4, 'group', 'color: #673AB7; font-weight: bold;', $title );
    $self->{depth}++;
    return;
}

sub groupCollapsed {
    my ( $self, $title ) = @_;
    return unless $self->{level} >= 4 && $self->{grouping};
    $self->_write( 4, 'groupCollapsed', 'color: #673AB7; font-weight: bold;', $title );
    $self->{depth}++;
    return;
}

sub groupEnd {
    my ($self) = @_;
    return unless $self->{level} >= 4 && $self->{grouping} && $self->{depth} > 0;
    $self->{sink}->('groupEnd');
    $self->{depth}--;
    return;
}

sub table {
    my ( $self, $data ) = @_;
    $self->{sink}->( 'table', $data ) if $self->{level} >= 4;
    return;
}
sub styled { my ( $self, $text, $css, @args ) = @_; $self->_write( 3, 'log', $css, $text, @args ) }

sub time {
    my ( $self, $label, $fn ) = @_;
    return $fn->() unless $self->{level} >= 4;
    $self->{sink}->( 'time', $label );
    my $value = eval { $fn->() };
    my $error = $@;
    $self->{sink}->( 'timeEnd', $label );
    die $error if length $error;
    return $value;
}

sub createLogger {
    my ( $self, $context ) = @_;
    return bless { parent => $self, context => $context }, 'Bufo::Core::Logger::Context';
}

package Bufo::Core::Logger::Context;
use strict;
use warnings;
our $AUTOLOAD;

sub AUTOLOAD {
    my ( $self, @args ) = @_;
    my ($method) = $AUTOLOAD =~ /::([^:]+)$/;
    die "Unknown contextual logger method $method"
      unless $method =~
      /\A(?:error|warn|log|info|debug|trace|group|groupCollapsed|groupEnd|table|time)\z/;
    my $parent = $self->{parent};
    return $parent->$method(@args) if $method =~ /\A(?:groupEnd|table|time)\z/;
    my $old = $parent->{context};
    $parent->{context} = $self->{context};
    my $result = $parent->$method(@args);
    $parent->{context} = $old;
    return $result;
}
sub DESTROY { }
1;
