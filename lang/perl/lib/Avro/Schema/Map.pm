package Avro::Schema::Map;

use strict;
use warnings;
use parent 'Avro::Schema::Base';

use Avro::Schema::Error::Parse;

sub new {
    my $class = shift;
    my %param = @_;
    my $schema = $class->SUPER::new(%param);

    my $struct = $param{struct}
        or throw Avro::Schema::Error::Parse("Map instantiation");

    my $values = $struct->{values};
    unless (defined $values && length $values) {
        throw Avro::Schema::Error::Parse("Map must declare 'values'");
    }
    $values = Avro::Schema->parse_struct($values, $param{names}, $param{namespace});
    $schema->{values} = $values;

    return $schema;
}

sub is_data_valid {
    my $schema = shift;
    my $default = shift;
    return 1 if $default && ref $default eq 'HASH';
    return 0;
}

sub values {
    my $schema = shift;
    return $schema->{values};
}

sub to_struct {
    my $schema = shift;
    my $known_names = shift || {};

    return {
        type => 'map',
        values => $schema->{values}->to_struct($known_names),
    };
}

1;
