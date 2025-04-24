package Avro::Schema::Primitive::String;

use strict;
use warnings;
use parent 'Avro::Schema::Primitive';

our $VERSION = '++MODULE_VERSION++';

sub is_data_valid {
    my ( undef, $data ) = @_;

    return defined $data && ! ref $data;
}

1;
