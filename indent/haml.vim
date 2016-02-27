" Vim indent file
" Language:	Haml
" Maintainer:	Tim Pope <vimNOSPAM@tpope.org>
" Last Change:	2010 May 21

if exists("b:did_indent")
  finish
endif
runtime! indent/ruby.vim
unlet! b:did_indent
let b:did_indent = 1

setlocal autoindent sw=2 et
setlocal indentexpr=GetHamlIndent()
setlocal indentkeys=o,O,*<Return>,},],0),!^F,=end,=else,=elsif,=rescue,=ensure,=when

" Only define the function once.
if exists("*GetHamlIndent")
  finish
endif

let s:attributes = '\%({.\{-\}}\|\[.\{-\}\]\)'
let s:tag = '\%([%.#][[:alnum:]_-]\+\|'.s:attributes.'\)*[<>]*'

if !exists('g:haml_self_closing_tags')
  let g:haml_self_closing_tags = 'base|link|meta|br|hr|img|input'
endif

" Check if line 'lnum' has more opening brackets than closing ones.
"
" COPIED AND BUTCHERED FROM 
" https://github.com/vim-ruby/vim-ruby/blob/master/indent/ruby.vim
" (comment stuff is removed)
function s:ExtraBrackets(lnum)
  let opening = {'parentheses': [], 'braces': [], 'brackets': []}
  let closing = {'parentheses': [], 'braces': [], 'brackets': []}

  let line = getline(a:lnum)
  let pos  = match(line, '[][(){}]', 0)

  " Save any encountered opening brackets, and remove them once a matching
  " closing one has been found. If a closing bracket shows up that doesn't
  " close anything, save it for later.
  while pos != -1
    if line[pos] == '('
      call add(opening.parentheses, {'type': '(', 'pos': pos})
    elseif line[pos] == ')'
      if empty(opening.parentheses)
        call add(closing.parentheses, {'type': ')', 'pos': pos})
      else
        let opening.parentheses = opening.parentheses[0:-2]
      endif
    elseif line[pos] == '{'
      call add(opening.braces, {'type': '{', 'pos': pos})
    elseif line[pos] == '}'
      if empty(opening.braces)
        call add(closing.braces, {'type': '}', 'pos': pos})
      else
        let opening.braces = opening.braces[0:-2]
      endif
    elseif line[pos] == '['
      call add(opening.brackets, {'type': '[', 'pos': pos})
    elseif line[pos] == ']'
      if empty(opening.brackets)
        call add(closing.brackets, {'type': ']', 'pos': pos})
      else
        let opening.brackets = opening.brackets[0:-2]
      endif
    endif
  endif

  let pos = match(line, '[][(){}]', pos + 1)

  " Find the rightmost brackets, since they're the ones that are important in
  " both opening and closing cases
  let rightmost_opening = {'type': '(', 'pos': -1}
  let rightmost_closing = {'type': ')', 'pos': -1}

  for opening in opening.parentheses + opening.braces + opening.brackets
    if opening.pos > rightmost_opening.pos
      let rightmost_opening = opening
    endif
  endfor

  for closing in closing.parentheses + closing.braces + closing.brackets
    if closing.pos > rightmost_closing.pos
      let rightmost_closing = closing
    endif
  endfor

  return [rightmost_opening, rightmost_closing]
endfunction

function! GetHamlIndent()
  let lnum = prevnonblank(v:lnum-1)
  if lnum == 0
    return 0
  endif
  let line = substitute(getline(lnum),'\s\+$','','')
  let cline = substitute(substitute(getline(v:lnum),'\s\+$','',''),'^\s\+','','')
  let lastcol = strlen(line)
  let line = substitute(line,'^\s\+','','')
  let indent = indent(lnum)
  let cindent = indent(v:lnum)
  let sw = exists('*shiftwidth') ? shiftwidth() : &sw
  if cline =~# '\v^-\s*%(elsif|else|when)>'
    let indent = cindent < indent ? cindent : indent - sw
  endif
  let increase = indent + sw
  if indent == indent(lnum)
    let indent = cindent <= indent ? -1 : increase
  endif

  let group = synIDattr(synID(lnum,lastcol,1),'name')

  " If the previous line contained unclosed opening brackets and we are still
  " in them, find the rightmost one and add indent depending on the bracket
  " type.
  "
  " If it contained hanging closing brackets, find the rightmost one, find its
  " match and indent according to that.
  "
  " COPIED FROM https://github.com/vim-ruby/vim-ruby/blob/master/indent/ruby.vim
  if line =~ '[[({]' || line =~ '[])}]\s*\%(#.*\)\=$'
    let [opening, closing] = s:ExtraBrackets(lnum)

    if opening.pos != -1
      if opening.type == '(' && searchpair('(', '', ')', 'bW', s:skip_expr) > 0
        if col('.') + 1 == col('$')
          return ind + sw
        else
          return 30
          return virtcol('.')
        endif
      else
        let nonspace = matchend(line, '\S', opening.pos + 1) - 1
        return nonspace > 0 ? nonspace : ind + sw
      endif
    elseif closing.pos != -1
      call cursor(lnum, closing.pos + 1)
      normal! %

      return indent('.') + sw
    else
      call cursor(clnum, vcol)
    end
  endif


  if line =~ '^!!!'
    return indent
  elseif line =~ '^/\%(\[[^]]*\]\)\=$'
    return increase
  elseif group == 'hamlFilter'
    return increase
  elseif line =~ '^'.s:tag.'[&!]\=[=~-]\s*\%(\%(if\|else\|elsif\|unless\|case\|when\|while\|until\|for\|begin\|module\|class\|def\)\>\%(.*\<end\>\)\@!\|.*do\%(\s*|[^|]*|\)\=\s*$\)'
    return increase
  elseif line =~ '^'.s:tag.'[&!]\=[=~-].*,\s*$'
    return increase
  elseif line == '-#'
    return increase
  elseif group =~? '\v^(hamlSelfCloser)$' || line =~? '^%\v%('.g:haml_self_closing_tags.')>'
    return indent
  elseif group =~? '\v^%(hamlTag|hamlAttributesDelimiter|hamlObjectDelimiter|hamlClass|hamlId|htmlTagName|htmlSpecialTagName)$'
    return increase
  elseif synIDattr(synID(v:lnum,1,1),'name') ==? 'hamlRubyFilter'
    return GetRubyIndent()
  else
    return indent
  endif
endfunction

" vim:set sw=2:
