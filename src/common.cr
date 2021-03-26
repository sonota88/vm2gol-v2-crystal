require "./types"

alias Expr = Node
alias Stmt = List

def puts_e(*args)
  STDERR.puts *args
end

def p_e(*args)
  STDERR.puts *(args.map { |arg| arg.inspect })
end

def pp_e(*args)
  STDERR.puts *(args.map { |arg| arg.pretty_inspect })
end

def read_stdin_all
  String.build do |io|
    while line = STDIN.gets(chomp: false)
      io << line
    end
  end
end

def format(template, *params)
  template % params
end
