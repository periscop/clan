
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
   clan_scop_p clan_parse(FILE *, clan_options_p);

   extern FILE * yyin;                  /**< File to be read by Lex */
   extern char scanner_latest_text[];   /**< Latest text read by Lex */

   /* This is the "parser state", a collection of variables that vary
    * during the parsing and thanks to we can extract all SCoP informations.
    */
   clan_scop_p      parser_scop;        /**< SCoP in construction */
   clan_statement_p parser_statement;   /**< Statement in construction */
   clan_symbol_p    parser_symbol;      /**< Top of the symbol table */
   int              parser_recording;   /**< Boolean: do we record or not? */
   char *           parser_record;      /**< What we record (statement body) */
   int              parser_depth = 0;   /**< Current loop depth */
   int *            parser_scheduling;  /**< Current statement scheduling */
   clan_symbol_p *  parser_iterators;   /**< Current iterator list */
   clan_matrix_p    parser_domain;      /**< Current iteration domain */
   int              parser_nb_cons = 0; /**< Current number of constraints */
   int *            parser_consperdim;  /**< Constraint nb for each dimension */
%}

%union { int value;                     /**< An integer value for integers */
         char * symbol;                 /**< A string for identifiers */
         clan_vector_p affex;           /**< An affine expression */
         clan_matrix_p setex;           /**< A set of affine expressions */
         clan_matrix_p rw[2];           /**< Read and write array accesses */
       }

%token IGNORE
%token IF ELSE FOR
%token REAL
%token <symbol> ID
%token <value>  INTEGER

%token syRPARENTHESIS syLPARENTHESIS syRBRACKET syLBRACKET syRBRACE syLBRACE
%token sySEMICOLON syPOINT

%token opEQUAL opLEQ opGEG opLOWER opGREATER opPLUS opMINUS
%token opMULTIPLY opDIVIDE opASSIGNMENT opINCREMENTATION
%token opPLUSEQUAL opMINUSEQUAL opMULTIPLYEQUAL opDIVIDEEQUAL

%left opPLUS opMINUS
%left opMULTIPLY opDIVIDE

%type <affex> condition
%type <affex> affine_expression
%type <affex> term
%type <setex> array_index
%type <setex> variable
%type <setex> expression
%type <rw>    assignment

%%

program:
    instruction_list
      {
        int nb_parameters, nb_arrays;

        parser_scop->parameters = clan_symbol_id_array(parser_symbol,
                                                       CLAN_TYPE_PARAMETER,
                                                       &nb_parameters);
        parser_scop->nb_parameters = nb_parameters;
        parser_scop->arrays = clan_symbol_id_array(parser_symbol,
                                                   CLAN_TYPE_ARRAY,
                                                   &nb_arrays);
        parser_scop->nb_arrays = nb_arrays;
        parser_scop->context = clan_matrix_malloc(0,nb_parameters+2);
      }
  ;

instruction_list:
    instruction
  | instruction_list instruction
  | IGNORE
  | instruction_list IGNORE
  ;

bloc:
    instruction
  | syRBRACE instruction_list syLBRACE
  ;

instruction:
    FOR
    syRPARENTHESIS
    ID
      {
        clan_symbol_p symbol;
        symbol = clan_symbol_add(&parser_symbol,$3,
                                 CLAN_TYPE_ITERATOR,parser_depth+1);
	/* Ensure that the returned symbol was either a new one,
	   either from the same type. */
	if (symbol->type != CLAN_TYPE_ITERATOR)
	  {
	    fprintf (stderr, "[Clan] Error: the input file is not a SCoP\nA loop iterator was previously used as a parameter\n");
	    exit(1);
	  }
	/* Update the rank, in case a symbol with the same name was
	   already existing. */
	if (symbol->rank != parser_depth + 1)
	  symbol->rank = parser_depth + 1;
        parser_iterators[parser_depth] = symbol;
      }
    opASSIGNMENT
    affine_expression
      {
        /* Loop lower bound i = a translates to i-a>=0 constraint */
        clan_vector_p i_term;
        clan_vector_p constraint;
        i_term = clan_vector_term(parser_symbol,1,$3);
        free($3);
        constraint = clan_vector_sub(i_term,$6);
        clan_vector_tag_inequality(constraint);
        clan_vector_free(i_term);
        clan_vector_free($6);

        clan_matrix_replace_vector(parser_domain,constraint,parser_nb_cons);
        parser_nb_cons++;
        parser_consperdim[parser_depth]++;
      }
    sySEMICOLON
    condition
      {
        clan_matrix_replace_vector(parser_domain,$9,parser_nb_cons);
        parser_nb_cons++;
        parser_consperdim[parser_depth]++;
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
  | IF syRPARENTHESIS condition syLPARENTHESIS bloc
  |   {
        parser_statement = clan_statement_malloc();
        parser_record = (char *)malloc(CLAN_MAX_STRING * sizeof(char));
        parser_recording = CLAN_TRUE;
        /* Yacc needs Lex to read the next token to ensure we are starting
         * an assignment. So we keep track of the latest text Lex read
         * and we start the statement body with it.
         */
        strcpy(parser_record,scanner_latest_text);
      }
    assignment
      {
	parser_statement->domain = clan_matrix_list_malloc();
	parser_statement->domain->elt = clan_matrix_ncopy(parser_domain,
							  parser_nb_cons);
        parser_statement->schedule = clan_matrix_scheduling(parser_scheduling,
                                                            parser_depth);
        parser_statement->read = $2[0];
        parser_statement->write = $2[1];
        parser_statement->body = parser_record;
        parser_statement->nb_iterators = parser_depth;
        parser_statement->iterators = clan_symbol_iterators(parser_iterators,
                                                            parser_depth);
        parser_recording = CLAN_FALSE;
        clan_statement_add(&(parser_scop->statement),parser_statement);
        parser_scheduling[parser_depth]++;
      }
  ;

incrementation:
    ID opINCREMENTATION
      {
        free($1);
      }
  | opINCREMENTATION ID
      {
        free($2);
      }
  ;

condition:
    affine_expression opLOWER affine_expression
      {
        /* a<b translates to b-a-1>=0 */
        clan_vector_p temp;
        temp = clan_vector_sub($3,$1);
        $$   = clan_vector_add_scalar(temp,-1);
        clan_vector_tag_inequality($$);
        clan_vector_free($1);
        clan_vector_free($3);
        clan_vector_free(temp);
      }
  | affine_expression opGREATER affine_expression
      {
        /* a>b translates to a-b-1>=0 */
        clan_vector_p temp;
        temp = clan_vector_sub($1,$3);
        $$   = clan_vector_add_scalar(temp,-1);
        clan_vector_tag_inequality($$);
        clan_vector_free($1);
        clan_vector_free($3);
        clan_vector_free(temp);
      }
  | affine_expression opLEQ affine_expression
      {
        /* a<=b translates to b-a>=0 */
        $$ = clan_vector_sub($3,$1);
        clan_vector_tag_inequality($$);
        clan_vector_free($1);
        clan_vector_free($3);
      }
  | affine_expression opGEG affine_expression
      {
        /* a>=b translates to a-b>=0 */
        $$ = clan_vector_sub($1,$3);
        clan_vector_tag_inequality($$);
        clan_vector_free($1);
        clan_vector_free($3);
      }
  | affine_expression opEQUAL affine_expression
      {
        /* a==b translates to a-b==0 */
        $$ = clan_vector_sub($1,$3);
        clan_vector_tag_equality($$);
        clan_vector_free($1);
        clan_vector_free($3);
      }
  ;

affine_expression:
    term
      {
        $$ = $1;
      }
  | affine_expression opPLUS  affine_expression
      {
        $$ = clan_vector_add($1,$3);
        clan_vector_free($1);
        clan_vector_free($3);
      }
  | affine_expression opMINUS affine_expression
      {
        $$ = clan_vector_sub($1,$3);
        clan_vector_free($1);
        clan_vector_free($3);
      }
  | syRPARENTHESIS affine_expression syLPARENTHESIS
      {
        $$ = $2;
      }
  ;

term:
    INTEGER
      {
        $$ = clan_vector_term(parser_symbol,$1,NULL);
      }
  | ID
      {
        clan_symbol_add(&parser_symbol,$1,CLAN_TYPE_UNKNOWN,parser_depth);
        $$ = clan_vector_term(parser_symbol,1,$1);
        free($1);
      }
  | opMINUS INTEGER
      {
        $$ = clan_vector_term(parser_symbol,-($2),NULL);
      }
  | INTEGER opMULTIPLY ID
      {
        clan_symbol_add(&parser_symbol,$3,CLAN_TYPE_UNKNOWN,parser_depth);
        $$ = clan_vector_term(parser_symbol,$1,$3);
        free($3);
      }
  | opMINUS INTEGER opMULTIPLY ID
      {
        clan_symbol_add(&parser_symbol,$4,CLAN_TYPE_UNKNOWN,parser_depth);
        $$ = clan_vector_term(parser_symbol,-($2),$4);
        free($4);
      }
  ;

assignment:
    variable opASSIGNMENT expression sySEMICOLON
      {
        $$[0] = $3;
        $$[1] = $1;
      }
  | variable opPLUSEQUAL expression sySEMICOLON
      {
        $$[0] = clan_matrix_concat($1,$3);
        clan_matrix_free($3);
        $$[1] = $1;
      }
  | variable opMINUSEQUAL expression sySEMICOLON
      {
        $$[0] = clan_matrix_concat($1,$3);
        clan_matrix_free($3);
        $$[1] = $1;
      }
  | variable opMULTIPLYEQUAL expression sySEMICOLON
      {
        $$[0] = clan_matrix_concat($1,$3);
        clan_matrix_free($3);
        $$[1] = $1;
      }
  | variable opDIVIDEEQUAL expression sySEMICOLON
      {
        $$[0] = clan_matrix_concat($1,$3);
        clan_matrix_free($3);
        $$[1] = $1;
      }
  ;

expression:
    NUMBER
      {
        $$ = NULL;
      }
  | opMINUS NUMBER
      {
        $$ = NULL;
      }
  | expression opPLUS expression
      {
        $$ = clan_matrix_concat($1,$3);
        clan_matrix_free($1);
        clan_matrix_free($3);
      }
  | expression opMINUS expression
      {
        $$ = clan_matrix_concat($1,$3);
        clan_matrix_free($1);
        clan_matrix_free($3);
      }
  | expression opMULTIPLY expression
      {
        $$ = clan_matrix_concat($1,$3);
        clan_matrix_free($1);
        clan_matrix_free($3);
      }
  | expression opDIVIDE expression
      {
        $$ = clan_matrix_concat($1,$3);
        clan_matrix_free($1);
        clan_matrix_free($3);
      }
  | syRPARENTHESIS expression syLPARENTHESIS
      {
        $$ = $2;
      }
  | variable
      {
        $$ = $1;
      }
  | ID syRPARENTHESIS syLPARENTHESIS
      {
        $$ = NULL;
        free($1);
      }
  ;

variable:
    ID
      {
        int rank;
        clan_matrix_p matrix;
        clan_symbol_add(&parser_symbol,$1,CLAN_TYPE_ARRAY,parser_depth);
        rank = clan_symbol_get_rank(parser_symbol,$1);
        matrix = clan_matrix_malloc(1,CLAN_MAX_DEPTH + CLAN_MAX_PARAMETERS + 2);
        clan_matrix_tag_array(matrix,rank);
        $$ = matrix;
        free($1);
      }
  | ID array_index
      {
        int rank;
        clan_symbol_add(&parser_symbol,$1,CLAN_TYPE_ARRAY,parser_depth);
        rank = clan_symbol_get_rank(parser_symbol,$1);
        clan_matrix_tag_array($2,rank);
        $$ = $2;
        free($1);
      }
  ;

array_index:
    syRBRACKET affine_expression syLBRACKET
      {
        $$ = clan_matrix_from_vector($2);
        clan_vector_free($2);
      }
  | array_index syRBRACKET affine_expression syLBRACKET
      {
        clan_matrix_insert_vector($1,$3,CLAN_END);
        clan_vector_free($3);
        $$ = $1;
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

  parser_scop   = clan_scop_malloc();
  parser_domain = clan_matrix_malloc(nb_rows,nb_columns);
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
  clan_matrix_free(parser_domain);
  clan_symbol_free(parser_symbol);
  free(parser_scheduling);
  free(parser_consperdim);
  free(parser_iterators);
}


/**
 * clan_parse function:
 * this function parses a file to extract a SCoP and returns, if successful,
 * a pointer to the clan_scop_t structure.
 * \param input   The file to parse (already open).
 * \param options Options for file parsing.
 **
 * - 01/05/2008: First version.
 */
clan_scop_p
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

