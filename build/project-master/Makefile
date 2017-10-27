MAKEDIR := $(dir $(firstword $(MAKEFILE_LIST)))
ROOTDIR := $(realpath $(MAKEDIR)/../..)

ifndef PROJECT
    $(error Build variable name PROJECT is undefined)
endif
ifndef INPUT
    $(error Build variable path INPUT is undefined)
endif
ifndef OUTPUT
    $(error Build variable path OUTPUT is undefined.)
endif

## Check input directory with configuration for master
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

boxname=${PROJECT}.master
boxoutput=template.$(boxname)
workdir?=tmp.$(boxname)
outdir?=${ROOTDIR}/template
box_config_name=$(boxname).yml
tools=$(ROOTDIR)/build/bin/

## Check output directory
outdir=${OUTPUT}
ifeq ("$(wildcard $(outdir)/$(boxname))","")
    $(info Writing "${PROJECT}" master to "$(abspath $(outdir)/$(boxname))")
else
    $(error Specified path for output already exists. : $(abspath $(outdir)/$(boxname)))
endif

# files for template
iso?=coreos_production_iso_image.iso
iso_checksum_type := md5

# configuration
in_environment=$(MAKEDIR)/coreos.env
in_baseurl=$(MAKEDIR)/coreos.url
in_files=$(MAKEDIR)/coreos.files
in_validator=$(MAKEDIR)/coreos.validate.url

# generate the install url from the environment vars
$(foreach var,$(file <$(in_environment)),$(eval export $(var)))
baseurl=$(file <$(in_baseurl))
validateurl=$(file <$(in_validator))

FETCH := curl -s -k
PUT := curl -s -k -X PUT --data-binary

# download rule
define download
$$(workdir)/$$(notdir $(1)):
	test -d '$$(workdir)' || mkdir -p '$$(workdir)'
	$$(info [*] Downloading CoreOS Installer $(baseurl)/$(1))
	$${FETCH} -o '$$@' '$(baseurl)/$(1)'
endef

# all files that are needed to install coreos
installer_files := $(foreach f,$(file <$(in_files)),$(workdir)/$(f))

# general utility rules
.PHONY: master-base
master-base-image: $(boxoutput)
	$(info [*] Moving template into $(outdir) : $^)
	mkdir -p '$(outdir)'
	mv '$<' '$(outdir)/$(boxname)'

.PHONY: master-base-download
master-base-download: $(foreach f,$(file <$(in_files)),$(workdir)/$(f))
	$(info [*] Successfully downloaded CoreOS installer files)

.PHONY: master-base-output
master-base-output: $(workdir)/$(boxname).key $(workdir)/$(boxname).key.pub $(workdir)/$(boxname)-vars.json $(workdir)/$(boxname).yml 
	$(info [*] Writing output files to $(outdir) : $^)
	mkdir -p '$(outdir)'
	cp $(foreach f,$^,'$(f)') '$(outdir)'

# actually build the box
$(boxoutput): $(installer_files) $(workdir)/$(boxname).json $(workdir)/$(boxname)-vars.json $(workdir)/$(boxname).yml
	$(info [*] Building template : $(MAKEDIR))
	@packer build --only=vmware-iso -var-file '$(workdir)/$(boxname)-vars.json' -var 'guest-config=$(boxname).yml' '$(workdir)/$(boxname).json'

# build json file containing all information about iso
$(workdir)/$(boxname)-vars.json.iso: $(workdir)/$(iso)
	$(info [*] Calculating $(iso_checksum_type) checksum for $<)
	$(eval iso_checksum := $(shell openssl dgst -r -$(iso_checksum_type) '$(workdir)/$(iso)' | cut -d' ' -f 1))
	$(info [*] Generating ISO variables for $@ : $^)
	@python $(tools)json-generate.py 'iso-checksum-type=$(iso_checksum_type)' 'iso-url=file://$(workdir)/$(iso)' 'iso-checksum=$(iso_checksum)' >| '$@'

# build json file containing all information about ssh'ing to the box
$(workdir)/$(boxname)-vars.json.ssh: $(workdir)/$(boxname).key
	$(info [*] Generating SSH variables $@ : $^)
	@python $(tools)json-generate.py 'provision-key=$(workdir)/$(boxname).key' >| '$@'

# build json file containing build-specific variables
$(workdir)/$(boxname)-vars.json.base:
	$(info [*] Generating build variables : $@)
	@python $(tools)json-generate.py 'guest-name=$(boxname)' 'install-input=$(workdir)' 'install-output=$(boxoutput)' >| '$@'

# concatenate all config into a single .json file for variables
$(workdir)/$(boxname)-vars.json: $(MAKEDIR)/default.json $(workdir)/$(boxname)-vars.json.iso $(workdir)/$(boxname)-vars.json.ssh $(workdir)/$(boxname)-vars.json.base
	$(info [*] Merging build variables together into $@ : $^)
	@python $(tools)json-merge.py $(foreach d,$^,'$(d)') >| '$@'

# concatenate json template into a single .json file with plugins
$(workdir)/$(boxname).json: $(MAKEDIR)/box.json $(if $(box_template_extra),$(foreach d,$(shell echo $(box_template_extra)/*),$(d)),)
	$(info [*] Merging box with enabled plugins into $@ : $^)
	@python $(tools)json-merge.py $(foreach d,$^,'$(d)') >| '$@'

# generate ssh public/private key
$(workdir)/$(boxname).key $(workdir)/$(boxname).key.pub:
	$(info [*] Generating public/private keypair : $(workdir)/$(boxname).key)
	@ssh-keygen -t rsa -C 'builder-generated public key' -f '$(workdir)/$(boxname).key' -N ''

# rules for bootstrap config
$(workdir)/$(boxname).yml: $(workdir)/$(box_config_name).header $(workdir)/$(box_config_name).merged
	$(info [*] Building YAML configuration $@ : $^)
	@cat $(foreach d,$^,'$(d)') >| '$@'
	$(info [*] Validating YAML configuration $@ : $(validateurl))
	@${PUT} '@$@' '$(validateurl)' | grep -q '{"result":null}' || ( ${PUT} '@$@' '$(validateurl)'; echo ''; exit 1 )

$(workdir)/$(boxname).yml.header:
	@echo '#cloud-config' >| '$@'

$(workdir)/$(boxname).yml.merged: $(MAKEDIR)/box.yml $(MAKEDIR)/default.yml $(workdir)/$(box_config_name).hostname $(workdir)/$(box_config_name).pubkey $(if $(box_config_extra),$(foreach d,$(box_config_extra)/*,$(d)),)
	$(info [*] Merging YAML configuration $@ : $^)
	@python $(tools)yaml-merge.py $(foreach d,$^,'$(d)') >| '$@'

$(workdir)/$(boxname).yml.hostname:
	$(info [*] Generating YAML configuration for hostname : $(boxname) )
	@echo "hostname: $(boxname)" >| $@

$(workdir)/$(boxname).yml.pubkey: $(workdir)/$(boxname).key.pub
	$(info [*] Generating YAML configuration $@ with public key : $^)
	@python $(tools)yaml-generate.py -p ssh_authorized_keys '$(strip $(file < $<))' >| '$@'

# rules for installer downloads
$(foreach f,$(file <$(in_files)),$(eval $(call download,$(f))))
