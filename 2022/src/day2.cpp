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

void solution1()
{
	std::string_view filename{"input/day2.txt"};
	std::ifstream input{filename.data(), std::ifstream::in};
	if (!input.is_open())
		fatal_error("Missing file: {}", filename);

	enum Choice {
		Rock = 0,
		Paper,
		Scissors
	};
	long long results[][3] = {{3, 0, 6}, {6, 3, 0}, {0, 6, 3}};
	long long score = 0;

	std::string line;
	while (input)
	{
		std::getline(input, line);
		if (line == "")
		{
			break;
		}

		assert(line.size() == 3);
		Choice opponent = static_cast<Choice>(line[0] - 'A');
		Choice mine = static_cast<Choice>(line[2] - 'X');

		score += static_cast<long long>(mine) + 1 + results[mine][opponent];
	}

	println("Solution1: {}", score);
}

void solution2()
{
	std::string_view filename{"input/day2.txt"};
	std::ifstream input{filename.data(), std::ifstream::in};
	if (!input.is_open())
		fatal_error("Missing file: {}", filename);

	enum Choice {
		Rock = 0,
		Paper,
		Scissors
	};
	enum Outcome {
		Lose = 0,
		Draw,
		Win
	};

	Choice choice_for_outcome[][3] = {{Scissors, Rock, Paper}, {Rock, Paper, Scissors}, {Paper, Scissors, Rock}};
	long long score = 0;

	std::string line;
	while (input)
	{
		std::getline(input, line);
		if (line == "")
		{
			break;
		}

		assert(line.size() == 3);
		Choice opponent = static_cast<Choice>(line[0] - 'A');

		Choice mine{};
		switch (line[2])
		{
		case 'X':
			mine = choice_for_outcome[opponent][Lose];
			break;
		case 'Y':
			mine = choice_for_outcome[opponent][Draw];
			score += 3;
			break;
		case 'Z':
			mine = choice_for_outcome[opponent][Win];
			score += 6;
			break;
		default: unreacheable();
		}

		score += static_cast<long long>(mine) + 1;
	}

	println("Solution2: {}", score);
}
