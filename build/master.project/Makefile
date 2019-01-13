SHELL=/usr/bin/bash

MAKEDIR := $(dir $(firstword $(MAKEFILE_LIST)))
ROOTDIR := $(realpath $(MAKEDIR)../..)

ifndef PROJECT
    $(error Build variable name PROJECT is undefined)
endif
ifndef INPUT
    $(error Build variable path INPUT is undefined)
endif
ifndef OUTPUT
    $(error Build variable path OUTPUT is undefined.)
endif

### Check input directory with configuration for master
ifneq ("$(wildcard ${INPUT})","")
    # modifications to CoreOS bootstrap
    ifeq ("$(wildcard ${INPUT}/master-bootstrap/*)","")
        box_config_extra=
    else
        box_config_extra?=${INPUT}/master-bootstrap
    endif

   # packer template extra modifications
    ifeq ("$(wildcard ${INPUT}/master-packer/*)","")
        box_template_extra=
    else
        box_template_extra?=${INPUT}/master-packer
    endif

    $(info Project "${PROJECT}" using configuration in "$(abspath ${INPUT})".)
else
    $(error Specified path for variable INPUT does not exist. : $(abspath ${INPUT}))
endif

### user variables
boxname?=master.${PROJECT}
outdir?=${ROOTDIR}/template
workdir?=build.dir

tools=$(ROOTDIR)/build/bin/

boxname_out=$(outdir)/$(boxname)
boxname_work=$(workdir)/$(boxname)
boxname_template=$(workdir)/$(boxname)/template

boxname_config=$(boxname).yml

### Check output directory
outdir=${OUTPUT}
ifeq ("$(wildcard $(boxname_out))","")
    $(info Preparing to write "$(boxname)" to "$(abspath $(boxname_out))")
else
    $(warning Output path for image already exists. : $(abspath $(boxname_out)))
endif

### default configuration
checksum_type := md5

## coreos configuration
in_coreos=$(MAKEDIR)coreos.url
in_coreos_version=$(MAKEDIR)coreos.version
in_coreos_validate=$(MAKEDIR)coreos.validate.url
in_coreos_files=$(MAKEDIR)coreos.files

coreos_iso=coreos_production_iso_image.iso

## github stuff
in_github=$(MAKEDIR)github.url
in_acbuild_repo=$(MAKEDIR)acbuild.repo
in_setup_network_environment_repo=$(MAKEDIR)/setup-network-environment.repo
in_salt_bootstrap_metaurl=$(MAKEDIR)salt-bootstrap.url

## generate the install url from the environment vars
$(foreach var,$(file <$(in_coreos_version)),$(eval export $(var)))
coreos_url=$(file <$(in_coreos))
coreos_validate_url=$(file <$(in_coreos_validate))

## generate the acbuild url for each file
acbuild_metaurl=$(shell printf -- '$(file <$(in_github))' '$(file <$(in_acbuild_repo))')
setup_network_environment_metaurl=$(shell printf -- '$(file <$(in_github))' '$(file <$(in_setup_network_environment_repo))')
salt_bootstrap_metaurl='$(file <$(in_salt_bootstrap_metaurl))'

## some utility macros
DOWNLOAD := curl -L -k --progress-bar
FETCH := curl -L -k -s
PUT := curl -L -K -s -X PUT --data-binary

ifneq ("$(wildcard $(ROOTDIR)/github.token)","")
GH_FETCH := ${FETCH} -H 'Authorization: token $(file <$(ROOTDIR)/github.token)'
else
GH_FETCH := ${FETCH}
endif

## ignition variables
ignition_config=$(MAKEDIR)ignition/
ignition_units_names=$(foreach f,$(wildcard $(ignition_config)units/*),$(notdir $(f)))
ignition_dropins_names=$(foreach f,$(wildcard $(ignition_config)dropins/*),$(notdir $(f)))

### definitions for generating rules

## download rules from github

# gh_download '$filename'
define gh_download
$(1):
	@test -d '$$(dir $(1))' || mkdir -p '$$(dir $(1))'
	$$(info [!] Downloading $$(notdir $(1)) from $(2))
	$${DOWNLOAD} -o '$$@' '$(2)'
endef

## download rules for CoreOS components

# coreos_download '$filename'
define coreos_download
$$(workdir)/$$(notdir $(1)):
	@test -d '$$(workdir)' || mkdir -p '$$(workdir)'
	$$(info [!] Downloading CoreOS Installer $(coreos_url)/$(1))
	$${DOWNLOAD} -o '$$@' '$(coreos_url)/$(1)'
endef

## rules for copying tools into staging directory

# coreos_tool '$target' '$source'
define coreos_tool
$(2): $(1)
	@test -d '$$(dir $(2))' || mkdir -p '$$(dir $(2))'
	$$(info [!] Copying file from $(1) to $(2))
	cp -f '$(1)' '$(2)'
endef

## because fuck CoreOS for breaking cloud-init right before deprecating it

# ignition_file '$target.json' '$infile' '$decimal-mode'
define ignition_file
$(2): $(1)
	@test -d '$$(dir $(2))' || mkdir -p '$$(dir $(2))'
	$$(info [!] Building ignition file $(2) from contents at $(1))
	@jq -n --slurpfile contents <(jq -Rs . '$(1)') '{ path: "/etc/sysctl.d/$$(notdir $(1))", mode: $(3), contents: $$$$contents[0] }' >| '$(2)'
endef

# ignition_unit_file '$unit.service' '$source.service' '$output.json'
define ignition_unit_file
$(3): $(2)
	$$(info [!] Creating ignition unit file $(3) : $(2))
	@jq -n --slurpfile contents <(jq -Rs . '$(2)') '{ name: "$(1)", enabled: true, contents: $$$$contents[0], dropins: [] }' >| '$(3)'
endef

# ignition_unit_dropins '$target.json' '$space-separated-dropins'
define ignition_unit_dropins
$(1): $(2)
	$$(info [!] Creating ignition unit dropins $(1) : $(2))
	@jq '[., inputs]' $(2) >| '$(1)'
endef

# ignition_unit_dropin_file '$dropin.conf' '$target.json'
define ignition_unit_dropins_file
$(2): $(1)
	@test -d '$$(dir $(2))' || mkdir -p '$$(dir $(2))'
	@jq -n --slurpfile contents <(jq -Rs . '$(1)') '{ name: "$(notdir $(1))", contents: $$$$contents[0] }' >| '$(2)'
endef

# ignition_unit '$target.json' '$unit.json' '$dropins.json'
define ignition_unit
$(1): $(2) $(3)
	$$(info [!] Building ignition unit $(1) : $(2) $(3))
	@test -d '$$(dir $(1))' || mkdir -p '$$(dir $(2))'
	@jq '.dropins = (inputs // .dropins)' $$^ >| '$(1)'
endef

# ignition_unit_missing '$unit.service' '$target.json' '$dropins.json'
define ignition_unit_missing
$(2): $(3)
	$$(info [!] Building (missing) ignition unit $(2) : $(3))
	@test -d '$$(dir $(2))' || mkdir -p '$$(dir $(2))'
	@jq -n --slurpfile dropins '$(3)' '{ name: "$(1)", dropins: $$$$dropins[0] }' >| '$(2)'
endef

### assign some variables containing the different files we need

## all files that are needed to install coreos
installer_files := $(foreach f,$(file <$(in_coreos_files)),$(workdir)/$(f))

## required files for acbuild
acbuild_files := $(foreach f,$(shell ${GH_FETCH} '$(acbuild_metaurl)' | python $(tools)json-query.py -d - '$$.assets.name'),$(workdir)/files/$(f))

## files for kelseyhightower's setup-network-environment
setup_network_environment_files := $(foreach f,$(shell ${GH_FETCH} '$(setup_network_environment_metaurl)' | python $(tools)json-query.py -d - '$$.assets.name'),$(workdir)/tools/bin/$(f))

## extra tools
extra_tools_files := $(foreach f,$(wildcard $(MAKEDIR)/tools/*),$(workdir)/tools/bin/$(notdir $(f)))

## salt-bootstrap.sh files
salt_bootstrap_file := $(shell ${GH_FETCH} '$(salt_bootstrap_metaurl)' | python $(tools)json-query.py -d - '$$.name')
salt_bootstrap_file_url := $(shell ${GH_FETCH} '$(salt_bootstrap_metaurl)' | python $(tools)json-query.py -d - '$$.download_url')

## all important files that are copied to output
output_files := $(boxname).key $(boxname).key.pub $(boxname_config)

# ignition sysctl
ignition_sysctl_files := $(wildcard $(ignition_config)sysctl/*.conf)

### general utility rules
.PHONY: master-image
master-image: $(boxname_out)
	$(info [!] Wrote output image to $(boxname_out))

.PHONY: download-installer
download-installer: $(installer_files)
	$(info [*] Successfully downloaded CoreOS installer files)

.PHONY: download-tools
download-tools: $(acbuild_files) $(setup_network_environment_files) $(workdir)/$(salt_bootstrap_file)
	$(info [*] Successfully downloaded required tools)

.PHONY: download
download: download-installer download-tools
	$(info [*] Successfully downloaded all required files)

.PHONY: master-output
master-output: $(foreach f,$(output_files),$(outdir)/$(f))
	$(info [!] Wrote output files to $(outdir) : $^)

.PHONY: clean-image
clean-image:
	$(info [!] Erasing temporary image at $(boxname_template))
	rm -rf '$(boxname_template)'
	$(info [!] Erasing image at $(boxname_out))
	rm -rf '$(boxname_out)'

.PHONY: clean-installer
clean-installer:
	$(info [!] Removing CoreOS installer files)
	rm -f $(installer_files)

.PHONY: clean-output
clean-output:
	$(info [!] Erasing temporary files from $(boxname_work))
	rm -f $(foreach f,$(output_files),'$(workdir)/$(f)')
	rm -rf '$(boxname_work)/salt' '$(boxname_work)/pillar'
	rm -f '$(boxname_work)/salt-minion.conf'
	$(info [!] Erasing output files from $(outdir))
	rm -f $(foreach f,$(output_files),'$(outdir)/$(f)')

.PHONY: clean-tools
clean-tools:
	$(info [!] Erasing temporary files from $(workdir)/files)
	rm -rf '$(workdir)/files'
	$(info [!] Erasing $(workdir)/$(salt_bootstrap_file))
	rm -f '$(workdir)/$(salt_bootstrap_file)'
	$(info [!] Erasing $(setup_network_environment_files))
	rm -f '$(setup_network_environment_files)'

.PHONY: clean-yaml
clean-yaml:
	$(info [!] Erasing temporary files for building cloudinit : $(boxname_config).*)
	rm -f '$(workdir)/$(boxname_config)'
	rm -rf '$(boxname_work)/$(boxname_config).'{header,hostname,merged,pubkey}

.PHONY: clean-json
clean-json:
	$(info [!] Erasing temporary files for building packer template : $(boxname).json $(boxname)-vars.json.*)
	rm -f '$(boxname_work)/$(boxname).json'
	rm -f '$(boxname_work)/$(boxname)-vars.json'{,.base,.iso,.salt,.ssh,.tools}

.PHONY: all
all: download-installer master-image master-output
.PHONY: clean
clean: clean-output clean-yaml clean-json clean-image
	test -d '$(boxname_work)' && rmdir '$(boxname_work)' || exit 0

### rules for actual output of template and related files
$(boxname_out): $(boxname_template)
	@test -d '$(outdir)' || mkdir -p '$(outdir)'
	$(info [*] Moving output template into $(outdir) : $<)
	mv '$<' '$@'

$(foreach f,$(output_files),$(outdir)/$(f)): $(foreach f,$(output_files),$(workdir)/$(f))
	@test -d '$(outdir)' || mkdir -p '$(outdir)'
	$(info [*] Copying output files to $(outdir) : $^)
	cp $(foreach f,$^,'$(f)') '$(outdir)'

### rules that actually build the box
$(boxname_template): $(installer_files) $(boxname_work)/$(boxname).json $(boxname_work)/$(boxname)-vars.json $(workdir)/$(boxname_config)
	$(info [!] Building template : $(MAKEDIR))
	packer build --only=vmware-iso -var-file '$(boxname_work)/$(boxname)-vars.json' -var 'guest-config=$(boxname_config)' '$(boxname_work)/$(boxname).json'

### build json file containing all information about the iso
$(boxname_work)/$(boxname)-vars.json.iso: $(workdir)/$(coreos_iso)
	@test -d '$(boxname_work)' || mkdir -p '$(boxname_work)'
	$(info [-] Calculating $(checksum_type) checksum for $<)
	$(eval iso_checksum := $(shell openssl dgst -r -$(checksum_type) '$<' | cut -d' ' -f 1))
	$(info [*] Generating ISO variables for $@ : $^)
	python $(tools)json-generate.py 'iso-checksum-type=$(checksum_type)' 'iso-url=file://$<' 'iso-checksum=$(iso_checksum)' >| '$@'

### build json file containing all information for ssh'ing to the box
$(boxname_work)/$(boxname)-vars.json.ssh: $(workdir)/$(boxname).key
	@test -d '$(boxname_work)' || mkdir -p '$(boxname_work)'
	$(info [*] Generating SSH variables $@ : $^)
	python $(tools)json-generate.py 'provision-key=$(workdir)/$(boxname).key' >| '$@'

### build json file containing build-specific variables
$(boxname_work)/$(boxname)-vars.json.base:
	@test -d '$(boxname_work)' || mkdir -p '$(boxname_work)'
	$(info [*] Generating build variables : $@)
	python $(tools)json-generate.py 'guest-name=$(boxname)' 'install-input=$(workdir)' 'install-output=$(boxname_template)' >| '$@'

### concatenate entire config into a single .json file
$(boxname_work)/$(boxname)-vars.json: $(MAKEDIR)default.json $(boxname_work)/$(boxname)-vars.json.iso $(boxname_work)/$(boxname)-vars.json.ssh $(boxname_work)/$(boxname)-vars.json.salt $(boxname_work)/$(boxname)-vars.json.tools $(boxname_work)/$(boxname)-vars.json.base
	@test -d '$(boxname_work)' || mkdir -p '$(boxname_work)'
	$(info [-] Merging build variables together into $@ : $^)
	python $(tools)json-merge.py $(foreach d,$^,'$(d)') >| '$@'

$(boxname_work)/$(boxname)-vars.json.tools: $(extra_tools_files) $(setup_network_environment_files)
	@test -d '$(boxname_work)' || mkdir -p '$(boxname_work)'
	$(info [-] Generating variables for miscellaneous CoreOS tools)
	python $(tools)json-generate.py 'tools-directory=$(workdir)/tools' >| '$@'

## generate necessary configuration variables for salt-stack
$(boxname_work)/$(boxname)-vars.json.salt: $(boxname_work)/salt $(boxname_work)/pillar $(boxname_work)/salt-minion.conf $(workdir)/$(salt_bootstrap_file)
	@test -d '$(boxname_work)' || mkdir -p '$(boxname_work)'
	$(info [-] Generating bootstrap variables for salt-bootstrap : : $^)
	python $(tools)json-generate.py 'salt-bootstrap-config=$(boxname_work)/salt-minion.conf' 'salt-bootstrap-installer=$(workdir)/$(salt_bootstrap_file)' 'salt-bootstrap-files=$(boxname_work)/salt' 'salt-bootstrap-pillar=$(boxname_work)/pillar' >| '$@'

## concatenate json template into a single .json file together with plugins
$(boxname_work)/$(boxname).json: $(MAKEDIR)box.json $(if $(box_template_extra),$(foreach d,$(shell echo $(box_template_extra)/*),$(d)),)
	@test -d '$(boxname_work)' || mkdir -p '$(boxname_work)'
	$(info [-] Merging box with enabled plugins into $@ : $^)
	python $(tools)json-merge.py $(foreach d,$^,'$(d)') >| '$@'

## generate ssh public/private key
$(workdir)/$(boxname).key $(workdir)/$(boxname).key.pub:
	@test -d '$(boxname_work)' || mkdir -p '$(boxname_work)'
	$(info [*] Generating public/private keypair : $(workdir)/$(boxname).key)
	ssh-keygen -t rsa -C 'builder-generated public key' -f '$(workdir)/$(boxname).key' -N ''

## rules for building bootstrap config
$(workdir)/$(boxname_config): $(boxname_work)/$(boxname_config).header $(boxname_work)/$(boxname_config).merged
	@test -d '$(boxname_work)' || mkdir -p '$(boxname_work)'
	$(info [*] Building YAML configuration $@ : $^)
	cat $(foreach d,$^,'$(d)') >| '$@'
	$(info [!] Validating YAML configuration $@ : $(coreos_validate_url))
	${PUT} '@$@' '$(coreos_validate_url)' | grep -q '{"result":null}' || ( ${PUT} '@$@' '$(coreos_validate_url)'; echo ''; exit 1 )

$(boxname_work)/$(boxname_config).header:
	@test -d '$(boxname_work)' || mkdir -p '$(boxname_work)'
	@echo '#cloud-config' >| '$@'

$(boxname_work)/$(boxname_config).merged: $(MAKEDIR)box.yml $(MAKEDIR)default.yml $(boxname_work)/$(boxname_config).hostname $(boxname_work)/$(boxname_config).pubkey $(if $(box_config_extra),$(foreach d,$(box_config_extra)/*,$(d)),)
	@test -d '$(boxname_work)' || mkdir -p '$(boxname_work)'
	$(info [-] Merging YAML configuration $@ : $^)
	python $(tools)yaml-merge.py $(foreach d,$^,'$(d)') >| '$@'

$(boxname_work)/$(boxname_config).hostname:
	@test -d '$(boxname_work)' || mkdir -p '$(boxname_work)'
	$(info [-] Generating YAML configuration for hostname : $(boxname) )
	@echo "hostname: $(boxname)" >| '$@'

$(boxname_work)/$(boxname_config).pubkey: $(workdir)/$(boxname).key.pub
	@test -d '$(boxname_work)' || mkdir -p '$(boxname_work)'
	$(info [-] Generating YAML configuration $@ with public key : $^)
	python $(tools)yaml-generate.py -p ssh_authorized_keys '$(strip $(file < $<))' >| '$@'

# bootstrap for ignition/sysctl directory
$(boxname_work)/$(boxname).ignition-sysctl.json: $(foreach f,$(ignition_sysctl_files),$(boxname_work)/ignition-sysctl.json-$(notdir $(f)))
	@test -d '$(boxname_work)' || mkdir -p '$(boxname_work)'
	$(info [-] Aggregating all sysctl files into $@ : $^)
	jq '[., inputs]' $^ >| $@

# XXX: add ignition stuff here

### rules for saltstack prep
$(boxname_work)/salt $(boxname_work)/pillar: $(MAKEDIR)salt $(MAKEDIR)pillar $(acbuild_files) $(boxname_work)/pillar/acbuild.sls
	@test -d '$(boxname_work)' || mkdir -p '$(boxname_work)'
	$(info [*] Copying states for bootstrapping $(boxname) to $(boxname_work)/salt.)
	cp -r '$(MAKEDIR)salt' '$(boxname_work)'/
	$(info [*] Copying bootstrap pillar to $(boxname_work)/pillar.)
	cp -r '$(MAKEDIR)pillar' '$(boxname_work)'/
	$(info [*] Copying extra files from $(workdir)/files into states at $(boxname_work)/salt.)
	cp -r '$(workdir)/files' '$(boxname_work)/salt'/

$(boxname_work)/salt-minion.conf: $(MAKEDIR)salt-minion.conf
	@test -d '$(boxname_work)' || mkdir -p '$(boxname_work)'
	$(info [*] Copying in bootstrap configuration from $@.)
	cp '$<' '$@'

$(boxname_work)/pillar/acbuild.sls: $(acbuild_files) $(boxname_work)/pillar
	@test -d '$(dir $@)' || mkdir -p '$(dir $@)'
	$(info [-] Generating default pillar configuration for acbuild.)
	@printf -- '- source: %s\n  algo: %s\n  hash: %s\n\n' $(foreach f,$(acbuild_files),'$(shell basename $(f))' '$(checksum_type)' "$(shell openssl dgst -r -$(checksum_type) '$(f)' | cut -d' ' -f1)") >| '$@'

### generated rules

## generate rules for downloading the coreos installer
$(foreach f,$(file <$(in_coreos_files)),$(eval $(call coreos_download,$(f))))

## generate rules for fetching acbuild
$(foreach u,$(shell ${GH_FETCH} '$(acbuild_metaurl)' | python $(tools)json-query.py -d - '$$.assets.browser_download_url'),$(eval $(call gh_download,$(workdir)/files/$(notdir $(u)),$(u))))

## generate rules for fetching setup-network-environment
$(foreach u,$(shell ${GH_FETCH} '$(setup_network_environment_metaurl)' | python $(tools)json-query.py -d - '$$.assets.browser_download_url'),$(eval $(call gh_download,$(workdir)/tools/bin/$(notdir $(u)),$(u))))

## generate rules for downloading saltstack-bootstrap
$(eval $(call gh_download,$(workdir)/$(salt_bootstrap_file),$(salt_bootstrap_file_url)))

## generate rules for transferring miscellaneous tools
$(foreach f,$(wildcard $(MAKEDIR)/tools/*),$(eval $(call coreos_tool,$(f),$(workdir)/tools/bin/$(notdir $(f)))))

## generate rules for making the ignition sysctl list (0644)
$(foreach f,$(ignition_sysctl_files),$(eval $(call ignition_file,$(f),$(boxname_work)/ignition-sysctl.json-$(notdir $(f)),420)))

## generate rules for making the ignition units list
$(foreach name,$(ignition_units_names),$(eval $(call ignition_unit_file,$(name),$(ignition_config)units/$(name),$(boxname_work)/ignition-units.json-$(name))))

## generate rules for making the ignition unit dropins files
$(foreach name,$(ignition_dropins_names),$(foreach f,$(wildcard $(ignition_config)dropins/$(name)/*.conf),$(eval $(call ignition_unit_dropins_file,$(f),$(boxname_work)/ignition-dropins.json-$(name)-$(notdir $(f))))))

## generate rules for making the ignition unit dropins list
$(foreach name,$(ignition_dropins_names),$(eval $(call ignition_unit_dropins,$(boxname_work)/ignition-dropins.json-$(name),$(foreach f,$(wildcard $(ignition_config)dropins/$(name)/*.conf),$(boxname_work)/ignition-dropins.json-$(name)-$(notdir $(f))))))

## generate rules for combining the units and their dropins

# rules that compose the unit with all of its dropins
$(foreach name,$(filter $(ignition_dropins_names),$(ignition_units_names)),$(eval $(call ignition_unit,$(boxname_work)/ignition-unit.json-$(name),$(boxname_work)/ignition-units.json-$(name),$(boxname_work)/ignition-dropins.json-$(name))))

# rules that compose the unit without any dropins
$(foreach name,$(filter-out $(ignition_dropins_names),$(ignition_units_names)),$(eval $(call ignition_unit,$(boxname_work)/ignition-unit.json-$(name),$(boxname_work)/ignition-units.json-$(name))))

# rules that compose a missing unit with all dropins
$(foreach name,$(filter-out $(ignition_units_names),$(ignition_dropins_names)),$(eval $(call ignition_unit_missing,$(name),$(boxname_work)/ignition-unit.json-$(name),$(boxname_work)/ignition-dropins.json-$(name))))
