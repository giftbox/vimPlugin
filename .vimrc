if(has("win32") || has("win95") || has("win64") || has("win16")) "判定当前操作系统类型
    let g:iswindows=1
else
    let g:iswindows=0
endif

if(g:iswindows==1) 
    if has('mouse')
        set mouse=a "允许鼠标的使用
    endif
    "au GUIEnter * simalt ~x "窗口最大化，仅Win下有作用
endif

set nocompatible "不要vim模仿vi模式，建议设置，否则会有很多不兼容的问题
nmap <Up> <NOP>
nmap <Down> <NOP>
nmap <Left> <NOP>
nmap <Right> <NOP>

colo desert "设置配色方案
set guioptions=r "隐藏菜单、工具栏
set gcr=a:blinkoff600-blinkon600 "调整光标闪烁
set fileencodings=utf-8,gbk,gb18030,utf-16,big5 "设置载入文件时如何选择字符集
set vb t_vb= "当vim进行编辑时，如果命令错误，会发出警报，以下三个设置去掉警报
set noerrorbells
set novisualbell

set nu "显示行号
set history=400 "设置记录的历史数
set nowrap "不自动换行
set tabstop=4 "让一个tab等于4个空格
set softtabstop=4
set shiftwidth=4
set expandtab "用空格代替制表符
set hlsearch "高亮显示结果
set ignorecase "搜索/补全时忽略大小写
set incsearch "在输入要搜索的文字时，vim会实时匹配
set backspace=indent,eol,start "允许退格键的使用
"set whichwrap+=<,>,[,] "允许退格键和光标跨行边界

filetype on "开启文件类型检测
filetype plugin on "根据文件类型加载插件
filetype indent on "根据文件类型定义不同的缩进，对c文件只是打开cindent
syntax on "打开高亮
"防止退出插入模式时光标左移一位
inoremap <ESC> <ESC>`^

"增加标准库的tags，通过 ctags -R --sort=1 --c++-kinds=+p --fields=+iaS --extra=+q --language-force=c++ /usr/include/* 得到
set tags+=~/.vim/tags/std_tags

"""""""""""autocmd""""""""""

if has("autocmd")
	"插入模式时光标变成小竖线，gvim自带属性，仅对命令行vim有效
	"autocmd InsertEnter * silent execute "!gconftool-2 --type string --set /apps/gnome-terminal/profiles/Default/cursor_shape ibeam"
	"autocmd InsertLeave * silent execute "!gconftool-2 --type string --set /apps/gnome-terminal/profiles/Default/cursor_shape block"
	"autocmd VimLeave * silent execute "!gconftool-2 --type string --set /apps/gnome-terminal/profiles/Default/cursor_shape block"

	"进入一个buffer时，自动更改到对应目录
	autocmd BufEnter * lcd %:p:h 

	"对text文件，设置文本宽度，与warp不同，这里会自动插入换行符
	autocmd FileType text setlocal textwidth=78 

	"打开文件时，跳到上次编辑的位置
	autocmd BufReadPost * 
                    \ if line("'\"") > 1 && line("'\"") <= line("$") |
                    \ exe "normal! g`\"" |
                    \ endif
endif

""""""""""设置在当前目录下生成并加载ctags和cscope""""""""""
""""""""""或加载整个项目通过脚本makecscope（利用绝对路径）生成的ctags和cscope""""""""""

map <C-F12> :call Do_CurDir_CsTag()<CR>
map <F12> :call Load_Project_CsTag()<CR>

function Clear_CurDir_CsTag()
    let dir = getcwd()
	"删除当前路径下tags文件
    if filereadable("tags")
        if(g:iswindows==1)
            let tagsdeleted=delete(dir."\\"."tags")
        else
            let tagsdeleted=delete("./"."tags")
        endif
        if(tagsdeleted!=0)
            echohl WarningMsg | echo "Fail to do tags! I cannot delete the tags" | echohl None
            return
        endif
    endif
	"解绑当前所有cscope文件
    if has("cscope")
        silent! execute "cs kill -1"
    endif
	"删除当前路径下cscope.files文件
    if filereadable("cscope.files")
        if(g:iswindows==1)
            let csfilesdeleted=delete(dir."\\"."cscope.files")
        else
            let csfilesdeleted=delete("./"."cscope.files")
        endif
        if(csfilesdeleted!=0)
            echohl WarningMsg | echo "Fail to do cscope! I cannot delete the cscope.files" | echohl None
            return
        endif
    endif
	"删除当前路径下cscope.out文件
    if filereadable("cscope.out")
        if(g:iswindows==1)
            let csoutdeleted=delete(dir."\\"."cscope.out")
        else
            let csoutdeleted=delete("./"."cscope.out")
        endif
        if(csoutdeleted!=0)
            echohl WarningMsg | echo "Fail to do cscope! I cannot delete the cscope.out" | echohl None
            return
        endif
    endif
endfunction

function Do_CurDir_CsTag()
	call Clear_CurDir_CsTag()
    let dir = getcwd()
	"生成新的tags文件，并加载
    if(executable('ctags'))
        "silent! execute "!ctags -R --c-types=+p --fields=+S *"
        silent! execute "!ctags -R --sort=1 --c++-kinds=+pl --fields=+iaS --extra=+q ."
    endif
	"生成新的cscope.file cscope.out文件，并加载
    if(executable('cscope') && has("cscope") )
        if(g:iswindows!=1)
            silent! execute "!find . -name '*.h' -o -name '*.c' -o -name '*.cpp' -o -name '*.hpp' -o -name 'Makefile' -o -name 'makefile' > cscope.files"
        else
            silent! execute "!dir /s/b *.c,*.cpp,*.h,*.hpp,Makefile,makefile >> cscope.files"
        endif
        silent! execute "!cscope -Rb"
        execute "normal :"
        if filereadable("cscope.out")
            execute "cs add cscope.out"
        endif
    endif
endfunction

function Load_Project_CsTag()
	call Clear_CurDir_CsTag()
	"加载总项目的tags文件
    if(executable('ctags'))
        set tags+=~/.vim/tags/current_tags
    endif
	"加载总项目的cscope.out文件
    if(executable('cscope') && has("cscope") )
        execute "cs add ~/.vim/cscope/current/cscope.out"
        execute "normal :"
    endif
endfunction

""""""""""设置cscope开启定位功能""""""""""

if has("cscope")
    set cst "与ctags使用相同快捷键 Ctrl+]  和 Ctrl+t 在代码间跳转
    set csto=0 "如果你想反向搜索顺序设置为1
	set cscopeverbose "添加数据库后打印信息

    "快捷键设置
    nmap <C-\>s :cs find s <C-R>=expand("<cword>")<CR><CR> "查找代码符号
    nmap <C-\>g :cs find g <C-R>=expand("<cword>")<CR><CR> "查找本定义
    nmap <C-\>c :cs find c <C-R>=expand("<cword>")<CR><CR> "查找调用本函数的函数
    nmap <C-\>t :cs find t <C-R>=expand("<cword>")<CR><CR> "查找本字符串
    nmap <C-\>e :cs find e <C-R>=expand("<cword>")<CR><CR> "查找本egrep模式
    nmap <C-\>f :cs find f <C-R>=expand("<cfile>")<CR><CR> "查找本文件
    nmap <C-\>i :cs find i ^<C-R>=expand("<cfile>")<CR>$<CR> "查找包含本文件的文件
    nmap <C-\>d :cs find d <C-R>=expand("<cword>")<CR><CR> "查找本函数调用的函数
endif

"""""""""""设置快捷键调出taglist显示函数列表"""""""""""

"进行Tlist的设置
"TlistUpdate可以更新tags
"按下F3呼出
map <F3> :silent! Tlist<CR> 
let Tlist_Ctags_Cmd='ctags' "因为ctags放在环境变量里，所以可以直接执行
let Tlist_Use_Right_Window=1 "让窗口显示在右边，0的话就是显示在左边
let Tlist_Show_One_File=1 "让taglist可以同时展示多个文件的函数列表，如果想只有1个，设置为1
let Tlist_File_Fold_Auto_Close=0 "非当前文件，函数列表折叠隐藏
let Tlist_Exit_OnlyWindow=1 "当taglist是最后一个分割窗口时，自动推出vim
let Tlist_Process_File_Always=0 "是否一直处理tags，1处理、0不处理。不是一直实时更新tags，因为没有必要
let Tlist_Inc_Winwidth=0

"""""""""""设置快捷键调出nerd tree显示文件浏览器"""""""""""

"F2打开/关闭
map <F2> :NERDTreeMirror<cr> 
map <F2> :NERDTreeToggle<cr> 
let NERDTreeIgnore=['\.m4','\.sh','\.log','\.in','\.sdf','\.sln','\.old','\.suo','\.vcxproj','\.vcproj','\.filters','\.user','\.am','\.in','\.o','\.lo','\.la','\.lib']

"""""""""""设置clang_complete自动补全""""""""""

set completeopt=menu,menuone,longest "关闭补全时的预览窗口
set complete=.,i "控制ctrl+n补全的列表索引顺序.,w,b,t,i (当前、其他窗口、其他buffer、tags、包含头文件中)
let g:clang_close_preview=1 "补全完毕后自动关闭预览
let g:clang_hl_errors=1 "下划线显示语法错误
let g:clang_auto_select=1 "自动选择弹出窗口第一行
let g:clang_periodic_quickfix=0 "按周期刷新语法错误
let g:clang_snippets=1 "自动列出函数中参数列表
let g:clang_complete_macros=1 "宏补全

"手动调用编译器刷新语法错误
map <F5> :call Smart_Save()<CR>

function Smart_Save()
	"保存先
	exec "w" 
	if &filetype =='c' || &filetype == 'cpp'
		call g:ClangUpdateQuickFix()
	endif
endfunction

"""""""""""设置autocomplpop自动弹出补全窗口策略""""""""""

let g:acp_completeOption='.,i'

