# Variables
ERL := erl
ERLC := erlc
SRC_DIR := .
EBIN_DIR := ebin
TEST_DIR := tests

# Targets
all: compile

compile:
	@mkdir -p $(EBIN_DIR)
	$(ERLC) -o $(EBIN_DIR) $(SRC_DIR)/dz5.erl
	$(ERLC) -o $(EBIN_DIR) $(SRC_DIR)/h_test.erl
	$(ERLC) -o $(EBIN_DIR) $(SRC_DIR)/test.erl

test: compile
	$(ERL) -pa $(EBIN_DIR) -noshell -eval "eunit:test(h_test, [verbose])" -s init stop

clean:
	rm -rf $(EBIN_DIR)/*.beam

.PHONY: all compile test clean