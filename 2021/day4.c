#include "utils.h"

#define BOARD_ROWS 5
#define BOARD_COLS 5

typedef struct Board {
    int cells[BOARD_ROWS][BOARD_COLS];
    int marked;
    bool won;
} Board;

static bool board_mark(Board *board, int num)
{
    for (int r = 0; r < BOARD_ROWS; r++) {
        for (int c = 0; c < BOARD_COLS; c++) {
            if (board->cells[r][c] == num) {
                board->marked |= 1 << (r * BOARD_COLS + c);
                // Check marked row
                if (((board->marked >> (r * BOARD_COLS)) & 0x1F) == 0x1F)
                    return true;
                // Check marked column
                if (((board->marked >> c) & 0x108421) == 0x108421)
                    return true;
            }
        }
    }
    return false;
}

static int board_get_score(Board *b, int last_num)
{
    int unmarked = 0;
    for (int r = 0; r < BOARD_ROWS; r++) {
        for (int c = 0; c < BOARD_COLS; c++) {
            if ((b->marked & (1 << (r * BOARD_COLS + c))) == 0)
                unmarked += b->cells[r][c];
        }
    }
    return unmarked * last_num;
}

static int *parse_random_numbers(ParserContext *ctx)
{
    int *nums = NULL;

    for (;;) {
        int n;
        if (!parser_read_int(ctx, &n))
            break;

        dynarr_push(nums, n);
        if (parser_peek_char(ctx) != ',')
            break;
        char tmp;
        parser_read_char(ctx, &tmp);
    }

    parser_consume_line(ctx);
    return nums;
}

static Board parse_board(ParserContext *ctx)
{
    Board b = {0};
    for (int r = 0; r < BOARD_ROWS; r++) {
        for (int c = 0; c < BOARD_COLS; c++) {
            parser_consume_whites(ctx);
            int n = 0;
            if (!parser_read_int(ctx, &n))
                assert(false);
            b.cells[r][c] = n;
        }
        parser_consume_line(ctx);
    }
    return b;
}

void debug_print_boards(Board *bs, int num)
{
    for (int r = 0; r < BOARD_ROWS; r++) {
        for (int b = 0; b < num; b++) {
            for (int c = 0; c < BOARD_COLS; c++) {
                if ((bs[b].marked & 1 << (r * BOARD_COLS + c)) != 0)
                    printf("[%2d]", bs[b].cells[r][c]);
                else
                printf(" %2d ", bs[b].cells[r][c]);
            }
            printf("    ");
        }
        printf("\n");
    }
    printf("\n");
}

void debug_print_all(Board *bs, int last_extracted)
{
    printf("---- Extracted: %d -----------------------------\n", last_extracted);
    for (int bc = 0; bc < dynarr_len(bs); bc += 5) {
        int count = MIN(dynarr_len(bs) - bc, 5);
        debug_print_boards(&bs[bc], count);
    }
}


void solution1(void)
{
    ParserContext ctx_ = parser_create_from_file("input/day4_1.txt");
    ParserContext *ctx = &ctx_;
    if (!parser_is_valid(ctx))
        return;

    int *nums = parse_random_numbers(ctx);
    Board *boards = NULL;

    while (!parser_eof(ctx)) {
        Board b = parse_board(ctx);
        dynarr_push(boards, b);
    }
    assert(dynarr_len(boards) > 0);

    int score = -1;

    for (int i = 0; i < dynarr_len(nums) && score < 0; i++) {
        for (int b = 0; b < dynarr_len(boards) && score < 0; b++) {
            if (board_mark(&boards[b], nums[i])) {
                score = board_get_score(&boards[b], nums[i]);
            }
        }
    }

    dynarr_free(boards);
    dynarr_free(nums);
    parser_destroy(ctx);

    printf("Solution 1: %d\n", score);
}

void solution2(void)
{
     ParserContext ctx_ = parser_create_from_file("input/day4_1.txt");
    ParserContext *ctx = &ctx_;
    if (!parser_is_valid(ctx))
        return;

    int *nums = parse_random_numbers(ctx);
    Board *boards = NULL;

    while (!parser_eof(ctx)) {
        Board b = parse_board(ctx);
        dynarr_push(boards, b);
    }
    assert(dynarr_len(boards) > 0);

    int score = -1;
    int win_count = 0;

    for (int i = 0; i < dynarr_len(nums) && score < 0; i++) {
        for (int b = 0; b < dynarr_len(boards) && score < 0; b++) {
            if (board_mark(&boards[b], nums[i])) {
                if (!boards[b].won) {
                    boards[b].won = true;
                    win_count++;
                }
                if (win_count == dynarr_len(boards))
                    score = board_get_score(&boards[b], nums[i]);
            }
        }
        // debug_print_all(boards, nums[i]);
    }

    dynarr_free(boards);
    dynarr_free(nums);
    parser_destroy(ctx);

    printf("Solution 2: %d\n", score);
}

int main(void)
{
    solution1();
    solution2();
}
