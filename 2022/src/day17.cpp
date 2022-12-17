#include "common.h"

#include <iostream>
#include <fstream>
#include <cassert>
#include <vector>
#include <array>

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

using Bitmap = std::vector<uint8_t>;

std::array<Bitmap, 5> rocks = {
	Bitmap{
		(uint8_t)0b00011110
	},
	Bitmap{
		(uint8_t)0b00001000,
		(uint8_t)0b00011100,
		(uint8_t)0b00001000,
	},
	Bitmap{
		(uint8_t)0b00000100,
		(uint8_t)0b00000100,
		(uint8_t)0b00011100,
	},
	Bitmap{
		(uint8_t)0b00010000,
		(uint8_t)0b00010000,
		(uint8_t)0b00010000,
		(uint8_t)0b00010000,
	},
	Bitmap{
		(uint8_t)0b00011000,
		(uint8_t)0b00011000,
	}
};

constexpr int next_rock_index(int current_index) { return (current_index + 1) % (int)rocks.size(); }

struct Rock {
	size_t height;
	Bitmap bitmap;
};

Rock make_rock(int rock_index, Bitmap& map)
{
	return {map.size() + 3, rocks[rock_index]};
}

bool try_move_right(Rock& rock, const Bitmap& map)
{
	for (auto el : rock.bitmap) {
		if (el & 0x1)
			return false;
	}

	if (rock.height < map.size()) {
		size_t end = std::min(map.size() - rock.height, rock.bitmap.size());
		for (size_t i = 0; i < end; i++) {
			size_t rock_index = rock.bitmap.size() - i - 1;
			size_t map_index = rock.height + i;
			if (map[map_index] & (rock.bitmap[rock_index] >> 1))
				return false;
		}
	}

	// We can move
	for (auto &el : rock.bitmap) {
		el = el >> 1;
	}
	return true;
}

bool try_move_left(Rock& rock, const Bitmap& map)
{
	for (auto el : rock.bitmap) {
		if (el & 0b0100'0000)
			return false;
	}

	if (rock.height < map.size()) {
		size_t end = std::min(map.size() - rock.height, rock.bitmap.size());
		for (size_t i = 0; i < end; i++) {
			size_t rock_index = rock.bitmap.size() - i - 1;
			size_t map_index = rock.height + i;
			if (map[map_index] & (rock.bitmap[rock_index] << 1))
				return false;
		}
	}

	// We can move
	for (auto &el : rock.bitmap) {
		el = el << 1;
	}
	return true;
}

bool try_move_down(Rock& rock, const Bitmap& map)
{
	if (rock.height == 0)
		return false;

	if (rock.height - 1 < map.size()) {
		size_t end = std::min(map.size() - rock.height + 1, rock.bitmap.size());
		for (size_t i = 0; i < end; i++) {
			size_t rock_index = rock.bitmap.size() - i - 1;
			size_t map_index = rock.height + i - 1;
			if (map[map_index] & rock.bitmap[rock_index])
				return false;
		}
	}

	rock.height -= 1;
	return true;
}

void set_to_rest(Rock& rock, Bitmap& map)
{
	if (map.size() < rock.height + rock.bitmap.size())
		map.resize(rock.height + rock.bitmap.size());

	for (size_t i = 0; i < rock.bitmap.size(); i++) {
		size_t rock_index = rock.bitmap.size() - i - 1;
		size_t map_index = rock.height + i;

		assert((rock.bitmap[rock_index] & map[map_index]) == 0);
		map[map_index] |= rock.bitmap[rock_index];
	}
}

void print(Bitmap& map)
{
	for (auto it = map.rbegin(); it != map.rend(); ++it) {
		uint8_t line = *it;
		print("|");
		for (int i = 7; i >= 0; i--) {
			print("{}", ((line >> i) & 1) ? '#' : '.');
		}
		println("|");
	}
	println("__________");
}

void solution1()
{
	std::string_view filename{"input/day17.txt"};
	std::ifstream input{filename.data(), std::ifstream::in};
	if (!input.is_open())
		fatal_error("Missing file: {}", filename);

	std::string moves;
	std::getline(input, moves);

	int rock_index = 0;
	int move_index = 0;

	Bitmap map;
	Rock rock = make_rock(rock_index, map);

	for (int i = 0; i < 2022; i++)
	{
		for (;;)
		{
			char move = moves[move_index];
			move_index = (move_index + 1) % (int)moves.size();

			if (move == '>')
				try_move_right(rock, map);
			else if (move == '<')
				try_move_left(rock, map);
			else
				unreacheable();

			if (!try_move_down(rock, map)) {
				set_to_rest(rock, map);
				rock_index = next_rock_index(rock_index);
				rock = make_rock(rock_index, map);
				break;
			}
		}
	}

	print(map);

	println("Solution1: {}", map.size());
}

void solution2()
{
	std::string_view filename{"input/day17.txt"};
	std::ifstream input{filename.data(), std::ifstream::in};
	if (!input.is_open())
		fatal_error("Missing file: {}", filename);

	std::string moves;
	std::getline(input, moves);

	int rock_index = 0;
	int move_index = 0;

	Bitmap map;
	Rock rock = make_rock(rock_index, map);

	size_t num_simulation = 1'000'000'000'000;

	for (size_t i = 0; i < num_simulation; i++)
	{
		for (;;)
		{
			char move = moves[move_index];
			move_index = (move_index + 1) % (int)moves.size();

			if (move == '>')
				try_move_right(rock, map);
			else if (move == '<')
				try_move_left(rock, map);
			else
				unreacheable();

			if (!try_move_down(rock, map)) {
				set_to_rest(rock, map);
				rock_index = next_rock_index(rock_index);
				rock = make_rock(rock_index, map);
				break;
			}
		}
	}

	print(map);

	println("Solution2: {}", map.size());
}
