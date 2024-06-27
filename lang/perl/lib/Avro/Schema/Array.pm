package Avro::Schema::Array;

use strict;
use warnings;
use parent 'Avro::Schema::Base';

use Avro::Schema::Error::Parse;

sub new {
    my $class = shift;
    my %param = @_;
    my $schema = $class->SUPER::new(%param);

    my $struct = $param{struct}
        or throw Avro::Schema::Error::Parse("Enum instantiation");

    my $items = $struct->{items}
        or throw Avro::Schema::Error::Parse("Array must declare 'items'");

    $items = Avro::Schema->parse_struct($items, $param{names}, $param{namespace});
    $schema->{items} = $items;
    return $schema;
}

sub is_data_valid {
    my $schema = shift;
    my $default = shift;
    return 1 if $default && ref $default eq 'ARRAY';
    return 0;
}

sub items {
    my $schema = shift;
    return $schema->{items};
}

sub to_struct {
    my $schema = shift;
    my $known_names = shift || {};

    return {
        type => 'array',
        items => $schema->{items}->to_struct($known_names),
    };
}

1;
