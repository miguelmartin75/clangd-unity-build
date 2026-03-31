enum MyEnum {
    MY_ENUM_ABC = 4,
    MY_ENUM_DEF
};

enum class MyCxxEnum {
    Abc = 2,
    Def
};

struct Vec2 {
    /** hello */
    int x;
    int y; /// abc

    Vec2 operator+(Vec2 o) const {
        return Vec2{x + o.x, y + o.y};
    }
};

// taken from cxb
#include <type_traits>

typedef float f32;
typedef double f64;
typedef int32_t i32;
typedef int64_t i64;
typedef uint8_t u8;
typedef uint16_t u16;
typedef uint32_t u32;
typedef uint64_t u64;
typedef int64_t ll;
typedef int32_t rune;

template <typename T>
static inline const T& min(const T& a, const T& b) {
    return a < b ? a : b;
}

template <typename T>
static inline const T& max(const T& a, const T& b) {
    return a > b ? a : b;
}

template <typename T>
const T& clamp(const T& x, const T& a, const T& b) {
    return a < b ? max(min(b, x), a) : min(max(a, x), b);
}

struct String8 {
    char* data;
    union {
        struct {
            size_t len : 63;
            bool not_null_term : 1;
        };
        size_t metadata;
    };

    inline size_t n_bytes() const {
        return len + !not_null_term;
    }
    inline size_t size() const {
        return len;
    }
    inline bool empty() const {
        return len == 0;
    }
    inline char& operator[](size_t idx) {
        return data[idx];
    }
    inline const char& operator[](size_t idx) const {
        return data[idx];
    }
    inline char& back() {
        return data[len - 1];
    }
    inline String8 slice(i64 i = 0, i64 j = -1) const {
        if(!data) {
            return {};
        }
        i64 ii = clamp(i < 0 ? (i64) len + i : i, (i64) 0, len == 0 ? 0 : (i64) len - 1);
        i64 jj = clamp(j < 0 ? (i64) len + j : j, (i64) 0, len == 0 ? 0 : (i64) len - 1);

        String8 c = *this;
        c.data = c.data + ii;
        c.len = max<i64>(0, jj - ii + 1);
        c.not_null_term = ii + c.len == len ? this->not_null_term : true;
        return c;
    }

    inline const char* c_str() const {
        return not_null_term ? nullptr : data;
    }

    inline int compare(const String8& o) const {
        int result = memcmp(data, o.data, len < o.len ? len : o.len);
        if(result == 0) {
            return len - o.len;
        }
        return result;
    }

    inline bool operator==(const String8& o) const {
        return compare(o) == 0;
    }

    inline bool operator!=(const String8& o) const {
        return !(*this == o);
    }

    inline bool operator<(const String8& o) const {
        size_t n = len < o.len ? len : o.len;
        int cmp = memcmp(data, o.data, n);
        if(cmp < 0) return true;
        if(cmp > 0) return false;
        return len < o.len;
    }

    inline bool operator>(const String8& o) const {
        return o < *this;
    }
};
#define COUNTOF_LIT(a) (size_t) (sizeof(a) / sizeof(*(a)))
#define LENGTHOF_LIT(s) (COUNTOF_LIT(s) - 1)
#define S8_LIT(s) (String8{.data = (char*) &(s)[0], .len = LENGTHOF_LIT(s), .not_null_term = false})
#define S8_DATA(c, l) (String8{.data = (char*) &(c)[0], .len = (l), .not_null_term = false})
#define S8_CSTR(s) (String8{.data = (char*) (s), .len = (size_t) strlen(s), .not_null_term = false})

template <class T>
struct Array {
    T* data;
    size_t len;
};

template <typename T, size_t N>
struct StaticArray {
    T data[N];
    size_t len = N;

    inline operator Array<T>() & {
        return Array<T>{data, len};
    }
    inline operator Array<T>() && = delete;
};


template <typename T>
inline void copy(T* dst, const T* src, size_t n) {
    if constexpr(std::is_trivially_assignable_v<T, T>) {
        memcpy(dst, src, n * sizeof(T));
    } else {
        for(size_t i = 0; i < n; ++i) {
            dst[i] = src[i];
        }
    }
}

template <typename T, size_t N>
StaticArray<T, N> make_static_array(const T (&xs)[N]) {
    StaticArray<T, N> sa{};
    ::copy(sa.data, xs, N);
    return sa;
}
