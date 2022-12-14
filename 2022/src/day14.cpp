#include "common.h"

#include <iostream>
#include <fstream>
#include <cassert>
#include <vector>
#include <unordered_set>

void solution1();
void solution2();

int main()
{
	solution1();
	solution2();
}

struct Cave {
	std::unordered_set<vec2i> rock;
	std::unordered_set<vec2i> sand;
	vec2i min = {INT32_MAX, INT32_MAX};
	vec2i max = {INT32_MIN, INT32_MIN};
};

constexpr vec2i sand_origin{500, 0};

vec2i parse_position(std::string_view &src);
void parse_line(Cave &cave, std::string_view src);

void print_cave(const Cave &cave);

void solution1()
{
	std::string_view filename{"input/day14.txt"};
	std::ifstream input{filename.data(), std::ifstream::in};
	if (!input.is_open())
		fatal_error("Missing file: {}", filename);

	std::string line;
	Cave cave;

	while (input)
	{
		std::getline(input, line);
		if (line.empty())
			continue;
		parse_line(cave, line);
	}

	auto is_falling_in_the_abyss = [&](vec2i pos) {
		return (pos.y > cave.max.y || pos.x < cave.min.x || pos.x > cave.max.x);
	};

	vec2i sand = sand_origin;
	int at_rest = 0;

	vec2i directions[] = {vec2i{0, 1}, vec2i{-1, 1}, vec2i{1, 1}};

	for (;;) {
		bool moved = false;
		for (auto dir : directions) {
			vec2i next_pos = sand + dir;
			if (cave.sand.find(next_pos) == cave.sand.end() && cave.rock.find(next_pos) == cave.rock.end())
			{
				sand = next_pos;
				moved = true;
				break;
			}
		}

		if (!moved) {
			cave.sand.insert(sand);
			++at_rest;
			sand = sand_origin;
		}
		else if (is_falling_in_the_abyss(sand))
			break;
	}

	print_cave(cave);

	println("Solution1: {}", at_rest);
}

void solution2()
{
	std::string_view filename{"input/day14.txt"};
	std::ifstream input{filename.data(), std::ifstream::in};
	if (!input.is_open())
		fatal_error("Missing file: {}", filename);

	std::string line;
	Cave cave;

	while (input)
	{
		std::getline(input, line);
		if (line.empty())
			continue;
		parse_line(cave, line);
	}

	auto is_falling_in_the_abyss = [&](vec2i pos) {
		return (pos.y > cave.max.y || pos.x < cave.min.x || pos.x > cave.max.x);
	};

	vec2i sand = sand_origin;
	int at_rest = 0;

	vec2i directions[] = {vec2i{0, 1}, vec2i{-1, 1}, vec2i{1, 1}};

	int floor = cave.max.y + 2;

	for (;;) {
		bool moved = false;
		if (sand.y < floor - 1)
		{
			for (auto dir : directions) {
				vec2i next_pos = sand + dir;
				if (cave.sand.find(next_pos) == cave.sand.end() && cave.rock.find(next_pos) == cave.rock.end())
				{
					sand = next_pos;
					moved = true;
					break;
				}
			}
		}

		if (!moved) {
			if (cave.sand.find(sand_origin) != cave.sand.end())
				break;

			cave.sand.insert(sand);
			++at_rest;
			sand = sand_origin;
		}
	}

	print_cave(cave);

	println("Solution2: {}", at_rest);
}

vec2i parse_position(std::string_view &src)
{
	vec2i res = {0, 0};
	src = parse_value(src, res.x);
	assert(!src.empty() and src[0] == ',');
	src = parse_value({begin(src) + 1, end(src)}, res.y);
	return res;
}

void parse_line(Cave &cave, std::string_view src)
{
	if (src.empty())
		return;

	constexpr std::string_view separator = " -> ";
	vec2i prev_pos = parse_position(src);
	cave.rock.insert(prev_pos);

	cave.min = min(cave.min, prev_pos);
	cave.max = max(cave.max, prev_pos);

	for (;;) {
		if (!src.starts_with(separator))
			return;
		src = {begin(src) + separator.size(), end(src)};

		vec2i current = parse_position(src);

		cave.min = min(cave.min, current);
		cave.max = max(cave.max, current);

		vec2i diff = prev_pos - current;
		vec2i dir = {sign(diff.x), sign(diff.y)};

		assert(std::abs(dir.x) == 1 || std::abs(dir.x) == 0);
		assert(std::abs(dir.y) == 1 || std::abs(dir.y) == 0);
		assert(std::abs(dir.x) != std::abs(dir.y));

		cave.rock.insert(current);
		for (vec2i pos = current; pos != prev_pos; pos = pos + dir)
			cave.rock.insert(pos);
		prev_pos = current;
	}
}

void print_cave(const Cave &cave) {
	vec2i start = cave.min;
	vec2i end = cave.max + vec2i{1, 1};

	start.y = std::min(start.y, 0);

	for (int y = start.y; y < end.y; y++) {
		for (int x = start.x; x < end.x; x++) {
			vec2i pos{x, y};

			if (pos == sand_origin)
				print("+");
			else if (cave.sand.find(pos) != cave.sand.end())
				print("o");
			else if (cave.rock.find(pos) != cave.rock.end())
				print("#");
			else
				print(".");
		}
		println("");
	}
}
