#include "common.h"

#include <iostream>
#include <fstream>
#include <cassert>
#include <string>
#include <unordered_set>
#include <array>

void solution1();
void solution2();

int main()
{
	solution1();
	solution2();
}

enum struct Direction : int {
	Up,
	Down,
	Right,
	Left
};

void print_sample(vec2i head, vec2i tail)
{
	println("### MOVE ###");
	for (int row = 4; row >= 0; row--) {
		for (int col = 0; col < 6; col++) {
			vec2i pos = {col, row};
			if (pos == head)
				print("H");
			else if (pos == tail)
				print("T");
			else if (pos == vec2i{0, 0})
				print("s");
			else
				print(".");
		}
		println("");
	}
}

void solution1()
{
	std::string_view filename{"input/day9.txt"};
	std::ifstream input{filename.data(), std::ifstream::in};
	if (!input.is_open())
		fatal_error("Missing file: {}", filename);

	std::unordered_set<vec2i> tail_positions;
	tail_positions.insert({0, 0});

	std::string line;
	vec2i head_pos = {}, tail_pos = {};

	while (input) {
		std::getline(input, line);
		if (line == "")
			continue;

		int move_amount = 0;
		parse_value({begin(line) + 2, end(line)}, move_amount);

		vec2i move = {};
		switch (line[0])
		{
		break; case 'U': move = {0, 1};
		break; case 'D': move = {0, -1};
		break; case 'R': move = {1, 0};
		break; case 'L': move = {-1, 0};
		break; default: unreacheable();
		}

		for (int i = 0; i < move_amount; i++) {
			vec2i prev_head_pos = head_pos;
			head_pos += move;
			vec2i distance = head_pos - tail_pos;

			if (std::abs(distance.x) > 1 || std::abs(distance.y) > 1) {
				tail_pos = prev_head_pos;
			}

			// print_sample(head_pos, tail_pos);

			tail_positions.insert(tail_pos);
		}
	}

	println("Solution1: {}", tail_positions.size());
}

void print_sample(const std::array<vec2i, 10>& knots)
{
	for (int row = 4; row >= 0; row--) {
		for (int col = 0; col < 6; col++) {
			vec2i pos = {col, row};
			int index = 0;
			for (; index < (int)knots.size(); index++)
			{
				if (knots[index] == pos)
					break;
			}

			if (index == 0)
				print("H");
			else if (index == 9)
				print("T");
			else if (index < 9)
				print("{}", index);
			else if (pos == vec2i{0, 0})
				print("s");
			else
				print(".");
		}
		println("");
	}
	println("");
}

void print_tail_path(const std::unordered_set<vec2i>& tails)
{
	vec2i ext_min = {}, ext_max = {};
	for (auto pos : tails)
	{
		ext_min = min(ext_min, pos);
		ext_max = max(ext_max, pos);
	}

	for (int y = ext_max.y - 1; y >= ext_min.y; y--)
	{
		for (int x = ext_min.x; x < ext_max.x; x++)
		{
			vec2i pos = {x, y};
			if (pos == vec2i{0, 0})
				print("s");
			else if (tails.find(pos) != tails.end())
				print("#");
			else
				print(".");
		}
		println("");
	}
}

void solution2()
{
	std::string_view filename{"input/day9.txt"};
	std::ifstream input{filename.data(), std::ifstream::in};
	if (!input.is_open())
		fatal_error("Missing file: {}", filename);

	std::unordered_set<vec2i> tail_positions;
	tail_positions.insert({0, 0});

	std::string line;
	std::array<vec2i, 10> knots;

	while (input) {
		std::getline(input, line);
		if (line == "")
			continue;

		int move_amount = 0;
		parse_value({begin(line) + 2, end(line)}, move_amount);

		//println("=={}==\n", line);

		vec2i move = {};
		switch (line[0])
		{
		break; case 'U': move = {0, 1};
		break; case 'D': move = {0, -1};
		break; case 'R': move = {1, 0};
		break; case 'L': move = {-1, 0};
		break; default: unreacheable();
		}

		for (int move_i = 0; move_i < move_amount; move_i++) {
			knots[0] += move;
			for (int i = 1; i < static_cast<int>(knots.size()); i++) {
				vec2i distance = knots[i - 1] - knots[i];
				if (std::abs(distance.x) > 1 || std::abs(distance.y) > 1)
				{
					if (distance.x != 0 && distance.y != 0)
						knots[i] += vec2i{sign(distance.x), sign(distance.y)};
					else if (distance.x != 0)
						knots[i] += vec2i{sign(distance.x), 0};
					else
						knots[i] += vec2i{0, sign(distance.y)};
				}
			}

			//print_sample(knots);
			tail_positions.insert(knots[9]);
		}
	}

	print_tail_path(tail_positions);

	println("Solution2: {}", tail_positions.size());
}
