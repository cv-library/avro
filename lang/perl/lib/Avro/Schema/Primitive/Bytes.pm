package Avro::Schema::Primitive::Bytes;

use strict;
use warnings;
use parent 'Avro::Schema::Primitive';

our $VERSION = '++MODULE_VERSION++';

sub is_data_valid {
    my ( undef, $data ) = @_;

    return !!0 if ! defined $data || ref $data;
    return !!1 unless utf8::is_utf8($data) and $data =~ /[^\x00-\xFF]/;
    return !!0;
}

1;
