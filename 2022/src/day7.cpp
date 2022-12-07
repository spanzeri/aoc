#include "common.h"

#include <iostream>
#include <fstream>
#include <cassert>
#include <vector>
#include <string>

void solution1();
void solution2();

int main()
{
	solution1();
	solution2();
}

struct File
{
	std::string name;
	long long size;
};

struct Directory
{
	std::string name;
	std::size_t parent_index = 0;
	std::vector<std::size_t> subdir_indices;
	std::vector<File> files;
	long long size = 0;
};

struct FS
{
	std::vector<Directory> dirs;
	size_t current_dir = ~(size_t)0;
};

void set_cwd_and_add_if_missing(FS& fs, std::string_view dir)
{
	if (fs.dirs.empty()) {
		if (dir != "/")
			fatal_error("No directories yet. Should have added root");
		fs.dirs.emplace_back(std::string{dir}, 0);
		fs.current_dir = 0;
		return;
	}

	assert(fs.current_dir < fs.dirs.size());
	auto &cwd = fs.dirs[fs.current_dir];

	if (dir == "..") {
		fs.current_dir = cwd.parent_index;
		return;
	}

	for (auto &subidx : cwd.subdir_indices) {
		if (fs.dirs[subidx].name == dir) {
			fs.current_dir = subidx;
			return;
		}
	}

	fatal_error("Tried to cd into an unknown directory: {}", dir);
}

void parse(std::ifstream& input, FS& fs)
{
	std::string line;
	bool parsing_ls = false;
	while (input)
	{
		std::getline(input, line);
		if (line == "")
			continue;

		if (line.starts_with('$'))
		{
			parsing_ls = false;
			std::string_view cmd{line.data() + 2, 2};
			if (cmd == "cd") {
				std::string_view arg{line.data() + 5, line.size() - 5};
				set_cwd_and_add_if_missing(fs, arg);
			}
			else if (cmd == "ls") {
				parsing_ls = true;
			}
			else {
				fatal_error("Invalid command: \"{}\"", cmd);
			}
		}
		else {
			if (!parsing_ls)
				fatal_error("Unexpected line, not a command: {}", line);

			auto &cwd = fs.dirs[fs.current_dir];

			if (line.starts_with("dir")) {
				std::string_view dirname = {begin(line) + 4, end(line)};
				auto found_el = std::find_if(begin(cwd.subdir_indices), end(cwd.subdir_indices),
				                             [&](std::size_t idx) { return (fs.dirs[idx].name == dirname); });
				if (found_el == end(cwd.subdir_indices)) {
					fs.dirs.emplace_back(std::string{dirname}, fs.current_dir);
					size_t new_index = fs.dirs.size() - 1;
					fs.dirs[fs.current_dir].subdir_indices.push_back(new_index);
				}
			}
			else {
				if (line.empty() || !std::isdigit(line[0]))
					fatal_error("Unexpected input line: {}", line);
				long long filesize = 0;
				std::string_view name = parse_value(line, filesize);
				name = {begin(name) + 1, end(name)};

				auto it =
				    std::find_if(begin(cwd.files), end(cwd.files), [&](const File &file) { return file.name == name; });
				if (it == end(cwd.files))
					cwd.files.emplace_back(std::string{name}, filesize);
			}
		}
	}
}

long long compute_size_recurse(FS& fs, size_t dir_index)
{
	long long sum = 0;
	auto &dir = fs.dirs[dir_index];
	for (auto& file : dir.files)
		sum += file.size;
	for (auto& subdir_index : dir.subdir_indices)
		sum += compute_size_recurse(fs, subdir_index);
	dir.size = sum;
	return dir.size;
}

void compute_dir_sizes(FS& fs)
{
	compute_size_recurse(fs, 0);
}

void print_dir_content(const FS& fs, size_t dir_index, size_t indent_amount)
{
	const auto &dir = fs.dirs[dir_index];
	std::string indent(indent_amount, ' ');

	for (auto& file : dir.files) {
		println("{}* {}: {}", indent, file.name, file.size);
	}
	for (auto subdir_idx : dir.subdir_indices) {
		println("{}- {}: {}", indent, fs.dirs[subdir_idx].name, fs.dirs[subdir_idx].size);
		print_dir_content(fs, subdir_idx, indent_amount + 3);
	}
}

void print_fs(const FS& fs)
{
	print_dir_content(fs, 0, 0);
}

void solution1()
{
	std::string_view filename{"input/day7.txt"};
	std::ifstream input{filename.data(), std::ifstream::in};
	if (!input.is_open())
		fatal_error("Missing file: {}", filename);

	FS fs;
	parse(input, fs);
	compute_dir_sizes(fs);
	//print_fs(fs);

	constexpr long long max_size = 100000;

	long long sum = 0;
	for (auto& dir : fs.dirs) {
		if (dir.size <= max_size)
			sum += dir.size;
	}

	println("Solution1: {}", sum);
}

void solution2()
{
	std::string_view filename{"input/day7.txt"};
	std::ifstream input{filename.data(), std::ifstream::in};
	if (!input.is_open())
		fatal_error("Missing file: {}", filename);

	FS fs;
	parse(input, fs);
	compute_dir_sizes(fs);
	//print_fs(fs);

	constexpr long long total = 70000000;
	constexpr long long needed_for_update = 30000000;

	long long free = total - fs.dirs[0].size;
	long long needed = needed_for_update - free;

	long long min = std::numeric_limits<long long>::max();
	for (auto& dir : fs.dirs) {
		if (dir.size >= needed)
			min = std::min(min, dir.size);
	}

	println("Solution2: {}", min);
}
