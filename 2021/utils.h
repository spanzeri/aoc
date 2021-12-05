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

#define MIN(a, b) ((a) < (b) ? (a) : (b))
#define MAX(a, b) ((a) > (b) ? (a) : (b))

typedef struct ParserContext {
    const char *current;
    const char *end;
    char *memory;
} ParserContext;

typedef struct String {
    const char *data;
    size_t len;
} String;

#define StringLit(txt) ((String){ txt, sizeof(txt) - 1 })

ParserContext parser_create_from_file(const char *filename);
void parser_destroy(ParserContext *ctx);

bool parser_is_valid(ParserContext *ctx);
bool parser_eof(ParserContext *ctx);

bool parser_consume_line(ParserContext *ctx);
bool parser_consume_whites(ParserContext *ctx);


bool parser_read_int(ParserContext *ctx, int *result);
bool parser_read_identifier(ParserContext *ctx, String *result);
bool parser_read_char(ParserContext *ctx, char *result);

int string_compare(String a, String b);

static inline bool string_equal(String a, String b) { return string_compare(a, b) == 0; }

struct DynArrHdr {
    int count;
    int capacity;
};

#define DYNARR_INITIAL_SIZE 16

#define _dynarr_hdr(a) ((a) != NULL ? ((struct DynArrHdr *)(a) - 1) : NULL)

#define dynarr_len(a) ((a) ? _dynarr_hdr(a)->count : 0)
#define dynarr_push(a, value) ( \
    (a) = _dynarr_grow(_dynarr_hdr(a), sizeof(*(a)), 1), \
    (a)[_dynarr_hdr(a)->count] = value, \
    _dynarr_hdr(a)->count++ \
    )

#define dynarr_dup(a) (_dynarr_dup(_dynarr_hdr(a), sizeof(*(a))))
#define dynarr_free(a) free(_dynarr_hdr(a))
#define dynarr_remove_swap(a, i) ( \
    assert(a && dynarr_len(a) > i), \
    (a)[i] = (a)[dynarr_len(a) - 1], \
    --_dynarr_hdr(a)->count)


void *_dynarr_grow(struct DynArrHdr *hdr, size_t element_size, int count);
void *_dynarr_dup(struct DynArrHdr *hdr, size_t element_size);
