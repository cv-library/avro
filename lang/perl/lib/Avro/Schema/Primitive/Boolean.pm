package Avro::Schema::Primitive::Boolean;

use strict;
use warnings;
use parent 'Avro::Schema::Primitive';

use JSON::PP; # For is_bool

our $VERSION = '++MODULE_VERSION++';

sub is_data_valid {
    my ( undef, $data ) = @_;

    return !!0 unless defined $data;
    # For versions of Perl without builtin::is_bool
    #                  \
    return !!1 if $data eq '' || JSON::PP::is_bool($data);
    return !!0 if ref $data; # sometimes risky
    return $data =~ m{^(?:yes|no|y|n|t|f|true|false|0|1)$}i;
}

1;
