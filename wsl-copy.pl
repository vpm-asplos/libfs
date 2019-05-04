#!/usr/bin/perl
use warnings;
use File::Find;
use Digest::MD5::File qw( file_md5_hex );
 

my @content;
find (\&wanted, $SRC);
#find (\&wanted, ".");
#find (\&wanted, $DST);

#foreach my $path (@content) {
#    print $path."\n";
#}

sub wanted {
    my $srcpath = $File::Find::name; 
    if (-f $srcpath && -T _) {
	my $dstpath = $srcpath;
	$dstpath =~ s/^$SRC/$DST/g; 
        #print "plain ASCII file: $srcpath -> $dstpath\n";
	if (!-e $dstpath) {
            print "FILE NOT EXIST $dstpath\n";
            return;
	}

	my $srcmd5 = file_md5_hex($srcpath);
	my $dstmd5 = file_md5_hex($dstpath);
	if ($srcmd5 ne $dstmd5) {
            #print ("DIFF md5: $srcpath == $srcmd5 != $dstpath == $dstmd5\n");
            print ("cp $srcpath $dstpath\n");
	    system("cp",$srcpath,$dstpath);
	} 
#else {
#            print ("DIFF md5: $srcpath == $srcmd5 != $dstpath == $dstmd5\n");    	
#	}
    } 
    return;
}
