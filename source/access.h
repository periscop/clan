/* Expression access lists and deferred affine subscript candidates. */
#ifndef CLAN_ACCESS_H
#define CLAN_ACCESS_H

struct osl_relation_list;

enum clan_access_operator {
  CLAN_ACCESS_ID = 256,
  CLAN_ACCESS_INTEGER,
  CLAN_ACCESS_PAREN,
  CLAN_ACCESS_OTHER,
  CLAN_ACCESS_EFFECT
};

struct clan_access_expr {
  int op;
  int value;
  int start;
  /* Owned here; child lists are transferred when expressions are combined. */
  struct osl_relation_list* access;
  char* name;
  struct clan_access_expr* left;
  struct clan_access_expr* right;
};

struct clan_access_expr* clan_access_expr_new(int, struct clan_access_expr*,
                                             struct clan_access_expr*);
void clan_access_expr_free(struct clan_access_expr*);
struct osl_relation_list* clan_access_last(struct osl_relation_list*);
int clan_access_subscript(struct clan_access_expr*, struct clan_access_expr*,
                          int);

#endif
