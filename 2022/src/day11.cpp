#include "common.h"

#include <iostream>
#include <fstream>
#include <cassert>
#include <vector>
#include <queue>

void solution1();
void solution2();

int main()
{
	solution1();
	solution2();
}

struct Test {
	int divisble_by = 0;
	int true_target_monkey = 0;
	int false_target_monkey = 0;
};

enum struct Operator : uint8_t {
	Plus,
	Times
};

// Not the most efficient way to store it, but good enough for this exercise
struct Op {
	Operator op;
	bool lhs_old = false;
	bool rhs_old = false;
	int lhs_value = 0;
	int rhs_value = 0;
};

struct Monkey {
	std::vector<int> starting_items;
	Op operation;
	Test test = {};
};

// Awful parser, but it does the job
bool parse_monkey(std::ifstream& input, Monkey& out_monkey)
{
	if (!input)
		return false;

	std::string line;
	std::getline(input, line);
	// Skip empty lines
	while (input && line == "")
		std::getline(input, line);
	if (!input)
		return false;

	// Parse header
	if (!line.starts_with("Monkey "))
		return false;

	// We are now parsing a monkey, for the sake of error checking just assert
	// if we find a string that does not match the expectations
	constexpr std::string_view start_items_prefix = "Starting items: ";

	// Starting items
	std::getline(input, line);
	std::string_view item_list = trim(std::string_view{begin(line), end(line)});
	assert(input && item_list.starts_with(start_items_prefix));
	item_list = {begin(item_list) + start_items_prefix.size(), end(item_list)};

	for (;;) {
		int item;
		item_list = parse_value(item_list, item);
		assert(item != 0);
		out_monkey.starting_items.emplace_back(item);
		if (item_list.empty())
			break;

		assert(item_list.starts_with(", "));
		item_list = {begin(item_list) + 2, end(item_list)};
	}

	// Operation
	assert(input);
	std::getline(input, line);
	std::string_view op_string = trim({begin(line), end(line)});
	constexpr std::string_view op_prefix = "Operation: new = ";
	constexpr std::string_view old_str = "old";
	assert(op_string.starts_with(op_prefix));
	op_string = {begin(op_string) + op_prefix.size(), end(op_string)};
	{
		if (op_string.starts_with(old_str)) {
			out_monkey.operation.lhs_old = true;
			op_string = {begin(op_string) + old_str.size(), end(op_string)};
		}
		else
			op_string = parse_value(op_string, out_monkey.operation.lhs_value);

		if (op_string.starts_with(" + "))
			out_monkey.operation.op = Operator::Plus;
		else if (op_string.starts_with(" * "))
			out_monkey.operation.op = Operator::Times;
		else
			unreacheable();
		op_string = {begin(op_string) + 3, end(op_string)};

		if (op_string.starts_with(old_str)) {
			out_monkey.operation.rhs_old = true;
			op_string = {begin(op_string) + old_str.size(), end(op_string)};
		}
		else
			op_string = parse_value(op_string, out_monkey.operation.rhs_value);
	}

	// Test condition
	assert(input);
	std::getline(input, line);
	std::string_view test_string = trim({begin(line), end(line)});
	constexpr std::string_view test_prefix = "Test: divisible by ";
	assert(test_prefix.starts_with(test_prefix));
	test_string = {begin(test_string) + test_prefix.size(), end(test_string)};
	parse_value(test_string, out_monkey.test.divisble_by);

	// True clause
	assert(input);
	std::getline(input, line);
	std::string_view true_string = trim({begin(line), end(line)});
	constexpr std::string_view true_prefix = "If true: throw to monkey ";
	assert(true_string.starts_with(true_prefix));
	true_string = {begin(true_string) + true_prefix.size(), end(true_string)};
	parse_value(true_string, out_monkey.test.true_target_monkey);

	// False clause
	assert(input);
	std::getline(input, line);
	std::string_view false_string = trim({begin(line), end(line)});
	constexpr std::string_view false_prefix = "If false: throw to monkey ";
	assert(false_string.starts_with(false_prefix));
	false_string = {begin(false_string) + false_prefix.size(), end(false_string)};
	parse_value(false_string, out_monkey.test.false_target_monkey);

	return true;
}

int execute_op(const Op& operation, int old_value)
{
	int lhs = operation.lhs_old ? old_value : operation.lhs_value;
	int rhs = operation.rhs_old ? old_value : operation.rhs_value;

	switch (operation.op) {
	case Operator::Plus: return lhs + rhs;
	case Operator::Times: return lhs * rhs;
	default: unreacheable();
	}
}

void solution1()
{
	std::string_view filename{"input/day11.txt"};
	std::ifstream input{filename.data(), std::ifstream::in};
	if (!input.is_open())
		fatal_error("Missing file: {}", filename);

	std::vector<Monkey> monkeys;
	for (;;) {
		Monkey m;
		if (!parse_monkey(input, m))
			break;
		monkeys.emplace_back(std::move(m));
		if (!input)
			break;
	}

	std::vector<int> inspected_items(monkeys.size(), 0);

	for (int round = 0; round < 20; round++) {
		for (size_t m = 0; m < monkeys.size(); ++m) {
			auto &monkey = monkeys[m];
			inspected_items[m] += static_cast<int>(monkey.starting_items.size());

			for (int item : monkey.starting_items) {
				auto worry = execute_op(monkey.operation, item);
				worry = worry / 3;
				int throw_monkey_index = (worry % monkey.test.divisble_by) == 0 ? monkey.test.true_target_monkey
				                                                                : monkey.test.false_target_monkey;
				monkeys[throw_monkey_index].starting_items.emplace_back(worry);
			}
			monkey.starting_items.resize(0);
		}
	}

	int max_inspected[2] = {0, 0};
	for (auto val : inspected_items) {
		if (val >= max_inspected[0]) {
			max_inspected[1] = max_inspected[0];
			max_inspected[0] = val;
		}
		else if (val > max_inspected[1])
			max_inspected[1] = val;
	}

	println("Solution1: {} * {} = {}", max_inspected[0], max_inspected[1], max_inspected[0] * max_inspected[1]);
}

void solution2()
{
	std::string_view filename{"input/day11.txt"};
	std::ifstream input{filename.data(), std::ifstream::in};
	if (!input.is_open())
		fatal_error("Missing file: {}", filename);

	std::vector<Monkey> monkeys;
	for (;;) {
		Monkey m;
		if (!parse_monkey(input, m))
			break;
		monkeys.emplace_back(std::move(m));
		if (!input)
			break;
	}

	std::vector<int> inspected_items(monkeys.size(), 0);

	size_t item_count = 0;
	std::vector<int> divisors(monkeys.size());
	for (size_t i = 0; i < monkeys.size(); i++)
	{
		item_count += monkeys[i].starting_items.size();
		divisors[i] = monkeys[i].test.divisble_by;
	}

	std::vector<std::vector<int>> modulii(item_count, std::vector<int>(monkeys.size(), 0));
	int index = 0;
	for (auto& monkey : monkeys) {
		for (int& item : monkey.starting_items) {
			for (size_t i = 0; i < divisors.size(); i++)
				modulii[index][i] = item % divisors[i];
			item = index;
			index++;
		}
	}

	auto execute_op_reduced = [&](int item_index, const Op &op) {
		for (size_t divi = 0; divi < divisors.size(); divi++) {
			modulii[item_index][divi] = execute_op(op, modulii[item_index][divi]);
			modulii[item_index][divi] = modulii[item_index][divi] % divisors[divi];
		}
	};

	for (int round = 0; round < 10000; round++)
	{
		for (size_t m = 0; m < monkeys.size(); ++m) {
			auto &monkey = monkeys[m];
			inspected_items[m] += static_cast<int>(monkey.starting_items.size());

			for (int item_index : monkey.starting_items) {
				execute_op_reduced(item_index, monkey.operation);
				int throw_monkey_index = (modulii[item_index][m] == 0) ? monkey.test.true_target_monkey
																	   : monkey.test.false_target_monkey;
				monkeys[throw_monkey_index].starting_items.emplace_back(item_index);
			}
			monkey.starting_items.resize(0);
		}

	#if 0
		if ((round + 1) == 1 || (round + 1) == 20 || ((round + 1) % 1000) == 0) {
			println("== After round: {} ==", round + 1);
			for (size_t i = 0; i < monkeys.size(); i++) {
				println("Monkey {} inspected items {} times.", i, inspected_items[i]);
			}
		}
	#endif
	}

	long long max_inspected[2] = {0, 0};
	for (auto val : inspected_items) {
		if (val >= max_inspected[0]) {
			max_inspected[1] = max_inspected[0];
			max_inspected[0] = val;
		}
		else if (val > max_inspected[1])
			max_inspected[1] = val;
	}

	println("Solution2: {} * {} = {}", max_inspected[0], max_inspected[1], max_inspected[0] * max_inspected[1]);
}
