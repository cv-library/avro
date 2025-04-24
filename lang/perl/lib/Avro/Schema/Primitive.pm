package Avro::Schema::Primitive;

use strict;
use warnings;
use parent 'Avro::Schema::Base';

our $VERSION = '++MODULE_VERSION++';

use Carp;

use Avro::Schema::Primitive::Boolean;
use Avro::Schema::Primitive::Bytes;
use Avro::Schema::Primitive::Double;
use Avro::Schema::Primitive::Float;
use Avro::Schema::Primitive::Int;
use Avro::Schema::Primitive::Long;
use Avro::Schema::Primitive::Null;
use Avro::Schema::Primitive::String;

my %PrimitiveType = map { $_ => 1 } qw/
    null
    boolean
    int
    long
    float
    double
    bytes
    string
/;

my %Singletons;

## FIXME: useless lazy generation
sub new {
    my $class = shift;
    my %param = @_;

    my $type = $param{type}
        or croak "Schema must have a type";

    throw Avro::Schema::Error::Parse("Not a primitive type $type")
        unless $class->is_type_valid($type);

    $class = "${class}::" . ucfirst $type;

    $Singletons{$class} //= $class->SUPER::new;
}

sub is_type_valid {
    return $PrimitiveType{ $_[1] || "" };
}

sub to_struct {
    my $schema = shift;
    return $schema->type;
}

1;
