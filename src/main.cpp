
int main(int argc, char** argv) {
    Vec2 v1 = {
        .x = 42,
        .y = 73
    };
    Vec2 v2 = {
        .x = 1,
        .y = 3
    };
    foobar(v1 + v2);

    if(argc >= 3) {
        printf("lookup up enum\n");
        int64_t value;
        String8 n = S8_CSTR(argv[1]);
        String8 v = S8_CSTR(argv[2]);
        if(!rtti_lookup_enum_value(n, v, &value)) {
            printf("enum: %s %s DNE\n", n.data, v.data);
        } else {
            printf("enum: %s %s = %lld\n", n.data, v.data, value);
        }
    }

    return 0;
}
