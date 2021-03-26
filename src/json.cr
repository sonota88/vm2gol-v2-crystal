require "json"

def json_parse_node(node) : Node
  val = node.as_i?
  if val
    return val.as(Int32)
  end

  val = node.as_s?
  if val
    return val.as(String)
  end

  val = node.as_a?
  if val
    return json_parse_list(val.as(Array))
  end

  raise "must not happen"
end

def json_parse_list(xs)
  list = List.new

  xs.each do |x|
    list << json_parse_node(x)
  end

  list
end

def json_parse(json) : List
  data: JSON::Any = JSON.parse(json)
  json_parse_list(data.as_a)
end

def print_indent(lv)
  print "  " * lv
end

def json_print_node(val, lv, pretty)

  case val
  in Int32
    print_indent(lv) if pretty
    print val
  in String
    print_indent(lv) if pretty
    print '"' + val + '"'
  in Symbol
    print_indent(lv) if pretty
    print '"' + val.to_s + '"'
  in List
    json_print_list(val, lv, pretty)
  end
end

def json_print_list(list : List, lv, pretty = false)
  print_indent(lv) if pretty
  print "["
  print "\n" if pretty

  list.each_with_index do |el, i|
    json_print_node(el, lv + 1, pretty)
    if i != list.size - 1
      print ","
      print " " unless pretty
    end
    print "\n" if pretty
  end

  print_indent(lv) if pretty
  print "]"
end

def json_print(list : List)
  json_print_list(list, 0)
end

def json_pretty_print(list : List)
  json_print_list(list, 0, pretty: true)
end
