#include "common.h"

#include <memory>
#include <iostream>
#include <fstream>
#include <cassert>
#include <vector>
#include <unordered_set>
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

struct Bitset3d {
	Bitset3d(vec3i min_, vec3i max_) {
		min = min_;
		extent = (max_ - min_) + vec3i{1, 1, 1};
		size_t alloc_size = (size_t)extent.x * (size_t)extent.y * (size_t)extent.z;
		size_t alloc_count = (alloc_size + 64 - 1) / 64;
		data = std::unique_ptr<uint64_t[]>(new uint64_t[alloc_count]());
	}

	struct Index {
		size_t pos;
		size_t bit;
	};

	Index make_index(vec3i pos) const {
		pos = pos - min;
		assert(pos.x >= 0 && pos.x < extent.x);
		assert(pos.y >= 0 && pos.y < extent.y);
		assert(pos.z >= 0 && pos.z < extent.z);

		size_t index =
			(size_t)pos.x +
			(size_t)pos.y * (size_t)extent.x +
			(size_t)pos.z * (size_t)extent.x * (size_t)extent.y;
		size_t ii = index / 64;
		size_t bb = index - (ii * 64);
		return {ii, bb};
	}

	bool test(vec3i pos) const {
		auto [i, b] = make_index(pos);
		return (data[i] & (1ull << b)) != 0;
	}

	void set(vec3i pos) {
		auto [i, b] = make_index(pos);
		data[i] |= 1ull << b;
	}

	vec3i min;
	vec3i extent;
	std::unique_ptr<uint64_t[]> data;
};

void solution2()
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

	ext_min -= {1, 1, 1};
	ext_max += {1, 1, 1};

	Bitset3d added_totest{ext_min, ext_max};
	auto is_valid = [=](vec3i pos)
	{
		if (pos.x < ext_min.x || pos.y < ext_min.y || pos.z < ext_min.z)
			return false;
		if (pos.x > ext_max.x || pos.y > ext_max.y || pos.z > ext_max.z)
			return false;
		return true;
	};

	vec3i directions[] = {
		{ 1,  0,  0},
		{-1,  0,  0},
		{ 0,  1,  0},
		{ 0, -1,  0},
		{ 0,  0,  1},
		{ 0,  0, -1},
	};

	int surface = 0;
	std::queue<vec3i> totest;
	totest.push({0, 0, 0});
	added_totest.set({0, 0, 0});

	while (!totest.empty()) {
		vec3i curr = totest.front();
		totest.pop();
		added_totest.set(curr);

		for (auto dir : directions) {
			auto next = curr + dir;
			if (!is_valid(next))
				continue;
			if (added_totest.test(next))
				continue;

			if (cubes.contains(next)) {
				++surface;
			}
			else {
				added_totest.set(next);
				totest.push(next);
			}
		}
	}

	println("Solution2: {}", surface);
}
