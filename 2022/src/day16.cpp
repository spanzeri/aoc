#include "common.h"

#include <iostream>
#include <fstream>
#include <cassert>
#include <vector>
#include <unordered_map>
#include <array>

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

constexpr int make_corridor_index(std::string_view name)
{
	return ((int)name[0] | ((int)name[1] << 8));
}

struct Valve {
	int index;
	int flow_rate = 0;
	std::vector<int> corridors;
};

std::string_view check_and_skip_prefix(std::string_view src, std::string_view prefix)
{
	assert(src.starts_with(prefix));
	return {begin(src) + prefix.size(), end(src)};
}

std::string_view parse_corridor_index(std::string_view src, std::vector<int>& corridors)
{
	assert(src.size() >= 2);
	corridors.push_back(make_corridor_index(src));
	return {begin(src) + 2, end(src)};
}

Valve parse_valve(std::string_view src) {
	Valve res = {};
	src = check_and_skip_prefix(src, "Valve ");
	res.index = make_corridor_index(src);
	src = {begin(src) + 2, end(src)};
	src = check_and_skip_prefix(src, " has flow rate=");
	src = parse_value(src, res.flow_rate);

	if (src.starts_with("; tunnels lead to valves "))
		src = check_and_skip_prefix(src, "; tunnels lead to valves ");
	else if (src.starts_with("; tunnel leads to valve "))
		src = check_and_skip_prefix(src, "; tunnel leads to valve ");
	else
		unreacheable();

	for (;;) {
		src = parse_corridor_index(src, res.corridors);
		if (!src.starts_with(", "))
			break;
		src = check_and_skip_prefix(src, ", ");
	}
	return res;
}

void solution1()
{
	std::string_view filename{"input/day16.txt"};
	std::ifstream input{filename.data(), std::ifstream::in};
	if (!input.is_open())
		fatal_error("Missing file: {}", filename);

	std::vector<Valve> valves;
	std::unordered_map<int, int> remap;
	std::string line;
	while (input) {
		std::getline(input, line);
		if (line.empty())
			continue;
		auto valve = parse_valve(line);
		remap[valve.index] = (int)valves.size();
		valves.push_back(valve);
	}

	for (auto& valve : valves) {
		for (auto& corridor : valve.corridors) {
			corridor = remap[corridor];
		}
	}

	println("Solution1: {}", 0);
}

void solution2()
{
	std::string_view filename{"input/day16.txt"};
	std::ifstream input{filename.data(), std::ifstream::in};
	if (!input.is_open())
		fatal_error("Missing file: {}", filename);

	println("Solution2: {}", 0);
}
