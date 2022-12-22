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
		if (a.robots[i] != b.robots[i] || a.resources[i] != b.resources[i])
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

void mine(State& state) {
	for (int i = 0; i < Material::COUNT; i++)
		state.resources[i] += state.robots[i];
	++state.time;
}

#if 0

int solve_1bp(const Blueprint& bp, int time)
{
	int max_geodes = 0;

	int maxes[Material::COUNT];
	for (int i = 0; i < Material::COUNT; i++)
		maxes[0] = std::max(maxes[0], bp.costs[i][0]);
	for (int i = Clay; i < Geode; i++) {
		maxes[i] = bp.costs[i + 1][1];
	}
	maxes[Geode] = INT_MAX;

	auto can_build_robot = [&](State &state, int mat) {
		if (state.resources[Ore] < bp.costs[mat][0])
			return false;
		return mat > Clay ? state.resources[mat - 1] >= bp.costs[mat][1] : true;
	};

	auto should_build_robot = [&](State &state, int mat) {
		if (state.robots[mat] >= maxes[mat])
			return false;
		if (mat == Geode)
			return state.time < time;
		if (mat == Ore || mat == Obsidian)
			return state.time < time - 1;
		return state.time < time - 2;
	};

	auto should_build_any = [&](State &state) {
		return (can_build_robot(state, Ore) && should_build_robot(state, Ore)) ||
		       (can_build_robot(state, Clay) && should_build_robot(state, Clay)) ||
		       (can_build_robot(state, Obsidian) && should_build_robot(state, Obsidian)) ||
		       (can_build_robot(state, Geode) && should_build_robot(state, Geode));
	};

	auto build_robot = [&](State &state, int mat) {
		state.resources[Ore] -= bp.costs[mat][0];
		if (mat > Clay)
			state.resources[mat - 1] -= bp.costs[mat][1];
		mine(state);
		state.robots[mat] += 1;
	};

	State init = {};
	init.robots[Ore] = 1;

	std::queue<State> states;
	states.push(init);
	std::unordered_set<State> state_cache;

	while (!states.empty()) {
		State curr = states.front();
		states.pop();

		while (curr.time < time && !should_build_any(curr))
			mine(curr);

		if (state_cache.contains(curr))
			continue;
		state_cache.insert(curr);

		if (curr.time == time) {
			if (curr.resources[Geode] > max_geodes)
				max_geodes = curr.resources[Geode];
			continue;
		}

		bool built_geode = false;

		for (int i = Material::COUNT - 1; i >= 0; --i) {
			if (can_build_robot(curr, i) && should_build_robot(curr, i)) {
				State next = curr;
				build_robot(next, i);
				states.push(next);
				if (i == Geode) {
					built_geode = true;
					break;
				}
			}
		}
		if (built_geode)
			continue;

		mine(curr);
		states.push(curr);
	}

	return max_geodes;
}

#else

int solve_1bp(const Blueprint& bp, int time)
{
	int max_geodes = 0;

	int maxes[Material::COUNT];
	for (int i = 0; i < Material::COUNT; i++)
		maxes[0] = std::max(maxes[0], bp.costs[i][0]);
	for (int i = Clay; i < Geode; i++) {
		maxes[i] = bp.costs[i + 1][1];
	}
	maxes[Geode] = INT_MAX;

	auto compute_time_needed_before = [&](int mat) {
		int target = bp.costs[mat + 1][1];
		int i = 0;
		int accum = 0;
		for (;;) {
			++i;
			accum += i;
			if (accum > target)
				break;
		}
		return i;
	};
	int latests[Material::COUNT];
	latests[Geode] = time - 1;
	latests[Ore] = time - 2;
	latests[Obsidian] = latests[Geode] - compute_time_needed_before(Obsidian);
	latests[Clay] = latests[Obsidian] - compute_time_needed_before(Clay);

	auto is_too_late_with_robots = [&](const State &state) {
		for (int i = 0; i < Material::COUNT; i++) {
			if (state.robots[i] == 0 && state.time >= latests[i])
				return true;
		}
		return false;
	};

	auto can_build_robot = [&](State &state, int mat) {
		if (state.resources[Ore] < bp.costs[mat][0])
			return false;
		return mat > Clay ? state.resources[mat - 1] >= bp.costs[mat][1] : true;
	};

	auto should_build_robot = [&](State &state, int mat) {
		if (state.robots[mat] >= maxes[mat])
			return false;
		if (mat == Geode)
			return state.time < time;
		if (mat == Ore || mat == Obsidian)
			return state.time < time - 1;
		return state.time < time - 2;
	};

	auto should_build_any = [&](State &state) {
		return (can_build_robot(state, Ore) && should_build_robot(state, Ore)) ||
		       (can_build_robot(state, Clay) && should_build_robot(state, Clay)) ||
		       (can_build_robot(state, Obsidian) && should_build_robot(state, Obsidian)) ||
		       (can_build_robot(state, Geode) && should_build_robot(state, Geode));
	};

	auto build_robot = [&](State &state, int mat) {
		state.resources[Ore] -= bp.costs[mat][0];
		if (mat > Clay)
			state.resources[mat - 1] -= bp.costs[mat][1];
		mine(state);
		state.robots[mat] += 1;
	};

	State init = {};
	init.robots[Ore] = 1;

	std::queue<State> states;
	states.push(init);
	std::unordered_set<State> state_cache;

	while (!states.empty()) {
		State curr = states.front();
		states.pop();

		while (curr.time < time && !should_build_any(curr))
			mine(curr);

		if (state_cache.contains(curr))
			continue;
		state_cache.insert(curr);

		if (curr.time == time) {
			if (curr.resources[Geode] > max_geodes)
				max_geodes = curr.resources[Geode];
			continue;
		}

		if (is_too_late_with_robots(curr))
			continue;

		bool built_geode = false;

		for (int i = Material::COUNT - 1; i >= 0; --i) {
			if (can_build_robot(curr, i) && should_build_robot(curr, i)) {
				State next = curr;
				build_robot(next, i);
				states.push(next);
				if (i == Geode) {
					built_geode = true;
					break;
				}
			}
		}
		if (built_geode)
			continue;

		mine(curr);
		states.push(curr);
	}

	return max_geodes;
}

#endif

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

int solve2(std::vector<Blueprint>& bps, int time) {
	int result = 1;
	for (int i = 0; i < 3; i++)
	{
		auto &bp = bps[i];
		int max = solve_1bp(bp, time);
		println("Max geode for blueprint: {} = {}, Quality score: {}", bp.index, max, bp.index * max);
		result *= max;
	}

	return result;
}

void solution2()
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

	println("Solution2: {}", solve2(bps, 32));
}
