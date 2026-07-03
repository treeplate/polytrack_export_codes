// ported from https://docs.rs/polytrack-codes/latest/src/polytrack_codes/tools/mod.rs.html

// ignore_for_file: constant_identifier_names, non_constant_identifier_names

const List<String> ENCODE_VALUES = [
  'A',
  'B',
  'C',
  'D',
  'E',
  'F',
  'G',
  'H',
  'I',
  'J',
  'K',
  'L',
  'M',
  'N',
  'O',
  'P',
  'Q',
  'R',
  'S',
  'T',
  'U',
  'V',
  'W',
  'X',
  'Y',
  'Z',
  'a',
  'b',
  'c',
  'd',
  'e',
  'f',
  'g',
  'h',
  'i',
  'j',
  'k',
  'l',
  'm',
  'n',
  'o',
  'p',
  'q',
  'r',
  's',
  't',
  'u',
  'v',
  'w',
  'x',
  'y',
  'z',
  '0',
  '1',
  '2',
  '3',
  '4',
  '5',
  '6',
  '7',
  '8',
  '9',
];

const List<int> DECODE_VALUES = [
  -1,
  -1,
  -1,
  -1,
  -1,
  -1,
  -1,
  -1,
  -1,
  -1,
  -1,
  -1,
  -1,
  -1,
  -1,
  -1,
  -1,
  -1,
  -1,
  -1,
  -1,
  -1,
  -1,
  -1,
  -1,
  -1,
  -1,
  -1,
  -1,
  -1,
  -1,
  -1,
  -1,
  -1,
  -1,
  -1,
  -1,
  -1,
  -1,
  -1,
  -1,
  -1,
  -1,
  -1,
  -1,
  -1,
  -1,
  -1,
  52,
  53,
  54,
  55,
  56,
  57,
  58,
  59,
  60,
  61,
  -1,
  -1,
  -1,
  -1,
  -1,
  -1,
  -1,
  0,
  1,
  2,
  3,
  4,
  5,
  6,
  7,
  8,
  9,
  10,
  11,
  12,
  13,
  14,
  15,
  16,
  17,
  18,
  19,
  20,
  21,
  22,
  23,
  24,
  25,
  -1,
  -1,
  -1,
  -1,
  -1,
  -1,
  26,
  27,
  28,
  29,
  30,
  31,
  32,
  33,
  34,
  35,
  36,
  37,
  38,
  39,
  40,
  41,
  42,
  43,
  44,
  45,
  46,
  47,
  48,
  49,
  50,
  51,
];

/// Encode the given byte buffer into base62 encoded text according to Polytrack's base62 implementation.
/// Returns [`None`] if something failed in the process.
String? encode(List<int> input) {
  int bit_pos = 0;
  StringBuffer res = StringBuffer();

  while (bit_pos < 8 * input.length) {
    int char_value = encode_chars(input, bit_pos)!;
    // if char_num ends with 11110, shorten it to 5 bits
    // (getting rid of value 62 and 63, which are too big for base62)
    if ((char_value & 30) == 30) {
      char_value &= 31;
      bit_pos += 5;
    } else {
      bit_pos += 6;
    }
    res.write(ENCODE_VALUES[char_value]);
  }

  return res.toString();
}

/// Decode the given string as base62 text according to Polytrack's base62 implementation.
/// Returns [`None`] if any character isn't valid for base62 encoded text.
List<int>? decode(String input) {
  int out_pos = 0;
  List<int> bytes_out = [];
  int i = 0;
  for (int ch in input.runes) {
    int char_code = ch;
    int char_value = DECODE_VALUES[char_code];
    if (char_value == -1) {
      return null;
    }
    // 5 if char_value is 30 or 31, 6 otherwise (see encode for explanation)
    int value_len = (char_value & 30) == 30 ? 5 : 6;
    decode_chars(
      bytes_out,
      out_pos,
      value_len,
      char_value,
      i == input.length - 1,
    );
    out_pos += value_len;
    i++;
  }

  return bytes_out;
}

int? encode_chars(List<int> bytes, int bit_index) {
  if (bit_index >= 8 * bytes.length) {
    return null;
  }

  int byte_index = bit_index ~/ 8;
  int current_byte = bytes[byte_index];
  int offset = bit_index - 8 * byte_index;
  if (offset <= 2 || byte_index >= bytes.length - 1) {
    // move mask into right position, get only offset bits of current_byte, move back
    return (current_byte & (63 << offset)) >> offset;
  } else {
    int next_byte = bytes[byte_index + 1];
    // same concept as above, move mask into right position,
    // get correct bits of current and next byte, move back, combine the two
    return ((current_byte & (63 << offset)) >> offset) |
        ((next_byte & (63 >> (8 - offset))) << (8 - offset));
  }
}

void decode_chars(
  List<int> bytes,
  int bit_index,
  int value_len,
  int char_value,
  bool is_last,
) {
  int byte_index = bit_index ~/ 8;
  while (byte_index >= bytes.length) {
    bytes.add(0);
  }

  // offset in current byte
  int offset = bit_index - 8 * byte_index;

  // writes value into byte (only part that fits)
  bytes[byte_index] |= ((char_value << offset) & 0xFF);

  // in case of value going into next byte add that part
  if (offset > 8 - value_len && !is_last) {
    int byte_index_next = byte_index + 1;
    if (byte_index_next >= bytes.length) {
      bytes.add(0);
    }

    // write rest of value into next byte
    bytes[byte_index_next] |= (char_value >> (8 - offset));
  }
}
