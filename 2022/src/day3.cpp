#include "common.h"

#include <iostream>
#include <fstream>
#include <numeric>
#include <cassert>

void solution1();
void solution2();

int main()
{
	solution1();
	solution2();
}

int get_item_priority(char item)
{
	if (item >= 'a' && item <= 'z')
		return item - 'a' + 1;
	if (item >= 'A' && item <= 'Z')
		return item - 'A' + 27;
	unreacheable();
}

void solution1()
{
	std::string_view filename{"input/day3.txt"};
	std::ifstream input{filename.data(), std::ifstream::in};
	if (!input.is_open())
		fatal_error("Missing file: {}", filename);

	std::string line;
	long long sum = 0;
	while (input)
	{
		std::getline(input, line);
		uint64_t flags = 0;

		std::size_t mid = line.size() / std::size_t{2};
		for (std::size_t i = 0; i < mid; i++)
			flags |= 1ull << (uint64_t)get_item_priority(line[i]);

		for (std::size_t i = mid; i < line.size(); i++)
		{
			char item = line[i];
			int priority = get_item_priority(item);
			uint64_t mask = 1ull << (uint64_t)priority;

			if ((flags & mask) != 0)
			{
				sum += priority;
				// Only mark it once
				flags = flags & (~mask);
			}
		}
	}

	println("Solution1: {}", sum);
}

void solution2()
{
	std::string_view filename{"input/day3.txt"};
	std::ifstream input{filename.data(), std::ifstream::in};
	if (!input.is_open())
		fatal_error("Missing file: {}", filename);

	std::string line[3];
	long long sum = 0;
	while (input)
	{
		std::getline(input, line[0]);
		if (!input) break; // No asserts, could be empty lines at the end
		std::getline(input, line[1]);
		if (!input) break;
		std::getline(input, line[2]);

		auto compute_flag = [](std::string_view items) {
			uint64_t flag = 0;
			for (auto item : items)
				flag |= 1ull << (uint64_t)get_item_priority(item);
			return flag;
		};

		auto combined_flags = compute_flag(line[0]) & compute_flag(line[1]) & compute_flag(line[2]);
		assert(combined_flags != 0);

		constexpr int MIN_PRIORITY = 1;
		constexpr int MAX_PRIORITY = 57;

		// Start as 1 because priorities start at 1
		int priority = MIN_PRIORITY;
		for (; priority <= MAX_PRIORITY; priority++)
		{
			if ((combined_flags >> priority) & 0x1)
				break;
		}
		assert(priority >= MIN_PRIORITY);
		assert(priority <= MAX_PRIORITY);
		assert((combined_flags & ~(1ull << priority)) == 0); // Only one item shared

		sum += priority;
	}

	println("Solution2: {}", sum);
}
