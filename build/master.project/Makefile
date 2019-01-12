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

boxname=master.${PROJECT}
workdir?=tmp.$(boxname)
outdir?=${ROOTDIR}/template
box_config_name=$(boxname).yml
tools=$(ROOTDIR)/build/bin/

boxname_out=$(outdir)/$(boxname)
boxname_work=template.$(boxname)

## Check output directory
outdir=${OUTPUT}
ifeq ("$(wildcard $(boxname_out))","")
    $(info Writing "${PROJECT}" master to "$(abspath $(boxname_out))")
else
    $(info Output path for image already exists. : $(abspath $(boxname_out)))
endif

# files for template
checksum_type := md5
iso?=coreos_production_iso_image.iso

# coreos configuration
in_environment=$(MAKEDIR)/coreos.env
in_baseurl=$(MAKEDIR)/coreos.url
in_files=$(MAKEDIR)/coreos.files
in_validator=$(MAKEDIR)/coreos.validate.url

# acbuild configuration
in_github=$(MAKEDIR)/github.url
in_acbuild=$(MAKEDIR)/acbuild.repo

# generate the install url from the environment vars
$(foreach var,$(file <$(in_environment)),$(eval export $(var)))
baseurl=$(file <$(in_baseurl))
validateurl=$(file <$(in_validator))

# generate the acbuild url from each file
acbuildurl=$(shell printf '$(file <$(in_github))' '$(file <$(in_acbuild))')

# some utility macros
FETCH := curl -L -s -k
PUT := curl -L -s -k -X PUT --data-binary

# download rule for CoreOS
define download
$$(workdir)/$$(notdir $(1)):
	test -d '$$(workdir)' || mkdir -p '$$(workdir)'
	$$(info [!] Downloading CoreOS Installer $(baseurl)/$(1))
	$${FETCH} -o '$$@' '$(baseurl)/$(1)'
endef

# download rule for acbuild
define acdownload
$$(workdir)/files/$$(notdir $$(shell basename '$(1)')):
	test -d '$$(workdir)/files' || mkdir -p '$$(workdir)/files'
	$$(info [!] Downloading $$(shell basename '$(1)') from $(1))
	$${FETCH} -o '$$@' '$(1)'
endef

# all files that are needed to install coreos
installer_files := $(foreach f,$(file <$(in_files)),$(workdir)/$(f))

# all files for acbuild
acbuild_files := $(foreach f,$(shell ${FETCH} '$(acbuildurl)' | python $(tools)json-query.py -d - '$$.assets.name'),$(workdir)/files/$(f))

# all important files that are preserved
output_files := $(boxname).key $(boxname).key.pub $(boxname).yml $(boxname)-vars.json

# general utility rules
.PHONY: master-image
master-image: $(boxname_out)
	$(info [!] Wrote output image to $(boxname_out))

.PHONY: download-coreos
download-coreos: $(installer_files)
	$(info [*] Successfully downloaded CoreOS installer files)

.PHONY: master-output
master-output: $(foreach f,$(output_files),$(outdir)/$(f))
	$(info [!] Wrote output files to $(outdir) : $^)

.PHONY: clean-image
clean-image:
	$(info [!] Erasing temporary image at $(boxname_work))
	rm -rf '$(boxname_work)'
	$(info [!] Erasing image at $(boxname_out))
	rm -rf '$(boxname_out)'

.PHONY: clean-coreos
clean-coreos:
	$(info [!] Removing CoreOS installer files)
	rm -f $(installer_files)

.PHONY: clean-output
clean-output:
	$(info [!] Erasing temporary files from $(workdir))
	rm -f $(foreach f,$(output_files),'$(workdir)/$(f)')
	rm -rf '$(workdir)/salt' '$(workdir)/pillar'
	rm -f '$(workdir)/salt-minion.conf'
	$(info [!] Erasing output files from $(outdir))
	rm -f $(foreach f,$(output_files),'$(outdir)/$(f)')

.PHONY: clean-tools
clean-tools:
	$(info [!] Erasing temporary files from $(workdir)/files)
	rm -rf '$(workdir)/files'

.PHONY: clean-yaml
clean-yaml:
	$(info [!] Erasing temporary files for building cloudinit : $(boxname).yml.*)
	rm -rf '$(workdir)/$(boxname).yml.'{header,hostname,merged,pubkey}

.PHONY: clean-json
clean-json:
	$(info [!] Erasing temporary files for building packer template : $(boxname).json $(boxname)-vars.json.*)
	rm -f '$(workdir)/$(boxname).json'
	rm -rf '$(workdir)/$(boxname)-vars.json.'{base,iso,salt,ssh}

.PHONY: all
all: download-coreos master-image master-output
.PHONY: clean
clean: clean-coreos clean-image clean-output clean-tools clean-yaml clean-json
	rmdir '$(workdir)'

# rules for actual output of template and related files
$(boxname_out): $(boxname_work)
	$(info [*] Moving output template into $(outdir) : $<)
	test -d '$(outdir)' || mkdir -p '$(outdir)'
	mv '$<' '$@'

$(foreach f,$(output_files),$(outdir)/$(f)): $(foreach f,$(output_files),$(workdir)/$(f))
	$(info [*] Copying output files to $(outdir) : $^)
	test -d '$(outdir)' || mkdir -p '$(outdir)'
	cp $(foreach f,$^,'$(f)') '$(outdir)'

# actually build the box
$(boxname_work): $(installer_files) $(workdir)/$(boxname).json $(workdir)/$(boxname)-vars.json $(workdir)/$(boxname).yml
	$(info [!] Building template : $(MAKEDIR))
	@packer build --only=vmware-iso -var-file '$(workdir)/$(boxname)-vars.json' -var 'guest-config=$(boxname).yml' '$(workdir)/$(boxname).json'

# build json file containing all information about iso
$(workdir)/$(boxname)-vars.json.iso: $(workdir)/$(iso)
	$(info [-] Calculating $(checksum_type) checksum for $<)
	$(eval iso_checksum := $(shell openssl dgst -r -$(checksum_type) '$(workdir)/$(iso)' | cut -d' ' -f 1))
	$(info [*] Generating ISO variables for $@ : $^)
	@python $(tools)json-generate.py 'iso-checksum-type=$(checksum_type)' 'iso-url=file://$(workdir)/$(iso)' 'iso-checksum=$(iso_checksum)' >| '$@'

# build json file containing all information for ssh'ing to the box
$(workdir)/$(boxname)-vars.json.ssh: $(workdir)/$(boxname).key
	$(info [*] Generating SSH variables $@ : $^)
	@python $(tools)json-generate.py 'provision-key=$(workdir)/$(boxname).key' >| '$@'

# build json file containing build-specific variables
$(workdir)/$(boxname)-vars.json.base:
	$(info [*] Generating build variables : $@)
	@python $(tools)json-generate.py 'guest-name=$(boxname)' 'install-input=$(workdir)' 'install-output=$(boxname_work)' >| '$@'

# concatenate all config into a single .json file for variables
$(workdir)/$(boxname)-vars.json: $(MAKEDIR)/default.json $(workdir)/$(boxname)-vars.json.iso $(workdir)/$(boxname)-vars.json.ssh $(workdir)/$(boxname)-vars.json.salt $(workdir)/$(boxname)-vars.json.base
	$(info [-] Merging build variables together into $@ : $^)
	@python $(tools)json-merge.py $(foreach d,$^,'$(d)') >| '$@'

# generate variables necessary for salt-stack
$(workdir)/$(boxname)-vars.json.salt: $(workdir)/salt $(workdir)/pillar $(workdir)/salt-minion.conf
	$(info [-] Generating bootstrap variables for salt-bootstrap : : $^)
	@python $(tools)json-generate.py 'salt-bootstrap-config=$(workdir)/salt-minion.conf' 'salt-bootstrap-files=$(workdir)/salt' 'salt-bootstrap-pillar=$(workdir)/pillar' >| '$@'

# concatenate json template into a single .json file with plugins
$(workdir)/$(boxname).json: $(MAKEDIR)/box.json $(if $(box_template_extra),$(foreach d,$(shell echo $(box_template_extra)/*),$(d)),)
	$(info [-] Merging box with enabled plugins into $@ : $^)
	@python $(tools)json-merge.py $(foreach d,$^,'$(d)') >| '$@'

# generate ssh public/private key
$(workdir)/$(boxname).key $(workdir)/$(boxname).key.pub:
	$(info [*] Generating public/private keypair : $(workdir)/$(boxname).key)
	@ssh-keygen -t rsa -C 'builder-generated public key' -f '$(workdir)/$(boxname).key' -N ''

# rules for generating bootstrap config
$(workdir)/$(boxname).yml: $(workdir)/$(box_config_name).header $(workdir)/$(box_config_name).merged
	$(info [*] Building YAML configuration $@ : $^)
	@cat $(foreach d,$^,'$(d)') >| '$@'
	$(info [!] Validating YAML configuration $@ : $(validateurl))
	@${PUT} '@$@' '$(validateurl)' | grep -q '{"result":null}' || ( ${PUT} '@$@' '$(validateurl)'; echo ''; exit 1 )

$(workdir)/$(boxname).yml.header:
	@echo '#cloud-config' >| '$@'

$(workdir)/$(boxname).yml.merged: $(MAKEDIR)/box.yml $(MAKEDIR)/default.yml $(workdir)/$(box_config_name).hostname $(workdir)/$(box_config_name).pubkey $(if $(box_config_extra),$(foreach d,$(box_config_extra)/*,$(d)),)
	$(info [-] Merging YAML configuration $@ : $^)
	@python $(tools)yaml-merge.py $(foreach d,$^,'$(d)') >| '$@'

$(workdir)/$(boxname).yml.hostname:
	$(info [-] Generating YAML configuration for hostname : $(boxname) )
	@echo "hostname: $(boxname)" >| '$@'

$(workdir)/$(boxname).yml.pubkey: $(workdir)/$(boxname).key.pub
	$(info [-] Generating YAML configuration $@ with public key : $^)
	@python $(tools)yaml-generate.py -p ssh_authorized_keys '$(strip $(file < $<))' >| '$@'

# rules for saltstack prep
$(workdir)/salt $(workdir)/pillar: $(MAKEDIR)/salt $(MAKEDIR)/pillar $(workdir)/files
	$(info [*] Copying states for bootstrapping $(boxname) to $(workdir)/salt.)
	cp -r '$(MAKEDIR)/salt' '$(workdir)/salt'
	$(info [*] Copying bootstrap pillar to $(workdir)/pillar.)
	cp -r '$(MAKEDIR)/pillar' '$(workdir)/pillar'
	$(info [*] Copying extra files from $(workdir)/files into states at $(workdir)/salt.)
	cp -r '$(workdir)/files' '$(workdir)/salt'/

$(workdir)/salt-minion.conf: $(MAKEDIR)/salt-minion.conf
	$(info [*] Copying in bootstrap configuration from $@.)
	test -d $(shell dirname '$@') || mkdir -p $(shell dirname '$@')
	cp '$<' '$@'

$(workdir)/files: $(acbuild_files) $(workdir)/pillar/acbuild.sls
	$(info [*] Successfully downloaded files for acbuild $(shell ${FETCH} '$(acbuildurl)' | python $(tools)json-query.py - '$$.name').)

$(workdir)/pillar/acbuild.sls: $(acbuild_files) $(workdir)/pillar
	$(info [-] Generating default pillar configuration for acbuild.)
	printf 'acbuild:\n' >| '$@'
	printf '    - source: %s\n      algo: %s\n      hash: %s\n\n' $(foreach f,$(acbuild_files),'$(shell basename $(f))' '$(checksum_type)' "$(shell openssl dgst -r -$(checksum_type) '$(f)' | cut -d' ' -f1)") >> '$@'

# rules for installer downloads
$(foreach f,$(file <$(in_files)),$(eval $(call download,$(f))))

# rules for acbuild downloads
$(foreach u,$(shell ${FETCH} '$(acbuildurl)' | python $(tools)json-query.py -d - '$$.assets.browser_download_url'),$(eval $(call acdownload,$(u))))
