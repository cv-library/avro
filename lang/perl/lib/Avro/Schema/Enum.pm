package Avro::Schema::Enum;

use strict;
use warnings;
use parent 'Avro::Schema::Named';

use Avro::Schema::Error::Parse;

sub new {
    my $class = shift;
    my %param = @_;
    my $schema = $class->SUPER::new(%param);
    my $struct = $param{struct}
        or throw Avro::Schema::Error::Parse("Enum instantiation");
    my $symbols = $struct->{symbols} || [];

    unless (@$symbols) {
        throw Avro::Schema::Error::Parse("Enum needs at least one symbol");
    }
    my %symbols;
    my $pos = 0;
    for (@$symbols) {
        if (ref $_) {
            throw Avro::Schema::Error::Parse(
                "Enum.symbol should be a string"
            );
        }
        throw Avro::Schema::Error::Parse("Duplicate symbol in Enum")
            if exists $symbols{$_};

        $symbols{$_} = $pos++;
    }
    $schema->{hash_symbols} = \%symbols;
    return $schema;
}

sub is_data_valid {
    my $schema = shift;
    my $data = shift;
    return 1 if defined $data && exists $schema->{hash_symbols}{$data};
    return 0;
}

sub symbols {
    my $schema = shift;
    unless (exists $schema->{symbols}) {
        my $sym = $schema->{hash_symbols};
        $schema->{symbols} = [ sort { $sym->{$a} <=> $sym->{$b} } keys %$sym ];
    }
    return $schema->{symbols};
}

sub symbols_as_hash {
    my $schema = shift;
    return $schema->{hash_symbols} || {};
}

sub to_struct {
    my $schema = shift;
    my $known_names = shift || {};

    my $fullname = $schema->fullname;
    if ($known_names->{ $fullname }++) {
        return $fullname;
    }
    return {
        type => 'enum',
        name => $schema->fullname,
        symbols => [ @{ $schema->symbols } ],
    };
}

1;
