###############################################################################
# build (Makefile)
#
# This file contains the base recipes used to build templates in the user's
# project. This is accomplished by wrapping the build-systems for the different
# projects under this directory.
###############################################################################

MAKEDIR := $(dir $(firstword $(MAKEFILE_LIST)))
ROOTDIR := $(realpath $(MAKEDIR)..)

### Parameters that the user can supply
BUILDDIR?=$(ROOTDIR)/build.dir
OUTPUT?=$(ROOTDIR)/template

### Internal variables that are used for building
outdir := $(patsubst %/,%,$(OUTPUT))
workdir := $(BUILDDIR)

## Available platform types to build the template for
platform = $(subst $(comma),$(space),$(PLATFORM))

#ifneq ($(platform),)
#$(info [-] User has specified the following template type(s): $(platform))
#options := $(options) only='$(subst $(space),$(comma),$(foreach name,$(platform),$(name)-iso))'
#else
#$(warning User has specified no template types. Assuming all platforms are available.)
#$(info [-] To target a specific build platform, set the PLATFORM variable to one or more of the following: vmware, virtualbox, parallels, hyperv, qemu)
#endif

### Include various Makefile components containing configurations and macros
include $(MAKEDIR)Makefile.box
include $(MAKEDIR)Makefile.bento

### General recipes used during building
.DEFAULT_GOAL := help

.PHONY: help
help:
	@printf 'Please specify one of the following:\n'
	@printf '\t%s\n' 'master-template'
	@printf '\t%s\n' 'bento'
	@printf '\t%s\n' 'boxcutter'

## Recipes for building the master-template
.PHONY: master-template
master-template: master-template/help

.PHONY: master-template/help
master-template/help:
	$(MAKE) -f $(MAKEDIR)master.project/Makefile help

.PHONY: master-template/build
master-template/build:
	$(MAKE) -f $(MAKEDIR)master.project/Makefile all
	@printf 'Successfully built master template.\n'

## Recipes for chef-bento templates
.PHONY: bento
bento: bento/help

.PHONY: bento/help
bento/help:
	@printf 'Please specify one of the following recipes to build:\n\n'
	@printf '\tbento/%s\n' $(foreach name,$(BENTO_TEMPLATES),'$(name)')

$(foreach f,$(filter-out %-ppc64el.json,$(wildcard $(MAKEDIR)/chef-bento/*/*/*.json)),$(eval $(call build_bento,$(f))))

## Recipes for boxcutter-windows templates
.PHONY: boxcutter
boxcutter: boxcutter/help

.PHONY: boxcutter/help
boxcutter/help:
	$(error boxcutter is not implemented yet!)

## Directory recipes for creating the output and work directories
$(outdir) $(workdir):
	@test -d '$@' || mkdir -p '$@'
