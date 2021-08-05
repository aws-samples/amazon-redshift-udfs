/* UDF: f_format_number.sql

Purpose: Provides a simple, non-locale aware way to format a number with user defined  thousands and decimal separator.

Internal dependencies: math.modf, collections.deque

External dependencies: None

2015-11-9: written by sdia

*/


CREATE OR REPLACE FUNCTION f_format_number(value FLOAT, group_sep VARCHAR, decimal_sep VARCHAR,
       group_length INT, prec INT, sign BOOL)

RETURNS VARCHAR IMMUTABLE
AS $$
    from collections import deque
    from math import modf

    def int_grouper_as_string(int_value, group_sep, group_length):
        d = deque(str(int(int_value)))
        grouped = []
        c = 0
        while True:
            try:
                x = d.pop()
            except IndexError:
                break
            if c and not c % group_length:
                grouped.append(group_sep)
            c += 1
            grouped.append(x)
        grouped.reverse()
        return ''.join(grouped)


    def get_decimal_as_string(fract_value, precision):
        if precision > 0:
            prec_string = '{{0:.{precision}f}}'.format(precision=precision)
            fract_string = prec_string.format(fract_value)
            return fract_string.split('.')[-1]
        else:
            return ''


    def f_format_number(value, group_sep=',', decimal_sep='.', group_length=3,
                        precision=2, sign=False):
        if value is None:
            return None
        try:
            value_float = float(value)
        except ValueError, e:
            print('A problem occured with formatting, numeric value was expected.')
            raise(e)
        try:
            assert decimal_sep != group_sep
        except AssertionError, e:
            print('A problem occured with formatting, group and decimal separators should not be equal!')
            raise(e)

        if value < 0:
            sign_symbol = '-'
        elif sign:
            sign_symbol = '+'
        else:
            sign_symbol = ''

        fract_part, int_part = modf(abs(value_float))
        int_group = int_grouper_as_string(int_part, group_sep, group_length)
        dec = get_decimal_as_string(fract_part, prec)

        res = sign_symbol+int_group

        if dec != '':
            res += decimal_sep+dec

        return res


    return f_format_number(value, group_sep, decimal_sep, group_length,
    	   prec, sign)

$$ LANGUAGE plpythonu;
