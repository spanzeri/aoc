#include "common.h"

#include <iostream>
#include <fstream>
#include <cassert>
#include <vector>

void solution1();
void solution2();

int main()
{
	solution1();
	solution2();
}

struct Entry {
	enum Kind {
		List,
		Value
	};
	Kind kind = List;
	union {
		int value = 0;
		int index;
	};
};

Entry make_value(int val) {
	Entry res;
	res.kind = Entry::Value;
	res.value = val;
	return res;
}

Entry make_list(int index) {
	Entry res;
	res.kind = Entry::List;
	res.index = index;
	return res;
}

struct Packet {
	std::vector<std::vector<Entry>> lists;
};

char readc(std::string_view& src) {
	if (src.empty())
		return '\0';
	char c = src[0];
	src = {begin(src) + 1, end(src)};
	return c;
}

char peekc(std::string_view src) {
	return !src.empty() ? src[0] : '\0';
}

void parse_list(Packet &packet, std::string_view& src)
{
	char c = readc(src);
	assert(c == '[');

	int index = (int)packet.lists.size();
	packet.lists.emplace_back();

	bool closed = false;

	for (;;) {
		c = peekc(src);
		if (c >= '0' && c <= '9') {
			int val;
			src = parse_value(src, val);
			packet.lists[index].push_back(make_value(val));
			assert(!src.empty());
		}
		else if (c == '[') {
			packet.lists[index].push_back(make_list((int)packet.lists.size()));
			parse_list(packet, src);
		}
		else if (c == ']') {
			readc(src);
			closed = true;
			break;
		}

		if (peekc(src) == ',') {
			readc(src);
		}
		else {
			unreacheable();
		}
	}

	assert(closed);

	return;
}

void dbg_print_list(const Packet& packet, int list_index)
{
	print("[");
	auto &list = packet.lists[list_index];
	for (size_t i = 0; i < list.size(); i++)
	{
		auto &entry = list[i];
		if (entry.kind == Entry::Value)
			print("{}", entry.value);
		else
			dbg_print_list(packet, entry.index);
		if (i != list.size() - 1)
			print(",");
	}
	print("]");
}

void dbg_print_packet(const Packet& packet)
{
	dbg_print_list(packet, 0);
	println("");
}

Packet parse_packet(std::string_view src)
{
	assert(src[0] == '[');

	Packet packet;
	parse_list(packet, src);
	return packet;
}

int compare_list_value(const Packet& p, int pi, int val)
{
	const auto &list = p.lists[pi];
	if (list.empty())
		return 1;
	if (list[0].kind == Entry::Value) {
		int other_val = list[0].value;
		if (other_val < val)
			return 1;
		if (other_val > val)
			return -1;
		if (list.size() > 1)
			return -1;
		return 0;
	}

	return compare_list_value(p, list[0].index, val);
}

int compare_list(const Packet& lhs, int lhsi, const Packet& rhs, int rhsi)
{
	const auto &l1 = lhs.lists[lhsi];
	const auto &l2 = rhs.lists[rhsi];

	int end = std::min((int)l1.size(), (int)l2.size());
	for (int i = 0; i < end; i++) {
		if (l1[i].kind == Entry::Value && l2[i].kind == Entry::Value)
		{
			if (l1[i].value < l2[i].value)
				return 1;
			if (l1[i].value > l2[i].value)
				return -1;
		}
		else if (l1[i].kind == Entry::List && l2[i].kind == Entry::List)
		{
			int res = compare_list(lhs, l1[i].index, rhs, l2[i].index);
			if (res != 0)
				return res;
		}
		else
		{
			if (l1[i].kind == Entry::List) {
				int res = compare_list_value(lhs, l1[i].index, l2[i].value);
				if (res != 0)
					return res;
			}
			else
			{
				int res = compare_list_value(rhs, l2[i].index, l1[i].value);
				if (res != 0)
					return -res;
			}
		}
	}

	if (l1.size() < l2.size())
		return 1;
	else if (l1.size() > l2.size())
		return -1;
	return 0;
}

int compare(const Packet& lhs, const Packet& rhs)
{
	return compare_list(lhs, 0, rhs, 0);
}

void solution1()
{
	std::string_view filename{"input/day13.txt"};
	std::ifstream input{filename.data(), std::ifstream::in};
	if (!input.is_open())
		fatal_error("Missing file: {}", filename);

	int index = 0;
	int value = 0;
	while (input) {
		std::string s1, s2;
		std::getline(input, s1);
		if (s1 == "")
			continue;

		assert(input);
		std::getline(input, s2);
		assert(s2 != "");

		Packet p1 = parse_packet(s1);
		Packet p2 = parse_packet(s2);

		++index;

		if (compare(p1, p2) > 0)
			value += index;
	}

	println("Solution1: {}", value);
}

bool operator==(const Packet& a, const Packet& b)
{
	return compare(a, b) == 0;
}

bool operator<(const Packet& a, const Packet& b)
{
	return compare(a, b) > 0;
}

void solution2()
{
	std::string_view filename{"input/day13.txt"};
	std::ifstream input{filename.data(), std::ifstream::in};
	if (!input.is_open())
		fatal_error("Missing file: {}", filename);

	std::string line;
	std::vector<Packet> packets;

	Packet div1 = parse_packet("[[2]]");
	Packet div2 = parse_packet("[[6]]");

	packets.push_back(div1);
	packets.push_back(div2);

	while (input) {
		std::getline(input, line);
		if (line == "")
			continue;

		packets.push_back(parse_packet(line));
	}

	std::sort(begin(packets), end(packets));

	/*
	for (auto& p : packets)
		dbg_print_packet(p);
	*/

	int idx1 = 0;
	int idx2 = 0;
	for (int i = 0; i < packets.size(); ++i) {
		if (idx1 == 0 && packets[i] == div1)
			idx1 = i + 1;
		else if (idx2 == 0 && packets[i] == div2)
			idx2 = i + 1;

		if (idx1 != 0 && idx2 != 0)
			break;
	}

	println("Solution2: {}", idx1 * idx2);
}
