#include "common.h"

#include <iostream>
#include <fstream>
#include <numeric>

void solution1();
void solution2();

int main()
{
	solution1();
	solution2();
}

void solution1()
{
	std::string_view filename{"input/day1.txt"};

	std::ifstream input{filename.data(), std::ifstream::in};

	if (!input.is_open())
		fatal_error("Missing file: {}", filename);

	// S

	long long sum = 0;
	long long max = 0;

	std::string line;
	while (input)
	{
		std::getline(input, line);
		if (line == "")
		{
			max = std::max(max, sum);
			sum = 0;
		}
		else
			sum += std::stoll(line);
	}

	if (sum != 0)
		max = std::max(max, sum);

	println("Solution1: {}", max);
}

void solution2()
{
	std::string_view filename{"input/day1.txt"};

	std::ifstream input{filename.data(), std::ifstream::in};

	if (!input.is_open())
		fatal_error("Missing file: {}", filename);

	// S

	long long top3[] = {0, 0, 0};
	long long sum = 0;

	auto try_insert = [&top3](long long val) {
		for (auto &prev_top : top3)
		{
			if (prev_top <= val)
				std::swap(prev_top, val);
		}
	};

	std::string line;
	while (input)
	{
		std::getline(input, line);
		if (line == "")
		{
			try_insert(sum);
			sum = 0;
		}
		else
			sum += std::stoll(line);
	}

	println("Solution2: {}", std::accumulate(begin(top3), end(top3), 0ll));
}
