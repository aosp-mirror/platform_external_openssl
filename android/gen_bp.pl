#!/usr/bin/perl -w

use strict;
use warnings;

my $os = shift;
my $gendir = shift;

do "./configdata.pm";
die "configdata parse error: $@" if $@;

sub collect_sources {
    my $name = shift;
    my @srcs = @{$configdata::unified_info{sources}->{$name}};
    foreach my $src (@srcs) {
        if ($src =~ /\.o$/) {
            collect_sources($src)
        } elsif ($src =~ /^\.\.\/\.\.\/(.*)$/) {
            print "        \"$1\",\n";
        } else {
            print "        \"$gendir/$src\",\n";
        };
    };
}

sub cc_defaults {
    my $bpname = shift;
    my $library = shift;
    my $cflagsRef = shift;

    print "cc_defaults {\n";
    print "    name: \"openssl_${bpname}_${os}_defaults\",\n";
    print "    target: { ${os}: {\n";
    if (scalar(@$cflagsRef) != 0) {
        print "    cflags: [\n";
        foreach my $flag (@$cflagsRef) {
            print "        \"-D$flag\",\n";
        };
        print "    ],\n";
    }
    print "    srcs: [\n";
    collect_sources($library);
    print "    ],\n";
    print "    },},\n";
    print "}\n";    
}

print "// Autogenerated by android/regen.sh\n\n";
cc_defaults("crypto", "libcrypto", \@{$configdata::config{lib_defines}});
cc_defaults("ssl", "libssl", \@{$configdata::config{lib_defines}});
cc_defaults("apps", "apps/libapps.a", \@{$configdata::config{lib_defines}});
my @empty = ();
cc_defaults("app", "apps/openssl", \@empty);