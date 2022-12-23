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
	North,
	South,
	West,
	East,
	DIR_COUNT
};

struct Elf {
	Direction first_dir = North;
	vec2i pos;
	vec2i proposed_pos;
};

std::vector<Elf> parse_elves(std::ifstream& input) {
	std::vector<Elf> elves;
	std::string line;
	int curr_y = 0;
	while (input) {
		std::getline(input, line);
		if (line.empty())
			break;
		for (int x = 0; x < (int)line.size(); x++)
		{
			if (line[x] == '#')
				elves.emplace_back(North, vec2i{x, curr_y});
		}
		++curr_y;
	}
	return elves;
}

constexpr vec2i move_dir[] = {
	vec2i{ 0, -1}, // N
	vec2i{ 0,  1}, // S
	vec2i{-1,  0}, // W
	vec2i{ 1,  0}, // E
};

bool do_round(std::vector<Elf>& elves)
{
	std::unordered_map<vec2i, int> proposed;
	std::unordered_set<vec2i> occupancy;

	// First figure out where they are
	for (auto& elf : elves) {
		assert(!occupancy.contains(elf.pos));
		occupancy.insert(elf.pos);
	}

	auto is_good_direction = [&](vec2i pos, Direction dir) -> bool
	{
		vec2i tests[3];
		if (dir == North) {
			tests[0] = pos + vec2i{-1, -1};
			tests[1] = pos + vec2i{ 0, -1};
			tests[2] = pos + vec2i{ 1, -1};
		}
		else if (dir == South) {
			tests[0] = pos + vec2i{-1,  1};
			tests[1] = pos + vec2i{ 0,  1};
			tests[2] = pos + vec2i{ 1,  1};
		}
		else if (dir == West) {
			tests[0] = pos + vec2i{-1, -1};
			tests[1] = pos + vec2i{-1,  0};
			tests[2] = pos + vec2i{-1,  1};
		}
		else if (dir == East) {
			tests[0] = pos + vec2i{ 1, -1};
			tests[1] = pos + vec2i{ 1,  0};
			tests[2] = pos + vec2i{ 1,  1};
		}

		return !occupancy.contains(tests[0]) && !occupancy.contains(tests[1]) && !occupancy.contains(tests[2]);
	};

	auto has_neighbors =
	    [&](vec2i pos) {
		    return occupancy.contains(pos + vec2i{-1, -1}) || // Above
		           occupancy.contains(pos + vec2i{ 0, -1}) ||
		           occupancy.contains(pos + vec2i{ 1, -1}) ||
		           occupancy.contains(pos + vec2i{-1,  0}) || // Side
		           occupancy.contains(pos + vec2i{ 1,  0}) ||
		           occupancy.contains(pos + vec2i{-1,  1}) || // Below
		           occupancy.contains(pos + vec2i{ 0,  1}) ||
		           occupancy.contains(pos + vec2i{ 1,  1});
	    };

	bool has_any_moved = false;

	// Propose a move for every elf
	for (auto &elf : elves)
	{
		Direction dir = elf.first_dir;
		elf.proposed_pos = elf.pos;
		elf.first_dir = (Direction)((elf.first_dir + 1) % DIR_COUNT);

		if (!has_neighbors(elf.pos))
			continue;
		has_any_moved = true;

		for (int i = 0; i < DIR_COUNT; i++) {
			Direction test_dir = (Direction)((dir + i) % DIR_COUNT);
			if (is_good_direction(elf.pos, test_dir)) {
				elf.proposed_pos = elf.pos + move_dir[test_dir];
				proposed[elf.proposed_pos] += 1;
				break;
			}
		}
	}

	if (!has_any_moved)
		return false;

	// Move all the elves
	for (auto& elf : elves) {
		// Couldn't move at all
		if (elf.pos == elf.proposed_pos)
			continue;

		int count = proposed[elf.proposed_pos];
		assert(count >= 1);
		if (count == 1)
			elf.pos = elf.proposed_pos;
	}

	return true;
}

void print_map(const std::vector<Elf>& elves)
{
	std::unordered_set<vec2i> occupied;
	vec2i minp = {INT_MAX, INT_MAX};
	vec2i maxp = {INT_MIN, INT_MIN};
	for (const auto& elf : elves) {
		minp = min(elf.pos, minp);
		maxp = max(elf.pos, maxp);
		assert(!occupied.contains(elf.pos));
		occupied.insert(elf.pos);
	}

	for (int y = minp.y; y <= maxp.y; y++) {
		for (int x = minp.x; x <= maxp.x; x++) {
			print("{}", occupied.contains({x, y}) ? '#' : '.');
		}
		println("");
	}
}

int get_empty(const std::vector<Elf>& elves)
{
	std::unordered_set<vec2i> occupied;
	vec2i minp = {INT_MAX, INT_MAX};
	vec2i maxp = {INT_MIN, INT_MIN};
	for (const auto& elf : elves) {
		minp = min(elf.pos, minp);
		maxp = max(elf.pos, maxp);
		assert(!occupied.contains(elf.pos));
		occupied.insert(elf.pos);
	}

	int area = (maxp.y - minp.y + 1) * (maxp.x - minp.x + 1);
	int result = area - (int)occupied.size();
	return result;
}

void solution1()
{
	std::string_view filename{"input/day23.txt"};
	std::ifstream input{filename.data(), std::ifstream::in};
	if (!input.is_open())
		fatal_error("Missing file: {}", filename);

	auto elves = parse_elves(input);

	for (int i = 0; i < 10; i++) {
		do_round(elves);
		//println("\n == End of Round {} ==", i + 1);
		//print_map(elves);
	}

	print_map(elves);
	int result = get_empty(elves);
	println("Solution1: {}", result);
}

void solution2()
{
	std::string_view filename{"input/day23.txt"};
	std::ifstream input{filename.data(), std::ifstream::in};
	if (!input.is_open())
		fatal_error("Missing file: {}", filename);

	auto elves = parse_elves(input);

	int round = 1;
	while (do_round(elves))
		++round;

	print_map(elves);
	println("Solution2: {}", round);
}
