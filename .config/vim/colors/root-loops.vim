" Store the following config under ~/.vim/colors/root-loops.vim
" then load it into vim via ':colorscheme root-loops' or by declaring
" it as your colorscheme in your .vimrc.

" root-loops.vim -- Root Loops Vim Color Scheme.
" Webpage:          https://rootloops.sh
" Description:      A vim color scheme for cereal lovers

hi clear

if exists("syntax_on")
    syntax reset
endif

let colors_name = "root loops"

if ($TERM =~ '256' || &t_Co >= 256) || has("gui_running")
    hi Normal ctermbg=NONE ctermfg=NONE guibg=NONE guifg=NONE
    hi NonText ctermfg=0 guifg=#e2e2e2
    hi Comment ctermfg=8 cterm=italic guifg=#ababab gui=italic
    hi Constant ctermfg=3 guifg=#c88953
    hi Error ctermfg=1 guifg=#d87595
    hi Identifier ctermfg=9 guifg=#e592ab
    hi Function ctermfg=4 guifg=#5ba1d0
    hi Special ctermfg=13 guifg=#b8a0e4
    hi Statement ctermfg=5 guifg=#a586d9
    hi String ctermfg=2 guifg=#90a254
    hi Operator ctermfg=6 guifg=#55aa9b
    hi Boolean ctermfg=3 guifg=#c88953
    hi Label ctermfg=14 guifg=#67c1b0
    hi Keyword ctermfg=5 guifg=#a586d9
    hi Exception ctermfg=5 guifg=#a586d9
    hi Conditional ctermfg=5 guifg=#a586d9
    hi PreProc ctermfg=13 guifg=#b8a0e4
    hi Include ctermfg=5 guifg=#a586d9
    hi Macro ctermfg=5 guifg=#a586d9
    hi StorageClass ctermfg=11 guifg=#dd9f6b
    hi Structure ctermfg=11 guifg=#dd9f6b
    hi Todo ctermbg=12 ctermfg=0 cterm=bold guibg=#78b6e2 guifg=#f1f1f1 gui=bold
    hi Type ctermfg=11 guifg=#dd9f6b
    hi Underlined cterm=underline gui=underline
    hi Bold cterm=bold gui=bold
    hi Italic cterm=italic gui=italic
    hi Ignore ctermbg=NONE ctermfg=NONE cterm=NONE guibg=NONE guifg=NONE gui=NONE
    hi StatusLine ctermbg=0 ctermfg=15 cterm=NONE guibg=#e2e2e2 guifg=#3a3a3a gui=NONE
    hi StatusLineNC ctermbg=0 ctermfg=15 cterm=NONE guibg=#f1f1f1 guifg=#222222 gui=NONE
    hi VertSplit ctermfg=8 guifg=#ababab
    hi TabLine ctermbg=0 ctermfg=7 guibg=#e2e2e2 guifg=#6a6a6a
    hi TabLineFill ctermbg=NONE ctermfg=0 guibg=NONE guifg=#e2e2e2
    hi TabLineSel ctermbg=11 ctermfg=0 guibg=#dd9f6b guifg=#e2e2e2
    hi Title ctermfg=4 cterm=bold guifg=#5ba1d0 gui=bold
    hi CursorLine ctermbg=0 ctermfg=NONE guibg=#e2e2e2 guifg=NONE
    hi Cursor ctermbg=15 ctermfg=0 guibg=#3a3a3a guifg=#f1f1f1
    hi CursorColumn ctermbg=0 guibg=#e2e2e2
    hi LineNr ctermfg=8 guifg=#ababab
    hi CursorLineNr ctermfg=6 guifg=#55aa9b
    hi helpLeadBlank ctermbg=NONE ctermfg=NONE guibg=NONE guifg=NONE
    hi helpNormal ctermbg=NONE ctermfg=NONE guibg=NONE guifg=NONE
    hi Visual ctermbg=8 ctermfg=15 cterm=bold guibg=#ababab guifg=#3a3a3a gui=bold
    hi VisualNOS ctermbg=8 ctermfg=15 cterm=bold guibg=#ababab guifg=#3a3a3a gui=bold
    hi Pmenu ctermbg=0 ctermfg=15 guibg=#e2e2e2 guifg=#3a3a3a
    hi PmenuSbar ctermbg=8 ctermfg=7 guibg=#ababab guifg=#6a6a6a
    hi PmenuSel ctermbg=8 ctermfg=15 cterm=bold guibg=#ababab guifg=#3a3a3a gui=bold
    hi PmenuThumb ctermbg=7 ctermfg=NONE guibg=#6a6a6a guifg=NONE
    hi FoldColumn ctermfg=7 guifg=#6a6a6a
    hi Folded ctermfg=12 guifg=#78b6e2
    hi WildMenu ctermbg=0 ctermfg=15 cterm=NONE guibg=#e2e2e2 guifg=#3a3a3a gui=NONE
    hi SpecialKey ctermfg=0 guifg=#e2e2e2
    hi IncSearch ctermbg=1 ctermfg=0 guibg=#d87595 guifg=#f1f1f1
    hi CurSearch ctermbg=3 ctermfg=0 guibg=#c88953 guifg=#f1f1f1
    hi Search ctermbg=11 ctermfg=0 guibg=#dd9f6b guifg=#f1f1f1
    hi Directory ctermfg=4 guifg=#5ba1d0
    hi MatchParen ctermbg=0 ctermfg=3 cterm=bold guibg=#e2e2e2 guifg=#c88953 gui=bold
    hi SpellBad cterm=undercurl gui=undercurl guisp=#e592ab
    hi SpellCap cterm=undercurl gui=undercurl guisp=#dd9f6b
    hi SpellLocal cterm=undercurl gui=undercurl guisp=#78b6e2
    hi SpellRare cterm=undercurl gui=undercurl guisp=#a5b966
    hi ColorColumn ctermbg=8 guibg=#ababab
    hi SignColumn ctermfg=7 guifg=#6a6a6a
    hi ModeMsg ctermbg=15 ctermfg=0 cterm=bold guibg=#222222 guifg=#e2e2e2 gui=bold
    hi MoreMsg ctermfg=4 guifg=#5ba1d0
    hi Question ctermfg=4 guifg=#5ba1d0
    hi QuickFixLine ctermbg=0 ctermfg=14 guibg=#e2e2e2 guifg=#67c1b0
    hi Conceal ctermfg=8 guifg=#ababab
    hi ToolbarLine ctermbg=0 ctermfg=15 guibg=#e2e2e2 guifg=#222222
    hi ToolbarButton ctermbg=8 ctermfg=15 guibg=#ababab guifg=#222222
    hi debugPC ctermfg=7 guifg=#6a6a6a
    hi debugBreakpoint ctermfg=8 guifg=#ababab
    hi ErrorMsg ctermfg=1 cterm=bold,italic guifg=#d87595 gui=bold,italic
    hi WarningMsg ctermfg=11 guifg=#dd9f6b
    hi DiffAdd ctermbg=10 ctermfg=0 guibg=#a5b966 guifg=#f1f1f1
    hi DiffChange ctermbg=12 ctermfg=0 guibg=#78b6e2 guifg=#f1f1f1
    hi DiffDelete ctermbg=9 ctermfg=0 guibg=#e592ab guifg=#f1f1f1
    hi DiffText ctermbg=14 ctermfg=0 guibg=#67c1b0 guifg=#f1f1f1
    hi diffAdded ctermfg=10 guifg=#a5b966
    hi diffRemoved ctermfg=9 guifg=#e592ab
    hi diffChanged ctermfg=12 guifg=#78b6e2
    hi diffOldFile ctermfg=11 guifg=#dd9f6b
    hi diffNewFile ctermfg=13 guifg=#b8a0e4
    hi diffFile ctermfg=12 guifg=#78b6e2
    hi diffLine ctermfg=7 guifg=#6a6a6a
    hi diffIndexLine ctermfg=14 guifg=#67c1b0

elseif &t_Co == 8 || $TERM !~# '^linux' || &t_Co == 16
    set t_Co=16
    hi Normal ctermbg=NONE ctermfg=NONE
    hi NonText ctermfg=0
    hi Comment ctermfg=8 cterm=italic
    hi Constant ctermfg=3
    hi Error ctermfg=1
    hi Identifier ctermfg=9
    hi Function ctermfg=4
    hi Special ctermfg=13
    hi Statement ctermfg=5
    hi String ctermfg=2
    hi Operator ctermfg=6
    hi Boolean ctermfg=3
    hi Label ctermfg=14
    hi Keyword ctermfg=5
    hi Exception ctermfg=5
    hi Conditional ctermfg=5
    hi PreProc ctermfg=13
    hi Include ctermfg=5
    hi Macro ctermfg=5
    hi StorageClass ctermfg=11
    hi Structure ctermfg=11
    hi Todo ctermbg=12 ctermfg=0 cterm=bold
    hi Type ctermfg=11
    hi Underlined cterm=underline
    hi Bold cterm=bold
    hi Italic cterm=italic
    hi Ignore ctermbg=NONE ctermfg=NONE cterm=NONE
    hi StatusLine ctermbg=0 ctermfg=15 cterm=NONE
    hi StatusLineNC ctermbg=0 ctermfg=15 cterm=NONE
    hi VertSplit ctermfg=8
    hi TabLine ctermbg=0 ctermfg=7
    hi TabLineFill ctermbg=NONE ctermfg=0
    hi TabLineSel ctermbg=11 ctermfg=0
    hi Title ctermfg=4 cterm=bold
    hi CursorLine ctermbg=0 ctermfg=NONE
    hi Cursor ctermbg=15 ctermfg=0
    hi CursorColumn ctermbg=0
    hi LineNr ctermfg=8
    hi CursorLineNr ctermfg=6
    hi helpLeadBlank ctermbg=NONE ctermfg=NONE
    hi helpNormal ctermbg=NONE ctermfg=NONE
    hi Visual ctermbg=8 ctermfg=15 cterm=bold
    hi VisualNOS ctermbg=8 ctermfg=15 cterm=bold
    hi Pmenu ctermbg=0 ctermfg=15
    hi PmenuSbar ctermbg=8 ctermfg=7
    hi PmenuSel ctermbg=8 ctermfg=15 cterm=bold
    hi PmenuThumb ctermbg=7 ctermfg=NONE
    hi FoldColumn ctermfg=7
    hi Folded ctermfg=12
    hi WildMenu ctermbg=0 ctermfg=15 cterm=NONE
    hi SpecialKey ctermfg=0
    hi IncSearch ctermbg=1 ctermfg=0
    hi CurSearch ctermbg=3 ctermfg=0
    hi Search ctermbg=11 ctermfg=0
    hi Directory ctermfg=4
    hi MatchParen ctermbg=0 ctermfg=3 cterm=bold
    hi SpellBad cterm=undercurl
    hi SpellCap cterm=undercurl
    hi SpellLocal cterm=undercurl
    hi SpellRare cterm=undercurl
    hi ColorColumn ctermbg=8
    hi SignColumn ctermfg=7
    hi ModeMsg ctermbg=15 ctermfg=0 cterm=bold
    hi MoreMsg ctermfg=4
    hi Question ctermfg=4
    hi QuickFixLine ctermbg=0 ctermfg=14
    hi Conceal ctermfg=8
    hi ToolbarLine ctermbg=0 ctermfg=15
    hi ToolbarButton ctermbg=8 ctermfg=15
    hi debugPC ctermfg=7
    hi debugBreakpoint ctermfg=8
    hi ErrorMsg ctermfg=1 cterm=bold,italic
    hi WarningMsg ctermfg=11
    hi DiffAdd ctermbg=10 ctermfg=0
    hi DiffChange ctermbg=12 ctermfg=0
    hi DiffDelete ctermbg=9 ctermfg=0
    hi DiffText ctermbg=14 ctermfg=0
    hi diffAdded ctermfg=10
    hi diffRemoved ctermfg=9
    hi diffChanged ctermfg=12
    hi diffOldFile ctermfg=11
    hi diffNewFile ctermfg=13
    hi diffFile ctermfg=12
    hi diffLine ctermfg=7
    hi diffIndexLine ctermfg=14
endif

hi link EndOfBuffer NonText
hi link SpecialComment Special
hi link Define PreProc
hi link PreCondit PreProc
hi link Number Constant
hi link Float Number
hi link Typedef Type
hi link SpecialChar Special
hi link Debug Special
hi link StatusLineTerm StatusLine
hi link StatusLineTermNC StatusLineNC
hi link WinSeparator VertSplit
hi link WinBar StatusLine
hi link WinBarNC StatusLineNC
hi link lCursor Cursor
hi link CursorIM Cursor
hi link Terminal Normal

if (has('termguicolors') && &termguicolors) || has('gui_running')
    let g:terminal_ansi_colors = [ '#e2e2e2', '#d87595', '#90a254', '#c88953', '#5ba1d0', '#a586d9', '#55aa9b', '#6a6a6a', '#ababab', '#e592ab', '#a5b966', '#dd9f6b', '#78b6e2', '#b8a0e4', '#67c1b0', '#222222' ]
endif
