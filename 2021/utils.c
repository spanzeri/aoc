#include "utils.h"

#if !defined(_WIN32)
    #define fread_s(buffer, buf_size, size, count) fread(buffer, size, count)
#endif

ParserContext parser_create_from_file(const char *filename)
{
    ParserContext ctx = {0};

    FILE *file;
    if (fopen_s(&file, filename, "rb")) {
        ERR("Failed to open file: %s", filename);
        return ctx;
    }

    fseek(file, 0, SEEK_END);
    long lsize = ftell(file);
    if (lsize < 0) {
        fclose(file);
        ERR("Failed to read size for file: %s", filename);
        return ctx;
    }
    fseek(file, 0, SEEK_SET);
    size_t size = (size_t)lsize;

    ctx.memory = (char *)malloc(size + 1);
    ctx.current = ctx.memory;
    ctx.end = ctx.current + size;

    size_t read_size = fread_s(ctx.memory, size + 1, sizeof(char), size, file);
    if (read_size != size) {
        ERR("Failed reading file: %s", filename);
        free(ctx.memory);
        ctx = (ParserContext){0};
    }

    fclose(file);
    return ctx;
}

void parser_destroy(ParserContext *ctx)
{
    if (ctx->memory != NULL)
        free(ctx->memory);
    *ctx = (ParserContext){0};
}

bool parser_is_valid(ParserContext *ctx)
{
    return ctx->current != NULL && ctx->end != NULL && ctx->current <= ctx->end;
}

bool parser_eof(ParserContext *ctx)
{
    return ctx->current == ctx->end;
}

bool parser_read_int(ParserContext *ctx, int *result)
{
    char *endptr;
    long int tmp = strtol(ctx->current, &endptr, 10);
    if (endptr == NULL || endptr == ctx->current)
        return false;

    ctx->current = endptr;
    *result = (int)tmp;
    return true;
}

bool parser_consume_line(ParserContext *ctx)
{
    const char *at = ctx->current;
    while (*at != '\r' && *at != '\n' && !parser_eof(ctx))
        at++;
    while (*at == '\r' || *at == '\n' || parser_eof(ctx))
        at++;
    ctx->current = at;
    return !parser_eof(ctx);
}
