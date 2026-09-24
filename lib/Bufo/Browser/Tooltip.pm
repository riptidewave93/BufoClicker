package Bufo::Browser::Tooltip;
use strict;
use warnings;
use Bufo::Browser::DOM;
my ( $pending, $element, $x, $y, $listener ) = ( undef, undef, 0, 0, undef );
sub cancelTooltip { Bufo::Browser::DOM::cancel($pending); $pending = undef; return; }

sub hideTooltip {
    cancelTooltip();
    if ( defined $listener ) {
        Bufo::Browser::DOM::unlisten( Bufo::Browser::DOM::document(), 'mousemove', $listener );

        $listener = undef;
    }
    if ( defined $element ) {
        my $old = $element;
        $element = undef;
        $old->{classList}->remove('visible');
        Bufo::Browser::DOM::later( 300, sub { $old->remove; return; } );
    }
    return;
}

sub updateTooltipPosition {
    my ($event) = @_;
    $x = $event->{clientX};
    $y = $event->{clientY};
    return;
}

sub showTooltip {
    my ( $content, $event ) = @_;
    updateTooltipPosition($event);
    cancelTooltip();
    $pending = Bufo::Browser::DOM::later(
        300,
        sub {
            hideTooltip();
            my $doc = Bufo::Browser::DOM::document();
            my $win = Bufo::Browser::DOM::window();
            $element              = $doc->createElement('div');
            $element->{id}        = 'game-tooltip';
            $element->{className} = 'game-tooltip';
            $element->{innerHTML} = $content;
            $doc->{body}->appendChild($element);
            my $rect = $element->getBoundingClientRect;
            my $left = $x + 15;
            my $top  = $y + 15;
            $left = $x - $rect->{width} - 15  if $left + $rect->{width} > $win->{innerWidth};
            $top  = $y - $rect->{height} - 15 if $top + $rect->{height} > $win->{innerHeight};
            $left = 6                         if $left < 6;
            $top  = 6                         if $top < 6;
            $element->{style}->{left} = $left . 'px';
            $element->{style}->{top}  = $top . 'px';
            my $shown = $element;
            Bufo::Browser::DOM::later( 10, sub { $shown->{classList}->add('visible'); return; } );
            $listener = sub {
                my ($e) = @_;
                hideTooltip() if abs( $e->{clientX} - $x ) > 5 || abs( $e->{clientY} - $y ) > 5;
                return;
            };
            Bufo::Browser::DOM::listen( $doc, 'mousemove', $listener );
            return;
        }
    );
    return;
}
1;
