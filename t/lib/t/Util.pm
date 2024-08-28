package t::Util;
use strict;
use warnings;

use Exporter 'import';

our @EXPORT = qw(
    run_tests
    run_str_tests
);

use Error::MismatchedTypeMessage qw( build_message );

use Test2::Tools::Basic qw(ok note);
use Test2::API qw(context);
use Text::Diff qw(diff);

sub run_tests {
    my ($message, @tests) = @_;

    my $c = context;

    for my $t (@tests) {
         my $case     = $t->{case};
         my $got      = $message->($t->{argument});
         my $expected = $t->{expected};
         chomp($expected) if defined $expected;

         my $ret = defined $expected ? ok($got eq $expected, $case) : ok(!defined $got, $case);
         if (!$ret && $expected) {
             note "Diff between got and expected:";
             note diff \$got, \$expected;
         }
     }

     $c->release;
}

sub run_str_tests {
    my $type = shift;

    my $message = build_message(
        type     => $type,
        typename => 'Str',
        template => '$obj->hello(%s)',
        usage    => 'hello(Str $message)'
    );

    my @tests = (
        {
            case     => 'Simple string',
            argument => 'hello',
            expected => undef,
        },
        {
            case     => 'Empty string',
            argument => '',
            expected => undef,
        },
        {
            case     => 'Number',
            argument => 123,
            expected => undef,
        },
        {
            case     => 'Empty hash reference',
            argument => {},
            expected => <<'...',
error: mismatched type

  $obj->hello({})
              ^^ expected `Str`, but got HASH reference

  Usage:
    hello(Str $message)
...
        },
        {
            case => 'Hash reference',
            argument => { key => 'value' },
            expected => <<'...',
error: mismatched type

  $obj->hello({...})
              ^^^^^ expected `Str`, but got HASH reference

  Usage:
    hello(Str $message)
...
        },
        {
            case => 'Empty array reference',
            argument => [],
            expected => <<'...',
error: mismatched type

  $obj->hello([])
              ^^ expected `Str`, but got ARRAY reference

  Usage:
    hello(Str $message)
...
        },
        {
            case => 'Simple array reference',
            argument => [123],
            expected => <<'...',
error: mismatched type

  $obj->hello([123])
              ^^^^^ expected `Str`, but got ARRAY reference

  Usage:
    hello(Str $message)
...
        },
        {
            case => 'Array reference',
            argument => [123,456],
            expected => <<'...',
error: mismatched type

  $obj->hello([123,...])
              ^^^^^^^^^ expected `Str`, but got ARRAY reference

  Usage:
    hello(Str $message)
...
        },
    );

    run_tests($message, @tests);
}

1;
