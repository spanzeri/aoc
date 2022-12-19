#include "common.h"

#include <iostream>
#include <fstream>
#include <cassert>
#include <vector>
#include <array>
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

enum Material {
	Ore = 0,
	Clay,
	Obsidian,
	Geode,

	COUNT
};

using MatArray = std::array<int, Material::COUNT>;
using CostArray = std::array<MatArray, Material::COUNT>;

struct Blueprint
{
	int index;
	CostArray costs;
};

struct State {
	MatArray robots;
	MatArray resources;
};

bool operator==(const State& a, const State& b) {
	return a.resources == b.resources && a.robots == b.robots;
}

namespace std {
template <>
struct hash<State> {
	size_t operator()(const State& s) const {
		size_t k = 0;
		for (int i = 0; i < Material::COUNT; i++)
			k ^= hash<int>()(s.robots[i]) | hash<int>()(s.resources[i]) << 32;
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

std::string_view parse_costs(std::string_view src, MatArray& costs) {
	for (;;) {
		src = trim(src);
		if (src.empty())
			return src;
		int amount;
		Material mat;
		src = parse_value(src, amount);
		src = trim(src);
		src = parse_mat(src, mat);
		costs[mat] = amount;
		if (src.starts_with(" and "))
			src = {begin(src) + sizeof(" and ") - 1, end(src)};
		else if (src.starts_with("."))
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
		src = parse_costs(src, bp.costs[(size_t)produced_mat]);
	}
}

State make_new_state(const State& prev)
{
	State next = prev;
	for (int i = 0; i < Material::COUNT; i++)
		next.resources[i] += next.robots[i];
	return next;
}

bool can_build_robot(const State& state, const Blueprint& bp, Material mat)
{
	for (int i = 0; i < Material::COUNT; i++)
		if (state.resources[i] < bp.costs[mat][i])
			return false;
	return true;
}

State build_robot(const State& prev, const Blueprint& bp, Material mat)
{
	State next = prev;
	for (int i = 0; i < Material::COUNT; i++)
		next.resources[i] -= bp.costs[mat][i];
	next.robots[mat] += 1;
	return next;
}

int solve_1bp(State initial, const Blueprint& bp, int time)
{
	MatArray maxes = {};
	for (auto& cost : bp.costs) {
		for (int i = 0; i < Material::COUNT; i++)
			maxes[i] = std::max(maxes[i], cost[i]);
	}

	MatArray latest = {};
	latest[Material::COUNT - 1] = time - 1;
	for (int mat = Material::COUNT - 2; mat >= 0; --mat) {
		latest[mat] = latest[mat + 1] - maxes[mat];
	}

	std::unordered_set<State> states[2];
	states[0].insert(initial);

	for (int ct = 0; ct < time; ct++) {
		if (ct == 21) {
			int x = 0;
			x = x;
		}
		println("At time {} num states {}", ct, states[0].size());

		for (const auto& state : states[0]) {
			State current = make_new_state(state);

			bool useless = false;
			for (int mat = 1; mat < Material::COUNT; mat++) {
				if (current.robots[mat] == 0 && ct > latest[mat]) {
					//useless = true;
					break;
				}
			}
			if (useless)
				continue;
			for (int mat = 0; mat < Material::COUNT - 1; mat++) {
				if (current.resources[mat] > maxes[mat]) {
					useless = true;
					break;
				}
			}
			if (useless)
				continue;

			for (int mat = Material::COUNT - 1; mat >= 0; mat--)
			{
				if (current.robots[mat] >= maxes[mat])
					continue;
				if (!can_build_robot(current, bp, (Material)mat))
					continue;
				states[1].insert(build_robot(current, bp, (Material)mat));
			}

			states[1].insert(current);
		}

		states[0] = {};
		swap(states[0], states[1]);
	}

	int max = 0;
	for (const auto& state : states[0]) {
		if (state.resources[Geode] > max)
			max = state.resources[Geode];
	}

	return max;
}

int solve(std::vector<Blueprint>& bps, int time) {
	State init_state = {};
	init_state.robots[Ore] = 1;

	int result = 0;
	for (auto& bp : bps)
	{
		int max = solve_1bp(init_state, bp, time);
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
