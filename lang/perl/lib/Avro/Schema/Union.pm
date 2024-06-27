package Avro::Schema::Union;

use strict;
use warnings;
use parent 'Avro::Schema::Base';

use Avro::Schema::Error::Parse;

sub new {
    my $class = shift;
    my %param = @_;
    my $schema = $class->SUPER::new(%param);
    my $union = $param{struct}
        or throw Avro::Schema::Error::Parse("Union.new needs a struct");

    my $names = $param{names} ||= {};

    my @schemas;
    my %seen_types;
    for my $struct (@$union) {
        my $sch = Avro::Schema->parse_struct($struct, $names, $param{namespace});
        my $type = $sch->type;

        ## 1.3.2 Unions may not contain more than one schema with the same
        ## type, except for the named types record, fixed and enum. For
        ## example, unions containing two array types or two map types are not
        ## permitted, but two types with different names are permitted.
        if (Avro::Schema::Named->is_type_valid($type)) {
            $type = $sch->fullname; # resolve Named types to their name
        }
        ## XXX: I could define &type_name doing the correct resolution for all classes
        if ($seen_types{ $type }++) {
            throw Avro::Schema::Error::Parse(
                "$type is present more than once in the union"
            )
        }
        ## 1.3.2 Unions may not immediately contain other unions.
        if ($type eq 'union') {
            throw Avro::Schema::Error::Parse(
                "Cannot embed unions in union"
            );
        }
        push @schemas, $sch;
    }
    $schema->{schemas} = \@schemas;

    return $schema;
}

sub schemas {
    my $schema = shift;
    return $schema->{schemas};
}

sub is_data_valid {
    my $schema = shift;
    my $data = shift;
    for my $type ( @{ $schema->{schemas} } ) {
        if ( $type->is_data_valid($data) ) {
            return 1;
        }
    }
    return 0;
}

sub to_struct {
    my $schema = shift;
    my $known_names = shift || {};
    return [ map { $_->to_struct($known_names) } @{$schema->{schemas}} ];
}

1;
