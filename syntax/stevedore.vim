if exists("b:current_syntax")
  finish
endif

syn match stevedoreId /^\/\x\+\// conceal

let b:current_syntax = "stevedore"
