alias Node = Int32 | String | List
alias List = Array(Node)

class Token
  @kind : Symbol
  @value : String
  @lineno : Int32

  getter :kind, :value, :lineno

  def initialize(@kind, @value, @lineno)
  end

  def value_as_int : Int32
    @value.to_i
  end

  def self.str_to_kind(s)
    case s
    when "kw"    then :kw
    when "ident" then :ident
    when "sym"   then :sym
    when "int"   then :int
    when "str"   then :str
    else
      raise "invalid kind string"
    end
  end

  def to_list
    [@lineno, @kind.to_s, @value]
  end

  def self.from_json(json)
    parts = json_parse(json)
    Token.new(
      str_to_kind(parts[1].as(String)),
      parts[2].as(String),
      parts[0].as(Int32)
    )
  end
end
