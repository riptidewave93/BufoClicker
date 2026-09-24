use strict;
use warnings;
use Test::More;
use lib 'lib';
require Bufo::ExplorerModel;
require Bufo::Explorer;
my $state    = Bufo::ExplorerModel->default_data( now => 1000 );
my $now      = 1000;
my $explorer = Bufo::Explorer->new( state => $state, now => sub { $now }, random => sub { 0.999 } );
ok( $explorer->startExploration('Pond'), 'public manager starts exploration' );
for ( 1 .. 10 ) { $now += 5000; $explorer->update(5) }
is( $state->{explorationsCompleted},      1,  'normal game updates complete exploration' );
is( $state->{lifetimeBufosFromExploring}, 43, 'original manager reward preserved' );
is( $state->{health},                     95, 'original manager fatigue preserved' );
done_testing;
