CWD := $(dir $(firstword $(MAKEFILE_LIST)))
BUILDDIR := $(realpath $(dir $(firstword $(MAKEFILE_LIST)))/../..)

ifndef PROJECT
    $(error Build variable name PROJECT is undefined)
endif
ifndef BOX_PLUGIN
    $(info Build plugin directory BOX_PLUGIN is undefined)
    box_plugin=
else
    box_plugin=${BOX_PLUGIN}
endif
ifndef BOX_CONFIG
    $(info Build config directory BOX_CONFIG is undefined)
    box_config=
else
    box_config=${BOX_CONFIG}
endif

boxname=${PROJECT}.master
boxoutput=output-${boxname}
workdir?=wwwroot
config=master.yml

# files for template
iso?=coreos_production_iso_image.iso
iso_checksum_type := md5
#box_plugin?=$(CWD)/enabled
#box_config?=$(CWD)/config

# configuration
in_environment=$(CWD)/coreos.env
in_baseurl=$(CWD)/coreos.url
in_files=$(CWD)/coreos.files
in_validator=$(CWD)/coreos.validate.url

# generate the install url from the environment vars
$(foreach var,$(file <${in_environment}),$(eval export $(var)))
baseurl=$(file <${in_baseurl})
validateurl=$(file <${in_validator})

FETCH := curl -s -k
PUT := curl -s -k -X PUT --data-binary

# download rule
define download
$${workdir}/$$(notdir $(1)):
	test -d '$${workdir}' || mkdir -p '$${workdir}'
	$$(info [*] Downloading CoreOS Installer ${baseurl}/$(1))
	$${FETCH} -o '$$@' '${baseurl}/$(1)'
endef

# all files that are needed to install coreos
installer_files := $(foreach f,$(file <${in_files}),${workdir}/$(f))

# general utility rules
.PHONY: master-base
master-base-image: ${boxoutput}

.PHONY: master-base-download
master-base-download: $(foreach f,$(file <${in_files}),${workdir}/$(f))
	$(info [*] Successfully downloaded CoreOS installer files)

.PHONY: master-base-output
master-base-output: ${workdir}/master.key ${workdir}/master.key.pub ${workdir}/${config} ${workdir}/master-vars.json
	$(info [*] Writing output files to ${outdir} : $^)
	mkdir -p '${outdir}'
	cp $(foreach f,$^,'$(f)') '${outdir}'

# actually build the box
${boxoutput}: ${installer_files} ${workdir}/master.json ${workdir}/master-vars.json ${workdir}/${config}
	$(info [*] Building template : $(CWD))
	@packer build --only=vmware-iso -var-file '${workdir}/master-vars.json' -var 'guest-config=${config}' '${workdir}/master.json'

# build json file containing all information about iso
${workdir}/master-vars.json.iso: ${workdir}/${iso}
	$(info [*] Calculating ${iso_checksum_type} checksum for $<)
	$(eval iso_checksum := $(shell openssl dgst -r -${iso_checksum_type} '${workdir}/${iso}' | cut -d' ' -f 1))
	$(info [*] Generating ISO variables for $@ : $^)
	@python $(BUILDDIR)/bin/json-generate.py 'iso-checksum-type=${iso_checksum_type}' 'iso-url=file://${workdir}/${iso}' 'iso-checksum=${iso_checksum}' >| '$@'

# build json file containing all information about ssh'ing to the box
${workdir}/master-vars.json.ssh: ${workdir}/master.key
	$(info [*] Generating SSH variables $@ : $^)
	@python $(BUILDDIR)/bin/json-generate.py 'provision-key=${workdir}/master.key' >| '$@'

# build json file containing build-specific variables
${workdir}/master-vars.json.base:
	$(info [*] Generating build variables : $@)
	@python $(BUILDDIR)/bin/json-generate.py 'guest-name=${boxname}' 'install-input=${workdir}' 'install-output=${boxoutput}' >| '$@'

# concatenate all config into a single .json file for variables
${workdir}/master-vars.json: $(CWD)/default.json ${workdir}/master-vars.json.iso ${workdir}/master-vars.json.ssh ${workdir}/master-vars.json.base
	$(info [*] Merging build variables together into $@ : $^)
	@python $(BUILDDIR)/bin/json-merge.py $(foreach d,$^,'$(d)') >| '$@'

# concatenate json template into a single .json file with plugins
${workdir}/master.json: $(CWD)/box.json $(if ${box_plugin},$(foreach d,$(shell echo ${box_plugin}/*),$(d)),)
	$(info [*] Merging box with enabled plugins into $@ : $^)
	@python $(BUILDDIR)/bin/json-merge.py $(foreach d,$^,'$(d)') >| '$@'

# generate ssh public/private key
${workdir}/master.key ${workdir}/master.key.pub:
	$(info [*] Generating public/private keypair : ${workdir}/master.key)
	@ssh-keygen -t rsa -C 'builder-generated public key' -f '${workdir}/master.key' -N ''

# rules for bootstrap config
${workdir}/${config}: ${workdir}/${config}.header ${workdir}/${config}.merged
	$(info [*] Building YAML configuration $@ : $^)
	@cat $(foreach d,$^,'$(d)') >| '$@'
	$(info [*] Validating YAML configuration $@ : ${validateurl})
	@${PUT} '@$@' '${validateurl}' | grep -q '{"result":null}' || ( ${PUT} '@$@' '${validateurl}'; echo ''; exit 1 )

${workdir}/${config}.header:
	@echo '#cloud-config' >| '$@'

${workdir}/${config}.merged: $(CWD)/box.yml $(CWD)/default.yml ${workdir}/${config}.hostname ${workdir}/${config}.pubkey $(if ${box_config},$(foreach d,${box_config}/*,$(d)),)
	$(info [*] Merging YAML configuration $@ : $^)
	@python $(BUILDDIR)/bin/yaml-merge.py $(foreach d,$^,'$(d)') >| '$@'

${workdir}/${config}.hostname:
	$(info [*] Generating YAML configuration for hostname : ${PROJECT}.master )
	@echo "hostname: ${PROJECT}.master" >| $@

${workdir}/${config}.pubkey: ${workdir}/master.key.pub
	$(info [*] Generating YAML configuration $@ with public key : $^)
	@python $(BUILDDIR)/bin/yaml-generate.py -p ssh_authorized_keys '$(strip $(file < $<))' >| '$@'

# rules for installer downloads
$(foreach f,$(file <${in_files}),$(eval $(call download,$(f))))
