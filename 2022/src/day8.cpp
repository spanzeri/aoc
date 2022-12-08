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

using row_t = std::vector<uint8_t>;
using grid_t = std::vector<row_t>;

grid_t make_grid(size_t row_count, size_t col_count)
{
	return {row_count, row_t(col_count, 0)};
}

void solution1()
{
	std::string_view filename{"input/day8.txt"};
	std::ifstream input{filename.data(), std::ifstream::in};
	if (!input.is_open())
		fatal_error("Missing file: {}", filename);

	std::string line;

	grid_t grid;

	while (input)
	{
		std::getline(input, line);
		if (line == "")
			continue;

		row_t row(line.size());
		for (size_t i = 0; i < line.size(); i++)
			row[i] = static_cast<uint8_t>(line[i] - '0');
		grid.push_back(row);
	}

	struct local_max {
		uint8_t left = 0;
		uint8_t right = 0;
		uint8_t top = 0;
		uint8_t bottom = 0;
	};

	size_t rows = grid.size();
	size_t cols = grid[0].size();
	std::vector<std::vector<local_max>> maxes{rows, std::vector<local_max>(cols, local_max{})};

	size_t row_last = rows - 1;
	size_t col_last = cols - 1;

	for (size_t r = 0; r < rows; r++)
	{
		for (size_t c = 0; c < cols; c++)
		{
			// Top and left
			{
				uint8_t lmax = c > 0 ? grid[r][c - 1] : 0;
				lmax = c > 1 ? std::max(lmax, maxes[r][c - 1].left) : lmax;
				maxes[r][c].left = lmax;

				uint8_t tmax = r > 0 ? grid[r - 1][c] : 0;
				tmax = r > 1 ? std::max(tmax, maxes[r - 1][c].top) : tmax;
				maxes[r][c].top = tmax;
			}

			// Bottom and right
			{
				size_t rr = rows - r - 1;
				size_t rc = cols - c - 1;

				uint8_t rmax = rc < col_last ? grid[rr][rc + 1] : 0;
				rmax = rc < col_last - 1 ? std::max(rmax, maxes[rr][rc + 1].right) : rmax;
				maxes[rr][rc].right = rmax;

				uint8_t bmax = rr < row_last ? grid[rr + 1][rc] : 0;
				bmax = rr < row_last - 1 ? std::max(bmax, maxes[rr + 1][rc].bottom) : bmax;
				maxes[rr][rc].bottom = bmax;
			}
		}
	}

	int count = (int)((rows + cols) * 2) - 4;
	for (size_t r = 1; r < row_last; r++) {
		for (size_t c = 1; c < col_last; c++) {
			auto current = grid[r][c];
			auto nmax = maxes[r][c];
			if (current > nmax.left || current > nmax.right || current > nmax.top || current > nmax.bottom) {
				count++;
			}
		}
		println("");
	}

	println("Solution1: {}", count);
}

void solution2()
{
	std::string_view filename{"input/day8.txt"};
	std::ifstream input{filename.data(), std::ifstream::in};
	if (!input.is_open())
		fatal_error("Missing file: {}", filename);

	std::string line;
	grid_t grid;

	while (input)
	{
		std::getline(input, line);
		if (line == "")
			continue;

		row_t row(line.size());
		for (size_t i = 0; i < line.size(); i++)
			row[i] = static_cast<uint8_t>(line[i] - '0');
		grid.push_back(row);
	}

	int rows = (int)grid.size();
	int cols = (int)grid[0].size();

	// #NOTE: can be solved caching previous solution like the one above, but I
	// run out of time today
	int max_score = 0;
	for (int r = 0; r < rows; r++) {
		for (int c = 0; c < cols; c++) {
			int height = grid[r][c];

			int l = 0;
			for (int cc = c - 1; cc >= 0; cc--) {
				l++;
				if (height <= grid[r][cc])
					break;
			}

			int t = 0;
			for (int rr = r - 1; rr >= 0; rr--) {
				t++;
				if (height <= grid[rr][c])
					break;
			}

			int rs = 0;
			for (int cc = c + 1; cc < cols; cc++) {
				rs++;
				if (height <= grid[r][cc])
					break;
			}

			int b = 0;
			for (int rr = r + 1; rr < rows; rr++) {
				b++;
				if (height <= grid[rr][c])
					break;
			}

			max_score = std::max(max_score, l * t * rs * b);
		}
	}

	println("Solution2: {}", max_score);
}
