#include <stdint.h>
#include <assert.h>
#include <stdio.h>
#include <stdlib.h>
#include <stdbool.h>
#include <string.h>

#define ERR(...)                      \
    do                                \
    {                                 \
        fprintf(stderr, __VA_ARGS__); \
        fputc('\n', stderr);          \
    } while (0)

#define countof(arr) (sizeof(arr) / sizeof(0[arr]))

typedef struct ParserContext {
    const char *current;
    const char *end;
    char *memory;
} ParserContext;

typedef struct String {
    const char *data;
    size_t size;
} String;

ParserContext parser_create_from_file(const char *filename);
void parser_destroy(ParserContext *ctx);

bool parser_is_valid(ParserContext *ctx);
bool parser_eof(ParserContext *ctx);

bool parser_read_int(ParserContext *ctx, int *result);
bool parser_consume_line(ParserContext *ctx);
