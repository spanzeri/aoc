#include "common.h"

#include <iostream>
#include <fstream>
#include <cassert>
#include <vector>
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
