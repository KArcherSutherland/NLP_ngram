# This is a program designed to generate sentences from 
# n-grams read from files.  The first thing it does is save the command line arguments 
# for the n-gram number and the number of sentences to generate.  
# Then it splits the input files into an array of all the words in all 
# of the files and builds a hash of all of the n-grams and their counts, ending on periods 
# to mark the ends of sentences.  Afterwards, the program iterates through this hash and builds an n-1gram to 1gram 
# relational table that keeps track of all of the ngram functions.  The counts in this table are 
# calculated into normalized probabilities and added up so that they total 1.

# After that the sentences are suposed to be generated.  It currently only works for trigrams.

use Data::Dumper;

#save command line arguments
$n = shift @ARGV;
$numsent = shift @ARGV;
%onegram = ();
$periodcount;
#initialize hashes and text array
my %counts = ();
my %ngrams;
@text;

#reads text into text array, converts to lowercase, removes newlines and some punctuation and then tokenizes
while(<>) {
	chomp;
	$_=lc($_);
	s/\R//;
	s/\r//;
	s/\n//;	
	if ($_=~s/[\.\!\?]/ \. /){
		$periodcount++;
	}
	s/[,""]//;
	s/(mrs|dr|mr)\./$1/;
	@line = split/ +/; # splits on white
	push @text, @line;
	
	#print Dumper (\@text);
}
		
#this reads all the text in the text array into a hash that contains ngrams and their frequency and also ends on periods, 
#exclamation points, and question marks.
for my $pos (0 .. $#text+1) {
	if ($pos<$n){
		@startarr = ();
		$bb = $n-$pos-2;
		for $i(0..$bb){
			push @startarr, "<start>";
		}
		push @startarr, @text[0..$pos];
		# print "@startarr\n";
		my $phrase = join ' ', @startarr;;
		$counts{$phrase}++;
	}
	else{
		my $phrase = join ' ', @text[($pos - $n+1) .. $pos];
		if ($phrase=~m/((.+) ?)+(\.|\!|\?) ?(.*)/){
			$modphrase = $phrase;
			$modphrase=~s/((.+) ?)+(\.|!|\?) ?(.*)/$2$3/;
			@modarr = split/ /, $modphrase;
			@startarr = ();		
			$bb = $n - $#modarr-2;
			for $i(0..$bb){
				push @startarr, "<start>";
			}
			push @modarr, @startarr;
			$modphrase = join' ',@modarr;
			$counts{$modphrase}++;
			# print "--$modphrase--\n";
		}
		if ($phrase =~m/(\.|\!|\?) ?((.+) ?)+/){
			$modphrase = $phrase;
			$modphrase=~s/((.+) ?)+(\.|!|\?) ?((.+) ?)+/$3 $5/;
			@modarr = split/ /, $modphrase;
			@startarr = ();		
			$bb = $n - $#modarr-2;
			for $i(0..$bb){
				push @startarr, "<start>";
			}
			unshift @modarr, @startarr;
			$modphrase = join' ',@modarr;
			# print "$modphrase\n";
			$counts{$modphrase}++;
			
		}
		if ($phrase!~m/[\.\!\?]/){
			$modphrase = $phrase;
			$counts{$modphrase}++;
			# print "$modphrase\n";
		}
	}
} 

#adds periods for unigrams
if ($n==1){
	my $squiggle;
	$ngrams{$squiggle}{"."} = $periodcount;
}
#this splits the previous hash into a two-dimensional relational hash, with n-1 words 
#in one direction and the last word the other direction
while (my ($key, $value) = each(%counts)){
	my @arr = split/ /, $key;
	my $markov = join' ',@arr[0..$#arr-1];
	my $next = $arr[$#arr];
	$ngrams{$markov}{$next}=$value;
}


#this function normalizes all of the probabilities and scales them additively from 0-1 for each n-1 gram.
foreach my $ip (keys %ngrams){
	my $cc = 0;
	my $dd = 0;
	while (my($key, $value) = each %{ $ngrams{$ip}}){
		$cc+=$value;
	}
	while (my($key, $value) = each %{ $ngrams{$ip}}){
		$ngrams{$ip}{$key} = ($value/$cc);
	}
	while (my($key, $value) = each %{ $ngrams{$ip}}){
		$dd+=$value;
		$ngrams{$ip}{$key} = abs(1-$dd);
	}
	
}

# print Dumper (\%ngrams);


if ($n==1){
	for $i (1..$numsent){
		while ($endcheck ne "."){
			my $markov;
			my $rand = rand();
	
			$check++;
			foreach my $key (sort {$ngrams{$markov}{$a} <=>  $ngrams{$markov}{$b} } keys %{ $ngrams{$markov}}){
				$chance = $ngrams{$markov}{$key};
				$rand = rand();
				if ($rand>$chance){
					$next = $key;
				}
			} 
			
			$endcheck = $next;
			push @sent, $next;
			
			}

			print join' ',@sent[$n-1..$#sent];
			print "\n";
	}
}


# this is where sentences are generated for n>=2
if ($n>1){
	for $i (1..$numsent){
		my @sent = ();
		$rand = rand();
		my $start;
	
		@startarr = ();		
		$bb = $n -2;
		for $i(1..$bb){
			push @startarr, "<start>";
		}
	

		push @sent, @startarr;
		push @sent, ".";

		$thusfar = join' ', @sent;
		$endcheck = "";
		$check = 0;
		while ($endcheck ne "."&& $check < 50){
			my $markov = join' ',@sent[$check..$check+$n-2];
			foreach my $key (sort {$ngrams{$markov}{$a} <=>  $ngrams{$markov}{$b} } keys %{ $ngrams{$markov}}){
				$chance = $ngrams{$markov}{$key};
				$rand = rand();
				if ($rand>$chance){
					$next = $key;
				}
				
			}
			$endcheck = $next;
			push @sent, $next;	
			$check++;
		}

		print join' ',@sent[$n-1..$#sent];
		print "\n";
	
	}
}
