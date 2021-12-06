#include "utils.h"

typedef struct Point {
    int x, y;
} Point;

typedef struct Line {
    Point start, end;
} Line;



Line parse_line_segment(ParserContext *ctx)
{
    Line l = {-1, -1, -1, -1};
    // x0
    if (!parser_read_int(ctx, &l.start.x))
        assert(false);
    // Separator ,
    char c;
    if (!parser_read_char(ctx, &c) || c != ',')
        assert(false);
    // y0
    if (!parser_read_int(ctx, &l.start.y))
        assert(false);

    // Separator ->
    parser_consume_whites(ctx);
    if (!parser_read_char(ctx, &c) || c != '-' ||
        !parser_read_char(ctx, &c) || c != '>')
        assert(false);
    parser_consume_whites(ctx);

    // x1
    if (!parser_read_int(ctx, &l.end.x))
        assert(false);
    // Separator ,
    if (!parser_read_char(ctx, &c) || c != ',')
        assert(false);
    // y1
    if (!parser_read_int(ctx, &l.end.y))
        assert(false);
    parser_consume_line(ctx);

    return l;
}

static bool has_intersections(Line a, Line b)
{
    if ((a.start.x < b.start.x && a.end.x < b.start.x) || (a.start.x > b.end.x && a.end.x > b.end.x))
        return false;
    if ((a.start.y < b.start.y && a.end.y < b.start.y) || (a.start.y > b.end.y && a.end.y > b.end.y))
        return false;
    return true;
}

static void add_intersection(Point **intersections, Point p)
{
    int i = 0;
    for (; i < dynarr_len(*intersections); i++)
        if ((*intersections)[i].x == p.x && (*intersections)[i].y == p.y)
            break;
    if (i == dynarr_len(*intersections))
        dynarr_push(*intersections, p);
}

static void intersect(Point **intersections, Line a, Line b)
{
    if (a.start.x == a.end.x) {
        if (a.start.y > a.end.y)
            SWAP(int, a.start.y, a.end.y);
    } else {
        if (a.start.x > a.end.x)
            SWAP(int, a.start.x, a.end.x);
    }

    if (b.start.x == b.end.x) {
        if (b.start.y > b.end.y)
            SWAP(int, b.start.y, b.end.y);
    } else {
        if (b.start.x > b.end.x)
            SWAP(int, b.start.x, b.end.x);
    }

    if (!has_intersections(a, b))
        return;

    if (a.start.x == a.end.x && b.start.x == b.end.x) {
        // Parallel and vertical
        int istarty, iendy;
        istarty = MAX(a.start.y, b.start.y);
        iendy = MIN(a.end.y, b.end.y);
        for (int y = istarty; y < iendy + 1; y++)
            add_intersection(intersections, (Point){a.start.x, y});
    }
    else if (a.start.y == a.end.y && b.start.y == b.end.y) {
        // Parallel and horizontal
        int istartx, iendx;
        istartx = MAX(a.start.x, b.start.x);
        iendx = MIN(a.end.x, b.end.x);
        for (int x = istartx; x < iendx + 1; x++)
            add_intersection(intersections, (Point){x, a.start.y});
    }
    else {
        // Coincident. At most one point in common
        int x = MAX(a.start.x, b.start.x);
        x = MIN(x, a.end.x);
        x = MIN(x, b.end.x);
        int y = MAX(a.start.y, b.start.y);
        y = MIN(y, a.end.y);
        y = MIN(y, b.end.y);
        add_intersection(intersections, (Point){x, y});
    }
}

void solution1(void)
{
    ParserContext ctx_ = parser_create_from_file("input/day5_1.txt");
    ParserContext *ctx = &ctx_;
    if (!parser_is_valid(ctx))
        return;

    Line *lines = NULL;
    Point *intersections = NULL;

    while (!parser_eof(ctx)) {
        Line l = parse_line_segment(ctx);
        if (l.start.x != l.end.x && l.start.y != l.end.y)
            continue;

        for (int i = 0; i < dynarr_len(lines); i++)
            intersect(&intersections, l, lines[i]);
        dynarr_push(lines, l);
    }
    int solution = dynarr_len(intersections);

    dynarr_free(lines);
    dynarr_free(intersections);
    parser_destroy(ctx);

    printf("Solution 1: %d\n", solution);
}


static bool line_is_valid(Line l)
{
    return l.start.x == l.end.x
        || l.start.y == l.end.y
        || abs(l.start.x - l.end.x) == abs(l.start.y - l.end.y);
}

static Point make_direction(Line a)
{
    int x = a.end.x - a.start.x;
    int y = a.end.y - a.start.y;
    if (x > 0)
        x = 1;
    else if (x < 0)
        x = -1;
    if (y > 0)
        y = 1;
    else if (y < 0)
        y = -1;
    return (Point){x, y};
}

static bool are_parallel(Point adir, Point bdir)
{
    return adir.x == bdir.x && adir.y == bdir.y
        || adir.x == -bdir.x && adir.y == -bdir.y;
}

static int square_distance(Point a, Point b)
{
    int x = a.x - b.x;
    int y = a.y - b.y;
    return x * x + y * y;
}

static bool has_same_sign(int x, int y)
{
    return (x > 0 && y == 0) || (x == 0 && y == 0) || (x < 0 && y < 0);
}

static int dot(Point a, Point b)
{
    return a.x * b.x + a.y * b.y;
}

static bool is_on_line(Point p, Line b)
{
    Line btop = (Line){b.start, p};
    Point bdir = make_direction(b);
    int bsqrlen = square_distance(b.start, b.end);

    if (line_is_valid(btop)) {
        Point btopdir = make_direction(btop);
        if (p.x == b.start.x && p.y == b.start.y) {
            return true;
        }

        if (btopdir.x == bdir.x && btopdir.y == bdir.y) {
            if (square_distance(p, b.start) <= bsqrlen) {
                return true;
            }
        }
    }

    return false;
}

static void intersect2(Point **intersections, Line a, Line b)
{
    Point adir = make_direction(a);
    Point bdir = make_direction(b);

    if (are_parallel(adir, bdir)) {
        Line btoa = (Line){b.start, a.start};

        if (!line_is_valid(btoa))
            return;

        Point p = a.start;
        bool found = false;
        for (;;) {
            if (is_on_line(p, b)) {
                add_intersection(intersections, p);
                found = true;
            }
            else if (found)
                break;

            if (p.x == a.end.x && p.y == a.end.y)
                break;
            p.x += adir.x;
            p.y += adir.y;
        }
    }
    else {
        Point p = a.start;
        for (;;) {
            if (is_on_line(p, b)) {
                add_intersection(intersections, p);
                return;
            }

            if (p.x == a.end.x && p.y == a.end.y)
                return;

            p.x += adir.x;
            p.y += adir.y;
        }
    }
}

void solution2(void)
{
    ParserContext ctx_ = parser_create_from_file("input/day5_1.txt");
    ParserContext *ctx = &ctx_;
    if (!parser_is_valid(ctx))
        return;

    Line *lines = NULL;
    Point *intersections = NULL;

    while (!parser_eof(ctx)) {
        Line l = parse_line_segment(ctx);
        if (!line_is_valid(l))
            continue;

        for (int i = 0; i < dynarr_len(lines); i++)
            intersect2(&intersections, l, lines[i]);
        dynarr_push(lines, l);
    }
    int solution = dynarr_len(intersections);

    dynarr_free(lines);
    dynarr_free(intersections);
    parser_destroy(ctx);

    printf("Solution 2: %d\n", solution);
}

int main(void)
{
    solution1();
    solution2();
}
