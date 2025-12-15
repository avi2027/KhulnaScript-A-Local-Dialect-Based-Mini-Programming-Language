#include <stdio.h>

int yyparse(void);
extern char *yytext;

int main(void) {
    printf("Enter KhulnaScript code, then Ctrl+D (EOF):\n\n");
    if (yyparse() == 0) {
        // yyparse already printed results
        return 0;
    } else {
        fprintf(stderr, "Parsing failed.\n");
        return 1;
    }
}


