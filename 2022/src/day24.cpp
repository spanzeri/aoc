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

struct Blizzard {
	vec2i pos;
	vec2i dir;
};

struct Map {
	std::vector<Blizzard> blizzards;
	vec2i start;
	vec2i end;

	bool is_inside(vec2i pos) const {
		if (pos.x <= 0 || pos.x >= end.x + 1)
			return false;
		if (pos.y <= 0 && pos != start)
			return false;
		if (pos.y >= end.y && pos != end)
			return false;
		return true;
	}
};

Map parse_map(std::ifstream& input) {
	Map map = {};
	std::string line;

	// First line
	std::getline(input, line);
	assert(!line.empty());
	int map_width = (int)line.size();
	int map_height = 1;
	assert(line[1] == '.');
	map.start = {1, 0};

	while (input) {
		std::getline(input, line);
		assert(!line.empty());
		assert((int)line.size() == map_width);
		assert(line[0] == '#' && line.back() == '#');
		if (line[1] == '#') {
			// Last line
			assert(line[map_width - 2] == '.');
			map.end = {map_width - 2, map_height};
			break;
		}
		else {
			for (int i = 1; i < map_width - 1; i++) {
				char c = line[i];
				if (c == '>')
					map.blizzards.emplace_back(vec2i{i, map_height}, vec2i{ 1, 0});
				else if (c == '<')
					map.blizzards.emplace_back(vec2i{i, map_height}, vec2i{-1, 0});
				else if (c == '^')
					map.blizzards.emplace_back(vec2i{i, map_height}, vec2i{ 0, -1});
				else if (c == 'v')
					map.blizzards.emplace_back(vec2i{i, map_height}, vec2i{ 0,  1});
				else
					assert(c == '.');
			}
		}

		++map_height;
	}

	return map;
}

using BlizzardAtTime = std::vector<std::vector<Blizzard>>;

void make_blizzard_state(BlizzardAtTime& blizzards, const Map& map, int time)
{
	assert((int)blizzards.size() == time);
	blizzards.resize(time + 1);
	const auto& prev_state = blizzards[time - 1];
	auto &curr_state = blizzards[time];

	for (auto blizzard : prev_state) {
		vec2i next_pos = blizzard.pos + blizzard.dir;
		if (!map.is_inside(next_pos)) {
			// wrap
			if (blizzard.dir.x == 1)
				next_pos.x = map.start.x;
			else if (blizzard.dir.x == -1)
				next_pos.x = map.end.x;
			else if (blizzard.dir.y == 1)
				next_pos.y = map.start.y + 1;
			else if (blizzard.dir.y == -1)
				next_pos.y = map.end.y - 1;
			else
				unreacheable();
		}
		assert(map.is_inside(next_pos));
		curr_state.emplace_back(next_pos, blizzard.dir);
	}
	assert(blizzards[time - 1].size() == map.blizzards.size());
}

void print_state(const Map& map, vec2i expedition, const std::vector<Blizzard>& blizzards, int time)
{
	println("Minute {}", time);
	for (int i = 0; i < map.end.x + 2; i++)
	{
		if (i == map.start.x)
			print(".");
		else
			print("#");
	}
	println("");

	for (int y = 1; y < map.end.y; y++) {
		print("#");
		for (int x = map.start.x; x <= map.end.x; ++x) {
			vec2i pos = {x, y};
			int bcount = 0;
			for (const auto& b : blizzards) {
				if (b.pos == pos)
					bcount += 1;
			}
			if (pos == expedition) {
				print("E");
			}
			else if (bcount > 0) {
				print("{}", bcount);
			}
			else
				print(".");
		}
		println("#");
	}

	for (int i = 0; i < map.end.x + 2; i++)
	{
		if (i == map.end.x)
			print(".");
		else
			print("#");
	}
	println("\n");
}

int solve(const Map& map)
{
	BlizzardAtTime blizzard_at_time;
	blizzard_at_time.push_back(map.blizzards);

	struct State {
		vec2i expedition;
		int time;
		bool operator ==(const State& b) const {
			return expedition == b.expedition && time == b.time;
		}
	};

	struct StateHasher
	{
		size_t operator()(State state) const {
			return std::hash<vec2i>()(state.expedition) ^ std::hash<int>()(state.time);
		}
	};

	std::queue<State> states;
	states.push({map.start, 0});
	int best_time = INT_MAX;
	std::unordered_set<State, StateHasher> state_cache;

	auto try_move = [&](const State &curr, vec2i move) {
		vec2i next = curr.expedition + move;
		if (map.is_inside(next))
			states.emplace(next, curr.time + 1);
		assert(manhattan_distance(curr.expedition, next) == 1);
	};

	while (!states.empty()) {
		State curr = states.front();
		states.pop();

		// We got to the end faster
		if (curr.time >= best_time)
			continue;

		if (state_cache.contains(curr))
			continue;
		state_cache.insert(curr);

		// Update where the blizzards are at
		if (curr.time >= (int)blizzard_at_time.size()) {
			make_blizzard_state(blizzard_at_time, map, curr.time);
			// print_state(map, curr.expedition, blizzard_at_time[curr.time], curr.time);
		}

		// The expedition is inside a blizzard, throw this state away
		const auto &bliz = blizzard_at_time[curr.time];
		auto it = std::find_if(begin(bliz), end(bliz), [&](const Blizzard &b) { return b.pos == curr.expedition; });
		if (it != end(bliz))
			continue;

		// We can get to the end in the next step
		if (curr.expedition == vec2i{map.end.x, map.end.y - 1}) {
			int final_time = curr.time + 1;
			if (final_time < best_time)
				best_time = final_time;
			continue;
		}

		// Try all the states, in the order that is likely going to give us the best result
		states.emplace(curr.expedition, curr.time + 1); // Wait in place
		try_move(curr, vec2i{ 0, -1}); // Move up
		try_move(curr, vec2i{-1,  0}); // Move left
		try_move(curr, vec2i{ 0,  1}); // Move down
		try_move(curr, vec2i{ 1,  0}); // Move right
	}

	return best_time;
}

void solution1()
{
	std::string_view filename{"input/day24.txt"};
	std::ifstream input{filename.data(), std::ifstream::in};
	if (!input.is_open())
		fatal_error("Missing file: {}", filename);

	Map map = parse_map(input);
	int res = solve(map);

	println("Solution1: {}", res);
}

struct OneTripRes {
	int time;
	std::vector<Blizzard> blizzard_at_time;
};

OneTripRes one_trip(const Map& map, vec2i start, vec2i end)
{
	BlizzardAtTime blizzard_at_time;
	blizzard_at_time.push_back(map.blizzards);

	struct State {
		vec2i expedition;
		int time;
		bool operator ==(const State& b) const {
			return expedition == b.expedition && time == b.time;
		}
	};

	struct StateHasher
	{
		size_t operator()(State state) const {
			return std::hash<vec2i>()(state.expedition) ^ std::hash<int>()(state.time);
		}
	};

	std::queue<State> states;
	states.push({start, 0});
	int best_time = INT_MAX;
	std::unordered_set<State, StateHasher> state_cache;

	auto try_move = [&](const State &curr, vec2i move) {
		vec2i next = curr.expedition + move;
		if (map.is_inside(next))
			states.emplace(next, curr.time + 1);
		assert(manhattan_distance(curr.expedition, next) == 1);
	};

	while (!states.empty()) {
		State curr = states.front();
		states.pop();

		// We got to the end faster
		if (curr.time >= best_time)
			continue;

		if (state_cache.contains(curr))
			continue;
		state_cache.insert(curr);

		// Update where the blizzards are at
		if (curr.time >= (int)blizzard_at_time.size()) {
			make_blizzard_state(blizzard_at_time, map, curr.time);
			// print_state(map, curr.expedition, blizzard_at_time[curr.time], curr.time);
		}

		// The expedition is inside a blizzard, throw this state away
		const auto &bliz = blizzard_at_time[curr.time];
		auto it = std::find_if(begin(bliz), bliz.end(), [&](const Blizzard &b) { return b.pos == curr.expedition; });
		if (it != bliz.end())
			continue;

		// We can get to the end in the next step
		if (curr.expedition == end) {
			int final_time = curr.time;
			if (final_time < best_time)
				best_time = final_time;
			continue;
		}

		// Try all the states, in the order that is likely going to give us the best result
		states.emplace(curr.expedition, curr.time + 1); // Wait in place
		try_move(curr, vec2i{ 0, -1}); // Move up
		try_move(curr, vec2i{-1,  0}); // Move left
		try_move(curr, vec2i{ 0,  1}); // Move down
		try_move(curr, vec2i{ 1,  0}); // Move right
	}

	return {best_time, blizzard_at_time[best_time]};
}

int solve2(const Map& map)
{
	auto first_trip = one_trip(map, map.start, map.end);
	Map map2 = map;
	map2.blizzards = first_trip.blizzard_at_time;
	auto second_trip = one_trip(map2, map.end, map.start);
	map2.blizzards = second_trip.blizzard_at_time;
	auto third_trip = one_trip(map2, map.start, map.end);

	println("Time for trips: 1) {}, 2) {}, 3) {}", first_trip.time, second_trip.time, third_trip.time);

	return first_trip.time + second_trip.time + third_trip.time;
}

void solution2()
{
	std::string_view filename{"input/day24.txt"};
	std::ifstream input{filename.data(), std::ifstream::in};
	if (!input.is_open())
		fatal_error("Missing file: {}", filename);

	Map map = parse_map(input);
	int res = solve2(map);

	println("Solution2: {}", res);
}
