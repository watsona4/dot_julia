using Readables, Test

# using the default settings
setreadables!()

@test readablestring(0) == "0"
@test readablestring(12) == "12"
@test readablestring(123) == "123"
@test readablestring(1234) == "1,234"
@test readablestring(12345) == "12,345"
@test readablestring(123456) == "123,456"
@test readablestring(1234567) == "1,234,567"

@test readablestring(0.0) == "0.0"
@test readablestring(12.0) == "12.0"
@test readablestring(123.0) == "123.0"
@test readablestring(1234.0) == "1,234.0"
@test readablestring(12345.0) == "12,345.0"
@test readablestring(123456.0) == "123,456.0"
@test readablestring(1234567.0) == "1.23456_7e+6"

@test readablestring(0.12345) == "0.12345"
@test readablestring(12.12345) == "12.12345"
@test readablestring(123.12345) == "123.12345"
@test readablestring(1234.12345) == "1,234.12345"
@test readablestring(12345.12345) == "12,345.12345"
@test readablestring(123456.12345) == "123,456.12345"
@test readablestring(1234567.12345) == "1.23456_71234_5e+6"

@test readablestring(0.12345678) == "0.12345_678"
@test readablestring(12.12345678) == "12.12345_678"
@test readablestring(123.12345678) == "123.12345_678"
@test readablestring(1234.12345678) == "1,234.12345_678"
@test readablestring(12345.12345678) == "12,345.12345_678"
@test readablestring(123456.12345678) == "123,456.12345_678"

@test readablestring(1234567.12325675) == "1.23456_71232_5675e+6"
@test readablestring(BigFloat("1234567.12325675")) == "1.23456_71232_5675e+06"

