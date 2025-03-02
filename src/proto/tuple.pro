/* tuple.c */

tuple_T *tuple_alloc(void);
int tuple_free_nonref(int copyID);
void tuple_free_items(int copyID);
void tuple_free(tuple_T *t);
long tuple_len(tuple_T *t);
int tuple_equal(tuple_T *t1, tuple_T *t2, int ic);
typval_T *tuple_find(tuple_T *t, long n);
int tuple_append_tv(tuple_T *t, typval_T *tv);
tuple_T *tuple_slice(tuple_T *tuple, long n1, long n2);
int tuple_slice_or_index( tuple_T *tuple, int range, varnumber_T n1_arg, varnumber_T n2_arg, int exclusive, typval_T *rettv, int verbose);
tuple_T *tuple_copy(tuple_T *orig, int deep, int top, int copyID);
int eval_tuple(char_u **arg, typval_T *rettv, evalarg_T *evalarg, int do_error);
void rettv_tuple_set(typval_T *rettv, tuple_T *t);
void tuple_unref(tuple_T *t);
int tuple_join(garray_T *gap, tuple_T *t, char_u *sep, int echo_style, int restore_copyID, int copyID);
char_u *tuple2string(typval_T *tv, int copyID, int restore_copyID);

/* vim: set ft=c : */
