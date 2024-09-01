use Test2::V0;
use Test2::Require::Module 'Type::Tiny', '2.000000';

use lib "t/lib";
use t::Util;

use Types::Standard -types;

subtest 'Given `Str` type' => sub {
    run_str_tests(Str);
};

subtest 'Given `Dict` type' => sub {
    run_dict_tests(Dict[
        name => Str,
        age => Int,
    ]);
};

done_testing;
