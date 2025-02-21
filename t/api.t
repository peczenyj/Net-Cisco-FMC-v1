use Test2::V0;
use Test2::Tools::Compare qw( array hash D );
use Net::Cisco::FMC::v1;
use JSON qw();

skip_all "environment variables not set"
    unless exists $ENV{NET_CISCO_FMC_V1_HOSTNAME}
        && exists $ENV{NET_CISCO_FMC_V1_USERNAME}
        && exists $ENV{NET_CISCO_FMC_V1_PASSWORD}
        && exists $ENV{NET_CISCO_FMC_V1_POLICY};

my $fmc = Net::Cisco::FMC::v1->new(
    server      => 'https://' . $ENV{NET_CISCO_FMC_V1_HOSTNAME},
    user        => $ENV{NET_CISCO_FMC_V1_USERNAME},
    passwd      => $ENV{NET_CISCO_FMC_V1_PASSWORD},
    clientattrs => { timeout => 30 },
);

ok($fmc->login, 'login to FMC successful');

is($fmc->domains,
    array {
        etc();
    },
    'domains are populated');
is($fmc->domain_uuid, D(), 'domain_uuid is defined');
is($fmc->_refresh_token, D(), '_refresh_token is defined');

ok(lives { $fmc->logout }, 'logout of FMC successful')
    or note($@);

is($fmc->domains, U(), 'domains are cleared');
is($fmc->domain_uuid, U(), 'domain_uuid is cleared');
is($fmc->_refresh_token, U(), '_refresh_token is cleared');

# all currently supported API calls require domain_uuid which is cleared so
# we can't use any for a useful test

ok($fmc->login, 're-login to FMC successful');

ok(my $policy = $fmc->create_accesspolicy({
    name => $ENV{NET_CISCO_FMC_V1_POLICY},
    defaultAction => {
        action => 'BLOCK',
        logBegin => 1,
        sendEventsToFMC => 1,
    },
}), 'access policy created');

END {
    $fmc->delete_accesspolicy($policy->{id})
        if defined $policy;
    $fmc->logout
        if defined $fmc;
}

ok(my $accessrules = $fmc->list_accessrules($policy->{id}),
    'list accessrules successful');
is($accessrules->{items}, [], 'access policy has no rules');

ok(my $ipv4_literal_rule = $fmc->create_accessrule(
    $policy->{id},
    {
        name                => 'simple IPv4 literals rule',
        action              => 'ALLOW',
        enabled             => JSON->boolean(1),
        sourceNetworks      => {
            literals => [
                {
                    type => 'Network',
                    value => '10.0.0.0/24',
                },
            ],
        },
        destinationNetworks => {
            literals => [
                {
                    type => 'Host',
                    value => '10.0.0.10',
                },
                {
                    type => 'Host',
                    value => '10.0.0.11',
                },
            ],
        },
        destinationPorts    => {
            literals => [
                {
                    type     => 'PortLiteral',
                    protocol => '6',
                    port     => '53',
                },
                {
                    type     => 'PortLiteral',
                    protocol => '17',
                    port     => '53',
                },
            ],
        },
    },
), 'simple IPv4 literals rule created');
ok($accessrules = $fmc->list_accessrules($policy->{id}),
    'list accessrules successful');
is($accessrules,
    hash {
        field items => array {
            item hash {
                field id => D();
                field links => hash{
                    etc();
                };
                field name => 'simple IPv4 literals rule';
                field type => 'AccessRule';
                end();
            };
            end();
        };
        end();
    }, 'access policy has one rule');

ok(my $ipv6_literal_rule = $fmc->create_accessrule(
    $policy->{id},
    {
        name                => 'simple IPv6 literals rule',
        action              => 'ALLOW',
        enabled             => JSON->boolean(1),
        sourceNetworks      => {
            literals => [
                {
                    type => 'Network',
                    value => '2001:0db8::/56',
                },
            ],
        },
        destinationNetworks => {
            literals => [
                {
                    type => 'Host',
                    value => '2001:0db8::a',
                },
                {
                    type => 'Host',
                    value => '2001:0db8::b',
                },
            ],
        },
        destinationPorts    => {
            literals => [
                {
                    type     => 'PortLiteral',
                    protocol => '6',
                    port     => '53',
                },
                {
                    type     => 'PortLiteral',
                    protocol => '17',
                    port     => '53',
                },
            ],
        },
    },
), 'simple IPv6 literals rule created');
ok($accessrules = $fmc->list_accessrules($policy->{id}),
    'list accessrules successful');
is($accessrules,
    hash {
        field items => array {
            item hash {
                field id => D();
                field links => hash{
                    etc();
                };
                field name => 'simple IPv4 literals rule';
                field type => 'AccessRule';
                end();
            };
            item hash {
                field id => D();
                field links => hash{
                    etc();
                };
                field name => 'simple IPv6 literals rule';
                field type => 'AccessRule';
                end();
            };
            end();
        };
        end();
    }, 'access policy has two rules');

ok($ipv4_literal_rule = $fmc->update_accessrule(
    $policy->{id},
    $ipv4_literal_rule,
    {
        urls => {
            urlCategoriesWithReputation => [
              {
                category => {
                    type => 'URLCategory',
                    name => 'Uncategorized',
                },
                type => 'UrlCategoryAndReputation',
              },
            ],
        },
    },
), 'URL categories added to simple IPv4 literals rule');

ok($ipv4_literal_rule = $fmc->update_accessrule(
    $policy->{id},
    $ipv4_literal_rule,
    {
        enabled => JSON->boolean(0),
    },
), 'simple IPv4 literals rule disabled');

ok($fmc->delete_accessrule(
    $policy->{id},
    $ipv4_literal_rule->{id}
), 'simple IPv4 literals rule deleted');

ok(my $identitypolicies = $fmc->list_identitypolicies, 'list identitypolicies successful');
ok($identitypolicies->{items}->@* > 0, 'identitypolicies has items');

ok(my $realms = $fmc->list_realms, 'list_realms successful');
ok($realms->{items}->@* > 0, 'realms has items');

ok(my $realmusers = $fmc->list_realmusers, 'list_realmusers successful');
ok($realmusers->{items}->@* > 0, 'realmusers has items');

ok(my $realmusergroups = $fmc->list_realmusergroups, 'list_realmusergroups successful');
ok($realmusergroups->{items}->@* > 0, 'realmusergroups has items');

ok(my $accesspolicies = $fmc->list_accesspolicies({ expanded => 'true' }), 'list_accesspolicies successful');
ok($accesspolicies->{items}->@* > 0, 'accesspolicies has items');

# we need to use an existing access policy which has an identity policy
# assigned, because there is no way to create an access policy with an
# identity policy assigned at the moment
# see https://bst.cisco.com/quickview/bug/CSCvy88945
my ($identity_test_policy) = grep {
        $_->{name} =~ /^$ENV{NET_CISCO_FMC_V1_POLICY}/
        && exists $_->{identityPolicySetting}
    } $accesspolicies->{items}->@*;

SKIP: {
    skip "Skipping identity tests because no access policy found that starts with '$ENV{NET_CISCO_FMC_V1_POLICY}' and has an identity policy assigned"
        unless defined $identity_test_policy;

    diag "using access policy '$identity_test_policy->{name}' id '$identity_test_policy->{id}' for identity tests";

    # the 'Special Identities' realm contains some predefined users
    my ($test_realm) = grep { $_->{name} eq 'Special Identities' } $realms->{items}->@*;
    diag "using realm '$test_realm->{name}' id '$test_realm->{id}' for identity tests";

    ok(my $filtered_realmusers = $fmc->list_realmusers({ realm => $test_realm->{id}, expanded => 'true' }),
        'list_realmusers filtered by realm successful');

    my ($test_realmuser) = grep { $_->{name} eq 'Guest' } $filtered_realmusers->{items}->@*;
    ok(defined $test_realmuser, "'Guest' realm user found");

    ok(my $identity_rule = $fmc->create_accessrule(
        $identity_test_policy->{id},
        {
            name                => 'identity rule',
            action              => 'ALLOW',
            enabled             => JSON->boolean(1),
            users => {
                objects => [
                    {
                        %$test_realmuser{qw( id type name realm )}
                    },
                ],
            },
            destinationNetworks => {
                literals => [
                    {
                        type => 'Host',
                        value => '2001:0db8::a',
                    },
                    {
                        type => 'Host',
                        value => '2001:0db8::b',
                    },
                ],
            },
            destinationPorts    => {
                literals => [
                    {
                        type     => 'PortLiteral',
                        protocol => '6',
                        port     => '53',
                    },
                    {
                        type     => 'PortLiteral',
                        protocol => '17',
                        port     => '53',
                    },
                ],
            },
        },
    ), 'identity rule created');

    ok(my $updated_identity_rule = $fmc->update_accessrule(
        $identity_test_policy->{id},
        $identity_rule,
        {
            enabled => JSON->boolean(0),
        },
    ), 'update_accessrule ok');

    END {
        $fmc->delete_accessrule($identity_test_policy->{id}, $identity_rule->{id})
            if defined $identity_rule;
    }
}

done_testing;
