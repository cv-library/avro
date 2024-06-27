package Avro::Schema::Field;

use strict;
use warnings;

my %ValidOrder = map { $_ => 1 } qw/ascending descending ignore/;

use Avro::Schema;
use Avro::Schema::Error::Parse;

sub new {
    my $class = shift;
    my ($struct, $names, $namespace) = @_;

    my $name = $struct->{name};
    throw Avro::Schema::Error::Parse("Record.Field.name is required")
        unless defined $name && length $name;

    my $type = $struct->{type};
    throw Avro::Schema::Error::Parse("Record.Field.name is required")
        unless defined $type && length $type;

    $type = Avro::Schema->parse_struct($type, $names, $namespace);
    my $field = { name => $name, type => $type };
    #TODO: find where to weaken precisely
    #Scalar::Util::weaken($struct->{type});

    if (exists $struct->{default}) {
        my $is_valid = $type->is_data_valid($struct->{default});
        my $t = $type->type;
        throw Avro::Schema::Error::Parse(
            "default value doesn't validate $t: '$struct->{default}'"
        ) unless $is_valid;

        ## small Perlish special case
        if ($type eq 'boolean') {
            $field->{default} = $struct->{default} ? 1 : 0;
        }
        else {
            $field->{default} = $struct->{default};
        }
    }
    if (my $order = $struct->{order}) {
        throw Avro::Schema::Error::Parse(
            "Order '$order' is not valid'"
        ) unless $ValidOrder{$order};
        $field->{order} = $order;
    }
    return bless $field, $class;
}

sub is_data_valid {
    my $field = shift;
    my $data = shift;
    return 1 if $field->{type}->is_data_valid($data);
    return 0;
}

sub to_struct {
    my $field = shift;
    my $known_names = shift || {};
    my $type = $field->{type}->to_struct($known_names);
    return { name => $field->{name}, type => $type };
}

1;
