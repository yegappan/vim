" Tests for the Tuple types

import './vim9.vim' as v9

func TearDown()
  " Run garbage collection after every test
  call test_garbagecollect_now()
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
endfunc

" Test for type()
func Test_tuple_type()
  let lines =<< trim END
    VAR t = (1, 2)
    call assert_equal(17, type(t))
    call assert_equal(v:t_tuple, type(t))
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
    call assert_equal('list<tuple<any>>', typename([()]))
    call assert_equal('list<tuple<number>>', typename([(1,)]))
    call assert_equal('tuple<any>', typename(test_null_tuple()))
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
  END
  call v9.CheckLegacyAndVim9Success(lines)
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
    LET t2 = (1, 2)
    call assert_false(t2 is t1)
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
    call assert_equal(0, count(test_null_tuple(), 'xx'))
    call assert_equal(0, count((), 'xx'))
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
    call assert_equal((), deepcopy(test_null_tuple()))
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
  let t = (1, 3, 5)
  let sum = 0
  call foreach(t, 'let sum += v:val')
  call assert_equal(9, sum)

  let sum = 0
  call foreach(test_null_tuple(), 'let sum += v:val')
  call assert_equal(0, sum)

  let lines =<< trim END
    def Sum(k: number, v: number)
      g:sum += v
    enddef
    var t = (1, 3, 5)
    var sum = 0
    g:sum = 0
    call foreach(t, Sum)
    call assert_equal(9, g:sum)

    g:sum = 0
    call foreach(test_null_tuple(), Sum)
    call assert_equal(0, g:sum)
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
    call assert_equal(0, get((), 0))
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

" Test for index()
func Test_tuple_index()
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
endfunc

" Test for min()
func Test_tuple_min()
  let lines =<< trim END
    VAR t = (1, 3, 5)
    call assert_equal(1, min(t))
    LET t = (6,)
    call assert_equal(6, min(t))
    call assert_equal(0, min(()))
    call assert_equal(0, min(test_null_tuple()))
  END
  call v9.CheckLegacyAndVim9Success(lines)
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
    for v2 in test_null_tuple()
      LET sum += v2
    endfor
    call assert_equal(0, sum)
  END
  call v9.CheckLegacyAndVim9Success(lines)
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
    var t: tuple<number> = (1, , 2)
  END
  call v9.CheckSourceDefAndScriptFailure(lines, [
        \ "E1068: No white space allowed before",
        \ 'E15: Invalid expression: ", 2)"'])
endfunc

" vim: shiftwidth=2 sts=2 expandtab
