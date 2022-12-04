#include "common.h"

#include <iostream>
#include <fstream>
#include <ranges>
#include <cassert>

void solution1();
void solution2();

int main()
{
	solution1();
	solution2();
}

struct Range {
	int lb = 0;
	int ub = 0;
};

Range parse_range(std::string_view str)
{
	std::size_t mid = str.find('-');
	int lb = std::atoi(str.data());
	int ub = std::atoi(str.data() + mid + 1);
	return {lb, ub};
}

void parse_line(std::string_view line, Range& out_range1, Range& out_range2)
{
	std::size_t mid = line.find(',');
	std::string_view range_sv1{begin(line), begin(line) + mid};
	std::string_view range_sv2{begin(line) + mid + 1, end(line)};
	out_range1 = parse_range(range_sv1);
	out_range2 = parse_range(range_sv2);
}

void solution1()
{
	std::string_view filename{"input/day4.txt"};
	std::ifstream input{filename.data(), std::ifstream::in};
	if (!input.is_open())
		fatal_error("Missing file: {}", filename);

	std::string line;
	int sum = 0;
	while (input)
	{
		std::getline(input, line);
		if (line == "")
			break;
		Range r1, r2;
		parse_line(line, r1, r2);

		if ((r1.lb <= r2.lb && r1.ub >= r2.ub) || (r1.lb >= r2.lb && r1.ub <= r2.ub))
			++sum;
	}

	println("Solution1: {}", sum);
}

void solution2()
{
	std::string_view filename{"input/day4.txt"};
	std::ifstream input{filename.data(), std::ifstream::in};
	if (!input.is_open())
		fatal_error("Missing file: {}", filename);

	std::string line;
	int sum = 0;
	while (input)
	{
		std::getline(input, line);
		if (line == "")
			break;
		Range r1, r2;
		parse_line(line, r1, r2);

		if ((r1.lb >= r2.lb && r1.lb <= r2.ub) || (r1.ub >= r2.lb && r1.ub <= r2.ub) ||
			(r2.lb >= r1.lb && r2.lb <= r1.ub) || (r2.ub >= r1.lb && r2.ub <= r1.ub))
			++sum;
	}

	println("Solution2: {}", sum);
}
