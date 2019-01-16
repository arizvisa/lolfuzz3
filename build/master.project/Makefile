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

boxname_out=$(outdir)/$(boxname)
boxname_work=$(workdir)/$(boxname)
boxname_template=$(workdir)/$(boxname)/template

boxname_config=$(boxname).config

### Check output directory
outdir=${OUTPUT}
ifeq ("$(wildcard $(boxname_out))","")
    $(info Preparing to write "$(boxname)" to "$(abspath $(boxname_out))")
else
    $(warning Output path for image already exists. : $(abspath $(boxname_out)))
endif

## some utility macros for downloading
DOWNLOAD := curl -L -k --progress-bar
FETCH := curl -s -S -L -k
PUT := curl -s -S -L -k -X PUT --data-binary

ifneq ("$(wildcard $(ROOTDIR)/github.token)","")
GH_FETCH := ${FETCH} -H 'Authorization: token $(file <$(ROOTDIR)/github.token)'
else
GH_FETCH := ${FETCH}
endif

### default configuration
checksum_type := md5
ignition_config := $(MAKEDIR)ignition/
salt_config := $(MAKEDIR)salt
salt_pillar := $(MAKEDIR)pillar

## all important files that are copied to output
output_files := $(boxname_config) $(boxname).id_rsa $(boxname).id_rsa.pub

## coreos configuration
in_coreos=$(MAKEDIR)coreos.url
in_coreos_version=$(MAKEDIR)coreos.version
in_coreos_validate=$(MAKEDIR)coreos.validate.url
in_coreos_files=$(MAKEDIR)coreos.files

coreos_iso=coreos_production_iso_image.iso

# all files that are needed to install coreos
coreos_installer_files := $(foreach f,$(file <$(in_coreos_files)),$(workdir)/$(f))

## generate the install url from the environment vars
$(foreach var,$(file <$(in_coreos_version)),$(eval export $(var)))
coreos_url=$(file <$(in_coreos))
coreos_validate_url=$(file <$(in_coreos_validate))

## github stuff
in_github=$(MAKEDIR)github.url
in_acbuild_repo=$(MAKEDIR)acbuild.repo
in_setup_network_environment_repo=$(MAKEDIR)/setup-network-environment.repo
in_salt_bootstrap_metaurl=$(MAKEDIR)salt-bootstrap.url

## acbuild variables
acbuild_metaurl := $(shell printf -- '$(file <$(in_github))' '$(file <$(in_acbuild_repo))')

# required files for acbuild
acbuild_files := $(foreach f,$(shell ${GH_FETCH} '$(acbuild_metaurl)' | jq -r '.assets[].name'),$(workdir)/files/$(f))

## variables for kelseyhightower's setup-network-environment
setup_network_environment_metaurl := $(shell printf -- '$(file <$(in_github))' '$(file <$(in_setup_network_environment_repo))')
setup_network_environment_files := $(foreach f,$(shell ${GH_FETCH} '$(setup_network_environment_metaurl)' | jq -r '.assets[].name'),$(workdir)/tools/bin/$(f))

## extra tools
extra_tools_files := $(foreach f,$(wildcard $(MAKEDIR)/tools/*),$(workdir)/tools/bin/$(notdir $(f)))

## salt-bootstrap.sh variables
salt_bootstrap_metaurl := '$(file <$(in_salt_bootstrap_metaurl))'
salt_bootstrap_file := $(shell ${GH_FETCH} '$(salt_bootstrap_metaurl)' | jq -r '.name | @sh')
salt_bootstrap_file_url := $(shell ${GH_FETCH} '$(salt_bootstrap_metaurl)' | jq -r '.download_url | @sh')

## ignition related variables
ignition_template := $(MAKEDIR)default.json
ignition_sysctl_files := $(wildcard $(ignition_config)sysctl/*.conf)
ignition_users_files := $(wildcard $(ignition_config)users/*)

ignition_units_names := $(foreach f,$(wildcard $(ignition_config)units/*),$(notdir $(f)))
ignition_dropins_names := $(foreach f,$(wildcard $(ignition_config)dropins/*),$(notdir $(f)))

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

# coreos_tool '$target' '$source'
define coreos_tool
$(2): $(1)
	@test -d '$$(dir $(2))' || mkdir -p '$$(dir $(2))'
	$$(info [!] Staging file $(1) in $(2))
	cp -f '$(1)' '$(2)'
endef

## because fuck CoreOS for breaking cloud-init right before deprecating it

# raw_file '$source.json-raw' '$target.json'
define raw_file
$(2): $(1)
	@jq -Rs . '$(1)' >| '$(2)'
endef

# ignition_file '$infile.json' '$target.json' '$decimal-mode'
define ignition_file
$(2): $(1)
	@test -d '$$(dir $(2))' || mkdir -p '$$(dir $(2))'
	$$(info [-] Building ignition file $(2) from contents at $(1))
	@jq -n --slurpfile contents '$(1)' '{ filesystem: "root", path: "/etc/sysctl.d/$$(notdir $(1))", mode: $(3), contents: { source: ("data:," + ($$$$contents[0] | @uri)) } }' >| '$(2)'
endef

# ignition_unit_file '$unit.service' '$source.service.json-raw' '$output.json'
define ignition_unit_file
$(3): $(2)
	$$(info [-] Creating ignition unit file $(3) : $(2))
	@jq -n --slurpfile contents '$(2)' '{ name: "$(1)", enable: false, contents: $$$$contents[0], dropins: [] }' >| '$(3)'
endef

# ignition_unit_dropins '$target.json' '$space-separated-dropins'
define ignition_unit_dropins
$(1): $(2)
	$$(info [-] Creating ignition unit dropins $(1) : $(2))
	@jq '[., inputs]' $(2) >| '$(1)'
endef

# ignition_unit_dropin_file '$filename.conf' '$dropin.conf' '$target.json'
define ignition_unit_dropins_file
$(3): $(2)
	@test -d '$$(dir $(3))' || mkdir -p '$$(dir $(3))'
	@jq -n --slurpfile contents '$(2)' '{ name: "$(1)", contents: $$$$contents[0] }' >| '$(3)'
endef

# ignition_unit '$target.json' '$unit.json' '$dropins.json'
define ignition_unit
$(1): $(2) $(3)
	$$(info [*] Combining ignition unit $(1) : $(2) $(3))
	@test -d '$$(dir $(1))' || mkdir -p '$$(dir $(2))'
	@jq '.dropins = (inputs // .dropins)' $$^ >| '$(1)'
endef

# ignition_unit_missing '$unit.service' '$target.json' '$dropins.json'
define ignition_unit_missing
$(2): $(3)
	$$(info [*] Combining (missing) ignition unit $(2) : $(3))
	@test -d '$$(dir $(2))' || mkdir -p '$$(dir $(2))'
	@jq -n --slurpfile dropins '$(3)' '{ name: "$(1)", dropins: $$$$dropins[0] }' >| '$(2)'
endef

# ignition_user '$target.json' '$source.json' '$list-of-json-files'
define ignition_user
$(1): $(2) $(3)
	$$(info [*] Combining files for user into $(1) : $$^)
	@test -d '$$(dir $(1))' || mkdir -p '$$(dir $(1))'
	@jq 'reduce inputs as $$$$item (.; . * $$$$item)' '$(2)' $(3) >| '$(1)'
endef

# output_file '$file' '$directory'
define output_file
$(2)/$(notdir $(1)): $(1)
	@test -d '$(2)' || mkdir -p '$(2)'
	$$(info [*] Copying output file to $(2) : $$<)
	cp '$$<' '$$@'
endef

### general utility rules
.PHONY: master-image
master-image: $(boxname_out)
	$(info [!] Wrote output image to $(boxname_out))

.PHONY: download-installer
download-installer: $(coreos_installer_files)
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
	rm -f $(coreos_installer_files)

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

.PHONY: clean-ignition
clean-ignition:
	$(info [!] Erasing temporary files for building ignition : $(boxname_config).*)
	rm -f '$(workdir)/$(boxname_config)'
	rm -rf '$(boxname_work)/$(boxname_config).'{original,files,units,users,hostname,sysctl,pubkey,validated}

.PHONY: clean-json
clean-json:
	$(info [!] Erasing temporary files for building packer template : $(boxname).json $(boxname)-vars.json.*)
	rm -f '$(boxname_work)/$(boxname).json'
	rm -f '$(boxname_work)/$(boxname)-vars.json'{,.base,.iso,.salt,.ssh,.tools}

.PHONY: all
all: download-installer master-image master-output
	$(info [!] Successfully built image and deployed files)

.PHONY: clean
clean: clean-output clean-ignition clean-json clean-image
	test -d '$(boxname_work)' && rmdir '$(boxname_work)' || exit 0

### rules for actual output of template and related files
$(boxname_out): $(boxname_template)
	@test -d '$(outdir)' || mkdir -p '$(outdir)'
	$(info [*] Moving output template into $(outdir) : $<)
	mv '$<' '$@'

$(foreach f,$(output_files),$(eval $(call output_file,$(workdir)/$(f),$(outdir))))

### rules that actually build the box
$(boxname_template): $(coreos_installer_files) $(boxname_work)/$(boxname).json $(boxname_work)/$(boxname)-vars.json $(workdir)/$(boxname_config)
	$(info [!] Building template : $(MAKEDIR))
	packer build --only=vmware-iso -var-file '$(boxname_work)/$(boxname)-vars.json' -var 'guest-config=$(boxname_config)' '$(boxname_work)/$(boxname).json'

### build json file containing all information about the iso
$(boxname_work)/$(boxname)-vars.json.iso: $(workdir)/$(coreos_iso)
	@test -d '$(boxname_work)' || mkdir -p '$(boxname_work)'
	$(info [-] Calculating $(checksum_type) checksum for $<)
	$(eval iso_checksum := $(shell openssl dgst -r -$(checksum_type) '$<' | cut -d' ' -f 1))
	$(info [-] Generating ISO variables for $@ : $^)
	@jq -n '{ "iso-checksum-type": "$(checksum_type)", "iso-url": "file://$<", "iso-checksum": "$(iso_checksum)" }' >| '$@'

### build json file containing all information for ssh'ing to the box
$(boxname_work)/$(boxname)-vars.json.ssh: $(workdir)/$(boxname).id_rsa
	@test -d '$(boxname_work)' || mkdir -p '$(boxname_work)'
	$(info [-] Generating SSH variables $@ : $^)
	@jq -n '{ "provision-key": "$(workdir)/$(boxname).id_rsa" }' >| '$@'

### build json file containing build-specific variables
$(boxname_work)/$(boxname)-vars.json.base:
	@test -d '$(boxname_work)' || mkdir -p '$(boxname_work)'
	$(info [-] Generating build variables : $@)
	@jq -n '{ "guest-name": "$(boxname)", "install-input": "$(workdir)", "install-output": "$(boxname_template)" }' >| '$@'

### concatenate entire template config into a single .json file
$(boxname_work)/$(boxname)-vars.json: $(MAKEDIR)box-vars.json $(boxname_work)/$(boxname)-vars.json.iso $(boxname_work)/$(boxname)-vars.json.ssh $(boxname_work)/$(boxname)-vars.json.salt $(boxname_work)/$(boxname)-vars.json.tools $(boxname_work)/$(boxname)-vars.json.base
	@test -d '$(boxname_work)' || mkdir -p '$(boxname_work)'
	$(info [*] Merging build variables together into $@ : $^)
	@jq 'reduce inputs as $$item (.; . * $$item)' $(foreach d,$^,'$(d)') >| '$@'

$(boxname_work)/$(boxname)-vars.json.tools: $(extra_tools_files) $(setup_network_environment_files)
	@test -d '$(boxname_work)' || mkdir -p '$(boxname_work)'
	$(info [-] Generating variables for miscellaneous CoreOS tools)
	@jq -n '{ "tools-directory": "$(workdir)/tools" }' >| '$@'

## generate necessary configuration variables for salt-stack
$(boxname_work)/$(boxname)-vars.json.salt: $(boxname_work)/salt $(boxname_work)/pillar $(boxname_work)/salt-minion.conf $(workdir)/$(salt_bootstrap_file)
	@test -d '$(boxname_work)' || mkdir -p '$(boxname_work)'
	$(info [-] Generating bootstrap variables for salt-bootstrap : : $^)
	@jq -n '{ "salt-bootstrap-config": "$(boxname_work)/salt-minion.conf", "salt-bootstrap-installer": "$(workdir)/$(salt_bootstrap_file)", "salt-bootstrap-files": "$(boxname_work)/salt", "salt-bootstrap-pillar": "$(boxname_work)/pillar" }' >| '$@'

## concatenate json template into a single .json file together with plugins
$(boxname_work)/$(boxname).json: $(MAKEDIR)box.json $(MAKEDIR)provision.json $(if $(box_template_extra),$(foreach d,$(shell echo $(box_template_extra)/*),$(d)),)
	@test -d '$(boxname_work)' || mkdir -p '$(boxname_work)'
	$(info [*] Merging box with enabled plugins into $@ : $^)
	@jq 'reduce inputs as $$item (.; . * $$item)' $(foreach d,$^,'$(d)') >| '$@'

## generate ssh public/private key
$(workdir)/$(boxname).id_rsa $(workdir)/$(boxname).id_rsa.pub:
	@test -d '$(boxname_work)' || mkdir -p '$(boxname_work)'
	$(info [-] Generating public/private keypair : $@)
	ssh-keygen -t rsa -C 'builder-generated public key' -f '$@' -N ''

### rules for building bootstrap config

# combine the result ignition json with any other configurations
$(workdir)/$(boxname_config): $(boxname_work)/$(boxname_config)-original $(if $(box_config_extra),$(foreach d,$(box_config_extra)/*,$(d)),)
	@test -d '$(workdir)' || mkdir -p '$(workdir)'
	$(info [*] Merging the ignition configuration $(boxname_work)/$(boxname_config) using the result json and extra configurations: $^)
	@jq 'reduce inputs as $$item (.; . * $$item)' $^ >| '$(boxname_work)/$(boxname_config)'
	$(info [!] Validating ignition configuration $(boxname_work)/$(boxname_config) : $(coreos_validate_url))
	${PUT} '@$(boxname_work)/$(boxname_config)' '$(coreos_validate_url)' >| '$(boxname_work)/$(boxname_config).validated'
	@jq '(.result // []) | .[] | select(.kind == "warning") | [(.line | tostring), (.column | tostring), .message] | @sh' '$(boxname_work)/$(boxname_config).validated' | while read y x message; do \
		printf 'Validation Warning: (line %d, col %d) %s\n' $$y $$x "$$message" 1>&2; \
	done
	@jq '(.result // []) | .[] | select(.kind == "error") | .message | @sh' '$(boxname_work)/$(boxname_config).validated' | while read message; do \
		printf 'Validation Error: %s\n' "$$message" 1>&2; \
		rm -f '$@'; \
		exit 1; \
	done
	cp -f '$(boxname_work)/$(boxname_config)' '$@'

# combine all ignition jsons into the template
$(boxname_work)/$(boxname_config)-original: $(ignition_template) $(boxname_work)/$(boxname_config)-files $(boxname_work)/$(boxname_config)-units $(boxname_work)/$(boxname_config)-users
	@test -d '$(boxname_work)' || mkdir -p '$(boxname_work)'
	$(info [*] Making the ignition configuration $@ from the template $(ignition_template))
	@jq --slurpfile files '$(boxname_work)/$(boxname_config)-files' --slurpfile units '$(boxname_work)/$(boxname_config)-units' --slurpfile users '$(boxname_work)/$(boxname_config)-users' '.storage.files |= $$files[0] | .systemd.units |= $$units[0] | .passwd.users |= $$users[0]' '$(ignition_template)' >| '$@'

# set the hostname using $(boxname)
$(boxname_work)/$(boxname_config)-hostname:
	@test -d '$(boxname_work)' || mkdir -p '$(boxname_work)'
	$(info [-] Building the ignition configuration file for the hostname : $(boxname) )
	# mode 0644 == 420
	@jq -n '[ { filesystem: "root", path: "/etc/hostname", mode: 420, contents: { source: ("data:," + ("$(boxname)" | @uri)) } } ]' >| '$@'

# bootstrap for ignition/sysctl directory
$(boxname_work)/$(boxname_config)-sysctl: $(foreach f,$(ignition_sysctl_files),$(boxname_work)/ignition-sysctl.json-$(notdir $(f)))
	@test -d '$(boxname_work)' || mkdir -p '$(boxname_work)'
	$(info [*] Merging all ignition sysctl files into $@ : $^)
	@jq '[., inputs]' $^ >| '$@'

# combine all ignition file jsons into a single one
$(boxname_work)/$(boxname_config)-files: $(boxname_work)/$(boxname_config)-hostname $(boxname_work)/$(boxname_config)-sysctl
	@test -d '$(boxname_work)' || mkdir -p '$(boxname_work)'
	$(info [*] Merging the ignition file section into $@ : $^)
	@jq '. + inputs' $^ >| '$@'

# combining for ignition/units and ignition/dropins
$(boxname_work)/$(boxname_config)-units: $(foreach name,$(ignition_units_names),$(boxname_work)/ignition-unit.json-$(name)) $(foreach name,$(ignition_dropins_names),$(boxname_work)/ignition-unit.json-$(name))
	@test -d '$(boxname_work)' || mkdir -p '$(boxname_work)'
	$(info [*] Merging the ignition unit section into $@ : $^)
	@jq '[., inputs]' $^ >| '$@'

# generate a json containing the sshAuthorizedKeys field in an object
$(boxname_work)/$(boxname_config)-pubkey: $(boxname_work)/$(boxname).id_rsa.pub.json-raw
	@test -d '$(boxname_work)' || mkdir -p '$(boxname_work)'
	$(info [-] Generating a json with the public key in $@ : $^)
	@jq -n --slurpfile pubkey '$<' '{ sshAuthorizedKeys: [$$pubkey[0] | rtrimstr("\n") ] }' >| '$@'

# combine all joined user objects into a single list
$(boxname_work)/$(boxname_config)-users: $(foreach f,$(ignition_users_files),$(boxname_work)/ignition-user.json-$(notdir $(f)))
	@test -d '$(boxname_work)' || mkdir -p '$(boxname_work)'
	$(info [*] Merging the ignition user section into $@: $^)
	@jq '[., inputs]' $^ >| '$@'

### rules for saltstack prep
$(boxname_work)/salt $(boxname_work)/pillar: $(salt_config) $(salt_pillar) $(acbuild_files) $(boxname_work)/pillar/acbuild.sls $(boxname_work)/pillar/project.sls
	@test -d '$(boxname_work)' || mkdir -p '$(boxname_work)'
	$(info [*] Copying states for bootstrapping $(boxname) to $(boxname_work)/salt.)
	cp -r '$(salt_config)' '$(boxname_work)'/
	$(info [*] Copying bootstrap pillar to $(boxname_work)/pillar.)
	cp -r '$(salt_pillar)' '$(boxname_work)'/
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

$(boxname_work)/pillar/project.sls: $(boxname_work)/pillar
	@test -d '$(dir $@)' || mkdir -p '$(dir $@)'
	$(info [-] Generating default pillar configuration for project.)
	@printf -- 'name: %s\n' '$(PROJECT)' >| '$@'

### generated rules

## generate rules for downloading the coreos installer
$(foreach f,$(file <$(in_coreos_files)),$(eval $(call coreos_download,$(f))))

## generate rules for fetching acbuild
$(foreach u,$(shell ${GH_FETCH} '$(acbuild_metaurl)' | jq -r '.assets[].browser_download_url'),$(eval $(call gh_download,$(workdir)/files/$(notdir $(u)),$(u))))

## generate rules for fetching setup-network-environment
$(foreach u,$(shell ${GH_FETCH} '$(setup_network_environment_metaurl)' | jq -r '.assets[].browser_download_url'),$(eval $(call gh_download,$(workdir)/tools/bin/$(notdir $(u)),$(u))))

## generate rules for downloading saltstack-bootstrap
$(eval $(call gh_download,$(workdir)/$(salt_bootstrap_file),$(salt_bootstrap_file_url)))

## generate rules for transferring miscellaneous tools
$(foreach f,$(wildcard $(MAKEDIR)/tools/*),$(eval $(call coreos_tool,$(f),$(workdir)/tools/bin/$(notdir $(f)))))

## generate rules for making the ignition sysctl list (0644 == 420)
$(foreach f,$(ignition_sysctl_files),$(eval $(call ignition_file,$(boxname_work)/ignition-sysctl.json-$(notdir $(f)).json-raw,$(boxname_work)/ignition-sysctl.json-$(notdir $(f)),420)))

## generate rules for making the ignition units list
$(foreach name,$(ignition_units_names),$(eval $(call ignition_unit_file,$(name),$(boxname_work)/ignition-units.json-$(name).json-raw,$(boxname_work)/ignition-units.json-$(name))))

## generate rules for making the ignition unit dropins files
$(foreach name,$(ignition_dropins_names),$(foreach f,$(wildcard $(ignition_config)dropins/$(name)/*.conf),$(eval $(call ignition_unit_dropins_file,$(notdir $(f)),$(boxname_work)/ignition-dropins.json-$(name)-$(notdir $(f)).json-raw,$(boxname_work)/ignition-dropins.json-$(name)-$(notdir $(f))))))

## generate rules for making the ignition unit dropins list
$(foreach name,$(ignition_dropins_names),$(eval $(call ignition_unit_dropins,$(boxname_work)/ignition-dropins.json-$(name),$(foreach f,$(wildcard $(ignition_config)dropins/$(name)/*.conf),$(boxname_work)/ignition-dropins.json-$(name)-$(notdir $(f))))))

## generate rules for combining the units and their dropins

# rules that compose the unit with all of its dropins
$(foreach name,$(filter $(ignition_dropins_names),$(ignition_units_names)),$(eval $(call ignition_unit,$(boxname_work)/ignition-unit.json-$(name),$(boxname_work)/ignition-units.json-$(name),$(boxname_work)/ignition-dropins.json-$(name))))

# rules that compose the unit without any dropins
$(foreach name,$(filter-out $(ignition_dropins_names),$(ignition_units_names)),$(eval $(call ignition_unit,$(boxname_work)/ignition-unit.json-$(name),$(boxname_work)/ignition-units.json-$(name))))

# rules that compose a missing unit with all dropins
$(foreach name,$(filter-out $(ignition_units_names),$(ignition_dropins_names)),$(eval $(call ignition_unit_missing,$(name),$(boxname_work)/ignition-unit.json-$(name),$(boxname_work)/ignition-dropins.json-$(name))))

## generate rules for combining each user with the sshAuthorizedKeys
$(foreach f,$(ignition_users_files),$(eval $(call ignition_user,$(boxname_work)/ignition-user.json-$(notdir $(f)),$(f),$(boxname_work)/$(boxname_config)-pubkey)))

## generate raw files that are needed for bash workaround

# ignition_sysctl_files contents
$(foreach f,$(ignition_sysctl_files),$(eval $(call raw_file,$(f),$(boxname_work)/ignition-sysctl.json-$(notdir $(f)).json-raw)))

# ignition_unit_files contents
$(foreach name,$(ignition_units_names),$(eval $(call raw_file,$(ignition_config)units/$(name),$(boxname_work)/ignition-units.json-$(name).json-raw)))

# ignition_dropins_names contents
$(foreach name,$(ignition_dropins_names),$(foreach f,$(wildcard $(ignition_config)dropins/$(name)/*.conf),$(eval $(call raw_file,$(f),$(boxname_work)/ignition-dropins.json-$(name)-$(notdir $(f)).json-raw))))

# ssh pubkey contents
$(eval $(call raw_file,$(workdir)/$(boxname).id_rsa.pub,$(boxname_work)/$(boxname).id_rsa.pub.json-raw))
