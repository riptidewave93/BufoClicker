package Bufo::Browser::Animation;
use strict;
use warnings;
use WebPerl qw/js js_new/;
use Bufo::Browser::DOM;
our %Easing = (
    linear    => sub { return $_[0] },
    easeIn    => sub { return $_[0]**2 },
    easeOut   => sub { my $t = $_[0]; return $t * ( 2 - $t ) },
    easeInOut => sub { my $t = $_[0]; return $t < .5 ? 2 * $t * $t : -1 + ( 4 - 2 * $t ) * $t },
    elastic   => sub {
        my $t = $_[0];
        return 2**( -10 * $t ) * sin( ( $t - .3 / 4 ) * ( 2 * 3.141592653589793 ) / .3 ) + 1;
    },
    bounce => sub {
        my $t = $_[0];
        return 7.5625 * $t * $t if $t < 1 / 2.75;
        return 7.5625 * ( $t - 1.5 / 2.75 )**2 + .75    if $t < 2 / 2.75;
        return 7.5625 * ( $t - 2.25 / 2.75 )**2 + .9375 if $t < 2.5 / 2.75;
        return 7.5625 * ( $t - 2.625 / 2.75 )**2 + .984375;
    }
);

sub animate {
    my ( $duration, $progress, $o ) = @_;
    $o ||= {};
    my $start    = js('performance')->now;
    my $ease     = $o->{easing} || $Easing{linear};
    my $executor = sub {
        my ( $resolve, $reject ) = @_;
        my $frame;
        $frame = sub {
            my ($timestamp) = @_;
            my $p = $duration > 0 ? ( $timestamp - $start ) / $duration : 1;
            $p = 1 if $p > 1;
            $p = 0 if $p < 0;
            my $ok = eval {
                my $v = $ease->($p);
                $progress->($v);
                $o->{onUpdate}->($v) if $o->{onUpdate};
                1;
            };
            if ( !$ok )   { $reject->($@); WebPerl::unregister($frame); $frame = undef; return; }
            if ( $p < 1 ) { Bufo::Browser::DOM::window()->requestAnimationFrame($frame); }
            else {
                $o->{onComplete}->() if $o->{onComplete};
                $resolve->();
                WebPerl::unregister($frame);
                $frame = undef;
            }
            return;
        };
        if ( $o->{delay} ) {
            Bufo::Browser::DOM::later( $o->{delay},
                sub { Bufo::Browser::DOM::window()->requestAnimationFrame($frame); return; } );
        } else {
            Bufo::Browser::DOM::window()->requestAnimationFrame($frame);
        }
        return;
    };
    my $p = js_new( 'Promise', $executor );
    WebPerl::unregister($executor);
    return $p;
}
sub rejected { return js('Promise')->reject('Element is required'); }

sub animateElement {
    my ( $el, $o ) = @_;
    return rejected() unless defined $el;
    $o ||= {};
    my ( %from, %to, %unit );
    my $computed = Bufo::Browser::DOM::window()->getComputedStyle($el);
    for my $key ( keys %{ $o->{properties} || {} } ) {
        my $value = $computed->{$key};
        my ( $n, $u ) = defined($value) ? $value =~ /^\s*([-+\d.eE]+)(.*)$/ : ();
        $from{$key} = defined($n) ? 0 + $n : 0;
        $unit{$key} = $u || '';
        my ($target) = $o->{properties}{$key} =~ /([-+\d.eE]+)/;
        $to{$key} = defined($target) ? 0 + $target : 0;
    }
    my %options = %$o;
    $options{easing} ||= $Easing{easeInOut};
    return animate(
        defined( $o->{duration} ) ? $o->{duration} : 300,
        sub {
            my $p = $_[0];
            for ( keys %from ) {
                $el->{style}->{$_} = ( $from{$_} + ( $to{$_} - $from{$_} ) * $p ) . $unit{$_};
            }
            return;
        },
        \%options
    );
}

sub fadeIn {
    my ( $el, $duration ) = @_;
    return rejected() unless defined $el;
    $el->{style}->{opacity} = 0;
    $el->{style}->{display} = '';
    return animateElement( $el,
        { properties => { opacity => 1 }, duration => defined($duration) ? $duration : 300 } );
}

sub fadeOut {
    my ( $el, $duration, $remove ) = @_;
    return rejected() unless defined $el;
    $remove = 1       unless defined $remove;
    return animateElement(
        $el,
        {
            properties => { opacity => 0 },
            duration   => defined($duration) ? $duration : 300,
            onComplete => sub { $el->{style}->{display} = 'none' if $remove; return; }
        }
    );
}

sub pulse {
    my ( $el, $scale, $duration ) = @_;
    return rejected() unless defined $el;
    $scale    = 1.05 unless defined $scale;
    $duration = 600  unless defined $duration;
    return js('Promise')->resolve if ( $el->{dataset}->{animating} || '' ) eq 'true';
    $el->{dataset}->{animating} = 'true';
    $el->{style}->{transform}   = '';
    my $clear =
      sub { $el->{style}->{transform} = ''; $el->{dataset}->{animating} = 'false'; return; };
    my $timer = Bufo::Browser::DOM::later( $duration + 300, $clear );
    return animate(
        $duration / 2,
        sub { $el->{style}->{transform} = 'scale(' . ( 1 + ( $scale - 1 ) * $_[0] ) . ')'; return; }
        ,
        {
            easing     => $Easing{easeOut},
            onComplete => sub {
                animate(
                    $duration / 2,
                    sub {
                        $el->{style}->{transform} =
                          'scale(' . ( $scale - ( $scale - 1 ) * $_[0] ) . ')';
                        return;
                    },
                    {
                        easing     => $Easing{easeIn},
                        onComplete =>
                          sub { Bufo::Browser::DOM::cancel($timer); $clear->(); return; }
                    }
                );
                return;
            }
        }
    );
}

sub shake {
    my ( $el, $intensity, $duration ) = @_;
    return rejected() unless defined $el;
    $intensity = 5   unless defined $intensity;
    $duration  = 500 unless defined $duration;
    my $original = $el->{style}->{transform} || '';
    my $executor = sub {
        my ($resolve) = @_;
        my $i = 0;
        my $step;
        $step = sub {
            if ( $i >= 6 ) {
                $el->{style}->{transform} = $original;
                $resolve->();
                $step = undef;
                return;
            }
            $el->{style}->{transform} =
                $original
              . ' translateX('
              . ( ( $i % 2 ? -1 : 1 ) * $intensity * ( 1 - $i / 6 ) ) . 'px)';
            ++$i;
            Bufo::Browser::DOM::later( $duration / 6, $step );
            return;
        };
        $step->();
        return;
    };
    my $p = js_new( 'Promise', $executor );
    WebPerl::unregister($executor);
    return $p;
}
1;
