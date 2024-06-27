package Avro::Schema::Named;

use parent 'Avro::Schema::Base';

use Scalar::Util;
use Avro::Schema::Error::Name;
use Avro::Schema::Error::Parse;

my %NamedType = map { $_ => 1 } qw/
    record
    enum
    fixed
/;

sub new {
    my $class = shift;
    my %param = @_;

    my $schema = $class->SUPER::new(%param);

    my $names     = $param{names}  || {};
    my $struct    = $param{struct} || {};
    my $name      = $struct->{name};
    unless (defined $name && length $name) {
        throw Avro::Schema::Error::Parse( "Missing name for $class" );
    }
    my $namespace = $struct->{namespace};
    unless (defined $namespace && length $namespace) {
        $namespace = $param{namespace};
    }

    $schema->set_names($namespace, $name);
    $schema->add_name($names);

    return $schema;
}

sub is_type_valid {
    return $NamedType{ $_[1] || "" };
}

sub set_names {
    my $schema = shift;
    my ($namespace, $name) = @_;

    my @parts = split /\./, ($name || ""), -1;
    if (@parts > 1) {
        $name = pop @parts;
        $namespace = join ".", @parts;
        if (grep { ! length $_ } @parts) {
            throw Avro::Schema::Error::Name(
                "name '$name' is not a valid name"
            );
        }
    }

    ## 1.3.2 The name portion of a fullname, and record field names must:
    ## * start with [A-Za-z_]
    ## * subsequently contain only [A-Za-z0-9_]
    my $type = $schema->{type};
    unless (length $name && $name =~ m/^[A-Za-z_][A-Za-z0-9_]*$/) {
        throw Avro::Schema::Error::Name(
            "name '$name' is not valid for $type"
        );
    }
    if (defined $namespace && length $namespace) {
        for (split /\./, $namespace, -1) {
            unless ($_ && /^[A-Za-z_][A-Za-z0-9_]*$/) {
                throw Avro::Schema::Error::Name(
                    "namespace '$namespace' is not valid for $type"
                );
            }
        }
    }
    $schema->{name} = $name;
    $schema->{namespace} = $namespace;
}

sub add_name {
    my $schema = shift;
    my ($names) = @_;

    my $name = $schema->fullname;
    if ( exists $names->{ $name } ) {
        throw Avro::Schema::Error::Parse( "Name $name is already defined" );
    }
    $names->{$name} = $schema;
    Scalar::Util::weaken( $names->{$name} );
    return;
}

sub fullname {
    my $schema = shift;
    return join ".",
        grep { defined $_ && length $_ }
        map { $schema->{$_ } }
        qw/namespace name/;
}

sub namespace {
    my $schema = shift;
    return $schema->{namespace};
}

1;
