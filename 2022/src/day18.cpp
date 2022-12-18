#include "common.h"

#include <iostream>
#include <fstream>
#include <cassert>
#include <vector>
#include <unordered_set>

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

vec3i parse_position(std::string_view src)
{
	vec3i res = {0, 0, 0};
	src = parse_value(src, res.x);

	assert(src.starts_with(","));
	src = {begin(src) + 1, end(src)};
	src = parse_value(src, res.y);

	assert(src.starts_with(","));
	src = {begin(src) + 1, end(src)};
	src = parse_value(src, res.z);

	return res;
}

int count_sides(const std::unordered_set<vec3i>& cubes, vec3i current)
{
	constexpr vec3i directions[] = {
		{ 0,  0, -1},
		{ 0,  0,  1},
		{ 0, -1,  0},
		{ 0,  1,  0},
		{-1,  0,  0},
		{ 1,  0,  0},
	};

	int sides = 0;
	for (auto dir : directions) {
		if (cubes.find(current + dir) == end(cubes))
			++sides;
	}

	return sides;
}

void solution1()
{
	std::string_view filename{"input/day18.txt"};
	std::ifstream input{filename.data(), std::ifstream::in};
	if (!input.is_open())
		fatal_error("Missing file: {}", filename);

	std::unordered_set<vec3i> cubes;

	std::string line;
	vec3i ext_min = {INT_MAX, INT_MAX, INT_MAX};
	vec3i ext_max = {INT_MIN, INT_MIN, INT_MIN};
	while (input)
	{
		std::getline(input, line);
		if (line.empty())
			continue;
		vec3i pos = parse_position(line);
		cubes.insert(pos);
		ext_min = min(ext_min, pos);
		ext_max = max(ext_max, pos);
	}

	int sum = 0;
	for (auto cube : cubes)
	{
		sum += count_sides(cubes, cube);
	}

	println("Solution1: {}", sum);
}

void solution2()
{
	std::string_view filename{"input/day18.txt"};
	std::ifstream input{filename.data(), std::ifstream::in};
	if (!input.is_open())
		fatal_error("Missing file: {}", filename);

	println("Solution2: {}", 0);
}
