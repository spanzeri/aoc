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

struct Sensor
{
	vec2i pos;
	vec2i closest_beacon;
};

Sensor parse_line(std::string_view src)
{
	constexpr std::string_view sensor_x_prefix = "Sensor at x=";
	constexpr std::string_view sensor_y_prefix = ", y=";
	constexpr std::string_view beacon_x_prefix = ": closest beacon is at x=";
	constexpr std::string_view beacon_y_prefix = ", y=";

	Sensor sensor = {};

	auto parse_coord = [](std::string_view& src, std::string_view prefix, int &val) {
		assert(src.starts_with(prefix));
		src = {begin(src) + prefix.size(), end(src)};
		src = parse_value(src, val);
	};

	parse_coord(src, sensor_x_prefix, sensor.pos.x);
	parse_coord(src, sensor_y_prefix, sensor.pos.y);
	parse_coord(src, beacon_x_prefix, sensor.closest_beacon.x);
	parse_coord(src, beacon_y_prefix, sensor.closest_beacon.y);

	return sensor;
}

struct Range {
	int min = 0, max = 0;

	bool contains(int x) { return (x >= min) && (x <= max); }

	bool intersect(Range other)
	{
		if (other.contains(min) || other.contains(max))
			return true;
		return contains(other.min) || contains(other.max);
	}

	Range merge(Range other) { return {std::min(min, other.min), std::max(max, other.max)}; }
};

void solution1()
{
	std::string_view filename{"input/day15.txt"};
	std::ifstream input{filename.data(), std::ifstream::in};
	if (!input.is_open())
		fatal_error("Missing file: {}", filename);

	std::vector<Sensor> sensors;
	std::string line;

	while (input) {
		std::getline(input, line);
		if (line.empty())
			continue;
		sensors.push_back(parse_line(line));
	}

	constexpr int target_y = 2'000'000;

	std::vector<Range> tested_xs;
	std::unordered_set<int> beacon_xs;

	for (const auto& sensor : sensors) {
		if (sensor.closest_beacon.y == target_y)
			beacon_xs.insert(sensor.closest_beacon.x);
	}

	for (const auto& sensor : sensors) {
		int beacon_distance = manhattan_distance(sensor.pos, sensor.closest_beacon);
		if (beacon_distance < std::abs(sensor.pos.y - target_y))
			continue;

		int x_ext = beacon_distance - std::abs(sensor.pos.y - target_y);
		Range range = {sensor.pos.x - x_ext, sensor.pos.x + x_ext};

		for (size_t index = 0; index < tested_xs.size();)
		{
			if (range.intersect(tested_xs[index])) {
				range = range.merge(tested_xs[index]);
				tested_xs[index] = tested_xs.back();
				tested_xs.pop_back();
			}
			else
				++index;
		}
		tested_xs.push_back(range);
	}

	int count = 0;
	for (auto& range : tested_xs) {
		for (int x = range.min; x <= range.max; x++)
			if (beacon_xs.find(x) == beacon_xs.end())
				++count;
	}

	println("Solution2: {}", count);
}

void solution2()
{
	std::string_view filename{"input/day15.txt"};
	std::ifstream input{filename.data(), std::ifstream::in};
	if (!input.is_open())
		fatal_error("Missing file: {}", filename);

	std::vector<Sensor> sensors;
	std::string line;

	while (input) {
		std::getline(input, line);
		if (line.empty())
			continue;
		sensors.push_back(parse_line(line));
	}

#if 0
	std::unordered_set<int> beacon_xs;

	for (const auto& sensor : sensors) {
		if (sensor.closest_beacon.y == target_y)
			beacon_xs.insert(sensor.closest_beacon.x);
	}
#endif

	auto skip_if_in_range = [&](Sensor s, vec2i pos) {
		int sensor_range = manhattan_distance(s.pos, s.closest_beacon);
		int x_extent = sensor_range - std::abs(s.pos.y - pos.y);
		Range range = {s.pos.x - x_extent, s.pos.x + x_extent};
		if (range.contains(pos.x))
			return vec2i{range.max + 1, pos.y};
		return pos;
	};

	constexpr int max_coord = 4'000'000;

	vec2i pos{};
	bool found = false;

	for (int y = 0; y <= max_coord && !found; ++y)
	{
		for (int x = 0; x <= max_coord;)
		{
			pos = {x, y};
			vec2i next_pos = pos;
			for (const auto& sensor : sensors) {
				auto skip_pos = skip_if_in_range(sensor, pos);
				next_pos.x = std::max(next_pos.x, skip_pos.x);
			}

			if (next_pos.x == pos.x) {
				found = true;
				break;
			}
			else {
				x = next_pos.x;
			}
		}
	}

	constexpr int multiplier = 4'000'000;

	println("Solution2: {}", (long long)pos.x * multiplier + pos.y);
}
