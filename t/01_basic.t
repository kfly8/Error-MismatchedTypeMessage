use Test::More;

use Error::MismatchedTypeMessage qw(
    build_message
);

use Types::Standard -types;

subtest 'Str type' => sub {

    my $message = build_message(
        type     => Str,
        typename => 'Str',
        template => '$q->hello(%s)',
        usage => <<'...',
hello(Str $message)
...
    );

    # note $message->(123);
    # note $message->({});
    note $message->({key => 1});
    # note $message->([]);
    # note $message->([123]);
    # note $message->([123,456]);
    pass;
};

subtest 'Dict type' => sub {

    my $Params = Dict[
        name => Str,
        age => Int,
    ];

    my $message = build_message(
        type     => $Params,
        typename => 'Params',
        template => '$q->hello(%s)',
        usage => <<'...',
hello({
  name => Str,
  age => Int,
})
...
    );

    #note $message->(123);
    #    note $message->({ name => {}, age => 'boo' });
    note $message->({ nmae => 'hello', age => 'aaa' });
    #     note $message->([123]);
    #     note $message->([123,456]);
    #     note $message->(\1);
    #     note $message->(sub { });
    #     note $message->(qr{aa});
    #
    #note $message->({ name => 'foo', age => 'hello' });

    # $q->hello({ age => 'hello', ... });
    #                    ^^^^^^^ expected Int, got `hello`

    # tempalte: $q->hello({ age => %s, ... });
    # type: Int
    # typename: Int
    #
    # value->{hello}

    pass;
};

done_testing;
