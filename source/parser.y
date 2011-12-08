
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

   int clan_parse_error = 0; /**< Set to 1 during parsing if
                                  encountered an error */
   void clan_parser_log(char *);
   osl_scop_p clan_parse(FILE *, clan_options_p);

   extern FILE * yyin;                 /**< File to be read by Lex */
   extern char * scanner_latest_text;  /**< Latest text read by Lex */

   /* This is the "parser state", a collection of variables that vary
    * during the parsing and thanks to we can extract all SCoP informations.
    */
   osl_scop_p      parser_scop;        /**< SCoP in construction */
   osl_statement_p parser_statement;   /**< Statement in construction */
   clan_symbol_p   parser_symbol;      /**< Top of the symbol table */
   int             parser_recording;   /**< Boolean: do we record or not? */
   char *          parser_record;      /**< What we record (statement body) */
   int             parser_depth = 0;   /**< Current loop depth */
   int *           parser_scattering;  /**< Current statement scattering */
   clan_symbol_p * parser_iterators;   /**< Current iterator list */
   osl_relation_p  parser_domain;      /**< Current iteration domain */
   int             parser_nb_cons = 0; /**< Current number of constraints */
   int *           parser_consperdim;  /**< Constraint nb for each dimension */
   int *           parser_variables_localvars; /**< List of variables
                                                    in #pragma local-vars */
   int *           parser_variables_liveout;   /**< List of variables
                                                    in #pragma live-out */

   /* Ugly global variable to keep/read Clan options during parsing. */
   clan_options_p  parser_options = NULL;


%}

%union { int value;                 /**< An integer value for integers */
         char * symbol;             /**< A string for identifiers */
         osl_vector_p affex;        /**< An affine expression */
         osl_relation_p setex;      /**< A set of affine expressions */
         osl_relation_list_p list;  /**< List of array accesses */
       }

%token IGNORE
%token IF ELSE FOR PRAGMALOCALVARS PRAGMALIVEOUT
%token MIN MAX CEILD FLOORD
%token REAL
%token <symbol> ID
%token <value>  INTEGER

%token syRPARENTHESIS syLPARENTHESIS syRBRACKET syLBRACKET syRBRACE syLBRACE
%token sySEMICOLON syCOMMA syPOINT syARROW

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
%type <list>   variable_list
%type <list>   expression
%type <list>   expression_list
%type <list>   assignment
%type <list>   function_call
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
	int nb_parameters = clan_symbol_nb_of_type(parser_symbol,
                                                   CLAN_TYPE_PARAMETER);

        parser_scop->parameters = clan_symbol_to_strings(parser_symbol,
                                                         CLAN_TYPE_PARAMETER);
	if (parser_options->bounded_context)
	  {
	    parser_scop->context = osl_relation_pmalloc(CLAN_PRECISION,
		                                        nb_parameters,
						        nb_parameters + 2);
	    int i;
	    for (i = 0; i < nb_parameters; ++i)
	      {
		osl_int_set_si(CLAN_PRECISION,
		               parser_scop->context->m[i], 0, 1);
		osl_int_set_si(CLAN_PRECISION,
		               parser_scop->context->m[i], i+1, 1);
		osl_int_set_si(CLAN_PRECISION,
		               parser_scop->context->m[i], nb_parameters+1, 1);
	      }
	  }
	else
          {
	    parser_scop->context = osl_relation_pmalloc(CLAN_PRECISION,
	                                                0, nb_parameters + 2);
          }
        osl_relation_set_type(parser_scop->context, OSL_TYPE_CONTEXT);
        osl_relation_set_attributes(parser_scop->context,
                                    0, 0, 0, nb_parameters);
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
  | syRBRACE instruction_list syLBRACE
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
                                 CLAN_TYPE_ITERATOR,parser_depth+1);
	/* Ensure that the returned symbol was either a new one,
	   either from the same type. */
	if (symbol->type != CLAN_TYPE_ITERATOR)
	  {
	    yyerror("[Clan] Error: the input file is not a SCoP\n"
		    "\t> A loop iterator was previously used as a parameter"
		    "\n");
	    return 0;
	  }
	/* Update the rank, in case a symbol with the same name was
	   already existing. */
	if (symbol->rank != parser_depth + 1)
	  symbol->rank = parser_depth + 1;
        parser_iterators[parser_depth] = clan_symbol_clone_one(symbol);
	/* Memorize the current iterator as a negative constraint prefix */
      }
    opASSIGNMENT
    max_affine_expression
      {
        osl_vector_p parser_i_term = clan_vector_term(parser_symbol,1,$3);
	osl_vector_tag_inequality(parser_i_term);
	int i, j;
	for (i = 0; i < $6->nb_rows; ++i)
	  {
	    for (j = 1; j < $6->nb_columns; ++j)
	      osl_int_oppose(CLAN_PRECISION, $6->m[i], j, $6->m[i], j);
	    osl_relation_add_vector($6,parser_i_term,i);
	  }
	osl_relation_insert_constraints(parser_domain, $6, parser_nb_cons);

        parser_nb_cons += $6->nb_rows;
        parser_consperdim[parser_depth] += $6->nb_rows;
	osl_vector_free(parser_i_term);
        free($3);
	osl_relation_free($6);
      }
    sySEMICOLON
    condition
      {
	osl_relation_insert_constraints(parser_domain, $9, parser_nb_cons);
        parser_nb_cons += $9->nb_rows;
        parser_consperdim[parser_depth] += $9->nb_rows;
        osl_relation_free($9);
      }
    sySEMICOLON
    incrementation
    syLPARENTHESIS
      { 
        parser_depth++;
        parser_scattering[parser_depth] = 0;
      }
    bloc
      {
        parser_depth--;
        parser_scattering[parser_depth]++;
        parser_nb_cons -= parser_consperdim[parser_depth];
        parser_consperdim[parser_depth] = 0;
	clan_symbol_free(parser_iterators[parser_depth]);
      }
/*
 * Rule 2: instruction -> if (condition) bloc
 *
 */
  |  IF syRPARENTHESIS condition syLPARENTHESIS
      {
	/* Insert the condition constraint in the current parser domain. */
	osl_relation_insert_constraints(parser_domain, $3, parser_nb_cons);
        parser_nb_cons += $3->nb_rows;
      }
    bloc
      {
        parser_nb_cons -= $3->nb_rows;
	/* Remove the condition constraint from the current parser domain. */
	int i, j;
	for (i = parser_nb_cons; i < parser_domain->nb_rows - 1; ++i)
	  for (j = 0; j < parser_domain->nb_columns; ++j)
	    osl_int_assign(CLAN_PRECISION,
		           parser_domain->m[i], j,
		           parser_domain->m[i+1], j);
      }
/*
 * Rule 3: instruction -> assignment
 *
 */
  |   {
        parser_statement = osl_statement_malloc();
        parser_recording = CLAN_TRUE;
        /* Yacc needs Lex to read the next token to ensure we are starting
         * an assignment. So we keep track of the latest text Lex read
         * and we start the statement body with it.
         */
        CLAN_strdup(parser_record, scanner_latest_text);
      }
    assignment
      {
        osl_body_p body;
	/* Deal with statements without surrounding loop by adding a
	   fake iterator */
	int old_parser_depth = parser_depth;
	if (parser_depth == 0)
	  {
	    char* fakeiter = strdup(CLAN_FAKEITER);
	    clan_symbol_p symbol;
	    symbol = clan_symbol_add(&parser_symbol, fakeiter,
				     CLAN_TYPE_ITERATOR, parser_depth+1);
	    free(fakeiter);
	    parser_iterators[parser_depth] = symbol;
	    osl_vector_p constraint = osl_vector_pmalloc(CLAN_PRECISION,
		parser_domain->nb_columns);
	    osl_int_set_si(CLAN_PRECISION, constraint->v, 1, 1);
	    parser_depth++;
	    osl_relation_replace_vector(parser_domain, constraint,
                                             parser_nb_cons);
	    parser_nb_cons++;
	    osl_vector_free(constraint);
	  }
	
	/* Build the statement structure from the parser state */
	/* - 1. Domain */
	parser_statement->domain = osl_relation_nclone(parser_domain,
	                                               parser_nb_cons);
        osl_relation_set_type(parser_statement->domain, OSL_TYPE_DOMAIN);
        osl_relation_set_attributes(parser_statement->domain,
            parser_depth, 0, 0, CLAN_MAX_PARAMETERS);

	/* - 2. Scattering */
        parser_statement->scattering = clan_relation_scattering(
	    parser_scattering, parser_depth);

	/* - 3. Array Accesses */
        parser_statement->access = $2;
	
	/* - 5. Body */
        body = osl_body_malloc();
        body->iterators = clan_symbol_array_to_strings(parser_iterators, parser_depth);
        body->expression = osl_strings_encapsulate(parser_record);
        parser_statement->body = osl_generic_malloc();
        parser_statement->body->interface = osl_body_interface();
        parser_statement->body->data = body;
        
	parser_recording = CLAN_FALSE;
        osl_statement_add(&(parser_scop->statement), parser_statement);
	
	/* We were parsing a statement without iterator. Restore the
	   original state */
	if (old_parser_depth == 0)
	  {
	    --parser_depth;
	    --parser_nb_cons;
	    parser_consperdim[parser_depth] = 0;
	  }
        parser_scattering[parser_depth]++;
      }
/*
 * Rule 4: instruction -> #pragma local-vars <vars>
 * NOTE: THIS RULE IS REPONSIBLE FOR 10 shift/reduce conflicts.
 * It is ok, though, the parsing will be correct.
 * FIXME: ndCed: the variable_list sounds craply used (function call)...
 *               Look at this.
 * TODO: rewrite it.
  | PRAGMALOCALVARS variable_list
      {
	int i, j;
	osl_relation_p m = $2->elt;
	for (i = 0; i <  m->nb_rows; ++i)
	  {
	    int id = osl_int_get_si(CLAN_PRECISION, m->m[i], 0);
	    for (j = 0; parser_variables_localvars[j] != -1 &&
		   parser_variables_localvars[j] != id; ++j)
	      ;
	    if (j == CLAN_MAX_LOCAL_VARIABLES)
	      {
		yyerror("[Clan] Error: maximum number of local variables reached\n");
		return 0;
	      }
	    if (parser_variables_localvars[j] == -1)
	      parser_variables_localvars[j] = id;
	  }
      }
 */
/*
 * Rule 5: instruction -> #pragma live-out <vars>
 * NOTE: THIS RULE IS REPONSIBLE FOR 10 shift/reduce conflicts.
 * It is ok, though, the parsing will be correct.
 * TODO: rewrite it.
  | PRAGMALIVEOUT variable_list
      {
	int i, j;
	osl_relation_p m = $2->elt;
	for (i = 0; i <  m->nb_rows; ++i)
	  {
	    int id = osl_int_get_si(CLAN_PRECISION, m->m[i], 0);
	    for (j = 0; parser_variables_liveout[j] != -1 &&
		   parser_variables_liveout[j] != id; ++j)
	      ;
	    if (j == CLAN_MAX_LOCAL_VARIABLES)
	      {
		yyerror("[Clan] Error: maximum number of live-out variables reached\n");
		return 0;
	      }
	    if (parser_variables_liveout[j] == -1)
	      parser_variables_liveout[j] = id;
	  }
      }
 */
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
	   yyerror("[Clan] Error: loop increment is not 1\n");
	   return 0;
	 }
       free ($1);
       free ($3);
     }
  | id opPLUSEQUAL INTEGER
     {
       if ($3 != 1)
	 {
	   yyerror("[Clan] Error: loop increment is not 1\n");
	   return 0;
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
	$$ = osl_relation_from_vector($1);
        osl_vector_free($1);
      }
  | MIN syRPARENTHESIS min_affine_expression syCOMMA min_affine_expression
    syLPARENTHESIS
     {
       $$ = osl_relation_concat_constraints($3, $5);
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
	$$ = osl_relation_from_vector($1);
        osl_vector_free($1);
      }
  | MAX syRPARENTHESIS max_affine_expression syCOMMA max_affine_expression
    syLPARENTHESIS
     {
       $$ = osl_relation_concat_constraints($3, $5);
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
        $$ = osl_vector_add($1,$3);
        osl_vector_free($1);
        osl_vector_free($3);
      }
  | affine_expression opMINUS affine_expression
      {
        $$ = osl_vector_sub($1,$3);
	osl_vector_free($1);
        osl_vector_free($3);
      }
  | syRPARENTHESIS affine_expression syLPARENTHESIS
      {
        $$ = $2;
      }
  | CEILD syRPARENTHESIS affine_expression syCOMMA term syLPARENTHESIS
      {
	osl_int_assign(CLAN_PRECISION, $3->v, 0, $5->v, $5->size - 1);
	$$ = $3;
      }
  | FLOORD syRPARENTHESIS affine_expression syCOMMA term syLPARENTHESIS
      {
	osl_int_assign(CLAN_PRECISION, $3->v, 0, $5->v, $5->size - 1);
	$$ = $3;
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
        $$ = clan_vector_term(parser_symbol, $1, NULL);
      }
/*
 * Rule 2: term -> id
 */
  | id
      {
        clan_symbol_add(&parser_symbol, $1, CLAN_TYPE_UNKNOWN, parser_depth);
        $$ = clan_vector_term(parser_symbol, 1, $1);
        free($1);
      }
/*
 * Rule 3: term -> - INT
 */
  | opMINUS INTEGER
      {
        $$ = clan_vector_term(parser_symbol, -($2), NULL);
      }
/*
 * Rule 4: term -> INT * id
 */
  | INTEGER opMULTIPLY id
      {
        clan_symbol_add(&parser_symbol, $3, CLAN_TYPE_UNKNOWN, parser_depth);
        $$ = clan_vector_term(parser_symbol, $1, $3);
        free($3);
      }
/*
 * Rule 4': term -> id * INT
 */
  | id opMULTIPLY INTEGER
      {
        clan_symbol_add(&parser_symbol, $1, CLAN_TYPE_UNKNOWN, parser_depth);
        $$ = clan_vector_term(parser_symbol, $3, $1);
        free($1);
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
        clan_symbol_add(&parser_symbol, $4, CLAN_TYPE_UNKNOWN, parser_depth);
        $$ = clan_vector_term(parser_symbol, -($2), $4);
        free($4);
      }
/*
 * Rule 7': term -> - id * INT
 */
  | opMINUS id opMULTIPLY INTEGER
      {
        clan_symbol_add(&parser_symbol, $2, CLAN_TYPE_UNKNOWN, parser_depth);
        $$ = clan_vector_term(parser_symbol, -($4), $2);
        free($2);
      }
/*
 * Rule 8: term -> - id
 */
  | opMINUS id
      {
        clan_symbol_add(&parser_symbol, $2, CLAN_TYPE_UNKNOWN, parser_depth);
        $$ = clan_vector_term(parser_symbol, -1, $2);
        free($2);
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
	osl_vector_p tmp = osl_vector_add_scalar($1, 1);
	osl_vector_tag_inequality(tmp);
	for (i = 0; i < $3->nb_rows; ++i)
	  {
	    /* We have parsed a ceild/floord at an earlier stage. */
	    if (!osl_int_zero(CLAN_PRECISION, $3->m[i], 0) &&
                !osl_int_one(CLAN_PRECISION, $3->m[i], 0))
	      {
		osl_int_p val = osl_int_malloc(CLAN_PRECISION);
		osl_int_assign(CLAN_PRECISION, val, 0, $3->m[i], 0);
		osl_int_set_si(CLAN_PRECISION, $3->m[i], 0, 0);
		osl_vector_p tmp2 = osl_vector_add_scalar($1, 0);
		int j;
		for (j = 1; j < $1->size; ++j)
                  osl_int_mul(CLAN_PRECISION, tmp2->v, j, $1->v, j, val, 0);
		osl_vector_p tmp3 = osl_vector_add_scalar(tmp2, 1);
		osl_vector_tag_inequality(tmp3);
		osl_relation_sub_vector($3, tmp3, i);
		osl_vector_free(tmp2);
		osl_vector_free(tmp3);
                osl_int_free(CLAN_PRECISION, val, 0);
	      }
	    else
	      osl_relation_sub_vector($3, tmp, i);
	  }
	osl_vector_free($1);
	osl_vector_free(tmp);
	$$ = $3;
      }
/*
 * Rule 2: condition -> <affex> > max_affex
 */
  | affine_expression opGREATER max_affine_expression
      {
        /* a>b translates to a-b-1>=0 */
	int i, j;
	osl_vector_p tmp = osl_vector_add_scalar($1, -1);
	osl_vector_tag_inequality(tmp);
	for (i = 0; i < $3->nb_rows; ++i)
	  {
	    for (j = 1; j < $3->nb_columns; ++j)
              osl_int_oppose(CLAN_PRECISION, $3->m[i], j, $3->m[i], j);
	    /* We have parsed a ceild/floord at an earlier stage. */
	    if (!osl_int_zero(CLAN_PRECISION, $3->m[i], 0) &&
                !osl_int_one(CLAN_PRECISION, $3->m[i], 0))
	      {
		osl_int_p val = osl_int_malloc(CLAN_PRECISION);
		osl_int_assign(CLAN_PRECISION, val, 0, $3->m[i], 0);
		osl_int_set_si(CLAN_PRECISION, $3->m[i], 0, 0);
		osl_vector_p tmp2 = osl_vector_add_scalar($1,0);
		int j;
		for (j = 1; j < $1->size; ++j)
                  osl_int_mul(CLAN_PRECISION, tmp2->v, j, $1->v, j, val, 0);
		osl_vector_p tmp3 = osl_vector_add_scalar(tmp2,-1);
		osl_vector_tag_inequality(tmp3);
		osl_relation_add_vector($3, tmp3, i);
		osl_vector_free(tmp2);
		osl_vector_free(tmp3);
                osl_int_free(CLAN_PRECISION, val, 0);
	      }
           else
                osl_relation_add_vector($3,tmp,i);
	  }
        osl_vector_free($1);
        osl_vector_free(tmp);
        $$ = $3;
      }
/*
 * Rule 3: condition -> <affex> <= min_affex
 */
  | affine_expression opLEQ min_affine_expression
      {
        /* a<=b translates to -a+b>=0 */
	int i;
	osl_vector_p tmp = osl_vector_add_scalar($1,0);
	osl_vector_tag_inequality(tmp);
	for (i = 0; i < $3->nb_rows; ++i)
	  {
	    /* We have parsed a ceild/floord at an earlier stage. */
	    if (!osl_int_zero(CLAN_PRECISION, $3->m[i], 0) &&
                !osl_int_one(CLAN_PRECISION, $3->m[i], 0))
	      {
		osl_int_p val = osl_int_malloc(CLAN_PRECISION);
		osl_int_assign(CLAN_PRECISION, val, 0, $3->m[i], 0);
		osl_int_set_si(CLAN_PRECISION, $3->m[i], 0, 0);
		osl_vector_p tmp2 = osl_vector_add_scalar($1,0);
		int j;
		for (j = 1; j < $1->size; ++j)
                  osl_int_mul(CLAN_PRECISION, tmp2->v, j, $1->v, j, val, 0);
		osl_vector_tag_inequality(tmp2);
		osl_relation_sub_vector($3, tmp2, i);
		osl_vector_free(tmp2);
                osl_int_free(CLAN_PRECISION, val, 0);
	      }
	    else
                osl_relation_sub_vector($3,tmp,i);
	  }
        osl_vector_free($1);
        osl_vector_free(tmp);
        $$ = $3;
      }
/*
 * Rule 4: condition -> <affex> >= max_affex
 */
  | affine_expression opGEQ max_affine_expression
      {
        /* a>=b translates to a-b>=0 */
	int i, j;
	osl_vector_p tmp = osl_vector_add_scalar($1,0);
	osl_vector_tag_inequality(tmp);
	for (i = 0; i < $3->nb_rows; ++i)
	  {
	    for (j = 1; j < $3->nb_columns; ++j)
              osl_int_oppose(CLAN_PRECISION, $3->m[i], j, $3->m[i], j);
	    /* We have parsed a ceild/floord at an earlier stage. */
	    if (!osl_int_zero(CLAN_PRECISION, $3->m[i], 0) &&
                !osl_int_one(CLAN_PRECISION, $3->m[i], 0))
	      {
		osl_int_p val = osl_int_malloc(CLAN_PRECISION);
		osl_int_assign(CLAN_PRECISION, val, 0, $3->m[i], 0);
		osl_int_set_si(CLAN_PRECISION, $3->m[i], 0, 0);
		osl_vector_p tmp2 = osl_vector_add_scalar($1,0);
		int j;
		for (j = 1; j < $1->size; ++j)
                  osl_int_mul(CLAN_PRECISION, tmp2->v, j, $1->v, j, val, 0);
		osl_vector_tag_inequality(tmp2);
		osl_relation_add_vector($3, tmp2, i);
		osl_vector_free(tmp2);
                osl_int_free(CLAN_PRECISION, val, 0);
	      }
	    else
                osl_relation_add_vector($3,tmp,i);
	  }
        osl_vector_free($1);
        osl_vector_free(tmp);
        $$ = $3;
      }
/*
 * Rule 5: condition -> <affex> == <affex>
 */
  | affine_expression opEQUAL affine_expression
      {
        /* a==b translates to a-b==0 */
	/* Warning: cases like ceild(M,32) == ceild(N,32) are not handled.
	   Assert if we encounter such a case. */
	assert ((osl_int_zero(CLAN_PRECISION, $1->v, 0) ||
                 osl_int_one(CLAN_PRECISION,  $1->v, 0)) &&
                (osl_int_zero(CLAN_PRECISION, $3->v, 0) ||
                 osl_int_one(CLAN_PRECISION,  $3->v, 0)));
	osl_vector_p res = osl_vector_sub($1,$3);
	osl_vector_tag_equality(res);
	$$ = osl_relation_from_vector(res);
	osl_vector_free(res);
        osl_vector_free($1);
	osl_vector_free($3);
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
       $$ = osl_relation_concat_constraints($1, $3);
       osl_relation_free($1);
       osl_relation_free($3);
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
 * Rule for a function call -> id_function ( expression_list )
 *
 */
function_call:
  id syRPARENTHESIS expression_list syLPARENTHESIS
    {
      CLAN_debug("Yacc function_call.1: id_function ( expression_list )");
      $$ = $3;
    }
  ;


/*
 * Rules for an assignment (an instruction which is not a 'for' nor an 'if')
 * return: <list>
 *
 */
assignment:
/*
 * Rule 1: assignment -> var = expression;
 */
    variable opASSIGNMENT expression sySEMICOLON
      {
        CLAN_debug("Yacc assignment.1: var = expression");
        if ($1 == NULL)
	  {
	    yyerror ("[Clan] Error: changing value of iterator/parameter");
	    return 0;
	  }
        osl_relation_list_set_type($3, OSL_TYPE_READ);
        osl_relation_set_type($1, OSL_TYPE_WRITE);
        $$ = osl_relation_list_node($1);
        osl_relation_list_concat_inplace(&($$), $3);
        osl_relation_free($1);
      }
/*
 * Rule 2: assignment -> var red_op expression;
 */
  | variable reduction_operator expression sySEMICOLON
      {
        CLAN_debug("Yacc assignment.2: var red_op expression");
	if ($1 == NULL)
	  {
	    yyerror ("[Clan] Error: changing value of iterator/parameter");
	    return 0;
	  }
        osl_relation_list_set_type($3, OSL_TYPE_READ);
        osl_relation_set_type($1, OSL_TYPE_WRITE);
        $$ = osl_relation_list_node($1);
        osl_relation_list_concat_inplace(&($$), $3);
        osl_relation_free($1);
      }
/*
 * Rule 3: assignment -> var un_op;
 */
  | variable unary_operator sySEMICOLON
      {
        CLAN_debug("Yacc assignment.3: var un_op");
	if ($1 == NULL)
	  {
	    yyerror ("[Clan] Error: changing value of iterator/parameter");
	    return 0;
	  }
        osl_relation_set_type($1, OSL_TYPE_WRITE);
        $$ = osl_relation_list_node($1);
        osl_relation_set_type($1, OSL_TYPE_READ);
        osl_relation_list_concat_inplace(&($$), osl_relation_list_node($1));
        osl_relation_free($1);
      }
/*
 * Rule 4: assignment -> un_op var;
 */
  | unary_operator variable sySEMICOLON
      {
        CLAN_debug("Yacc assignment.4: un_op var");
	if ($2 == NULL)
	  {
	    yyerror ("[Clan] Error: changing value of iterator/parameter");
	    return 0;
	  }
        osl_relation_set_type($2, OSL_TYPE_WRITE);
        $$ = osl_relation_list_node($2);
        osl_relation_set_type($2, OSL_TYPE_READ);
        osl_relation_list_concat_inplace(&($$), osl_relation_list_node($2));
        osl_relation_free($2);
      }
/*
 * Rule 5: assignment -> var;
 */
  | variable sySEMICOLON
      {
        CLAN_debug("Yacc assignment.5: var");
        osl_relation_set_type($1, OSL_TYPE_READ);
        $$ = osl_relation_list_node($1);
        osl_relation_free($1);
      }
/*
 * Rule 6: assignment -> { assignment }
 */
  | syRBRACE assignment syLBRACE
      {
        CLAN_debug("Yacc assignment.6: { assignment }");
        $$ = $2;
      }
/*
 * Rule 7: assignment -> function_call;
 */
  | function_call sySEMICOLON
      {
        CLAN_debug("Yacc assignment.7: function_call");
        osl_relation_list_set_type($1, OSL_TYPE_READ);
        $$ = $1;
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
 * return: <list>
 *
 */
expression:
/*
 * Rule 1: expression -> number
 */
    NUMBER
      {
        CLAN_debug("Yacc expression.1: number");
        $$ = NULL;
      }
/*
 * Rule 2: expression -> - number
 */
  | opMINUS NUMBER
      {
        CLAN_debug("Yacc expression.2: - number");
        $$ = NULL;
      }
/*
 * Rule 3: expression -> variable
 */
  | variable
      {
        CLAN_debug("Yacc expression.3: variable");
        $$ = osl_relation_list_node($1);
        osl_relation_free($1);
      }
/*
 * Rule 4: expression -> expression bin_op expression
 * The %prec is a hack to force to shift in this rule.
 */
  | expression binary_operator expression %prec MAXPRIORITY
      {
        CLAN_debug("Yacc expression.4: expression bin_op expression");
	$$ = $1;
        osl_relation_list_concat_inplace(&($$), $3);
      }
/*
 * Rule 5: expression -> ! expression
 */
  | opNOT expression
      {
        CLAN_debug("Yacc expression.5: ! expression");
        $$ = $2;
      }
/*
 * Rule 6: expression -> ( expression )
 */
  | syRPARENTHESIS expression syLPARENTHESIS
      {
        CLAN_debug("Yacc expression.6: ( expression )");
	$$ = $2;
      }
/*
 * Rule 7: expression -> expression : expression ? expression
 */
  | expression opQMARK expression opCOLON expression
      {
        CLAN_debug("Yacc expression.7: expression : expression ? expression");
	$$ = $1;
        osl_relation_list_concat_inplace(&($$), $3);
        osl_relation_list_concat_inplace(&($$), $5);
      }
/*
 * Rule 8: expression -> function_call
 */
  | function_call %prec MAXPRIORITY 
      {
        CLAN_debug("Yacc expression.8: function_call");
        $$ = $1;
      }
  ;


/*
 * Rules for a comma-separated expression list.
 * return: <list>
 *
 */
expression_list:
/*
 * Rule 1: expression_list -> expression
 */
    expression
     {
       $$ = $1;
     }
/*
 * Rule 2: expression_list -> expression , expression_list
 */
  | expression_list syCOMMA expression 
     {
        $$ = $1;
        osl_relation_list_concat_inplace(&($$),$3);
     }
  |
/*
 * Rule 3: expression_list -> NULL
 */
  ;


/*
 * Rules to describe a variable. It can be a scalar ('a'), a
 * n-dimensional array ('a[i]').
 * return: <setex>
 *
 */
variable:
/*
 * Rule 1: variable -> id
 * ex: variable -> a
 */
    id
      {
        int rank;
        osl_relation_p relation;
	char* s = (char*) $1;
	clan_symbol_p symbol = clan_symbol_lookup(parser_symbol, s);
	// If the variable is an iterator or a parameter, discard it
	// from the read/write clause.
	if ((symbol && symbol->type == CLAN_TYPE_ITERATOR) ||
	    (symbol && symbol->type == CLAN_TYPE_PARAMETER))
	  $$ = NULL;
	else
	  {
	    clan_symbol_add(&parser_symbol, s, CLAN_TYPE_ARRAY,
		            parser_depth);
	    rank = clan_symbol_get_rank(parser_symbol, s);
	    relation = osl_relation_pmalloc(CLAN_PRECISION,
		0, CLAN_MAX_DEPTH + CLAN_MAX_PARAMETERS + 2);
            // The fakeiter makes sure there is at least one dimension.
            osl_relation_set_attributes(relation,
                0, CLAN_max(1, parser_depth), 0, CLAN_MAX_PARAMETERS);
	    clan_relation_tag_array(relation, rank);
	    $$ = relation;
	  }
        free($1);
      }
/*
 * Rule 2: variable -> id array_index
 * ex: variable -> a[i][j]
 */
  | id array_index
      {
        int rank;
        clan_symbol_add(&parser_symbol, $1, CLAN_TYPE_ARRAY, parser_depth);
        rank = clan_symbol_get_rank(parser_symbol, $1);
        // The fakeiter makes sure there is at least one dimension.
        osl_relation_set_attributes($2, 0, CLAN_max(1, parser_depth), 0,
                                    CLAN_MAX_PARAMETERS);
        clan_relation_outputize($2);
        clan_relation_tag_array($2, rank);
        $$ = $2;
        free($1);
      }
/*
 * Rule 3: variable -> - variable
 */
   | opMINUS variable
      {
	$$ = $2;
      }
/*
 * Rule 4: variable -> + variable
 */
   | opPLUS variable
      {
	$$ = $2;
      }
  ;


/*
 * Dummy rule for basic arithmetic expression. Used in variable_list.
 *
 */
arithmetic_expression:
    NUMBER
  | arithmetic_expression opMINUS arithmetic_expression
  | arithmetic_expression opPLUS arithmetic_expression
  | arithmetic_expression opMULTIPLY arithmetic_expression
  | arithmetic_expression opDIVIDE arithmetic_expression
  | syRPARENTHESIS arithmetic_expression syLPARENTHESIS
  ;


/*
 * Rules to describe a list of variables, separated by a comma.
 * return: <list>
 *
 */
variable_list:
/*
 * Rule 1: variable_list -> variable
 */
    variable
      {
	$$ = osl_relation_list_node($1);
        osl_relation_free($1);
      }
/*
 * Rule 2: variable_list -> variable_list , variable
 */
  | variable_list syCOMMA variable
      {
        osl_relation_list_p temp = osl_relation_list_node($3);
	$$ = osl_relation_list_concat($1,temp);
        osl_relation_free($3);
        osl_relation_list_free(temp);
        osl_relation_list_free($1);
      }
/*
 * Rule 3: variable_list -> variable_list , arithmetic_expression
 */
  | variable_list syCOMMA arithmetic_expression
      {
	$$ = $1;
      }
/*
 * Rule 4: variable_list -> arithmetic_expression, variable_list
 */
  | arithmetic_expression
      {
	$$ = NULL;
      }
/*
 * Rule 5: variable_list -> VOID
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
        CLAN_debug("Yacc array_index.1: [ <affex> ]");
        $$ = osl_relation_from_vector($2);
        osl_vector_free($2);
      }
/*
 * Rule 2: array_index -> array_index [ <affex> ]
 */
  | array_index syRBRACKET affine_expression syLBRACKET
      {
        CLAN_debug("Yacc array_index.2: array_index [ <affex> ]");
	if ($1 != NULL)
	  osl_relation_insert_vector($1,$3,$1->nb_rows);
        osl_vector_free($3);
        $$ = $1;
      }
  ;


/*
 * Rules to (1) eliminate the parenthesis around an identifier, and
 * (2) support the &ID reference operator
 * operator.
 *
 * return <symbol>
 */
id:
/*
 * Rule 1: id -> ID
 */
    ID
     {
       CLAN_debug("Yacc id.1: ID");
       $$ = $1;
     }
/*
 * Rule 2: id -> ( ID )
 */
  | syRPARENTHESIS ID syLPARENTHESIS
     {
       CLAN_debug("Yacc id.2: ( ID )");
       $$ = $2;
     }
/*
 * Rule 3: id -> & ID
 */
  | opAND ID
     {
       CLAN_debug("Yacc id.3: & ID");
       $$ = $2;
     }
/*
 * Rule 4: id -> math_func_list
 */
  | math_func_list
     {
       CLAN_debug("Yacc id.4: math_func_list");
       $$ = NULL;
     }
  ;

math_func_list: MIN | MAX | CEILD | FLOORD;

NUMBER:
    INTEGER
  | REAL
  ;

%%


void
yyerror(char *s)
{
  fprintf(stderr, "%s\n", s);
  clan_parse_error = 1;
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
clan_parser_initialize_state(clan_options_p options)
{
  int i, nb_rows, nb_columns, depth;

  nb_rows    = CLAN_MAX_CONSTRAINTS;
  nb_columns = CLAN_MAX_DEPTH + CLAN_MAX_PARAMETERS + 2;
  depth      = CLAN_MAX_DEPTH;

  parser_scop   = osl_scop_malloc();
  parser_domain = osl_relation_pmalloc(CLAN_PRECISION, nb_rows, nb_columns);
  parser_symbol = NULL;

  parser_scattering = (int *)malloc(depth * sizeof(int));
  parser_consperdim = (int *)malloc(depth * sizeof(int));
  for (i = 0; i < depth; i++)
  {
    parser_scattering[i] = 0;
    parser_consperdim[i] = 0;
  }
  parser_iterators = (clan_symbol_p *)malloc(depth * sizeof(clan_symbol_p));
  parser_variables_localvars =
    (int*)malloc((CLAN_MAX_LOCAL_VARIABLES + 1) * sizeof(int));
  parser_variables_liveout =
    (int*)malloc((CLAN_MAX_LOCAL_VARIABLES + 1) * sizeof(int));
  parser_depth = 0;
  parser_nb_cons = 0;
  /* Reset also the Symbol global variables. */
  extern int symbol_nb_iterators;
  symbol_nb_iterators = 0;
  extern int symbol_nb_parameters;
  symbol_nb_parameters = 0;
  extern int symbol_nb_arrays;
  symbol_nb_arrays = 0;
  extern int symbol_nb_functions;
  symbol_nb_functions = 0;

  for (i = 0; i <= CLAN_MAX_LOCAL_VARIABLES; ++i)
    parser_variables_localvars[i] = -1;
  for (i = 0; i <= CLAN_MAX_LOCAL_VARIABLES; ++i)
    parser_variables_liveout[i] = -1;

  parser_options = options;
  parser_scop->language = strdup("C");
  parser_record = NULL;
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
  osl_relation_free(parser_domain);
  clan_symbol_free(parser_symbol);
  free(parser_scattering);
  free(parser_consperdim);
  free(parser_iterators);
  free(parser_variables_localvars);
  free(parser_variables_liveout);
}

/**
 * clan_parse function:
 * this function parses a file to extract a SCoP and returns, if successful,
 * a pointer to the osl_scop_t structure.
 * \param input   The file to parse (already open).
 * \param options Options for file parsing.
 **
 * - 01/05/2008: First version.
 */
osl_scop_p
clan_parse(FILE * input, clan_options_p options)
{
  osl_generic_p arrays;
  yyin = input;

  clan_parser_initialize_state(options);

  yyparse();

  CLAN_debug("parsing successful");

  fclose(yyin);
  clan_scanner_free();

  if (!clan_parse_error)
    {
      /*if (parser_variables_localvars[0] != -1 ||
	  parser_variables_liveout[0] != -1)
	clan_scop_fill_options(parser_scop, parser_variables_localvars,
			       parser_variables_liveout);
      */
      clan_scop_compact(parser_scop);
      CLAN_debug("compaction successful");

      // Add extensions.
      parser_scop->registry = osl_interface_get_default_registry();
      clan_scop_generate_scatnames(parser_scop);
      arrays = clan_symbol_to_arrays(parser_symbol);
      osl_generic_add(&parser_scop->extension, arrays);
      
      // OpenScop wants an empty context rather than a NULL context.
      if (parser_scop->context == NULL) {
        parser_scop->context = osl_relation_pmalloc(CLAN_PRECISION, 0, 2);
        parser_scop->context->type = OSL_TYPE_CONTEXT;
        osl_relation_set_attributes(parser_scop->context, 0, 0, 0, 0);
      }
    }
  else
    parser_scop = NULL;
  clan_parser_free_state();
  CLAN_debug("parser state successfully freed");

  return parser_scop;
}

