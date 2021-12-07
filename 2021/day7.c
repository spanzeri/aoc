#include "utils.h"

int alignment_compare(const void * a, const void * b)
{
   return ( *(int*)a - *(int*)b );
}

int compute_alignments_distance(int *alignments, int align)
{
    int count = 0;
    for (int i = 0; i < dynarr_len(alignments); i++)
        count += abs(alignments[i] - align);
    return count;
}

void solution1(void)
{
    ParserContext ctx_ = parser_create_from_file("input/day7_1.txt");
    ParserContext *ctx = &ctx_;
    if (!parser_is_valid(ctx))
        return;

    int *alignments = parser_parse_as_csv(ctx);
    assert(alignments && dynarr_len(alignments) > 0);

    qsort(alignments, dynarr_len(alignments), sizeof(int), alignment_compare);

    int median_index = dynarr_len(alignments) / 2;
    int median = alignments[median_index];

    int solution = compute_alignments_distance(alignments, median);

    printf("Solution 1: %d\n", solution);
    parser_destroy(ctx);
    dynarr_free(alignments);
}

int64_t compute_alignments_distance2(int *alignments, int align)
{
    int64_t count = 0;
    for (int i = 0; i < dynarr_len(alignments); i++) {
        int64_t n = abs(alignments[i] - align);
        count += n * (n + 1) / 2;
    }
    return count;
}

void solution2(void)
{
    ParserContext ctx_ = parser_create_from_file("input/day7_1.txt");
    ParserContext *ctx = &ctx_;
    if (!parser_is_valid(ctx))
        return;

    int *alignments = parser_parse_as_csv(ctx);
    assert(alignments && dynarr_len(alignments) > 0);

    qsort(alignments, dynarr_len(alignments), sizeof(int), alignment_compare);

    int64_t best = INT64_MAX;
    int best_pos = 0;

    for (int i = 0; i < dynarr_len(alignments); i++) {
        int64_t curr = compute_alignments_distance2(alignments, i);
        if (curr < best) {
            best = curr;
            best_pos = i;
        }
    }

    // printf("Alignment position: %2d, Distance: %2lld\n", best_pos, best);

    printf("Solution 2: %lld\n", best);
    parser_destroy(ctx);
    dynarr_free(alignments);
}

int main(void)
{
    solution1();
    solution2();
}
