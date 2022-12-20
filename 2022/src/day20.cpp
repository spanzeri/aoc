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

void solution1()
{
	std::string_view filename{"input/day20.txt"};
	std::ifstream input{filename.data(), std::ifstream::in};
	if (!input.is_open())
		fatal_error("Missing file: {}", filename);

	std::vector<int> nums;

	std::string line;
	while (input) {
		std::getline(input, line);
		if (line.empty())
			continue;
		nums.push_back(0);
		parse_value(line, nums.back());
	}

	int count = (int)nums.size();

	std::vector<int> pos_to_index(nums.size(), 0);
	std::vector<int> index_to_pos(nums.size(), 0);
	for (int i = 0; i < count; i++) {
		pos_to_index[i] = i;
		index_to_pos[i] = i;
	}

	auto print_nums = [&]() {
		print("[");
		for (auto n : nums) {
			print("{} ", n);
		}
		println("]");
	};

	auto find_dest = [&](int curr_index, int64_t shift) {
		shift -= shift < 0 ? 1 : 0;
		auto index = (curr_index + shift) % (count - 1);
		if (index < 0)
			index += count;
		return (int)index;
	};

	// Mixing
	for (int indexi = 0; indexi < count; indexi++)
	{
		//print_nums();

		int curr_index = index_to_pos[indexi];
		int shift = nums[curr_index];
		int dest_index = find_dest(curr_index, shift);

		if (curr_index == dest_index)
			continue;

		if (dest_index < curr_index) {
			// Slide forward
			int window = curr_index - dest_index;
			int temp_pos = pos_to_index[curr_index];
			memmove(&nums[dest_index + 1], &nums[dest_index], (size_t)window * sizeof(int));
			memmove(&pos_to_index[dest_index + 1], &pos_to_index[dest_index], (size_t)window * sizeof(int));
			nums[dest_index] = shift;
			pos_to_index[dest_index] = temp_pos;
		}
		else {
			// Slide backward
			int window = dest_index - curr_index;
			int temp_pos = pos_to_index[curr_index];
			memmove(&nums[curr_index], &nums[curr_index + 1], (size_t)window * sizeof(int));
			memmove(&pos_to_index[curr_index], &pos_to_index[curr_index + 1], (size_t)window * sizeof(int));
			nums[dest_index] = shift;
			pos_to_index[dest_index] = temp_pos;
		}

		for (int i = 0; i < count; i++) {
			int index = pos_to_index[i];
			index_to_pos[index] = i;
		}
	}
	//print_nums();

	int zero_pos = 0;
	for (; zero_pos < count; zero_pos++)
		if (nums[zero_pos] == 0)
			break;

	int p0 = (zero_pos + 1000) % count;
	int p1 = (zero_pos + 2000) % count;
	int p2 = (zero_pos + 3000) % count;
	println("Sum of: {} {} {}", nums[p0], nums[p1], nums[p2]);

	println("Solution1: {}", nums[p0] + nums[p1] + nums[p2]);
}

void solution2()
{
	std::string_view filename{"input/day20.txt"};
	std::ifstream input{filename.data(), std::ifstream::in};
	if (!input.is_open())
		fatal_error("Missing file: {}", filename);

	std::vector<int64_t> nums;

	std::string line;
	while (input) {
		std::getline(input, line);
		if (line.empty())
			continue;
		nums.push_back(0);
		parse_value(line, nums.back());
	}

	for (auto& n : nums)
		n *= 811589153;

	int count = (int)nums.size();

	std::vector<int> pos_to_index(nums.size(), 0);
	std::vector<int> index_to_pos(nums.size(), 0);
	for (int i = 0; i < count; i++) {
		pos_to_index[i] = i;
		index_to_pos[i] = i;
	}

	auto print_nums = [&]() {
		print("[");
		for (auto n : nums) {
			print("{} ", n);
		}
		println("]");
	};

	auto find_dest = [&](int curr_index, int64_t shift) {
		auto index = (curr_index + shift) % (count - 1);
		if (index < 0)
			index += count - 1;
		return (int)index;
	};

	// Mixing
	for (int indexi = 0; indexi < count * 10; indexi++)
	{
		// print_nums();
		int curr_index = index_to_pos[indexi % count];
		int64_t current_num = nums[curr_index];
		int64_t shift = nums[curr_index];
		int dest_index = find_dest(curr_index, shift);

		if (curr_index == dest_index)
			continue;

		if (dest_index < curr_index) {
			// Slide forward
			int window = curr_index - dest_index;
			int temp_pos = pos_to_index[curr_index];
			memmove(&nums[dest_index + 1], &nums[dest_index], (size_t)window * sizeof(nums[0]));
			memmove(&pos_to_index[dest_index + 1], &pos_to_index[dest_index], (size_t)window * sizeof(pos_to_index[0]));
			nums[dest_index] = current_num;
			pos_to_index[dest_index] = temp_pos;
		}
		else {
			// Slide backward
			int window = dest_index - curr_index;
			int temp_pos = pos_to_index[curr_index];
			memmove(&nums[curr_index], &nums[curr_index + 1], (size_t)window * sizeof(nums[0]));
			memmove(&pos_to_index[curr_index], &pos_to_index[curr_index + 1], (size_t)window * sizeof(pos_to_index[0]));
			nums[dest_index] = current_num;
			pos_to_index[dest_index] = temp_pos;
		}

		for (int i = 0; i < count; i++) {
			int index = pos_to_index[i];
			index_to_pos[index] = i;
		}
	}
	// print_nums();

	int zero_pos = 0;
	for (; zero_pos < count; zero_pos++)
		if (nums[zero_pos] == 0)
			break;

	int p0 = (zero_pos + 1000) % count;
	int p1 = (zero_pos + 2000) % count;
	int p2 = (zero_pos + 3000) % count;
	println("Sum of: {} {} {}", nums[p0], nums[p1], nums[p2]);

	println("Solution2: {}", nums[p0] + nums[p1] + nums[p2]);
}
