#include "utils.h"

void solution1(void)
{
    ParserContext ctx_ = parser_create_from_file("input/day2_1.txt");
    ParserContext *ctx = &ctx_;
    if (!parser_is_valid(ctx))
        return;

    int depth = 0;
    int hpos = 0;

    while (!parser_eof(ctx)) {
        String cmd = {0};
        if (parser_read_identifier(ctx, &cmd)) {
            parser_consume_whites(ctx);

            int amount = 0;
            if (parser_read_int(ctx, &amount)) {
                if (string_equal(cmd, StringLit("forward")))
                    hpos += amount;
                else if (string_equal(cmd, StringLit("down")))
                    depth += amount;
                else if (string_equal(cmd, StringLit("up")))
                    depth -= amount;
                else
                    assert(false);
            }

            parser_consume_line(ctx);
        }
    }
    parser_destroy(ctx);

    printf("Solution 1: %d\n", depth * hpos);
}

void solution2(void)
{
    ParserContext ctx_ = parser_create_from_file("input/day2_1.txt");
    ParserContext *ctx = &ctx_;
    if (!parser_is_valid(ctx))
        return;

    int depth = 0;
    int hpos = 0;
    int aim = 0;

    while (!parser_eof(ctx)) {
        String cmd = {0};
        if (parser_read_identifier(ctx, &cmd)) {
            parser_consume_whites(ctx);

            int amount = 0;
            if (parser_read_int(ctx, &amount)) {
                if (string_equal(cmd, StringLit("forward"))) {
                    hpos += amount;
                    depth += amount * aim;
                }
                else if (string_equal(cmd, StringLit("down")))
                    aim += amount;
                else if (string_equal(cmd, StringLit("up")))
                    aim -= amount;
                else
                    assert(false);
            }

            parser_consume_line(ctx);
        }
    }
    parser_destroy(ctx);


    printf("Depth: %d - HPos: %d\n", depth, hpos);
    printf("Solution 2: %d\n", depth * hpos);
}

int main(void)
{
    solution1();
    solution2();
}
