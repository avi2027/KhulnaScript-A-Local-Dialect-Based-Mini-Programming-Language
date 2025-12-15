%{
#include <stdio.h>
#include <stdlib.h>
#include <string.h>

// Simple symbol table for variables
typedef struct Var {
    char *name;
    int value;
    struct Var *next;
} Var;

Var *symtab = NULL;

void set_var(const char *name, int value) {
    Var *v = symtab;
    while (v) {
        if (strcmp(v->name, name) == 0) {
            v->value = value;
            return;
        }
        v = v->next;
    }
    v = (Var *)malloc(sizeof(Var));
    v->name = strdup(name);
    v->value = value;
    v->next = symtab;
    symtab = v;
}

int get_var(const char *name) {
    Var *v = symtab;
    while (v) {
        if (strcmp(v->name, name) == 0) {
            return v->value;
        }
        v = v->next;
    }
    // defaults like original Python: x=4,y=2,i=1
    if (strcmp(name, "x") == 0) return 4;
    if (strcmp(name, "y") == 0) return 2;
    if (strcmp(name, "i") == 0) return 1;
    return 0;
}

// Buffer for generated Python code
char pybuf[4096];
size_t pylen = 0;

void append_py(const char *s) {
    size_t slen = strlen(s);
    if (pylen + slen + 1 >= sizeof(pybuf)) return;
    memcpy(pybuf + pylen, s, slen);
    pylen += slen;
    pybuf[pylen] = '\0';
}

void yyerror(const char *s);
int yylex(void);

%}

%union {
    int ival;
    char *sval;
}

%token JODI NA HOILE SOMMAN RAKHO JOG GUN DAO BARAI
%token LBRACE RBRACE LPAREN RPAREN SEMI
%token <ival> NUMBER
%token <sval> IDENT

%type <ival> condition

%%
program
    : if_stmt
      {
          // After parsing, print symbol table and Python code
          printf("Final memory state:\n");
          Var *v = symtab;
          while (v) {
              printf("%s = %d\n", v->name, v->value);
              v = v->next;
          }
          printf("\nGenerated Python code:\n%s\n", pybuf);
      }
    ;

if_stmt
    : JODI LPAREN condition RPAREN LBRACE stmt_list_if RBRACE NA HOILE LBRACE stmt_list_else RBRACE
    ;

condition
    : IDENT SOMMAN NUMBER
      {
          int lhs = get_var($1);
          $$ = (lhs == $3);

          char line[128];
          snprintf(line, sizeof(line), "if %s == %d:\n", $1, $3);
          append_py(line);
      }
    ;

stmt_list_if
    : /* empty */
    | stmt_list_if stmt_if
    ;

stmt_if
    : assign_plus_if
    | assign_mul_if
    | copy_if
    | inc_if
    ;

stmt_list_else
    : /* empty */
    | else_header stmt_list_else_nonempty
    ;

else_header
    : /* empty */
      {
          append_py("else:\n");
      }
    ;

stmt_list_else_nonempty
    : stmt_else
    | stmt_list_else_nonempty stmt_else
    ;

stmt_else
    : assign_plus_else
    | assign_mul_else
    | copy_else
    | inc_else
    ;

/* ----- IF BLOCK STATEMENTS ----- */

assign_plus_if
    : IDENT RAKHO IDENT JOG DAO NUMBER SEMI
      {
          int left = get_var($3);
          int res = left + $6;
          set_var($1, res);

          char line[128];
          snprintf(line, sizeof(line), "    %s = %s + %d\n", $1, $3, $6);
          append_py(line);
      }
    ;

assign_mul_if
    : IDENT RAKHO IDENT GUN DAO IDENT SEMI
      {
          int l = get_var($3);
          int r = get_var($6);
          int res = l * r;
          set_var($1, res);

          char line[128];
          snprintf(line, sizeof(line), "    %s = %s * %s\n", $1, $3, $6);
          append_py(line);
      }
    ;

copy_if
    : IDENT RAKHO IDENT SEMI
      {
          int v = get_var($3);
          set_var($1, v);

          char line[128];
          snprintf(line, sizeof(line), "    %s = %s\n", $1, $3);
          append_py(line);
      }
    ;

inc_if
    : IDENT BARAI DAO SEMI
      {
          int v = get_var($1) + 1;
          set_var($1, v);

          char line[128];
          snprintf(line, sizeof(line), "    %s += 1\n", $1);
          append_py(line);
      }
    ;

/* ----- ELSE BLOCK STATEMENTS (same semantics, different indentation) ----- */

assign_plus_else
    : IDENT RAKHO IDENT JOG DAO NUMBER SEMI
      {
          int left = get_var($3);
          int res = left + $6;
          set_var($1, res);

          char line[128];
          snprintf(line, sizeof(line), "    %s = %s + %d\n", $1, $3, $6);
          append_py(line);
      }
    ;

assign_mul_else
    : IDENT RAKHO IDENT GUN DAO IDENT SEMI
      {
          int l = get_var($3);
          int r = get_var($6);
          int res = l * r;
          set_var($1, res);

          char line[128];
          snprintf(line, sizeof(line), "    %s = %s * %s\n", $1, $3, $6);
          append_py(line);
      }
    ;

copy_else
    : IDENT RAKHO IDENT SEMI
      {
          int v = get_var($3);
          set_var($1, v);

          char line[128];
          snprintf(line, sizeof(line), "    %s = %s\n", $1, $3);
          append_py(line);
      }
    ;

inc_else
    : IDENT BARAI DAO SEMI
      {
          int v = get_var($1) + 1;
          set_var($1, v);

          char line[128];
          snprintf(line, sizeof(line), "    %s += 1\n", $1);
          append_py(line);
      }
    ;

%%
void yyerror(const char *s) {
    fprintf(stderr, "Parse error: %s\n", s);
}