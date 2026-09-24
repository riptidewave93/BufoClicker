package Bufo::Browser::DOM;
use strict;
use warnings;
use Scalar::Util qw/refaddr/;
use WebPerl      qw/js/;
use Scalar::Util qw/blessed/;
sub document { return js('document'); }
sub window   { return js('window'); }

sub createElement {
    my ( $tag, $o ) = @_;
    $o ||= {};
    my $el = document()->createElement($tag);
    $el->{id} = $o->{id} if defined $o->{id};
    my $classes = $o->{classes};
    $classes = [ split /\s+/, $classes ] if defined($classes) && !ref($classes);
    $el->{classList}->add($_) for @{ $classes || [] };
    $el->setAttribute( $_, $o->{attributes}{$_} ) for keys %{ $o->{attributes} || {} };
    setContent( $el, $o->{content} )       if exists $o->{content};
    addEventListeners( $el, $o->{events} ) if $o->{events};
    $o->{parent}->appendChild($el)         if defined $o->{parent};
    return $el;
}

sub addClass {
    my ( $el, $c ) = @_;
    eval { $el->{classList}->add($c) } if defined($el) && defined($c) && length($c);
    return $el;
}

sub removeClass {
    my ( $el, $c ) = @_;
    eval { $el->{classList}->remove($c) } if defined($el) && defined($c) && length($c);
    return $el;
}

sub toggleClass {
    my ( $el, $c, $force ) = @_;
    if ( defined($el) && defined($c) && length($c) ) {
        eval {
            defined($force)
              ? $el->{classList}->toggle( $c, !!$force )
              : $el->{classList}->toggle($c);
        };
    }
    return $el;
}

sub setContent {
    my ( $el, $content ) = @_;
    return $el unless defined $el;
    $el->{innerHTML} = '';
    if    ( !ref $content ) { $el->{textContent} = defined($content) ? "$content" : ''; }
    elsif ( ref($content) eq 'ARRAY' ) {
        for (@$content) {
            $el->appendChild($_) if defined($_) && eval { $_->{nodeType} == 1 };
        }
    } else {
        $el->appendChild($content) if eval { $content->{nodeType} == 1 };
    }
    return $el;
}

# WebPerl creates a new bound JS function on each coderef conversion.
# Keep the converted function until the matching DOM listener is removed.
my @listeners;

sub listen {
    my ( $target, $event, $callback ) = @_;
    my $id = refaddr($callback);
    for my $entry (@listeners) {
        return
             if $entry->{id} == $id
          && $entry->{event} eq $event
          && js('Object')->is( $entry->{target}, $target );
    }
    my $function = js($callback);
    $target->addEventListener( $event, $function );
    push @listeners,
      {
        target   => $target,
        event    => $event,
        callback => $callback,
        id       => $id,
        function => $function
      };
    return;
}

sub unlisten {
    my ( $target, $event, $callback ) = @_;
    my $id = refaddr($callback);
    my @keep;
    for my $entry (@listeners) {
        if (   $entry->{id} == $id
            && $entry->{event} eq $event
            && js('Object')->is( $entry->{target}, $target ) )
        {
            $target->removeEventListener( $event, $entry->{function} );
        } else {
            push @keep, $entry;
        }
    }
    @listeners = @keep;
    if ( !grep { $_->{id} == $id } @listeners ) {
        WebPerl::unregister($callback) if exists $WebPerl::CodeTable{ sprintf( '%06x', $id ) };
    }
    return;
}

sub addEventListeners {
    my ( $el, $events ) = @_;
    return $el unless defined $el;
    for ( keys %{ $events || {} } ) {
        eval { Bufo::Browser::DOM::listen( $el, $_, $events->{$_} ) };
    }
    return $el;
}

sub querySelector {
    my ( $s, $p ) = @_;
    $p = document() unless defined $p;
    return eval { $p->querySelector($s) };
}

sub querySelectorAll {
    my ( $s, $p ) = @_;
    $p = document() unless defined $p;
    my $list = eval { $p->querySelectorAll($s) };
    return [] unless defined $list;
    return [ map { $list->item($_) } 0 .. $list->{length} - 1 ];
}

sub removeElement {
    my ($el) = @_;
    eval { $el->remove } if defined $el;
    return;
}

sub setVisible {
    my ( $el, $v ) = @_;
    $el->{style}->{display} = $v ? '' : 'none' if defined $el;
    return $el;
}

# Keep a single JS function identity until a timer has fired or is cancelled.
my %timers;

sub later {
    my ( $delay, $work ) = @_;
    my ( $id, $callback );
    $callback = sub {
        delete $timers{$id};
        my $ok    = eval { $work->(); 1 };
        my $error = $@;
        WebPerl::unregister($callback);
        $callback = undef;
        warn $error unless $ok;
        return;
    };
    $id = window()->setTimeout( $callback, $delay );
    $timers{$id} = \$callback;
    return $id;
}

sub cancel {
    my ($id) = @_;
    return unless defined $id;
    window()->clearTimeout($id);
    my $slot = delete $timers{$id};
    if ( $slot && $$slot ) {
        WebPerl::unregister($$slot);
        $$slot = undef;
    }
    return;
}

sub escape {
    my ($v) = @_;
    $v = '' unless defined $v;
    $v =~ s/&/&amp;/g;
    $v =~ s/</&lt;/g;
    $v =~ s/>/&gt;/g;
    $v =~ s/"/&quot;/g;
    $v =~ s/'/&#39;/g;
    return $v;
}
1;
