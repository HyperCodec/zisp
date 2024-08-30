pub fn c_isnumeric(char: u8) bool {
    return char >= '0' and char <= '9';
}

pub fn s_isnumeric(str: []u8) bool {
    for(str) |c| {
        if(!c_isnumeric(c)) {
            return false;
        }
    }

    return true;
}

pub fn c_iswhitespace(char: u8) bool {
    return char == ' ' or char == '\n' or char == '\t' or char == '\r';
}

pub fn s_iswhitespace(str: []u8) bool {
    for(str) |c| {
        if(!c_iswhitespace(c)) {
            return false;
        }
    }

    return true;
}

const testing = @import("std").testing;
test "is numeric" {
    try testing.expect(c_isnumeric(' ') == false);
    try testing.expect(c_isnumeric('4') == true);
}

test "is whitespace" {
    try testing.expect(c_iswhitespace(' ') == true);
    try testing.expect(c_iswhitespace('b') == false);
}