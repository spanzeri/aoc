#ifndef INCLUDED_COMMON_H
#define INCLUDED_COMMON_H

#include <string_view>
#include <string>
#include <format>
#include <iterator>
#include <iostream>
#include <exception>
#include <sstream>

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

std::string_view parse_value(std::string_view in, auto& out_val)
{
	auto [ptr, ec] = std::from_chars(in.data(), in.data() + in.size(), out_val);
	if (ec != std::errc())
		return in;

	return std::string_view{ptr, in.size() - (ptr - in.data())};
}

#endif // INCLUDED_COMMON_H
