#include "common.h"

#include <iostream>
#include <fstream>
#include <cassert>
#include <vector>
#include <array>
#include <unordered_set>
#include <unordered_map>

void solution1();
void solution2();

int main()
{
	{
		SimpleTimer timer{"solution1"};
		solution1();
	}
	{
		SimpleTimer timer{"solution2"};
		solution2();
	}
}

enum Direction {
	Right = 0,
	Down,
	Left,
	Up,
	DIR_COUNT
};

char at_position(const std::vector<std::string>& map, vec2i pos)
{
	if (pos.y < 0 || pos.y >= (int)map.size())
		return ' ';
	if (pos.x < 0 || pos.x >= (int)map[pos.y].size())
		return ' ';
	return map[pos.y][pos.x];
}

vec2i wrap_position(const std::vector<std::string>& map, vec2i pos, Direction dir) {
	if (dir == Up || dir == Down) {
		int min = dir == Down ? 0 : (int)map.size() - 1;
		int max = dir == Down ? (int)map.size() - 1 : 0;
		int step = dir == Down ? 1 : -1;

		for (int y = min; y != max; y += step) {
			char c = at_position(map, vec2i{pos.x, y});
			if (c != ' ')
				return vec2i{pos.x, y};
		}

		unreacheable();
	}

	int min = dir == Right ? 0 : (int)map[pos.y].size() - 1;
	int max = dir == Right ? (int)map[pos.y].size() - 1 : 0;
	int step = dir == Right ? 1 : -1;

	for (int x = min; x != max; x += step) {
		char c = at_position(map, vec2i{x, pos.y});
		if (c != ' ')
			return vec2i{x, pos.y};
	}

	unreacheable();
}

void solution1()
{
	std::string_view filename{"input/day22.txt"};
	std::ifstream input{filename.data(), std::ifstream::in};
	if (!input.is_open())
		fatal_error("Missing file: {}", filename);

	std::string line;
	std::vector<std::string> map;

	while (input) {
		std::getline(input, line);
		if (line.empty())
			break;
		map.push_back(line);
	}
	assert(input);
	std::string path;
	std::getline(input, path);

	vec2i pos = {0, 0};
	Direction dir = Right;

	// Initial position
	for (int x = 0; x < (int)map[0].size(); x++) {
		if (map[0][x] == '.') {
			pos = {x, 0};
			break;
		}
	}

	auto make_vec_direction = [](Direction dir) {
		switch (dir)
		{
		case Right: return vec2i{ 1,  0};
		case Down:  return vec2i{ 0,  1};
		case Left:  return vec2i{-1,  0};
		case Up:    return vec2i{ 0, -1};
		default: unreacheable();
		}
	};

	std::string_view curr_path = path;
	while (!curr_path.empty()) {
		if (curr_path[0] == 'R') {
			dir = (Direction)((dir + 1) % DIR_COUNT);
			curr_path = {begin(curr_path) + 1, end(curr_path)};
			continue;
		}

		if (curr_path[0] == 'L') {
			dir = (Direction)((dir - 1 + DIR_COUNT) % DIR_COUNT);
			curr_path = {begin(curr_path) + 1, end(curr_path)};
			continue;
		}

		vec2i vdir = make_vec_direction(dir);
		int count;
		curr_path = parse_value(curr_path, count);

		for (int i = 0; i < count; i++) {
			vec2i next = pos + vdir;
			char c = at_position(map, next);

			if (c == '.') {
				pos = next;
				continue;
			}

			if (c == '#')
				break;

			next = wrap_position(map, next, dir);
			c = at_position(map, next);
			if (c == '.')
				pos = next;
			else if (c == '#')
				break;
			else
				unreacheable();
		}
	}

	int result = (pos.y + 1) * 1000 + (pos.x + 1) * 4 + dir;

	println("Solution1: {}", result);
}

enum struct EFace
{
	Front = 0,
	Bottom,
	Back,
	Top,
	Right,
	Left,
	COUNT
};

bool is_in_bounding_box(vec2i pos, vec2i min, vec2i max)
{
	return pos.x >= min.x && pos.x < max.x && pos.y >= min.y && pos.y < max.y;
}

EFace get_current_face(vec2i curr)
{
	if (is_in_bounding_box(curr, {50, 0}, {100, 50}))
		return EFace::Front;
	if (is_in_bounding_box(curr, {50, 50}, {100, 100}))
		return EFace::Bottom;
	if (is_in_bounding_box(curr, {50, 100}, {100, 150}))
		return EFace::Back;
	if (is_in_bounding_box(curr, {0, 100}, {50, 150}))
		return EFace::Left;
	if (is_in_bounding_box(curr, {0, 150}, {50, 200}))
		return EFace::Top;
	if (is_in_bounding_box(curr, {100, 0}, {150, 50}))
		return EFace::Right;
	unreacheable();
}

std::pair<vec2i, Direction> cube_wrap(vec2i curr, Direction dir)
{
	EFace curr_face = get_current_face(curr);
	switch (curr_face)
	{
	case EFace::Front:
		if (dir == Up)
			return {{0, 150 + (curr.x - 50)}, Right};
		if (dir == Left)
			return {{0, 149 - curr.y}, Right};
		unreacheable();

	case EFace::Bottom:
		if (dir == Left)
			return {{curr.y - 50, 100}, Down};
		if (dir == Right)
			return {{(curr.y - 50) + 100, 49}, Up};
		unreacheable();

	case EFace::Back:
		if (dir == Down)
			return {{49, 150 + (curr.x - 50)}, Left};
		if (dir == Right)
			return {{149, 49 - (curr.y - 100)}, Left};
		unreacheable();

	case EFace::Top:
		if (dir == Right)
			return {{50 + curr.y - 150, 149}, Up};
		if (dir == Left)
			return {{50 + curr.y - 150, 0}, Down};
		if (dir == Down)
			return {{100 + curr.x, 0}, Down};
		unreacheable();

	case EFace::Right:
		if (dir == Up)
			return {{curr.x - 100, 199}, Up};
		if (dir == Down)
			return {{99, 50 + (curr.x - 100)}, Left};
		if (dir == Right)
			return {{99, 149 - curr.y}, Left};
		unreacheable();

	case EFace::Left:
		if (dir == Up)
			return {{50, curr.x + 50}, Right};
		if (dir == Left)
			return {{50, 149 - curr.y}, Right};
		unreacheable();
	}
	unreacheable();
}

void solution2()
{
	std::string_view filename{"input/day22.txt"};
	std::ifstream input{filename.data(), std::ifstream::in};
	if (!input.is_open())
		fatal_error("Missing file: {}", filename);

	std::string line;
	std::vector<std::string> map;

	while (input) {
		std::getline(input, line);
		if (line.empty())
			break;
		map.push_back(line);
	}
	assert(input);
	std::string path;
	std::getline(input, path);

	vec2i pos = {50, 0};
	Direction dir = Right;

	auto make_vec_direction = [](Direction dir) {
		switch (dir)
		{
		case Right: return vec2i{ 1,  0};
		case Down:  return vec2i{ 0,  1};
		case Left:  return vec2i{-1,  0};
		case Up:    return vec2i{ 0, -1};
		default: unreacheable();
		}
	};

	std::unordered_map<vec2i, Direction> visited;

	std::string_view curr_path = path;
	while (!curr_path.empty()) {
		if (curr_path[0] == 'R') {
			dir = (Direction)((dir + 1) % DIR_COUNT);
			curr_path = {begin(curr_path) + 1, end(curr_path)};
			continue;
		}

		if (curr_path[0] == 'L') {
			dir = (Direction)((dir - 1 + DIR_COUNT) % DIR_COUNT);
			curr_path = {begin(curr_path) + 1, end(curr_path)};
			continue;
		}

		vec2i vdir = make_vec_direction(dir);
		int count;
		curr_path = parse_value(curr_path, count);

		for (int i = 0; i < count; i++) {
			vec2i next = pos + vdir;

			char c = at_position(map, next);

			if (c == '.') {
				visited[pos] = dir;
				pos = next;
				continue;
			}

			if (c == '#')
				break;

			auto p = cube_wrap(pos, dir);
			c = at_position(map, p.first);
			assert(c != ' ');

			if (c == '.') {
				pos = p.first;
				dir = p.second;
				vdir = make_vec_direction(dir);
				visited[pos] = dir;
			}
			else if (c == '#')
				break;
		}
	}

	for (int y = 0; y < 200; y++) {
		for (int x = 0; x < 150; x++) {
			vec2i pp{x, y};
			auto it = visited.find(pp);
			if (it != end(visited)) {
				switch (it->second) {
				case Left: print("<"); break;
				case Up: print("^"); break;
				case Right: print(">"); break;
				case Down: print("V"); break;
				}
			}
			else
				print("{}", at_position(map, pp));
		}
		println("");
	}

	int result = (pos.y + 1) * 1000 + (pos.x + 1) * 4 + dir;

	println("Solution2: {}", result);
}
