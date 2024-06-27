package Avro::Schema::Base;

use parent Avro::Schema;

sub new {
    my $class = shift;
    my %param = @_;

    my $type = $param{type};
    if (!$type) {
        my ($t) = $class =~ /::([^:]+)$/;
        $type = lc ($t);
    }
    my $schema = bless {
        type => $type,
    }, $class;
    return $schema;
}

sub type { shift->{type} }

sub to_string {
    my $schema = shift;
    my $known_names = shift || {};
    return Avro::Schema->to_string($schema->to_struct($known_names));
}

1;
