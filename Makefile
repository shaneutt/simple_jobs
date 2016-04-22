REBAR := `pwd`/rebar3

all: test

test:
	@$(REBAR) do dialyzer, eunit -v

shell:
	@$(REBAR) do dialyzer, eunit, shell

.PHONY: all test shell
