#ifndef INCLUDED_COMMON_H
#define INCLUDED_COMMON_H

#include <string_view>
#include <string>
#include <format>
#include <iterator>
#include <iostream>
#include <exception>
#include <sstream>
#include <type_traits>
#include <chrono>

// Written for simplicity, not performance.

namespace details {

template <typename ...Args>
void print_impl(std::ostream& stream, std::string_view fmt, Args&&... args)
{
	std::string buffer;
	std::vformat_to(std::back_inserter(buffer), fmt, std::make_format_args(args...));
	stream << buffer;
}

template <typename ...Args>
void println_impl(std::ostream& stream, std::string_view fmt, Args&&... args)
{
	std::string buffer;
	std::vformat_to(std::back_inserter(buffer), fmt, std::make_format_args(args...));;
	stream << buffer << std::endl;
}

} // end namespace details

template <typename ...Args>
void print(std::string_view fmt, Args&&... args)
{
	details::print_impl(std::cout, fmt, std::forward<Args>(args)...);
}

template <typename ...Args>
void println(std::string_view fmt, Args&&... args)
{
	details::println_impl(std::cout, fmt, std::forward<Args>(args)...);
}

template <typename ...Args>
void fatal_error(std::string_view fmt, Args&&... args)
{
	details::println_impl(std::cerr, fmt, std::forward<Args>(args)...);
	std::terminate();
}

template <typename T, std::size_t N>
T* begin(T (&arr)[N])
{
	return &arr[0];
}

template <typename T, std::size_t N>
T* end(T (&arr)[N])
{
	return &arr[N - 1] + 1;
}

#if defined(__GNUC__) || defined(__clang__)
	#define FORCEINLINE inline __attribute__((always_inline))
#elif defined(_MSC_VER)
	#define FORCEINLINE __forceinline
#else
	#define FORCEINLINE inline
#endif

[[noreturn]] FORCEINLINE void unreacheable()
{
#if defined(__GNUC__) || defined(__clang__)
	__builtin_unreachable();
#elif defined(_MSC_VER)
	__assume(0);
#else
	assert(0);
#endif
}

constexpr std::string_view parse_value(std::string_view in, auto& out_val)
{
	auto [ptr, ec] = std::from_chars(in.data(), in.data() + in.size(), out_val);
	if (ec != std::errc())
		return in;

	return std::string_view{ptr, in.size() - (ptr - in.data())};
}

constexpr std::string_view trim_left(std::string_view in)
{
	if (in.empty())
		return in;

	auto it = begin(in);
	while (*it == ' ')
		++it;
	return {it, end(in)};
}

constexpr std::string_view trim_right(std::string_view in)
{
	if (in.empty())
		return in;

	auto it = end(in) - 1;
	while (*it == ' ')
		--it;
	return {begin(in), it + 1};
}

constexpr std::string_view trim(std::string_view in)
{
	return trim_left(trim_right(in));
}

struct vec2i {
	int x = 0;
	int y = 0;

	friend constexpr auto operator+(vec2i a, vec2i b) -> vec2i {
		return { a.x + b.x, a.y + b.y };
	}

	friend constexpr auto operator-(vec2i a, vec2i b) -> vec2i {
		return { a.x - b.x, a.y - b.y };
	}

	friend constexpr auto operator+=(vec2i &a, vec2i b) { a = a + b; }
	friend constexpr auto operator-=(vec2i &a, vec2i b) { a = a - b; }

	friend constexpr auto operator==(vec2i a, vec2i b) -> bool { return a.x == b.x && a.y == b.y; }
	friend constexpr auto operator!=(vec2i a, vec2i b) -> bool { return !(a == b); }

	friend constexpr auto min(vec2i a, vec2i b) -> vec2i {
		return {std::min(a.x, b.x), std::min(a.y, b.y)};
	}

	friend constexpr auto max(vec2i a, vec2i b) -> vec2i {
		return {std::max(a.x, b.x), std::max(a.y, b.y)};
	}
};

inline int manhattan_distance(vec2i lhs, vec2i rhs)
{
	vec2i diff = rhs - lhs;
	return std::abs(diff.x) + std::abs(diff.y);
}

struct vec3i {
	int x = 0;
	int y = 0;
	int z = 0;

	friend constexpr auto operator+(vec3i a, vec3i b) -> vec3i {
		return { a.x + b.x, a.y + b.y, a.z + b.z };
	}

	friend constexpr auto operator-(vec3i a, vec3i b) -> vec3i {
		return { a.x - b.x, a.y - b.y, a.z - b.z };
	}

	friend constexpr auto operator+=(vec3i &a, vec3i b) { a = a + b; }
	friend constexpr auto operator-=(vec3i &a, vec3i b) { a = a - b; }

	friend constexpr auto operator==(vec3i a, vec3i b) -> bool { return a.x == b.x && a.y == b.y && a.z == b.z; }
	friend constexpr auto operator!=(vec3i a, vec3i b) -> bool { return !(a == b); }

	friend constexpr auto min(vec3i a, vec3i b) -> vec3i {
		return {std::min(a.x, b.x), std::min(a.y, b.y), std::min(a.z, b.z)};
	}

	friend constexpr auto max(vec3i a, vec3i b) -> vec3i {
		return {std::max(a.x, b.x), std::max(a.y, b.y), std::max(a.z, b.z)};
	}
};

inline int manhattan_distance(vec3i lhs, vec3i rhs)
{
	vec3i diff = rhs - lhs;
	return std::abs(diff.x) + std::abs(diff.y) + std::abs(diff.z);
}
namespace std {

template <>
struct hash<vec2i>
{
	std::size_t operator()(vec2i v) const {
		return hash<int64_t>()(v.x + (static_cast<int64_t>(v.y) << 32));
	}
};

template <>
struct hash<vec3i>
{
	std::size_t operator()(vec3i v) const {
		return hash<int>()(v.x) ^ hash<int>()(v.y) ^ hash<int>()(v.z);
	}
};

} // end namespace std

template <std::signed_integral T>
constexpr auto sign(T i) {
	if (i == 0)
		return 0;
	return i > 0 ? static_cast<T>(1) : static_cast<T>(-1);
}

struct SimpleTimer
{
	explicit SimpleTimer(std::string_view name)
		: name{name}
	{
		start = std::chrono::steady_clock::now();
	}

	~SimpleTimer()
	{
		auto end = std::chrono::steady_clock::now();
		println(" Time [{}] = {}ms", name, std::chrono::duration_cast<std::chrono::milliseconds>(end - start).count());
	}

	std::chrono::time_point<std::chrono::steady_clock> start;
	std::string name;
};

#endif // INCLUDED_COMMON_H
