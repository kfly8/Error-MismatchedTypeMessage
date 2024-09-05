use Test2::V0;
use Test2::Require::Module 'Type::Tiny', '2.000000';

use lib "t/lib";
use t::test;

use Type::Tiny;
use Types::Standard -types;

# Given `Str` type, run tests
run_str_tests(Str);
run_str_tests(Type::Tiny->new(name => 'MyStr', parent => Str));

# Given `Dict` type, run tests
run_dict_tests(Dict[name => Str,age => Int]);
# TODO
# run_dict_tests(Type::Tiny->new(name => 'MyDict', parent => Dict[name => Str,age => Int]));

done_testing;
