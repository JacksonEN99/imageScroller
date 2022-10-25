use strict;
use warnings;
use List::Util 'shuffle';

my $hash = {}; # Used to hold all picture elements so that they can be randomly shuffled
my $indexCounter = 0;

# $filter_input is the file with a list of pictures to convert to scrolling webpage
# $input is the file that controls the parameters on how the scrolling webpages are created
my $filter_input = './pictures.txt';
my $input = './parameters.txt';

# File Modification Inputs
my $minRatio = '';
my $maxRatio = '';
my $equality = ''; # Either '<=', '>=', '<' or '>'
my $width_height = ''; # Either 'width/height' or 'height/width'
my $ratioTrueFalse = 'true';
my $wide_only = '';
my $tall_only = '';
my $random = '';

# Normal Inputs
my $output_file = '';
my $search = '';
my $remove = ''; # List of files that you don't want in 'search' results

#########################################################
# BEGIN HEADER HTML FILE
#########################################################
my $First_HTML = '<!DOCTYPE html>
<html lang="en">
 <head>
  <meta charset="utf-8">
  <meta name="description" content="Picture Shuffler">
  <meta name="viewport" content="width=device-width, initial-scale=1">
  <link rel="stylesheet" href="css/styles.css">
  <script src="js/script.js" defer></script>
  <title>Picture Shuffle</title>
 </head>
 <body>
  <div class="slider-container">
   <div>
	<h4>Picture Transition Time</h4>
	<input type="range" min="100" max="2000" class="slider" step="100" id="transitionTimeSlider">
	<p>Seconds: <span id="transitionTimeSpan"></span></p>
   </div>
   <hr>
   <div>
	<h4>Picture View Time</h4> 
	<input type="range" min="1000" max="10000" class="slider" step="100" id="viewTimeSlider">
	<p>Seconds: <span id="viewTimeSpan"></span></p>
   </div> 
  </div>
';
	
my $last_HTML = '
 </body>
</html>';

#######################################################
# END HEADER HTML FILE
#######################################################

open(FILTER_INPUT, "<$filter_input") or die ("Can't open file: $filter_input $!");
open(INPUT, "<$input") or die ("Can't open file: $input $!");

# Read the information from the Parameters.txt file which will determine how each HTML file is created
while(<INPUT>)
{
	my $z = $_;
	if($z =~ m/^#/ || $z =~ m/^$/) { next; }
	$z =~ s/\s+/ /g; # Remove more than one white-space
	$z =~ s/^\s+//;
	$z =~ s/\s+$//;
	
	if($z =~ m/^(?:ratio|wide_only|tall_only|random)/gi) {
		if($z=~ m/ratio/i)
		{
			$z =~ s/ratio\s+([\d.]*)\|*([\d.]*)\s*([<=>]+)\s*(.*)$/$1$2$3$4/i;
			$minRatio = $1;
			$maxRatio = $2;
			$equality = $3;
			$width_height = $4;
			if($maxRatio eq '') {
				if($equality eq '<=') {
					$maxRatio = 100;
				}
				elsif($equality eq '>=') {
					$maxRatio = 0;
				}
			}
		}
		if($z eq 'random') { $random = 'true'; }
		if($z eq 'wide_only') { $wide_only = 'true'; }
		if($z eq 'tall_only') { $tall_only = 'true'; }
		next;
	}

	($output_file, $search, $remove) = split / /, $z;

	# Remove all characters from new folder name
	$output_file =~ s/[\[\]\-_]*(\w*)[\[\]\-_]*/$1/g;

	# Filter '$search' input
	if($search =~ m/\|/g && $search =~ m/&/g)
	{
		my @temp = split /&/, $search;
		$search = '';
		foreach(@temp)
		{
			$search .= '(?=.*(?:' . $_ . ').*)';
			## UNCOMMENT BELOW IF YOU WANT SEARCH WORDS TO BE EXACT
			#$search .= '(?=.*[_-](?:' . $_ . ')[_-].*)';
		}
	}
	else
	{	
		if($search =~ m/\|/g)
		{
			$search = '[-_](?:' . $search . ')[-_]';
		}

		if ($search =~ m/&/g)
		{
			my @temp = split('&', $search);
			$search = '';
			foreach (@temp)
			{
				$search .= '(?=.*[-_]';
				$search .= $_;
				$search .= ')';
			}
		}
	}
	
	# Filter '$remove' input
	if(defined($remove)) {
		if($remove =~ m/\|/g) {
			$remove = '(?:[-_]' . $remove . '[-_])';
		}

		if ($remove =~ m/&/g) {
			my @temp = split('&', $remove);
			$remove = '';
			foreach (@temp) {
				$remove .= '(?=.*[-_]';
				$remove .= $_;
				$remove .= '[-_].*)';
			}
		}	
	} else {
		$remove = '^$';
	}
	
	if ($output_file =~ m/|/g)
	{
		$output_file =~ s/\|/_or_/gi;
	}
	if( $output_file =~ m/&/g)
	{
		$output_file =~ s/&/_and_/gi;
	}
	
	# Create the HTML file with the name being specified in the Parameters.txt file
	my $output = "$output_file.html";
	open(OUTPUT, ">$output") or die ("Can't open file: $output $!");
	print OUTPUT $First_HTML;
	seek(FILTER_INPUT,0,0); # Go to the beginning of the file with all the information about the pictures 
	
	# Read the information from the 'pictures.txt' file
	while(<FILTER_INPUT>)
	{
		my $fileName = $_;
		my $origName = $_;
		# Parse the 1st, 2nd, and last comma-separated line item into individual variables
		$fileName =~ s/^(.*?),(.*?),.*,(.*?)$/$1 $2 $3/gi;
		my $folder = $1;
		my $name = $2;
		my $SHA = $3;
		$name = lc($name);
		
		my $a = $name;
		chomp($a);

		# If picture file name contains '$search' but doesn't contain '$remove', do the following
		if($a =~ m/$search/i && $a !~ m/$remove/i)
		{
			my $x = $origName;

			$x =~ s/^(.*?),(.*?),(.*?),(.*?),(.*?),(.*?)$/$1 $2 $3 $4 $5 $6/gi;
			my ($folder, $file, $width, $height);
			$folder = $1;
			$file = $2;
			$width = $4;
			$height = $5;
			$folder =~ s#Images#\.\/images#ig;	
			
			# If the 'parameter.txt' file had the 'ratio' attribute uncommented, perform the following
			if($minRatio ne '') {
				if($width_height eq 'width/height') {
					if($equality eq '<=') {
						if($minRatio <= $width/$height && $maxRatio >= $width/$height) {
							$ratioTrueFalse = 'true';
						} else { $ratioTrueFalse = 'false'; }
					}
					elsif($equality eq '>=') {
						if($minRatio >= $width/$height && $maxRatio <= $width/$height) {
							$ratioTrueFalse = 'true';
						} else { $ratioTrueFalse = 'false'; }
					}
				}
				elsif($width_height eq 'height/width') {
					if($equality eq '<=') {
						if($minRatio <= $height/$width && $maxRatio >= $height/$width) {
							$ratioTrueFalse = 'true';
						} else { $ratioTrueFalse = 'false'; }
					}
					elsif($equality eq '>=') {
						if($minRatio >= $height/$width && $maxRatio <= $height/$width) {
							$ratioTrueFalse = 'true';
						} else { $ratioTrueFalse = 'false'; }					
					}
				}
				else { $ratioTrueFalse = 'false'; }				
			}
					
			if ($height < $width && $tall_only ne 'true' && $ratioTrueFalse eq 'true')
			{
				$indexCounter++;

				my $caption = "$file</span><span>Width: $width Height: $height";			
				my $wide_input = '<figure class="flex-item-wide"><img src="' . $folder . '/' . $file . '" alt=""><figcaption class="caption-box"><span>' . $caption . '</span></figcaption></figure>';
				$hash->{$indexCounter} = [1, $wide_input];
			}
			elsif ($width < $height && $wide_only ne 'true' && $ratioTrueFalse eq 'true')
			{
				$indexCounter++;
				
				my $caption = "$file</span><span>Width: $width Height: $height";
				my $tall_input = '<figure class="flex-item"><img src="' . $folder . '/' . $file . '" alt=""><figcaption class="caption-box"><span>' . $caption . '</span></figcaption></figure>';
				$hash->{$indexCounter} = [0, $tall_input];
			}
		}
	}
	
	my @shuffled = [];
	my $tallPicCounter = 0;
	my $widePicCounter = 0;
	my $tallPicHTML = '';
	my $widePicHTML = '';
	
	# If the 'parameter.txt' file has the 'random' attribute commented-out, don't shuffle the results; do otherwise 
	if($random eq '') {
		@shuffled = keys %$hash;		
	} else {
		@shuffled = shuffle(keys %$hash);
	}
	
	for(my $x = 0; $x < @shuffled; $x++) {
		my $random_value = $hash->{$shuffled[$x]};

		# Create three pictures per '<section>' for pictures that are 'tall' and two pictures per '<section>' for pictures that are 'wide'
		if(@$random_value[0] == 0) {
			if($tallPicCounter == 0) {
				$tallPicCounter++;
				$tallPicHTML = '<section class="flex-container">' . @$random_value[1];
			} elsif($tallPicCounter == 2) {
				$tallPicCounter = 0;
				$tallPicHTML .= @$random_value[1] . '</section>' . "\n";
				print OUTPUT $tallPicHTML;
			} else {
				$tallPicCounter++;
				$tallPicHTML .= @$random_value[1];
			}
		} else {
			if($widePicCounter == 0) {
				$widePicCounter++;
				$widePicHTML = '<section class="flex-container">' . @$random_value[1];
			} else {
				$widePicCounter = 0;
				$widePicHTML .= @$random_value[1] . '</section>' . "\n";
				print OUTPUT $widePicHTML;
			}
		}
	}
	undef $hash;
	undef @shuffled;
	print OUTPUT $last_HTML;
	close(OUTPUT);
	print "SEARCH: $search\n";
	print "REMOVE: $remove\n";
}

close(FILTER_INPUT);
close(INPUT);