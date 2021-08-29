# coding: utf-8

require "./common"
require "./json"

alias Names = Array(String)

class Global
  @@label_id = 0

  def self.get_label_id
    @@label_id += 1
    @@label_id
  end
end

def rest(list, i) : List
  list[i..-1]
end

def fn_arg_disp(
      fn_arg_names : Names,
      fn_arg_name
    ) : Int32
  index = fn_arg_names.index(fn_arg_name)
  if index.nil?
    raise "must not happen"
  end

  index + 2
end

def lvar_disp(
      lvar_names : Names,
      lvar_name
    ) : Int32
  index = lvar_names.index(lvar_name)
  if index.nil?
    raise "must not happen"
  end

  -(index + 1)
end

# --------------------------------

def asm_prologue
  puts "  push bp"
  puts "  cp sp bp"
end

def asm_epilogue
  puts "  cp bp sp"
  puts "  pop bp"
end

# --------------------------------

def _gen_expr_add
  puts "  pop reg_b"
  puts "  pop reg_a"
  puts "  add_ab"
end

def _gen_expr_mult
  puts "  pop reg_b"
  puts "  pop reg_a"
  puts "  mult_ab"
end

def _gen_expr_eq
  label_id = Global.get_label_id()

  label_end = "end_eq_#{label_id}"
  label_then = "then_#{label_id}"

  puts "  pop reg_b"
  puts "  pop reg_a"

  puts "  compare"
  puts "  jump_eq #{label_then}"

  # else
  puts "  cp 0 reg_a"
  puts "  jump #{label_end}"

  # then
  puts "label #{label_then}"
  puts "  cp 1 reg_a"

  puts "label #{label_end}"
end

def _gen_expr_neq
  label_id = Global.get_label_id()

  label_end = "end_neq_#{label_id}"
  label_then = "then_#{label_id}"

  puts "  pop reg_b"
  puts "  pop reg_a"

  puts "  compare"
  puts "  jump_eq #{label_then}"

  # else
  puts "  cp 1 reg_a"
  puts "  jump #{label_end}"

  # then
  puts "label #{label_then}"
  puts "  cp 0 reg_a"

  puts "label #{label_end}"
end

def _gen_expr_binary(
      fn_arg_names : Names,
      lvar_names : Names,
      expr : List
    )
  operator = expr[0].as(String)

  gen_expr(fn_arg_names, lvar_names, expr[1])
  puts "  push reg_a"
  gen_expr(fn_arg_names, lvar_names, expr[2])
  puts "  push reg_a"

  case operator
  when "+"   then _gen_expr_add()
  when "*"   then _gen_expr_mult()
  when "eq"  then _gen_expr_eq()
  when "neq" then _gen_expr_neq()
  else
    raise "unexpected operator"
  end
end

def gen_expr(
      fn_arg_names : Names,
      lvar_names : Names,
      expr : Expr
    )
  case expr
  in Int32
    puts "  cp #{expr} reg_a"
  in String
    if lvar_names.includes?(expr)
      disp = lvar_disp(lvar_names, expr)
      puts "  cp [bp:#{disp}] reg_a"
    elsif fn_arg_names.includes?(expr)
      disp = fn_arg_disp(fn_arg_names, expr)
      puts "  cp [bp:#{disp}] reg_a"
    else
      raise "must not happen"
    end
  in List
    _gen_expr_binary(fn_arg_names, lvar_names, expr)
  end
end

def _gen_call(
      fn_arg_names : Names,
      lvar_names : Names,
      funcall : List
    )
  fn_name = funcall[0].as(String)
  fn_args = rest(funcall, 1)

  fn_args.reverse.each do |fn_arg|
    gen_expr(fn_arg_names, lvar_names, fn_arg)
    puts "  push reg_a"
  end

  gen_vm_comment("call  #{fn_name}")
  puts "  call #{fn_name}"
  puts "  add_sp #{fn_args.size}"
end

def gen_call(
      fn_arg_names : Names,
      lvar_names : Names,
      stmt : Stmt
    )
  funcall = rest(stmt, 1)
  _gen_call(fn_arg_names, lvar_names, funcall)
end

def gen_call_set(
      fn_arg_names : Names,
      lvar_names : Names,
      stmt : Stmt
    )
  lvar_name = stmt[1].as(String)
  funcall = stmt[2].as(List)

  _gen_call(fn_arg_names, lvar_names, funcall)

  disp = lvar_disp(lvar_names, lvar_name)
  puts "  cp reg_a [bp:#{disp}]"
end

def _gen_set(
      fn_arg_names : Names,
      lvar_names : Names,
      lhs : String,
      rhs : Expr
    )
  gen_expr(fn_arg_names, lvar_names, rhs)

  if lvar_names.includes?(lhs)
    disp = lvar_disp(lvar_names, lhs)
    puts "  cp reg_a [bp:#{disp}]"
  else
    raise "unsupported"
  end
end

def gen_set(
      fn_arg_names : Names,
      lvar_names : Names,
      stmt : Stmt
    )
  _gen_set(
    fn_arg_names,
    lvar_names,
    stmt[1].as(String),
    stmt[2]
  )
end

def gen_return(
      lvar_names : Names,
      stmt : Stmt
    )
  expr = stmt[1]
  gen_expr([] of String, lvar_names, expr)
end

def gen_while(
      fn_arg_names : Names,
      lvar_names : Names,
      stmt : Stmt
    )
  cond_expr = stmt[1]
  body = stmt[2].as(List)

  label_id = Global.get_label_id()

  puts ""

  puts "label while_#{label_id}"

  gen_expr(fn_arg_names, lvar_names, cond_expr)

  puts "  cp 0 reg_b" # 比較対象の値をセット
  puts "  compare"

  puts "  jump_eq end_while_#{label_id}"

  puts "  jump true_#{label_id}"

  puts "label true_#{label_id}"
  gen_stmts(fn_arg_names, lvar_names, body)

  puts "  jump while_#{label_id}"

  puts "label end_while_#{label_id}"
  puts ""
end

def gen_case(
      fn_arg_names : Names,
      lvar_names : Names,
      stmt : Stmt
    )
  when_clauses = rest(stmt, 1)

  label_id = Global.get_label_id()

  when_idx = -1

  label_end = "end_case_#{label_id}"
  label_when_head = "when_#{label_id}"
  label_end_when_head = "end_when_#{label_id}"

  when_clauses.each do |node|
    when_clause = node.as(List)
    when_idx += 1

    cond = when_clause[0]
    rest = rest(when_clause, 1)

    puts "  # 条件 #{label_id}_#{when_idx}: #{cond.inspect}"

    gen_expr(fn_arg_names, lvar_names, cond)

    puts "  cp 0 reg_b"

    puts "  compare"
    puts "  jump_eq #{label_end_when_head}_#{when_idx}"
    puts "  jump #{label_when_head}_#{when_idx}"

    puts "label #{label_when_head}_#{when_idx}"

    gen_stmts(fn_arg_names, lvar_names, rest)
    puts "  jump #{label_end}"

    puts "label #{label_end_when_head}_#{when_idx}"
  end

  puts "label #{label_end}"
end

def gen_vm_comment(comment : String)
  puts "  _cmt " + comment.gsub(" ", "~")
end

def gen_debug
  puts "  _debug"
end

def gen_var(
      fn_arg_names : Names,
      lvar_names : Names,
      stmt : Stmt
    )
  puts "  sub_sp 1"

  if stmt.size == 3
    _gen_set(
      fn_arg_names,
      lvar_names,
      stmt[1].as(String),
      stmt[2]
    )
  end
end

def gen_func_def(rest : List)
  fn_name = rest[1].as(String)
  fn_arg_names = rest[2].as(List).map { |node| node.as(String) }
  body = rest[3].as(List)

  puts ""
  puts "label #{fn_name}"
  asm_prologue()

  puts ""
  puts "  # 関数の処理本体"

  lvar_names = [] of String

  body.each do |node|
    stmt = node.as(List)

    stmt_head = stmt[0].as(String)
    stmt_rest = rest(stmt, 1)

    case stmt_head
    when "var"
      lvar_names << stmt_rest[0].as(String)
      gen_var(fn_arg_names, lvar_names, stmt)
    else
      gen_stmt(fn_arg_names, lvar_names, stmt)
    end
  end

  puts ""
  asm_epilogue
  puts "  ret"
end

def gen_stmt(
      fn_arg_names : Names,
      lvar_names : Names,
      stmt : Stmt
)
  stmt_head = stmt[0].as(String)
  stmt_rest : List = rest(stmt, 1)

  case stmt_head
  when "set"
    gen_set(fn_arg_names, lvar_names, stmt)
  when "call"
    gen_call(fn_arg_names, lvar_names, stmt)
  when "call_set"
    gen_call_set(fn_arg_names, lvar_names, stmt)
  when "return"
    gen_return(lvar_names, stmt)
  when "while"
    gen_while(fn_arg_names, lvar_names, stmt)
  when "case"
    gen_case(fn_arg_names, lvar_names, stmt)
  when "_cmt"
    gen_vm_comment(stmt_rest[0].as(String))
  when "_debug"
    gen_debug()
  else
    raise "unexpected statement"
  end
end

def gen_stmts(
      fn_arg_names : Names,
      lvar_names : Names,
      stmts : List
    )
  stmts.each do |node|
    stmt = node.as(Stmt)

    gen_stmt(fn_arg_names, lvar_names, stmt)
  end
end

def gen_top_stmts(top_stmts : List)
  top_stmts.each do |node|
    top_stmt = node.as(List)

    head = top_stmt[0].as(String)

    case head
    when "func"
      gen_func_def(top_stmt)
    else
      raise "unexpected top statement"
    end
  end
end

def codegen_builtin_set_vram
  puts ""
  puts "label set_vram"
  asm_prologue()
  puts "  set_vram [bp:2] [bp:3]" # vram_addr value
  asm_epilogue()
  puts "  ret"
end

def codegen_builtin_get_vram
  puts ""
  puts "label get_vram"
  asm_prologue()
  puts "  get_vram [bp:2] reg_a" # vram_addr dest
  asm_epilogue()
  puts "  ret"
end

ast_src = read_stdin_all()
ast = json_parse(ast_src)

puts "  call main"
puts "  exit"

rest = rest(ast, 1)

gen_top_stmts(rest)

puts "#>builtins"
codegen_builtin_set_vram()
codegen_builtin_get_vram()
puts "#<builtins"
