package Avro::Schema::Record;

use parent 'Avro::Schema::Named';
use Scalar::Util;
use Avro::Schema::Error::Parse;
use Avro::Schema::Field;

sub new {
    my $class = shift;
    my %param = @_;

    my $names  = $param{names} ||= {};
    my $schema = $class->SUPER::new(%param);

    my $fields = $param{struct}{fields}
        or throw Avro::Schema::Error::Parse("Record must have Fields");

    throw Avro::Schema::Error::Parse("Record.Fields must me an array")
        unless ref $fields eq 'ARRAY';

    my $namespace = $schema->namespace;

    my @fields;
    for my $field (@$fields) {
        my $f = Avro::Schema::Field->new($field, $names, $namespace);
        push @fields, $f;
    }
    $schema->{fields} = \@fields;
    return $schema;
}

sub to_struct {
    my $schema = shift;
    my $known_names = shift || {};
    ## consider that this record type is now known (will serialize differently)
    my $fullname = $schema->fullname;
    if ($known_names->{ $fullname }++) {
        return $fullname;
    }
    return {
        type => $schema->{type},
        name => $fullname,
        fields => [
            map { $_->to_struct($known_names) } @{ $schema->{fields} }
        ],
    };
}

sub fields {
    my $schema = shift;
    return $schema->{fields};
}

sub fields_as_hash {
    my $schema = shift;
    unless (exists $schema->{_fields_as_hash}) {
        $schema->{_fields_as_hash} = {
            map { $_->{name} => $_ } @{ $schema->{fields} }
        };
    }
    return $schema->{_fields_as_hash};
}

sub is_data_valid {
    my $schema = shift;
    my $data = shift;
    for my $field (@{ $schema->{fields} }) {
        my $key = $field->{name};
        return 0 unless $field->is_data_valid($data->{$key});
    }
    return 1;
}

1;
