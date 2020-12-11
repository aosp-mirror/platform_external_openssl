#!/usr/bin/perl -w

use strict;
use warnings;

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
            print "        \"android/generated/$src\",\n";
        };
    };
}

print "cc_defaults {\n";
print "    name: \"libopenssl_crypto_srcs\",\n";
print "    cflags: [\n";
foreach my $flag (@{$configdata::config{lib_defines}}) {
    print "        \"-D$flag\",\n";
};
print "    ],\n";
print "    srcs: [\n";
collect_sources("libcrypto");
print "    ],\n";
print "}\n";

print "cc_defaults {\n";
print "    name: \"libopenssl_ssl_srcs\",\n";
print "    cflags: [\n";
foreach my $flag (@{$configdata::config{lib_defines}}) {
    print "        \"-D$flag\",\n";
};
print "    ],\n";
print "    srcs: [\n";
collect_sources("libssl");
print "    ],\n";
print "}\n";

print "cc_defaults {\n";
print "    name: \"libopenssl_apps_srcs\",\n";
print "    cflags: [\n";
foreach my $flag (@{$configdata::config{lib_defines}}) {
    print "        \"-D$flag\",\n";
};
print "    ],\n";
print "    srcs: [\n";
collect_sources("apps/libapps.a");
print "    ],\n";
print "}\n";

print "cc_defaults {\n";
print "    name: \"openssl_app_srcs\",\n";
print "    srcs: [\n";
collect_sources("apps/openssl");
print "    ],\n";
print "}\n";