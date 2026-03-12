" autoload/foldtext.vim - Autoloaded foldtext functions
" Maintainer: Phong Nguyen

function! s:FractionsBetween(lo, hi, denominator) abort
    " Find all fractions between [a, b] and [c, d] with denominator equal
    " to `a:denominator'
    let l:lo = a:lo[0] / a:lo[1]
    let l:hi = a:hi[0] / a:hi[1]
    let l:fractions = []
	let l:n = 1.0
	while l:n < a:denominator
        let l:p = l:n / a:denominator
        if l:p > l:lo && l:p < l:hi
            call add(l:fractions, [l:n, a:denominator])
        endif
	   let l:n += 1
	endwhile
    return l:fractions
endfunction

function! s:FractionSearch(proportion, denominator) abort
    " Search for the nearest fraction, used by s:FractionNearest().
    if a:denominator == 1
        return [[0.0, 1], [1.0, 1]]
    endif

    let [l:lo, l:hi] = s:FractionSearch(a:proportion, a:denominator - 1)
    let l:fractionsBetween = s:FractionsBetween(l:lo, l:hi, a:denominator)
    for l:fraction in l:fractionsBetween
        let l:f = l:fraction[0] / l:fraction[1]
        if a:proportion >= l:f
            let l:lo = l:fraction
        else
            let l:hi = l:fraction
            break
        endif
    endfor
    return [l:lo, l:hi]
endfunction

function! s:FractionNearest(proportion, maxDenominator) abort
    " Find the neareset fraction to `a:proportion' (which is a float),
    " but using fractions with denominator less than `a:maxDenominator'.
    let [l:lo, l:hi] = s:FractionSearch(a:proportion, a:maxDenominator)
    let l:mid = (l:lo[0] / l:lo[1] + l:hi[0] / l:hi[1]) / 2
    if a:proportion > l:mid
        return l:hi
    else
        return l:lo
    endif
endfunction

function! s:FractionFormat(fraction) abort
    " Format a fraction: [a, b] --> 'a/b'
    let [l:n, l:d] = a:fraction
    if l:n == 0.0
        return g:FoldText_epsilon
    endif
    if l:d != 1
        return printf("%.0f%s%d", l:n, g:FoldText_division, l:d)
    endif
    return printf("%.0f", l:n)
endfunction

function! s:CalculateSignColumnWidth() abort
    if has('signs')
        if !empty(sign_getplaced(bufname('%'), { 'group': '*' })[0]['signs'])
            return 2
        elseif &signcolumn == 'yes'
            return 2
        endif
    endif
    return 0
endfunction

function! foldtext#FoldText() abort
    " Returns a line representing the folded text
    "
    " A fold across the following:
    "
    " fu! MyFunc()
    "    call Foo()
    "    echo Bar()
    " endfu
    "
    " should, in general, produce something like:
    "
    " fu! MyFunc() <...> endfu                    L*15 O*2/5 Z*2
    "
    " The folded line has the following components:
    "
    "   - <...>           the folded text, but squashed;
    "   - endfu           the last line (where applicable);
    "   - L*15            the number of lines folded (including first);
    "   - O*2/5           the fraction of the whole file folded;
    "   - Z*2             the fold level of the fold.
    "
    " You may also define any of the following strings:
    "
    " let g:FoldText_placeholder = '<...>'
    " let g:FoldText_line = 'L'
    " let g:FoldText_level = 'Z'
    " let g:FoldText_whole = 'O'
    " let g:FoldText_division = '/'
    " let g:FoldText_multiplication = '*'
    " let g:FoldText_epsilon = '0'
    " let g:FoldText_denominator = 25
    "
    let l:fs = v:foldstart
    while getline(l:fs) =~ '^\s*$'
        let l:fs = nextnonblank(l:fs + 1)
    endwhile
    if l:fs > v:foldend
        let l:line = getline(v:foldstart)
    else
        let l:spaces = repeat(' ', &tabstop)
        let l:line = substitute(getline(l:fs), '\t', l:spaces, 'g')
    endif
 
    let l:foldEnding = strpart(getline(v:foldend), indent(v:foldend), 3)

    let l:endBlockChars = ['end', '}', ']', ')']
    let l:endBlockRegex = printf('^\s*\(%s\);\?$', join(l:endBlockChars, '\|'))
    let l:endCommentRegex = '\s*\*/$'
    let l:startCommentBlankRegex = '\v^\s*/\*!?\s*$'

    if l:foldEnding =~ l:endBlockRegex
        let l:foldEnding = " " .. g:FoldText_placeholder .. " " .. l:foldEnding
    elseif l:foldEnding =~ l:endCommentRegex
        if getline(v:foldstart) =~ l:startCommentBlankRegex
            let l:nextLine = substitute(getline(v:foldstart + 1), '\v\s*\*', '', '')
            let l:line = l:line .. l:nextLine
        endif
        let l:foldEnding = " " .. g:FoldText_placeholder .. " " .. l:foldEnding
    else
        let l:foldEnding = " " .. g:FoldText_placeholder
    endif
    let l:foldColumnWidth = &foldcolumn ? 1 : 0
    let l:numberColumnWidth = &number ? strwidth(line('$')) : 0
    let l:signColumnWidth = s:CalculateSignColumnWidth()
    let l:width = winwidth(0) - l:foldColumnWidth - l:numberColumnWidth - g:FoldText_gap
    let l:width -= l:signColumnWidth

    let l:foldSize = 1 + v:foldend - v:foldstart
    let l:foldSizeStr = printf("%s%s%s", g:FoldText_line, g:FoldText_multiplication, l:foldSize)

    let l:foldLevelStr = g:FoldText_level .. g:FoldText_multiplication .. v:foldlevel .. " "

    let l:proportion = (l:foldSize * 1.0) / line("$")
    let l:foldFraction = s:FractionNearest(l:proportion, g:FoldText_denominator)
    let l:foldFractionStr = printf(" %s%s%s ", g:FoldText_whole, g:FoldText_multiplication, s:FractionFormat(l:foldFraction))
    let l:ending = l:foldSizeStr .. l:foldFractionStr .. l:foldLevelStr

    if strwidth(l:line .. l:foldEnding .. l:ending) >= l:width
        let l:line = strpart(l:line, 0, l:width - strwidth(l:foldEnding .. l:ending))
    endif

    let l:expansionStr = repeat(" ", g:FoldText_gap + l:width - strwidth(l:line .. l:foldEnding .. l:ending))
    return l:line .. l:foldEnding .. l:expansionStr .. l:ending
endfunction
