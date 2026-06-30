BUILD_DIR = build
BIN_DIR = bin
SRC_DIR = src

SHA256_PATH = sha256

DEBUG_FLAGS = -g
BASE_FLAGS = -felf64 -w+all

all:
	mkdir -p $(BUILD_DIR) $(BIN_DIR)
	nasm -o $(BUILD_DIR)/$(SHA256_PATH).o $(SHA256_PATH).s \
		$(INCLUDE_FLAGS) $(DEBUG_FLAGS) $(BASE_FLAGS)
	ld -o $(BIN_DIR)/$(SHA256_PATH) $(BUILD_DIR)/$(SHA256_PATH).o

run:
	mkdir -p $(BUILD_DIR) $(BIN_DIR)
	nasm -o $(BUILD_DIR)/$(SHA256_PATH).o $(SHA256_PATH).s \
		$(INCLUDE_FLAGS) $(DEBUG_FLAGS) $(BASE_FLAGS)
	ld -o $(BIN_DIR)/$(SHA256_PATH) $(BUILD_DIR)/$(SHA256_PATH).o
	./$(BIN_DIR)/$(SHA256_PATH)

.PHONY: clean
clean:
	rm -rf $(BUILD_DIR) $(BIN_DIR)
