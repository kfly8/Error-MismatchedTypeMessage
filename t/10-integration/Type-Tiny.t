use Test2::V0;
use Test2::Require::Module 'Type::Tiny', '2.000000';

use lib "t/lib";
use t::Util;

use Types::Standard -types;

subtest 'Given `Str` type' => sub {
    run_str_tests(Str);
};

# subtest 'Dict type' => sub {
#
#     my $Params = Dict[
#         name => Str,
#         age => Int,
#     ];
#
#     my $message = build_message(
#         type     => $Params,
#         typename => 'Params',
#         template => '$q->hello(%s)',
#         usage => <<'...',
# hello({
#   name => Str,
#   age => Int,
# })
# ...
#     );
#
#     #note $message->(123);
#     #    note $message->({ name => {}, age => 'boo' });
#     note $message->({ nmae => 'hello', age => 'aaa' });
#     #     note $message->([123]);
#     #     note $message->([123,456]);
#     #     note $message->(\1);
#     #     note $message->(sub { });
#     #     note $message->(qr{aa});
#     #
#     #note $message->({ name => 'foo', age => 'hello' });
#
#     # $q->hello({ age => 'hello', ... });
#     #                    ^^^^^^^ expected Int, got `hello`
#
#     # tempalte: $q->hello({ age => %s, ... });
#     # type: Int
#     # typename: Int
#     #
#     # value->{hello}
#
#     pass;
# };

done_testing;
