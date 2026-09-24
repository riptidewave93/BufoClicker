#!/usr/bin/env perl
use strict;
use warnings;
use FindBin;
use File::Path qw(make_path remove_tree);
use File::Copy qw(copy);
use File::Find qw(find);
use File::Temp qw(tempdir);
use Digest::SHA;

chdir "$FindBin::Bin/.." or die "Cannot enter project: $!";
my $development = @ARGV == 1 && $ARGV[0] eq '--development' ? 1 : 0;
die "Usage: perl scripts/build.pl [--development]\n" if @ARGV && !$development;
my $release = 'v0.09-beta';
my $sha     = '5f441249217e90ab378c666f473d4206ab4f44907f6bb0aa8d70834bc38c40dc';
my $archive = ".cache/webperl-$release.zip";
make_path('.cache');
unless ( -f $archive ) {
    my $url =
      "https://github.com/haukex/webperl/releases/download/$release/webperl_prebuilt_$release.zip";
    system( 'curl', '--fail', '--location', '--retry', '3', '--output', "$archive.part", $url ) == 0
      or die "WebPerl download failed\n";
    rename "$archive.part", $archive or die "Cannot cache runtime: $!";
}
open my $zip, '<:raw', $archive or die "Cannot read runtime: $!";
my $digest = Digest::SHA->new(256)->addfile($zip)->hexdigest;
close $zip;
die "Runtime checksum mismatch; remove $archive and rebuild\n" unless $digest eq $sha;
my $stage = tempdir( '.build-XXXXXX', DIR => '.', CLEANUP => 1 );
make_path("$stage/runtime");
for my $file (qw(webperl.js emperl.js emperl.wasm emperl.data LICENSE_artistic.txt LICENSE_gpl.txt))
{
    open my $input, '-|', 'unzip', '-p', $archive, "webperl_prebuilt_$release/$file"
      or die "Cannot extract $file: $!";
    open my $output, '>:raw', "$stage/runtime/$file" or die "Cannot write $file: $!";
    my $buffer;
    while ( read( $input, $buffer, 65536 ) ) { print {$output} $buffer or die "Write failed: $!"; }
    close $input  or die "Runtime archive is missing $file\n";
    close $output or die "Cannot finish $file: $!";
}

# This older Perl build probes integer conversions before falling back to doubles.
system(
    'wasm-opt',          "$stage/runtime/emperl.wasm",
    '--trap-mode-clamp', '-o',
    "$stage/runtime/emperl-compatible.wasm"
  ) == 0
  or die "WebPerl numeric compatibility pass failed\n";
rename "$stage/runtime/emperl-compatible.wasm", "$stage/runtime/emperl.wasm"
  or die "Cannot install compatible runtime: $!";

# Keep Perl alive until pagehide and visibilitychange finish saving progress.
my $bridge_path = "$stage/runtime/webperl.js";
open my $bridge_in, '<:raw', $bridge_path or die "Cannot read browser bridge: $!";
my $bridge = do { local $/; <$bridge_in> };
close $bridge_in;
my $removed = $bridge =~
  s{\t\t\twindow\.addEventListener\("beforeunload", function \(\) \{\n\t\t\t\t// not really needed because we're unloading anyway, but for good measure, end Perl\.\.\.\n\t\t\t\tconsole\.debug\("Perl: beforeunload, ending\.\.\."\);\n\t\t\t\tPerl\.end\(\);\n\t\t\t\}\);\n}{};
die "Pinned WebPerl shutdown hook changed\n" unless $removed == 1;
open my $bridge_out, '>:raw', $bridge_path or die "Cannot write browser bridge: $!";
print {$bridge_out} $bridge;
close $bridge_out;

for my $tree (qw(assets styles)) {
    find(
        {
            no_chdir => 1,
            wanted   => sub {
                return if /\.ts\z/;
                my $destination = "$stage/$File::Find::name";
                if    ( -d $_ ) { make_path($destination); }
                elsif ( -f $_ ) { copy( $_, $destination ) or die "Cannot copy $_: $!"; }
            }
        },
        $tree
    );
}
copy( 'web/index.html',         "$stage/index.html" )  or die "Cannot copy entry: $!";
copy( 'assets/images/bufo.ico', "$stage/favicon.ico" ) or die "Cannot copy favicon: $!";
open my $bundle, '>:raw', "$stage/app.pl" or die "Cannot create Perl bundle: $!";
print {$bundle} "package Bufo::Build; our \$DEVELOPMENT = $development;\n";
my @modules = qw(
  Catalog Number ExplorerModel Enemies Combat Explorer
  Util/Validation Util/Deferred Util/General Util/Number Util/Math Util/Time Util/Storage
  Util/SaveManager Util/DataLoader Util/State Util/Index Core/Logger Core/Events Core/EventBus Core/StateManager
  Model/Generators Model/Upgrades Model/Achievements Model/Prestige Model/Boss Model/State
  Managers/Generators Managers/Upgrades Managers/Achievements Managers/Prestige Managers/Boss Managers/Golden
  Game Save API Loop Loader Managers
  Browser/DOM Browser/Component Browser/Container Browser/Animation Browser/Tooltip
  Browser/Styles Browser/Constants Browser/Templates Browser/Components Browser/Lists
  Browser/Special Browser/UIManager Browser/UI Browser/Debug Browser/StyleLoader Browser/Initialization
);

for my $module (@modules) {
    die "Missing application module $module\n" unless -f "lib/Bufo/$module.pm";
    print {$bundle} "BEGIN { \$INC{'Bufo/$module.pm'} = __FILE__ }\n";
}
append_file( $bundle, "lib/Bufo/$_.pm" ) for @modules;
append_file( $bundle, 'web/app.pl' );
close $bundle or die "Cannot finish Perl bundle: $!";

# Preserve the directory inode mounted by the development nginx container.
make_path('dist');
opendir my $old, 'dist' or die "Cannot inspect output: $!";
for my $name ( grep { $_ ne '.' && $_ ne '..' } readdir $old ) {
    my $path = "dist/$name";
    if   ( -d $path && !-l $path ) { remove_tree($path); }
    else                           { unlink $path or die "Cannot replace $path: $!"; }
}
closedir $old;
opendir my $built, $stage or die "Cannot inspect build: $!";
for my $name ( grep { $_ ne '.' && $_ ne '..' } readdir $built ) {
    rename "$stage/$name", "dist/$name" or die "Cannot install $name: $!";
}
closedir $built;
print "Built dist/ with WebPerl $release ($sha)\n";

sub append_file {
    my ( $output, $path ) = @_;
    open my $input, '<:raw', $path or die "Cannot read $path: $!";
    local $/;
    print {$output} "\n# Source: $path\n", <$input>, "\n";
    close $input;
}
