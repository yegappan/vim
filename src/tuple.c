/* vi:set ts=8 sts=4 sw=4 noet:
 *
 * VIM - Vi IMproved	by Bram Moolenaar
 *
 * Do ":help uganda"  in Vim to read copying and usage conditions.
 * Do ":help credits" in Vim to see a list of people who contributed.
 * See README.txt for an overview of the Vim source code.
 */

/*
 * tuple.c: Tuple support functions.
 */

#include "vim.h"

#if defined(FEAT_EVAL) || defined(PROTO)

// Tuple heads for garbage collection.
static tuple_T		*first_tuple = NULL;	// list of all tuples

    static void
tuple_init(tuple_T *tuple)
{
    // Prepend the tuple to the list of tuples for garbage collection.
    if (first_tuple != NULL)
	first_tuple->tv_used_prev = tuple;
    tuple->tv_used_prev = NULL;
    tuple->tv_used_next = first_tuple;
    first_tuple = tuple;

    ga_init2(&tuple->tv_items, sizeof(typval_T), 20);
}

/*
 * Allocate an empty header for a tuple.
 * Caller should take care of the reference count.
 */
    tuple_T *
tuple_alloc(void)
{
    tuple_T  *t;

    t = ALLOC_CLEAR_ONE(tuple_T);
    if (t != NULL)
	tuple_init(t);
    return t;
}

/*
 * Free a tuple, including all non-container items it points to.
 * Ignores the reference count.
 */
    static void
tuple_free_contents(tuple_T *t)
{
    for (int i = 0; i < TUPLE_LEN(t); i++)
	clear_tv(TUPLE_ITEM(t, i));

    ga_clear(&t->tv_items);
}

/*
 * Go through the list of tuples and free items without the copyID.
 * But don't free a tuple that has a watcher (used in a for loop), these
 * are not referenced anywhere.
 */
    int
tuple_free_nonref(int copyID)
{
    tuple_T	*tt;
    int		did_free = FALSE;

    for (tt = first_tuple; tt != NULL; tt = tt->tv_used_next)
	if ((tt->tv_copyID & COPYID_MASK) != (copyID & COPYID_MASK))
	{
	    // Free the Tuple and ordinary items it contains, but don't recurse
	    // into Lists and Dictionaries, they will be in the list of dicts
	    // or list of lists.
	    tuple_free_contents(tt);
	    did_free = TRUE;
	}
    return did_free;
}

    static void
tuple_free_list(tuple_T  *t)
{
    // Remove the tuple from the list of tuples for garbage collection.
    if (t->tv_used_prev == NULL)
	first_tuple = t->tv_used_next;
    else
	t->tv_used_prev->tv_used_next = t->tv_used_next;
    if (t->tv_used_next != NULL)
	t->tv_used_next->tv_used_prev = t->tv_used_prev;

    free_type(t->tv_type);
    vim_free(t);
}

    void
tuple_free_items(int copyID)
{
    tuple_T	*tt, *tt_next;

    for (tt = first_tuple; tt != NULL; tt = tt_next)
    {
	tt_next = tt->tv_used_next;
	if ((tt->tv_copyID & COPYID_MASK) != (copyID & COPYID_MASK))
	{
	    // Free the List and ordinary items it contains, but don't recurse
	    // into Lists and Dictionaries, they will be in the list of dicts
	    // or list of lists.
	    tuple_free_list(tt);
	}
    }
}

    void
tuple_free(tuple_T *t)
{
    if (in_free_unref_items)
	return;

    tuple_free_contents(t);
    tuple_free_list(t);
}

/*
 * Get the number of items in a tuple.
 */
    long
tuple_len(tuple_T *t)
{
    if (t == NULL)
	return 0L;
    return t->tv_items.ga_len;
}

/*
 * Return TRUE when two tuples have exactly the same values.
 */
    int
tuple_equal(
    tuple_T	*t1,
    tuple_T	*t2,
    int		ic)	// ignore case for strings
{
    if (t1 == t2)
	return TRUE;
    if (tuple_len(t1) != tuple_len(t2))
	return FALSE;
    if (tuple_len(t1) == 0)
	// empty and NULL tuples are considered equal
	return TRUE;
    if (t1 == NULL || t2 == NULL)
	return FALSE;

    for (int i = 0, j = 0; i < TUPLE_LEN(t1) && j < TUPLE_LEN(t2); i++, j++)
	if (!tv_equal(TUPLE_ITEM(t1, i), TUPLE_ITEM(t2, j), ic))
	    return FALSE;
    return TRUE;
}

/*
 * Locate item with index "n" in tuple "t" and return it.
 * A negative index is counted from the end; -1 is the last item.
 * Returns NULL when "n" is out of range.
 */
    typval_T *
tuple_find(tuple_T *t, long n)
{
    if (t == NULL)
	return NULL;

    // Negative index is relative to the end.
    if (n < 0)
	n = TUPLE_LEN(t) + n;

    // Check for index out of range.
    if (n < 0 || n >= TUPLE_LEN(t))
	return NULL;

    return TUPLE_ITEM(t, n);
}

    int
tuple_append_tv(tuple_T *t, typval_T *tv)
{
    if (t->tv_type != NULL && t->tv_type->tt_member != NULL
		&& check_typval_arg_type(t->tv_type->tt_member, tv,
							      NULL, 0) == FAIL)
	return FAIL;

    if (ga_grow(&t->tv_items, 1) == FAIL)
	return FAIL;
    *TUPLE_ITEM(t, TUPLE_LEN(t)) = *tv;
    t->tv_items.ga_len++;

    return OK;
}

    tuple_T *
tuple_slice(tuple_T *tuple, long n1, long n2)
{
    tuple_T	*new_tuple = tuple_alloc();

    if (new_tuple == NULL)
	return NULL;

    for (int i = n1; i <= n2; i++)
    {
	if (tuple_append_tv(new_tuple, TUPLE_ITEM(tuple, i)) == FAIL)
	{
	    tuple_free(new_tuple);
	    return NULL;
	}
    }

    return new_tuple;
}

    int
tuple_slice_or_index(
    tuple_T	*tuple,
    int		range,
    varnumber_T	n1_arg,
    varnumber_T	n2_arg,
    int		exclusive,
    typval_T	*rettv,
    int		verbose)
{
    long	len = TUPLE_LEN(tuple);
    varnumber_T	n1 = n1_arg;
    varnumber_T	n2 = n2_arg;
    typval_T	var1;

    if (n1 < 0)
	n1 = len + n1;
    if (n1 < 0 || n1 >= len)
    {
	// For a range we allow invalid values and for legacy script return an
	// empty list, for Vim9 script start at the first item.
	// A tuple index out of range is an error.
	if (!range)
	{
	    if (verbose)
		semsg(_(e_tuple_index_out_of_range_nr), (long)n1_arg);
	    return FAIL;
	}
	if (in_vim9script())
	    n1 = n1 < 0 ? 0 : len;
	else
	    n1 = len;
    }
    if (range)
    {
	tuple_T	*t;

	if (n2 < 0)
	    n2 = len + n2;
	else if (n2 >= len)
	    n2 = len - (exclusive ? 0 : 1);
	if (exclusive)
	    --n2;
	if (n2 < 0 || n2 + 1 < n1)
	    n2 = -1;
	t = tuple_slice(tuple, n1, n2);
	if (t == NULL)
	    return FAIL;
	clear_tv(rettv);
	rettv_tuple_set(rettv, t);
    }
    else
    {
	// copy the item to "var1" to avoid that freeing the list makes it
	// invalid.
	copy_tv(tuple_find(tuple, n1), &var1);
	clear_tv(rettv);
	*rettv = var1;
    }
    return OK;
}

/*
 * Make a copy of tuple "orig".  Shallow if "deep" is FALSE.
 * The refcount of the new tuple is set to 1.
 * See item_copy() for "top" and "copyID".
 * Returns NULL when out of memory.
 */
    tuple_T *
tuple_copy(tuple_T *orig, int deep, int top, int copyID)
{
    tuple_T	*copy;
    int		idx;

    if (orig == NULL)
	return NULL;

    copy = tuple_alloc();
    if (copy == NULL)
	return NULL;

    if (orig->tv_type == NULL || top || deep)
	copy->tv_type = NULL;
    else
	copy->tv_type = alloc_type(orig->tv_type);
    if (copyID != 0)
    {
	// Do this before adding the items, because one of the items may
	// refer back to this tuple.
	orig->tv_copyID = copyID;
	orig->tv_copytuple = copy;
    }

    for (idx = 0; idx < TUPLE_LEN(orig) && !got_int; idx++)
    {
	if (ga_grow(&copy->tv_items, 1) == FAIL)
	    break;
	copy->tv_items.ga_len++;
	if (deep)
	{
	    if (item_copy(TUPLE_ITEM(orig, idx), TUPLE_ITEM(copy, idx),
						deep, FALSE, copyID) == FAIL)
		break;
	}
	else
	    copy_tv(TUPLE_ITEM(orig, idx), TUPLE_ITEM(copy, idx));
    }

    ++copy->tv_refcount;
    if (idx != TUPLE_LEN(orig))
    {
	tuple_unref(copy);
	copy = NULL;
    }

    return copy;
}

/*
 * Allocate a variable for a tuple and fill it from "*arg".
 * "*arg" points to the "," after the first element.
 * "rettv" contains the first element.
 * Returns OK or FAIL.
 */
    int
eval_tuple(char_u **arg, typval_T *rettv, evalarg_T *evalarg, int do_error)
{
    int		evaluate = evalarg == NULL ? FALSE
					 : evalarg->eval_flags & EVAL_EVALUATE;
    tuple_T	*t = NULL;
    typval_T	tv;
    int		vim9script = in_vim9script();
    int		had_comma;

    if (evaluate)
    {
	t = tuple_alloc();
	if (t == NULL)
	    return FAIL;

	if (rettv->v_type != VAR_UNKNOWN)
	{
	    // Add the first item to the tuple from "rettv"
	    if (tuple_append_tv(t, rettv) == FAIL)
		return FAIL;
	}
    }

    if (**arg == ')')
	// empty tuple
	goto done;

    *arg = skipwhite_and_linebreak(*arg + 1, evalarg);
    while (**arg != ')' && **arg != NUL)
    {
	if (eval1(arg, &tv, evalarg) == FAIL)	// recursive!
	    goto failret;
	if (check_typval_is_value(&tv) == FAIL)
	{
	    if (evaluate)
		clear_tv(&tv);
	    goto failret;
	}

	if (evaluate)
	{
	    if (tuple_append_tv(t, &tv) == FAIL)
	    {
		clear_tv(&tv);
		goto failret;
	    }
	}

	if (!vim9script)
	    *arg = skipwhite(*arg);

	// the comma must come after the value
	had_comma = **arg == ',';
	if (had_comma)
	{
	    if (vim9script && !IS_WHITE_NL_OR_NUL((*arg)[1]) && (*arg)[1] != ']')
	    {
		semsg(_(e_white_space_required_after_str_str), ",", *arg);
		goto failret;
	    }
	    *arg = skipwhite(*arg + 1);
	}

	// The "]" can be on the next line.  But a double quoted string may
	// follow, not a comment.
	*arg = skipwhite_and_linebreak(*arg, evalarg);
	if (**arg == ')')
	    break;

	if (!had_comma)
	{
	    if (do_error)
	    {
		if (**arg == ',')
		    semsg(_(e_no_white_space_allowed_before_str_str),
								    ",", *arg);
		else
		    semsg(_(e_missing_comma_in_list_str), *arg);
	    }
	    goto failret;
	}
    }

    if (**arg != ')')
    {
	if (do_error)
	    semsg(_(e_missing_end_of_list_rsb_str), *arg);
failret:
	if (evaluate)
	    tuple_free(t);
	return FAIL;
    }

done:
    *arg += 1;
    if (evaluate)
	rettv_tuple_set(rettv, t);

    return OK;
}

/*
 * Set a tuple as the return value.  Increments the reference count.
 */
    void
rettv_tuple_set(typval_T *rettv, tuple_T *t)
{
    rettv->v_type = VAR_TUPLE;
    rettv->vval.v_tuple = t;
    if (t != NULL)
	++t->tv_refcount;
}

/*
 * Unreference a tuple: decrement the reference count and free it when it
 * becomes zero.
 */
    void
tuple_unref(tuple_T *t)
{
    if (t != NULL && --t->tv_refcount <= 0)
	tuple_free(t);
}

typedef struct join_S {
    char_u	*s;
    char_u	*tofree;
} join_T;

    static int
tuple_join_inner(
    garray_T	*gap,		// to store the result in
    tuple_T	*t,
    char_u	*sep,
    int		echo_style,
    int		restore_copyID,
    int		copyID,
    garray_T	*join_gap)	// to keep each tuple item string
{
    int		i;
    join_T	*p;
    int		len;
    int		sumlen = 0;
    int		first = TRUE;
    char_u	*tofree;
    char_u	numbuf[NUMBUFLEN];
    char_u	*s;
    typval_T	*tv;

    // Stringify each item in the tuple.
    for (int i = 0; i < TUPLE_LEN(t) && !got_int; i++)
    {
	tv = TUPLE_ITEM(t, i);
	s = echo_string_core(tv, &tofree, numbuf, copyID,
				      echo_style, restore_copyID, !echo_style);
	if (s == NULL)
	    return FAIL;

	len = (int)STRLEN(s);
	sumlen += len;

	(void)ga_grow(join_gap, 1);
	p = ((join_T *)join_gap->ga_data) + (join_gap->ga_len++);
	if (tofree != NULL || s != numbuf)
	{
	    p->s = s;
	    p->tofree = tofree;
	}
	else
	{
	    p->s = vim_strnsave(s, len);
	    p->tofree = p->s;
	}

	line_breakcheck();
	if (did_echo_string_emsg)  // recursion error, bail out
	    break;
    }

    // Allocate result buffer with its total size, avoid re-allocation and
    // multiple copy operations.  Add 2 for a tailing ']' and NUL.
    if (join_gap->ga_len >= 2)
	sumlen += (int)STRLEN(sep) * (join_gap->ga_len - 1);
    if (ga_grow(gap, sumlen + 2) == FAIL)
	return FAIL;

    for (i = 0; i < join_gap->ga_len && !got_int; ++i)
    {
	if (first)
	    first = FALSE;
	else
	    ga_concat(gap, sep);
	p = ((join_T *)join_gap->ga_data) + i;

	if (p->s != NULL)
	    ga_concat(gap, p->s);
	line_breakcheck();
    }

    return OK;
}

/*
 * Join tuple "t" into a string in "*gap", using separator "sep".
 * When "echo_style" is TRUE use String as echoed, otherwise as inside a Tuple.
 * Return FAIL or OK.
 */
    int
tuple_join(
    garray_T	*gap,
    tuple_T	*t,
    char_u	*sep,
    int		echo_style,
    int		restore_copyID,
    int		copyID)
{
    garray_T	join_ga;
    int		retval;
    join_T	*p;
    int		i;

    if (TUPLE_LEN(t) < 1)
	return OK; // nothing to do
    ga_init2(&join_ga, sizeof(join_T), TUPLE_LEN(t));
    retval = tuple_join_inner(gap, t, sep, echo_style, restore_copyID,
							    copyID, &join_ga);

    if (join_ga.ga_data == NULL)
	return retval;

    // Dispose each item in join_ga.
    p = (join_T *)join_ga.ga_data;
    for (i = 0; i < join_ga.ga_len; ++i)
    {
	vim_free(p->tofree);
	++p;
    }
    ga_clear(&join_ga);

    return retval;
}

/*
 * Return an allocated string with the string representation of a tuple.
 * May return NULL.
 */
    char_u *
tuple2string(typval_T *tv, int copyID, int restore_copyID)
{
    garray_T	ga;

    if (tv->vval.v_tuple == NULL)
	return NULL;
    ga_init2(&ga, sizeof(char), 80);
    ga_append(&ga, '(');
    if (tuple_join(&ga, tv->vval.v_tuple, (char_u *)", ",
				       FALSE, restore_copyID, copyID) == FAIL)
    {
	vim_free(ga.ga_data);
	return NULL;
    }
    ga_append(&ga, ')');
    ga_append(&ga, NUL);
    return (char_u *)ga.ga_data;
}

#endif // defined(FEAT_EVAL)
