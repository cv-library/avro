package Avro::Schema::Primitive::Long;

use strict;
use warnings;
use parent 'Avro::Schema::Primitive';

our $VERSION = '++MODULE_VERSION++';

use Config;
use Try::Tiny;

# Private function deleted below, should be a lexical sub
sub _bigint {
    require Math::BigInt;
    my $val = Math::BigInt->new(shift);

    $Config{use64bitint}
        ? 0 + $val->bstr() # numify() loses precision
        : $val;
}

# Avro type limits
# Private constants deleted below
use constant MAX => _bigint('0x7FFF_FFFF_FFFF_FFFF');
use constant MIN => _bigint('-0x8000_0000_0000_0000');

sub is_data_valid {
    my ( undef, $data ) = @_;

    no warnings 'numeric';

    return !!0 unless defined $data;
    return !!0 if $data < MIN || $data > MAX;

    unless ($Config{use64bitint}) {
        require Math::BigInt;

        my $int = try {
            Math::BigInt->new($data);
        }
        catch {
            warn "probably a unblessed ref: $_";
        };

        return defined $int && !$int->is_nan && $int->ble(MAX);
    }

    my $packed = pack 'q', $data;
    return $data eq unpack 'q', $packed;
}

# Delete private symbols to avoid adding them to the API
delete $Avro::Schema::Primitive::Long::{$_} for '_bigint', <{MIN,MAX}>;

1;
