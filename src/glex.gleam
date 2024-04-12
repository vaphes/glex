import gleam/string
import gleam/list
import gleam/bit_array
import gleam/regex.{type Options, type Regex, Options}
import gleam/iterator.{type Iterator}

pub type Token {
  Valid(name: String, value: String)
  Ignored(name: String, value: String)
  Invalid(value: String)
  EndOfFile
}

pub type Position {
  Position(Int)
}

pub opaque type Rule {
  Rule(name: String, pattern: String, regex: Regex)
}

pub fn new_rule(name: String, pattern: String) -> Rule {
  let options = Options(case_insensitive: False, multi_line: False)
  let pattern = case pattern {
    "^" <> _rest -> pattern
    _ -> "^" <> pattern
  }
  let assert Ok(regex) = regex.compile(pattern, options)
  Rule(name, pattern, regex)
}

pub opaque type Lexer {
  Lexer(rules: List(Rule), ignore: List(Rule), source: String, position: Int)
}

pub fn new() -> Lexer {
  Lexer([], [], "", 0)
}

pub fn add_rule(lexer: Lexer, name: String, pattern: String) -> Lexer {
  let rule = new_rule(name, pattern)
  Lexer(
    list.concat([lexer.rules, [rule]]),
    lexer.ignore,
    lexer.source,
    lexer.position,
  )
}

pub fn add_ignore(lexer: Lexer, name: String, pattern: String) -> Lexer {
  let rule = new_rule(name, pattern)
  Lexer(
    lexer.rules,
    list.concat([lexer.ignore, [rule]]),
    lexer.source,
    lexer.position,
  )
}

pub fn build(lexer: Lexer, source: String) -> Lexer {
  Lexer(lexer.rules, lexer.ignore, source, 0)
}

pub fn lex(lexer: Lexer) -> List(#(Token, Position)) {
  iterator(lexer)
  |> iterator.to_list()
}

pub fn iterator(lexer: Lexer) -> Iterator(#(Token, Position)) {
  use lexer <- iterator.unfold(from: lexer)

  case next(lexer) {
    #(_lexer, #(EndOfFile, _position)) -> iterator.Done
    #(lexer, wraped_token) ->
      iterator.Next(element: wraped_token, accumulator: lexer)
  }
}

pub fn next(lexer: Lexer) -> #(Lexer, #(Token, Position)) {
  let ignore = lex_rules(lexer.ignore, lexer.source)
  case ignore {
    Ok(#(name, value)) -> {
      let rest =
        lexer.source
        |> string.drop_left(string.length(value))
      #(
        advance(lexer, rest, string.length(value)),
        wrap_token(lexer, Ignored(name, value)),
      )
    }
    Error(Nil) -> {
      let rules = lex_rules(lexer.rules, lexer.source)
      case rules {
        Ok(#(name, value)) -> {
          let rest =
            lexer.source
            |> string.drop_left(string.length(value))
          #(
            advance(lexer, rest, string.length(value)),
            wrap_token(lexer, Valid(name, value)),
          )
        }
        Error(Nil) -> {
          case string.pop_grapheme(lexer.source) {
            Error(Nil) -> #(lexer, #(EndOfFile, Position(lexer.position)))
            Ok(#(grapheme, rest)) -> {
              #(
                advance(lexer, rest, byte_size(grapheme)),
                wrap_token(lexer, Invalid(grapheme)),
              )
            }
          }
        }
      }
    }
  }
}

pub fn ok(tokens: List(#(Token, Position))) -> Bool {
  tokens
  |> list.all(fn(token) {
    case token {
      #(Invalid(_), _) -> False
      _ -> True
    }
  })
}

pub fn valid_only(tokens: List(#(Token, Position))) -> List(#(Token, Position)) {
  tokens
  |> list.filter(fn(token) {
    case token {
      #(Valid(_, _), _) -> True
      _ -> False
    }
  })
}

pub fn ignored_only(
  tokens: List(#(Token, Position)),
) -> List(#(Token, Position)) {
  tokens
  |> list.filter(fn(token) {
    case token {
      #(Ignored(_, _), _) -> True
      _ -> False
    }
  })
}

pub fn invalid_only(
  tokens: List(#(Token, Position)),
) -> List(#(Token, Position)) {
  tokens
  |> list.filter(fn(token) {
    case token {
      #(Invalid(_), _) -> True
      _ -> False
    }
  })
}

fn advance(lexer: Lexer, source: String, offset: Int) -> Lexer {
  Lexer(
    rules: lexer.rules,
    ignore: lexer.ignore,
    source: source,
    position: lexer.position + offset,
  )
}

fn wrap_token(lexer: Lexer, token: Token) -> #(Token, Position) {
  #(token, Position(lexer.position))
}

fn byte_size(string: String) -> Int {
  bit_array.byte_size(<<string:utf8>>)
}

fn lex_rules(
  rules: List(Rule),
  source: String,
) -> Result(#(String, String), Nil) {
  rules
  |> list.flat_map(fn(rule) {
    rule.regex
    |> regex.scan(source)
    |> list.map(fn(match) { #(rule.name, match.content) })
  })
  |> list.first()
}
