package Bufo::Util::Storage;
use strict;
use warnings;
use JSON::PP ();

sub new {
    my ( $class, %args ) = @_;
    for (qw(get set remove clear keys)) {
        die "Storage $_ adapter is required\n" unless ref( $args{$_} ) eq 'CODE';
    }
    bless \%args, $class;
}

sub _log {
    my ( $self, $level, @args ) = @_;
    $self->{logger}->$level(@args) if $self->{logger};
    return;
}

sub isStorageAvailable {
    my ($self) = @_;
    return eval {
        $self->{set}->( '__storage_test__', '__storage_test__' );
        my $ok = $self->{get}->('__storage_test__') eq '__storage_test__';
        $self->{remove}->('__storage_test__');
        $ok;
    } ? 1 : 0;
}

sub saveToStorage {
    my ( $self, $key, $data ) = @_;
    if ( !defined($key) || !length($key) ) {
        $self->_log( error => 'Storage key is required' );
        return 0;
    }
    unless ( $self->isStorageAvailable ) {
        $self->_log( warn => 'localStorage is not available' );
        return 0;
    }
    my $ok = eval {
        $self->{set}->( $key, JSON::PP->new->allow_nonref->encode($data) );
        1;
    };
    if ( !$ok ) {
        my $error = $@;
        $self->_log( error => 'Failed to save data to localStorage:', $error );
        $self->_log( warn  => 'localStorage quota exceeded' )
          if "$error" =~ /(?:QuotaExceededError|NS_ERROR_DOM_QUOTA_REACHED)/;
    }
    return $ok ? 1 : 0;
}

sub loadFromStorage {
    my ( $self, $key, $default ) = @_;
    if ( !defined($key) || !length($key) ) {
        $self->_log( error => 'Storage key is required' );
        return $default;
    }
    unless ( $self->isStorageAvailable ) {
        $self->_log( warn => 'localStorage is not available' );
        return $default;
    }
    my $value = eval {
        my $raw = $self->{get}->($key);
        defined($raw) ? JSON::PP->new->allow_nonref->decode($raw) : $default;
    };
    if ($@) { $self->_log( error => "Failed to load localStorage key $key:", $@ ); return $default }
    return $value;
}

sub clearStorage {
    my ( $self, $key ) = @_;
    if ( !defined($key) || !length($key) ) {
        $self->_log( error => 'Storage key is required' );
        return 0;
    }
    unless ( $self->isStorageAvailable ) {
        $self->_log( warn => 'localStorage is not available' );
        return 0;
    }
    my $ok = eval {
        $self->{remove}->($key);
        1;
    };
    $self->_log( error => "Failed to clear localStorage key $key:", $@ ) unless $ok;
    return $ok ? 1 : 0;
}

sub clearAllStorage {
    my ($self) = @_;
    unless ( $self->isStorageAvailable ) {
        $self->_log( warn => 'localStorage is not available' );
        return 0;
    }
    my $ok = eval {
        $self->{clear}->();
        1;
    };
    $self->_log( error => 'Failed to clear localStorage:', $@ ) unless $ok;
    return $ok ? 1 : 0;
}

sub _encode_text {
    my ( $self, $text ) = @_;
    return $self->{encode}->($text) if $self->{encode};
    require MIME::Base64;
    require Encode;
    my $bytes = Encode::encode( 'UTF-8', $text );
    $bytes =~ s/([^A-Za-z0-9\-_.!~*'()])/sprintf('%%%02X',ord($1))/ge;
    return MIME::Base64::encode_base64( $bytes, '' );
}

sub _decode_text {
    my ( $self, $encoded ) = @_;
    return $self->{decode}->($encoded) if $self->{decode};
    require MIME::Base64;
    require Encode;
    $encoded =~ s/\s+//g;
    die 'Invalid Base64'
      unless $encoded =~ /\A[A-Za-z0-9+\/]*(?:={1,2})?\z/
      && length($encoded) % 4 != 1
      && ( $encoded !~ /=/ || length($encoded) % 4 == 0 );
    my $uri = MIME::Base64::decode_base64($encoded);
    die 'Invalid URI escape' if $uri =~ /%(?![0-9A-Fa-f]{2})/;
    $uri =~ s/%([0-9A-Fa-f]{2})/chr(hex($1))/ge;
    return Encode::decode( 'UTF-8', $uri, Encode::FB_CROAK() );
}

sub exportToString {
    my ( $self, $data ) = @_;
    my $out = eval { $self->_encode_text( JSON::PP->new->allow_nonref->encode($data) ) };
    $self->_log( error => 'Failed to export data:', $@ ) if $@;
    return $out;
}

sub importFromString {
    my ( $self, $text ) = @_;
    if ( !defined($text) || !length($text) ) {
        $self->_log( error => 'Import string is required' );
        return undef;
    }
    my $out = eval { JSON::PP->new->allow_nonref->decode( $self->_decode_text($text) ) };
    $self->_log( error => 'Failed to import data:', $@ ) if $@;
    return $out;
}

sub _utf16_size {
    my ($text) = @_;
    my $size = 0;
    $size += ord($_) > 65535 ? 4 : 2 for split //, $text;
    return $size;
}

sub getStorageSize {
    my ($self) = @_;
    $self->_log( warn => 'localStorage is not available' ), return 0
      unless $self->isStorageAvailable;
    my $size = 0;
    for my $key ( @{ $self->{keys}->() } ) {
        next unless length $key;
        my $value = $self->{get}->($key) // '';
        $size += _utf16_size($key) + _utf16_size($value);
    }
    return $size;
}

sub hasStorageKey {
    my ( $self, $key ) = @_;
    return 0 unless $key && $self->isStorageAvailable;
    return defined( $self->{get}->($key) ) ? 1 : 0;
}

# Raw access is used by the single authoritative game save codec.
sub get_raw    { $_[0]{get}->( $_[1] ) }
sub set_raw    { $_[0]{set}->( $_[1], $_[2] ); return 1 }
sub remove_raw { $_[0]{remove}->( $_[1] );     return 1 }
1;
