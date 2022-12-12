#include "common.h"

#include <iostream>
#include <fstream>
#include <cassert>
#include <vector>
#include <queue>
#include <unordered_set>

void solution1();
void solution2();

int main()
{
	solution1();
	solution2();
}

struct Grid {
	std::vector<std::vector<char>> heights;

	bool is_valid_position(vec2i pos) const {
		if (pos.x < 0 || pos.y < 0)
			return false;
		if (pos.y >= static_cast<int>(heights.size()))
			return false;
		if (pos.x >= static_cast<int>(heights[pos.y].size()))
			return false;
		return true;
	}

	bool is_visited_position(vec2i pos) const {
		if (!is_valid_position(pos))
			return false;
		return get(pos) == '~';
	}

	bool can_visit(vec2i current, vec2i next) const {
		if (!is_valid_position(next) || is_visited_position(next))
			return false;
		int hn = get(next);
		int hc = get(current);
		return hc >= (hn - 1);
	}

	void visit_position(vec2i pos) {
		get(pos) = '~';
	}

	char& get(vec2i p) {
		assert(is_valid_position(p));
		return heights[p.y][p.x];
	}

	const char& get(vec2i p) const {
		assert(is_valid_position(p));
		return heights[p.y][p.x];
	}
};

int visit1(Grid& grid, vec2i start_pos, vec2i end_pos)
{
	constexpr vec2i direction[] ={
		{ 0,  1},
		{ 0, -1},
		{-1,  0},
		{ 1,  0}};

	struct FuturePos {
		vec2i pos = {0, 0};
		int distance = 0;
	};

	grid.get(start_pos) = 'a';
	grid.get(end_pos) = 'z';

	std::queue<FuturePos> to_visit;
	to_visit.push({start_pos, 0});

	while (!to_visit.empty()) {
		auto current = to_visit.front();
		to_visit.pop();

		if (grid.is_visited_position(current.pos))
			continue;

		if (current.pos == end_pos)
			return current.distance;

		for (auto dir : direction) {
			vec2i next = current.pos + dir;
			if (grid.can_visit(current.pos, next))
				to_visit.push({next, current.distance + 1});
		}

		grid.visit_position(current.pos);
	}

	return -1;
}

void solution1()
{
	std::string_view filename{"input/day12.txt"};
	std::ifstream input{filename.data(), std::ifstream::in};
	if (!input.is_open())
		fatal_error("Missing file: {}", filename);

	std::string line;
	Grid grid;
	vec2i start_pos;
	vec2i end_pos;

	while (input) {
		std::getline(input, line);
		if (line == "")
			continue;

		grid.heights.push_back({});
		auto &row = grid.heights.back();
		for (auto c : line) {
			if (c == 'S')
				start_pos = {(int)row.size(), (int)grid.heights.size() - 1};
			else if (c == 'E')
				end_pos = {(int)row.size(), (int)grid.heights.size() - 1};

			row.push_back(c);
		}
	}

	int res = visit1(grid, start_pos, end_pos);

	println("Solution1: {}", res);
}

int visit2_do_visit(Grid grid, vec2i start_pos, vec2i end_pos, int current_min) {
	constexpr vec2i direction[] ={
		{ 0,  1},
		{ 0, -1},
		{-1,  0},
		{ 1,  0}};

	struct FuturePos {
		vec2i pos = {0, 0};
		int distance = 0;
	};

	std::queue<FuturePos> to_visit;
	to_visit.push({start_pos, 0});

	while (!to_visit.empty()) {
		auto current = to_visit.front();
		to_visit.pop();

		if (current.distance >= current_min)
			return INT_MAX;

		if (grid.is_visited_position(current.pos))
			continue;

		if (current.pos == end_pos)
			return current.distance;

		for (auto dir : direction) {
			vec2i next = current.pos + dir;
			// Avoid stepping on other 'a', it would be a shorter path
			if (grid.can_visit(current.pos, next) && grid.get(next) != 'a')
				to_visit.push({next, current.distance + 1});
		}

		grid.visit_position(current.pos);
	}

	return INT_MAX;
}

int visit2(Grid& grid, vec2i start_pos, vec2i end_pos)
{
	grid.get(start_pos) = 'a';
	grid.get(end_pos) = 'z';

	std::unordered_set<vec2i> a_heights;

	for (int r = 0; r < (int)grid.heights.size(); r++) {
		for (int c = 0; c < (int)grid.heights[r].size(); c++) {
			vec2i pos = {c, r};
			if (grid.get(pos) == 'a')
				a_heights.insert(pos);
		}
	}

	int min_distance = INT_MAX;

	while (!a_heights.empty()) {
		vec2i start = *a_heights.begin();
		int tested = visit2_do_visit(grid, start, end_pos, min_distance);
		min_distance = std::min(tested, min_distance);
		a_heights.erase(start);
	}

	return min_distance;
}

void solution2()
{
	std::string_view filename{"input/day12.txt"};
	std::ifstream input{filename.data(), std::ifstream::in};
	if (!input.is_open())
		fatal_error("Missing file: {}", filename);

	std::string line;
	Grid grid;
	vec2i start_pos;
	vec2i end_pos;

	while (input) {
		std::getline(input, line);
		if (line == "")
			continue;

		grid.heights.push_back({});
		auto &row = grid.heights.back();
		for (auto c : line) {
			if (c == 'S')
				start_pos = {(int)row.size(), (int)grid.heights.size() - 1};
			else if (c == 'E')
				end_pos = {(int)row.size(), (int)grid.heights.size() - 1};

			row.push_back(c);
		}
	}

	int res = visit2(grid, start_pos, end_pos);

	println("Solution2: {}", res);
}
