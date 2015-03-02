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
		normal! zc
		let fstart = foldclosed(a:lnum)
		normal! zo
	endif
	return fstart == a:lnum
endfunction

function! s:foldmarker_begin(bufnr)
        let buf_winnr = bufwinnr(a:bufnr)
        if buf_winnr != -1
                let foldmarker_begin = split(getwinvar(buf_winnr, '&foldmarker'), ',')[0]
        else
                let foldmarker_begin = split(&foldmarker, ',')[0]
        endif
        return foldmarker_begin
endfunction

function! s:comment_begin(bufnr)
        let [comment_begin, comment_end] = split(getbufvar(a:bufnr, "&commentstring"), '\V\C%s', 1)
        return comment_begin
endfunction

function! s:foldlist(bufnr)
	if &foldmethod == 'marker'
                let comment_begin    = s:comment_begin(a:bufnr)
                let foldmarker_begin = s:foldmarker_begin(a:bufnr)
                return filter(map(getbufline(a:bufnr, 1, "$"),
                        \ '{ "line" : v:val, "lnum" : v:key+1 }'),
                        \ "v:val.line =~ '\\V\\_^\\s\\*' . comment_begin . '\\.\\*' . foldmarker_begin . '\\d'")
	else
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
		call cursor(orig_cursor[1], orig_cursor[2], orig_cursor[3])
		return lines
	endif
endfunction


function! s:foldtext(bufnr, val)
	if has_key(a:val, 'word')
		return a:val.word
	else
                let comment_begin    = s:comment_begin(a:bufnr)
                let foldmarker_begin = s:foldmarker_begin(a:bufnr)
		return matchstr(a:val.line,
                    \ '\V' . comment_begin .  '\s\*\zs\.\*\ze' . foldmarker_begin)
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
	try
		let orig_foldenable = &foldenable
		let &foldenable = 1
		return map(s:foldlist(bufnr), '{
\		"word" : repeat(g:unite_fold_indent_space, foldlevel(v:val.lnum)-1) . g:Unite_fold_foldtext(bufnr, v:val),
\		"source": "fold",
\		"kind": "jump_list",
\		"action__path": expand("%:p"),
\		"action__line": v:val.lnum,
\		}')
	finally
		let &foldenable = orig_foldenable
	endtry
endfunction


