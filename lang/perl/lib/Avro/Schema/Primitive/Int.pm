package Avro::Schema::Primitive::Int;

use strict;
use warnings;
use parent 'Avro::Schema::Primitive';

our $VERSION = '++MODULE_VERSION++';

sub is_data_valid {
    my ( undef, $data ) = @_;

    return !!0 unless defined $data;

    no warnings 'numeric';

    my $packed = pack 'l', $data;
    return $data eq unpack 'l', $packed;
}

1;
