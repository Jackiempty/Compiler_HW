
/* Please feel free to modify any content */

/* Definition section */
%{
    #include "compiler_common.h" //Extern variables that communicate with lex
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

    /* Used to generate code */
    /* As printf; the usage: CODEGEN("%d - %s\n", 100, "Hello world"); */
    /* We do not enforce the use of this macro */
    #define CODEGEN(...) \
        do { \
            for (int i = 0; i < g_indent_cnt; i++) { \
                fprintf(fout, "\t"); \
            } \
            fprintf(fout, __VA_ARGS__); \
        } while (0)

    /* Symbol table function - you can add new functions if needed. */
    /* parameters and return type can be changed */
    static void create_symbol();
    static void insert_symbol(char*, int, char*, char*);
    Symbol* lookup_symbol(const char*);
    static void dump_symbol();
    static void display_error(int);

    /* Global variables */
    bool g_has_error = false;
    FILE *fout = NULL;
    int g_indent_cnt = 0;
%}

%error-verbose

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

/* Yacc will start at this nonterminal */
%start Program

/* Precedence */
%left LOR
%left LAND
%left '>' '<' GEQ LEQ EQL NEQ
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
    | AssignmentStatement
    | IfStatement
    | WhileStatement
    // | ReturnStatement
    | '{' StartScope BlockStatements EndScope '}'
    | NEWLINE
;

LetStatement
    : LET IDENT ':' Type '=' Type_LIT ';' { insert_symbol($<s_val>2, 0, $<s_val>4, "-"); }
    | LET MUT IDENT ':' Type '=' Type_LIT ';' { insert_symbol($<s_val>3, 1, $<s_val>5, "-"); }
    | LET IDENT ':' Type ';' { insert_symbol($<s_val>2, 0, $<s_val>4, "-"); }
    | LET MUT IDENT ':' Type ';' { insert_symbol($<s_val>3, 1, $<s_val>5, "-"); }
    | LET IDENT '=' Type_LIT ';' { insert_symbol($<s_val>2, 0, $<s_val>5, "-"); }
    | LET MUT IDENT '=' Type_LIT ';' { insert_symbol($<s_val>3, 1, $<s_val>5, "-"); }
;

ExpressionStatement
    : PRINTLN Expr ';' { printf("PRINTLN %s\n", $<s_val>2); }
    | PRINT Expr ';' { printf("PRINT %s\n", $<s_val>2); }
;

AssignmentStatement
    : IDENT '=' Expr ';' { lookup_symbol($<s_val>1)->addr == -2 ? : printf("ASSIGN\n"); lookup_symbol($<s_val>1)->mut == 0 ? display_error(0) : (lookup_symbol($<s_val>1)->addr != -2 ? : display_error(4)); }
    | IDENT ADD_ASSIGN Expr ';' { printf("ADD_ASSIGN\n"); }
    | IDENT SUB_ASSIGN Expr ';' { printf("SUB_ASSIGN\n"); }
    | IDENT MUL_ASSIGN Expr ';' { printf("MUL_ASSIGN\n"); }
    | IDENT DIV_ASSIGN Expr ';' { printf("DIV_ASSIGN\n"); }
    | IDENT REM_ASSIGN Expr ';' { printf("REM_ASSIGN\n"); }
;

IfStatement
    : IF Expr BlockStatement
    | IF Expr BlockStatement ELSE BlockStatement
;

WhileStatement
    : WHILE Expr BlockStatement
;

Expr
    : Expr '+' Expr { printf("ADD\n"); $$ = $<s_val>1; }
    | Expr '-' Expr { printf("SUB\n"); $$ = $<s_val>1; }
    | Expr '*' Expr { printf("MUL\n"); $$ = $<s_val>1; }
    | Expr '/' Expr { printf("DIV\n"); $$ = $<s_val>1; }
    | Expr '%' Expr { printf("REM\n"); $$ = $<s_val>1; }
    | Expr '>' Expr { strcmp($<s_val>1, $<s_val>3) == 0 ? : display_error(1); printf("GTR\n"); $$ = "bool"; }
    | Expr '<' Expr { printf("LSS\n"); $$ = "bool"; }
    | Expr EQL Expr { printf("EQL\n"); $$ = $<s_val>1; }
    | Expr NEQ Expr { printf("NEQ\n"); $$ = $<s_val>1; }
    | Expr GEQ Expr { printf("GEQ\n"); $$ = $<s_val>1; }
    | Expr LEQ Expr { printf("LEQ\n"); $$ = $<s_val>1; }
    | Expr LAND Expr { printf("LAND\n"); $$ = "bool"; }
    | Expr LOR  Expr { printf("LOR\n"); $$ = "bool"; }
    | Expr LSHIFT Expr { strcmp($<s_val>1, $<s_val>3) == 0 ? : display_error(2); printf("LSHIFT\n"); $$ = $<s_val>1; }
    | '(' Expr ')' { $$ = $<s_val>2; }
    | '-' Expr %prec UMINUS { printf("NEG\n"); $$ = $<s_val>2; }
    | '!' Expr %prec UMINUS { printf("NOT\n"); $$ = $<s_val>2; }
    | IDENT { lookup_symbol($<s_val>1)->addr == -2 ? display_error(3) : printf("IDENT (name=%s, address=%d)\n", $<s_val>1, lookup_symbol($<s_val>1)->addr); $$ = lookup_symbol($<s_val>1)->type; }
    | Expr AS Type { printf("%s2%s\n", strcmp($<s_val>1, "f32") ? "i" : "f" , strcmp($<s_val>3, "f32") ? "i" : "f"); }
    | Type_LIT { $$ = $<s_val>1; }
    | IDENT { lookup_symbol($<s_val>1)->addr == -2 ? display_error(3) : printf("IDENT (name=%s, address=%d)\n", $<s_val>1, lookup_symbol($<s_val>1)->addr); } '[' Type_LIT ']' { $$ = "array"; }
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
    | '[' Type ';' Type_LIT ']' { $$ = "array"; }
;

Type_LIT
    : '\"' STRING_LIT '\"' { printf("STRING_LIT \"%s\"\n", $<s_val>2); $$ = "str"; }
    | '\"' '\"' { printf("STRING_LIT \"\"\n"); $$ = "str"; }
    | INT_LIT { printf("INT_LIT %d\n", $<i_val>1); $$ = "i32"; }
    | FLOAT_LIT { printf("FLOAT_LIT %f\n", $<f_val>1); $$ = "f32"; }
    | TRUE { printf("bool TRUE\n"); $$ = "bool"; }
    | FALSE { printf("bool FALSE\n"); $$ = "bool"; }
    | '[' Array ']' { $$ = "array"; }
;

Array
    : Type_LIT
    | Array ',' Type_LIT
;

%%

/* C code section */
int main(int argc, char *argv[])
{
    if (argc == 2) {
        yyin = fopen(argv[1], "r");
    } else {
        yyin = stdin;
    }
    if (!yyin) {
        printf("file `%s` doesn't exists or cannot be opened\n", argv[1]);
        exit(1);
    }

    /* Codegen output init */
    char *bytecode_filename = "hw3.j";
    fout = fopen(bytecode_filename, "w");
    CODEGEN(".source hw3.j\n");
    CODEGEN(".class public Main\n");
    CODEGEN(".super java/lang/Object\n");

    /* Symbol table init */
    // Add your code

    yylineno = 0;
    yyparse();

    /* Symbol table dump */
    // Add your code

	printf("Total lines: %d\n", yylineno);
    fclose(fout);
    fclose(yyin);

    if (g_has_error) {
        remove(bytecode_filename);
    }
    yylex_destroy();
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
    Symbol s;
    s.addr = -2;
    return &s;
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

static void display_error(int errorType) {
    printf("error:%d: ", yylineno + 1);
    switch (errorType) {
        case 0:
            printf("cannot borrow immutable borrowed content `x` as mutable");
            break;
        case 1:
            printf("invalid operation: GTR (mismatched types undefined and i32)");
            break;
        case 2:
            printf("invalid operation: LSHIFT (mismatched types i32 and f32)");
            break;
        case 3:
            printf("undefined: gg");
            break;
        case 4: 
            printf("undefined: y");
            break;
    }
    printf("\n");
}