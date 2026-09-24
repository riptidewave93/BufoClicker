package Bufo::Util::General;
use strict;
use warnings;
use JSON::PP     ();
use Scalar::Util qw(refaddr reftype blessed);

sub new {
    my ( $class, %args ) = @_;
    bless { random => $args{random} // sub { rand() }, %args }, $class;
}

sub generateId {
    my ( $self, $prefix ) = @_;
    my $now = $self->{time} ? $self->{time}->getCurrentTime : time() * 1000;
    return ( $prefix // '' ) . $now . '-' . int( $self->{random}->() * 10000 );
}

sub isDefined {
    defined( $_[0] ) && !( blessed( $_[0] ) && $_[0]->isa('Bufo::Util::Undefined') ) ? 1 : 0;
}
sub isNullOrUndefined        { !isDefined( $_[0] ) }
sub defaultIfNullOrUndefined { isDefined( $_[0] ) ? $_[0] : $_[1] }

sub _clone {
    my ( $v, $seen ) = @_;
    return $v unless ref($v);
    my $id = refaddr($v);
    return $seen->{$id} if exists $seen->{$id};
    my $type = reftype($v);
    my $copy;
    if ( $type eq 'ARRAY' ) {
        $copy = [];
        $seen->{$id} = $copy;
        push @$copy, map { _clone( $_, $seen ) } @$v;
    } elsif ( $type eq 'HASH' ) {
        $copy        = {};
        $seen->{$id} = $copy;
        $copy->{$_}  = _clone( $v->{$_}, $seen ) for keys %$v;
    } elsif ( $type eq 'SCALAR' || $type eq 'REF' ) {
        my $inner;
        $copy        = \$inner;
        $seen->{$id} = $copy;
        $inner       = _clone( $$v, $seen );
    } else {
        die "Value cannot be cloned\n";
    }
    bless $copy, blessed($v) if blessed($v);
    return $copy;
}

sub deepClone {
    my ($v) = @_;
    my $copy = eval { _clone( $v, {} ) };
    return $copy unless $@;
    return [@$v] if ref($v) eq 'ARRAY';
    return {%$v} if ref($v) eq 'HASH';
    return $v;
}
sub isPlainObject { ref( $_[0] ) eq 'HASH' ? 1 : 0 }

sub safeJsonParse {
    my ( $raw, $fallback ) = @_;
    my $v = eval { JSON::PP->new->allow_nonref->decode($raw) };
    return $@ ? $fallback : $v;
}

sub safeJsonStringify {
    my ( $v, $fallback ) = @_;
    $fallback = '{}' unless defined $fallback;
    my $s = eval { JSON::PP->new->allow_nonref->encode($v) };
    return $@ ? $fallback : $s;
}
sub delay            { my ( $self, $ms ) = @_; return $self->{time}->delay($ms) }
sub cancellableDelay { my ( $self, $ms ) = @_; return $self->{time}->cancellableDelay($ms) }

sub attempt {
    my ( $fn, $default ) = @_;
    my $value = eval { $fn->() };
    return $@ ? $default : $value;
}

sub getRandomElement {
    my ( $self, $values ) = @_;
    return undef unless ref($values) eq 'ARRAY' && @$values;
    return $values->[ int( $self->{random}->() * @$values ) ];
}

sub shuffleArray {
    my ( $self, $values ) = @_;
    return [] unless ref($values) eq 'ARRAY';
    my @copy = @$values;
    for ( my $i = $#copy ; $i > 0 ; $i-- ) {
        my $j = int( $self->{random}->() * ( $i + 1 ) );
        @copy[ $i, $j ] = @copy[ $j, $i ];
    }
    return \@copy;
}
1;
