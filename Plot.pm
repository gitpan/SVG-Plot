=head1 NAME

   SVG::Plot - a simple module to take a set of x,y points and plot them on a plane

=head1 SYNOPSIS

   use SVG::Plot;
   my $points = [[0,1,'http://uri/'],[2,3,'/uri/foo.png]];
   my $plot = SVG::Plot->new(
                              points => \@points,
                              debug => 0,
			      scale => 0.025,
                              max_width => 800,
                              max_height => 400,
			      point_size => 3,
			      point_style => {
			      fill => 'blue',
			      stroke => 'yellow'},
      			      line => 'follow',
                              margin => 6,
                            ); 
   # -- or --
   $plot->points($points);
   $plot->scale(4);

   print $plot->plot;

If C<debug> is set to true then debugging information is emitted as
warnings.  Note that the actual margin will be half of the value set
in C<margin>, since half of it goes to each side.  If C<max_width>
and/or C<max_height> is set then C<scale> will be reduced if necessary
in order to keep the width down.

C<plot> will croak if C<max_width> or C<max_height> is smaller than
C<margin>, since this is impossible.

=cut

package SVG::Plot;

our $VERSION = '0.03';
use strict;
use SVG;
use Carp qw( croak );

use Class::MethodMaker new_hash_init => 'new', get_set => [ qw( debug grid scale points image point_style point_size margin line line_style max_width max_height ) ];

sub plot {
    my $self = shift;
    my $points = $self->points;
    croak "no points to plot!" if not $points;
    my $grid = $self->grid;

    if (not $grid) {
	$grid = $self->work_out_grid($points);
    }

    my $scale = $self->scale || 10;
    my $m = $self->margin || 10;
    
    # Reduce scale if necessary to fit to width constraint.
    if ( $self->max_width ) {
        my $max_plot_width = $self->max_width - $m; # Account for margin
        croak "max_width must be larger than margin"
	    if $max_plot_width <= 0;
        my $x_extent = $grid->{max_x} - $grid->{min_x};
        my $max_width_scale = $max_plot_width / $x_extent;
        $scale = $max_width_scale if $scale > $max_width_scale;
    }

    # Reduce scale further if necessary to fit to height constraint.
    if ( $self->max_height ) {
        my $max_plot_height = $self->max_height - $m; # Account for margin
        croak "max_height must be larger than margin"
	    if $max_plot_height <= 0;
        my $y_extent = $grid->{max_y} - $grid->{min_y};
        my $max_height_scale = $max_plot_height / $y_extent;
        $scale = $max_height_scale if $scale > $max_height_scale;
    }

    my $h = int(($grid->{max_y} - $grid->{min_y})*$scale);
    my $w = int(($grid->{max_x} - $grid->{min_x})*$scale);
 
    my $svg = SVG->new( width => $w+$m, height => $h+$m ); # make a little margin +10

    if (my $map = $self->image) {
	my $img = $svg->image(
			      x=>0, y=>0,
			      '-href'=>$map, #may also embed SVG, e.g. "image.svg"
			      id=>'image_1'
			      );
    }

    my $point_style = $self->point_style;
    $point_style ||= {
	stroke => 'red',
	fill => 'white',
    };

    my $z=$svg->tag('g',
		    id    => 'group_z',
		    style => $point_style
		    );

    my $point_size = $self->point_size || 3;
    my $plotted;

    foreach (@$points) {

	# adding a margin ... 
	my $halfm = $m / 2;

	my ($x,$y) = ($_->[0],$_->[1]);
	my $href = $_->[2] || $self->random_id;
	
	# svg is upside-down
	$x = int(($x - $grid->{min_x})*$scale) + $halfm;
	$y = int(($grid->{max_y} - $y)*$scale) + $halfm;

	push @$plotted, [$x,$y,$href];
	my $id = $self->random_id;
	warn("anchor_$id") if $self->debug;;

	$z->anchor(id => "anchor_".$id,
		   -href => $href,
		   -target => 'new_window_0')->circle(
						      cx => $x, cy => $y,
						      r => $point_size,
						      id    => 'dot_'.$id,
						  );
    }

    if (my $line = $self->line) {
	my $style = $self->line_style;
	$style ||= {  'stroke-width' => 2, stroke => 'blue'  };

	if ($line eq 'follow') {
	    for my $n (0..($#{$plotted}-1)) {
		my $p1 = $plotted->[$n];
		my $p2 = $plotted->[$n+1];
		my $tag = $svg->line(
				     id => $self->random_id,
				     x1 => $p1->[0], y1 => $p1->[1],
				     x2 => $p2->[0], y2 => $p2->[1],
				     style => $style
				     );
	    }
	}
    }
    return $svg->xmlify;
}

sub work_out_grid {
    my ($self,$points) = @_;

    my $start = $points->[0];
    my ($lx,$ly,$hx,$hy);
    $lx = $start->[0];
    $hx = $lx;
    $ly = $start->[1];
    $hy = $ly;

    foreach (@$points) {

	$lx = $_->[0] if ($_->[0] <= $lx); 
	$ly = $_->[1] if ($_->[1] <= $ly);
	$hx = $_->[0] if ($_->[0] >= $hx);
	$hy = $_->[1] if ($_->[1] >= $hy);
    }
    return {
	min_x => $lx,
	max_x => $hx,
	min_y => $ly,
	max_y => $hy
	};
}

sub random_id {
    my @t = (0..9);
    return '_:id'.join '', (map { @t[rand @t] } 0..6);
}
    
1;

=head1 DESCRIPTION

a very simple module which allows you to give a set of points [x co-ord, y co-ord and optional http uri]) and plot them in SVG. 

$plot->points($points) where $points is a reference to an array of array references. 

see the SYNOPSIS for a list of parameters you can give to the plot. (overriding the styles on the ponts; sizing a margin; setting a scale; optionally drawing a line ( line => 'follow' ) between the points in the order they are specified.

you can supply a grid in the format 
SVG::Plot->new(
    grid => { min_x => 1,
              min_y => 2,
              max_x => 15,
              max_y => 16 }
              );

or $plot->grid($grid)

this is like a viewbox that shifts the boundaries of the plot.

if it's not specified, the module works out the viewbox from the highest and lowest X and Y co-ordinates in the list of points.

=head1 NOTES

this is a very, very early draft, released so Kake can use it in OpenGuides without having non-CPAN dependencies.

for an example of what i should be able to do with this, see http://space.frot.org/rdf/tubemap.svg ... a better way of making meta-information between the lines, some kind of matrix drawing

also, i want to supply access to different plotting algorithms, not just for the cartesian plane; particularly the buckminster fuller dymaxion map; cf Geo::Dymaxion, when that gets released (http://iconocla.st/hacks/dymax/ )

to see work in progress, http://frot.org/hacks/svgplot/ ; suggestions appreciated.

=head1 BUGS

full of them i am sure; this is a very alpha release; i won't change existing the API (if it deserves the name) though.

=head1 AUTHOR

    Jo Walsh  ( jo@london.pm.org )
    Kate L Pugh ( kake@earth.li )

=cut



