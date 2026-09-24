package Bufo::Number;
use strict;
use warnings;
use Scalar::Util ();

sub _finite {
    return defined($_[0]) && !ref($_[0])
        && Scalar::Util::looks_like_number($_[0]) && "$_[0]" !~ /nan|inf/i;
}

# Match Math.round without converting large floating-point values to Perl integers.
sub _round {
    my ($value, $digits) = @_;
    my $scale = 10 ** $digits;
    my $shifted = $value * $scale + 0.5;
    my $rounded = 0 + sprintf('%.0f', $shifted);
    $rounded -= 1 if $rounded > $shifted;
    return $rounded / $scale;
}

sub _group {
    my ($text) = @_;
    my ($whole, $fraction) = split /\./, $text, 2;
    $whole =~ s/(\d)(?=(\d{3})+$)/$1,/g;
    return $whole . (defined($fraction) ? '.' . $fraction : '');
}

sub format {
    my ($number, $precision) = @_;
    return '0' unless _finite($number) && $number != 0;
    $precision = 1 unless _finite($precision);
    $precision = 0 if $precision < 0;
    $precision = 6 if $precision > 6;
    $precision = int($precision);

    my $absolute = abs($number);
    if ($absolute < 1_000_000) {
        my $digits = $absolute < 1000 ? $precision : 0;
        my $rounded = _round($number, $digits);
        my $text = sprintf('%.*f', $digits, $rounded);
        $text =~ s/\.?0+$// if $text =~ /\./;
        return _group($text);
    }

    my @suffix = ('', 'K', 'M', 'B', 'T', 'Qa', 'Qi', 'Sx', 'Sp', 'Oc', 'No', 'Dc');
    my $tier = 0;
    while ($absolute >= 1000 && $tier < $#suffix) {
        $absolute /= 1000;
        $tier++;
    }
    my $capped = $absolute > 999_999;
    $absolute = 999_999 if $capped;
    my $text = sprintf('%.*f', $precision, $absolute);
    my $sign = $number < 0 ? '-' : '';
    return $sign . _group($text) . $suffix[$tier] . ($capped ? '+' : '');
}
1;
