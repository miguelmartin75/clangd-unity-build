bool rtti_lookup_enum_value(String8 enum_name, String8 enum_value, Rtti_Enum_Value *value) {
    const Rtti_Enum_Type* type = {};
    for(size_t i = 0; i < rtti_enum_table.len; ++i) {
        if(rtti_enum_table.data[i].name == enum_name) {
            type = &rtti_enum_table.data[i];
            break;
        }
    }
    if(!type) {
        return false;
    }
    for(size_t i = 0; i < type->values.len; ++i) {
        if(type->values.data[i].name == enum_value) {
            if(value) {
                *value = type->values.data[i];
                return true;
            }
        }
    }

    return false;
}
