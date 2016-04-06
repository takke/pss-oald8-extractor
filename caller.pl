#!/usr/bin/perl

#
# 各スクリプトを PAR 化のために一元的に呼び出す
#

use Getopt::Long;

MAIN: {
    #
    # コマンド行を解析する
    #
    my $call_type = '';
    GetOptions('calltype=s' => \$call_type, 'workdir=s' => \$work_directory);
    
    if ($call_type eq '') {
        print "usage: fpwcaller.pl -calltype gaiji|halfchar|split...\n";
        die "\n";
    }
    
    print "call type: [${call_type}]\n";
    
    if ($call_type eq 'split_psssound') {
        require 'split_psssound.pl';
    } elsif ($call_type eq 'psstool') {
        require 'psstool.pl';
    } else {
        print "unknown call type..";
    }
}

1;
