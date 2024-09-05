package t::test;
use strict;
use warnings;

use Exporter 'import';

our @EXPORT = qw(
    run_str_tests
    run_dict_tests
);

use Error::MismatchedTypeMessage qw( build_message );

use Test2::V0;
use Text::Diff qw(diff);

# Given `Str` type, run tests
#
# @param $type : Str
sub run_str_tests {
    my $type = shift;

    my @cases = (
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
    ); # end of cases

    my $message = build_message(
        typename => 'Str',
        type     => $type,
        template => '$obj->hello(%s)',
        usage    => <<'...'
hello(Str $message)
...
    );

    _run_tests(
        "Run `Str` tests with `$type` (@{[ref $type]})",
        $message,
        @cases
    );
}

# Given `Dict` type, run tests
#
# @param $type : Dict[name => Str, age => Int]
sub run_dict_tests {
    my $type = shift;

    my @cases = (
        {
            case     => 'Valid Params',
            argument => { name => 'foo', age => 123 },
            expected => undef,
        },
        {
            case     => 'Simple string',
            argument => 'hello',
            expected => <<'...',
error: mismatched type

  $obj->hello('hello')
              ^^^^^^^ expected `Params`, but got `'hello'`

  Usage:
    hello({
      name => Str,
      age => Int,
    })
...
        },
        {
            case     => 'Invalid name',
            argument => { name => {}, age => 123 },
            expected => <<'...',
error: mismatched type

  $obj->hello({ 'name' => {}, ... })
                          ^^ expected `Str`, but got HASH reference

  Usage:
    hello({
      name => Str,
      age => Int,
    })
...
        },
        {
            case     => 'Invalid age',
            argument => { name => 'foo', age => 'hello' },
            expected => <<'...',
error: mismatched type

  $obj->hello({ 'age' => 'hello', ... })
                         ^^^^^^^ expected `Int`, but got `'hello'`

  Usage:
    hello({
      name => Str,
      age => Int,
    })
...
        },
        {
            case => 'Missing `name`',
            argument => { age => 123 },
            expected => <<'...',
error: mismatched type

  $obj->hello({...})
              ^^^^^ missing `name` in Params

  Usage:
    hello({
      name => Str,
      age => Int,
    })
...
        },
        {
            case => 'Missing `name` and `age`',
            argument => {  },
            expected => <<'...',
error: mismatched type

  $obj->hello({})
              ^^ missing `age` and `name` in Params

  Usage:
    hello({
      name => Str,
      age => Int,
    })
...
        },
        {
            case => 'Typo key',
            argument => { nmae => 'foo', age => 123 },
            expected => <<'...',
error: mismatched type

  $obj->hello({...})
              ^^^^^ missing `name` in Params

  $obj->hello({ 'nmae' => ... })
                ^^^^^^ unknown field `nmae` in Params

  Usage:
    hello({
      name => Str,
      age => Int,
    })
...
        },

    ); # end of cases

    my $message = build_message(
        type     => $type,
        typename => 'Params',
        template => '$obj->hello(%s)',
        usage => <<'...',
hello({
  name => Str,
  age => Int,
})
...
    );

    _run_tests(
        "Run `Dict` tests with `$type` (@{[ref $type]})",
        $message,
        @cases
    );
}

sub _run_tests {
    my ($note, $message, @tests) = @_;

    subtest $note => sub {
        for my $t (@tests) {
             my $case     = $t->{case};
             my $got      = $message->($t->{argument});
             my $expected = $t->{expected};

             my $ret = defined $expected ? ok($got eq $expected, $case) : ok(!defined $got, $case);
             if (!$ret && $expected) {
                 note "Diff between got and expected:";
                 note diff \$got, \$expected;
             }
         }
     };
}

1;
