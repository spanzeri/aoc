#include "utils.h"

#define BIT_COUNT 12

void solution1(void)
{
    ParserContext ctx_ = parser_create_from_file("input/day3_1.txt");
    ParserContext *ctx = &ctx_;
    if (!parser_is_valid(ctx))
        return;

    int ones_count[BIT_COUNT] = {0};
    int line_count = 0;

    while (!parser_eof(ctx)) {
        for (int i = 0; i < countof(ones_count); i++) {
            char c;
            if (parser_read_char(ctx, &c)) {
                if (c == '1')
                    ones_count[i]++;
            }
        }
        line_count++;
        parser_consume_line(ctx);
    }

    int gamma = 0, epsilon = 0;
    for (int i = 0; i < countof(ones_count); i++) {
        if (ones_count[i] > (line_count / 2))
            gamma += 1 << ((int)countof(ones_count) - i - 1);
        else
            epsilon += 1 << ((int)countof(ones_count) - i- 1);
    }

    parser_destroy(ctx);

    printf("Solution 1: %d\n", gamma * epsilon);
}

static int binary_str_to_int(String s)
{
    if (s.len == 0)
        return 0;
    int shift = (int)s.len - 1;
    int value = 0;
    for (int i = 0; i < s.len; i++) {
        value += (int)(s.data[i] - '0') << shift;
        shift--;
    }
    return value;
}

void solution2(void)
{
    ParserContext ctx_ = parser_create_from_file("input/day3_1.txt");
    ParserContext *ctx = &ctx_;
    if (!parser_is_valid(ctx))
        return;

    String *lines = NULL;
    while (!parser_eof(ctx)) {
        String s;
        if (parser_read_identifier(ctx, &s))
            dynarr_push(lines, s);
        parser_consume_line(ctx);
    }

    String *oxygen = dynarr_dup(lines);
    String *co2 = lines;

    int num_bits = (int)lines[0].len;

    for (int bit = 0; bit < num_bits; bit++) {
        assert(dynarr_len(oxygen) > 0);
        if (dynarr_len(oxygen) == 1)
            break;

        int ones = 0, zeros = 0;
        for (int i = 0; i < dynarr_len(oxygen); i++) {
            if (oxygen[i].data[bit] == '0')
                ++zeros;
            else
                ++ones;
        }

        char to_remove = ones >= zeros ? '0' : '1';

        for (int i = 0; i < dynarr_len(oxygen);) {
            if (oxygen[i].data[bit] == to_remove)
                dynarr_remove_swap(oxygen, i);
            else
                i++;
        }
    }

    for (int bit = 0; bit < num_bits; bit++) {
        assert(dynarr_len(co2) > 0);
        if (dynarr_len(co2) == 1)
            break;

        int ones = 0, zeros = 0;
        for (int i = 0; i < dynarr_len(co2); i++) {
            if (co2[i].data[bit] == '0')
                ++zeros;
            else
                ++ones;
        }

        char to_remove = ones < zeros ? '0' : '1';

        for (int i = 0; i < dynarr_len(co2);) {
            if (co2[i].data[bit] == to_remove)
                dynarr_remove_swap(co2, i);
            else
                i++;
        }
    }

    int oxygen_val = binary_str_to_int(oxygen[0]);
    int co2_val = binary_str_to_int(co2[0]);

    dynarr_free(oxygen);
    dynarr_free(co2);
    parser_destroy(ctx);

    printf("Solution 2: %d\n", oxygen_val * co2_val);
}

int main(void)
{
    solution1();
    solution2();
}
