if exists("b:current_syntax")
  finish
endif

syn match stevedoreId /^\/\d*\/\x\+\// conceal

let b:current_syntax = "stevedore"
