" This file contains relatively short functions and a few commands and
" mappings for vim.  Many of these were written in response to questions
" posted on the vim mailing list.  As a result (if I do say so myself)
" there are a lot of clever ideas in this file.

" Since I experiment a lot with this file, I want to avoid having
" duplicate autocommands.
augroup Foo
  autocmd!
augroup END

" This is the beginning of a function for taking an input string and
" returning the value after "special characters" have been evaluated:
" <C-U> erases all previous input.  One might also want to implement
" <C-W> and others.
fun! DoSp(str)
  let s = substitute(a:str, '.*\<C-U>', "", "")
  return s
endfun

" This function evaluates the input string in Input mode.  Special
" characters, such as <C-U> and <C-N> will be executed in Input mode.
" Raw <Esc> characters will produce unpredictable results.
fun! EvalInput(string)
  new
  execute "normal a" . a:string . "\<Esc>ggyG"
  q!
  return @"
endfun

" Use with  :nmap % :call HTMLmatch()
" If the cursor is on a non-alphabetic character then invoke the normal
" behavior of %.  If the cursor is on an alphabetic character, attempt to
" jump from <tag> to </tag> and back.  This is just a quick demo; it does
" not deal with nesting.  For a more complete version, see matchit.vim .
fun! HTMLmatch()
  if getline(".")[col(".")-1] !~ "\\a"
    normal! %
    return
  endif
  execute "normal ?\\A\<CR>"
  normal lye
  if getline(".")[col(".")-2] == '/'
    execute 'normal ?<\s*' . @" . "\<CR>l"
  else
    execute 'normal /<\s*\/' . @" . "\<CR>ll"
  endif
endfun

augroup Foo
  autocmd BufEnter *.cpp,*.h inoremap { {<Esc>:call ClassHeader("-")<CR>a
  autocmd BufLeave *.cpp,*.h iunmap {
  " Keep your braces balanced!}}}
augroup END

" With the above autocommands, this will insert a header every time you
" begin a new class in C++ .
fun! ClassHeader(leader)
  if getline(".") !~ "^\\s*class"
    return
  endif
  normal yyP$x
  let width = 80
  if exists("&tw")
    let width = &tw
  endif
  execute "normal " . (width-virtcol(".")-3) . "I" . a:leader . "\<Esc>"
  execute "normal a \<Esc>"
  execute "normal I//\<Esc>"
  " Keep your braces balanced!{
  execute "normal! jo};\<Esc>"
  normal k$
endfun

" This is my first user-defined command.  Unlike a user-defined function,
" a command can be called from the function Foo() and have access to the
" local variables of Foo().
" Usage:  :let foo = 1 | Line foo s/foo/bar
" Usage:  :let foo = 1 | let bar = 3 | Line foo,bar s/foo/bar
" You can also do ":Line foo+1 s/foo/bar" or "Line foo-1,bar+1 ..."
" There must be no spaces in "foo,bar".
command! -nargs=* Line
	\ | let Line_range = matchstr(<q-args>, '\S\+')
	\ | let Line_range = "(" . substitute(Line_range, ",", ").','.(", "") . ")"
	\ | execute "let Line_range = " . Line_range
	\ | execute Line_range . substitute(<q-args>, '\S\+', "", "")
	\ | unlet Line_range
" Example:  If foo=2 and bar=3 and you do ":Line foo-1,bar+1 s/foo/bar" then
" 1. Line_range = "foo-1,bar+1"
" 2. Line_range = "(foo-1).','.(bar+1)"
" If there is no comma then this step has no effect.
" 3. Line_range = "1,4"
" 4. 1,4 s/foo/bar

" Usage:  :let foo = 1 | let bar = 3 | Range foo bar s/foo/bar
command! -nargs=* Range
	\ | execute substitute(<q-args>, '\(\S\+\)\s\+\(\S\+\)\(.*\)',
		\ 'let Range_range=\1.",".\2', "")
	\ | execute Range_range . substitute(<q-args>, '\S\+\s\+\S\+', "", "")
	\ | unlet Range_range

" Usage:  let ma = Mark() ... execute ma
" has the same effect as  normal ma ... normal 'a
" without affecting global marks.
" You can also use Mark(17) to refer to the start of line 17 and Mark(17,34)
" to refer to the 34'th (screen) column of the line 17.  The functions
" Line() and Virtcol() extract the line or (screen) column from a "mark"
" constructed from Mark() and default to line() and virtcol() if they do not
" recognize the pattern.
" Update:  :execute Mark() now restores screen position as well as the cursor.
fun! Mark(...)
  if a:0 == 0
    let mark = line(".") . "G" . virtcol(".") . "|"
    normal! H
    let mark = "normal!" . line(".") . "Gzt" . mark
    execute mark
    return mark
  elseif a:0 == 1
    return "normal!" . a:1 . "G1|"
  else
    return "normal!" . a:1 . "G" . a:2 . "|"
  endif
endfun

" See comments above Mark()
fun! Line(mark)
  if a:mark =~ '\dG\d\+|$'
    return substitute(a:mark, '.\{-}\(\d\+\)G\d\+|$', '\1', "")
  else
    return line(a:mark)
  endif
endfun

" See comments above Mark()
fun! Virtcol(mark)
  if a:mark =~ '\d\+G\d\+|$'
    return substitute(a:mark, '.*G\(\d\+\)|$', '\1', "")
  else
    return col(a:mark)
  endif
endfun

" This function can be used to trash your search history in vim 5.6.
" Just call it twice in a row, with the help of the map below.  This
" bug should be fixed in the next release of vim.
fun! Foo()
  let n = histnr("/")
  /qwertyuiop
  if histnr("/") > n
    call histdel("/", -1)
  endif
endfun
map <F4> :call Foo()<CR>
map <F5> :history /<CR>

" Usage:  If the file contains lines like
" let pippo1 = pippo12
" I like pippo2
" then :%call Pippo()<CR> will append lines
" pippo1
" pippo12
" pippo2
" to the end of the file.
" I do not know what the original requester had in mind, but this could be
" useful for generating dictionaries.  For example, for LaTeX, try
" :%call Pippo('\\\a\+') and then sort the resulting lines.
fun! Pippo(...) range
  if a:0
    let pat = a:1
  else
    let pat = '\<pippo\d\+\>'
  endif
  let bot = line("$")
  execute a:firstline . "," . a:lastline . 'g/' . pat . '/copy $'
  if bot == line("$")
    return
  endif
  execute (bot+1) . ',$s/' . pat . '/&\r/ge'
  execute (bot+1) . ',$v/' . pat . '/d'
  execute (bot+1) . ',$s/.\{-}\(' . pat . '\)$/\1/e'
endfun

" First line:  Stefan Roemer's idea (seems to work better than my idea, line 2.)
" If it works right then hitting <F4> does not make ":call CommandlineClear()"
" appear on the command line.
fun! CommandlineClear()
  let ch_save = &ch | let &ch = 0 | let &ch = ch_save
  echo strpart("\r\r\r\r\r\r\r\r\r\r\r\r\r\r\r\r\r\r\r\r", 0, &ch)
endfun
map <F4> :call CommandlineClear()<CR>

" <S-4> or $ takes you to the last character of the line; this takes you
" to the last non-blank character of the line.
map <M-4> 0:let@9=@/<Bar>set nohls<CR>/.*\S/e<CR>:let @/=@9<Bar>set hls<CR>
" Here is another way to do it.  I use a function for legibility and for the
" sake of a local variable.
map <M-4> :call LastNonBlank()<CR>
fun! LastNonBlank()
  let i = matchend(getline("."), '.*\S')-1
  if i > 0
    execute "normal!0" . i . "l"
  elseif i == 0
    execute normal! 0
  endif
endfun

" Strip off a pattern from a keyword and jump to the tag.
nmap <C-]> :call StripTag("xxx")<CR>
fun! StripTag(pattern)
  let keyword = expand("<cword>")
  if keyword =~ '^' . a:pattern
    execute "tag!" . substitute(keyword, a:pattern, "", "")
  else
    execute "normal! \<C-]>"
  endif
endfun

" These autocommands and function insert a template every time you
" type "<scr" at the end of a line in a *.jsp file.
augroup Foo
  autocmd BufEnter *.jsp imap r r<Esc>:call JS_template()<CR>a
  autocmd BufLeave *.jsp iunmap r
augroup END
fun! JS_template()
  if getline(".") !~ '<scr$'
    return
  endif
  s/scr$/script language="JavaScript">/
  append
  function foo() {
      alert("Hello, world.");
    }
  </script>

.
endfun

"The following autocommand and function align C++ style << characters.
augroup Foo
  autocmd BufEnter *.cpp imap < <<C-O>:call LineUpLT()<CR>
  autocmd BufLeave *.cpp iunmap <
augroup END

fun! LineUpLT()
  if line(".") == 1 || getline(".") !~ '^\s*<<$'
    return
  endif
  let newline = getline(line(".")-1)
  let col = match(newline, "<<")
  if col != -1
    let newline = strpart(newline, 0, col)
    let newline = substitute(newline, '\S', " ", "g") . "<<"
    call setline(line("."), newline)
    normal!$
  endif
endfun

fun! Count(pat)
  let num = 0
  execute 'g/' . a:pat . '/let num = num + 1'
  return num
endfun

" A joint effort with Douglas Potts.
" Show the colors of all highlight groups.
" Oops, we reinvented the wheel!  See $VIMRUNTIME/hitest.vim .
fun! ShowHi()
  " Save the value of 'more'
  let save_more = &more
  " Spare me the "more" prompts!
  :set nomore
  " Redirect output of :hi to register a
  redir @a
  hi
  redir END
  new
  " Put it in a temp buffer
  put a
  " Remove any line that does not match '\h' (head-of-word character)
  v/\h/d
  " Do some processing to add 'syn keyword' syntax
  %s/.\{-}\(\h\w*\).*/syn keyword \1 \1/
  " Yank the buffer into register a and execute it.
  %y a
  @a
endfun

command! -nargs=1 -complete=var EditFun call EditFun(<q-args>)
fun! EditFun(name)
  " Save the value of 'more'
  let save_more = &more
  " Spare me the "more" prompts!
  :set nomore
  " Redirect output of :hi to register a
  redir @a
  execute "function " . a:name
  redir END
  " Put it in a temp buffer
  execute "sp " . tempname()
  put a
  set ft=vim
endfun

" Get information from user-defined modelines.  If the file contains
" /* foo:  bar */
" on line 17 then GetModelines('/\* foo:') returns the String "17:".
" If the pattern contains a \(group\) then the matching text is
" returned:  GetModelines('/\* foo:  \(.*\) \*/') returns "17:bar".
" A more robust input pattern would be '/\*\s*foo:\s*\(.\{-}\)\s*\*/'.
" If no match is found, the function returns "0:".  Vim will also
" report that no match was found; this may trigger a hit-return prompt.
" At least, it does not count as an error.
"
" By default, the whole file is searched, and the LAST match counts.
" You can restrict the range as follows:
"   GetModelines(pat, 100)	searches the first 100 lines;
"   GetModelines(pat, -100)	searches the last 100 lines;
"   GetModelines(pat, 10,100)	searches lines 10 to 100.
" In all cases, the script checks for a valid range, so that you do
" not have to.
fun! GetModelines(pat, ...)
  " Long but simple:  set start line and finish line.
  let EOF = line("$")
  if a:0 >1
    let start = a:1
    let finish = a:2
  elseif a:0 == 1
    if a:1 > 0
      let start = 1
      let finish = a:1
    else
      let start = EOF + a:1 + 1
      let finish = EOF
    endif
  endif
  if !exists("start") || start < 1
    let start = 1
  endif
  if !exists("finish") || finish > line(">")
    let finish = EOF
  endif
  " Now for the fun part!  Remember that any command can be used after
  " :g/pat/ although :s is the most common.  Since I am using "/" to
  " delimit the :g command, I have to escape them in a:pat.
  let n = 0
  execute "g/" . escape(a:pat, "/") . "/let n=line('.')"
  " Now, some substitute() magic:  I enclose the pattern in a \(group\),
  " in case it contains branches, and add .\{-} and .* at the beginning
  " and end, so it matches the whole line.  Since \(pat\) is the first
  " group, \2 refers to the user's first group, if any.
  if n
    execute "normal!\<C-O>"
    return substitute(getline(n), '.\{-}\(' . a:pat . '\).*', n.':\2', '')
  else
    echo
    return "0:"
  endif
endfun

" Make tab stops at columns 8, 17, 26, and 35.
" In real life, you would want to map <Tab> instead of <F7>.
imap <F7> <C-R>=VarTab(virtcol("."),8,17,26,35)<CR>

fun! VarTab(c, ...)
  let i = 1
  while i <= a:0
    execute "let num_sp = -a:c + a:" . i
    if num_sp > 0
      break
    endif
    let i = i+1
  endwhile
  if i > a:0
    return ""
  endif
  let spaces = " "
  let len = 1
  while len < num_sp
    let spaces = spaces . spaces
    let len = len + len
  endwhile
  return strpart(spaces, 0, num_sp)
endfun

" For HTML files, map <BS> to delete "&foo;" as one character.
" To avoid complications (start of line, end of line, etc.) the
" mapping inserts a character, the function deletes all but two
" characters, and the mapping deletes the last two.
augroup Foo
  autocmd BufEnter *.html,*.htm
   \ inoremap <BS> x<Esc>:call SmartBS('&[^ \t;]*;')<CR>a<BS><BS>
  autocmd BufLeave *.html,*.htm iunmap <BS>
augroup END

fun! SmartBS(pat)
  let init = strpart(getline("."), 0, col(".")-1)
  let len = strlen(matchstr(init, a:pat . "$")) - 1
  if len > 0
    execute "normal!" . len . "X"
  endif
endfun

" If you have the line
"	foobar
" and call :Transform abc xyz
" then the "a" and "b" in "foobar" are teanslated into "x" and "y", to give
"	fooyxr
" If the Transform() function is given the optional third argument, a string,
" then it returns the transformed string instead of operating on the current
" line.  Both can be given a range of lines, following the usual rules.
command! -nargs=* -range Transform <line1>,<line2> call Transform(<f-args>)

fun! Transform(old, new, ...)
  if a:0
    let string = a:1
  else
    let string = getline(".")
  endif
  let i = 0
  while i < strlen(a:old) && i < strlen(a:new)
    execute "let string=substitute(string,'".a:old[i]."','".a:new[i]."','g')"
    let i = i+1
  endwhile
  if a:0
    return string
  else
    call setline(".", string)
  endif
endfun
