" Tests for the Tuple types

import './vim9.vim' as v9

func TearDown()
  " Run garbage collection after every test
  call test_garbagecollect_now()
endfunc

" Test for indexing a tuple
func Test_tuple_indexing()
  let lines =<< trim END
    VAR t = ('a', 'b', 'c')
    call assert_equal('a', t[0])
    call assert_equal('c', t[2])
    call assert_equal('c', t[-1])
    call assert_equal('a', t[-3])
  END
  call v9.CheckLegacyAndVim9Success(lines)

  let lines =<< trim END
    echo ('a', 'b', 'c')[3]
  END
  call v9.CheckLegacyAndVim9Failure(lines, [
        \ 'E1518: Tuple index out of range: 3',
        \ 'E1518: Tuple index out of range: 3',
        \ 'E1518: Tuple index out of range: 3'])

  let lines =<< trim END
    echo ('a', 'b', 'c')[-4]
  END
  call v9.CheckLegacyAndVim9Failure(lines, [
        \ 'E1518: Tuple index out of range: -4',
        \ 'E1518: Tuple index out of range: -4',
        \ 'E1518: Tuple index out of range: -4'])

  let lines =<< trim END
    call assert_equal(('b', 'c'), ('a', 'b', 'c')[1 : 5])
  END
  call v9.CheckLegacyAndVim9Success(lines)
endfunc

" Test for comparing tuples
func Test_tuple_compare()
  let lines =<< trim END
    call assert_false((1, 2) == (1, 3))
    call assert_true((1, 2) == (1, 2))
    call assert_true((1,) == (1,))
    call assert_true(() == ())
    call assert_false((1, 2) == (1, 2, 3))
    call assert_false((1, 2) == test_null_tuple())
    VAR t1 = (1, 2)
    VAR t2 = t1
    call assert_true(t1 == t2)
  END
  call v9.CheckLegacyAndVim9Success(lines)

  let lines =<< trim END
    echo (1.0, ) == 1.0
  END
  call v9.CheckLegacyAndVim9Failure(lines, [
        \ 'E1516: Can only compare Tuple with Tuple',
        \ 'E1072: Cannot compare tuple with float',
        \ 'E1072: Cannot compare tuple with float'])

  let lines =<< trim END
    echo 1.0 == (1.0,)
  END
  call v9.CheckLegacyAndVim9Failure(lines, [
        \ 'E1516: Can only compare Tuple with Tuple',
        \ 'E1072: Cannot compare float with tuple',
        \ 'E1072: Cannot compare float with tuple'])

  let lines =<< trim END
    echo (1, 2) =~ []
  END
  call v9.CheckLegacyAndVim9Failure(lines, [
        \ 'E691: Can only compare List with List',
        \ 'E1072: Cannot compare tuple with list',
        \ 'E1072: Cannot compare tuple with list'])

  let lines =<< trim END
    echo (1, 2) =~ (1, 2)
  END
  call v9.CheckLegacyAndVim9Failure(lines, [
        \ 'E1517: Invalid operation for Tuple',
        \ 'E1517: Invalid operation for Tuple',
        \ 'E1517: Invalid operation for Tuple'])
endfunc

" Test for locking and unlocking a tuple variable
func Test_tuple_lock()
  let lines =<< trim END
    VAR t = ([0, 1],)
    call add(t[0], 2)
    call assert_equal(([0, 1, 2], ), t)
  END
  call v9.CheckLegacyAndVim9Success(lines)

  let lines =<< trim END
    VAR t = ([0, 1],)
    lockvar 2 t
    call add(t[0], 2)
  END
  call v9.CheckLegacyAndVim9Failure(lines, [
        \ 'E741: Value is locked: add() argument',
        \ 'E1178: Cannot lock or unlock a local variable',
        \ 'E741: Value is locked: add() argument'])

  let lines =<< trim END
    LET g:t = ([0, 1],)
    lockvar 2 g:t
    unlockvar 2 g:t
    call add(g:t[0], 3)
    call assert_equal(([0, 1, 3], ), g:t)
    unlet g:t
  END
  call v9.CheckLegacyAndVim9Success(lines)

  let lines =<< trim END
    VAR t1 = (1, 2)
    const t2 = t1
    LET t2 = ()
  END
  call v9.CheckLegacyAndVim9Failure(lines, [
        \ 'E741: Value is locked: t2',
        \ 'E1018: Cannot assign to a constant: t2',
        \ 'E46: Cannot change read-only variable "t2"'])
endfunc

" Test for stridx()
func Test_tuple_stridx()
  let lines =<< trim END
    call stridx(('abc', ), 'a')
  END
  call v9.CheckLegacyAndVim9Failure(lines, [
        \ 'E1521: Using a Tuple as a String',
        \ 'E1013: Argument 1: type mismatch, expected string but got tuple<string>',
        \ 'E1174: String required for argument 1'])
endfunc

" Test for string()
func Test_tuple_string()
  let lines =<< trim END
    VAR t = (1, 'as''d', [1, 2, function("strlen")], {'a': 1}, )
    call assert_equal("(1, 'as''d', [1, 2, function('strlen')], {'a': 1})", string(t))

    #" empty tuple
    LET t = ()
    call assert_equal("()", string(t))

    #" one item tuple
    LET t = ("a", )
    call assert_equal("('a', )", string(t))

    call assert_equal("()", string(test_null_tuple()))
  END
  call v9.CheckLegacyAndVim9Success(lines)

  " recursive tuple
  let lines =<< trim END
    VAR l = []
    VAR t = (l,)
    call add(l, t)
    call assert_equal('([(...)], )', string(t))
  END
  call v9.CheckLegacyAndVim9Success(lines)
endfunc

" Test for sort()
func Test_tuple_sort()
  let lines =<< trim END
    call sort([1.1, (1.2,)], 'f')
  END
  call v9.CheckLegacyAndVim9Failure(lines, [
        \ 'E1520: Using a Tuple as a Float',
        \ 'E1520: Using a Tuple as a Float',
        \ 'E1520: Using a Tuple as a Float'])
endfunc

" Test for type()
func Test_tuple_type()
  let lines =<< trim END
    VAR t = (1, 2)
    call assert_equal(17, type(t))
    call assert_equal(v:t_tuple, type(t))
    call assert_equal(v:t_tuple, type(()))
    call assert_equal(v:t_tuple, type(test_null_tuple()))
  END
  call v9.CheckLegacyAndVim9Success(lines)
endfunc

" Test for typename()
func Test_tuple_typename()
  let lines =<< trim END
    call assert_equal('tuple<number>', typename((1, 2)))
    call assert_equal('tuple<string>', typename(('a', 'b')))
    call assert_equal('tuple<bool>', typename((v:true, v:true)))
    call assert_equal('tuple<any>', typename((1, 'b')))
    call assert_equal('tuple<any>', typename(()))
    call assert_equal('tuple<dict<any>>', typename(({}, )))
    call assert_equal('tuple<list<any>>', typename(([], )))
    call assert_equal('tuple<list<number>>', typename(([1, 2], )))
    call assert_equal('tuple<list<string>>', typename((['a', 'b'], )))
    call assert_equal('tuple<list<list<number>>>', typename(([[1], [2]], )))
    call assert_equal('tuple<tuple<number>>', typename(((1, 2), )))
    call assert_equal('list<tuple<number>>', typename([(1,)]))
    call assert_equal('list<tuple<any>>', typename([()]))
    call assert_equal('tuple<any>', typename(test_null_tuple()))
  END
  call v9.CheckLegacyAndVim9Success(lines)

  let lines =<< trim END
    # recursive tuple
    var l: list<tuple<any>> = []
    var t = (l,)
    add(l, t)
    assert_equal('tuple<list<tuple<any>>>', typename(t))
    assert_equal('list<tuple<any>>', typename(l))
  END
  call v9.CheckSourceDefAndScriptSuccess(lines)
endfunc

" Test for tuple identity
func Test_tuple_identity()
  let lines =<< trim END
    call assert_false((1, 2) is (1, 2))
    call assert_true((1, 2) isnot (1, 2))
    call assert_true((1, 2) isnot test_null_tuple())
    VAR t1 = ('abc', 'def')
    VAR t2 = t1
    call assert_true(t2 is t1)
    VAR t3 = (1, 2)
    call assert_false(t3 is t1)
  END
  call v9.CheckLegacyAndVim9Success(lines)
endfunc

" Test for add() with a tuple
func Test_tuple_add()
  let lines =<< trim END
    VAR t = (1, 2, 3)
    call add(t, 4)
  END
  call v9.CheckLegacyAndVim9Failure(lines, [
        \ 'E897: List or Blob required',
        \ 'E1013: Argument 1: type mismatch, expected list<any> but got tuple<number>',
        \ 'E1226: List or Blob required for argument 1'])
endfunc

" Test for copy()
func Test_tuple_copy()
  let lines =<< trim END
    VAR t1 = (['a', 'b'], ['c', 'd'], ['e', 'f'])
    VAR t2 = copy(t1)
    VAR t3 = t1
    call assert_false(t2 is t1)
    call assert_true(t3 is t1)
    call assert_true(t2[1] is t1[1])
    call assert_equal((), copy(()))
    call assert_equal((), copy(test_null_tuple()))
  END
  call v9.CheckLegacyAndVim9Success(lines)
endfunc

" Test for count()
func Test_tuple_count()
  let lines =<< trim END
    VAR t = ('ab', 'cd', 'ab')
    call assert_equal(2, count(t, 'ab'))
    call assert_equal(0, count(t, 'xx'))
    call assert_equal(0, count((), 'xx'))
    call assert_equal(0, count(test_null_tuple(), 'xx'))
    call assert_fails("call count((1, 2), 1, v:true, 2)", 'E1518: Tuple index out of range: 2')
  END
  call v9.CheckLegacyAndVim9Success(lines)
endfunc

" Test for deepcopy()
func Test_tuple_deepcopy()
  let lines =<< trim END
    VAR t1 = (['a', 'b'], ['c', 'd'], ['e', 'f'])
    VAR t2 = deepcopy(t1)
    VAR t3 = t1
    call assert_false(t2 is t1)
    call assert_true(t3 is t1)
    call assert_false(t2[1] is t1[1])
    call assert_equal((), deepcopy(()))
    call assert_equal((), deepcopy(test_null_tuple()))

    #" copy a recursive tuple
    VAR l = []
    VAR tuple = (l,)
    call add(l, tuple)
    call assert_equal('([(...)], )', string(deepcopy(tuple)))
  END
  call v9.CheckLegacyAndVim9Success(lines)
endfunc

" Test for empty()
func Test_tuple_empty()
  let lines =<< trim END
    call assert_true(empty(()))
    call assert_true(empty(test_null_tuple()))
    call assert_false(empty((1, 2)))
    VAR t = ('abc', 'def')
    call assert_false(empty(t))
  END
  call v9.CheckLegacyAndVim9Success(lines)
endfunc

" Test for eval()
func Test_tuple_eval()
  let lines =<< trim END
    call assert_equal((), eval('()'))
    call assert_equal(([],), eval('([],)'))
    call assert_equal((1, 2, 3), eval('(1, 2, 3)'))
  END
  call v9.CheckLegacyAndVim9Success(lines)
endfunc

" Test for extend() with a tuple
func Test_tuple_extend()
  let lines =<< trim END
    VAR t = (1, 2, 3)
    call extend(t, (4, 5))
    call extendnew(t, (4, 5))
  END
  call v9.CheckLegacyAndVim9Failure(lines, [
        \ 'E712: Argument of extend() must be a List or Dictionary',
        \ 'E1013: Argument 1: type mismatch, expected list<any> but got tuple<number>',
        \ 'E712: Argument of extend() must be a List or Dictionary'])
endfunc

" Test for filter() with a tuple
func Test_tuple_filter()
  let lines =<< trim END
    VAR t = (1, 2, 3)
    call filter(t, 'v:val == 2')
  END
  call v9.CheckLegacyAndVim9Failure(lines, [
        \ 'E1523: Cannot use a tuple with function filter()',
        \ 'E1013: Argument 1: type mismatch, expected list<any> but got tuple<number>',
        \ 'E1523: Cannot use a tuple with function filter()'])
endfunc

" Test for flatten() with a tuple
func Test_tuple_flatten()
  let t = ([1, 2], [3, 4], [5, 6])
  call assert_fails("call flatten(t, 2)", 'E686: Argument of flatten() must be a List')
endfunc

" Test for flattennew() with a tuple
func Test_tuple_flattennew()
  let lines =<< trim END
    var t = ([1, 2], [3, 4], [5, 6])
    flattennew(t, 2)
  END
  call v9.CheckSourceDefFailure(lines, 'E1013: Argument 1: type mismatch, expected list<any> but got tuple<list<number>>')
endfunc

" Test for foreach() with a tuple
func Test_tuple_foreach()
  let t = ('a', 'b', 'c')
  let str = ''
  call foreach(t, 'let str ..= v:val')
  call assert_equal('abc', str)

  let sum = 0
  call foreach(test_null_tuple(), 'let sum += v:val')
  call assert_equal(0, sum)

  let lines =<< trim END
    def Concatenate(k: number, v: string)
      g:str ..= v
    enddef
    var t = ('a', 'b', 'c')
    var str = 0
    g:str = ''
    call foreach(t, Concatenate)
    call assert_equal('abc', g:str)

    g:str = ''
    call foreach(test_null_tuple(), Concatenate)
    call assert_equal('', g:str)
  END
  call v9.CheckSourceDefAndScriptSuccess(lines)
endfunc

" Test for get()
func Test_tuple_get()
  let lines =<< trim END
    VAR t = (10, 20, 30)
    for [i, v] in [[0, 10], [1, 20], [2, 30], [3, 0]]
      call assert_equal(v, get(t, i))
    endfor

    for [i, v] in [[-1, 30], [-2, 20], [-3, 10], [-4, 0]]
      call assert_equal(v, get(t, i))
    endfor
    call assert_equal(0, get((), 5))
    call assert_equal('c', get(('a', 'b'), 2, 'c'))
    call assert_equal('x', get(test_null_tuple(), 0, 'x'))
  END
  call v9.CheckLegacyAndVim9Success(lines)
endfunc

" Test for id()
func Test_tuple_id()
  let lines =<< trim END
    VAR t1 = (['a'], ['b'], ['c'])
    VAR t2 = (['a'], ['b'], ['c'])
    VAR t3 = t1
    call assert_true(id(t1) != id(t2))
    call assert_true(id(t1) == id(t3))
  END
  call v9.CheckLegacyAndVim9Success(lines)
endfunc

" Test for index() function
func Test_tuple_index_func()
  let lines =<< trim END
    VAR t = (88, 33, 99, 77)
    call assert_equal(3, index(t, 77))
    call assert_equal(2, index(t, 99, 1))
    call assert_equal(2, index(t, 99, -4))
    call assert_equal(2, index(t, 99, -5))
    call assert_equal(-1, index(t, 66))
    call assert_equal(-1, index(t, 77, 4))
    call assert_equal(-1, index((), 8))
    call assert_equal(-1, index(test_null_tuple(), 9))
  END
  call v9.CheckLegacyAndVim9Success(lines)

  let lines =<< trim END
    VAR t = (88, 33, 99, 77)
    call assert_equal(-1, index(t, 77, []))
  END
  call v9.CheckLegacyAndVim9Failure(lines, [
        \ 'E745: Using a List as a Number',
        \ 'E1013: Argument 3: type mismatch, expected number but got list<any>',
        \ 'E1210: Number required for argument 3'])

  let lines =<< trim END
    VAR t = (88, 33, 99, 77)
    call assert_equal(-1, index(t, 77, 1, ()))
  END
  call v9.CheckLegacyAndVim9Failure(lines, [
        \ 'E1519: Using a Tuple as a Number',
        \ 'E1013: Argument 4: type mismatch, expected bool but got tuple<any>',
        \ 'E1212: Bool required for argument 4'])
endfunc

" Test for indexof()
func Test_tuple_indexof()
  let lines =<< trim END
    VAR t = ('a', 'b', 'c', 'd')
    call assert_equal(2, indexof(t, 'v:val =~ "c"'))
    call assert_equal(2, indexof(t, 'v:val =~ "c"', {'startidx': 2}))
    call assert_equal(-1, indexof(t, 'v:val =~ "c"', {'startidx': 3}))
    call assert_equal(2, indexof(t, 'v:val =~ "c"', {'startidx': -3}))
    call assert_equal(2, indexof(t, 'v:val =~ "c"', {'startidx': -6}))
    call assert_equal(-1, indexof(t, 'v:val =~ "e"'))
    call assert_equal(-1, indexof((), 'v:val == 1'))
    call assert_equal(-1, indexof(test_null_tuple(), 'v:val == 2'))
  END
  call v9.CheckLegacyAndVim9Success(lines)

  func g:MyIndexOf(k, v)
    echoerr 'MyIndexOf failed'
  endfunc
  let lines =<< trim END
    VAR t = (1, 2, 3)
    echo indexof(t, function('g:MyIndexOf'))
  END
  call v9.CheckLegacyAndVim9Failure(lines, [
        \ 'MyIndexOf failed',
        \ 'MyIndexOf failed',
        \ 'MyIndexOf failed'])
  delfunc g:MyIndexOf
endfunc

" Test for insert()
func Test_tuple_insert()
  let lines =<< trim END
    VAR t = (1, 2, 3)
    call insert(t, 4)
    call insert(t, 4, 2)
  END
  call v9.CheckLegacyAndVim9Failure(lines, [
        \ 'E899: Argument of insert() must be a List or Blob',
        \ 'E1013: Argument 1: type mismatch, expected list<any> but got tuple<number>',
        \ 'E1226: List or Blob required for argument 1'])
endfunc

" Test for items()
func Test_tuple_items()
  let lines =<< trim END
    VAR t = ([], {}, ())
    call assert_equal([[0, []], [1, {}], [2, ()]], items(t))
    call assert_equal([[0, 1]], items((1, )))
    call assert_equal([], items(()))
    call assert_equal([], items(test_null_tuple()))
  END
  call v9.CheckLegacyAndVim9Success(lines)
endfunc

" Test for join()
func Test_tuple_join()
  let lines =<< trim END
    VAR t = ('a', 'b', 'c')
    call assert_equal('a b c', join(t))
    call assert_equal('a-b-c', join(t, '-'))
    call assert_equal('', join(()))
    call assert_equal('', join(test_null_tuple()))
  END
  call v9.CheckLegacyAndVim9Success(lines)
endfunc

" Test for js_encode()
func Test_tuple_js_encode()
  let lines =<< trim END
    call assert_equal('["a","b","c"]', js_encode(('a', 'b', 'c')))
    call assert_equal('["a","b"]', js_encode(('a', 'b')))
    call assert_equal('["a"]', js_encode(('a',)))
    call assert_equal("[]", js_encode(()))
    call assert_equal("[]", js_encode(test_null_tuple()))
    call assert_equal('["a",,]', js_encode(('a', v:none)))
  END
  call v9.CheckLegacyAndVim9Success(lines)
endfunc

" Test for json_encode()
func Test_tuple_json_encode()
  let lines =<< trim END
    call assert_equal('["a","b","c"]', json_encode(('a', 'b', 'c')))
    call assert_equal('["a","b"]', json_encode(('a', 'b')))
    call assert_equal('["a"]', json_encode(('a',)))
    call assert_equal("[]", json_encode(()))
    call assert_equal("[]", json_encode(test_null_tuple()))
  END
  call v9.CheckLegacyAndVim9Success(lines)

  let lines =<< trim END
    VAR t = (function('min'), function('max'))
    VAR s = json_encode(t)
  END
  call v9.CheckLegacyAndVim9Failure(lines, [
        \ 'E1161: Cannot json encode a func',
        \ 'E1161: Cannot json encode a func',
        \ 'E1161: Cannot json encode a func'])
endfunc

" Test for len()
func Test_tuple_len()
  let lines =<< trim END
    call assert_equal(0, len(()))
    call assert_equal(0, len(test_null_tuple()))
    call assert_equal(1, len(("abc",)))
    call assert_equal(3, len(("abc", "def", "ghi")))
  END
  call v9.CheckLegacyAndVim9Success(lines)
endfunc

" Test for map() with a tuple
func Test_tuple_map()
  let t = (1, 3, 5)
  call assert_fails("call map(t, 'v:val + 1')", 'E1523: Cannot use a tuple with function map()')
endfunc

" Test for max()
func Test_tuple_max()
  let lines =<< trim END
    VAR t = (1, 3, 5)
    call assert_equal(5, max(t))
    LET t = (6,)
    call assert_equal(6, max(t))
    call assert_equal(0, max(()))
    call assert_equal(0, max(test_null_tuple()))
  END
  call v9.CheckLegacyAndVim9Success(lines)

  let lines =<< trim END
    vim9script
    var x = max(('a', 2))
  END
  call v9.CheckSourceFailure(lines, 'E1030: Using a String as a Number: "a"')

  let lines =<< trim END
    vim9script
    var x = max((1, 'b'))
  END
  call v9.CheckSourceFailure(lines, 'E1030: Using a String as a Number: "b"')

  let lines =<< trim END
    vim9script
    def Fn()
      var x = max(('a', 'b'))
    enddef
    Fn()
  END
  call v9.CheckSourceFailure(lines, 'E1030: Using a String as a Number: "a"')

  let lines =<< trim END
    echo max([('a', 'b'), 20])
  END
  call v9.CheckLegacyAndVim9Failure(lines, [
        \ 'E1519: Using a Tuple as a Number',
        \ 'E1519: Using a Tuple as a Number',
        \ 'E1519: Using a Tuple as a Number'])
endfunc

" Test for min()
func Test_tuple_min()
  let lines =<< trim END
    VAR t = (5, 3, 1)
    call assert_equal(1, min(t))
    LET t = (6,)
    call assert_equal(6, min(t))
    call assert_equal(0, min(()))
    call assert_equal(0, min(test_null_tuple()))
  END
  call v9.CheckLegacyAndVim9Success(lines)

  let lines =<< trim END
    vim9script
    var x = min(('a', 2))
  END
  call v9.CheckSourceFailure(lines, 'E1030: Using a String as a Number: "a"')

  let lines =<< trim END
    vim9script
    var x = min((1, 'b'))
  END
  call v9.CheckSourceFailure(lines, 'E1030: Using a String as a Number: "b"')


  let lines =<< trim END
    vim9script
    def Fn()
      var x = min(('a', 'b'))
    enddef
    Fn()
  END
  call v9.CheckSourceFailure(lines, 'E1030: Using a String as a Number: "a"')
endfunc

" Test for reduce()
func Test_tuple_reduce()
  let t = (1, 3, 5)
  call assert_fails("call reduce(t, 'v:val + 1')", 'E1098: String, List or Blob required')
endfunc

" Test for remove()
func Test_tuple_remove()
  let lines =<< trim END
    VAR t = (1, 3, 5)
    call remove(t, 1)
  END
  call v9.CheckLegacyAndVim9Failure(lines, [
        \ 'E896: Argument of remove() must be a List, Dictionary or Blob',
        \ 'E1013: Argument 1: type mismatch, expected list<any> but got tuple<number>',
        \ 'E1228: List, Dictionary or Blob required for argument 1'])
endfunc

" Test for test_refcount()
func Test_tuple_refcount()
  let lines =<< trim END
    VAR t = (1, 2, 3)
    call assert_equal(1, test_refcount(t))
    VAR x = t
    call assert_equal(2, test_refcount(t))
    LET x = (4, 5)
    call assert_equal(1, test_refcount(t))
    for n in t
      call assert_equal(2, test_refcount(t))
    endfor
    call assert_equal(1, test_refcount(t))
  END
  call v9.CheckLegacyAndVim9Success(lines)
endfunc

" Test for reverse()
func Test_tuple_reverse()
  let lines =<< trim END
    VAR t = (1, 3, 5)
    call reverse(t)
  END
  call v9.CheckLegacyAndVim9Failure(lines, [
        \ 'E1252: String, List or Blob required for argument 1',
        \ 'E1013: Argument 1: type mismatch, expected list<any> but got tuple<number>',
        \ 'E1252: String, List or Blob required for argument 1'])
endfunc

" Test for slicing a tuple
func Test_tuple_slice()
  let lines =<< trim END
    VAR t = (1, 3, 5, 7, 9)
    call assert_equal((3, 5), t[1 : 2])
    call assert_equal((9,), t[4 : 4])
    call assert_equal((7, 9), t[3 : 6])
    call assert_equal((), test_null_tuple()[:])

    call assert_equal((9,), slice(t, 4))
    call assert_equal((5, 7, 9), slice(t, 2))
    call assert_equal((), slice(t, 5))
    call assert_equal((), slice((), 1, 2))
    call assert_equal((), slice(test_null_tuple(), 1, 2))
  END
  call v9.CheckLegacyAndVim9Success(lines)
endfunc

" Test for using a tuple in a for statement
func Test_tuple_for()
  let lines =<< trim END
    VAR sum = 0
    for v1 in (1, 3, 5)
      LET sum += v1
    endfor
    call assert_equal(9, sum)

    LET sum = 0
    for v2 in ()
      LET sum += v2
    endfor
    call assert_equal(0, sum)

    LET sum = 0
    for v2 in test_null_tuple()
      LET sum += v2
    endfor
    call assert_equal(0, sum)
  END
  call v9.CheckLegacyAndVim9Success(lines)

  " ignoring the for loop assignment using '_'
  let lines =<< trim END
    vim9script
    var count = 0
    for _ in (1, 2, 3)
      count += 1
    endfor
    assert_equal(3, count)
  END
  call v9.CheckSourceSuccess(lines)

  let lines =<< trim END
    var sum = 0
    for v in null_tuple
      sum += v
    endfor
    assert_equal(0, sum)
  END
  call v9.CheckSourceDefAndScriptSuccess(lines)

  let lines =<< trim END
    vim9script
    def Foo()
      for x in ((1, 2), (3, 4))
      endfor
    enddef
    Foo()
  END
  call v9.CheckSourceSuccess(lines)
endfunc

func Test_tuple_declaration_error()
  let lines =<< trim END
    var t: tuple<number> = (1,2)
  END
  call v9.CheckSourceDefAndScriptFailure(lines, "E1069: White space required after")

  let lines =<< trim END
    var t: tuple<number> = (1, 2,3)
  END
  call v9.CheckSourceDefAndScriptFailure(lines, "E1069: White space required after")

  let lines =<< trim END
    var t = (1, 2 ,3)
  END
  call v9.CheckSourceDefAndScriptFailure(lines, [
        \ "E1068: No white space allowed before ','",
        \ "E1068: No white space allowed before ','"])

  let lines =<< trim END
    VAR t = (1, 2 3)
  END
  call v9.CheckLegacyAndVim9Failure(lines, [
        \ 'E1526: Missing comma in Tuple: 3)',
        \ 'E1526: Missing comma in Tuple: 3)',
        \ 'E1526: Missing comma in Tuple: 3)'])

  let lines =<< trim END
    VAR t = (1, 2,
  END
  call v9.CheckLegacyAndVim9Failure(lines, [
        \ "E1525: Missing end of Tuple ')'",
        \ "E1525: Missing end of Tuple ')'",
        \ "E1525: Missing end of Tuple ')'"])

  let lines =<< trim END
    var t: tuple<number> = (1, , 2)
  END
  call v9.CheckSourceDefAndScriptFailure(lines, [
        \ "E1068: No white space allowed before",
        \ 'E15: Invalid expression: ", 2)"'])
endfunc

" Test for checking the tuple type in assignment and return value
func Test_tuple_type_check()
  let lines =<< trim END
    var t: tuple<number> = ('a', 'b')
  END
  call v9.CheckSourceDefFailure(lines, 'E1012: Type mismatch; expected tuple<number> but got tuple<string>', 1)

  let lines =<< trim END
    var t: tuple = ('a', 'b')
  END
  call v9.CheckSourceDefFailure(lines, 'E1008: Missing <type> after tuple', 1)

  let lines =<< trim END
    var t = ('a', 'b')
    t = (1, 2)
  END
  call v9.CheckSourceDefFailure(lines, 'E1012: Type mismatch; expected tuple<string> but got tuple<number>', 2)

  let lines =<< trim END
    var t: tuple<number> = []
  END
  call v9.CheckSourceDefFailure(lines, 'E1012: Type mismatch; expected tuple<number> but got list<any>', 1)

  let lines =<< trim END
    var t: tuple<number> = {}
  END
  call v9.CheckSourceDefFailure(lines, 'E1012: Type mismatch; expected tuple<number> but got dict<any>', 1)

  let lines =<< trim END
    var l: list<number> = (1, 2)
  END
  call v9.CheckSourceDefFailure(lines, 'E1012: Type mismatch; expected list<number> but got tuple<number>', 1)

  let lines =<< trim END
    vim9script
    def Fn(): tuple<tuple<string>>
      return ((1, 2), (3, 4))
    enddef
    defcompile
  END
  call v9.CheckSourceFailure(lines, 'E1012: Type mismatch; expected tuple<tuple<string>> but got tuple<tuple<number>>', 1)

  let lines =<< trim END
    var t: tuple<number> = ()
  END
  call v9.CheckSourceDefSuccess(lines)

  let lines =<< trim END
    vim9script
    def Fn(): tuple<tuple<string>>
      return ()
    enddef
    defcompile
  END
  call v9.CheckSourceSuccess(lines)

  let lines =<< trim END
    vim9script
    def Fn(t: tuple<number>)
    enddef
    Fn(('a', 'b'))
  END
  call v9.CheckSourceFailure(lines, 'E1013: Argument 1: type mismatch, expected tuple<number> but got tuple<string>')

  let lines =<< trim END
    var t: any = (1, 2)
    t = ('a', 'b')
  END
  call v9.CheckSourceDefSuccess(lines)

  let lines =<< trim END
    var t: tuple<any> = (1, 2)
    t = ('a', 'b')
  END
  call v9.CheckSourceDefSuccess(lines)
endfunc

" Test for modifying a tuple
func Test_tuple_modify()
  let lines =<< trim END
    var t = (1, 2)
    t[0] = 3
  END
  call v9.CheckSourceDefAndScriptFailure(lines, ["E1531: Tuple 't' is immutable", 'E689: Index not allowed after a tuple: t[0] = 3'])
endfunc

def Test_using_null_tuple()
  var lines =<< trim END
    var x = null_tuple
    assert_true(x is null_tuple)
    var y = copy(x)
    assert_true(y is null_tuple)
    call assert_true((1, 2) != null_tuple)
    call assert_true(null_tuple != (1, 2))
    assert_equal(0, count(null_tuple, 'xx'))
    var z = deepcopy(x)
    assert_true(z is null_tuple)
    assert_equal(1, empty(x))
    assert_equal('xx', get(x, 0, 'xx'))
    assert_equal(-1, index(null_tuple, 10))
    assert_equal(-1, indexof(null_tuple, 'v:val == 2'))
    assert_equal('', join(null_tuple))
    assert_equal(0, len(x))
    assert_equal(0, min(null_tuple))
    assert_equal(0, max(null_tuple))
    assert_equal((), slice(null_tuple, 0, 0))
    assert_equal('()', string(x))
    assert_equal('tuple<any>', typename(x))
    assert_equal(17, type(x))
  END
  v9.CheckSourceDefAndScriptSuccess(lines)

  lines =<< trim END
    var x = null_tupel
  END
  v9.CheckSourceDefAndScriptFailure(lines, [
        \ 'E1001: Variable not found: null_tupel',
        \ 'E121: Undefined variable: null_tupel'])
enddef

" Test for saving and restoring tuples from a viminfo file
func Test_tuple_viminfo()
  let viminfo_save = &viminfo
  set viminfo^=!
  let g:MYTUPLE = ([1, 2], [3, 4], 'a', 'b', 1, 2)
  wviminfo! Xviminfo
  let g:MYTUPLE = ()
  rviminfo! Xviminfo
  call assert_equal(([1, 2], [3, 4], 'a', 'b', 1, 2), g:MYTUPLE)
  let &viminfo = viminfo_save
  call delete('Xviminfo')
endfunc

" vim: shiftwidth=2 sts=2 expandtab
