# Licensed to the Apache Software Foundation (ASF) under one
# or more contributor license agreements.  See the NOTICE file
# distributed with this work for additional information
# regarding copyright ownership.  The ASF licenses this file
# to you under the Apache License, Version 2.0 (the
# "License"); you may not use this file except in compliance
# with the License.  You may obtain a copy of the License at
#
#   https://www.apache.org/licenses/LICENSE-2.0
#
# Unless required by applicable law or agreed to in writing,
# software distributed under the License is distributed on an
# "AS IS" BASIS, WITHOUT WARRANTIES OR CONDITIONS OF ANY
# KIND, either express or implied.  See the License for the
# specific language governing permissions and limitations
# under the License.

package Avro::Schema;
use strict;
use warnings;

use Carp;
use JSON::MaybeXS ();
use Try::Tiny;
use Avro::Schema::Error::Parse;
use Avro::Schema::Primitive;
use Avro::Schema::Record;
use Avro::Schema::Enum;
use Avro::Schema::Array;
use Avro::Schema::Map;
use Avro::Schema::Fixed;
use Avro::Schema::Union;

our $VERSION = '++MODULE_VERSION++';

my $json = JSON::MaybeXS->new->allow_nonref;

sub parse {
    my $schema      = shift;
    my $json_string = shift;
    my $names       = shift || {};
    my $namespace   = shift || "";

    my $struct = try {
        $json->decode($json_string);
    }
    catch {
        throw Avro::Schema::Error::Parse(
            "Cannot parse json string: $_"
        );
    };
    return $schema->parse_struct($struct, $names, $namespace);
}

sub to_string {
    my $class = shift;
    my $struct = shift;
    return $json->encode($struct);
}

sub parse_struct {
    my $schema = shift;
    my $struct = shift;
    my $names = shift || {};
    my $namespace = shift || "";

    ## 1.3.2 A JSON object
    if (ref $struct eq 'HASH') {
        my $type = $struct->{type}
            or throw Avro::Schema::Error::Parse("type is missing");
        if ( Avro::Schema::Primitive->is_type_valid($type) ) {
            return Avro::Schema::Primitive->new(type => $type);
        }
        ## XXX technically we shouldn't allow error type other than in
        ## a Protocol definition
        if ($type eq 'record' or $type eq 'error') {
            return Avro::Schema::Record->new(
                struct => $struct,
                names => $names,
                namespace => $namespace,
            );
        }
        elsif ($type eq 'enum') {
            return Avro::Schema::Enum->new(
                struct => $struct,
                names => $names,
                namespace => $namespace,
            );
        }
        elsif ($type eq 'array') {
            return Avro::Schema::Array->new(
                struct => $struct,
                names => $names,
                namespace => $namespace,
            );
        }
        elsif ($type eq 'map') {
            return Avro::Schema::Map->new(
                struct => $struct,
                names => $names,
                namespace => $namespace,
            );
        }
        elsif ($type eq 'fixed') {
            return Avro::Schema::Fixed->new(
                struct => $struct,
                names => $names,
                namespace => $namespace,
            );
        }
        else {
            throw Avro::Schema::Error::Parse("unknown type: $type");
        }
    }
    ## 1.3.2 A JSON array, representing a union of embedded types.
    elsif (ref $struct eq 'ARRAY') {
        return Avro::Schema::Union->new(
            struct => $struct,
            names => $names,
            namespace => $namespace,
        );
    }
    ## 1.3.2 A JSON string, naming a defined type.
    else {
        my $type = $struct;
        ## It's one of our custom defined type

        ## Short name provided, prepend the namespace
        if ( $type !~ /\./ ) {
            my $fulltype = $namespace . '.' . $type;
            if (exists $names->{$fulltype}) {
                return $names->{$fulltype};
            }
        }

        ## Fully-qualified name
        if (exists $names->{$type}) {
            return $names->{$type};
        }

        ## It's a primitive type
        return Avro::Schema::Primitive->new(type => $type);
    }
}

sub match {
    my $class = shift;
    my %param = @_;

    my $reader = $param{reader}
        or croak "missing reader schema";
    my $writer = $param{writer}
        or croak "missing writer schema";

    my $wtype = ref $writer ? $writer->type : $writer;
    my $rtype = ref $reader ? $reader->type : $reader;
    ## 1.3.2 either schema is a union
    return $wtype if $wtype eq 'union' or $rtype eq 'union';

    ## 1.3.2 both schemas have same primitive type
    return $wtype if $wtype eq $rtype
             && Avro::Schema::Primitive->is_type_valid($wtype);

    ## 1.3.2
    ## int is promotable to long, float, or double
    if ($wtype eq 'int' && (
        $rtype eq 'float' or $rtype eq 'long' or $rtype eq 'double'
    )) {
        return $rtype;
    }
    ## long is promotable to float or double
    if ($wtype eq 'long' && (
        $rtype eq 'float' or $rtype eq 'double'
    )) {
        return $rtype;
    }
    ## float is promotable to double
    if ($wtype eq 'float' && $rtype eq 'double') {
        return $rtype;
    }
    return 0 unless $rtype eq $wtype;

    ## 1.3.2 {subtype and/or names} match
    if ($rtype eq 'array') {
        return $wtype if $class->match(
            reader => $reader->items,
            writer => $writer->items,
        );
    }
    elsif ($rtype eq 'record') {
        return $wtype if $reader->fullname eq $writer->fullname;
    }
    elsif ($rtype eq 'map') {
        return $wtype if $class->match(
            reader => $reader->values,
            writer => $writer->values,
        );
    }
    elsif ($rtype eq 'fixed') {
        return $wtype if $reader->size     eq $writer->size
                      && $reader->fullname eq $writer->fullname;
    }
    elsif ($rtype eq 'enum') {
        return $wtype if $reader->fullname eq $writer->fullname;
    }
    return 0;
}

1;
