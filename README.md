# NAME

Net::Cisco::FMC::v1 - Cisco Firepower Management Center (FMC) API version 1 client library

# VERSION

version 0.007000

# SYNOPSIS

```perl
use strict;
use warnings;
use Net::Cisco::FMC::v1;
use Data::Dumper::Concise;

my $fmc = Net::Cisco::FMC::v1->new(
    server      => 'https://fmcrestapisandbox.cisco.com',
    user        => 'admin',
    passwd      => '$password',
    clientattrs => { timeout => 30 },
);

# login to populate domains
$fmc->login;

# list all domain uuids and names
print Dumper($fmc->domains);
# switch domain
$fmc->domain_uuid("e276abec-e0f2-11e3-8169-6d9ed49b625f");
```

# DESCRIPTION

This module is a client library for the Cisco Firepower Management
Center (FMC) REST API version 1.
Currently it is developed and tested against FMC version 6.2.3.6.

# ATTRIBUTES

## domains

Returns a list of hashrefs containing name and uuid of all domains which gets
populated by ["login"](#login).

## domain\_uuid

The UUID of the domain which is used by all methods.

# METHODS

## login

Logs into the FMC by fetching an authentication token via http basic
authentication.

## relogin

Refreshes the session by loging in again (not using the refresh token) and
restores the currently set domain\_uuid.

## logout

Logs out of the FMC.

## create\_accessrule

Takes an access policy id, a hashref of the rule which should be created and
optional query parameters.

## list\_accessrules

Takes an access policy id and query parameters and returns a hashref with a
single key 'items' that has a list of access rules similar to the FMC API.

## get\_accessrule

Takes an access policy id, rule id and query parameters and returns the access
rule.

## update\_accessrule

Takes an access policy id, rule object and a hashref of the rule and returns
a hashref of the updated access rule.

## delete\_accessrule

Takes an access policy id and a rule object id.

Returns true on success.

## list\_deployabledevices

Takes optional query parameters and returns a hashref with a
single key 'items' that has a list of deployable devices similar to the FMC
API.

## create\_deploymentrequest

Takes a hashref of deployment parameters.

Returns the created task in the ->{metadata}->{task} hashref.

## get\_task

Takes a task id and returns its status.

## wait\_for\_task

Takes a task id and an optional callback and checks its status every second
until it isn't in-progress any more.
The in-progress status is different for each task type, currently only
'DEVICE\_DEPLOYMENT' is supported.
The callback coderef which is called for every check with the task as argument.

Returns the task.

## cleanup\_protocolport

Takes a ProtocolPortObject and renames it to protocol\_port, e.g. tcp\_443.
If it has no port 'any' is used instead of the port number no avoid
'predefined name' errors.
Returns the ProtocolPortObject with the updated attributes.

## cleanup\_icmpv4object

Takes a ICMPv4Object and renames it to protocol\_type\[\_code\], e.g. icmp\_8\_0.
If it has no code only protocol and type is used.

## cleanup\_hosts

- removes '\_Mask32' from the name
- removes the description if it is 'Created during ASA Migration'

## create\_cleaned\_accesspolicy

Takes an access policy name and a hashref of optional arguments.

### Optional arguments

- target\_access\_policy\_name

    Defaults to access policy name with the postfix '-cleaned'.

- rule\_name\_coderef

    Gets passed the rule number and rule object and must return the new rule name.

Creates a new access policy with the target name containing all rules of the
input access policy but cleaned by the following rules:

- the commentHistoryList is omitted
- replace autogenerated DM\_INLINE\_ NetworkGroups by their content

    Only if they don't contain more than 50 items because of the current limit in
    FMC.

- replace autogenerated DM\_INLINE\_ PortObjectGroups by their content
- optional: the rule name is generated

    By passing a coderef named 'rule\_name\_coderef' in the optional arguments
    hashref.

The new access policy is created with a defaultAction of:

```perl
action          => 'BLOCK'
logBegin        => true
sendEventsToFMC => true
```

This is mainly for access policies migrated by the Cisco Firepower Migration
Tool from a Cisco ASA.

Supports resuming.

# KNOWN BUGS

Older FMC versions have bugs like:

- truncated JSON responses

    No workaround on client side possible, only a FMC update helps.

- no response to the 11th call (version 6.2.2.1)

    No workaround on client side because newer FMC versions (at least 6.2.3.6)
    throttle the login call too.

- accessrule is created but error 'You do not have the required
authorization to do this operation' is thrown (version 6.2.2)

    No workaround on client side possible, only a FMC update helps.

# AUTHOR

Alexander Hartmaier <abraxxa@cpan.org>

# COPYRIGHT AND LICENSE

This software is copyright (c) 2018 - 2023 by Alexander Hartmaier.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.
