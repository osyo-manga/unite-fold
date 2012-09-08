scriptencoding utf-8

function! unite#sources#fold#define()
	return s:source
endfunction

function! s:create_foldlist_item(lnum)
	return {'line': getline(a:lnum), 'lnum': a:lnum, 'word': getline(a:lnum)}
endfunction

function! s:is_new_folding_start(lnum)
	if foldlevel(a:lnum) ==0
		return 0
	endif

	let fstart = foldclosed(a:lnum)
	if fstart == -1 " the fold is opened
		call cursor(a:lnum, 1)
		normal zc
		let fstart = foldclosed(a:lnum)
		normal zo
	endif
	return fstart == a:lnum
endfunction

function! s:foldlist(bufnr)
	if &foldmethod == 'marker'
		return filter(map(getbufline(a:bufnr, 1, "$"), '{ "line" : v:val, "lnum" : v:key+1 }'), "v:val.line =~ '^\".*'.split(&foldmarker, ',')[0]")
	else
		let orig_foldenable = &foldenable
		let orig_cursor = getpos('.')
		let lnum = 1
		let prev_flv = 0
		let lines = []
		while lnum <= line('$')
			let flv = foldlevel(lnum)
			if prev_flv < flv
				call add(lines, s:create_foldlist_item(lnum))
			elseif prev_flv == flv
				" prev_flv == flv
				" add to candidate if prev and current line is in different
				" folding
				if s:is_new_folding_start(lnum)
					call add(lines, s:create_foldlist_item(lnum))
				endif
			else
				" nothing
			endif
			let lnum += 1
			let prev_flv = flv
		endwhile
		let &foldenable = orig_foldenable
		call cursor(orig_cursor[1], orig_cursor[2], orig_cursor[3])
		return lines
	endif
endfunction


function! s:foldtext(bufnr, val)
	if has_key(a:val, 'word')
		return a:val.word
	else
		return matchstr(a:val.line, "\"\\s*\\zs.*\\ze".split(&foldmarker, ",")[0])
	end
endfunction

let g:Unite_fold_foldtext = get(g:, "Unite_fold_foldtext", function("s:foldtext"))
let g:unite_fold_indent_space = get(g:, "unite_fold_indent_space", "  ")


let s:source = {
\	"name" : "fold",
\	"description" : "show buffer fold list",
\}

function! s:source.gather_candidates(args, context)
	let bufnr = bufnr("%")
	return map(s:foldlist(bufnr), '{
\	"word" : repeat(g:unite_fold_indent_space, foldlevel(v:val.lnum)-1) . g:Unite_fold_foldtext(bufnr, v:val),
\	"source": "fold",
\	"kind": "jump_list",
\	"action__path": expand("%:p"),
\	"action__line": v:val.lnum,
\	}')
endfunction


