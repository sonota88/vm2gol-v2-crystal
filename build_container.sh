#!/bin/bash

opts="--error-trace --static"

crystal build src/json_tester.cr -o bin/json_tester $opts
crystal build src/lexer.cr -o bin/lexer $opts
crystal build src/parser.cr -o bin/parser $opts
crystal build src/codegen.cr -o bin/codegen $opts
