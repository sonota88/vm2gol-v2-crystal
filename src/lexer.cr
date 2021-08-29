require "./common"
require "./json"

src = read_stdin_all()

tokens = [] of Token

pos = 0
lineno = 1

while pos < src.size
  rest = src[pos .. -1]

  case rest
  when /\A([ ]+)/
    str = $1
    pos += str.size

  when /\A(\n)/
    str = $1
    pos += str.size
    lineno += 1

  when %r{\A(//.*)}
    str = $1
    pos += str.size

  when /\A"(.*)"/
    str = $1
    tokens << Token.new(:str, str, lineno)
    pos += str.size + 2

  when /\A(func|set|var|call_set|call|return|case|while|_cmt|_debug)[^a-z_]/
    str = $1
    tokens << Token.new(:kw, str, lineno)
    pos += str.size

  when /\A(-?[0-9]+)/
    str = $1
    tokens << Token.new(:int, str, lineno)
    pos += str.size

  when /\A(==|!=|[\(\)\{\}=;\+\*,])/
    str = $1
    tokens << Token.new(:sym, str, lineno)
    pos += str.size

  when /\A([a-z_][a-z0-9_]*)/
    str = $1
    tokens << Token.new(:ident, str, lineno)
    pos += str.size

  else
    puts_e "lineno (#{lineno})"
    p_e rest[0...100]
    raise "unexpected pattern"
  end
end

tokens.each do |t|
  json_print(t.to_list())
  print "\n"
end
