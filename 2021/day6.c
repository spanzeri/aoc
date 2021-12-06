#include "utils.h"

static void debug_print_day(int day, int *fishes)
{
    printf("After %2d days: ", day + 1);
    for (int f = 0; f < dynarr_len(fishes); f++)
        if (f != dynarr_len(fishes) - 1)
            printf("%d,", fishes[f]);
        else
            printf("%d", fishes[f]);
    printf("\n");
}

void solution1(void)
{
    ParserContext ctx_ = parser_create_from_file("input/day6_1.txt");
    ParserContext *ctx = &ctx_;
    if (!parser_is_valid(ctx))
        return;

    int *fishes = NULL;
    while (!parser_eof(ctx)) {
        int timer = 0;
        if (parser_read_int(ctx, &timer))
            dynarr_push(fishes, timer);
        char c = 0;
        if (parser_read_char(ctx, &c) && c == ',')
            continue;
    }

    const int num_of_days = 80;
    for (int day = 0; day < num_of_days; day++) {
        int new_fish_count = 0;
        for (int f = 0; f < dynarr_len(fishes); f++) {
            int timer = fishes[f];
            if (timer == 0) {
                new_fish_count++;
                fishes[f] = 6;
            }
            else {
                fishes[f] = timer - 1;
            }
        }

        for (int f = 0; f < new_fish_count; f++)
            dynarr_push(fishes, 8);

        // debug_print_day(day + 1, fishes);
    }

    printf("Solution 1: %d\n", dynarr_len(fishes));
    parser_destroy(ctx);
    dynarr_free(fishes);
}

void solution2(void)
{
    ParserContext ctx_ = parser_create_from_file("input/day6_1.txt");
    ParserContext *ctx = &ctx_;
    if (!parser_is_valid(ctx))
        return;

    int64_t fish_by_timer[9] = {0};

    while (!parser_eof(ctx)) {
        int timer = 0;
        if (parser_read_int(ctx, &timer)) {
            assert(timer <= 8);
            fish_by_timer[timer]++;
        }
        char c = 0;
        if (parser_read_char(ctx, &c) && c == ',')
            continue;
    }

    const int num_of_days = 256;
    for (int day = 0; day < num_of_days; day++) {
        int64_t new_fishes = fish_by_timer[0];
        for (int timer = 0; timer < countof(fish_by_timer) - 1; timer++) {
            fish_by_timer[timer] = fish_by_timer[timer + 1];
        }
        fish_by_timer[6] += new_fishes;
        fish_by_timer[8] = new_fishes;
    }

    int64_t solution = 0;
    for (size_t i = 0; i < countof(fish_by_timer); i++)
        solution += fish_by_timer[i];

    printf("Solution 2: %lld\n", solution);
    parser_destroy(ctx);
}

int main(void)
{
    solution1();
    solution2();
}
