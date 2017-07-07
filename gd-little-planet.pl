#!/usr/bin/env perl
# -------------------
# gd-little-planet.pl
# -------------------
# Changes:
#
# version 1.0 2017/07/07
#   Initial release
use utf8;
use strict;
use warnings;
use GD;
use Getopt::Long qw/:config posix_default no_ignore_case bundling auto_help/;
use Math::Round ();

use constant VERSION => "1.0";
use constant DEBUG => $ENV{DEBUG};
use constant PI => atan2(1, 1) * 4;

GetOptions(\my %opt, qw/
    size|s=s
    output|o=s
/);

my $file = shift;
$file && -f $file
    or usage();
my $img_org = GD::Image->new($file);

defined $opt{size} && $opt{size} !~ /[^0-9]/
    or $opt{size} = 600;

my $nw = my $nh = $opt{size};
my $hw = $nw / 2;
my $hh = $nh / 2;
my $r  = sqrt($hw * $hw + $hh * $hh);
my $lut = [];
my $pos = 0;
my $src = [];
my $dst = [];

my $img = GD::Image->new($nw, $nh, 1); # truecolor
$img->transparent($img->colorAllocate(255, 255, 255));
$img->interlaced('true');
$img->copyResized($img_org, 0, 0, 0, 0, $img->width, $img->height, $img_org->width, $img_org->height);
$img->rotate180();
undef $img_org;

for (my $y = 0; $y < $nh; $y++){
    for (my $x = 0; $x < $nw; $x++){
        my $sx = atan2($y - $hh, $x - $hw) * $hw / PI + $hw;
        my $sy = sqrt(($x - $hw) * ($x - $hw) + ($y - $hh) * ($y - $hh));
        $sy = ($r - $sy) / $r;
        $sy = $nh - $sy * $sy * $nh - 1;
        if ($sx < 0){ $sx = 0; }
        if ($nw - 1 < $sx){ $sx = $nw - 1; }
        if ($sy < 0){ $sy = 0; }
        if ($nh - 1 < $sy){ $sy = $nh - 1; }

        $sx = Math::Round::round($sx);
        $sy = Math::Round::round($sy);

        $lut->[$pos++] = ($sy * $nw + $sx);

        push @$src, $img->getPixel($x, $y);
    }
}
for (my $n = 0; $n < $nh * $nw; $n++){
    my $x = $n % $nw;
    my $y = int($n / $nw);
    if (DEBUG){
        warn "[DEBUG] n=$n x=$x, y=$y lut=$lut->[$n] color=[@{[join(',', @{$src->[$lut->[$n]]})]}]\n";
    }
    $img->setAntiAliased($img->colorAllocateAlpha($img->rgb($src->[$lut->[$n]]), $img->alpha($src->[$lut->[$n]])));
    $img->setPixel($x, $y, $img->colorAllocateAlpha($img->rgb($src->[$lut->[$n]]), $img->alpha($src->[$lut->[$n]])));
}

my $fh = (defined $opt{output} && $opt{output} ne '') ? IO::File->new($opt{output}, "w") : \*STDOUT;
print $fh $img->jpeg;
close $fh;
exit;

sub usage {
    warn "$_\n" for @_;
    require File::Basename;
    my $script_name = File::Basename::basename($0);
    die <<"USAGE";
$script_name version @{[VERSION]}

Usage:
    $script_name JPEG_FILE
        --size      [-s]    Size of output jpeg's one side of square. (default: 600)
        --output    [-o]    Specify output filename. (default: STDOUT)
USAGE
}
