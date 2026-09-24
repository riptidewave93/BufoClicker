package Bufo::Util::DataLoader;
use strict;
use warnings;
use JSON::PP ();
use Bufo::Util::Deferred;

sub new {
    my ( $class, %args ) = @_;
    die 'fetch adapter is required' unless ref( $args{fetch} ) eq 'CODE';
    bless \%args, $class;
}

sub _log {
    my ( $self, $level, @args ) = @_;
    $self->{logger}->$level(@args) if $self->{logger};
    return;
}

sub loadJsonData {
    my ( $self, $path, $on_success, $on_failure ) = @_;
    my $deferred = Bufo::Util::Deferred->new;
    $deferred->then( $on_success, $on_failure ) if $on_success || $on_failure;
    my $settled = 0;
    my $fail    = sub {
        return if $settled++;
        my $error = "Error loading $path: $_[0]";
        $self->_log( error => $error );
        $deferred->reject($error);
    };
    my $ok = sub {
        return if $settled;
        my $response = $_[0];
        my $value    = eval {
            die "HTTP " . ( $response->{status} // 0 )
              unless ref($response) eq 'HASH'
              && ( $response->{status} // 0 ) >= 200
              && $response->{status} < 300;
            JSON::PP->new->allow_nonref->decode( $response->{text} );
        };
        if ($@) { $fail->($@); return }
        $settled = 1;
        $deferred->resolve($value);
    };
    eval { $self->{fetch}->( $path, $ok, $fail, 10000 ); 1 } or $fail->($@);
    return $deferred;
}

sub loadMultipleJsonData {
    my ( $self, $files, $on_success ) = @_;
    my $done = Bufo::Util::Deferred->new;
    $done->then($on_success) if $on_success;
    my $remaining = scalar keys %$files;
    my ( %results, @errors );
    if ( !$remaining ) { $done->resolve( {} ); return $done }
    my $finish = sub {
        if ( --$remaining == 0 ) {
            $self->_log( warn => 'Some data files failed to load:', \@errors ) if @errors;
            $done->resolve( \%results );
        }
    };
    for my $key ( keys %$files ) {
        $self->loadJsonData(
            $files->{$key},
            sub { $results{$key} = $_[0]; $finish->() },
            sub { push @errors, $_[0]; $finish->() }
        );
    }
    return $done;
}

sub shouldLoadData {
    my ( $self, $key, $version ) = @_;
    my $cached = eval { $self->{storage}->get_raw( $key . '_version' ) };
    return $@ || !defined($cached) || !length($cached) || $cached ne $version ? 1 : 0;
}

sub updateDataCacheVersion {
    my ( $self, $key, $version ) = @_;
    eval { $self->{storage}->set_raw( $key . '_version', $version ); 1 }
      or $self->_log( warn => "Failed to update data cache version for $key:", $@ );
    return;
}
1;
