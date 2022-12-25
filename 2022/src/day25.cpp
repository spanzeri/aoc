#include "common.h"

#include <iostream>
#include <fstream>
#include <cassert>
#include <vector>
#include <array>
#include <unordered_set>
#include <unordered_map>
#include <queue>

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

std::string snafu_adder(std::vector<std::string>& snafus)
{
	int rem = 0;
	std::vector<char> result;
	for (;;) {
		int sum = rem;
		rem = 0;
		bool all_empty = true;
		for (auto& s : snafus) {
			if (s.empty())
				continue;
			all_empty = false;
			char c = s.back();
			s.pop_back();

			switch (c) {
			case '0': break;
			case '1': sum += 1; break;
			case '2': sum += 2; break;
			case '-': sum -= 1; break;
			case '=': sum -= 2; break;
			}
		}

		while (sum > 2) {
			sum -= 5;
			rem += 1;
		}
		while (sum < -2) {
			sum += 5;
			rem -= 1;
		}

		if (all_empty && rem == 0)
			break;

		if (sum == -1) {
			result.emplace_back('-');
		}
		else if (sum == -2) {
			result.emplace_back('=');
		}
		else if (sum >= 0 && sum < 3) {
			result.emplace_back((char)('0' + sum));
		}
		else
			unreacheable();
	}

	std::string res;
	res.reserve(result.size());
	for (int i = (int)result.size() - 1; i >= 0; --i)
		res.push_back(result[i]);
	return res;
}

void solution1()
{
	std::string_view filename{"input/day25.txt"};
	std::ifstream input{filename.data(), std::ifstream::in};
	if (!input.is_open())
		fatal_error("Missing file: {}", filename);

	std::vector<std::string> snafus;
	while (input) {
		std::string line;
		std::getline(input, line);
		if (line.empty())
			continue;
		snafus.push_back(std::move(line));
	}

	std::string res = snafu_adder(snafus);

	println("Solution1: {}", res);
}

void solution2()
{
	std::string_view filename{"input/day25.txt"};
	std::ifstream input{filename.data(), std::ifstream::in};
	if (!input.is_open())
		fatal_error("Missing file: {}", filename);

	println("Solution2: {}", 0);
}
