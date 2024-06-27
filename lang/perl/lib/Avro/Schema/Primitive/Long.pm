package Avro::Schema::Primitive::Long;

use strict;
use warnings;
use feature 'state';
use parent 'Avro::Schema::Primitive';

our $VERSION = '++MODULE_VERSION++';

use Config;
use Try::Tiny;

sub is_data_valid {
    my ( undef, $data ) = @_;

    return !!0 unless defined $data;

    unless ($Config{use64bitint}) {
        require Math::BigInt;

        my $int = try {
            Math::BigInt->new($data);
        }
        catch {
            warn "probably a unblessed ref: $_";
        };

        return !!0 if !defined $int || $int->is_nan;

        state $max = Math::BigInt->new( "0x7FFF_FFFF_FFFF_FFFF" );
        return $int->bcmp($max) <= 0 ? 1 : 0;
    }

    my $packed = pack 'q', $data;
    return $data eq unpack 'q', $packed;
}

1;
