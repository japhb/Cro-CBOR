unit module Cro::CBOR:auth<zef:japhb>:api<0>:ver<0.0.1>;


use Cro::BodyParser;
use Cro::HTTP::MimeTypes;
use Cro::HTTP::Message;
use Cro::HTTP::BodySerializers;
use Cro::HTTP::BodyParserSelectors;
use Cro::HTTP::BodySerializerSelectors;
use Cro::HTTP::Router::WebSocket;
use Cro::WebSocket::Message::Opcode;
use Cro::WebSocket::Client;

use CBOR::Simple;


# Make sure the CBOR MIME type is registered;
%mime<cbor> = 'application/cbor';


### HTTP PARSER AND SERIALIZER

class HTTP::BodyParser does Cro::BodyParser {
    method is-applicable(Cro::HTTP::Message $message --> Bool) {
        with $message.content-type {
            .type eq 'application' && .subtype eq 'cbor' || .suffix eq 'cbor'
        }
        else {
            False
        }
    }

    method parse(Cro::HTTP::Message $message --> Promise) {
        Promise(supply {
            my $payload = Blob.new;
            whenever $message.body-byte-stream -> $blob {
                $payload ~= $blob;
                LAST emit cbor-decode($payload);
            }
        })
    }
}


class HTTP::BodySerializer does Cro::HTTP::BodySerializer {
    method is-applicable(Cro::HTTP::Message $message, $body --> Bool) {
        with $message.content-type {
            .type eq 'application' && .subtype eq 'cbor' || .suffix eq 'cbor'
        }
        else {
            False
        }
    }

    method serialize(Cro::HTTP::Message $message, $body --> Supply) {
        my $cbor = cbor-encode($body);
        self!set-content-length($message, $cbor.bytes);
        supply { emit $cbor }
    }
}


### WEBSOCKET PARSER AND SERIALIZER

class WebSocket::BodyParser does Cro::BodyParser {
    method is-applicable($message) {
        # We presume that if this body parser has been installed, then we will
        # always be doing CBOR
        True
    }

    method parse($message) {
        $message.body-blob.then: -> $blob-promise {
            cbor-decode($blob-promise.result)
        }
    }
}


class WebSocket::BodySerializer does Cro::BodySerializer {
    method is-applicable($message, $body) {
        # We presume that if this body serializer has been installed, then we
        # will always be doing CBOR
        True
    }

    method serialize($message, $body) {
        $message.opcode = Binary;
        supply emit cbor-encode($body)
    }
}


### HTTP PARSER AND SERIALIZER SELECTORS

class HTTP::BodyParserSelector::Request
   is Cro::HTTP::BodyParserSelector::RequestDefault {
    method select(Cro::HTTP::Message $message --> Cro::BodyParser) {
        return HTTP::BodyParser if HTTP::BodyParser.is-applicable($message);
        callsame;
    }
}


class HTTP::BodyParserSelector::Response
   is Cro::HTTP::BodyParserSelector::ResponseDefault {
    method select(Cro::HTTP::Message $message --> Cro::BodyParser) {
        return HTTP::BodyParser if HTTP::BodyParser.is-applicable($message);
        callsame;
    }
}

class HTTP::BodySerializerSelector::Request
   is Cro::HTTP::BodySerializerSelector::RequestDefault {
    method select(Cro::HTTP::Message $message, $body --> Cro::HTTP::BodySerializer) {
        return HTTP::BodySerializer if HTTP::BodySerializer.is-applicable($message, $body);
        callsame;
    }
}

class HTTP::BodySerializerSelector::Response
   is Cro::HTTP::BodySerializerSelector::ResponseDefault {
    method select(Cro::HTTP::Message $message, $body --> Cro::HTTP::BodySerializer) {
        return HTTP::BodySerializer if HTTP::BodySerializer.is-applicable($message, $body);
        callsame;
    }
}


### ROUTER HELPERS

multi web-socket(&handler, :$cbor!) is export {
    web-socket(&handler, :body-parsers(WebSocket::BodyParser),
                         :body-serializers(WebSocket::BodySerializer))
}


### WEBSOCKET CLIENT

class WebSocket::Client is Cro::WebSocket::Client {
    multi method new(:$cbor!, :$uri, :@headers) {
        self.new(:$uri, :@headers, :body-parsers(WebSocket::BodyParser),
                                   :body-serializers(WebSocket::BodySerializer))
    }
}


=begin pod

=head1 NAME

Cro::CBOR - Support CBOR in Cro for body parsing/serializing


=head1 SYNOPSIS

=begin code :lang<raku>

use Cro::CBOR;

=end code


=head1 DESCRIPTION

Cro::CBOR is a set of extensions to C<Cro::HTTP> and C<Cro::WebSocket> to
support using CBOR alongside JSON as a standard body serialization format.


=head1 AUTHOR

Geoffrey Broadwell <gjb@sonic.net>


=head1 COPYRIGHT AND LICENSE

Copyright 2021 Geoffrey Broadwell

This library is free software; you can redistribute it and/or modify it under
the Artistic License 2.0.

=end pod
