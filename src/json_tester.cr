require "./common"
require "./json"

json = read_stdin_all()
list = json_parse(json)
json_pretty_print(list)
