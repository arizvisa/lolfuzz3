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

### GNU Makefile utilitiy functions
noop=
space=$(noop) $(noop)
comma=,
lc = $(subst A,a,$(subst B,b,$(subst C,c,$(subst D,d,$(subst E,e,$(subst F,f,$(subst G,g,$(subst H,h,$(subst I,i,$(subst J,j,$(subst K,k,$(subst L,l,$(subst M,m,$(subst N,n,$(subst O,o,$(subst P,p,$(subst Q,q,$(subst R,r,$(subst S,s,$(subst T,t,$(subst U,u,$(subst V,v,$(subst W,w,$(subst X,x,$(subst Y,y,$(subst Z,z,$1))))))))))))))))))))))))))
uc = $(subst a,A,$(subst b,B,$(subst c,C,$(subst d,D,$(subst e,E,$(subst f,F,$(subst g,G,$(subst h,H,$(subst i,I,$(subst j,J,$(subst k,K,$(subst l,L,$(subst m,M,$(subst n,N,$(subst o,O,$(subst p,P,$(subst q,Q,$(subst r,R,$(subst s,S,$(subst t,T,$(subst u,U,$(subst v,V,$(subst w,W,$(subst x,X,$(subst y,Y,$(subst z,Z,$1))))))))))))))))))))))))))

### Include various Makefile components containing configurations and macros
include $(MAKEDIR)Makefile.box
include $(MAKEDIR)Makefile.bento
include $(MAKEDIR)Makefile.boxcutter

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

## Auto-generated chef-bento recipes for the templates
$(foreach f,$(filter-out %-ppc64el.json,$(wildcard $(MAKEDIR)/chef-bento/*/*/*.json)),$(eval $(call build_bento,$(f))))

## Auto-generated boxcutter-windows recipes for both isos and the templates
$(foreach item,$(shell jq -r '[inputs] | map([([.variables.iso_checksum_type, .variables.iso_checksum] | join(":")), .variables.iso_url]) | unique_by(first) | map(join("$$")) | .[]' $(MAKEDIR)/boxcutter-windows/*.json),$(eval $(call download_with_checksum,$(firstword $(subst :, ,$(item))),$(lastword $(subst :, ,$(firstword $(subst $$, ,$(item))))),$(lastword $(subst $$, ,$(item))))))
$(foreach f,$(filter-out %-ssh.json,$(filter-out %-cygwin.json,$(wildcard $(MAKEDIR)/boxcutter-windows/*.json))),$(eval $(call build_boxcutter,$(f))))

## Recipes for boxcutter-windows templates
.PHONY: boxcutter
boxcutter: boxcutter/help

.PHONY: boxcutter/help
boxcutter/help:
	@printf 'Please specify one of the following recipes to build:\n\n'
	@printf '\tboxcutter/%s\n' $(foreach name,$(BOXCUTTER_TEMPLATES),'$(name)')

## Directory recipes for creating the output and work directories
$(outdir) $(workdir):
	@test -d '$@' || mkdir -p '$@'
