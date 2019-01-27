MAKEDIR := $(dir $(firstword $(MAKEFILE_LIST)))
ROOTDIR := $(realpath $(MAKEDIR)../..)

### Parameters that the user can supply

# mandatory parameters
ifndef PROJECT
    $(error [!] Required build variable PROJECT is not specified)
endif

# optional parameters
ifndef INPUT
    $(info [!] Optional build variable INPUT was not specified)
    $(info [*] Setting default value for INPUT: $(ROOTDIR)/config/master.project)
    INPUT := $(ROOTDIR)/config/master.project
endif

ifndef OUTPUT
    $(info [!] Optional build variable OUTPUT was not specified)
    $(info [*] Setting default value for OUTPUT: $(ROOTDIR)/deploy)
    OUTPUT := $(ROOTDIR)/deploy
endif

## configurable parameters
# convert the following parameters to an integer
VALIDATE ?= 1
validate := $(VALIDATE)
validate := $(patsubst T%,1,$(patsubst F%,0,$(patsubst t%,1,$(patsubst f%,0,$(validate)))))
validate := $(patsubst Y%,1,$(patsubst N%,0,$(patsubst y%,1,$(patsubst n%,0,$(validate)))))

BUILD ?= 1
build := $(BUILD)
build := $(patsubst T%,1,$(patsubst F%,0,$(patsubst t%,1,$(patsubst f%,0,$(build)))))
build := $(patsubst Y%,1,$(patsubst N%,0,$(patsubst y%,1,$(patsubst n%,0,$(build)))))

### Check input directory for optional configuration to provision master.project
ifneq ($(wildcard ${INPUT}),)
    # modifications to CoreOS ignition
    ifeq ($(wildcard ${INPUT}/*),)
        box_config_custom=
    else
        box_config_custom=$(wildcard $(patsubst %/,%,${INPUT})/*)
    endif
endif

# nodify user if any custom configuration was specified
ifneq ($(box_config_custom),)
    $(info [-] Building project "${PROJECT}" with custom configuration: $(box_config_custom))
endif

### user variables
boxname?=master.${PROJECT}
boxname_config=$(boxname).config

workdir?=build.dir
boxname_workdir=$(workdir)/$(boxname)
boxname_template=$(boxname_workdir)/template

# all important filenames that are copied to output
output_names := $(boxname_config) $(boxname).id_rsa $(boxname).id_rsa.pub

### Check output directory
ifeq ($(wildcard $(patsubst %/,%,$(OUTPUT))/$(boxname)),)
    $(info [-] Using the following output path for $(boxname): $(abspath $(patsubst %/,%,$(OUTPUT))/$(boxname)))
else
    $(info [!] The output path for $(boxname) already exists (output will fail): $(abspath $(patsubst %/,%,$(OUTPUT))/$(boxname)))
endif

$(info [-] Using the following work directory: $(abspath $(workdir)))

### Inform the user of any options they've specified
ifeq ($(validate),0)
    $(info [!] User has requested to skip validation of configuration: $(boxname_config))
endif

ifeq ($(build),0)
    $(info [!] User has requested to skip building the target: $(boxname_template))
endif

### some utility macros for downloading files
DOWNLOAD := curl -L -C- --progress-bar
FETCH := curl -L -s -S
PUT := curl -L -s -S -X PUT --data-binary

ifneq ($(wildcard $(ROOTDIR)/github.token),)
GH_FETCH := ${FETCH} -H 'Authorization: token $(file <$(ROOTDIR)/github.token)'
else
GH_FETCH := ${FETCH}
endif

### static configuration
checksum_type := md5
ignition_config := $(MAKEDIR)ignition
salt_config := $(MAKEDIR)salt
salt_pillar := $(MAKEDIR)pillar
salt_patches := $(MAKEDIR)patches
tools_config := $(MAKEDIR)tools

in_github_url_format=$(MAKEDIR)github.url
github_url_format=$(file <$(in_github_url_format))

### coreos configuration
in_coreos=$(MAKEDIR)coreos.url
in_coreos_version=$(MAKEDIR)coreos.version
in_coreos_validate=$(MAKEDIR)coreos.validate.url
in_coreos_files=$(MAKEDIR)coreos.files

coreos_iso=coreos_production_iso_image.iso

# generate the install url from the environment vars
$(foreach var,$(file <$(in_coreos_version)),$(eval export $(var)))

coreos_url=$(file <$(in_coreos))
coreos_validate_url=$(file <$(in_coreos_validate))

# all files that are needed to install coreos
coreos_installer_files := $(foreach f,$(file <$(in_coreos_files)),$(workdir)/$(f))

### tools configuration
toolsdir=$(workdir)/tools
filesdir=$(workdir)/files

## acbuild
in_acbuild_repo=$(MAKEDIR)acbuild.repo
acbuild_metaurl != printf -- '$(github_url_format)' '$(file <$(in_acbuild_repo))'

# required files for acbuild
acbuild_files := $(foreach f,$(shell ${GH_FETCH} '$(acbuild_metaurl)' | jq -r '.assets[].name'),$(filesdir)/$(f))

## kelseyhightower's setup-network-environment
in_setup_network_environment_repo=$(MAKEDIR)/setup-network-environment.repo
setup_network_environment_metaurl != printf -- '$(github_url_format)' '$(file <$(in_setup_network_environment_repo))'

setup_network_environment_files := $(foreach f,$(shell ${GH_FETCH} '$(setup_network_environment_metaurl)' | jq -r '.assets[].name'),$(toolsdir)/bin/$(f))

## extra tools to include
extra_tools_files := $(foreach f,$(wildcard $(tools_config)/*),$(toolsdir)/bin/$(notdir $(f)))

## salt-bootstrap.sh installer
in_salt_bootstrap_metaurl=$(MAKEDIR)salt-bootstrap.url
in_salt_bootstrap_version=$(MAKEDIR)salt-bootstrap.version

salt_bootstrap_metaurl := '$(file <$(in_salt_bootstrap_metaurl))'
salt_bootstrap_file != ${GH_FETCH} '$(salt_bootstrap_metaurl)' | jq -r '.name | @sh'
salt_bootstrap_file_url != ${GH_FETCH} '$(salt_bootstrap_metaurl)' | jq -r '.download_url | @sh'
salt_bootstrap_version := '$(file <$(in_salt_bootstrap_version))'
salt_bootstrap_pillar_files := acbuild.sls project-name.sls

### ignition components and related variables
ignition_template := $(MAKEDIR)default.json
ignition_sysctl_files := $(wildcard $(ignition_config)/sysctl/*.conf)
ignition_users_files := $(wildcard $(ignition_config)/users/*)
ignition_network_files := $(wildcard $(ignition_config)/network/*.network)

ignition_units_names := $(foreach f,$(wildcard $(ignition_config)/units/*),$(notdir $(f)))
ignition_dropins_names := $(foreach f,$(wildcard $(ignition_config)/dropins/*),$(notdir $(f)))

### definitions for generating recipes

# output_file '$file' '$directory'
define output_file
$(2)/$(notdir $(1)): $(1)	| $(2)
	@if [ -e '$$@' ]; then \
	    printf '[!] Refusing to deploy over already existing file: %s\n' '$$@'; \
	    false; \
	fi
	@printf '[*] Copying output file to %s: %s\n' '$(2)' '$$<'
	@cp '$$<' '$$@'
endef

# json_rawfile '$source.raw' '$target.json'
define json_rawfile
$(2): $(1)	| $(patsubst %/,%,$(dir $(2)))
	@jq -Rs . '$(1)' >| '$(2)'
endef

## github

# gh_download '$target' '$url'
define gh_download
$(1):	| $(patsubst %/,%,$(dir $(1)))
	@printf '[!] Downloading %s: %s\n' '$(2)' '$$(notdir $(1))'
	$${GH_FETCH} -o '$$@' '$(2)'
endef

## CoreOS components

# coreos_download '$target' '$filename'
define coreos_download
$(1):	| $(dir $(1))
	@printf '[!] Downloading CoreOS Installer file: %s\n' '$(coreos_url)/$(2)'
	$${DOWNLOAD} -o '$$@' '$(coreos_url)/$(2)'
endef

# checksum '$filename' '$checksum' '$checksum_filename'
define checksum
$(3): $(1)
	@printf '[*] Calculating %s checksum for %s: $$@\n' '$(2)' '$$<'
	@openssl dgst -$(2) '$$<' | rev | cut -d' ' -f 1 | rev | tr -d '\r\n' >| '$$@'
endef

# coreos_tool '$target' '$source'
define coreos_tool
$(2): $(1)	| $(patsubst %/,%,$(dir $(2)))
	@printf '[!] Staging file %s in %s\n' '$(1)' '$(2)'
	@cp -f '$(1)' '$(2)'
endef

# XXX: because fuck CoreOS for breaking cloud-init right before deprecating it

# ignition_file '$contents.json' '$target.json' '$filename' '$decimal-mode'
define ignition_file
$(2): $(1)	| $(patsubst %/,%,$(dir $(2)))
	@printf '[-] Building ignition file from contents %s: %s\n' '$(1)' '$(2)'
	@jq -n --arg path '/etc/sysctl.d/$(3)' --arg mode '$(4)' --slurpfile contents '$(1)' '{ filesystem: "root", path: $$$$path, mode: $$$$mode, contents: { source: ("data:," + ($$$$contents[0] | @uri)) } }' >| '$(2)'
endef

# ignition_unit_file '$unit.service' '$source.service.json-raw' '$output.json'
define ignition_unit_file
$(3): $(2)
	@printf '[-] Creating ignition unit file %s: %s\n' '$(3)' '$(2)'
	@jq -n --arg name '$(1)' --slurpfile contents '$(2)' '{ name: $$$$name, enable: false, contents: $$$$contents[0], dropins: [] }' >| '$(3)'
endef

# ignition_unit_dropins '$target.json' '$space-separated-dropins'
define ignition_unit_dropins
$(1): $(2)
	@printf '[-] Creating ignition unit dropins %s: %s\n' '$(1)' '$(2)'
	@jq '[., inputs]' $(2) >| '$(1)'
endef

# ignition_dropin_file '$filename' '$contents' '$target.json'
define ignition_dropin_file
$(3): $(2)	| $(patsubst %/,%,$(dir $(3)))
	@jq -n --arg name '$(1)' --slurpfile contents '$(2)' '{ name: $$$$name, contents: $$$$contents[0] }' >| '$(3)'
endef

# ignition_unit '$target.json' '$unit.json' '$dropins.json'
define ignition_unit
$(1): $(2) $(3)	| $(patsubst %/,%,$(dir $(1)))
	@printf '[*] Combining ignition unit %s: %s %s\n' '$(1)' '$(2)' '$(3)'
	@jq '.dropins = (inputs // .dropins)' $$^ >| '$(1)'
endef

# ignition_unit_missing '$unit.service' '$target.json' '$dropins.json'
define ignition_unit_missing
$(2): $(3)	| $(patsubst %/,%,$(dir $(2)))
	@printf '[*] Combining (missing) ignition unit %s: %s\n' '$(2)' '$(3)'
	@jq -n --arg name '$(1)' --slurpfile dropins '$(3)' '{ name: $$$$name, dropins: $$$$dropins[0] }' >| '$(2)'
endef

# ignition_user '$target.json' '$source.json' '$list-of-json-files'
define ignition_user
$(1): $(2) $(3)	| $(patsubst %/,%,$(dir $(1)))
	@printf '[*] Combining files for user into %s: %s\n' '$(1)' '$$^'
	@jq 'reduce inputs as $$$$item (.; . * $$$$item)' '$(2)' $(3) >| '$(1)'
endef

### general utility recipes
.DEFAULT_GOAL := help

.PHONY: help
help:
	$(info [*] User requested help to build template)
	@printf '\nThe following recipes are available:\n'
	@printf '\t%s\n' 'all' 'output' 'template' 'clean' 'download'
	@printf '\nTo pre-download an individual class of files needed to build:\n'
	@printf '\t%s\n' 'download-installer' 'download-tools'
	@printf '\nTo clean any intermediary files that were needed a specific component:\n'
	@printf '\t%s\n' 'clean-output' 'clean-template' 'clean-build' 'clean-provisioning' 'clean-json' 'clean-ignition' 'clean-tools' 'clean-installer' 'clean-tools'
	@printf '\nThanks for playing!\n'

.PHONY: template
template: $(patsubst %/,%,$(OUTPUT))/$(boxname)
	@printf '[!] Wrote completed template: %s\n' '$<'

.PHONY: clean
clean: clean-ignition clean-json clean-provisioning clean-build clean-template
	@printf '[*] Successfully cleaned all intermediary files for building template\n'
	@printf '[-] Attempting to remove directory: %s\n' '$(boxname_workdir)'
	rmdir '$(boxname_workdir)'

.PHONY: all
all: download template output
	@printf '[*] Successfully built everything\n'

## downloading
.PHONY: download-installer
download-installer: $(coreos_installer_files)
	@printf '[*] Successfully downloaded CoreOS installer files\n'

.PHONY: download-tools
download-tools: $(acbuild_files) $(setup_network_environment_files) $(workdir)/$(salt_bootstrap_file)
	@printf '[*] Successfully downloaded required tools\n'

.PHONY: download
download: download-installer download-tools
	@printf '[*] Successfully downloaded all required files\n'

.PHONY: output
output: $(patsubst %/,%,$(OUTPUT))/$(boxname) $(foreach f,$(output_names),$(patsubst %/,%,$(OUTPUT))/$(f))
	@printf '[!] Sucessfully wrote output files to %s: %s\n' '$(patsubst %/,%,$(OUTPUT)))' '$^'

## cleaning up files
.PHONY: clean-output
clean-output:
	@printf '[!] Erasing template: %s\n' '$(patsubst %/,%,$(OUTPUT))/$(boxname)'
	-rm -rf '$(patsubst %/,%,$(OUTPUT))/$(boxname)'
	@printf '[!] Erasing output files from %s\n' '$(patsubst %/,%,$(OUTPUT))'
	-rm -f $(foreach f,$(output_names),'$(patsubst %/,%,$(OUTPUT))/$(f)')

.PHONY: clean-installer
clean-installer:
	@printf '[!] Removing CoreOS installer files\n'
	-rm -f $(foreach f,$(coreos_installer_files),'$(f)')
	@printf '[!] Removing CoreOS installer checksum files\n'
	-rm -f $(foreach f,$(coreos_installer_files),'$(f).$(checksum_type)')

.PHONY: clean-template
clean-template:
	@printf '[!] Erasing temporary template: %s\n' '$(boxname_template)'
	-rm -rf '$(boxname_template)'

.PHONY: clean-build
clean-build:
	@printf '[!] Erasing temporary output files from %s\n' '$(workdir)'
	-rm -f $(foreach f,$(output_names),'$(workdir)/$(f)')

.PHONY: clean-provisioning
clean-provisioning:
	@printf '[!] Erasing temporary files used for provisioning: %s %s %s\n' '$(boxname_workdir)/salt' '$(boxname_workdir)/pillar' '$(boxname_workdir)/salt-minion.conf'
	-rm -rf '$(boxname_workdir)/salt'
	-rm -rf '$(boxname_workdir)/pillar'
	-rm -f '$(boxname_workdir)/salt-minion.conf'

.PHONY: clean-tools
clean-tools:
	@printf '[!] Erasing tool %s\n' '$(workdir)/$(salt_bootstrap_file)'
	-rm -f '$(workdir)/$(salt_bootstrap_file)'
	@printf '[!] Erasing tool %s\n' '$(setup_network_environment_files)'
	-rm -f '$(setup_network_environment_files)'
	@printf '[!] Erasing temporary files from %s\n' '$(filesdir)'
	-rm -rf '$(filesdir)'
	@printf '[!] Removing tool directories %s\n' '$(toolsdir)'
	rmdir '$(toolsdir)/bin' '$(toolsdir)'

.PHONY: clean-ignition
clean-ignition:
	@printf '[!] Erasing temporary files for building ignition: %s\n' '$(boxname_workdir)/ignition-*'
	-rm -f $(foreach f,$(ignition_sysctl_files),'$(boxname_workdir)/ignition-sysctl.json-$(notdir $(f))'{,.json-raw})
	-rm -f $(foreach f,$(ignition_users_files),'$(boxname_workdir)/ignition-user.json-$(notdir $(f))')
	-rm -f $(foreach f,$(ignition_network_files),'$(boxname_workdir)/ignition-network.json-$(notdir $(f))'{,.json-raw})
	-rm -f $(foreach name,$(ignition_units_names),'$(boxname_workdir)/ignition-unit.json-$(name)'-*)
	-rm -f $(foreach name,$(ignition_units_names),'$(boxname_workdir)/ignition-unit.json-$(name)')
	-rm -f $(foreach name,$(ignition_units_names),'$(boxname_workdir)/ignition-units.json-$(name)'-*)
	-rm -f $(foreach name,$(ignition_units_names),'$(boxname_workdir)/ignition-units.json-$(name)'{,.json-raw})
	-rm -f $(foreach name,$(ignition_dropins_names),'$(boxname_workdir)/ignition-unit.json-$(name)'-* '$(boxname_workdir)/ignition-dropins.json-$(name)'-*)
	-rm -f $(foreach name,$(ignition_dropins_names),'$(boxname_workdir)/ignition-unit.json-$(name)' '$(boxname_workdir)/ignition-dropins.json-$(name)')
	@printf '[!] Erasing temporary files for ssh keys: %s\n' '$(boxname_workdir)/$(boxname).id_rsa*'
	-rm -f '$(boxname_workdir)/$(boxname).id_rsa'*
	@printf '[!] Erasing temporary files for building config: %s\n' '$(foreach name,original files units users hostname sysctl pubkey network,$(boxname_workdir)/$(boxname_config)-$(name))'
	-rm -f $(foreach name,original files units users hostname sysctl pubkey network,'$(boxname_workdir)/$(boxname_config)-$(name)')
	@printf '[!] Erasing temporary configuration files: %s %s\n' '$(boxname_workdir)/$(boxname_config)' '$(boxname_workdir)/$(boxname_config).validate'
	-rm -f '$(boxname_workdir)/$(boxname_config)' '$(boxname_workdir)/$(boxname_config).validate'

.PHONY: clean-json
clean-json:
	@printf '[!] Erasing temporary packer template: %s\n' '$(boxname).json'
	-rm -f '$(boxname_workdir)/$(boxname).json'
	@printf '[!] Erasing temporary files for building packer template: %s\n' '$(foreach suffix,base iso salt ssh tools,$(boxname_workdir)/$(boxname)-vars.json.$(suffix))'
	-rm -f '$(boxname_workdir)/$(boxname)-vars.json'{,.base,.iso,.salt,.ssh,.tools}
	-rm -f $(foreach suffix,base iso salt ssh tools,'$(boxname_workdir)/$(boxname)-vars.json.$(suffix)')
	-rm -f $(foreach f,$(coreos_installer_files),$(boxname_workdir)/$(notdir $(f)).$(checksum_type).json-raw)

### recipes for required directories
$(patsubst %/,%,$(OUTPUT)) $(workdir):
	@test -d '$@' || mkdir -p '$@'

$(boxname_workdir):	$(workdir)
	@test -d '$@' || mkdir -p '$@'

$(filesdir) $(toolsdir) $(toolsdir)/bin: $(workdir)
	@test -d '$@' || mkdir -p '$@'

### recipes for actual output of the template and its related files
$(patsubst %/,%,$(OUTPUT))/$(boxname): $(boxname_template)	| $(patsubst %/,%,$(OUTPUT))
	@printf '[*] Moving template %s: %s\n' '$<' '$(dir $@)'
	mv '$<' '$@'

### recipes that actually build the box
$(boxname_template): $(boxname_workdir)/$(boxname).json $(boxname_workdir)/$(boxname)-vars.json $(workdir)/$(boxname_config) $(coreos_installer_files)
ifneq ($(build),0)
	@printf '[!] Building template %s using var-file %s: %s\n' '$(boxname_workdir)/$(boxname).json' '$(boxname_workdir)/$(boxname)-vars.json' '$(boxname_template)'
	packer build -only=vmware-iso -var-file '$(boxname_workdir)/$(boxname)-vars.json' -var 'guest-config=$(boxname_config)' '$(boxname_workdir)/$(boxname).json'
else
	@printf '[!] Refusing to build template %s due to BUILD being set to %d\n' '$@' '$(build)'
	@printf 'packer build -only=vmware-iso -var-file %c%s%c -var %cguest-config=%s%c %c%s%c\n' "'" '$(boxname_workdir)/$(boxname)-vars.json' "'" "'" '$(boxname_config)' "'" "'" '$(boxname_workdir)/$(boxname).json' "'"
	@false
endif

# build json file containing all information about the iso
$(boxname_workdir)/$(boxname)-vars.json.iso: $(workdir)/$(coreos_iso) $(boxname_workdir)/$(coreos_iso).$(checksum_type).json-raw	| $(boxname_workdir)
	@printf '[-] Generating ISO variables for %s: %s\n' '$@' '$<'
	@jq -n --arg checksum_type '$(checksum_type)' --arg url 'file://$<' --slurpfile iso_checksum '$(boxname_workdir)/$(coreos_iso).$(checksum_type).json-raw' '{ "iso-checksum-type": $$checksum_type, "iso-url": $$url, "iso-checksum": $$iso_checksum[0] }' >| '$@'

# build json file containing all information for ssh'ing to the box
$(boxname_workdir)/$(boxname)-vars.json.ssh: $(workdir)/$(boxname).id_rsa	| $(boxname_workdir)
	@printf '[-] Generating SSH variables %s: %s\n' '$@' '$^'
	@jq -n --arg key '$<' '{ "provision-key": $$key }' >| '$@'

# build json file containing build-specific variables
$(boxname_workdir)/$(boxname)-vars.json.base:	| $(boxname_workdir)
	@printf '[-] Generating build variables: %s\n' '$@'
	@jq -n --arg name '$(boxname)' --arg input '$(workdir)' --arg output '$(boxname_template)' '{ "guest-name": $$name, "install-input": $$input, "install-output": $$output }' >| '$@'

# concatenate entire template configuration into a single .json file
$(boxname_workdir)/$(boxname)-vars.json: $(MAKEDIR)box-vars.json $(boxname_workdir)/$(boxname)-vars.json.iso $(boxname_workdir)/$(boxname)-vars.json.ssh $(boxname_workdir)/$(boxname)-vars.json.salt $(boxname_workdir)/$(boxname)-vars.json.tools $(boxname_workdir)/$(boxname)-vars.json.base
	@printf '[*] Merging build variables together into %s: %s\n' '$@' '$^'
	@jq 'reduce inputs as $$item (.; . * $$item)' $(foreach d,$^,'$(d)') >| '$@'

# grab all the specified tools into the tools directory and build a json for it
$(boxname_workdir)/$(boxname)-vars.json.tools: $(setup_network_environment_files) $(extra_tools_files)	| $(boxname_workdir)
	@printf '[-] Generating variables for miscellaneous CoreOS tools\n'
	@jq -n --arg tools '$(toolsdir)' '{ "tools-directory": $$tools }' >| '$@'

# generate necessary configuration variables for salt-stack
$(boxname_workdir)/$(boxname)-vars.json.salt: $(boxname_workdir)/salt $(boxname_workdir)/pillar $(foreach name,$(salt_bootstrap_pillar_files),$(boxname_workdir)/pillar/$(name)) $(boxname_workdir)/salt-minion.conf $(workdir)/$(salt_bootstrap_file) $(salt_patches)
	@printf '[-] Generating bootstrap variables for salt-bootstrap: %s\n' '$^'
	@jq -n --arg configuration '$(boxname_workdir)/salt-minion.conf' --arg installer '$(workdir)/$(salt_bootstrap_file)' --arg saltdir '$(boxname_workdir)/salt' --arg pillardir '$(boxname_workdir)/pillar' --arg version '$(salt_bootstrap_version)' --arg patchdir '$(salt_patches)' '{ "salt-bootstrap-config": $$configuration, "salt-bootstrap-installer": $$installer, "salt-bootstrap-files": $$saltdir, "salt-bootstrap-pillar": $$pillardir, "salt-bootstrap-version": $$version, "salt-bootstrap-patches": $$patchdir }' >| '$@'

# concatenate json template into a single .json file together with plugins
$(boxname_workdir)/$(boxname).json: $(MAKEDIR)box.json $(MAKEDIR)provision.json 	| $(boxname_workdir)
	@printf '[*] Merging box with enabled plugins into %s: %s\n' '$@' '$^'
	@jq 'reduce inputs as $$item (.; . * $$item)' $(foreach d,$^,'$(d)') >| '$@'

# generate ssh public/private key
$(workdir)/$(boxname).id_rsa $(workdir)/$(boxname).id_rsa.pub:	| $(workdir)
	@printf '[-] Generating public/private keypair: %s\n' '$@'
	ssh-keygen -q -t rsa -C 'core@$(boxname)' -f '$(workdir)/$(boxname).id_rsa' -N ''

### recipes for building the bootstrap configuration

## recipes for validating the configuration
$(boxname_workdir)/$(boxname_config).validate: $(boxname_workdir)/$(boxname_config)
ifneq ($(validate),0)
	@printf '[!] Validating ignition configuration %s: %s\n' '$<' '$(coreos_validate_url)'
	${PUT} '@$<' '$(coreos_validate_url)' >| '$@'
else
	@printf '[!] Skipping the validation for the ignition configuration: %s\n' '$<'
	@jq -n . >| '$@'
endif

$(workdir)/$(boxname_config): $(boxname_workdir)/$(boxname_config).validate $(boxname_workdir)/$(boxname_config)	| $(workdir)
	@jq '(.result // []) | .[] | select(.kind == "warning") | [(.line | tostring), (.column | tostring), .message] | @sh' '$<' | while read y x message; do \
		printf 'Validation Warning: (line %d, col %d) %s\n' $$y $$x "$$message" 1>&2; \
	done
	@jq '(.result // []) | .[] | select(.kind == "error") | .message | @sh' '$<' | while read message; do \
		printf 'Validation Error: %s\n' "$$message" 1>&2; \
		exit 1; \
	done
	@printf '[*] Successfully validated ignition configuration: %s\n' '$@'
	@cp -f '$(boxname_workdir)/$(boxname_config)' '$@'

# combine the result ignition json with any other configurations
$(boxname_workdir)/$(boxname_config): $(boxname_workdir)/$(boxname_config)-original $(foreach opt,$(box_config_custom),$(opt))
	@printf '[*] Merging the ignition configuration %s using the result json and extra configurations: %s\n' '$@' '$^'
	@jq 'reduce inputs as $$item (.; . * $$item)' $^ >| '$@'

# combine all ignition jsons into the template
$(boxname_workdir)/$(boxname_config)-original: $(ignition_template) $(boxname_workdir)/$(boxname_config)-files $(boxname_workdir)/$(boxname_config)-units $(boxname_workdir)/$(boxname_config)-users $(boxname_workdir)/$(boxname_config)-network
	@printf '[*] Making ignition configuration with template %s: %s\n' '$<' '$@'
	@jq --slurpfile files '$(boxname_workdir)/$(boxname_config)-files' --slurpfile units '$(boxname_workdir)/$(boxname_config)-units' --slurpfile users '$(boxname_workdir)/$(boxname_config)-users' --slurpfile networks '$(boxname_workdir)/$(boxname_config)-network' '.storage.files |= $$files[0] | .systemd.units |= $$units[0] | .passwd.users |= $$users[0] | .networkd.units |= $$networks[0]' '$(ignition_template)' >| '$@'

# set the hostname using $(boxname) with the mode 420 (0644 in octal)
$(boxname_workdir)/$(boxname_config)-hostname:	| $(boxname_workdir)
	@printf '[-] Building the ignition configuration file for the hostname: %s\n' '$(boxname)'
	@jq -n --arg content '$(boxname)' '[{ filesystem: "root", path: "/etc/hostname", mode: 420, contents: { source: ("data:," + ($$content | @uri)) } }]' >| '$@'

# bootstrap for ignition/sysctl directory
$(boxname_workdir)/$(boxname_config)-sysctl: $(foreach f,$(ignition_sysctl_files),$(boxname_workdir)/ignition-sysctl.json-$(notdir $(f)))
	@printf '[*] Merging all ignition sysctl files into %s: %s\n' '$@' '$^'
	@jq '[., inputs]' $^ >| '$@'

# combine all ignition file jsons into a single one
$(boxname_workdir)/$(boxname_config)-files: $(boxname_workdir)/$(boxname_config)-hostname $(boxname_workdir)/$(boxname_config)-sysctl
	@printf '[*] Merging the ignition file section into %s: %s\n' '$@' '$^'
	@jq '. + inputs' $^ >| '$@'

# combining for ignition/units and ignition/dropins
$(boxname_workdir)/$(boxname_config)-units: $(foreach name,$(ignition_units_names),$(boxname_workdir)/ignition-unit.json-$(name)) $(foreach name,$(ignition_dropins_names),$(boxname_workdir)/ignition-unit.json-$(name))
	@printf '[*] Merging the ignition unit section into %s: %s\n' '$@' '$^'
	@jq '[., inputs]' $^ >| '$@'

# generate a json containing the sshAuthorizedKeys field in an object
$(boxname_workdir)/$(boxname_config)-pubkey: $(boxname_workdir)/$(boxname).id_rsa.pub.json-raw
	@printf '[-] Generating a json with the public key in %s: %s\n' '$@' '$^'
	@jq -n --slurpfile pubkey '$<' '{ sshAuthorizedKeys: [$$pubkey[0] | rtrimstr("\n")] }' >| '$@'

# combine all joined user objects into a single list
$(boxname_workdir)/$(boxname_config)-users: $(foreach f,$(ignition_users_files),$(boxname_workdir)/ignition-user.json-$(notdir $(f)))
	@printf '[*] Merging the ignition user section into %s: %s\n' '$@' '$^'
	@jq '[., inputs]' $^ >| '$@'

# combine all joined network dropins into a single list
$(boxname_workdir)/$(boxname_config)-network: $(foreach f,$(ignition_network_files),$(boxname_workdir)/ignition-network.json-$(notdir $(f)))
	@printf '[*] Merging all ignition network files into %s: %s\n' '$@' '$^'
	@jq '[., inputs]' $^ >| '$@'

### recipes for provisioning with saltstack
$(boxname_workdir)/salt $(boxname_workdir)/pillar: $(salt_config) $(salt_pillar) $(acbuild_files)	| $(boxname_workdir)
	@printf '[*] Copying states for bootstrapping %s: %s\n' '$(boxname)' '$(boxname_workdir)/salt'
	@cp -r '$(salt_config)' '$(boxname_workdir)'/
	@printf '[*] Copying bootstrap pillar: %s\n' '$(boxname_workdir)/pillar'
	@cp -r '$(salt_pillar)' '$(boxname_workdir)'/
	@printf '[*] Copying extra files from %s into states: %s\n' '$(filesdir)' '$(boxname_workdir)/salt'
	@cp -r '$(filesdir)' '$(boxname_workdir)/salt'/

$(boxname_workdir)/salt-minion.conf: $(MAKEDIR)salt-minion.conf	| $(boxname_workdir)
	@printf '[*] Copying in bootstrap configuration: %s\n' '$@'
	@cp '$<' '$@'

$(boxname_workdir)/pillar/acbuild.sls: $(acbuild_files)	| $(boxname_workdir)/pillar
	@printf '[-] Generating default pillar configuration: %s\n' '$^'
	@printf -- '- Source: %s\n  Algo: %s\n  Hash: %s\n\n' $(foreach f,$^,'$(shell basename $(f))' '$(checksum_type)' "$(shell openssl dgst -$(checksum_type) '$(f)' | rev | cut -d' ' -f1 | rev)") >| '$@'

$(boxname_workdir)/pillar/project-name.sls:	| $(boxname_workdir)/pillar
	@printf '[-] Writing project name into pillar configuration: %s\n' '$@'
	@printf -- '%s\n' '$(PROJECT)' >| '$@'

### recipes that are automatically generated

# output results into the output directory
$(foreach f,$(output_names),$(eval $(call output_file,$(workdir)/$(f),$(patsubst %/,%,$(OUTPUT)))))

## coreos installation and provisioning

# download the coreos installer
$(foreach name,$(file <$(in_coreos_files)),$(eval $(call coreos_download,$(workdir)/$(name),$(name))))

# generate hashes for downloaded files
$(foreach f,$(coreos_installer_files),$(eval $(call checksum,$(f),$(checksum_type),$(f).$(checksum_type))))
$(foreach f,$(coreos_installer_files),$(eval $(call json_rawfile,$(f).$(checksum_type),$(boxname_workdir)/$(notdir $(f)).$(checksum_type).json-raw)))

# fetch the acbuild tool
$(foreach u,$(shell ${GH_FETCH} '$(acbuild_metaurl)' | jq -r '.assets[].browser_download_url'),$(eval $(call gh_download,$(filesdir)/$(notdir $(u)),$(u))))

# fetch the setup-network-environment tool
$(foreach u,$(shell ${GH_FETCH} '$(setup_network_environment_metaurl)' | jq -r '.assets[].browser_download_url'),$(eval $(call gh_download,$(toolsdir)/bin/$(notdir $(u)),$(u))))

# transfer any miscellaneous tools
$(foreach f,$(wildcard $(tools_config)/*),$(eval $(call coreos_tool,$(f),$(toolsdir)/bin/$(notdir $(f)))))

# download the saltstack-bootstrap installer
$(eval $(call gh_download,$(workdir)/$(salt_bootstrap_file),$(salt_bootstrap_file_url)))

## ignition components

# making the ignition sysctl list (the permission 0644 is 420 in decimal)
$(foreach f,$(ignition_sysctl_files),$(eval $(call ignition_file,$(boxname_workdir)/ignition-sysctl.json-$(notdir $(f)).json-raw,$(boxname_workdir)/ignition-sysctl.json-$(notdir $(f)),$(notdir $(f)),420)))

# making the ignition network list (the permission 0644 is 420 in decimal)
$(foreach f,$(ignition_network_files),$(eval $(call ignition_dropin_file,$(notdir $(f)),$(boxname_workdir)/ignition-network.json-$(notdir $(f)).json-raw,$(boxname_workdir)/ignition-network.json-$(notdir $(f)))))

# making the ignition units list
$(foreach name,$(ignition_units_names),$(eval $(call ignition_unit_file,$(name),$(boxname_workdir)/ignition-units.json-$(name).json-raw,$(boxname_workdir)/ignition-units.json-$(name))))

# making the ignition unit dropins files
$(foreach name,$(ignition_dropins_names),$(foreach f,$(wildcard $(ignition_config)/dropins/$(name)/*.conf),$(eval $(call ignition_dropin_file,$(notdir $(f)),$(boxname_workdir)/ignition-dropins.json-$(name)-$(notdir $(f)).json-raw,$(boxname_workdir)/ignition-dropins.json-$(name)-$(notdir $(f))))))

# making the ignition unit dropins list
$(foreach name,$(ignition_dropins_names),$(eval $(call ignition_unit_dropins,$(boxname_workdir)/ignition-dropins.json-$(name),$(foreach f,$(wildcard $(ignition_config)/dropins/$(name)/*.conf),$(boxname_workdir)/ignition-dropins.json-$(name)-$(notdir $(f))))))

# recipes that compose the unit with all of its dropins
$(foreach name,$(filter $(ignition_dropins_names),$(ignition_units_names)),$(eval $(call ignition_unit,$(boxname_workdir)/ignition-unit.json-$(name),$(boxname_workdir)/ignition-units.json-$(name),$(boxname_workdir)/ignition-dropins.json-$(name))))

# recipes that compose the unit without any dropins
$(foreach name,$(filter-out $(ignition_dropins_names),$(ignition_units_names)),$(eval $(call ignition_unit,$(boxname_workdir)/ignition-unit.json-$(name),$(boxname_workdir)/ignition-units.json-$(name))))

# recipes that compose a missing unit with all dropins
$(foreach name,$(filter-out $(ignition_units_names),$(ignition_dropins_names)),$(eval $(call ignition_unit_missing,$(name),$(boxname_workdir)/ignition-unit.json-$(name),$(boxname_workdir)/ignition-dropins.json-$(name))))

# combining each user with the sshAuthorizedKeys (FIXME: allow unique ssh keys per-user)
$(foreach f,$(ignition_users_files),$(eval $(call ignition_user,$(boxname_workdir)/ignition-user.json-$(notdir $(f)),$(f),$(boxname_workdir)/$(boxname_config)-pubkey)))

# raw ignition_sysctl_files contents
$(foreach f,$(ignition_sysctl_files),$(eval $(call json_rawfile,$(f),$(boxname_workdir)/ignition-sysctl.json-$(notdir $(f)).json-raw)))

# raw ignition_network_files contents
$(foreach f,$(ignition_network_files),$(eval $(call json_rawfile,$(f),$(boxname_workdir)/ignition-network.json-$(notdir $(f)).json-raw)))

# raw ignition_unit_files contents
$(foreach name,$(ignition_units_names),$(eval $(call json_rawfile,$(ignition_config)/units/$(name),$(boxname_workdir)/ignition-units.json-$(name).json-raw)))

# raw ignition_dropins_names contents
$(foreach name,$(ignition_dropins_names),$(foreach f,$(wildcard $(ignition_config)/dropins/$(name)/*.conf),$(eval $(call json_rawfile,$(f),$(boxname_workdir)/ignition-dropins.json-$(name)-$(notdir $(f)).json-raw))))

# raw ssh pubkey contents
$(eval $(call json_rawfile,$(workdir)/$(boxname).id_rsa.pub,$(boxname_workdir)/$(boxname).id_rsa.pub.json-raw))
