" Vim plugin for viewing decompiled class files using jad
" Ideas:  Allow for a default to be set in the vimrc
"         - map a keystroke to decompile and edit, or decompile and view in
"         split window
if exists("loaded_gzip") || &cp || exists("#BufReadPre#*.gz")
  finish
endif
let loaded_gzip = 1

augroup class
  " Remove all gzip autocommands
  au!

  " Enable editing of gzipped files
  " set binary mode before reading the file
  " use "gzip -d", gunzip isn't always available
  autocmd BufReadPre,FileReadPre	*.class  set bin
  autocmd BufReadPost,FileReadPost	*.class  call s:read("jad")
  "autocmd BufWritePost,FileWritePost	*.gz  call s:write("gzip")
  "autocmd FileAppendPre			*.gz  call s:appre("gzip -d")
  "autocmd FileAppendPost		*.gz  call s:write("gzip")
augroup END

" Function to check that executing "cmd [-f]" works.
" The result is cached in s:have_"cmd" for speed.
fun s:check(cmd)
  let name = substitute(a:cmd, '\(\S*\).*', '\1', '')
  if !exists("s:have_" . name)
    let e = executable(name)
    if e < 0
      let r = system(name . " --version")
      let e = (r !~ "not found" && r != "")
    endif
    exe "let s:have_" . name . "=" . e
  endif
  exe "return s:have_" . name
endfun

" After reading compressed file: Uncompress text in buffer with "cmd"
fun s:read(cmd)
  " don't do anything if the cmd is not supported
  if !s:check(a:cmd)
    return
  endif
  " make 'patchmode' empty, we don't want a copy of the written file
  let pm_save = &pm
  set pm=
  " set 'modifiable'
  let ma_save = &ma
  set ma
  " when filtering the whole buffer, it will become empty
  let empty = line("'[") == 1 && line("']") == line("$")
  let jadfile = expand("<afile>:r") . "." . "jad"
  let orig = expand("<afile>")
  " uncompress the temp file: call system("gzip -d tmp.gz")
  "call system(a:cmd . " " . orig)
  " delete the compressed lines
  "'[,']d
  " read in the uncompressed lines "'[-1r tmp"
  set nobin

  "Split and show code in a new window
  "new
  "execute "silent r !" a:cmd . " -p " . orig
   
  g/.*/d
  execute "silent r !" a:cmd . " -p " . orig
  1
  set ft=java
  set syntax=java
  setlocal nomodifiable
  "execute "silent '[-1r " . tmp
  " if buffer became empty, delete trailing blank line
  "if empty
    "silent $delete
    "1
  "endif
  " delete the temp file and the used buffers
  "call delete(tmp)
  "silent! exe "bwipe " . tmp
  "silent! exe "bwipe " . tmpe
  let &pm = pm_save
  let &ma = ma_save
  " When uncompressed the whole buffer, do autocommands
  "if empty
  "  execute ":silent! doau BufReadPost " . expand("%:r")
  "endif
endfun

" After writing compressed file: Compress written file with "cmd"
fun s:write(cmd)
  " don't do anything if the cmd is not supported
  if s:check(a:cmd)
    if rename(expand("<afile>"), expand("<afile>:r")) == 0
      call system(a:cmd . " " . expand("<afile>:r"))
    endif
  endif
endfun

" Before appending to compressed file: Uncompress file with "cmd"
fun s:appre(cmd)
  " don't do anything if the cmd is not supported
  if s:check(a:cmd)
    call system(a:cmd . " " . expand("<afile>"))
    call rename(expand("<afile>:r"), expand("<afile>"))
  endif
endfun

" vim: set sw=2 :
