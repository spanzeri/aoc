#include "utils.h"

void solution1(void)
{
    ParserContext ctx_ = parser_create_from_file("input/day1_1.txt");
    ParserContext *ctx = &ctx_;
    if (!parser_is_valid(ctx))
        return;

    int current = 0, last = 0, count = 0;
    if (!parser_read_int(ctx, &last)) {
        ERR("Invalid file format");
        return;
    }

    while (parser_consume_line(ctx)) {
        parser_read_int(ctx, &current);
        count += current > last ? 1 : 0;
        last = current;
    }

    printf("Solution 1: %d\n", count);
    parser_destroy(ctx);
}

void solution2(void)
{
    ParserContext ctx_ = parser_create_from_file("input/day1_1.txt");
    ParserContext *ctx = &ctx_;
    if (!parser_is_valid(ctx))
        return;

    int buffer[4];
    for (int i = 0; i < countof(buffer); i++) {
        if (!parser_read_int(ctx, &buffer[i]))
            assert(false);
        if (!parser_consume_line(ctx))
            assert(false);
    }

    int count = 0;
    const int last = countof(buffer) - 1;
    for (;;) {
        if (buffer[0] + buffer[1] + buffer[2] < buffer[1] + buffer[2] + buffer[3])
            count++;

        int next;
        if (!parser_read_int(ctx, &next))
            break;

        memmove(buffer, &buffer[1], sizeof(int) * last);
        buffer[last] = next;
    }

    printf("Solution 2: %d\n", count);
    parser_destroy(ctx);
}

int main(void)
{
    solution1();
    solution2();
}
