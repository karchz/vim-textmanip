" Memo:
"         l_cut/add           r_cut/add
"                 |           |
"                 V           V        _.data index
"                +-+---------+-+----      0
"   u_cut/add -> +-+         +-+   ^      |
"                |             |   |      |
"                |             |  height  |
"                |             |   |      |
"                +-+         +-+   V      N
"   d_cut/add -> +-+---------+-+ ---   len(_.data)
"                |             |
"                +<-- width -->+

let s:u = textmanip#util#get()

function! s:height(val) "{{{1
  return len(a:val)
endfunction

function! s:width(val) "{{{1
  return len(a:val[0])
endfunction
"}}}

let s:Area = {}
function! s:Area.new(data) "{{{1
  " data is array of string
  "  ex) [ 'string1', 'string2'...]
  "
  " and `_data` is only state this object keep.
  " So we dont' need deepcopy, shallow copy is ok here.
  let o = copy(self)
  let o._data = a:data
  return o
endfunction

function! s:Area.data(...) "{{{1
  if a:0
    let self._data = a:1
  endif
  return self._data
endfunction

function! s:Area.height() "{{{1
  return len(self.data())
endfunction

function! s:Area.is_empty() "{{{1
  return empty(self.data())
endfunction

function! s:Area.width() "{{{1
  " assume all data have same width, so this function is useless!
  " FIXME should delete this function?
  return len(self.data()[0])
endfunction

function! s:Area.dump() "{{{1
  return PP(self.data())
endfunction

" add
function! s:Area.add(dir, val) "{{{1
  let lis = type(a:val) ==# 3 ? a:val : [a:val]

  if a:dir is '^'
    call self.data(lis + self.data())
    return self
  endif

  if a:dir is 'v'
    call self.data(self.data() + lis) 
    return self
  endif

  if self.is_empty()
    call self.data(lis)
    return self
  endif

  if a:dir is '<'
    cal map(self.data(), 'lis[v:key] . v:val')
    return self
  endif

  if a:dir is '>'
    call map(self.data(), 'v:val . lis[v:key]')
    return self
  endif

  call Plog(a:dir)
  throw 'never happen!'
endfunction


" cut
function! s:Area.cut(dir, n) "{{{1
  " n: number of cut

  if a:dir is '^'
    let end = min([a:n, self.height()]) - 1
    return remove(self.data(), 0, end)
  endif

  if a:dir is 'v'
    let last = self.height()
    return remove(self.data(), last-a:n, last-1)
  endif

  if a:dir is '<'
    let R = map(copy(self.data()), 'v:val[ : a:n-1]')
    call map(self.data(), 'v:val[a:n :]')
    return R
  endif

  if a:dir is '>'
    let R = map(copy(self.data()), 'v:val[-a:n : -1]')
    call map(self.data(), 'v:val[:-a:n-1]')
    return R
  endif

  " call Plog(a:dir)
  throw 'never happen!'
endfunction

" swap
function! s:Area.swap(dir, val) "{{{1
  let n = s:u.toward(a:dir) is '^v' ? s:height(a:val) : s:width(a:val)
  let R = self.cut(a:dir, n)
  call self.add(a:dir, a:val)
  return R
endfunction

" pushout
function! s:Area.pushout(dir, val) "{{{1
  let n = s:u.toward(a:dir) is '^v' ? s:height(a:val) : s:width(a:val)
  call self.add(a:dir, a:val)
  return self.cut(s:u.opposite(a:dir), n)
endfunction

" rotate
function! s:Area.rotate(dir, n)
  call self.add(
        \ s:u.opposite(a:dir), self.cut(a:dir, a:n))
  return self
endfunction

" duplcate vertical/horizontal(=side)
function! s:Area.duplicate(dir, n) "{{{1
  if a:dir =~# '\^\|v' " vertical
    call self.data(repeat(self.data(), a:n))
    return self
  endif

  if a:dir =~# '>\|<' " horizontal
    " horizontal, map have side effect, so no need to updata with data()
    call map(self.data(), 'repeat(v:val, a:n)')
    return self
  endif
  throw 'never happen!'
endfunction
"}}}

" Public:
function! textmanip#area#new(data) "{{{1
  return s:Area.new(a:data)
endfunction
" vim: foldmethod=marker
