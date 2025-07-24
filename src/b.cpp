struct Vec2 {
    int x;
    int y;

    Vec2 operator+(Vec2 o) const {
        return Vec2{x + o.x, y + o.y};
    }
};

fn void foobar(Vec2 v) {
    printf("calling foo & bar...\n");
    printf("v.x = %d, v.y = %d\n", v.x, v.y);
    foo();
    bar();
}
