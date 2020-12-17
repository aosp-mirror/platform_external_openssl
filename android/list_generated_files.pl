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
            collect_sources($src);
        } elsif ($src !~ /^\.\.\/\.\.\//) {
            print "$src\n";
        };
    };
    # Print any generated headers
    foreach my $dep (@{$configdata::unified_info{depends}->{$name}}) {
        print "$dep\n" if $dep =~ /\.h$/;
    };
}

# Print the globally needed headers
foreach my $file (@{$configdata::unified_info{depends}->{""}}) {
    print "$file\n";
};

collect_sources("libcrypto");
collect_sources("libssl");
collect_sources("apps/openssl");