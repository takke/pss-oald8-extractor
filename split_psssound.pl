#!/usr/bin/perl

use strict;
use English;
use FileHandle;
use Compress::Raw::Zlib;
use File::Copy;

use vars qw($oald8dir $sound_type);
use vars qw($uk_output $us_output $sound_debug);

require './oald8_config.conf';

my $tmpfile = "contents.tmp";

my $silent_wav = pack("C*", 
		   0x52, 0x49, 0x46, 0x46, 0x25, 0x00, 0x00, 0x00,
		   0x57, 0x41, 0x56, 0x45, 0x66, 0x6d, 0x74, 0x20,
		   0x10, 0x00, 0x00, 0x00, 0x01, 0x00, 0x01, 0x00,
		   0x11, 0x2b, 0x00, 0x00, 0x11, 0x2b, 0x00, 0x00,
		   0x01, 0x00, 0x08, 0x00, 0x64, 0x61, 0x74, 0x61,
		   0x01, 0x00, 0x00, 0x00, 0x7f);

MAIN: {
	if ($sound_type != 0) {
		inflate_contents("uk_pron.skn/files.skn/");
		extract_contents("uk_pron.skn/files.skn/", $uk_output,    "Ch8h6h4h4h4h4", 19, "UK_");
		inflate_contents("us_pron.skn/files.skn/");
		extract_contents("us_pron.skn/files.skn/", $us_output,    "Ch8h6h4h4h4h4", 19, "US_");
	}
}

sub extract_contents
{
	my ($idmdir, $outdir, $template, $hdsize, $prename) = @_;
	
	my $srcpath = $oald8dir . $idmdir;
    $srcpath =~ s/^(.+?)\/?$/$1\//;

    my $files_dat = $srcpath . "files.dat";
    my $files_h = new FileHandle;
	my $tagfile = $outdir . "_tag.txt";
	
    mkdir $outdir, 0755 if !(-d $outdir);

    $files_h->open("$files_dat", 'r') or die "$files_dat: $^E\n";
    binmode $files_h;
    open(TAGFILE, ">$tagfile");

    my $ncontents;
    my @type;
    my @cont_offset;
    my @name_offset;

    for ($ncontents=0; ;$ncontents++) {
		last if read($files_h, my $tmp, $hdsize) != $hdsize;
		my @dat = unpack($template, $tmp);
		push @type, $dat[0];        # 1:text, 0:binary (?)
		push @cont_offset, hex(scalar reverse($dat[1])); #
		push @name_offset, hex(scalar reverse($dat[2])); #
    }

    my $name_tda  = $srcpath . "NAME.tda";
    my $name_h = new FileHandle;
    $name_h->open($name_tda, 'r') or die "$name_tda: $^E\n";
	binmode $name_h;

    my $uzcont_h = new FileHandle;
    $uzcont_h->open("$tmpfile", 'r') or die "$tmpfile: $^E\n";
	binmode $uzcont_h;

    for (my $i=0; $i<$ncontents; $i++) {
		my $name_size;
		my $uzcont_size;
		if ($i == $ncontents-1) {
			$name_size = (-s $name_tda)-$name_offset[$ncontents-1]-1;
			$uzcont_size = (-s "$tmpfile")-$cont_offset[$ncontents-1]-1;
		} else {
			$name_size = $name_offset[$i+1]-$name_offset[$i]-1;
			$uzcont_size = $cont_offset[$i+1]-$cont_offset[$i]-1;
		}
		
		seek($name_h, $name_offset[$i], 0);
		my $size = read($name_h, my $name, $name_size);
		print "name_size:[$name_size]\n" if $sound_debug;
		print "size     :[$size]\n" if $sound_debug;
		die $! if $size != $name_size;

		seek($uzcont_h, $cont_offset[$i], 0);
		my $size = read($uzcont_h, my $content, $uzcont_size);
		print "uzcont_size:[$uzcont_size]\n" if $sound_debug;
		print "size       :[$size]\n" if $sound_debug;
		die $! if $size != $uzcont_size;
		
		
		$| = 1;
		if (($i+1) % 10 == 0 || ($i+1)==$ncontents) {
		    my $mini_name = substr($name, 0, 35);
    		printf("%-70s\r", "$outdir (".($i+1)."/$ncontents) [$mini_name] ...");
    	}
		$| = 0;
		my $tagname = $name;
		$tagname =~ s/\..+$//g;     	# 拡張子を除去
		$tagname =~ tr/-_a-zA-Z0-9/_/c; # 使用不能文字を置き換え

		if ($name =~ /\.mp3$/) {
			my $wavefile = "$outdir/$prename$tagname.wav";
			my $mp3_err = "";
			open(OUT, ">$wavefile") or die "$wavefile :$!\n";
#			binmode OUT if $type[$i] == 0;
			binmode OUT;
			print OUT mp3_to_wav($content, $name, $mp3_err);
			close OUT;
			if ($mp3_err ne "") {
				print "$mp3_err\n";
				unlink $wavefile;
			} else {
				print TAGFILE "$prename$tagname $outdir/$prename$tagname.wav\n";
			}
		}
	}
    close TAGFILE;
	close $files_h;
	close $name_h;
	close $uzcont_h;
    unlink "$tmpfile";
	printf("%-70s\n", "$outdir ($ncontents) done.");
}

sub inflate_contents
{
	my($idmdir) = @_;
	
	my $srcpath = $oald8dir . $idmdir;
    $srcpath =~ s/^(.+?)\/?$/$1\//;

	$| = 1;
	printf("%-70s\r", "Inflating (".$idmdir.") ...");
	$| = 0;
    my $content_tda = $srcpath . "CONTENT.tda";
    my $content_tdz = $srcpath . "CONTENT.tda.tdz";

    my $contidx_h = new FileHandle;
    $contidx_h->open("$content_tdz", 'r') or die "$content_tdz: $^En";
    binmode $contidx_h;

    my $content_h = new FileHandle;
    $content_h->open("$content_tda", 'r') or die "$content_tda: $^E\n";
    binmode $content_h;

    open OUT, ">$tmpfile" or die "$tmpfile: $!\n";
    binmode OUT;

	my $offset = 0;
	
    while(){
		last if read($contidx_h, my $tmp, 8) != 8;
		my @dat = unpack("VV", $tmp);
		my ($zcont_size) = $dat[1];
#		my ($zcont_size) = unpack("x4V", $tmp);
		die "$^E\n" if read($content_h, my $zcont, $zcont_size) != $zcont_size;
		my ($inflater, $status) = new Compress::Raw::Zlib::Inflate(CRC32 => 1);
		die "Failed to initialize inflater\n" if $status != Z_OK;
		$status = $inflater->inflate($zcont, my $contents);
		my $csize = length $contents;
#		die "Failed to inflate\n" if ($status != Z_OK && $status != Z_STREAM_END);
		print OUT $contents;
		if ($csize != $dat[0])
		{
			printf("%-70s\n", "Failed to inflate $offset -> ".($offset+$dat[0])." ($csize != $dat[0])");
			my $template = "C".($dat[0]-$csize);
			my $dummy = pack($template,0);
			$csize = length $dummy;
			printf("%s\n", "dummy write $csize byte");
			print OUT $dummy;
		}
		$offset = $offset + $dat[0];
    }
    close OUT;
	close $contidx_h;
	close $content_h;

    return 1;
}

sub mp3_to_wav {
	my ($mp3, $mp3_name) = @_;
	my %info = ();
	my $wave = '';

Profiler:
	{
		my $count = 0;
		my @tmp;
		
		my @BRateTab1 = # MPEG I  - Layer III,II,I
			(0, 32, 40, 48, 56, 64, 80, 96,112,128,160,192,224,256,320,0,
			 0, 32, 48, 56, 64, 80, 96,112,128,160,192,224,256,320,384,0,
			 0, 32, 64, 96,128,160,192,224,256,288,320,352,384,416,448,0);
		my @BRateTab2 = # MPEG II - Layer III, II ,I
			(0,  8, 16, 24, 32, 40, 48, 56, 64, 80, 96,112,128,144,160,0,
			 0,  8, 16, 24, 32, 40, 48, 56, 64, 80, 96,112,128,144,160,0,
			 0, 32, 48, 56, 64, 80, 96,112,128,144,160,176,192,224,256,0);
		my @FreqTab = (11025, 12000,  8000, 0, # MPEG 2.5
					   0,     0,     0, 0,
					   22050, 24000, 16000, 0, # MPEG II
					   44100, 48000, 32000, 0  # MPEG I
					   );
		my @SmpsPerFrame = ( 576, 1152, 384, # MPEG 2.5
							 0,    0,   0, # Reserved
							 576, 1152, 384, # MPEG 2
							 1152, 1152, 384  # MPEG 1
							 );
		my ($mpeg_version, $layer);


		$info{'data_size'} = length($mp3);
		$info{'data_offset'} = 0;

		# check ID3v2 tag
		if (substr($mp3, 0, 3) eq 'ID3') {
			@tmp = unpack('x6C4', $mp3);
			my $tag_size = ($tmp[0] << 21) + ($tmp[1] << 14) + ($tmp[2] <<   7)
				+ $tmp[3] + 10;
			$info{'data_size'} -= $tag_size;
			$info{'data_offset'} += $tag_size;
		}

		#check ID3v1 tag
		if (substr($mp3, length($mp3) - 128, 3) eq 'TAG') {
			$info{'data_size'} -= 128;
		}

		$count = $info{'data_offset'};
		@tmp = unpack("C4", substr($mp3, $count, 4));
		if ($tmp[0] == 0xff && ($tmp[1] & 0xe0) == 0xe0) {
			$mpeg_version = ($tmp[1] >> 3) & 0x03;
			$layer        = ($tmp[1] >> 1) & 0x03;
		} else {
			$_[2] = "$PROGRAM_NAME: warning: failed to find first frame ($mp3_name).";
			return $silent_wav;
		}
		# $info{'i_bit_rate'} = $tmp[2] >> 4;
		my $i_bit_rate = $tmp[2] >> 4;

		if ($mpeg_version == 3) {
			# MPEG 1
			$info{'bit_rate'} = $BRateTab1[($layer - 1) * 16 + $i_bit_rate];
		} elsif ($mpeg_version == 2 || $mpeg_version == 0) {
			# MPEG 2 or MPEG 2.5
			$info{'bit_rate'} = $BRateTab2[($layer - 1) * 16 + $i_bit_rate];
		} else {
			$info{'bit_rate'} = 0;
		}

		# $info{'i_sampling_rate'} = (($tmp[2] >> 2) & 0x03);
		$info{'sampling_rate'} = $FreqTab[$mpeg_version * 4
										  + (($tmp[2] >> 2) & 0x03)];
		# $info{'i_padding_bit'}   = ($tmp[2] >> 1) & 0x01;
		my $i_padding_bit  = ($tmp[2] >> 1) & 0x01;
		# $info{'i_channel_mode'}  = ($tmp[3] >> 6) & 0x03;

		$info{'sample_per_frame'} = $SmpsPerFrame[$mpeg_version * 3 + $layer - 1];
		$info{'frame_size'} =
			int($info{'sample_per_frame'} / 8 * $info{'bit_rate'} * 1000
				/ $info{'sampling_rate'} + $i_padding_bit + 0.5);
		$info{'frame_length'} = int(($info{'data_size'} / $info{'frame_size'})
									+ 0.5);
		$info{'total_sec'} = ($info{'frame_length'} * $info{'sample_per_frame'})
			/ $info{'sampling_rate'};
		$info{'sample_length'} = $info{'frame_length'} * $info{'sample_per_frame'};
		
		$info{'channel_mode'} = ((($tmp[3] >> 6) & 0x03) < 3) ? 2 : 1;
		$info{'padding'} = ($i_padding_bit == 1) ? 1 : 2;
	}

	if ($info{'sample_per_frame'} == 0
		|| $info{'sampling_rate'} == 0
			|| $info{'bit_rate'} == 0) {
		$_[2] = "$PROGRAM_NAME: warning: RIFF/WAVE header generation was failed ($mp3_name).";
		return $silent_wav;
	}


	$wave .= 'RIFF';
	$wave .= pack('V', $info{'data_size'} + 70 - 8);
	$wave .= 'WAVEfmt ';
	$wave .= pack('V', 30);
	$wave .= pack('v', 0x55);
	$wave .= pack('v', $info{'channel_mode'});
	$wave .= pack('V', $info{'sampling_rate'});
	$wave .= pack('V', $info{'bit_rate'} * 1000 / 8);
	$wave .= pack('v', 1);
	$wave .= pack('v', 0);
	$wave .= pack('v', 0x0c);
	$wave .= pack('v', 0x01);
	$wave .= pack('V', $info{'padding'});
	$wave .= pack('v', $info{'frame_size'});
	$wave .= pack('v', 1);
	$wave .= pack('v', 0x571);

	$wave .= 'fact';
	$wave .= pack('V', 4);
	$wave .= pack('V', $info{'sample_length'});

	$wave .= "data";
	$wave .= pack("V", $info{'data_size'});

	$wave .= substr($mp3, $info{'data_offset'}, $info{'data_size'});

	return $wave;
}

