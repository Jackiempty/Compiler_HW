/* Please feel free to modify any content */

/* Definition section */
%{
    #include "compiler_common.h"
    // #define YYDEBUG 1
    // int yydebug = 1;
    #define MAX_SCOPES 64
    #define MAX_SYMBOLS_PER_SCOPE 128
    #define MAX_NAME_LEN 64

    typedef struct {
        char name[MAX_NAME_LEN];
        char* type;
        int mut;
        int addr;
        int lineno;
        char* func_sig;
    } Symbol;

    Symbol symbol_table[MAX_SCOPES][MAX_SYMBOLS_PER_SCOPE];
    int symbol_count[MAX_SCOPES];
    int current_scope = -1;
    int symbol_addr = -1;

    extern int yylineno;
    extern int yylex();
    extern FILE *yyin;

    int yylex_destroy ();
    void yyerror (char const *s)
    {
        printf("error:%d: %s\n", yylineno, s);
    }

    extern int yylineno;
    extern int yylex();
    extern FILE *yyin;

    /* Symbol table function - you can add new functions if needed. */
    /* parameters and return type can be changed */
    static void create_symbol();
    static void insert_symbol(char*, int, char*, char*);
    // static void insert_symbol();
    Symbol* lookup_symbol(const char* name);
    static void dump_symbol();

    /* Global variables */
    bool HAS_ERROR = false;

    
%}

%define parse.error verbose

/* Use variable or self-defined structure to represent
 * nonterminal and token type
 *  - you can add new fields if needed.
 */
%union {
    int i_val;
    float f_val;
    char *s_val;
    /* ... */
}

/* Token without return */
%token LET MUT NEWLINE
%token INT FLOAT BOOL STR
%token TRUE FALSE
%token GEQ LEQ EQL NEQ LOR LAND
%token ADD_ASSIGN SUB_ASSIGN MUL_ASSIGN DIV_ASSIGN REM_ASSIGN
%token IF ELSE FOR WHILE LOOP
%token PRINT PRINTLN
%token FUNC RETURN BREAK
%token ID ARROW AS IN DOTDOT RSHIFT LSHIFT

/* Token with return, which need to sepcify type */
%token <i_val> INT_LIT
%token <f_val> FLOAT_LIT
%token <s_val> STRING_LIT
%token <s_val> IDENT

/* Nonterminal with return, which need to sepcify type */
%type <s_val> Type
%type <s_val> Expr
%type <s_val> Type_LIT
// %type <s_val> Operator

/* Yacc will start at this nonterminal */
%start Program

/* Precedence */
%left LOR
%left LAND
%left '>' '<'
%left '+' '-'
%left '*' '/' '%'
%right UMINUS

/* Grammar section */
%%

Program
    : GlobalStatementList
;

GlobalStatementList 
    : GlobalStatementList GlobalStatement
    | GlobalStatement
;

GlobalStatement
    : StartScope FunctionDeclStmt EndScope
    | NEWLINE
;

FunctionDeclStmt
    : FUNC { printf("func: "); } IDENT { printf("%s\n", $<s_val>3); insert_symbol($<s_val>3, -1, "func", "(V)V"); } '(' ')' '{' StartScope BlockStatements EndScope '}'
;

BlockStatements
    : BlockStatements BlockStatement
    | BlockStatement
;

BlockStatement
    : LetStatement
    | ExpressionStatement
    /* | IfStatement
    | WhileStatement
    | ReturnStatement */
    | '{' StartScope BlockStatements EndScope '}'
    | NEWLINE
;

LetStatement
    : LET IDENT ':' Type '=' Type_LIT ';' { insert_symbol($<s_val>2, 0, $<s_val>4, "-"); }
;

ExpressionStatement
    : PRINTLN Expr ';' { printf("PRINTLN %s\n", $<s_val>2); }
    | PRINT Expr ';' { printf("PRINT %s\n", $<s_val>2); }
;

Expr
    : Expr '+' Expr { printf("ADD\n"); $$ = $<s_val>1; }
    | Expr '-' Expr { printf("SUB\n"); $$ = $<s_val>1; }
    | Expr '*' Expr { printf("MUL\n"); $$ = $<s_val>1; }
    | Expr '/' Expr { printf("DIV\n"); $$ = $<s_val>1; }
    | Expr '%' Expr { printf("REM\n"); $$ = $<s_val>1; }
    | Expr '>' Expr { printf("GTR\n"); $$ = "bool"; }
    | Expr '<' Expr { printf("LSS\n"); $$ = "bool"; }
    | Expr LAND Expr { printf("LAND\n"); $$ = "bool"; }
    | Expr LOR  Expr { printf("LOR\n"); $$ = "bool"; }
    | '(' Expr ')' { $$ = $<s_val>2; }
    | '-' Expr %prec UMINUS { printf("NEG\n"); $$ = $<s_val>2; }
    | '!' Expr %prec UMINUS { printf("NOT\n"); $$ = $<s_val>2; }
    | IDENT { printf("IDENT (name=%s, address=%d)\n", $<s_val>1, lookup_symbol($<s_val>1)->addr); $$ = lookup_symbol($<s_val>1)->type; }
    | Type_LIT
    /* | Expr Operator Expr { printf("%s\n", $<s_val>2); $$ = $<s_val>1; } */
    /* | IDENT { printf("IDENT (name=%s, address=%d)\n", $<s_val>1, lookup_symbol($<s_val>1)->addr); } Operator IDENT { printf("IDENT (name=%s, address=%d)\n", $<s_val>4, lookup_symbol($<s_val>4)->addr); } { printf("%s\n", $<s_val>3); $$ = lookup_symbol($<s_val>1)->type; } */
;

StartScope
    : /* empty */ { create_symbol(); }
;

EndScope
    : /* empty */ { dump_symbol(); }
;

Type
    : INT { $$ = "i32"; }
    | FLOAT { $$ = "f32"; }
    | BOOL { $$ = "bool"; }
    | '&' STR { $$ = "str"; }
;

Type_LIT
    : '\"' STRING_LIT '\"' { printf("STRING_LIT \"%s\"\n", $<s_val>2); $$ = "str"; }
    | INT_LIT { printf("INT_LIT %d\n", $<i_val>1); $$ = "i32"; }
    | FLOAT_LIT { printf("FLOAT_LIT %f\n", $<f_val>1); $$ = "f32"; }
    | TRUE { printf("bool TRUE\n"); $$ = "bool"; }
    | FALSE { printf("bool FALSE\n"); $$ = "bool"; }
;

/* Operator
    : '+' { $$ = "ADD"; }
    | '-' { $$ = "SUB"; }
    | '*' { $$ = "MUL"; }
    | '/' { $$ = "DIV"; }
    | '%' { $$ = "REM"; }
    | '>' { $$ = "GTR"; }
    | '<' { $$ = "LSS"; }
; */

// sample
/* FunctionDeclStmt
    : FUNC { create_symbol(); } IDENT { printf("func: %s\n", $<s_val>3); } '(' ')' '{' Type_Dec1 { printf("Type_Dec1\n"); } ';' '}'
; */

/* Type_Dec1
    : Type { printf("%s\n", $<s_val>1); } IDENT '=' INT_LIT { printf("INT_LIT %s, %s, %d\n", $<s_val>3, $<s_val>4, $<i_val>5); }
; */


%%

/* C code section */
int main(int argc, char *argv[])
{
    if (argc == 2) {
        yyin = fopen(argv[1], "r");
    } else {
        yyin = stdin;
    }

    yylineno = 0;
    yyparse();

	printf("Total lines: %d\n", yylineno);
    fclose(yyin);
    return 0;
}

static void create_symbol() {
    current_scope++;
    printf("> Create symbol table (scope level %d)\n", current_scope);
}

static void insert_symbol(char* name, int mut, char* type, char* func_sig) {
    printf("> Insert `%s` (addr: %d) to scope level %d\n", name, symbol_addr, current_scope);
    Symbol* s = &symbol_table[current_scope][symbol_count[current_scope]];
    // insert all information
    strncpy(s->name, name, MAX_NAME_LEN);
    s->mut = mut;
    s->type = type;
    s->addr = symbol_addr;
    s->lineno = yylineno + 1;
    s->func_sig = func_sig;
    // strncpy(s->func_sig, func_sig, 10);
    symbol_count[current_scope]++;
    symbol_addr++;
}

Symbol* lookup_symbol(const char* name) {
    for (int s = current_scope; s >= 0; s--) {
        for (int i = 0; i < symbol_count[s]; i++) {
            if (strcmp(symbol_table[s][i].name, name) == 0) {
                return &symbol_table[s][i];
            }
        }
    }
}

static void dump_symbol() {
    Symbol* s = symbol_table[current_scope];
    printf("\n> Dump symbol table (scope level: %d)\n", current_scope);
    printf("%-10s%-10s%-10s%-10s%-10s%-10s%-10s\n",
        "Index", "Name", "Mut","Type", "Addr", "Lineno", "Func_sig");

    for (int i = 0; i < symbol_count[current_scope]; i++){
        printf("%-10d%-10s%-10d%-10s%-10d%-10d%-10s\n",
            i, s[i].name, s[i].mut, s[i].type, s[i].addr, s[i].lineno, s[i].func_sig);
    }
    symbol_count[current_scope] = 0;
    current_scope--;
}
