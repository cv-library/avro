package Avro::Schema::Primitive::Int;

use strict;
use warnings;
use parent 'Avro::Schema::Primitive';

our $VERSION = '++MODULE_VERSION++';

use constant MAX => 0x7FFF_FFFF;
use constant MIN => -0x8000_0000;

sub is_data_valid {
    my ( undef, $data ) = @_;

    return !!0 unless defined $data;

    no warnings 'numeric';

    return !!0 if $data < MIN || $data > MAX;

    my $packed = pack 'l', $data;
    return $data eq unpack 'l', $packed;
}

# Delete private symbols to avoid adding them to the API
delete $Avro::Schema::Primitive::Int::{$_} for <{MIN,MAX}>;

1;
