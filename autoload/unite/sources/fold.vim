scriptencoding utf-8

function! unite#sources#fold#define()
	return s:source
endfunction


function! s:foldlist(bufnr)
	return filter(map(getbufline(a:bufnr, 1, "$"), '{ "line" : v:val, "lnum" : v:key+1 }'), "v:val.line =~ '^\".*'.split(&foldmarker, ',')[0]")
endfunction


function! s:foldtext(bufnr, lnum, line)
	return matchstr(a:line, "\"\\s*\\zs.*\\ze".split(&foldmarker, ",")[0])
endfunction

let g:Unite_fold_foldtext = get(g:, "unite_fold_foldtext", function("s:foldtext"))
let g:unite_fold_indent_space = get(g:, "unite_fold_indent_space", "  ")


let s:source = {
\	"name" : "fold",
\	"description" : "show buffer fold list",
\}

function! s:source.gather_candidates(args, context)
	let bufnr = bufnr("%")
	return map(s:foldlist(bufnr), '{
\	"word" : repeat(g:unite_fold_indent_space, foldlevel(v:val.lnum)-1) . g:Unite_fold_foldtext(bufnr, v:val.lnum, v:val.line),
\	"source": "fold",
\	"kind": "jump_list",
\	"action__path": expand("%:p"),
\	"action__line": v:val.lnum,
\	}')
endfunction


