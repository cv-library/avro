package Avro::Schema::Primitive::Null;

use strict;
use warnings;
use parent 'Avro::Schema::Primitive';

our $VERSION = '++MODULE_VERSION++';

sub is_data_valid {
    my ( undef, $data ) = @_;
    return ! defined $data;
}

1;
