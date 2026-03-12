if has('multi_byte')
    let defaults = {'placeholder': '⟨⋯ ⟩', 'line': '▤ ', 'whole': '⭕ ',
\       'level': '⧚', 'division': '∕', 'multiplication': '×',
\       'epsilon': 'ε'}
else
    let defaults = {'placeholder': '<...>', 'line': 'L', 'whole': 'W',
\       'level': 'Z', 'division': '/', 'multiplication': '*',
\       'epsilon': '0'}
endif
let defaults['denominator'] = 25
let defaults['gap'] = 4

if !exists('g:FoldText_placeholder')
    let g:FoldText_placeholder = defaults['placeholder']
endif
if !exists('g:FoldText_line')
    let g:FoldText_line = defaults['line']
endif
if !exists('g:FoldText_whole')
    let g:FoldText_whole = defaults['whole']
endif
if !exists('g:FoldText_level')
    let g:FoldText_level = defaults['level']
endif
if !exists('g:FoldText_division')
    let g:FoldText_division = defaults['division']
endif
if !exists('g:FoldText_multiplication')
    let g:FoldText_multiplication = defaults['multiplication']
endif
if !exists('g:FoldText_epsilon')
    let g:FoldText_epsilon = defaults['epsilon']
endif
if !exists('g:FoldText_denominator')
    let g:FoldText_denominator = defaults['denominator']
endif
if g:FoldText_denominator >= &maxfuncdepth
    let g:FoldText_denominator = &maxfuncdepth - 1
endif
if !exists('g:FoldText_gap')
    let g:FoldText_gap = defaults['gap']
endif

unlet defaults

set foldtext=foldtext#FoldText()
