/** WARNING: this is generated code **/

static const Rtti_Enum_Value MyEnum_values[] = {
    Rtti_Enum_Value{
        .name = S8_LIT("MY_ENUM_ABC"),
        .value = 4
    },
    Rtti_Enum_Value{
        .name = S8_LIT("MY_ENUM_DEF"),
        .value = 5
    },
};

static const Rtti_Enum_Value MyCxxEnum_values[] = {
    Rtti_Enum_Value{
        .name = S8_LIT("Abc"),
        .value = 2
    },
    Rtti_Enum_Value{
        .name = S8_LIT("Def"),
        .value = 3
    },
};

static const Rtti_Enum_Type rtti_enum_table_data[] = {
    Rtti_Enum_Type{
        .name = S8_LIT("MyEnum"),
        .values = Rtti_Enum_Value_Array{
            .data = MyEnum_values,
            .len = sizeof(MyEnum_values) / sizeof(*MyEnum_values)
        }
    },
    Rtti_Enum_Type{
        .name = S8_LIT("MyCxxEnum"),
        .values = Rtti_Enum_Value_Array{
            .data = MyCxxEnum_values,
            .len = sizeof(MyCxxEnum_values) / sizeof(*MyCxxEnum_values)
        }
    },
};

static const Rtti_Enum_Type_Array rtti_enum_table = {
    .data = rtti_enum_table_data,
    .len = sizeof(rtti_enum_table_data) / sizeof(*rtti_enum_table_data)
};
