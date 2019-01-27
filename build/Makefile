MAKEDIR := $(dir $(firstword $(MAKEFILE_LIST)))

.DEFAULT_GOAL := help

.PHONY: master-template
master-template:
	$(MAKE) -f $(MAKEDIR)master.project/Makefile all
	@printf 'Successfully built master template.\n'

.PHONY: help
help:
	@printf 'Please specify one of the following:\n'
	@printf '\t%s\n' 'master-template'
