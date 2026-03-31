struct Rtti_Enum_Value {
  String8 name;
  int64_t value;
};

struct Rtti_Enum_Value_Array {
  const Rtti_Enum_Value *data;
  size_t len;
};

struct Rtti_Enum_Type {
  String8 name;
  Rtti_Enum_Value_Array values;
};

struct Rtti_Enum_Type_Array {
  const Rtti_Enum_Type *data;
  size_t len;
};

