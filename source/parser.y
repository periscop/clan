
   /*+------- <| --------------------------------------------------------**
    **         A                     Clan                                **
    **---     /.\   -----------------------------------------------------**
    **   <|  [""M#                 parser.y                              **
    **-   A   | #   -----------------------------------------------------**
    **   /.\ [""M#         First version: 30/04/2008                     **
    **- [""M# | #  U"U#U  -----------------------------------------------**
         | #  | #  \ .:/
         | #  | #___| #
 ******  | "--'     .-"  ******************************************************
 *     |"-"-"-"-"-#-#-##   Clan : the Chunky Loop Analyzer (experimental)     *
 ****  |     # ## ######  *****************************************************
 *      \       .::::'/                                                       *
 *       \      ::::'/     Copyright (C) 2008 University Paris-Sud 11         *
 *     :8a|    # # ##                                                         *
 *     ::88a      ###      This is free software; you can redistribute it     *
 *    ::::888a  8a ##::.   and/or modify it under the terms of the GNU Lesser *
 *  ::::::::888a88a[]:::   General Public License as published by the Free    *
 *::8:::::::::SUNDOGa8a::. Software Foundation, either version 2.1 of the     *
 *::::::::8::::888:Y8888:: License, or (at your option) any later version.    *
 *::::':::88::::888::Y88a::::::::::::...                                      *
 *::'::..    .   .....   ..   ...  .                                          *
 * This software is distributed in the hope that it will be useful, but       *
 * WITHOUT ANY WARRANTY; without even the implied warranty of MERCHANTABILITY *
 * or FITNESS FOR A PARTICULAR PURPOSE.  See the GNU General Public License   *
 * for more details.                                                          *
 *                                                                            *
 * You should have received a copy of the GNU Lesser General Public License   *
 * along with software; if not, write to the Free Software Foundation, Inc.,  *
 * 59 Temple Place, Suite 330, Boston, MA  02111-1307 USA                     *
 *                                                                            *
 * Clan, the Chunky Loop Analyzer                                             *
 * Written by Cedric Bastoul, Cedric.Bastoul@u-psud.fr                        *
 *                                                                            *
 ******************************************************************************/

/*
 * Clan's parsing has been derived from Jeff Lee and Jutta Degener's work:
 * Yacc Grammar:      http://www.quut.com/c/ANSI-C-grammar-y.html
 * Lex Specification: http://www.quut.com/c/ANSI-C-grammar-l-1998.html
 * FAQ:               http://www.quut.com/c/ANSI-C-grammar-FAQ.html
 * For those about to Clan, Jeff and Jutta, we salute you!
 */

%{
   #include <stdio.h>
   #include <stdlib.h>
   #include <string.h>
   #include <assert.h>
   
   #include <osl/macros.h>
   #include <osl/int.h>
   #include <osl/vector.h>
   #include <osl/relation.h>
   #include <osl/statement.h>
   #include <osl/strings.h>
   #include <osl/generic.h>
   #include <osl/extensions/arrays.h>
   #include <osl/scop.h>
   #include <clan/macros.h>
   #include <clan/vector.h>
   #include <clan/relation.h>
   #include <clan/relation_list.h>
   #include <clan/scop.h>
   #include <clan/symbol.h>
   #include <clan/statement.h>
   #include <clan/options.h>

   int yylex(void);
   void yyerror(char *);
   void clan_scanner_free();

   int clan_parse_error = 0;             /**< Set to 1 during parsing if
                                              encountered an error */
   void clan_parser_add_ld();
   int  clan_parser_nb_ld();
   void clan_parser_log(char *);
   void clan_parser_increment_loop_depth();
   osl_scop_p clan_parse(FILE *, clan_options_p);

   extern FILE *   yyin;                 /**< File to be read by Lex */
   extern char *   scanner_latest_text;  /**< Latest text read by Lex */
   extern int      scanner_line;         /**< Current scanned line */
   extern int      scanner_column;       /**< Scanned column (current) */
   extern int      scanner_column_LALR;  /**< Scanned column (before token) */
   extern int      symbol_nb_arrays;     /**< Number of array symbols */
   extern int      symbol_nb_iterators;  /**< Number of iterator symbols */
   extern int      symbol_nb_parameters; /**< Number of parameter symbols */
   extern int      symbol_nb_functions;  /**< Number of function symbols */

   /* This is the "parser state", a collection of variables that vary
    * during the parsing and thanks to we can extract all SCoP informations.
    */
   osl_scop_p      parser_scop;          /**< SCoP in construction */
   clan_symbol_p   parser_symbol;        /**< Top of the symbol table */
   int             parser_recording;     /**< Boolean: do we record or not? */
   char *          parser_record;        /**< What we record (statement body)*/
   int             parser_loop_depth;    /**< Current loop depth */
   int             parser_if_depth;      /**< Current if depth */
   int *           parser_scattering;    /**< Current statement scattering */
   clan_symbol_p * parser_iterators;     /**< Current iterator list */
   osl_relation_list_p parser_stack;     /**< Iteration domain stack */
   int *           parser_nb_local_dims; /**< Nb of local dims per depth */
   int *           parser_valid_else;    /**< Boolean: OK for else per depth */
   int             parser_indent;        /**< SCoP indentation */

   int             parser_ceild;         /**< Boolean: ceild used */
   int             parser_floord;        /**< Boolean: floord used */
   int             parser_min;           /**< Boolean: min used */
   int             parser_max;           /**< Boolean: max used */
#if 0   
   int *           parser_variables_localvars; /**< List of variables
                                                    in #pragma local-vars */
   int *           parser_variables_liveout;   /**< List of variables
                                                    in #pragma live-out */
#endif

   /* Ugly global variable to keep/read Clan options during parsing. */
   clan_options_p  parser_options = NULL;
%}

/* We expect the if-then-else shift/reduce to be there, nothing else. */
%expect 1

%union { int value;                      /**< An integer value for integers */
         char * symbol;                  /**< A string for identifiers */
         osl_vector_p affex;             /**< An affine expression */
         osl_relation_p setex;           /**< A set of affine expressions */
         osl_relation_list_p list;       /**< List of array accesses */
         osl_statement_p stmt;           /**< List of statements */
         osl_scop_p scop;                /**< SCoP */
       }


%token CONSTANT STRING_LITERAL SIZEOF
%token PTR_OP INC_OP DEC_OP LEFT_OP RIGHT_OP LE_OP GE_OP EQ_OP NE_OP
%token AND_OP OR_OP MUL_ASSIGN DIV_ASSIGN MOD_ASSIGN ADD_ASSIGN
%token SUB_ASSIGN LEFT_ASSIGN RIGHT_ASSIGN AND_ASSIGN
%token XOR_ASSIGN OR_ASSIGN TYPE_NAME

%token TYPEDEF EXTERN STATIC AUTO REGISTER INLINE RESTRICT
%token CHAR SHORT INT LONG SIGNED UNSIGNED FLOAT DOUBLE CONST VOLATILE VOID
%token BOOL COMPLEX IMAGINARY
%token STRUCT UNION ENUM ELLIPSIS

%token CASE DEFAULT IF ELSE SWITCH WHILE DO FOR GOTO CONTINUE BREAK RETURN

%token IGNORE
%token PRAGMALOCALVARS PRAGMALIVEOUT
%token MIN MAX CEILD FLOORD
%token <symbol> ID
%token <value>  INTEGER

%type <stmt>   statement_list
%type <stmt>   statement_or_ignore
%type <stmt>   statement
%type <stmt>   compound_statement
%type <stmt>   expression_statement
%type <stmt>   selection_else_statement
%type <stmt>   selection_statement
%type <stmt>   iteration_statement
%type <stmt>   loop_body
%type <setex>  loop_initialization
%type <setex>  loop_condition
%type <value>  loop_stride

%type <setex>  affine_minmax_expression
%type <setex>  affine_min_expression
%type <setex>  affine_max_expression
%type <setex>  affine_relation
%type <setex>  affine_logical_and_expression
%type <setex>  affine_condition
%type <affex>  affine_primary_expression
%type <affex>  affine_unary_expression
%type <affex>  affine_multiplicative_expression
%type <affex>  affine_ceildfloord_expression
%type <affex>  affine_ceild_expression
%type <affex>  affine_floord_expression
%type <affex>  affine_expression

%type <list>   primary_expression
%type <list>   postfix_expression
%type <list>   argument_expression_list
%type <list>   unary_expression
%type <list>   cast_expression
%type <list>   multiplicative_expression
%type <list>   additive_expression
%type <list>   shift_expression
%type <list>   relational_expression
%type <list>   equality_expression
%type <list>   and_expression
%type <list>   exclusive_or_expression
%type <list>   inclusive_or_expression
%type <list>   logical_and_expression
%type <list>   logical_or_expression
%type <list>   conditional_expression
%type <list>   assignment_expression
%type <list>   expression

%start scop
%%


// +--------------------------------------------------------------------------+
// |                              SCoP GRAMMAR                                |
// +--------------------------------------------------------------------------+


// Rules for a scop
scop:
    statement_list
    {
      int nb_parameters;
      osl_scop_p scop;

      CLAN_debug("rule scop.1: statement_list");
      scop = osl_scop_malloc();
      CLAN_strdup(scop->language, "C");
      
      // Build the SCoP context.
      nb_parameters = clan_symbol_nb_of_type(parser_symbol, CLAN_TYPE_PARAMETER);
      scop->parameters = clan_symbol_to_strings(parser_symbol, CLAN_TYPE_PARAMETER);
      scop->context = osl_relation_pmalloc(CLAN_PRECISION, 0, nb_parameters + 2);
      osl_relation_set_type(scop->context, OSL_TYPE_CONTEXT);
      osl_relation_set_attributes(scop->context, 0, 0, 0, nb_parameters);

      // Set the statements.
      scop->statement = $1;
      
      parser_scop = scop;
      CLAN_debug_call(osl_scop_dump(stderr, scop));
    } 
  ;


// Rules for a statement list
// Return <stmt>
statement_list:
    statement_or_ignore      { $$ = $1; }
  | statement_list
    statement_or_ignore      { $$ = $1; osl_statement_add(&$$, $2); }
  ;


// Rules for a statement or ignore
// Return <stmt>
statement_or_ignore:
    { 
      if (parser_indent == CLAN_UNDEFINED)
        parser_indent = scanner_column_LALR - 1;
    }
    statement                { $$ = $2; }
  | IGNORE                   { $$ = NULL; }
  ; 


// Rules for a statement
// Return <stmt>
statement:
    compound_statement       { $$ = $1; }
  | expression_statement     { $$ = $1; }
  | selection_statement      { $$ = $1; }
  | iteration_statement      { $$ = $1; }
  ;


// Rules for a compound statement
// Return <stmt>
compound_statement:
    '{' '}'                  { $$ = NULL; }
  | '{' statement_list '}'   { $$ = $2; }
;


// +--------------------------------------------------------------------------+
// |                           AFFINE CONTROL PART                            |
// +--------------------------------------------------------------------------+


selection_else_statement:
    ELSE 
    {
      if (!parser_valid_else[parser_if_depth])
	yyerror("unsupported negation of a condition involving a modulo");
    }
    statement
    {
      CLAN_debug("rule selection_else_statement.1: else <stmt>");
      $$ = $3;
      CLAN_debug_call(osl_statement_dump(stderr, $$));
    }
  |
    {
      CLAN_debug("rule selection_else_statement.2: <void>");
      $$ = NULL;
    }
  ;


selection_statement:
    IF '(' affine_condition ')'
    {
      CLAN_debug("rule selection_statement.1.1: if ( condition ) ...");
      osl_relation_list_dup(&parser_stack);
      clan_relation_and(parser_stack->elt, $3);
      parser_if_depth++;
      if ((parser_loop_depth + parser_if_depth) > CLAN_MAX_DEPTH)
	CLAN_error("CLAN_MAX_DEPTH reached, recompile with a higher value");
    }
    statement
    {
      osl_relation_p not_if;
      
      CLAN_debug("rule selection_statement.1.2: if ( condition ) <stmt> ...");
      osl_relation_list_drop(&parser_stack);
      osl_relation_list_dup(&parser_stack);
      if (!clan_relation_existential($3)) {
	not_if = clan_relation_not($3);
	clan_relation_and(parser_stack->elt, not_if);
	osl_relation_free(not_if);
	parser_valid_else[parser_if_depth] = 1;
      }
      else {
	parser_valid_else[parser_if_depth] = 0;
      }
      osl_relation_free($3);
    }
    selection_else_statement
    {
      CLAN_debug("rule selection_statement.1.3: if ( condition ) <stmt>"
	         "[else <stmt>]");
      osl_relation_list_drop(&parser_stack);
      $$ = $6;
      osl_statement_add(&$$, $8);
      parser_if_depth--;
      parser_nb_local_dims[parser_loop_depth + parser_if_depth] = 0;
      CLAN_debug_call(osl_statement_dump(stderr, $$));
    }
  ;


iteration_statement:
    FOR '(' loop_initialization loop_condition loop_stride ')'
    {
      osl_vector_p   iterator_term;
      osl_relation_p iterator_relation;
      osl_relation_p init_constraints;
      osl_relation_p stride_constraints;
      
      CLAN_debug("rule iteration_statement.1.1: for ( init cond stride ) ...");
      clan_parser_increment_loop_depth();

      // Check the stride and the initialization are correct.
      if ($5 == 0)
	yyerror("unsupported zero loop stride");
      if (($5 > 0) && (parser_min || parser_floord))
	yyerror("illegal min or floord in positive stride loop initialization");
      if (($5 < 0) && (parser_max || parser_ceild))
	yyerror("illegal max or ceild in positive stride loop initialization");
      parser_ceild  = 0;
      parser_floord = 0;
      parser_min    = 0;
      parser_max    = 0;

      // Generate the set of constraints contributed by the initialization.
      iterator_term = clan_vector_term(parser_symbol, 0, NULL);
      osl_int_set_si(CLAN_PRECISION, iterator_term->v, parser_loop_depth, 1); 
      iterator_relation = osl_relation_from_vector(iterator_term);
      if ($5 > 0)
	init_constraints = clan_relation_greater(iterator_relation, $3, 0);
      else
	init_constraints = clan_relation_greater($3, iterator_relation, 0);
      osl_vector_free(iterator_term);
      osl_relation_free(iterator_relation);

      // Add the contribution of the initialization to the current domain.
      osl_relation_list_dup(&parser_stack);
      clan_relation_and(parser_stack->elt, init_constraints);
      
      // Add the contribution of the condition to the current domain.
      clan_relation_and(parser_stack->elt, $4);

      // Add the contribution of the stride to the current domain.
      if (($5 != 1) && ($5 != -1)) {
	stride_constraints = clan_relation_stride(parser_stack->elt,
	                                          parser_loop_depth, $5);
	osl_relation_free(parser_stack->elt);
        parser_stack->elt = stride_constraints;
      }
      
      osl_relation_free(init_constraints);
      osl_relation_free($3);
      osl_relation_free($4);
      parser_scattering[2*parser_loop_depth-1] = ($5 > 0) ? 1 : -1;
      parser_scattering[2*parser_loop_depth] = 0;
    }
    loop_body
    {
      CLAN_debug("rule iteration_statement.1.2: for ( init cond stride ) "
	         "body");
      $$ = $8;
      CLAN_debug_call(osl_statement_dump(stderr, $$));
    }
  | loop_infinite
    {
      osl_vector_p   iterator_term;
      osl_relation_p iterator_relation;

      CLAN_debug("rule iteration_statement.2.1: loop_infinite ...");
      clan_symbol_new_iterator(&parser_symbol, parser_iterators,
	                       "clan_infinite_loop", parser_loop_depth);
      clan_parser_increment_loop_depth();
      
      // Generate the constraint clan_infinite_loop >= 0.
      iterator_term = clan_vector_term(parser_symbol, 0, NULL);
      osl_int_set_si(CLAN_PRECISION, iterator_term->v, parser_loop_depth, 1); 
      osl_int_set_si(CLAN_PRECISION, iterator_term->v, 0, 1); 
      iterator_relation = osl_relation_from_vector(iterator_term);
      
      // Add it to the domain stack.
      osl_relation_list_dup(&parser_stack);
      clan_relation_and(parser_stack->elt, iterator_relation);
      osl_vector_free(iterator_term);
      osl_relation_free(iterator_relation);
      parser_scattering[2*parser_loop_depth-1] = 1;
      parser_scattering[2*parser_loop_depth] = 0;
    }
    loop_body
    {
      CLAN_debug("rule iteration_statement.2.2: loop_infinite body");
      $$ = $3;
      CLAN_debug_call(osl_statement_dump(stderr, $$));
    }
  ;


loop_initialization:
    ID
    {
      clan_symbol_new_iterator(&parser_symbol, parser_iterators, $1,
	                       parser_loop_depth);
    }
    '=' affine_minmax_expression ';'
    {
      CLAN_debug("rule lower_bound.1: ID = max_affex ;");
      free($1);
      $$ = $4;
      CLAN_debug_call(osl_relation_dump(stderr, $$));
    }
  ;


loop_condition:
    affine_condition ';'
    {
      CLAN_debug("rule upper_bound.1: <affex> ;");
      $$ = $1;
      CLAN_debug_call(osl_relation_dump(stderr, $$));
    }
  ;


//
// Rules for the for loop increment.
// Handled cases (with s an integer):
// i++, i--; ++i, --i, i = i + v, i = i - s, i += s, i -= s
// return <value>
//
loop_stride:
    ID INC_OP             { $$ =  1;  free($1); }
  | ID DEC_OP             { $$ = -1;  free($1); }
  | INC_OP ID             { $$ =  1;  free($2); }
  | DEC_OP ID             { $$ = -1;  free($2); }
  | ID '=' ID '+' INTEGER { $$ =  $5; free($1); free($3); }
  | ID '=' ID '-' INTEGER { $$ = -$5; free($1); free($3); }
  | ID ADD_ASSIGN INTEGER { $$ =  $3; free($1); }
  | ID SUB_ASSIGN INTEGER { $$ = -$3; free($1); }
  ;


loop_infinite:
    WHILE '(' INTEGER ')'
  | FOR '(' ';' ';' ')'
  ;


loop_body:
    statement
    {
      CLAN_debug("rule loop_body.1: <stmt>");
      parser_loop_depth--;
      clan_symbol_free(parser_iterators[parser_loop_depth]);
      osl_relation_list_drop(&parser_stack);
      $$ = $1;
      parser_scattering[2*parser_loop_depth]++;
      parser_nb_local_dims[parser_loop_depth + parser_if_depth] = 0;
      CLAN_debug_call(osl_statement_dump(stderr, $$));
    }
  ;


// +--------------------------------------------------------------------------+
// |                             AFFINE EXPRESSIONS                           |
// +--------------------------------------------------------------------------+


affine_minmax_expression:
    affine_ceildfloord_expression
    {
      CLAN_debug("rule affine_minmax_expression.1: <affex>");
      $$ = osl_relation_from_vector($1);
      osl_vector_free($1);
      CLAN_debug_call(osl_relation_dump(stderr, $$));
    }
  | minmax '(' affine_minmax_expression ',' affine_minmax_expression ')'
    {
      CLAN_debug("rule affine_minmax_expression.2: "
                 "MAX (affine_minmaxexpression , affine_minmax_expression )");
      $$ = osl_relation_concat_constraints($3, $5);
      osl_relation_free($3);
      osl_relation_free($5);
      CLAN_debug_call(osl_relation_dump(stderr, $$));
    }
  ;


minmax:
    MIN { parser_min = 1; }
  | MAX { parser_max = 1; }
  ;


//
// Rules for min(... operators.
// return <setex>
//
affine_min_expression:
//
// Rule affine_min_expression.1: <affex>
//
    affine_floord_expression
    {
      CLAN_debug("rule affine_min_expression.1: <affex>");
      $$ = osl_relation_from_vector($1);
      osl_vector_free($1);
      CLAN_debug_call(osl_relation_dump(stderr, $$));
    }
//
// Rule affine_min_expression.2 MIN ( aff_min_expr , aff_min_expr )
//
  | MIN '(' affine_min_expression ',' affine_min_expression ')'
    {
      CLAN_debug("rule affine_min_expression.2: "
                 "MIN ( affine_min_expression , affine_min_expresssion");
      $$ = osl_relation_concat_constraints($3, $5);
      osl_relation_free($3);
      osl_relation_free($5);
      CLAN_debug_call(osl_relation_dump(stderr, $$));
    }
  ;


//
// Rules for max(... operators.
// return <setex>
//
affine_max_expression:
//
// Rule affine_max_expression.1: <affex>
//
    affine_ceild_expression
    {
      CLAN_debug("rule affine_max_expression.1: <affex>");
      $$ = osl_relation_from_vector($1);
      osl_vector_free($1);
      CLAN_debug_call(osl_relation_dump(stderr, $$));
    }
//
// Rule affine_max_expression.2: MAX ( aff_max_expr , aff_max_expr )
//
  | MAX '(' affine_max_expression ',' affine_max_expression ')'
    {
      CLAN_debug("rule affine_max_expression.2: "
                 "MAX ( affine_max_expression , affine_max_expression )");
      $$ = osl_relation_concat_constraints($3, $5);
      osl_relation_free($3);
      osl_relation_free($5);
      CLAN_debug_call(osl_relation_dump(stderr, $$));
    }
  ;


//
// Rules for defining an affine condition. A condition is an affine relation
// (possibly with min/max operator(s)) of the form 'affex1 op affex2'
// where affex2 may contain min operators iff op is '<' or '<=', and
// max operators iff op is '>' or '>='.
// return: <setex>
//
affine_relation:
//
// Rule affine_relation.1: max_affex < min_affex
//
    affine_max_expression '<' affine_min_expression
    {
      CLAN_debug("rule affine_relation.1: max_affex < min_affex");
      $$ = clan_relation_greater($3, $1, 1);
      osl_relation_free($1);
      osl_relation_free($3);
      CLAN_debug_call(osl_relation_dump(stderr, $$));
    }
//
// Rule affine_relation.2: min_affex > max_affex
//
  | affine_min_expression '>' affine_max_expression
    {
      CLAN_debug("rule affine_relation.2: min_affex > max_affex");
      $$ = clan_relation_greater($1, $3, 1);
      osl_relation_free($1);
      osl_relation_free($3);
      CLAN_debug_call(osl_relation_dump(stderr, $$));
    }
//
// Rule affine_relation.3: max_affex <= min_affex
//
  | affine_max_expression LE_OP affine_min_expression
    {
      CLAN_debug("rule affine_relation.3: max_affex <= min_affex");
      $$ = clan_relation_greater($3, $1, 0);
      osl_relation_free($1);
      osl_relation_free($3);
      CLAN_debug_call(osl_relation_dump(stderr, $$));
    }
//
// Rule affine_relation.4: min_affex >= max_affex
//
  | affine_min_expression GE_OP affine_max_expression
    {
      CLAN_debug("rule affine_relation.4: min_affex >= max_affex");
      $$ = clan_relation_greater($1, $3, 0);
      osl_relation_free($1);
      osl_relation_free($3);
      CLAN_debug_call(osl_relation_dump(stderr, $$));
    }
//
// Rule affine_relation.5: <affex> == <affex>
//
  | affine_expression EQ_OP affine_expression
    {
      // a==b translates to a-b==0.
      osl_vector_p res;

      CLAN_debug("rule affine_relation.5: <affex> == <affex>");
      // Warning: cases like ceild(M,32) == ceild(N,32) are not handled.
      // Assert if we encounter such a case.
      assert ((osl_int_zero(CLAN_PRECISION, $1->v, 0) ||
	       osl_int_one(CLAN_PRECISION,  $1->v, 0)) &&
	      (osl_int_zero(CLAN_PRECISION, $3->v, 0) ||
	       osl_int_one(CLAN_PRECISION,  $3->v, 0)));
      res = osl_vector_sub($1, $3);
      osl_vector_tag_equality(res);
      $$ = osl_relation_from_vector(res);
      osl_vector_free(res);
      osl_vector_free($1);
      osl_vector_free($3);
      CLAN_debug_call(osl_relation_dump(stderr, $$));
    }
//
// Rule affine_relation.6: ( affine_relation )
//
  | '(' affine_condition ')'
    {
      CLAN_debug("rule affine_relation.6: ( condition )");
      $$ = $2;
      CLAN_debug_call(osl_relation_dump(stderr, $$));
    }
//
// Rule affine_relation.7: ! ( affine_condition )
//
  | '!' '(' affine_condition ')'
    {
      CLAN_debug("rule affine_relation.7: ! ( condition )");
      if (clan_relation_existential($3))
	yyerror("unsupported negation of a condition involving a modulo");
      $$ = clan_relation_not($3);
      osl_relation_free($3);
      CLAN_debug_call(osl_relation_dump(stderr, $$));
    }
//
// Rule affine_relation.8: affine_expression % INTEGER == INTEGER
//
  | affine_expression '%' INTEGER EQ_OP INTEGER
    {
      CLAN_debug("rule affine_relation.8: "
	         "affine_expression %% INTEGER == INTEGER");
      osl_int_set_si(CLAN_PRECISION, $1->v,
	             CLAN_MAX_DEPTH + 1 + clan_parser_nb_ld(), -$3);
      osl_int_add_si(CLAN_PRECISION,
	             $1->v, $1->size - 1, $1->v, $1->size - 1, -$5);
      clan_parser_add_ld();
      $$ = osl_relation_from_vector($1);
      osl_vector_free($1);
      CLAN_debug_call(osl_relation_dump(stderr, $$));
    }
  ;


affine_logical_and_expression:
    affine_relation
    {
      CLAN_debug("rule affine_logical_and_expression.1: affine_relation");
      $$ = $1;
      CLAN_debug_call(osl_relation_dump(stderr, $$));
    }
  | affine_logical_and_expression AND_OP affine_relation
    {
      CLAN_debug("rule affine_logical_and_expression.2: "
	         "affine_logical_and_expression && affine_relation");
      clan_relation_and($1, $3);
      $$ = $1;
      osl_relation_free($3);
      CLAN_debug_call(osl_relation_dump(stderr, $$));
    }
  ;


affine_condition:
    affine_logical_and_expression
    {
      CLAN_debug("rule affine_condition.1: affine_logical_and_expression");
      $$ = $1;
      CLAN_debug_call(osl_relation_dump(stderr, $$));
    }
  | affine_condition OR_OP affine_logical_and_expression
    {
      CLAN_debug("rule affine_condition.2: "
	         "affine_condition || affine_logical_and_expression");
      osl_relation_add(&$1, $3);
      $$ = $1;
      CLAN_debug_call(osl_relation_dump(stderr, $$));
    }
  ;


affine_primary_expression:
    ID
    {
      clan_symbol_p id;

      CLAN_debug("rule affine_primary_expression.1: id");
      id = clan_symbol_add(&parser_symbol, $1, CLAN_UNDEFINED,
                           parser_loop_depth);
      if (id->type == CLAN_TYPE_ARRAY)
        yyerror("variable or array reference in an affine expression");
      else if (id->type == CLAN_TYPE_FUNCTION)
        yyerror("function call in an affine expression");

      $$ = clan_vector_term(parser_symbol, 1, $1);
      free($1);
      CLAN_debug_call(osl_vector_dump(stderr, $$));
    }
  | INTEGER
    {
      CLAN_debug("rule affine_primary_expression.2: INTEGER");
      $$ = clan_vector_term(parser_symbol, $1, NULL);
      CLAN_debug_call(osl_vector_dump(stderr, $$));
    }
  | '(' affine_expression ')'
    {
      CLAN_debug("rule affine_primary_expression.3: "
                 "affine_additive_expression");
      $$ = $2;
      CLAN_debug_call(osl_vector_dump(stderr, $$));
    }
  ;


affine_unary_expression:
    affine_primary_expression
    {
      CLAN_debug("rule affine_unary_expression.1: affine_primary_expression");
      $$ = $1;
      CLAN_debug_call(osl_vector_dump(stderr, $$));
    }
  | '+' affine_primary_expression
    {
      CLAN_debug("rule affine_unary_expression.2: +affine_primary_expression");
      $$ = $2;
      CLAN_debug_call(osl_vector_dump(stderr, $$));
    }
  | '-' affine_primary_expression
    {
      CLAN_debug("rule affine_unary_expression.2: -affine_primary_expression");
      $$ = osl_vector_mul_scalar($2, -1);
      osl_vector_free($2);
      CLAN_debug_call(osl_vector_dump(stderr, $$));
    }
  ;


affine_multiplicative_expression:
    affine_unary_expression
    { 
      CLAN_debug("rule affine_multiplicative_expression.1: "
                 "affine_unary_expression");
      $$ = $1;
      CLAN_debug_call(osl_vector_dump(stderr, $$));
    }
  | affine_multiplicative_expression '*' affine_unary_expression
    {
      int coef;
      
      CLAN_debug("rule affine_multiplicative_expression.2: "
                 "affine_multiplicative_expression * affine_unary_expression");
      if (!osl_vector_is_scalar($1) && !osl_vector_is_scalar($3))
        yyerror("non-affine expression");

      if (osl_vector_is_scalar($1)) {
        coef = osl_int_get_si($1->precision, $1->v, $1->size - 1);
        $$ = osl_vector_mul_scalar($3, coef);
      }
      else {
        coef = osl_int_get_si($3->precision, $3->v, $3->size - 1);
        $$ = osl_vector_mul_scalar($1, coef);
      }
      osl_vector_free($1);
      osl_vector_free($3);
      CLAN_debug_call(osl_vector_dump(stderr, $$));
    }
  | affine_multiplicative_expression '/' affine_unary_expression
    {
      int val1, val2;
      
      CLAN_debug("rule affine_multiplicative_expression.3: "
                 "affine_multiplicative_expression / affine_unary_expression");
      if (!osl_vector_is_scalar($1) || !osl_vector_is_scalar($3))
        yyerror("non-affine expression");
      val1 = osl_int_get_si($1->precision, $1->v, $1->size - 1);
      val2 = osl_int_get_si($3->precision, $3->v, $3->size - 1);
      $$ = clan_vector_term(parser_symbol, val1 / val2, NULL);
      osl_vector_free($1);
      osl_vector_free($3);
      CLAN_debug_call(osl_vector_dump(stderr, $$));
    }
  ;


affine_expression:
    affine_multiplicative_expression
    { 
      CLAN_debug("rule affine_expression.1: "
                 "affine_multiplicative_expression");
      $$ = $1;
      CLAN_debug_call(osl_vector_dump(stderr, $$));
    }
  | affine_expression '+' affine_multiplicative_expression
    {
      CLAN_debug("rule affine_expression.2: "
          "affine_expression + affine_multiplicative_expression");
      $$ = osl_vector_add($1, $3);
      osl_vector_free($1);
      osl_vector_free($3);
      CLAN_debug_call(osl_vector_dump(stderr, $$));
    }
  | affine_expression '-' affine_multiplicative_expression
    {
      CLAN_debug("rule affine_expression.3: "
          "affine_expression - affine_multiplicative_expression");
      $$ = osl_vector_sub($1, $3);
      osl_vector_free($1);
      osl_vector_free($3);
      CLAN_debug_call(osl_vector_dump(stderr, $$));
    }
  ;


affine_ceildfloord_expression:
    affine_expression
    {
      CLAN_debug("affine_ceildloord_expression.1: affine_expression");
      $$ = $1;
      CLAN_debug_call(osl_vector_dump(stderr, $$));
    }
  | ceildfloord '(' affine_expression ',' INTEGER ')'
    {
      CLAN_debug("affine_ceildfloord_expression.2: "
                 "ceildfloord ( affine_expression , INTEGER )");
      osl_int_set_si(CLAN_PRECISION, $3->v, 0, $5);
      $$ = $3;
      CLAN_debug_call(osl_vector_dump(stderr, $$));
    }
  ;


ceildfloord:
    CEILD  { parser_ceild = 1; }
  | FLOORD { parser_floord = 1; }
  ;


affine_ceild_expression:
    affine_expression
    {
      CLAN_debug("affine_ceil_expression.1: affine_expression");
      $$ = $1;
      CLAN_debug_call(osl_vector_dump(stderr, $$));
    }
  | CEILD '(' affine_expression ',' INTEGER ')'
    {
      CLAN_debug("affine_ceil_expression.2: "
                 "CEILD ( affine_expression , INTEGER )");
      osl_int_set_si(CLAN_PRECISION, $3->v, 0, $5);
      $$ = $3;
      CLAN_debug_call(osl_vector_dump(stderr, $$));
    }
  ;


affine_floord_expression:
    affine_expression
    {
      CLAN_debug("affine_floor_expression.1: affine_expression");
      $$ = $1;
      CLAN_debug_call(osl_vector_dump(stderr, $$));
    }
  | FLOORD '(' affine_expression ',' INTEGER ')'
    {
      CLAN_debug("affine_floor_expression.2: "
                 "FLOORD ( affine_expression , INTEGER )");
      osl_int_set_si(CLAN_PRECISION, $3->v, 0, $5);
      $$ = $3;
      CLAN_debug_call(osl_vector_dump(stderr, $$));
    }
  ;


// +--------------------------------------------------------------------------+
// |                          QUASI-ANSI C STATEMENTS                         |
// +--------------------------------------------------------------------------+


primary_expression:
    ID
    {
      int rank, nb_columns;
      osl_relation_p id;
      osl_relation_list_p list;

      CLAN_debug("rule primary_expression.1: ID");
      clan_symbol_add(&parser_symbol, $1, CLAN_TYPE_ARRAY, parser_loop_depth);
      rank = clan_symbol_get_rank(parser_symbol, $1);
      nb_columns = CLAN_MAX_DEPTH + CLAN_MAX_LOCAL_DIMS +
	           CLAN_MAX_PARAMETERS + 2;
      id = osl_relation_pmalloc(CLAN_PRECISION, 0, nb_columns);
      osl_relation_set_attributes(id, 0, parser_loop_depth, 0, CLAN_MAX_PARAMETERS);
      clan_relation_tag_array(id, rank);
      list = osl_relation_list_malloc();
      list->elt = id;
      free($1);
      $$ = list;
      CLAN_debug_call(osl_relation_list_dump(stderr, $$));
    }
  | CONSTANT
    { $$ = NULL; }
  | INTEGER
    { $$ = NULL; }
  | STRING_LITERAL
    { $$ = NULL; }
  | '(' expression ')'
    { $$ = $2; }
  ;


postfix_expression:
    primary_expression
    { $$ = $1; }
  | postfix_expression '[' affine_expression ']' // ANSI: expression
    {
      CLAN_debug("rule postfix_expression.2: postfix_expression [ <affex> ]");
      clan_relation_new_output_vector($1->elt, $3);
      osl_vector_free($3);
      $$ = $1;
      CLAN_debug_call(osl_relation_list_dump(stderr, $$));
    }
  | postfix_expression '(' ')'
    { 
      osl_relation_list_free($1);
      $$ = NULL;
    }
  | postfix_expression '(' argument_expression_list ')'
    {
      osl_relation_list_free($1);
      $$ = $3;
    }
  | postfix_expression '.' ID
    {
      int rank;

      CLAN_debug("rule postfix_expression.4: postfix_expression . ID");
      clan_symbol_add(&parser_symbol, $3, CLAN_TYPE_ARRAY, parser_loop_depth);
      rank = clan_symbol_get_rank(parser_symbol, $3);
      clan_relation_new_output_scalar($1->elt, rank);
      free($3);
      $$ = $1;
      CLAN_debug_call(osl_relation_list_dump(stderr, $$));
    }
  | postfix_expression PTR_OP ID
    {
      int rank;

      CLAN_debug("rule postfix_expression.5: postfix_expression -> ID");
      clan_symbol_add(&parser_symbol, $3, CLAN_TYPE_ARRAY, parser_loop_depth);
      rank = clan_symbol_get_rank(parser_symbol, $3);
      clan_relation_new_output_scalar($1->elt, rank);
      free($3);
      $$ = $1;
      CLAN_debug_call(osl_relation_list_dump(stderr, $$));
    }
  | postfix_expression INC_OP
    { $$ = $1; }
  | postfix_expression DEC_OP
    { $$ = $1; }
  ;

argument_expression_list:
    assignment_expression
    { $$ = $1; }
  | argument_expression_list ',' assignment_expression
    {
      $$ = $1;
      osl_relation_list_add(&$$, $3);
    }
  ;

unary_expression:
    postfix_expression
    { $$ = $1; }
  | INC_OP unary_expression
    { $$ = $2; }
  | DEC_OP unary_expression
    { $$ = $2; }
  | unary_operator cast_expression
    { $$ = $2; }
  | SIZEOF unary_expression
    { $$ = $2; }
  | SIZEOF '(' type_name ')'
    { $$ = NULL; }
  ;

unary_operator:
    '&'
  | '*'
  | '+'
  | '-'
  | '~'
  | '!'
  ;

cast_expression:
    unary_expression
    { $$ = $1; }
  | '(' type_name ')' cast_expression
    { $$ = $4; }
  ;

multiplicative_expression:
    cast_expression
    { $$ = $1; }
  | multiplicative_expression '*' cast_expression
    {
      $$ = $1;
      osl_relation_list_add(&$$, $3);
    }
  | multiplicative_expression '/' cast_expression
    {
      $$ = $1;
      osl_relation_list_add(&$$, $3);
    }
  | multiplicative_expression '%' cast_expression
    {
      $$ = $1;
      osl_relation_list_add(&$$, $3);
    }
  ;

additive_expression:
    multiplicative_expression
    { $$ = $1; }
  | additive_expression '+' multiplicative_expression
    {
      $$ = $1;
      osl_relation_list_add(&$$, $3);
    }
  | additive_expression '-' multiplicative_expression
    {
      $$ = $1;
      osl_relation_list_add(&$$, $3);
    }
  ;

shift_expression:
    additive_expression
    { $$ = $1; }
  | shift_expression LEFT_OP additive_expression
    {
      $$ = $1;
      osl_relation_list_add(&$$, $3);
    }
  | shift_expression RIGHT_OP additive_expression
    {
      $$ = $1;
      osl_relation_list_add(&$$, $3);
    }
  ;

relational_expression:
    shift_expression
    { $$ = $1; }
  | relational_expression '<' shift_expression
    {
      $$ = $1;
      osl_relation_list_add(&$$, $3);
    }
  | relational_expression '>' shift_expression
    {
      $$ = $1;
      osl_relation_list_add(&$$, $3);
    }
  | relational_expression LE_OP shift_expression
    {
      $$ = $1;
      osl_relation_list_add(&$$, $3);
    }
  | relational_expression GE_OP shift_expression
    {
      $$ = $1;
      osl_relation_list_add(&$$, $3);
    }
  ;

equality_expression:
    relational_expression
    { $$ = $1; }
  | equality_expression EQ_OP relational_expression
    {
      $$ = $1;
      osl_relation_list_add(&$$, $3);
    }
  | equality_expression NE_OP relational_expression
    {
      $$ = $1;
      osl_relation_list_add(&$$, $3);
    }
  ;

and_expression:
    equality_expression
    { $$ = $1; }
  | and_expression '&' equality_expression
    {
      $$ = $1;
      osl_relation_list_add(&$$, $3);
    }
  ;

exclusive_or_expression:
    and_expression
    { $$ = $1; }
  | exclusive_or_expression '^' and_expression
    {
      $$ = $1;
      osl_relation_list_add(&$$, $3);
    }
  ;

inclusive_or_expression:
    exclusive_or_expression
    { $$ = $1; }
  | inclusive_or_expression '|' exclusive_or_expression
    {
      $$ = $1;
      osl_relation_list_add(&$$, $3);
    }
  ;

logical_and_expression:
    inclusive_or_expression
    { $$ = $1; }
  | logical_and_expression AND_OP inclusive_or_expression
    {
      $$ = $1;
      osl_relation_list_add(&$$, $3);
    }
  ;

logical_or_expression:
    logical_and_expression
    { $$ = $1; }
  | logical_or_expression OR_OP logical_and_expression
    {
      $$ = $1;
      osl_relation_list_add(&$$, $3);
    }
  ;

conditional_expression:
    logical_or_expression
    { $$ = $1; }
  | logical_or_expression '?' expression ':' conditional_expression
    {
      $$ = $1;
      osl_relation_list_add(&$$, $3);
      osl_relation_list_add(&$$, $5);
    }
  ;

assignment_expression:
    conditional_expression
    {
      CLAN_debug("rule assignment_expression.1: conditional_expression;");
      $$ = $1;
      clan_relation_list_define_type($$, OSL_TYPE_READ);
      CLAN_debug_call(osl_relation_list_dump(stderr, $$));
    }
  | unary_expression assignment_operator assignment_expression
    {
      osl_relation_list_p list;

      CLAN_debug("rule assignment_expression.2: unary_expression "
	         "assignment_operator assignment_expression;");
      $$ = $1;
      // Accesses of $1 are READ except the last one which is a WRITE.
      clan_relation_list_define_type($$, OSL_TYPE_READ);
      list = $$;
      while (list->next != NULL)
	list = list->next;
      osl_relation_set_type(list->elt, OSL_TYPE_WRITE);
      osl_relation_list_add(&$$, $3);
      CLAN_debug_call(osl_relation_list_dump(stderr, $$));
    }
  ;

assignment_operator:
    '='
  | MUL_ASSIGN
  | DIV_ASSIGN
  | MOD_ASSIGN
  | ADD_ASSIGN
  | SUB_ASSIGN
  | LEFT_ASSIGN
  | RIGHT_ASSIGN
  | AND_ASSIGN
  | XOR_ASSIGN
  | OR_ASSIGN
  ;

expression:
    assignment_expression
    { $$ = $1; }
  | expression ',' assignment_expression
    {
      $$ = $1;
      osl_relation_list_add(&$$, $3);
    }
  ;

expression_statement:
    ';'
    {
      CLAN_debug("rule expression_statement.1: ;");
      $$ = NULL;
      CLAN_debug_call(osl_statement_dump(stderr, $$));
    }
  | 
    {
      CLAN_strdup(parser_record, scanner_latest_text);
      parser_recording = CLAN_TRUE;
    }
    expression ';'
    {
      osl_statement_p statement;
      osl_body_p body;
      
      CLAN_debug("rule expression_statement.2: expression ;");
      statement = osl_statement_malloc();

      // - 1. Domain
      statement->domain = osl_relation_clone(parser_stack->elt);
      osl_relation_set_type(statement->domain, OSL_TYPE_DOMAIN);
      osl_relation_set_attributes(statement->domain, parser_loop_depth, 0,
	                          clan_parser_nb_ld(), CLAN_MAX_PARAMETERS);

      // - 2. Scattering
      statement->scattering = clan_relation_scattering(parser_scattering,
	                                               parser_loop_depth);

      // - 3. Array accesses
      statement->access = $2;

      // - 4. Body.
      body = osl_body_malloc();
      body->iterators = clan_symbol_array_to_strings(parser_iterators,
	                                             parser_loop_depth);
      body->expression = osl_strings_encapsulate(parser_record);
      statement->body = osl_generic_malloc();
      statement->body->interface = osl_body_interface();
      statement->body->data = body;
      parser_recording = CLAN_FALSE;
      
      parser_scattering[2*parser_loop_depth]++;

      $$ = statement;
      CLAN_debug_call(osl_statement_dump(stderr, $$));
    }
  ;


// +--------------------------------------------------------------------------+
// |                              ANSI C CASTING                              |
// +--------------------------------------------------------------------------+


constant_expression:
    conditional_expression
  ;

declaration_specifiers:
    storage_class_specifier
  | storage_class_specifier declaration_specifiers
  | type_specifier
  | type_specifier declaration_specifiers
  | type_qualifier
  | type_qualifier declaration_specifiers
  ;

storage_class_specifier:
    TYPEDEF
  | EXTERN
  | STATIC
  | AUTO
  | REGISTER
  ;

type_specifier:
    VOID
  | CHAR
  | SHORT
  | INT
  | LONG
  | FLOAT
  | DOUBLE
  | SIGNED
  | UNSIGNED
  | struct_or_union_specifier
  | enum_specifier
  | TYPE_NAME
  ;

struct_or_union_specifier:
    struct_or_union ID '{' struct_declaration_list '}' { free($2); }
  | struct_or_union '{' struct_declaration_list '}'
  | struct_or_union ID { free($2); }
  ;

struct_or_union:
    STRUCT
  | UNION
  ;

struct_declaration_list:
    struct_declaration
  | struct_declaration_list struct_declaration
  ;

struct_declaration:
    specifier_qualifier_list struct_declarator_list ';'
  ;

specifier_qualifier_list:
    type_specifier specifier_qualifier_list
  | type_specifier
  | type_qualifier specifier_qualifier_list
  | type_qualifier
  ;

struct_declarator_list:
    struct_declarator
  | struct_declarator_list ',' struct_declarator
  ;

struct_declarator:
    declarator
  | ':' constant_expression
  | declarator ':' constant_expression
  ;

enum_specifier:
    ENUM '{' enumerator_list '}'
  | ENUM ID '{' enumerator_list '}' { free($2); }
  | ENUM ID { free($2); }
  ;

enumerator_list:
    enumerator
  | enumerator_list ',' enumerator
  ;

enumerator:
    ID { free($1); }
  | ID '=' constant_expression { free($1); }
  ;

type_qualifier:
    CONST
  | VOLATILE
  ;

declarator:
    pointer direct_declarator
  | direct_declarator
  ;

direct_declarator:
    ID { free($1); }
  | '(' declarator ')'
  | direct_declarator '[' constant_expression ']'
  | direct_declarator '[' ']'
  | direct_declarator '(' parameter_type_list ')'
  | direct_declarator '(' identifier_list ')'
  | direct_declarator '(' ')'
  ;

pointer:
    '*'
  | '*' type_qualifier_list
  | '*' pointer
  | '*' type_qualifier_list pointer
  ;

type_qualifier_list:
    type_qualifier
  | type_qualifier_list type_qualifier
  ;


parameter_type_list:
    parameter_list
  | parameter_list ',' ELLIPSIS
  ;

parameter_list:
    parameter_declaration
  | parameter_list ',' parameter_declaration
  ;

parameter_declaration:
    declaration_specifiers declarator
  | declaration_specifiers abstract_declarator
  | declaration_specifiers
  ;

identifier_list:
    ID { free($1); }
  | identifier_list ',' ID { free($3); }
  ;

type_name:
    specifier_qualifier_list
  | specifier_qualifier_list abstract_declarator
  ;

abstract_declarator:
    pointer
  | direct_abstract_declarator
  | pointer direct_abstract_declarator
  ;

direct_abstract_declarator:
    '(' abstract_declarator ')'
  | '[' ']'
  | '[' constant_expression ']'
  | direct_abstract_declarator '[' ']'
  | direct_abstract_declarator '[' constant_expression ']'
  | '(' ')'
  | '(' parameter_type_list ')'
  | direct_abstract_declarator '(' ')'
  | direct_abstract_declarator '(' parameter_type_list ')'
  ;

%%


void yyerror(char *s) {
  int i, line = 1;
  char c = 'C';
  FILE *file;
  
  fprintf(stderr, "[Clan] Error: %s at line %d, column %d.\n", s,
          scanner_line, scanner_column - 1);
  
  // Print a message to show where is the problem.
  if ((parser_options != NULL) && (parser_options->name != NULL)) {
    file = fopen(parser_options->name, "r");
    if (file != NULL) {
      // Go to the right line.
      while (line != scanner_line) {
        c = fgetc(file);
        if (c == '\n')
          line++;
      }

      // Print the line.
      while (c != EOF) {
        c = fgetc(file);
        fprintf(stderr, "%c", c);
        if (c == '\n')
          break;
      }

      // Print the situation line.
      for (i = 0; i < scanner_column - 1; i++) {
        if (i < scanner_column - 5)
          fprintf(stderr, " ");
        else if (i < scanner_column - 2)
          fprintf(stderr, "~");
        else
          fprintf(stderr, "^\n");
      }
      fclose(file);
    }
    else {
      CLAN_warning("cannot open input file");
    }
  }
  
  clan_parse_error = 1;
}


void clan_parser_add_ld() {
  parser_nb_local_dims[parser_loop_depth + parser_if_depth]++;

  if (CLAN_DEBUG) {
    int i;
    CLAN_debug("parser_nb_local_dims updated");
    for (i = 0; i <= parser_loop_depth + parser_if_depth; i++)
      fprintf(stderr, "%d:%d ", i, parser_nb_local_dims[i]);
    fprintf(stderr, "\n");
  }
  
  if (clan_parser_nb_ld() > CLAN_MAX_LOCAL_DIMS)
    CLAN_error("CLAN_MAX_LOCAL_DIMS reached, recompile with a higher value");
}


int clan_parser_nb_ld() {
  int i, nb_ld = 0;

  for (i = 0; i <= parser_loop_depth + parser_if_depth; i++)
    nb_ld += parser_nb_local_dims[i]; 
  return nb_ld;
}


void clan_parser_increment_loop_depth() {
  parser_loop_depth++;
  if ((parser_loop_depth + parser_if_depth) > CLAN_MAX_DEPTH)
    CLAN_error("CLAN_MAX_DEPTH reached, recompile with a higher value");
}


/**
 * clan_parser_initialize_state function:
 * this function achieves the initialization of the "parser state": a
 * collection of variables that vary during the parsing and thanks to we
 * can extract all SCoP informations.
 */
void clan_parser_initialize_state(clan_options_p options) {
  int i, nb_columns, depth;

  nb_columns        = CLAN_MAX_DEPTH + CLAN_MAX_LOCAL_DIMS +
                      CLAN_MAX_PARAMETERS + 2;
  depth             = CLAN_MAX_DEPTH;
  parser_symbol     = NULL;
  parser_scop       = NULL;
  parser_stack      = osl_relation_list_malloc();
  parser_stack->elt = osl_relation_pmalloc(CLAN_PRECISION, 0, nb_columns);
  parser_loop_depth = 0;
  parser_options    = options;
  parser_record     = NULL;
  parser_if_depth   = 0;
  parser_ceild      = 0;
  parser_floord     = 0;
  parser_min        = 0;
  parser_max        = 0;
  parser_indent     = CLAN_UNDEFINED;

  CLAN_malloc(parser_nb_local_dims, int *, depth * sizeof(int));
  CLAN_malloc(parser_valid_else,    int *, depth * sizeof(int));
  for (i = 0; i < depth; i++) {
    parser_nb_local_dims[i] = 0;
    parser_valid_else[i] = 0;
  }
  
  CLAN_malloc(parser_scattering, int *, (2 * depth + 1) * sizeof(int));
  for (i = 0; i < 2 * depth + 1; i++)
    parser_scattering[i] = 0;

  CLAN_malloc(parser_iterators, clan_symbol_p *, depth*sizeof(clan_symbol_p));

#if 0
  parser_variables_localvars =
    (int*)malloc((CLAN_MAX_LOCAL_VARIABLES + 1) * sizeof(int));
  parser_variables_liveout =
    (int*)malloc((CLAN_MAX_LOCAL_VARIABLES + 1) * sizeof(int));
#endif

  /* Reset also the Symbol global variables. */
  symbol_nb_iterators  = 0;
  symbol_nb_parameters = 0;
  symbol_nb_arrays     = 0;
  symbol_nb_functions  = 0;

#if 0
  for (i = 0; i <= CLAN_MAX_LOCAL_VARIABLES; ++i)
    parser_variables_localvars[i] = -1;
  for (i = 0; i <= CLAN_MAX_LOCAL_VARIABLES; ++i)
    parser_variables_liveout[i] = -1;
#endif
}


/**
 * clan_parser_free_state function:
 * this function frees the memory allocated for the "parser state".
 */
void clan_parser_free_state() {
  clan_symbol_free(parser_symbol);
  free(parser_scattering);
  free(parser_iterators);
  free(parser_nb_local_dims);
  free(parser_valid_else);
  osl_relation_list_drop(&parser_stack);
#if 0
  free(parser_variables_localvars);
  free(parser_variables_liveout);
#endif
}


/**
 * clan_parse function:
 * this function parses a file to extract a SCoP and returns, if successful,
 * a pointer to the osl_scop_t structure.
 * \param input   The file to parse (already open).
 * \param options Options for file parsing.
 */
osl_scop_p clan_parse(FILE * input, clan_options_p options) {
  osl_generic_p arrays;
  osl_scop_p scop;
  yyin = input;

  clan_parser_initialize_state(options);

  yyparse();

  CLAN_debug("parsing done");

  fclose(yyin);
  clan_scanner_free();

  if (!clan_parse_error) {
    /*if (parser_variables_localvars[0] != -1 ||
      parser_variables_liveout[0] != -1)
      clan_scop_fill_options(parser_scop, parser_variables_localvars,
      parser_variables_liveout);
    */
    scop = parser_scop;
    if (CLAN_DEBUG) {
      CLAN_debug("SCoP before compaction:");
      osl_scop_dump(stderr, scop);
    }
    
    clan_scop_compact(scop);

    if (CLAN_DEBUG) {
      CLAN_debug("SCoP after compaction:");
      osl_scop_dump(stderr, scop);
    }

    // Add extensions.
    scop->registry = osl_interface_get_default_registry();
    clan_scop_generate_scatnames(scop);
    arrays = clan_symbol_to_arrays(parser_symbol);
    osl_generic_add(&scop->extension, arrays);
    clan_scop_generate_coordinates(scop, options->name);

    // OpenScop wants an empty context rather than a NULL context.
    if (scop->context == NULL) {
      scop->context = osl_relation_pmalloc(CLAN_PRECISION, 0, 2);
      scop->context->type = OSL_TYPE_CONTEXT;
      osl_relation_set_attributes(scop->context, 0, 0, 0, 0);
    }
  }
  else {
    scop = NULL;
  }
  clan_parser_free_state();
  CLAN_debug("parser state successfully freed");

  return scop;
}

