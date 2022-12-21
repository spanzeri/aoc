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

enum Material {
	Ore = 0,
	Clay,
	Obsidian,
	Geode,

	COUNT
};

struct Blueprint
{
	int index = 0;
	int costs[Material::COUNT][2] = {};
};

struct State {
	int robots[Material::COUNT] = {};
	int resources[Material::COUNT] = {};
	int time = 0;
};

bool operator==(const State& a, const State& b) {
	for (int i = 0; i < Material::COUNT; i++)
		if (a.robots[i] != b.robots[i] && a.resources[i] != b.resources[i])
			return false;
	return a.time == b.time;
}

namespace std {
template <>
struct hash<State> {
	size_t operator()(const State& s) const {
		size_t k = 0;
		for (int i = 0; i < Material::COUNT; i++)
			k ^= hash<int>()(s.robots[i]) ^ hash<int>()(s.resources[i]);
		k ^= hash<int>()(s.time);
		return k;
	}
};
}

std::string_view consume_prefix(std::string_view src, std::string_view prefix)
{
	assert(src.starts_with(prefix));
	return {begin(src) + prefix.size(), end(src)};
}

std::string_view parse_mat(std::string_view src, Material& out_mat)
{
	constexpr std::array<std::string_view, Material::COUNT> mat_strings{"ore", "clay", "obsidian", "geode"};
	for (int i = 0; i < (int)mat_strings.size(); i++) {
		if (src.starts_with(mat_strings[i])) {
			out_mat = (Material)i;
			return {begin(src) + mat_strings[i].size(), end(src)};
		}
	}
	unreacheable();
}

std::string_view parse_costs(std::string_view src, Blueprint& bp, Material mat) {
	for (;;) {
		src = trim(src);
		if (src.empty())
			return src;
		Material base;
		src = parse_value(src, bp.costs[mat][0]);
		src = trim(src);
		src = parse_mat(src, base);
		assert(base == Ore);
		if (mat >= Obsidian) {
			assert(src.starts_with(" and "));
			src = {begin(src) + sizeof(" and ") - 1, end(src)};
			src = parse_value(src, bp.costs[mat][1]);
			src = trim(src);
			src = parse_mat(src, base);
			assert(base == mat - 1);
		}
		assert(src.starts_with("."));
		return {begin(src) + 1, end(src)};
	}
}

Blueprint parse_blueprint(std::string_view src) {
	Blueprint bp = {};
	src = consume_prefix(src, "Blueprint ");
	src = parse_value(src, bp.index);
	src = consume_prefix(src, ": ");
	for (;;) {
		src = trim(src);
		if (src.empty())
			return bp;
		src = consume_prefix(src, "Each ");
		Material produced_mat;
		src = parse_mat(src, produced_mat);
		src = consume_prefix(src, " robot costs ");
		src = parse_costs(src, bp, produced_mat);
	}
}

int solve_1bp(const Blueprint& bp, int time)
{
	int max_geodes = 0;

	int max_robots[Material::COUNT];
	max_robots[Geode] = INT_MAX;
	for (int i = 0; i < Material::COUNT; i++)
		max_robots[Ore] = std::max(max_robots[Ore], bp.costs[i][0]);
	for (int i = 1; i < Material::Geode; i++)
		max_robots[i] = bp.costs[i + 1][1];

	State init_state = {};
	init_state.robots[Ore] = 1;

	std::vector<State> states;
	states.push_back(init_state);

	std::unordered_set<State> state_cache;

	auto mine = [](State &state) {
		for (int i = 0; i < Material::COUNT; ++i)
			state.resources[i] += state.robots[i];
		state.time += 1;
	};

	while (!states.empty())
	{
		State prev = states.back();
		states.pop_back();

		// Advance the state
		State curr = prev;
		mine(curr);

		if (curr.time == time) {
			if (curr.resources[Geode] > max_geodes)
				max_geodes = curr.resources[Geode];
			continue;
		}

		// Push a state where we do nothing
		if (!state_cache.contains(curr)) {
			states.push_back(curr);
			state_cache.insert(curr);
		}

		// Build a robot. Skip if we have too many for a type or if we could have
		// built it in the previous state and decided not to (as it wouldn't make sense)
		for (int i = 0; i < Material::COUNT; i++)
		{
			if (curr.time >= time - 2)
				continue;
			if (curr.robots[i] == max_robots[i])
				continue;
			if (curr.resources[Ore] < bp.costs[i][0] || (i > Clay && curr.resources[i - 1] < bp.costs[i][1]))
				continue;
			if (prev.resources[Ore] >= bp.costs[i][0] && (i <= Clay || prev.resources[i - 1] >= bp.costs[i][1]))
				continue;

			// Build the robot
			State curr_with_robot = curr;
			curr_with_robot.resources[Ore] -= bp.costs[i][0];
			if (i > Clay)
				curr_with_robot.resources[i - 1] -= bp.costs[i][1];
			curr_with_robot.robots[i] += 1;
			mine(curr_with_robot);

			if (!state_cache.contains(curr_with_robot)) {
				states.push_back(curr_with_robot);
				state_cache.insert(curr_with_robot);
			}
		}
	}

	return max_geodes;
}

int solve(std::vector<Blueprint>& bps, int time) {
	int result = 0;
	for (auto& bp : bps)
	{
		int max = solve_1bp(bp, time);
		println("Max geode for blueprint: {} = {}, Quality score: {}", bp.index, max, bp.index * max);
		result += bp.index * max;
	}

	return result;
}

void solution1()
{
	std::string_view filename{"input/day19.txt"};
	std::ifstream input{filename.data(), std::ifstream::in};
	if (!input.is_open())
		fatal_error("Missing file: {}", filename);

	std::vector<Blueprint> bps;

	std::string line;
	while (input) {
		std::getline(input, line);
		if (line.empty())
			continue;
		bps.push_back(parse_blueprint(line));
	}

	println("Solution1: {}", solve(bps, 24));
}

void solution2()
{
	std::string_view filename{"input/day19.txt"};
	std::ifstream input{filename.data(), std::ifstream::in};
	if (!input.is_open())
		fatal_error("Missing file: {}", filename);

	println("Solution2: {}", 0);
}
