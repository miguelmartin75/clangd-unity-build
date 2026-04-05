BUILD_DIR ?= build
SRC_DIR ?= src
TEST_DIR ?= tests
CONFIG ?= Debug

VERBOSE ?= 1
CXX ?= clang++
CXXSTD ?= -std=c++14
CXX_STD ?= $(CXXSTD)
PKG_CONFIG ?= pkg-config
CATCH2_PC ?= catch2-with-main
CODEGEN_SCRIPT ?= ./scripts/compile.py
CODEGEN ?= 0
COMPILE_COMMANDS ?= 0
ARGS ?=

ifeq ($(CONFIG),Debug)
	OPTFLAGS ?= -g
else ifeq ($(CONFIG),Release)
	OPTFLAGS ?= -O3
else ifeq ($(CONFIG),RelWithDebInfo)
	OPTFLAGS ?= -O3 -g
else
	$(error Unknown CONFIG $(CONFIG); expected Debug, Release, or RelWithDebInfo)
endif

ifeq ($(filter 1,$(CODEGEN) $(COMPILE_COMMANDS)),)
	CXX_CMD := $(CXX)
else
	CXX_CMD := $(CODEGEN_SCRIPT)
endif

COMMON_CXXFLAGS := $(strip $(CXXFLAGS) $(OPTFLAGS) $(CXX_STD))
EXE_CXXFLAGS := $(strip $(COMMON_CXXFLAGS) -I$(SRC_DIR))
TEST_CXXFLAGS := $(strip $(COMMON_CXXFLAGS) -I./ -I$(SRC_DIR) -DTESTS)
CATCH2_CFLAGS := $(shell $(PKG_CONFIG) --cflags $(CATCH2_PC) 2>/dev/null)
CATCH2_LIBS := $(shell $(PKG_CONFIG) --libs --static $(CATCH2_PC) 2>/dev/null)

ifeq ($(VERBOSE),0)
	Q := @
	LOG = @:
else
	Q :=
	LOG = @printf '%s\n'
endif

export BUILD_DIR SRC_DIR CXX CODEGEN COMPILE_COMMANDS

.PHONY: all main tests test-main run run-tests setup clean
all: main
main: $(BUILD_DIR)/main
tests: test-main
test-main: $(BUILD_DIR)/test_main

run: main
	$(LOG) "$(BUILD_DIR)/main $(ARGS)"
	$(Q)./$(BUILD_DIR)/main $(ARGS)

run-tests: test-main
	$(LOG) "$(BUILD_DIR)/test_main $(ARGS)"
	$(Q)./$(BUILD_DIR)/test_main $(ARGS)

setup:
	$(Q)uv sync

clean:
	$(Q)rm -rf $(BUILD_DIR)
	$(Q)rm -f compile_commands.json

$(BUILD_DIR):
	$(Q)mkdir -p $@

$(BUILD_DIR)/main: $(SRC_DIR)/compile_main.cpp | $(BUILD_DIR)
	$(LOG) ".. building main"
	$(Q)$(CXX_CMD) $(EXE_CXXFLAGS) $< -o $@

$(BUILD_DIR)/test_main: $(TEST_DIR)/compile_main.cpp | $(BUILD_DIR)
	$(LOG) ".. building test-main"
	$(Q)$(CXX_CMD) $(TEST_CXXFLAGS) $(CATCH2_CFLAGS) $< $(CATCH2_LIBS) -o $@
