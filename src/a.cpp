struct Vec2 {
    int x;
    int y;

    Vec2 operator+(Vec2 o) const {
        return Vec2{x + o.x, y + o.y};
    }
};

fn void foo() {
    printf("foo\n");
}
fn void bar() {
    printf("bar\n");
}
