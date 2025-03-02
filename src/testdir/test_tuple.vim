" Tests for the Tuple types

import './vim9.vim' as v9

func TearDown()
  " Run garbage collection after every test
  call test_garbagecollect_now()
endfunc

" Tuple creation
func Test_tuple_create()
  " Creating tuple directly with different types
  let t = (1, 'as''d', [1, 2, function("strlen")], {'a': 1},)
  call assert_equal("(1, 'as''d', [1, 2, function('strlen')], {'a': 1})", string(t))

  " empty tuple
  let t = ()
  call assert_equal("()", string(t))

  " one item tuple
  let t = ("a", )
  call assert_equal("('a')", string(t))
endfunc

" Test for len()
func Test_tuple_len()
  call assert_equal(0, len(()))
  call assert_equal(1, len(("abc",)))
  call assert_equal(3, len(("abc", "def", "ghi")))
endfunc

" Test for empty()
func Test_tuple_empty()
  call assert_true(empty(()))
  call assert_false(empty((1, 2)))
  let t = ('abc', 'def')
  call assert_false(empty(t))
endfunc

" Test for type()
func Test_tuple_type()
  let t = (1, 2)
  call assert_equal(17, type(t))
  call assert_equal(v:t_tuple, type(t))
endfunc

" Test for typename()
func Test_tuple_typename()
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
endfunc

" Test for comparing tuples
func Test_tuple_compare()
  call assert_false((1, 2) == (1, 3))
  call assert_true((1, 2) == (1, 2))
  call assert_true(() == ())
  call assert_false((1, 2) == (1, 2, 3))
endfunc

" Test for tuple identity
func Test_tuple_identity()
  call assert_false((1, 2) is (1, 2))
  call assert_true((1, 2) isnot (1, 2))
  let t1 = ('abc', 'def')
  let t2 = t1
  call assert_true(t2 is t1)
  let t2 = (1, 2)
  call assert_false(t2 is t1)
endfunc

" Test for get()
func Test_tuple_get()
  let t = (10, 20, 30)
  for [i, v] in [[0, 10], [1, 20], [2, 30], [3, 0]]
    call assert_equal(v, get(t, i))
  endfor

  for [i, v] in [[-1, 30], [-2, 20], [-3, 10], [-4, 0]]
    call assert_equal(v, get(t, i))
  endfor
  call assert_equal(0, get((), 0))
  call assert_equal('c', get(('a', 'b'), 2, 'c'))
endfunc

" Test for copy()
func Test_tuple_copy()
  let t1 = (['a', 'b'], ['c', 'd'], ['e', 'f'])
  let t2 = copy(t1)
  let t3 = t1
  call assert_false(t2 is t1)
  call assert_true(t3 is t1)
endfunc

" Test for deepcopy()
func Test_tuple_deepcopy()
  let t1 = (['a', 'b'], ['c', 'd'], ['e', 'f'])
  let t2 = deepcopy(t1)
  let t3 = t1
  call assert_false(t2 is t1)
  call assert_true(t3 is t1)
endfunc

" Test for slicing a tuple
func Test_tuple_slice()
  let t = (1, 3, 5, 7, 9)
  call assert_equal((3, 5), t[1:2])
  call assert_equal((9,), t[4:4])
  call assert_equal((7, 9), t[3:6])
endfunc

" Test for add() with a tuple
func Test_tuple_add()
  let t = (1, 2, 3)
  call assert_fails("call add(t, 4)", 'E897: List or Blob required')
endfunc

" Test for extend() with a tuple
func Test_tuple_extend()
  let t = (1, 2, 3)
  call assert_fails("call extend(t, (4, 5))", 'E712: Argument of extend() must be a List or Dictionary')
  call assert_fails("call extendnew(t, (4, 5))", 'E712: Argument of extendnew() must be a List or Dictionary')
endfunc

" Test for filter() with a tuple
func Test_tuple_filter()
  let t = (1, 2, 3)
  call assert_fails("call filter(t, 'v:val == 2')", 'E1250: Argument of filter() must be a List, String, Dictionary or Blob')
endfunc

" Test for flatten() with a tuple
func Test_tuple_flatten()
  let t = (1, 2, 3)
  call assert_fails("call flatten(t, 3)", 'E686: Argument of flatten() must be a List')
  call assert_fails("call flattennew(t, 3)", 'E686: Argument of flatten() must be a List')
endfunc

" Test for foreach() with a tuple
func Test_tuple_foreach()
  " TODO
endfunc

" vim: shiftwidth=2 sts=2 expandtab
