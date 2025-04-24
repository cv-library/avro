package Avro::Schema::Fixed;

use strict;
use warnings;
use parent 'Avro::Schema::Named';

use Avro::Schema::Error::Parse;

sub new {
    my $class = shift;
    my %param = @_;
    my $schema = $class->SUPER::new(%param);

    my $struct = $param{struct}
        or throw Avro::Schema::Error::Parse("Fixed instantiation");

    my $size = $struct->{size};
    unless (defined $size && length $size) {
        throw Avro::Schema::Error::Parse("Fixed must declare 'size'");
    }
    if (ref $size) {
        throw Avro::Schema::Error::Parse(
            "Fixed.size should be a scalar"
        );
    }
    unless ($size =~ m{^\d+$} && $size > 0) {
        throw Avro::Schema::Error::Parse(
            "Fixed.size should be a positive integer"
        );
    }
    # Cast into numeric so that it will be encoded as a JSON number
    $schema->{size} = $size + 0;

    return $schema;
}

sub is_data_valid {
    my ( $schema, $data ) = @_;

    return 0 if utf8::is_utf8($data) && $data =~ /[^\x00-\xFF]/;
    return $data && length($data) == $schema->{size};
}

sub size {
    my $schema = shift;
    return $schema->{size};
}

sub to_struct {
    my $schema = shift;
    my $known_names = shift || {};

    my $fullname = $schema->fullname;
    if ($known_names->{ $fullname }++) {
        return $fullname;
    }

    return {
        type => 'fixed',
        name => $fullname,
        size => $schema->{size},
    };
}

1;
