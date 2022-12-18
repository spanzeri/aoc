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

constexpr int make_index_from_label(std::string_view name)
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
	corridors.push_back(make_index_from_label(src));
	return {begin(src) + 2, end(src)};
}

Valve parse_valve(std::string_view src) {
	Valve res = {};
	src = check_and_skip_prefix(src, "Valve ");
	res.index = make_index_from_label(src);
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

struct Bitset
{
	uint64_t data = 0;
	void set(int index) { data |= 1ull << index; }
	bool test(int index) const { return (data & (1ull << index)) != 0; }
	void reset(int index) { data &= ~(1ull << index); }
	void flip(int index) { data ^= 1ull << index; }
};

int compute_open_flow(std::vector<Valve>& valves, Bitset open)
{
	int accum = 0;
	for (int vi = 0; vi < (int)valves.size(); vi++)
	{
		if (open.test(vi))
			accum += valves[vi].flow_rate;
	}
	return accum;
}

int dfs(
	std::vector<Valve>& valves, int index, const std::vector<std::vector<int>>& distances,
	Bitset open, int time_left, int released_pressure)
{
	int open_flow = compute_open_flow(valves, open);
	int max = released_pressure + open_flow * time_left;

	for (int vi = 0; vi < (int)valves.size(); vi++) {
		if (vi == index)
			continue;
		if (valves[vi].flow_rate == 0)
			continue;
		if (open.test(vi))
			continue;

		// Time to move there and open the valve
		int delta_time = distances[index][vi] + 1;
		if (time_left - delta_time < 2)
			continue;

		int new_total = released_pressure + open_flow * delta_time;
		open.set(vi);
		int new_max = dfs(valves, vi, distances, open, time_left - delta_time, new_total);
		max = std::max(max, new_max);
		open.reset(vi);
	}

	return max;
}

int solve(std::vector<Valve>& valves, int first_valve)
{
	std::vector<std::vector<int>> distances(valves.size(), std::vector<int>(valves.size(), (int)valves.size() + 1));

	for (size_t i = 0; i < valves.size(); i++) {
		distances[i][i] = 0;
		for (int adj : valves[i].corridors)
			distances[i][adj] = 1;
	}

	// Run the Floyd-Warshall algorithm to update the distance matrix.
	for (size_t k = 0; k < valves.size(); k++) {
		for (size_t i = 0; i < valves.size(); i++) {
			for (size_t j = 0; j < valves.size(); j++) {
				distances[i][j] = std::min(distances[i][j], distances[i][k] + distances[k][j]);
			}
		}
	}

	return dfs(valves, first_valve, distances, Bitset{}, 30, 0);
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

	int first_valve = 0;
	int start_index = make_index_from_label("AA");
	for (int vi = 0; vi < (int)valves.size(); vi++)
	{
		auto &valve = valves[vi];
		if (valve.index == start_index)
			first_valve = vi;
		for (auto& corridor : valve.corridors) {
			corridor = remap[corridor];
		}
	}

	println("Solution1: {}", solve(valves, first_valve));
}

bool should_open(std::vector<Valve>& valves, Bitset open, int current, int valve)
{
	if (valve == current)
		return false;
	if (open.test(valve))
		return false;
	return valves[valve].flow_rate > 0;
}

struct InitalState {
	int index;
	int time_left;
};

int dfs2(
	std::vector<Valve>& valves, bool consider_other, InitalState& init, int index, const std::vector<std::vector<int>>& distances,
	Bitset open, Bitset ignore, int time_left, int released_pressure)
{
	int open_flow = compute_open_flow(valves, open);
	int max = released_pressure + open_flow * time_left;

	if (consider_other)
	{
		int other_max = dfs2(valves, false, init, init.index, distances, Bitset{}, open, init.time_left, 0);
		max += other_max;
	}

	for (int vi = 0; vi < (int)valves.size(); vi++) {
		if (vi == index)
			continue;
		if (valves[vi].flow_rate == 0)
			continue;
		if (open.test(vi))
			continue;
		if (!consider_other && ignore.test(vi))
			continue;

		// Time to move there and open the valve
		int delta_time = distances[index][vi] + 1;
		if (time_left - delta_time < 2)
			continue;

		int new_total = released_pressure + open_flow * delta_time;
		open.set(vi);
		int new_max = dfs2(valves, consider_other, init, vi, distances, open, ignore, time_left - delta_time, new_total);
		max = std::max(max, new_max);
		open.reset(vi);
	}

	return max;
}

int solve2(std::vector<Valve>& valves, int first_valve)
{
	std::vector<std::vector<int>> distances(valves.size(), std::vector<int>(valves.size(), (int)valves.size() + 1));

	for (size_t i = 0; i < valves.size(); i++) {
		distances[i][i] = 0;
		for (int adj : valves[i].corridors)
			distances[i][adj] = 1;
	}

	// Run the Floyd-Warshall algorithm to update the distance matrix.
	for (size_t k = 0; k < valves.size(); k++) {
		for (size_t i = 0; i < valves.size(); i++) {
			for (size_t j = 0; j < valves.size(); j++) {
				distances[i][j] = std::min(distances[i][j], distances[i][k] + distances[k][j]);
			}
		}
	}

	InitalState init{.index = first_valve, .time_left = 26};

	return dfs2(valves, true, init, init.index, distances, Bitset{}, Bitset{}, init.time_left, 0);
}

void solution2()
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

	int first_valve = 0;
	int start_index = make_index_from_label("AA");
	for (int vi = 0; vi < (int)valves.size(); vi++)
	{
		auto &valve = valves[vi];
		if (valve.index == start_index)
			first_valve = vi;
		for (auto& corridor : valve.corridors) {
			corridor = remap[corridor];
		}
	}

	println("Solution1: {}", solve2(valves, first_valve));
}
