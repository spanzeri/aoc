#include "common.h"

#include <iostream>
#include <fstream>
#include <cassert>
#include <vector>
#include <queue>

void solution1();
void solution2();

int main()
{
	solution1();
	solution2();
}

struct Instruction {
	enum Kind {
		NoOp,
		AddX
	};
	Kind kind;
	int counter;
};

void solution1()
{
	std::string_view filename{"input/day10.txt"};
	std::ifstream input{filename.data(), std::ifstream::in};
	if (!input.is_open())
		fatal_error("Missing file: {}", filename);

	std::queue<Instruction> instructions = {};
	std::queue<int> values = {};

	int regx = 1;
	int cycle = 0;

	constexpr int LAST_CYCLE = 240;

	long long strength = 0;
	for (;;)
	{
		cycle += 1;

		std::string line;
		if (input) {
			std::getline(input, line);
		}

		if (line.starts_with("addx"))
		{
			int val = 0;
			parse_value({begin(line) + sizeof("addx"), end(line)}, val);
			instructions.emplace(Instruction::AddX, 2);
			values.emplace(val);
		}
		else {
			instructions.emplace(Instruction::NoOp, 1);
		}

		// During cycle
		if (cycle == 20 || ((cycle - 20) % 40) == 0) {
			strength += cycle * regx;
		}
		if (cycle >= LAST_CYCLE)
			break;

		// End of cycle
		auto &inst = instructions.front();
		inst.counter--;
		if (inst.counter == 0) {
			if (inst.kind == Instruction::AddX) {
				regx += values.front();
				values.pop();
			}
			instructions.pop();
		}
	}

	println("Solution1: {}", strength);
}


void solution2()
{
	std::string_view filename{"input/day10.txt"};
	std::ifstream input{filename.data(), std::ifstream::in};
	if (!input.is_open())
		fatal_error("Missing file: {}", filename);

	std::queue<Instruction> instructions = {};
	std::queue<int> values = {};

	int regx = 1;
	int cycle = 1;

	constexpr int LAST_CYCLE = 240;

	println("Solution2:");

	for (; cycle <= LAST_CYCLE; cycle++)
	{
		std::string line;
		if (input) {
			std::getline(input, line);
		}

		if (line.starts_with("addx"))
		{
			int val = 0;
			parse_value({begin(line) + sizeof("addx"), end(line)}, val);
			instructions.emplace(Instruction::AddX, 2);
			values.emplace(val);
		}
		else {
			instructions.emplace(Instruction::NoOp, 1);
		}

		// During cycle
		int sprite_position = (cycle - 1) % 40;
		if (sprite_position >= regx - 1 && sprite_position <= regx + 1)
			print("#");
		else
			print(".");
		if (sprite_position == 39)
			print("\n");

		// End of cycle
		auto &inst = instructions.front();
		inst.counter--;
		if (inst.counter == 0) {
			if (inst.kind == Instruction::AddX) {
				regx += values.front();
				values.pop();
			}
			instructions.pop();
		}
	}
}
