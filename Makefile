BUILD_DIR = build
BIN_DIR 	= bin
SRC_DIR 	= src

TEST_PATH		= test_sha256

DEBUG_FLAGS = -g
BASE_FLAGS 	= -felf64 -w+all

test:
	mkdir -p $(BUILD_DIR) $(BIN_DIR)
	nasm -o $(BUILD_DIR)/$(TEST_PATH).o $(TEST_PATH).s \
		$(INCLUDE_FLAGS) $(DEBUG_FLAGS) $(BASE_FLAGS)
	ld -o $(BIN_DIR)/$(TEST_PATH) $(BUILD_DIR)/$(TEST_PATH).o
	./$(BIN_DIR)/$(TEST_PATH)

.PHONY: clean
clean:
	rm -rf $(BUILD_DIR) $(BIN_DIR)
