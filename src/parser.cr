# coding: utf-8

require "./common"
require "./types"
require "./json"

class Global
  property tokens : Array(Token)
  property pos : Int32

  @@_instance = Global.new

  def initialize
    @tokens = [] of Token
    @pos = 0
  end

  def self.instance
    @@_instance
  end
end

def read_tokens : Array(Token)
  input = read_stdin_all()

  input.each_line
    .select { |line| line.starts_with?("[") }
    .map { |line| Token.from_json(line) }
    .to_a
end

def rest_head
  g = Global.instance
  g.tokens[g.pos ... g.pos + 8]
    .map { |t| format("%s<%s>", t.kind, t.value) }
end

def dump_state(msg = nil)
  g = Global.instance
  pp_e [msg, g.pos, rest_head]
end

def assert_value(pos, exp)
  g = Global.instance
  t = g.tokens[pos]

  if t.value != exp
    msg = format(
      "assertion failed: expected(%s) actual(%s)",
      exp.inspect,
      t.inspect
    )
    raise msg
  end
end

def end?
  g = Global.instance
  g.tokens.size <= g.pos
end

def peek(offset = 0)
  g = Global.instance
  g.tokens[g.pos + offset]
end

def inc_pos
  g = Global.instance
  g.pos += 1
end

def consume(str)
  g = Global.instance
  assert_value(g.pos, str)
  inc_pos()
end

# --------------------------------

def parse_arg : Node
    t = peek()

    case t.kind
    when :ident
      inc_pos()
      t.value
    when :int
      inc_pos()
      t.value_as_int
    else
      raise "unexpected kind"
    end
end

def parse_args : List
  args = List.new

  if peek().value == ")"
    return args
  end

  args << parse_arg()

  while peek().value == ","
    consume ","
    args << parse_arg()
  end

  args
end

def parse_func : Stmt
  consume "func"

  t = peek(); inc_pos()
  func_name = t.value

  consume "("
  args = parse_args()
  consume ")"

  consume "{"

  stmts = [] of Node
  while peek().value != "}"
    stmts <<
      if peek().value == "var"
        parse_var()
      else
        parse_stmt()
      end
  end
  consume "}"

  ["func", func_name, args, stmts] of Node
end

def parse_var_declare : Stmt
  t = peek(); inc_pos()
  var_name = t.value

  consume ";"

  ["var", var_name] of Node
end

def parse_var_init : Stmt
  t = peek(); inc_pos()
  var_name = t.value

  consume "="

  expr = parse_expr()

  consume ";"

  ["var", var_name, expr] of Node
end

def parse_var : Stmt
  consume "var"

  t = peek(1)

  case t.value
  when ";" then parse_var_declare()
  when "=" then parse_var_init()
  else
    raise "unexpected token"
  end
end

def binop?(t) : Bool
  ["+", "*", "==", "!="].includes?(t.value)
end

def _parse_expr_factor : Expr
  t_left = peek()

  case t_left.kind
  when :int
    inc_pos()
    t_left.value_as_int
  when :ident
    inc_pos()
    t_left.value
  when :sym
    consume "("
    expr = parse_expr()
    consume ")"
    expr
  else
    raise "unexpected kind"
  end
end

def parse_expr : Expr
  expr : Expr = _parse_expr_factor()

  while binop?(peek())
    op = peek().value
    inc_pos()

    factor : Node = _parse_expr_factor()

    new_expr = [] of Node
    new_expr << op
    new_expr << expr
    new_expr << factor

    expr = new_expr
  end

  expr
end

def parse_set : Stmt
  consume "set"

  t = peek(); inc_pos()
  var_name = t.value

  consume "="

  expr = parse_expr()

  consume ";"

  ["set", var_name, expr] of Node
end

def _parse_funcall : List
  t = peek(); inc_pos()
  fn_name = t.value

  consume "("
  args = parse_args()
  consume ")"

  funcall = List.new
  funcall << fn_name
  funcall += args

  funcall
end

def parse_call : Stmt
  consume "call"

  funcall = _parse_funcall()

  consume ";"

  ret = List.new
  ret << "call"
  ret += funcall
  ret
end

def parse_call_set : Stmt
  consume "call_set"

  t = peek(); inc_pos()
  var_name = t.value

  consume "="

  expr = _parse_funcall()

  consume ";"

  ["call_set", var_name, expr] of Node
end

def parse_return : Stmt
  consume "return"

  t = peek()

  if t.value == ";"
    consume ";"
    ["return"] of Node
  else
    expr = parse_expr()
    consume ";"
    ["return", expr] of Node
  end
end

def parse_while : Stmt
  consume "while"

  consume "("
  expr = parse_expr()
  consume ")"

  consume "{"
  stmts = parse_stmts()
  consume "}"

  ["while", expr, stmts] of Node
end

def parse_case : Stmt
  consume "case"

  consume "{"

  when_clauses = List.new

  while peek().value != "}"
    consume "("
    expr = parse_expr()
    consume ")"

    consume "{"
    stmts = parse_stmts()
    consume "}"

    expr_stmts = List.new
    expr_stmts << expr
    expr_stmts += stmts
    when_clauses << expr_stmts
  end

  consume "}"

  ret = List.new
  ret << "case"
  ret += when_clauses
  ret
end

def parse_vm_comment : Stmt
  consume "_cmt"
  consume "("

  t = peek(); inc_pos()
  comment = t.value

  consume ")"
  consume ";"

  ["_cmt", comment] of Node
end

def parse_debug : Stmt
  consume "_debug"
  consume "("
  consume ")"
  consume ";"

  ["_debug"] of Node
end

def parse_stmt : Stmt
  case peek().value
  when "set"      then parse_set()
  when "call"     then parse_call()
  when "call_set" then parse_call_set()
  when "return"   then parse_return()
  when "while"    then parse_while()
  when "case"     then parse_case()
  when "_cmt"     then parse_vm_comment()
  when "_debug"   then parse_debug()
  else
    raise "unexpected token"
  end
end

def parse_stmts : List
  stmts = List.new

  while peek().value != "}"
    stmts << parse_stmt()
  end

  stmts
end

def parse_top_stmt : List
  if peek().value == "func"
    parse_func()
  else
    raise "unexpected token"
  end
end

def parse_top_stmts : List
  raw_top_stmts = List.new

  until end?()
    raw_top_stmts << parse_top_stmt()
  end

  top_stmts = List.new
  top_stmts << "top_stmts"
  top_stmts += raw_top_stmts
  top_stmts
end

g = Global.instance
g.tokens = read_tokens()

ast =
  begin
    parse_top_stmts()
  rescue e
    dump_state()
    raise e
  end

json_pretty_print(ast)
