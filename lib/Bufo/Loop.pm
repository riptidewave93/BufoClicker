package Bufo::Loop;
use strict;
use warnings;

# Scheduling is injected so the same fixed-step loop runs in WASM and native tests.
sub new {
    my ( $class, %args ) = @_;
    die "Loop requires a clock and tick callback\n" unless $args{now} && $args{tick};
    return bless {
        %args,
        running     => 0,
        scale       => 1,
        fps         => 60,
        accumulated => 0,
        ui_elapsed  => 0,
        frame_id    => undef
    }, $class;
}

sub start {
    my $self = shift;
    return if $self->{running};
    $self->{running}     = 1;
    $self->{last}        = $self->{now}->();
    $self->{accumulated} = 0;
    $self->_schedule;
}

sub stop {
    my $self = shift;
    $self->{running} = 0;
    $self->{cancel}->( $self->{frame_id} ) if defined( $self->{frame_id} ) && $self->{cancel};
    $self->{frame_id} = undef;
}

sub _schedule {
    my $self = shift;
    $self->{frame_id} = $self->{schedule}->( sub { $self->frame( $_[0] ); } )
      if $self->{running} && $self->{schedule};
}

sub frame {
    my ( $self, $timestamp ) = @_;
    return 0 unless $self->{running};
    my $delta = $timestamp - $self->{last};
    $self->{last} = $timestamp;
    $delta = 0 if $delta < 0;
    $self->{accumulated} += $delta * $self->{scale};
    $self->{accumulated} = 1000 if $self->{accumulated} > 1000;
    my $step  = 1000 / $self->{fps};
    my $count = 0;

    while ( $self->{accumulated} >= $step ) {
        eval { $self->{tick}->( $step / 1000 ); 1 } or do {
            $self->{on_error}->($@) if $self->{on_error};
        };
        $self->{accumulated} -= $step;
        $count++;
    }
    $self->{ui_elapsed} += $delta;
    if ( $self->{ui_elapsed} >= 100 ) {
        $self->{emit}
          ->( 'GAME_TICK', { deltaTime => $self->{ui_elapsed}, timeScale => $self->{scale} } )
          if $self->{emit};
        $self->{ui_elapsed} = 0;
    }
    $self->_schedule;
    return $count;
}
sub setTimeScale { $_[0]{scale} = $_[1] < 0.1 ? 0.1 : $_[1] > 5 ? 5 : $_[1]; }
sub getTimeScale { $_[0]{scale} }
sub setTargetFPS { $_[0]{fps} = $_[1] < 10 ? 10 : $_[1] > 144 ? 144 : $_[1]; }
sub isRunning    { $_[0]{running} }
1;
