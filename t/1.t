use strict;
use Test::XML::XPath;
use XML::XPath;
use Test::More tests => 18;
BEGIN { use_ok('SVG::Plot') };

my $points = [ [0, 1, "http://example.com/?x=0;y=1"],
               [1, 2, "http://example.com/?x=1;y=2"]  ];

my $plot = SVG::Plot->new( points => $points );
isa_ok( $plot, "SVG::Plot" );

eval {
    local $SIG{__WARN__} = sub { die $_[0]; };
    $plot->plot;
};
is( $@, "", "->plot doesn't warn if debug option isn't set" );

my $noisyplot = SVG::Plot->new( points => $points, debug => 1 );
eval {
    local $SIG{__WARN__} = sub { die $_[0]; };
    $noisyplot->plot;
};
ok( $@, "...but does if it is" );

# scale defaults to 10, as does margin.  Our points are a unit square so
# we expect the image to end up sized 20 by 20.
my $output = $plot->plot;
like_xpath( $output, '/svg[@width="20"][@height="20"]',
      "image dimensions as expected with default scale and margin" );
like_xpath( $output, '//circle[@cx="5"][@cy="15"]',
      "...and first point where we expect it" );

$plot->scale(100);
$output = $plot->plot;
like_xpath( $output, '/svg[@width="110"][@height="110"]',
      "...and dimensions OK with default margin but scale set to 100" );
like_xpath( $output, '//circle[@cx="5"][@cy="105"]',
      "...first point too" );

$plot->scale(10);
$plot->margin(50);
$output = $plot->plot;
like_xpath( $output, '/svg[@width="60"][@height="60"]',
      "...and dimensions OK with default scale but margin set to 50" );
like_xpath( $output, '//circle[@cx="25"][@cy="35"]',
      "...first point too" );

# Now try constraining the image size.  (Data taken from grubstreet model
# of Hammersmith.)
my $hammersmith_points = [ ];
while ( <DATA> ) {
    chomp;
    my ($x, $y) = split / /;
    push @$hammersmith_points, [$x, $y, "http://example.com/?x=$x;y=$y"];
}

## Width tests first.
$plot = SVG::Plot->new( points    => $hammersmith_points,
                        max_width => 800 );
$output = $plot->plot;

my $xp = XML::XPath->new(xml => $output);
my $nodeset = $xp->find('//svg');
my $node = $nodeset->get_node(1);
my $width = $node->getAttribute("width");
my $height = $node->getAttribute("height");
ok( $width <= 800, "max_width parameter respected" );

# Make sure that scale isn't stretched if max_width is bigger than width
# would be anyway.
$plot = SVG::Plot->new( points    => $points, # original unit square points
                        max_width => 10000000 );
$output = $plot->plot;
like_xpath( $output, '/svg[@width="20"][@height="20"]',
      "max_width can't make scale bigger" );

# Test croaking if max_width is smaller than margin.
$plot = SVG::Plot->new( points => $points, margin => 100, max_width => 10 );
eval { $plot->plot; };
ok( $@, "->plot croaks if max_width is smaller than margin" );

## Now height tests.
$plot = SVG::Plot->new( points    => $hammersmith_points,
                        max_height => 400 );
$output = $plot->plot;

$xp = XML::XPath->new(xml => $output);
$nodeset = $xp->find('//svg');
$node = $nodeset->get_node(1);
$width = $node->getAttribute("width");
$height = $node->getAttribute("height");
ok( $height <= 400, "max_height parameter respected" );

# Make sure that scale isn't stretched if max_height is bigger than height
# would be anyway.
$plot = SVG::Plot->new( points    => $points, # original unit square points
                        max_height => 10000000 );
$output = $plot->plot;
like_xpath( $output, '/svg[@width="20"][@height="20"]',
      "max_height can't make scale bigger" );

# Test croaking if max_height is smaller than margin.
$plot = SVG::Plot->new( points => $points, margin => 100, max_height => 10 );
eval { $plot->plot; };
ok( $@, "->plot croaks if max_height is smaller than margin" );

## Test both width and height together.
$plot = SVG::Plot->new( points    => $hammersmith_points,
                        max_height => 400,
                        max_width  => 800 );
$output = $plot->plot;

$xp = XML::XPath->new(xml => $output);
$nodeset = $xp->find('//svg');
$node = $nodeset->get_node(1);
$width = $node->getAttribute("width");
$height = $node->getAttribute("height");
ok( $height <= 400,
    "max_height parameter respected when max height/width specified" );
ok( $width <= 800, "...max_width too" );

__DATA__
519478 179613
521930 182978
522575 178602
524099 178350
523385 178489
521970 178786
522770 179023
523479 178088
523416 178325
523474 178483
523302 178304
522122 178659
522959 178749
522909 178232
522780 178578
523158 178661
522570 178728
523368 178583
523393 178517
