#include "common.h"

#include <iostream>
#include <fstream>
#include <cassert>
#include <vector>

void solution1();
void solution2();

int main()
{
	solution1();
	solution2();
}

std::vector<std::vector<char>> parse_stacks(std::ifstream& input)
{
	std::vector<std::vector<char>> stacks;
	stacks.reserve(10);

	std::string line;
	while (input)
	{
		std::getline(input, line);

		for (std::size_t i = 0; i < line.size(); i++) {
			if (isspace(line[i]))
				continue;
			if (line[i] >= 'A' && line[i] <= 'Z') {
				// Found a stack entry
				// Insert at front of the stack, so it's ready for faster pops
				// from the back later.
				std::size_t stack_index = (i - 1u) / 4u;
				if (stacks.size() < stack_index + 1) {
					stacks.resize(stack_index + 1);
				}
				auto &stack = stacks[stack_index];
				if (stack.empty()) {
					stack.reserve(16);
				}
				stack.emplace(begin(stack), line[i]);
			}
			else if (line[i] >= '0' && line[i] <= '9')
			{
				// We are on the indices line, skip this and the next white-line
				std::getline(input, line);
				assert(line == "");
				return stacks;
			}
		}
	}

	unreacheable();
}

struct command
{
	int count = 0;
	int source = -1;
	int destination = -1;
};

[[nodiscard]] bool is_valid(const command& cmd)
{
	return cmd.count > 0 && cmd.source > 0 && cmd.destination > 0;
}

command parse_command(std::string_view line)
{
	command cmd{};

	const std::string_view move_substr = "move ";
	if (line.starts_with(move_substr)) {
		line = std::string_view{begin(line) + move_substr.size(), end(line)};
		line = parse_value(line, cmd.count);
	}
	else
		return {};

	const std::string_view from_substr = " from ";
	if (line.starts_with(from_substr)) {
		line = std::string_view{begin(line) + from_substr.size(), end(line)};
		line = parse_value(line, cmd.source);
	}
	else
		return {};

	const std::string_view to_substr = " to ";
	if (line.starts_with(to_substr)) {
		line = std::string_view{begin(line) + to_substr.size(), end(line)};
		line = parse_value(line, cmd.destination);
	}
	else
		return {};

	return cmd;
}

void solution1()
{
	std::string_view filename{"input/day5.txt"};
	std::ifstream input{filename.data(), std::ifstream::in};
	if (!input.is_open())
		fatal_error("Missing file: {}", filename);

	std::vector<std::vector<char>> stacks = parse_stacks(input);

	std::string line;
	while (input)
	{
		// Parse commands
		std::getline(input, line);
		if (line == "")
			break;

		command cmd = parse_command(line);
		assert(is_valid(cmd));

		auto &src = stacks[cmd.source - 1];
		auto &dst = stacks[cmd.destination - 1];
		for (int i = 0; i < cmd.count; i++) {
			dst.push_back(src.back());
			src.pop_back();
		}
	}

	print("Solution1: ");
	for (auto& stack : stacks)
	{
		print("{}", stack.back());
	}
	print("\n");
}

void solution2()
{
	std::string_view filename{"input/day5.txt"};
	std::ifstream input{filename.data(), std::ifstream::in};
	if (!input.is_open())
		fatal_error("Missing file: {}", filename);

	std::vector<std::vector<char>> stacks = parse_stacks(input);

	std::string line;
	while (input)
	{
		// Parse commands
		std::getline(input, line);
		if (line == "")
			break;

		command cmd = parse_command(line);
		assert(is_valid(cmd));

		auto &src = stacks[cmd.source - 1];
		auto &dst = stacks[cmd.destination - 1];

		for (std::size_t i = src.size() - cmd.count; i < src.size(); i++) {
			dst.push_back(src[i]);
		}
		src.resize(src.size() - (std::size_t)cmd.count);
	}

	print("Solution2: ");
	for (auto& stack : stacks)
	{
		print("{}", stack.back());
	}
	print("\n");
}
