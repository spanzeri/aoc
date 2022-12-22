#include "common.h"

#include <iostream>
#include <fstream>
#include <cassert>
#include <vector>
#include <array>
#include <unordered_set>
#include <unordered_map>

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

struct MonkeyMath {
	enum Op {
		Add,
		Mul,
		Sub,
		Div
	} op;
	std::string lhs;
	std::string rhs;
};

struct Monkey
{
	enum Job {
		Yell,
		Math
	} job;
	union
	{
		int64_t value;
		int64_t index;
	};
};

std::string_view parse_name(std::string_view src, std::string& dest)
{
	src = trim(src);
	auto b = begin(src);
	auto e = b;
	while (e != end(src) && *e >= 'a' && *e <= 'z')
		++e;
	dest = std::string(b, e);
	return {e, end(src)};
}

std::string parse_monkey(std::string_view src, Monkey& monkey, std::vector<MonkeyMath>& math_ops)
{
	std::string name;
	src = parse_name(src, name);
	assert(src.starts_with(": "));
	src = {begin(src) + 2, end(src)};
	assert(!src.empty());
	if (src[0] >= 'a' && src[0] <= 'z') {
		MonkeyMath math;
		src = parse_name(src, math.lhs);
		if (src.starts_with(" + "))
			math.op = MonkeyMath::Add;
		else if (src.starts_with(" * "))
			math.op = MonkeyMath::Mul;
		else if (src.starts_with(" - "))
			math.op = MonkeyMath::Sub;
		else if (src.starts_with(" / "))
			math.op = MonkeyMath::Div;
		else
			unreacheable();
		src = {begin(src) + 3, end(src)};
		parse_name(src, math.rhs);
		monkey.job = Monkey::Math;
		monkey.index = (int)math_ops.size();
		math_ops.push_back(std::move(math));
	}
	else {
		monkey.job = Monkey::Yell;
		parse_value(src, monkey.value);
	}
	return name;
}

int64_t solve_monkey(std::string_view name, std::unordered_map<std::string, Monkey>& monkeys, std::vector<MonkeyMath>& math_ops)
{
	auto &monkey = monkeys[std::string(name)];
	if (monkey.job == Monkey::Yell)
		return monkey.value;

	auto &math = math_ops[monkey.index];
	int64_t lhs = solve_monkey(math.lhs, monkeys, math_ops);
	int64_t rhs = solve_monkey(math.rhs, monkeys, math_ops);

	int64_t res = 0;
	switch (math.op) {
	case MonkeyMath::Add: res = lhs + rhs; break;
	case MonkeyMath::Mul: res = lhs * rhs; break;
	case MonkeyMath::Sub: res = lhs - rhs; break;
	case MonkeyMath::Div: res = lhs / rhs; break;
	}

	// Caching
	monkey.job = Monkey::Yell;
	monkey.value = res;

	return res;
}

void solution1()
{
	std::string_view filename{"input/day21.txt"};
	std::ifstream input{filename.data(), std::ifstream::in};
	if (!input.is_open())
		fatal_error("Missing file: {}", filename);

	std::string line;
	std::vector<MonkeyMath> math_ops;
	std::unordered_map<std::string, Monkey> monkeys;

	while (input) {
		std::getline(input, line);
		if (line.empty())
			continue;

		Monkey monkey;
		std::string name = parse_monkey(line, monkey, math_ops);
		monkeys[name] = monkey;
	}

	println("Solution1: {}", solve_monkey("root", monkeys, math_ops));
}

struct Variable
{
	MonkeyMath::Op op;
	bool lhs_variable = false;
	int64_t constant = 0;
};

bool solve2_eq(
	std::string_view name, std::unordered_map<std::string, Monkey>& monkeys, std::vector<MonkeyMath>& math_ops,
	std::vector<Variable>& variables, int64_t& result)
{
	if (name == "humn")
		return false;

	auto &monkey = monkeys[std::string(name)];
	if (monkey.job == Monkey::Yell) {
		result = monkey.value;
		return true;
	}

	auto &math = math_ops[monkey.index];

	int64_t lhs, rhs;
	bool solved_lhs = solve2_eq(math.lhs, monkeys, math_ops, variables, lhs);
	bool solved_rhs = solve2_eq(math.rhs, monkeys, math_ops, variables, rhs);

	if (solved_lhs && solved_rhs) {
		switch (math.op) {
		case MonkeyMath::Add: result = lhs + rhs; break;
		case MonkeyMath::Mul: result = lhs * rhs; break;
		case MonkeyMath::Sub: result = lhs - rhs; break;
		case MonkeyMath::Div: result = lhs / rhs; break;
		}

		// Caching
		monkey.job = Monkey::Yell;
		monkey.value = result;

		return true;
	}

	if (!solved_lhs) {
		Variable var;
		var.op = math.op;
		var.lhs_variable = true;
		var.constant = rhs;
		variables.push_back(var);
	}
	else {
		Variable var;
		var.op = math.op;
		var.lhs_variable = false;
		var.constant = lhs;
		variables.push_back(var);
	}

	return false;
}

int64_t solve2(std::string_view name, std::unordered_map<std::string, Monkey>& monkeys, std::vector<MonkeyMath>& math_ops)
{
	auto &root_monkey = monkeys[std::string(name)];
	auto &eq = math_ops[root_monkey.index];

	// Try and solve backward (with variable)
	std::vector<Variable> variables;
	int64_t lhs, rhs;
	bool humn_left  = !solve2_eq(eq.lhs, monkeys, math_ops, variables, lhs);
	bool humn_right = !solve2_eq(eq.rhs, monkeys, math_ops, variables, rhs);
	assert(humn_left != humn_right);
	(void)humn_right;

	int64_t matchv = humn_left ? rhs : lhs;

	// Solve variable forward
	for (int i = (int)variables.size() - 1; i >= 0; --i) {
		const auto &var = variables[i];
		switch(var.op)
		{
		case MonkeyMath::Add: {
			matchv = matchv - var.constant;
			break;
		}

		case MonkeyMath::Sub: {
			if (var.lhs_variable)
				matchv = matchv + var.constant;
			else
				matchv = var.constant - matchv;
			break;
		}

		case MonkeyMath::Mul: {
			matchv = matchv / var.constant;
			break;
		}

		case MonkeyMath::Div: {
			matchv = matchv * var.constant;
			break;
		}
		}
	}

	return matchv;
}

void solution2()
{
	std::string_view filename{"input/day21.txt"};
	std::ifstream input{filename.data(), std::ifstream::in};
	if (!input.is_open())
		fatal_error("Missing file: {}", filename);

	std::string line;
	std::vector<MonkeyMath> math_ops;
	std::unordered_map<std::string, Monkey> monkeys;

	while (input) {
		std::getline(input, line);
		if (line.empty())
			continue;

		Monkey monkey;
		std::string name = parse_monkey(line, monkey, math_ops);
		monkeys[name] = monkey;
	}

	println("Solution2: {}", solve2("root", monkeys, math_ops));
}
