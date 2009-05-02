
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
 *       \      ::::'/     Copyright (C) 2008 Cedric Bastoul                  *
 *     :8a|    # # ##                                                         *
 *     ::88a      ###      This is free software; you can redistribute it     *
 *    ::::888a  8a ##::.   and/or modify it under the terms of the GNU Lesser *
 *  ::::::::888a88a[]:::   General Public License as published by the Free    *
 *::8:::::::::SUNDOGa8a::. Software Foundation, either version 3 of the       *
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
 * Written by Cedric Bastoul, Cedric.Bastoul@inria.fr                         *
 *                                                                            *
 ******************************************************************************/


%{
   #include <stdio.h>
   #include <stdlib.h>
   #include <string.h>
   #include <clan/macros.h>
   #include <clan/vector.h>
   #include <clan/matrix.h>
   #include <clan/scop.h>
   #include <clan/symbol.h>
   #include <clan/statement.h>
   #include <clan/options.h>

   int yylex(void);
   void yyerror(char *);
   void clan_parser_log(char *);
   scoplib_scop_p clan_parse(FILE *, clan_options_p);

   extern FILE * yyin;                  /**< File to be read by Lex */
   extern char scanner_latest_text[];   /**< Latest text read by Lex */

   /* This is the "parser state", a collection of variables that vary
    * during the parsing and thanks to we can extract all SCoP informations.
    */
   scoplib_scop_p      parser_scop;        /**< SCoP in construction */
   scoplib_statement_p parser_statement;   /**< Statement in construction */
   clan_symbol_p       parser_symbol;      /**< Top of the symbol table */
   int                 parser_recording;   /**< Boolean: do we record or not? */
   char *              parser_record;      /**< What we record
					      (statement body) */
   int                 parser_depth = 0;   /**< Current loop depth */
   int *               parser_scheduling;  /**< Current statement scheduling */
   clan_symbol_p *     parser_iterators;   /**< Current iterator list */
   scoplib_matrix_p    parser_domain;      /**< Current iteration domain */
   int                 parser_nb_cons = 0; /**< Current number of constraints */
   int *               parser_consperdim;  /**< Constraint nb for each
					      dimension */
   int                 parser_fake_arrays = 0; /**< Current count of fake
					       array ids */

%}

%union { int value;                     /**< An integer value for integers */
         char * symbol;                 /**< A string for identifiers */
         scoplib_vector_p affex;        /**< An affine expression */
         scoplib_matrix_p setex;        /**< A set of affine expressions */
         scoplib_matrix_p rw[2];        /**< Read and write array accesses */
       }

%token IGNORE
%token IF ELSE FOR
%token MIN MAX
%token REAL
%token <symbol> ID
%token <value>  INTEGER

%token syRPARENTHESIS syLPARENTHESIS syRBRACKET syLBRACKET syRBRACE syLBRACE
%token sySEMICOLON syCOMMA syPOINT

%token opEQUAL opLEQ opGEQ opLOWER opGREATER opPLUS opMINUS
%token opINCREMENTATION opDECREMENTATION opNOT
%token opMULTIPLY opDIVIDE opMOD opAND opOR opCOMP
%token opASSIGNMENT
%token opPLUSEQUAL opMINUSEQUAL opMULTIPLYEQUAL opDIVIDEEQUAL
%token opMODEQUAL opANDEQUAL opOREQUAL opCOMPEQUAL
%token opLAND opLOR opQMARK opCOLON

%left opPLUS opMINUS
%left opMULTIPLY opDIVIDE opMOD opAND opOR opCOMP
%left opEQUAL opLEQ opGEQ opLOWER opGREATER opLAND opCOLON opQMARK
%left opNOT
%left MAXPRIORITY /* Dummy token to help in removing shift/reduce conflicts */

%type <setex>  condition
%type <setex>  min_affine_expression
%type <setex>  max_affine_expression
%type <affex>  affine_expression
%type <affex>  term
%type <setex>  array_index
%type <setex>  variable
%type <setex>  variable_list
%type <setex>  expression
%type <rw>     assignment
%type <symbol> id

%%

/*
 * Start rule.
 *
 */
program:
    instruction_list
      {
	/* The full program was parsed. Allocate and fill the final
	   .scop structures. */
	int nb_parameters, nb_arrays;

        parser_scop->parameters = clan_symbol_id_array(parser_symbol,
                                                       SCOPLIB_TYPE_PARAMETER,
                                                       &nb_parameters);
        parser_scop->nb_parameters = nb_parameters;
        parser_scop->arrays = clan_symbol_id_array(parser_symbol,
                                                   SCOPLIB_TYPE_ARRAY,
                                                   &nb_arrays);
        parser_scop->nb_arrays = nb_arrays;
        parser_scop->context = scoplib_matrix_malloc(0,nb_parameters+2);
      }
  |
  ;

/*
 * Rules for a list of instructions
 *
 */
instruction_list:
    instruction
  | instruction_list instruction
  | IGNORE
  | instruction_list IGNORE
  ;


/*
 * Rules for a bloc of instructions.
 */
bloc:
/*
 * Rule 1: bloc -> instruction
 */
    instruction
/*
 * Rule 2: bloc -> { instruction_list }
 */
  | syRBRACE instruction_list syLBRACE
  ;


/*
 * Rules for a program instruction. Either a for(..., if(..., or a
 * regular statement.
 *
 */
instruction:
/*
 * Rule 1: instruction -> for ( id = <setex>; condition; increment) bloc
 *
 */
    FOR
    syRPARENTHESIS
    id
      {
        clan_symbol_p symbol;
        symbol = clan_symbol_add(&parser_symbol,$3,
                                 SCOPLIB_TYPE_ITERATOR,parser_depth+1);
	/* Ensure that the returned symbol was either a new one,
	   either from the same type. */
	if (symbol->type != SCOPLIB_TYPE_ITERATOR)
	  {
	    fprintf (stderr, "[Clan] Error: the input file is not a SCoP\n"
		     "\t> A loop iterator was previously used as a parameter"
		     "\n");
	    exit(1);
	  }
	/* Update the rank, in case a symbol with the same name was
	   already existing. */
	if (symbol->rank != parser_depth + 1)
	  symbol->rank = parser_depth + 1;
        parser_iterators[parser_depth] = symbol;
	/* Memorize the current iterator as a negative constraint prefix */
      }
    opASSIGNMENT
    max_affine_expression
      {
        scoplib_vector_p parser_i_term = clan_vector_term(parser_symbol,1,$3);
	scoplib_vector_tag_inequality(parser_i_term);
	int i, j;
	for (i = 0; i < $6->NbRows; ++i)
	  {
	    for (j = 1; j < $6->NbColumns; ++j)
	      SCOPVAL_oppose($6->p[i][j],$6->p[i][j]);
	    scoplib_matrix_add_vector($6,parser_i_term,i);
	  }
	scoplib_matrix_insert_matrix(parser_domain,$6,parser_nb_cons);

        parser_nb_cons += $6->NbRows;
        parser_consperdim[parser_depth] += $6->NbRows;
	scoplib_vector_free(parser_i_term);
        free($3);
	scoplib_matrix_free($6);
      }
    sySEMICOLON
    condition
      {
	scoplib_matrix_insert_matrix(parser_domain,$9,parser_nb_cons);
        parser_nb_cons += $9->NbRows;
        parser_consperdim[parser_depth] += $9->NbRows;
      }
    sySEMICOLON
    incrementation
    syLPARENTHESIS
      {
        parser_depth++;
        parser_scheduling[parser_depth] = 0;
      }
    bloc
      {
        parser_depth--;
        parser_scheduling[parser_depth]++;
        parser_nb_cons -= parser_consperdim[parser_depth];
        parser_consperdim[parser_depth] = 0;
      }
/*
 * Rule 2: instruction -> if (condition) bloc
 *
 */
  |  IF syRPARENTHESIS condition syLPARENTHESIS
      {
	/* Insert the condition constraint in the current parser domain. */
	scoplib_matrix_insert_matrix(parser_domain,$3,parser_nb_cons);
        parser_nb_cons += $3->NbRows;
      }
    bloc
      {
        parser_nb_cons -= $3->NbRows;
	/* Remove the condition constraint from the current parser domain. */
	int i, j;
	for (i = parser_nb_cons; i < parser_domain->NbRows - 1; ++i)
	  for (j = 0; j < parser_domain->NbColumns; ++j)
	    SCOPVAL_assign(parser_domain->p[i][j],parser_domain->p[i+1][j]);
      }
/*
 * Rule 3: instruction -> assignment
 *
 */
  |   {
        parser_statement = scoplib_statement_malloc();
        parser_record = (char *)malloc(SCOPLIB_MAX_STRING * sizeof(char));
        parser_recording = CLAN_TRUE;
        /* Yacc needs Lex to read the next token to ensure we are starting
         * an assignment. So we keep track of the latest text Lex read
         * and we start the statement body with it.
         */
        strcpy(parser_record,scanner_latest_text);
      }
    assignment
      {
	/* Deal with statements without surrounding loop by adding a
	   fake iterator */
	int old_parser_depth = parser_depth;
	if (parser_depth == 0)
	  {
	    char* fakeiter = strdup("fakeiter");
	    clan_symbol_p symbol = clan_symbol_lookup(parser_symbol, fakeiter);
	    if (symbol)
	      free(fakeiter);
	    else
	      symbol = clan_symbol_add(&parser_symbol,fakeiter,
				       SCOPLIB_TYPE_ITERATOR,parser_depth+1);
	    parser_iterators[parser_depth] = symbol;
	    scoplib_vector_p constraint =
	      scoplib_vector_malloc(parser_domain->NbColumns);
	    SCOPVAL_set_si(constraint->p[1],1);
	    parser_depth++;
	    scoplib_matrix_replace_vector(parser_domain,constraint,parser_nb_cons);
	    parser_nb_cons++;
	    scoplib_vector_free(constraint);
	  }
	/* Construct the statement structure from the parser state */
	parser_statement->domain = scoplib_matrix_list_malloc();
	parser_statement->domain->elt = scoplib_matrix_ncopy(parser_domain,
							  parser_nb_cons);
        parser_statement->schedule = clan_matrix_scheduling(parser_scheduling,
                                                            parser_depth);
        parser_statement->read = $2[0];
        parser_statement->write = $2[1];
        parser_statement->body = parser_record;
        parser_statement->nb_iterators = parser_depth;
        parser_statement->iterators = clan_symbol_iterators(parser_iterators,
                                                            parser_depth);
	if (parser_statement->write == NULL)
	  parser_statement->write =
	    scoplib_matrix_malloc(0, parser_domain->NbColumns);
	if (parser_statement->read == NULL)
	  parser_statement->read =
	    scoplib_matrix_malloc(0, parser_domain->NbColumns);
        parser_recording = CLAN_FALSE;
        scoplib_statement_add(&(parser_scop->statement),parser_statement);
	/* We were parsing a statement without iterator. Restore the
	   original state */
	if (old_parser_depth == 0)
	  {
	    --parser_depth;
	    --parser_nb_cons;
	    parser_consperdim[parser_depth] = 0;
	  }
        parser_scheduling[parser_depth]++;
      }
  ;


/*
 * Rules for the for loop increment.
 * Handled cases:
 * i++, ++i, i = i + 1, i += 1
 *
 */
incrementation:
    id opINCREMENTATION
      {
        free($1);
      }
  | opINCREMENTATION id
      {
        free($2);
      }
  | id opASSIGNMENT id opPLUS INTEGER
     {
       if ($5 != 1)
	 {
	   fprintf (stderr, "[Clan] Error: loop increment is not 1\n");
	   exit (1);
	 }
       free ($1);
       free ($3);
     }
  | id opPLUSEQUAL INTEGER
     {
       if ($3 != 1)
	 {
	   fprintf (stderr, "[Clan] Error: loop increment is not 1\n");
	   exit (1);
	 }
       free ($1);
     }
  ;


/*
 * Reduction rules for min(... operators.
 * return <setex>
 *
 */
min_affine_expression:
    affine_expression
      {
	$$ = scoplib_matrix_from_vector($1);
        scoplib_vector_free($1);
      }
  | MIN syRPARENTHESIS min_affine_expression syCOMMA min_affine_expression
    syLPARENTHESIS
     {
       $$ = scoplib_matrix_concat($3, $5);
     }
  ;


/*
 * Reduction rules for max(... operators.
 * return <setex>
 *
 */
max_affine_expression:
    affine_expression
      {
	$$ = scoplib_matrix_from_vector($1);
        scoplib_vector_free($1);
      }
  | MAX syRPARENTHESIS max_affine_expression syCOMMA max_affine_expression
    syLPARENTHESIS
     {
       $$ = scoplib_matrix_concat($3, $5);
     }
  ;


/*
 * Reduction rules for affine expression.
 * return <affex>
 *
 */
affine_expression:
    term
      {
        $$ = $1;
      }
  | affine_expression opPLUS affine_expression
      {
        $$ = scoplib_vector_add($1,$3);
        scoplib_vector_free($1);
        scoplib_vector_free($3);
      }
  | affine_expression opMINUS affine_expression
      {
        $$ = scoplib_vector_sub($1,$3);
	scoplib_vector_free($1);
        scoplib_vector_free($3);
      }
  | syRPARENTHESIS affine_expression syLPARENTHESIS
      {
        $$ = $2;
      }
  ;


/*
 * Reduction rules for a term.
 * return <affex>
 *
 */
term:
/*
 * Rule 1: term -> INT
 */
    INTEGER
      {
        $$ = clan_vector_term(parser_symbol,$1,NULL);
      }
/*
 * Rule 2: term -> id
 */
  | id
      {
        clan_symbol_add(&parser_symbol,$1,SCOPLIB_TYPE_UNKNOWN,parser_depth);
        $$ = clan_vector_term(parser_symbol,1,$1);
        free($1);
      }
/*
 * Rule 3: term -> - INT
 */
  | opMINUS INTEGER
      {
        $$ = clan_vector_term(parser_symbol,-($2),NULL);
      }
/*
 * Rule 4: term -> INT * id
 */
  | INTEGER opMULTIPLY id
      {
        clan_symbol_add(&parser_symbol,$3,SCOPLIB_TYPE_UNKNOWN,parser_depth);
        $$ = clan_vector_term(parser_symbol,$1,$3);
        free($3);
      }
/*
 * Rule 5: term -> INT * INT
 */
  | INTEGER opMULTIPLY INTEGER
      {
        $$ = clan_vector_term(parser_symbol, ($1) * ($3), NULL);
      }
/*
 * Rule 6: term -> INT / INT
 */
  | INTEGER opDIVIDE INTEGER
      {
        $$ = clan_vector_term(parser_symbol, ($1) / ($3), NULL);
      }
/*
 * Rule 7: term -> - INT * id
 */
  | opMINUS INTEGER opMULTIPLY id
      {
        clan_symbol_add(&parser_symbol,$4,SCOPLIB_TYPE_UNKNOWN,parser_depth);
        $$ = clan_vector_term(parser_symbol,-($2),$4);
        free($4);
      }
  ;


/*
 * Rules for defining a condition. A condition is an affine expression
 * (possibly with min/max operator(s)) of the form 'affex1 op affex2'
 * where affex2 may contain min operators iff op is '<' or '<=', and
 * max operators iff op is '>' or '>='.
 * return: <setex>
 */
condition:
/*
 * Rule 1: condition -> <affex> < min_affex
 */
    affine_expression opLOWER min_affine_expression
      {
        /* a<b translates to -a+b-1>=0 */
	int i;
	scoplib_vector_p tmp = scoplib_vector_add_scalar($1,1);
	scoplib_vector_tag_inequality(tmp);
	for (i = 0; i < $3->NbRows; ++i)
	  scoplib_matrix_sub_vector($3, tmp, i);
	scoplib_vector_free($1);
	$$ = $3;
      }
/*
 * Rule 2: condition -> <affex> > max_affex
 */
  | affine_expression opGREATER max_affine_expression
      {
        /* a>b translates to a-b-1>=0 */
	int i, j;
	scoplib_vector_p tmp = scoplib_vector_add_scalar($1,-1);
	scoplib_vector_tag_inequality(tmp);
	for (i = 0; i < $3->NbRows; ++i)
	  {
	    for (j = 1; j < $3->NbColumns; ++j)
	      SCOPVAL_oppose($3->p[i][j],$3->p[i][j]);
	    scoplib_matrix_add_vector($3,tmp,i);
	  }
	scoplib_vector_free($1);
	$$ = $3;
      }
/*
 * Rule 3: condition -> <affex> <= min_affex
 */
  | affine_expression opLEQ min_affine_expression
      {
        /* a<=b translates to -a+b>=0 */
	int i;
	scoplib_vector_p tmp = scoplib_vector_add_scalar($1,0);
	scoplib_vector_tag_inequality(tmp);
	for (i = 0; i < $3->NbRows; ++i)
	  scoplib_matrix_sub_vector($3,tmp,i);
	scoplib_vector_free($1);
	$$ = $3;
      }
/*
 * Rule 4: condition -> <affex> >= max_affex
 */
  | affine_expression opGEQ max_affine_expression
      {
        /* a>=b translates to a-b>=0 */
	int i, j;
	scoplib_vector_p tmp = scoplib_vector_add_scalar($1,0);
	scoplib_vector_tag_inequality(tmp);
	for (i = 0; i < $3->NbRows; ++i)
	  {
	    for (j = 1; j < $3->NbColumns; ++j)
	      SCOPVAL_oppose($3->p[i][j],$3->p[i][j]);
	    scoplib_matrix_add_vector($3,tmp,i);
	  }
	scoplib_vector_free($1);
	$$ = $3;
      }
/*
 * Rule 5: condition -> <affex> == <affex>
 */
  | affine_expression opEQUAL affine_expression
      {
        /* a==b translates to a-b==0 */
	scoplib_vector_p res = scoplib_vector_sub($1,$3);
	scoplib_vector_tag_equality(res);
	$$ = scoplib_matrix_from_vector(res);
	scoplib_vector_free(res);
        scoplib_vector_free($1);
	scoplib_vector_free($3);
      }
/*
 * Rule 6: condition -> ( condition )
 */
  | syRPARENTHESIS condition syLPARENTHESIS
      {
	$$ = $2;
      }
/*
 * Rule 7: condition -> condition && condition
 */
  | condition opLAND condition
     {
       $$ = scoplib_matrix_concat($1,$3);
       scoplib_matrix_free($1);
       scoplib_matrix_free($3);
     }
  ;


/*
 * Shortcut rules for reduction operators (+=, -=, ...)
 *
 */
reduction_operator:
    opPLUSEQUAL
  | opMINUSEQUAL
  | opMULTIPLYEQUAL
  | opDIVIDEEQUAL
  | opMODEQUAL
  | opANDEQUAL
  | opOREQUAL
  | opCOMPEQUAL
  ;

/*
 * Shortcut rules for unary increment/decrement operators (-- and ++)
 *
 */
unary_operator:
    opINCREMENTATION
  | opDECREMENTATION
  ;


/*
 * Rules for an assignment (an instruction which is not a 'for' nor an 'if')
 * return: <rw>
 *
 */
assignment:
/*
 * Rule 1: assignment -> var = expression;
 */
    variable opASSIGNMENT expression sySEMICOLON
      {
        $$[0] = $3;
        $$[1] = $1;
      }
/*
 * Rule 2: assignment -> var red_op expression;
 */
  | variable reduction_operator expression sySEMICOLON
      {
        $$[0] = scoplib_matrix_concat($1,$3);
        scoplib_matrix_free($3);
        $$[1] = $1;
      }
/*
 * Rule 3: assignment -> var un_op;
 */
  | variable unary_operator sySEMICOLON
    {
       $$[0] = $1;
       $$[1] = scoplib_matrix_copy($1);
    }
/*
 * Rule 4: assignment -> un_op var;
 */
  | unary_operator variable sySEMICOLON
    {
       $$[0] = $2;
       $$[1] = scoplib_matrix_copy($2);
    }
/*
 * Rule 5: assignment -> var;
 */
  | variable sySEMICOLON
     {
       $$[0] = $1;
       $$[1] = NULL;
     }
  ;


/*
 * Shortcut rules for all binary operators BUT '='.
 *
 */
binary_operator:
    opPLUS
  | opMINUS
  | opMULTIPLY
  | opDIVIDE
  | opMOD
  | opGEQ
  | opGREATER
  | opLEQ
  | opLOWER
  | opEQUAL
  | opAND
  | opOR
  | opCOMP
  ;

/*
 * Rules for an expression.
 * return: <setex>
 */
expression:
/*
 * Rule 1: expression -> number
 */
    NUMBER
      {
        $$ = NULL;
      }
/*
 * Rule 2: expression -> - number
 */
  | opMINUS NUMBER
      {
        $$ = NULL;
      }
/*
 * Rule 3: expression -> variable
 */
  | variable
      {
        $$ = $1;
      }
/*
 * Rule 4: expression -> expression bin_op expression
 * The %prec is a hack to force to shift in this rule.
 */
  | expression binary_operator expression %prec MAXPRIORITY
      {
        $$ = scoplib_matrix_concat($1,$3);
	scoplib_matrix_free($1);
        scoplib_matrix_free($3);
      }
/*
 * Rule 5: expression -> ! expression
 */
  | opNOT expression
      {
        $$ = $2;
      }
/*
 * Rule 6: expression -> ( expression )
 */
  | syRPARENTHESIS expression syLPARENTHESIS
      {
        $$ = $2;
      }
/*
 * Rule 7: expression -> expression : expression ? expression
 */
  | expression opQMARK expression opCOLON expression
      {
	scoplib_matrix_p tmp = scoplib_matrix_concat($1,$3);
        $$ = scoplib_matrix_concat(tmp,$5);
	scoplib_matrix_free(tmp);
	scoplib_matrix_free($1);
	scoplib_matrix_free($3);
	scoplib_matrix_free($5);
      }
  ;


/*
 * Rules to describe a variable. It can be a scalar ('a'), a
 * n-dimensional array ('a[i]'), or a procedure call ('a(b,c,d)')
 * return: <setex>
 */
variable:
/*
 * Rule 1: variable -> id
 * ex: variable -> a
 */
    id
      {
        int rank;
        scoplib_matrix_p matrix;
	char* s = (char*) $1;
	clan_symbol_p symbol = clan_symbol_lookup(parser_symbol, s);
	int fake_array = 0;
	// Special code to treat iterators as RHS. We emulate a fake
	// array, with a distinct array name per access of the
	// iterator as RHS.
	if (symbol && symbol->type == SCOPLIB_TYPE_ITERATOR)
	  {
	    s = (char*) malloc(sizeof(char) * 12 + strlen(SCOPLIB_FAKE_ARRAY));
	    sprintf(s, "%s_%d", SCOPLIB_FAKE_ARRAY, parser_fake_arrays++);
	    symbol = clan_symbol_lookup(parser_symbol, s);
	    fake_array = 1;
	  }
        clan_symbol_add(&parser_symbol, s, SCOPLIB_TYPE_ARRAY, parser_depth);
        rank = clan_symbol_get_rank(parser_symbol, s);
        matrix = scoplib_matrix_malloc(1,CLAN_MAX_DEPTH + CLAN_MAX_PARAMETERS + 2);
        clan_matrix_tag_array(matrix, rank);
	if (fake_array) 
	  SCOPVAL_set_si(matrix->p[0][clan_symbol_get_rank(parser_symbol, $1)],
			 1);
        $$ = matrix;
        free($1);
      }
/*
 * Rule 2: variable -> id array_index
 * ex: variable -> a[i][j]
 */
  | id array_index
      {
        int rank;
        clan_symbol_add(&parser_symbol,$1,SCOPLIB_TYPE_ARRAY,parser_depth);
        rank = clan_symbol_get_rank(parser_symbol,$1);
        clan_matrix_tag_array($2,rank);
        $$ = $2;
        free($1);
      }
/*
 * Rule 3: variable -> id ( variable_list )
 * ex: variable -> a(b,c,d)
 */
   | id syRPARENTHESIS variable_list syLPARENTHESIS
      {
	$$ = $3;
	free($1);
      }
/*
 * Rule 4: variable -> - variable
 */
   | opMINUS variable
      {
	$$ = $2;
      }
/*
 * Rule 5: variable -> + variable
 */
   | opPLUS variable
      {
	$$ = $2;
      }
  ;


/*
 * Rules to describe a list of variables, separated by a comma.
 * return: <setex>
 */
variable_list:
/*
 * Rule 1: variable_list -> variable
 */
    variable
      {
	$$ = $1;
      }
/*
 * Rule 2: variable_list -> variable_list , variable
 */
  | variable_list syCOMMA variable
      {
	$$ = scoplib_matrix_concat($1,$3);
      }
/*
 * Rule 3: variable_list ->
 */
  |
      {
	$$ = NULL;
      }
  ;


/*
 * Rules for n-level array indices
 * return: <setex>
 *
 */
array_index:
/*
 * Rule 1: array_index -> [ <affex> ]
 */
    syRBRACKET affine_expression syLBRACKET
      {
        $$ = scoplib_matrix_from_vector($2);
        scoplib_vector_free($2);
      }
/*
 * Rule 2: array_index -> array_index [ <affex> ]
 */
  | array_index syRBRACKET affine_expression syLBRACKET
      {
	if ($1 != NULL)
	  scoplib_matrix_insert_vector($1,$3,$1->NbRows);
        scoplib_vector_free($3);
        $$ = $1;
      }
  ;


/*
 * Rules to eliminate the parenthesis around an identifier.
 *
 * return <symbol>
 */
id:
/*
 * Rule 1: id -> ID
 */
    ID
     {
       $$ = $1;
     }
/*
 * Rule 2: id -> ( ID )
 */
  | syRPARENTHESIS ID syLPARENTHESIS
     {
       $$ = $2;
     }
  ;

NUMBER:
    INTEGER
  | REAL
  ;

%%


void
yyerror(char *s)
{
  fprintf(stderr, "%s\n", s);
}


/**
 * clan_parser_initialize_state function:
 * this function achieves the initialization of the "parser state": a
 * collection of variables that vary during the parsing and thanks to we
 * can extract all SCoP informations.
 **
 * - 02/05/2008: First version.
 */
void
clan_parser_initialize_state()
{
  int i, nb_rows, nb_columns, depth;

  nb_rows    = CLAN_MAX_CONSTRAINTS;
  nb_columns = CLAN_MAX_DEPTH + CLAN_MAX_PARAMETERS + 2;
  depth      = CLAN_MAX_DEPTH;

  parser_scop   = scoplib_scop_malloc();
  parser_domain = scoplib_matrix_malloc(nb_rows,nb_columns);
  parser_symbol = NULL;

  parser_scheduling = (int *)malloc(depth * sizeof(int));
  parser_consperdim = (int *)malloc(depth * sizeof(int));
  for (i = 0; i < depth; i++)
  {
    parser_scheduling[i] = 0;
    parser_consperdim[i] = 0;
  }
  parser_iterators = (clan_symbol_p *)malloc(depth * sizeof(clan_symbol_p));
}


/**
 * clan_parser_free_state function:
 * this function frees the memory allocated for the "parser state", except
 * for parser_scop, obviously.
 **
 * - 02/05/2008: First version.
 */
void
clan_parser_free_state()
{
  scoplib_matrix_free(parser_domain);
  clan_symbol_free(parser_symbol);
  free(parser_scheduling);
  free(parser_consperdim);
  free(parser_iterators);
}


/**
 * clan_parse function:
 * this function parses a file to extract a SCoP and returns, if successful,
 * a pointer to the scoplib_scop_t structure.
 * \param input   The file to parse (already open).
 * \param options Options for file parsing.
 **
 * - 01/05/2008: First version.
 */
scoplib_scop_p
clan_parse(FILE * input, clan_options_p options)
{
  yyin = input;

  clan_parser_initialize_state();

  yyparse();

  clan_parser_free_state();
  clan_scop_compact(parser_scop);
  fclose(yyin);

  return parser_scop;
}

