package Avro::Schema::Primitive::Float;

use strict;
use warnings;
use feature 'state';
use parent 'Avro::Schema::Primitive';

our $VERSION = '++MODULE_VERSION++';

use Regexp::Common;

sub is_data_valid {
    my ( undef, $data ) = @_;

    return !!0 unless defined $data;
    return $data =~ /^$RE{num}{real}$/
}

1;
