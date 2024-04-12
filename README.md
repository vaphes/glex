# glex

[![Package Version](https://img.shields.io/hexpm/v/glex)](https://hex.pm/packages/glex)
[![Hex Docs](https://img.shields.io/badge/hex-docs-ffaff3)](https://hexdocs.pm/glex/)

```sh
gleam add glex
```

```gleam
import gleam/io
import gleam/list
import gleam/string
import glex

pub fn main() {
  // Making a lexer for a simple rung of ladder logic

  let file_type = "([A-Za-z]){1,2}"
  let file_number = "([2-9]?[0-5]?[0-5]?)?"
  let element_delimiter = "(:|/)"
  let element_number = "(\\d{1,4}|[A-Za-z]{1,4})"
  let word_delimiter = "([.|/])?"
  let word_number = "(\\d{1,4}|[A-Za-z]{1,4})?"
  let bit_delimiter = "(/)?"
  let bit_number = "(\\d{1,4}|[A-Za-z]{1,4})?"

  let address =
    string.concat([
      file_type,
      file_number,
      element_delimiter,
      element_number,
      word_delimiter,
      word_number,
      bit_delimiter,
      bit_number,
    ])

  let rung = "SOR XIC T4:0.1/DN OTE B3/0 EOR"

  let tokens =
    glex.new()
    |> glex.add_rule("SOR", "SOR")
    |> glex.add_rule("EOR", "EOR")
    |> glex.add_rule("XIC", "XIC")
    |> glex.add_rule("OTE", "OTE")
    |> glex.add_rule("ADDRESS", address)
    |> glex.add_ignore("whitespace", "\\s+")
    |> glex.build(rung)
    |> glex.lex()

  tokens
  |> list.each(io.debug)
  // #(Valid("SOR", "SOR"), Position(0))
  // #(Ignored("whitespace", " "), Position(3))
  // #(Valid("XIC", "XIC"), Position(4))
  // #(Ignored("whitespace", " "), Position(7))
  // #(Valid("ADDRESS", "T4:0.1/DN"), Position(8))
  // #(Ignored("whitespace", " "), Position(17))
  // #(Valid("OTE", "OTE"), Position(18))
  // #(Ignored("whitespace", " "), Position(21))
  // #(Valid("ADDRESS", "B3/0"), Position(22))
  // #(Ignored("whitespace", " "), Position(26))
  // #(Valid("EOR", "EOR"), Position(27))

  tokens
  |> glex.ok()
  |> io.debug
  // True

  tokens
  |> glex.valid_only()
  |> list.each(io.debug)
  // #(Valid("SOR", "SOR"), Position(0))
  // #(Valid("XIC", "XIC"), Position(4))
  // #(Valid("ADDRESS", "T4:0.1/DN"), Position(8))
  // #(Valid("OTE", "OTE"), Position(18))
  // #(Valid("ADDRESS", "B3/0"), Position(22))
  // #(Valid("EOR", "EOR"), Position(27))
}
```

Further documentation can be found at <https://hexdocs.pm/glex>.

## Development

```sh
gleam run   # Run the project
gleam test  # Run the tests
gleam shell # Run an Erlang shell
```
