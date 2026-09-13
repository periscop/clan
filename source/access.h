/* Expression access lists and deferred affine subscript candidates. */
#ifndef CLAN_ACCESS_H
#define CLAN_ACCESS_H

struct osl_relation_list;

// Flags for supported base scalar declaration specifiers.
enum clan_private_type {
  CLAN_PRIVATE_CHAR = 1,
  CLAN_PRIVATE_SHORT = 2,
  CLAN_PRIVATE_INT = 4,
  CLAN_PRIVATE_LONG = 8,
  CLAN_PRIVATE_LONGLONG = 16,
  CLAN_PRIVATE_SIGNED = 32,
  CLAN_PRIVATE_UNSIGNED = 64,
  CLAN_PRIVATE_FLOAT = 128,
  CLAN_PRIVATE_DOUBLE = 256,
  CLAN_PRIVATE_BOOL = 512,
  CLAN_PRIVATE_COMPLEX = 1024,
  CLAN_PRIVATE_IMAGINARY = 2048
};

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

int clan_access_private_type_add(int, int);
int clan_access_private_type(int);
struct clan_access_expr* clan_access_expr_new(int, struct clan_access_expr*,
                                             struct clan_access_expr*);
struct clan_access_expr* clan_access_identifier(char*);
void clan_access_expr_free(struct clan_access_expr*);
struct osl_relation_list* clan_access_last(struct osl_relation_list*);
int clan_access_subscript(struct clan_access_expr*, struct clan_access_expr*,
                          int);

#endif
