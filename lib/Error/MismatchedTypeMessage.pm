package Error::MismatchedTypeMessage;
use strict;
use warnings;

use Exporter 'import';
use Carp qw(croak);

our @EXPORT_OK = qw(
    build_message_maker
);

our $VERSION = "0.01";

# Create a message maker which is used to generate error message
#
# Example:
#   my $message_maker = build_message_maker(
#       typename => 'Str',
#       type     => Types::Standard::Str,
#       template => 'hello(%s)',
#       usage    => 'hello(Str $message)',
#   );
#
#   my $message = $message_maker->({});
#   # =>
#   # error: mismatched type
#   #
#   #   hello({})
#   #        ^^^ expected `Str`, but got HASH reference
#   # usage:
#   #   hello(Str $message)
sub build_message_maker {
    my (%args) = @_;

    # TODO: Validate arguments
    my $type     = $args{type};
    my $typename = $args{typename};
    my $template = $args{template};
    my $usage    = $args{usage};

    my $indent = " " x 2;

    my $find_reason = _build_error_reason_finder($type, $typename, $template);

    if ($usage) {
        $usage =~ s/^(.+)/${indent}${indent}$1/mg;
        $usage = "${indent}Usage:\n$usage";
    }

    return sub {
        my $value = shift;

        my $reason = $find_reason->($value);
        return unless $reason;

        my $message = "error: mismatched type";

        $reason =~ s/^(.+)/${indent}$1/mg;
        $message .= "\n\n$reason";
        $message .= "\n\n$usage" if $usage;

        return $message;
    };
}

sub _build_error_reason_finder {
    my ($type, $typename, $template) = @_;

    return $type->is_a_type_of('Value') ? _build_error_reason_finder_for_value($type, $typename, $template)
         : $type->is_a_type_of('Dict')  ? _build_error_reason_finder_for_dict($type, $typename, $template)
         : croak "unsupported type: $type";
}

# case:
#   $q->hello([123])
#             ^^^^^ expected `Str`, but got ARRAY reference
sub _build_error_reason_finder_for_value {
    my ($type, $typename, $template) = @_;

    my $message = _error_message_maker_case_expected($typename, $template);
    return sub {
        my $value = shift;
        return if $type->check($value);
        return $message->($value);
    }
}

# cases:
#   $q->hello(123)
#             ^^^ expected `Params`, but got `123`

#   $q->hello({...})
#             ^^^^^ missing `name` and `age` in `Params`

#   $q->hello({ foo => ... })
#               ^^^ unknown field `foo` in `Params`

#   $q->hello({ age => 'hello', ... })
#                      ^^^^^^^ expected Int, got `hello`

# TODO Slurpy, Option support

sub _build_error_reason_finder_for_dict {
    my ($type, $typename, $template) = @_;

    my $message_not_hashref = _error_message_maker_case_expected($typename, $template);

    my $dict = { @{ $type->parameters } };
    my $keys = [ sort keys %$dict ];

    my $suffix = @$keys > 1 ? ', ...' : '';

    my $key_to_find_reason = {
        map {
            my $key = $_;
            my $tmpl = sprintf($template, "{ '$key' => %s$suffix }");
            $key => _build_error_reason_finder($dict->{$key}, $dict->{$key}, $tmpl)
        } @$keys
    };

    return sub {
        my $value = shift;

        my $ref = ref $value || '';
        if ($ref ne 'HASH') {
            return $message_not_hashref->($value);
        }

        my $mismatch = [];
        my $missing = [];
        for my $key (@$keys) {
            if (exists $value->{$key}) {
                my $v = $value->{$key};
                my $t = $dict->{$key};
                next if $t->check($v);

                my $find_reason = $key_to_find_reason->{$key};
                push @$mismatch => $find_reason->($v);
            }
            else {
                push @$missing => $key;
            }
        }

        my $reasons = [];

        # First, push missing fields
        if (@$missing) {
            push @$reasons => _error_message_maker(sub {
                return "missing `@{[join '` and `', @$missing]}` in $typename";
            }, $template)->($value);
        }

        # Second, push unknown fields
        my @unknown = grep { !exists $dict->{$_} } keys %$value;
        for my $key (@unknown) {
            my $tmpl = sprintf($template, "{ %s => ... }");
            push @$reasons => _error_message_maker(sub {
                return "unknown field `$key` in $typename";
            }, $tmpl)->($key);
        }

        # Last, push mismatched fields
        push @$reasons => @$mismatch;

        return join "\n\n", @$reasons;
    }
}

sub _error_message_maker {
    my ($message_generator, $template) = @_;

    my $pos = index($template, '%s');
    if ($pos == -1) {
        croak "template must contain '%s' placeholder: $template";
    }
    my $indent = " " x $pos;

    return sub {
        my $value = shift;

        my $param = _dd_for_template($value);
        my $code = sprintf($template, $param);

        my $hat = '^' x length($param);

        my $msg = $message_generator->($value);
        return "$code\n$indent$hat $msg";
    }
}

sub _error_message_maker_case_expected {
    my ($typename, $template) = @_;

    _error_message_maker(sub {
        my $value = shift;

        my $ref = ref $value || '';
        my $got = $ref ? "$ref reference" : "`@{[_dd($value)]}`";
        return "expected `$typename`, but got $got";
    }, $template);
}

sub _dd {
    my $value = shift;

    require Data::Dumper;
    no warnings qw(once);
    local $Data::Dumper::Indent   = 0;
    local $Data::Dumper::Terse    = 1;
    local $Data::Dumper::Sortkeys = 1;
    local $Data::Dumper::Maxdepth = 2;

    Data::Dumper::Dumper($value);
}

sub _dd_for_template {
    my $value = shift;

    my $ref = ref $value || '';
    if ($ref eq 'ARRAY') {
        if (@$value == 0) {
            return '[]';
        }
        elsif (@$value == 1) {
            return sprintf('[%s]', _dd_for_template($value->[0]));
        }
        else {
            return sprintf('[%s,...]', _dd_for_template($value->[0]));
        }
    }
    elsif ($ref eq 'HASH') {
        my @keys = keys %$value;
        if (@keys) {
            return "{...}";
        }
        else {
            return '{}';
        }
    }
    else {
        return _dd($value);
    }
}

1;
__END__

=encoding utf-8

=head1 NAME

Error::MismatchedTypeMessage - It's new $module

=head1 SYNOPSIS

    use Error::MismatchedTypeMessage qw(build_message_maker);

    my $message_maker = build_message_maker(
        typename => 'Str',
        type     => Types::Standard::Str,
        template => 'hello(%s)',
        usage    => 'hello(Str $message)',
    );

    my $message = $message_maker->({});
    # =>
    # error: mismatched type
    #
    #   hello({})
    #        ^^^ expected `Str`, but got HASH reference
    # usage:
    #   hello(Str $message)


=head1 DESCRIPTION

Error::MismatchedTypeMessage is ...

=head1 LICENSE

Copyright (C) kobaken.

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself.

=head1 AUTHOR

kobaken E<lt>kentafly88@gmail.comE<gt>

=cut

