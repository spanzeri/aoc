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

size_t detect_unique_msg(std::string_view msg, unsigned unique_count)
{
	for (size_t index = 0; index < msg.size() - unique_count;)
	{
		size_t next_index = 0;
		for (size_t i = index + unique_count - 1; i > index && !next_index ; i--)
		{
			for (size_t j = i - 1; j >= index; j--) {
				if (msg[i] == msg[j]) {
					next_index = j + 1;
					break;
				}
				if (j == 0) // Unsigend is the wrong default!
					break;
			}
		}

		if (next_index == 0)
			return index + unique_count;
		index = next_index;
	}
	unreacheable();
}

void solution1()
{
	std::string_view filename{"input/day6.txt"};
	std::ifstream input{filename.data(), std::ifstream::in};
	if (!input.is_open())
		fatal_error("Missing file: {}", filename);

	std::string line;
	while (input)
	{
		// Parse commands
		std::getline(input, line);
		assert(line.size() > 4);
		break;
	}

	println("Solution1: {}", detect_unique_msg(line, 4u));
}

void solution2()
{
	std::string_view filename{"input/day6.txt"};
	std::ifstream input{filename.data(), std::ifstream::in};
	if (!input.is_open())
		fatal_error("Missing file: {}", filename);

	std::string line;
	while (input)
	{
		// Parse commands
		std::getline(input, line);
		assert(line.size() > 4);
		break;
	}

	println("Solution2: {}", detect_unique_msg(line, 14u));
}
