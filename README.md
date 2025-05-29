[![Actions Status](https://github.com/japhb/Cro-CBOR/actions/workflows/test.yml/badge.svg)](https://github.com/japhb/Cro-CBOR/actions)

NAME
====

Cro::CBOR - Support CBOR in Cro for body parsing/serializing

SYNOPSIS
========

```raku
use Cro::CBOR;

# SERVER SIDE
route {
    get -> 'cbor' {
        web-socket :cbor, -> $incoming {             # NOTE `:cbor`
            supply whenever $incoming -> $message {
                my $body = await $message.body;      # NOTE `$message.body` (not -text)
                ... "Generate $response here";
                emit $response;
            }
        }
    }
}

# CLIENT SIDE
my $client     = Cro::CBOR::WebSocket::Client.new(:cbor);
my $connection = await $client.connect: 'http://localhost:12345/cbor';
```

DESCRIPTION
===========

Cro::CBOR is a set of extensions to `Cro::HTTP` and `Cro::WebSocket` to support using CBOR alongside JSON as a standard body serialization format.

If you're already using Cro's automatic JSON serialization, CBOR serialization works very similarly. Replace `:json` with `:cbor`, and `Cro::WebSocket::Client` with `Cro::CBOR::WebSocket::Client`, and most pieces will Just Work. And if not, please file an issue in the [Cro::CBOR repository](https://github.com/japhb/Cro-CBOR/issues), and I'll happily take a look.

AUTHOR
======

Geoffrey Broadwell <gjb@sonic.net>

COPYRIGHT AND LICENSE
=====================

Copyright 2021 Geoffrey Broadwell

This library is free software; you can redistribute it and/or modify it under the Artistic License 2.0.

