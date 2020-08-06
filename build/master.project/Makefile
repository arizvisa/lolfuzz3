###############################################################################
# master.project (Makefile)
#
# This file contains the main recipes that are used to build a template for
# the "master" box for a particular project. Building of the template results
# in a deployable, cloneable template with an instance of SaltStack provisioned
# for the target project. After building of the template, the user can then
# authenticate to the template as the "core" user with the provided SSH
# keypair. The user is then able to design the states required for the project
# using the contents of the service directory.
###############################################################################

MAKEDIR := $(dir $(firstword $(MAKEFILE_LIST)))
ROOTDIR := $(realpath $(MAKEDIR)../..)

# Include necessary utility macros
include $(MAKEDIR)Makefile.platform
include $(MAKEDIR)Makefile.inc

### Parameters that the user can supply
BUILDDIR?=$(ROOTDIR)/build.dir
OUTPUT?=$(ROOTDIR)

### List of options that the user can provide to influence the build
include $(MAKEDIR)Makefile.config

### Internal variables that are used for building

# Output directory to write the template into
outdir := $(patsubst %/,%,$(OUTPUT))/$(project_output_path)

# Intermediary work directory to stage required files into
workdir?=$(BUILDDIR)

### Box-specific internal variables used for building the box

# Project variable used to name the current project
project := $(call lc,${PROJECT})

# Validate the project variable since it determines our working directories
ifeq ($(project),)
    ifeq ($(wildcard $(outdir)/$(project_filename)),)
        # If the file doesn't exist, then use a default
        project := null
        $(warning No PROJECT was specified. Using project name "$(project)" until failure.)
    else
        # Extract the name straight out of the file in the root of the repo
        project := $(file <$(outdir)/$(project_filename))
        $(info [-] Found already existing project name: $(project))
    endif

else
    # If the user already assigned it, then just use it
    $(info [-] Using project name: $(project))
endif

# Figure out the name of the box using the project name
boxname?=master.$(project)

# Intermediary box working directories for staging build-specific files in
boxname_workdir=$(workdir)/$(boxname)
boxname_template=$(boxname_workdir)/template

# List of static files that are required for deployment (does not include template)
output_project_name := $(project_filename)
output_identity_file := $(boxname).id
output_config := $(boxname).config
output_keypair_pub := $(boxname).id_rsa.pub
output_keypair_prv := $(boxname).id_rsa

# Paths containing the service directory to use for deployment
repository_serve := $(shell git rev-parse -q --verify $(project_serve_branch))
project_serve := $(ROOTDIR)/$(project_serve_root)/$(project).project
branch_serve := $(ROOTDIR)/$(project_serve_path)

### Check parameters specified by the user

## Validation option
VALIDATE ?= 1
validate := $(VALIDATE)
validate := $(patsubst T%,1,$(patsubst F%,0,$(patsubst t%,1,$(patsubst f%,0,$(validate)))))
validate := $(patsubst Y%,1,$(patsubst N%,0,$(patsubst y%,1,$(patsubst n%,0,$(validate)))))

ifeq ($(validate),0)
    $(warning User has requested to skip validation of configuration: $(boxname).config)
endif

## Build option
BUILD ?= 1
build := $(BUILD)
build := $(patsubst T%,1,$(patsubst F%,0,$(patsubst t%,1,$(patsubst f%,0,$(build)))))
build := $(patsubst Y%,1,$(patsubst N%,0,$(patsubst y%,1,$(patsubst n%,0,$(build)))))

ifeq ($(build),0)
    $(warning User has requested to skip building the target: $(boxname_template))
endif

## Headless option
HEADLESS ?= 0
headless := $(HEADLESS)
headless := $(patsubst T%,1,$(patsubst F%,0,$(patsubst t%,1,$(patsubst f%,0,$(headless)))))
headless := $(patsubst Y%,1,$(patsubst N%,0,$(patsubst y%,1,$(patsubst n%,0,$(headless)))))

ifeq ($(headless),1)
    $(warning User has requested to build the target without the graphical user interface)
    headless_option := true
else
    headless_option := false
endif

## Debug option
DEBUG ?= 0
debug := $(DEBUG)
debug := $(patsubst T%,1,$(patsubst F%,0,$(patsubst t%,1,$(patsubst f%,0,$(debug)))))
debug := $(patsubst Y%,1,$(patsubst N%,0,$(patsubst y%,1,$(patsubst n%,0,$(debug)))))

ifeq ($(debug),1)
    $(warning User has enabled the debug option. Packer will not remove template on failure.)
    options := $(options) on-error=ask
else
    options := $(options) on-error=cleanup
endif

## Available platform types to build the template for
platform = $(subst $(comma),$(space),$(PLATFORM))

ifneq ($(platform),)
$(info [-] User has specified the following template type(s): $(platform))
options := $(options) only='$(subst $(space),$(comma),$(strip $(foreach name,$(filter-out qemu,$(platform)),$(name)-iso) $(foreach name,$(filter qemu,$(platform)),$(name))))'
else
$(warning User has specified no template types. Assuming all platforms are available.)
$(info [-] To target a specific build platform, set the PLATFORM variable to one or more of the following: vmware, virtualbox, parallels, hyperv, qemu)
endif

### Check for any default service configurations included in the repository

## If SERVE was not specified, then we'll do some searching for it
ifeq ($(SERVE),)

    # First check the project configuration
    ifneq ($(wildcard $(project_serve)/*),)
        SERVE=$(project_serve)
        $(info [*] Found default service configuration for $(project): $(SERVE))
    endif

    # Next check for the repository configuration
    ifneq ($(wildcard $(branch_serve)/*),)
        SERVE=$(branch_serve)
        $(info [*] Found default service configuration for branch: $(SERVE))
    endif
endif

## Use the specified or detected service configuration

# Prioritize a particular branch if one was found in the repository. The
# $(boxname_workdir)/serve target is special in that it will actually clone
# the commit from $(repository_serve) in order to deploy into the master.
ifneq ($(repository_serve),)
    $(info [-] Using service configuration from commit: $(repository_serve))
    serve := $(boxname_workdir)/serve
else
    # If SERVE was not defined anywhere, then use an empty directory. Due to the
    # make_directory dependency on $(serve), this will get automatically created.
    ifndef SERVE
        serve := $(boxname_workdir)/empty

    # Otherwise, this might just be a hardcoded path so we'll just verify it
    else
        ifneq ($(wildcard $(SERVE)/*),)
            $(info [-] Using service configuration: $(abspath $(patsubst %/,%,$(SERVE))))
            serve := $(patsubst %/,%,$(SERVE))

        # Nothing was found, so we'll just error out here
        else
            $(error No service configuration found in path: $(abspath (patsubst %/,%,$(SERVE))))
        endif
    endif
endif

### Notify the user what directories we're going to write files to
$(info [-] Using the work directory: $(abspath $(workdir)))

ifeq ($(wildcard $(outdir)/$(boxname)),)
    $(info [-] Using the output path for $(boxname): $(abspath $(outdir)/$(boxname)))
else
    $(warning The output path for $(boxname) already exists (builder will refuse to overwrite during deployment): $(abspath $(outdir)/$(boxname)))
endif

### Include various Makefile components containing configurations and macros
include $(MAKEDIR)Makefile.coreos
include $(MAKEDIR)Makefile.github
include $(MAKEDIR)Makefile.ignition
include $(MAKEDIR)Makefile.provision
include $(MAKEDIR)Makefile.salt

### General recipes used during building
.DEFAULT_GOAL := help

FORCE:

## Regular recipes that the user can use
.PHONY: help
help:
	$(info [*] User requested help for the makefile)
	@printf '\nThe following recipes are available:\n'
	@printf '\t%s\n' 'all' 'output' 'template' 'clean' 'download'
	@printf '\nTo pre-download an individual class of files needed for the build:\n'
	@printf '\t%s\n' 'download-installer' 'download-tools'
	@printf '\nTo clean up any intermediary files that were needed for building a specific component:\n'
	@printf '\t%s\n' 'clean-output' 'clean-template' 'clean-build' 'clean-provisioning' 'clean-json' 'clean-ignition' 'clean-tools' 'clean-installer' 'clean-tools'

	@printf '\nParameters that are available:\n'
	@printf '\tPROJECT: (mandatory) Name of the project (also used as the cluster%cs domain)\n' "'"
	@printf '\tPLATFORM: Virtualization platform(s) to target the template towards (vmware, virtualbox, qemu, parallels, hyperv).\n'
	@printf '\tHEADLESS: (default false) Specify whether the build should be headless (no gui).\n'
	@printf '\tOUTPUT: (default /template) Path to deploy the template, its config, and auth keypair to\n'
	@printf '\tSERVE: Path of initial service directory that is deployed to the template after installation of salt\n'
	@printf '\tBUILDDIR: (default /build.dir) Path containing intermediary files for building template\n'
	@printf '\tBUILD: (default true) Whether to actually build the template, or to just generate the config\n'
	@printf '\tVALIDATE: (default true) Whether to validate the config via "%s"\n' "https://coreos.com/validate"
	@printf '\tDEBUG: (default false) Emit more logging, and ask the user before unregistering (and removing) the template\n'

	@printf '\nThanks for playing!\n'

.PHONY: template
template: $(foreach suffix,$(platform),$(outdir)/$(boxname)-$(suffix))
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
download-installer: $(coreos_installer_files) $(foreach f,$(filter %.DIGESTS,$(coreos_installer_files)),$(patsubst %.DIGESTS,%.verified,$(f)))
	@printf '[*] Successfully downloaded CoreOS installer files\n'

.PHONY: download-tools
download-tools: $(acbuild_files) $(workdir)/$(salt_bootstrap_file) $(foreach f,$(setup_network_environment_files),$(toolsdir)/libexec/$(f))
	@printf '[*] Successfully downloaded required tools\n'

.PHONY: download
download: download-installer download-tools
	@printf '[*] Successfully downloaded all required files\n'

.PHONY: output
output: $(foreach suffix,$(platform),$(outdir)/$(boxname)-$(suffix))
	@printf '[*] Sucessfully wrote output files to %s: %s\n' '$(outdir)' '$^'

## cleaning up files
.PHONY: clean-output
clean-output:
	@printf '[*] Erasing template: %s\n' $(foreach suffix,vmware virtualbox qemu parallels hyperv,'$(outdir)/$(boxname)-$(suffix)')
	-rm -rf $(foreach suffix,vmware virtualbox qemu parallels hyperv,'$(outdir)/$(boxname)-$(suffix)')
	@printf '[*] Erasing output files from %s\n' '$(outdir)'
	-rm -f $(foreach f,$(output_identity_file),'$(outdir)/$(f)')
	-rm -f $(foreach f,$(output_config),'$(outdir)/$(f)')

.PHONY: clean-installer
clean-installer:
	@printf '[*] Removing CoreOS installer files\n'
	-rm -f $(foreach f,$(coreos_installer_files),'$(f)')
	@printf '[*] Removing CoreOS installer checksum files\n'
	-rm -f $(foreach f,$(coreos_installer_files),'$(f).$(checksum_type)')

.PHONY: clean-template
clean-template:
	@printf '[*] Erasing temporary template: %s\n' '$(boxname_template)'
	-rm -rf $(foreach suffix,vmware virtualbox qemu parallels hyperv,'$(boxname_template)-$(suffix)')

.PHONY: clean-build
clean-build:
	@printf '[*] Erasing temporary output files from %s\n' '$(workdir)'
	-rm -f $(foreach f,$(output_config),'$(workdir)/$(f)')

.PHONY: clean-provisioning
clean-provisioning:
	@printf '[*] Erasing temporary files used for provisioning: %s %s %s\n' '$(boxname_workdir)/salt' '$(boxname_workdir)/pillar' '$(boxname_workdir)/salt-minion.conf'
	-rm -rf '$(boxname_workdir)/salt'
	-rm -rf '$(boxname_workdir)/pillar'
	-rm -f '$(boxname_workdir)/salt-minion.conf'
	-rm -rf '$(boxname_workdir)/serve' '$(boxname_workdir)/serve.tar' '$(boxname_workdir)/empty'

.PHONY: clean-tools
clean-tools:
	@printf '[*] Erasing tool %s\n' '$(workdir)/$(salt_bootstrap_file)'
	-rm -f '$(workdir)/$(salt_bootstrap_file)'
	@printf '[*] Erasing tool %s\n' '$(foreach f,$(setup_network_environment_files),$(toolsdir)/libexec/$(f))'
	-rm -f $(foreach f,$(setup_network_environment_files),'$(toolsdir)/libexec/$(f)')
	@printf '[*] Erasing temporary files from %s\n' '$(filesdir)'
	-rm -rf '$(filesdir)'
	@printf '[*] Removing tool directories %s\n' '$(toolsdir)'
	rmdir '$(toolsdir)/bin' '$(toolsdir)'

.PHONY: clean-ignition
clean-ignition:
	@printf '[*] Erasing temporary files for building ignition: %s\n' '$(boxname_workdir)/ignition-*'
	-rm -f $(foreach f,$(ignition_sysctl_files),'$(boxname_workdir)/ignition-sysctl.json-$(notdir $(f))'{,.json-raw})
	-rm -f $(foreach f,$(ignition_users_files),'$(boxname_workdir)/ignition-user.json-$(notdir $(f))')
	-rm -f $(foreach f,$(ignition_network_files),'$(boxname_workdir)/ignition-network.json-$(notdir $(f))'{,.json-raw})
	-rm -f $(foreach name,$(ignition_units_names),'$(boxname_workdir)/ignition-unit.json-$(name)'-*)
	-rm -f $(foreach name,$(ignition_units_names),'$(boxname_workdir)/ignition-unit.json-$(name)')
	-rm -f $(foreach name,$(ignition_units_names),'$(boxname_workdir)/ignition-units.json-$(name)'-*)
	-rm -f $(foreach name,$(ignition_units_names),'$(boxname_workdir)/ignition-units.json-$(name)'{,.json-raw})
	-rm -f $(foreach name,$(ignition_dropins_names),'$(boxname_workdir)/ignition-unit.json-$(name)'-* '$(boxname_workdir)/ignition-dropins.json-$(name)'-*)
	-rm -f $(foreach name,$(ignition_dropins_names),'$(boxname_workdir)/ignition-unit.json-$(name)' '$(boxname_workdir)/ignition-dropins.json-$(name)')
	@printf '[*] Erasing temporary files for ignition rootfs: %s\n' '$(boxname_workdir)/rootfs'
	-rm -f $(foreach name,$(ignition_root_files),'$(boxname_workdir)/rootfs/$(name)'{,.json-raw})
	-rm -rf '$(boxname_workdir)/rootfs'
	@printf '[*] Erasing temporary files for ssh keys: %s\n' '$(foreach name,$(boxname).id_rsa.pub.json-raw,$(boxname_workdir)/$(name))'
	-rm -f '$(foreach name,$(boxname).id_rsa.pub.json-raw,$(boxname_workdir)/$(name))'
	@printf '[*] Erasing temporary files for building config: %s\n' '$(foreach name,original files units users hostname sysctl pubkey network rootfs,$(boxname_workdir)/$(boxname).config-$(name))'
	-rm -f $(foreach name,original files units users identifier sysctl pubkey network rootfs,'$(boxname_workdir)/$(boxname).config-$(name)')
	@printf '[*] Erasing temporary configuration files: %s %s\n' '$(boxname_workdir)/$(boxname).config.ok' '$(boxname_workdir)/$(boxname).config.validate'
	-rm -f '$(boxname_workdir)/$(boxname).config.ok' '$(boxname_workdir)/$(boxname).config.validate'
	@printf '[*] Erasing identification files: %s %s\n' '$(boxname_workdir)/ignition-id.json' '$(boxname_workdir)/ignition-id.json-raw'
	-rm -f '$(boxname_workdir)/ignition-id.json' '$(boxname_workdir)/ignition-id.json-raw'
	@printf '[*] Erasing hostname files: %s %s %s\n' '$(boxname_workdir)/$(boxname).name.antinewline' '$(boxname_workdir)/ignition-hostname.json' '$(boxname_workdir)/ignition-hostname.json-raw'
	-rm -f '$(boxname_workdir)/$(boxname).name.antinewline' '$(boxname_workdir)/ignition-hostname.json' '$(boxname_workdir)/ignition-hostname.json-raw'

.PHONY: clean-json
clean-json:
	@printf '[*] Erasing temporary packer template: %s\n' '$(boxname).json'
	-rm -f '$(boxname_workdir)/$(boxname).json'
	@printf '[*] Erasing identification files: %s %s\n' '$(boxname_workdir)/$(boxname).id.antinewline' '$(boxname_workdir)/$(boxname).id.json-raw'
	-rm -f '$(boxname_workdir)/$(boxname).id.antinewline' '$(boxname_workdir)/$(boxname).id.json-raw'
	@printf '[*] Erasing project files: %s %s\n' '$(boxname_workdir)/$(boxname).name' '$(boxname_workdir)/$(project_filename).antinewline'
	-rm -f '$(boxname_workdir)/$(boxname).name' '$(boxname_workdir)/$(project_filename).antinewline'
	@printf '[*] Erasing temporary files for building packer template: %s\n' '$(foreach suffix,base iso salt ssh tools,$(boxname_workdir)/$(boxname)-vars.json.$(suffix))'
	-rm -f '$(boxname_workdir)/$(boxname)-vars.json'{,.base,.iso,.salt,.ssh,.tools}
	-rm -f $(foreach suffix,base iso salt ssh tools,'$(boxname_workdir)/$(boxname)-vars.json.$(suffix)')
	-rm -f $(foreach f,$(coreos_installer_files),$(boxname_workdir)/$(notdir $(f)).$(checksum_type).json-raw)

### Directory recipes for building any required directories
$(outdir) $(workdir):
	@test -d '$@' || mkdir -p '$@'

$(filesdir) $(toolsdir) $(toolsdir)/bin $(toolsdir)/libexec $(toolsdir)/sbin: $(workdir)
	@test -d '$@' || mkdir -p '$@'

$(eval $(call make_directory,$(boxname_workdir),$(workdir)))
$(eval $(call make_directory,$(boxname_workdir)/empty,$(boxname_workdir)))

### Output recipes for performing tasks after building of the template
define output_template
$$(outdir)/$$(boxname)-$(1): $$(boxname_template)-$(1)	| $$(outdir)
	$$(call verify_expression_not,$$(wildcard $$@),Refusing to deploy $$< over already existing file: $$@)
	@printf '[*] Moving template %s: %s\n' '$$<' '$$(dir $$@)'
	mv '$$<' '$$@'
	@printf '[*] Leaving an empty directory as a placeholder: %s\n' '$$<'
	mkdir -p '$$<'
endef
$(foreach suffix,$(platform),$(eval $(call output_template,$(suffix))))

$(outdir)/$(output_project_name):
	@printf '[*] Writing project name to file: %s\n' '$@'
	@echo '$(project)' >| '$@'

### Recipe for using the "serve" branch
$(boxname_workdir)/serve:	| $(boxname_workdir)
	@printf '[!] Cloning branch %s from repository into target: %s\n' '$(project_serve_branch)' '$@'
	git -C '$(ROOTDIR)' clone --dissociate -n --single-branch --branch '$(project_serve_branch)' . '$@'
	@printf '[!] Checking out commit %s in target: %s\n' '$(repository_serve)' '$@'
	git -C '$@' checkout -B master '$(repository_serve)'

$(boxname_workdir)/serve.tar: $(serve)	| $(boxname_workdir)
	@printf '[-] Archiving the service directory: %s\n' '$<'
	$(GTAR) -C '$<' -cpf '$@' .

### Box recipes required to build the template
$(foreach suffix,$(platform),$(boxname_template)-$(suffix)): $(boxname_workdir)/$(boxname).config.ok $(boxname_workdir)/$(boxname).json $(boxname_workdir)/$(boxname)-vars.json $(outdir)/$(output_config) $(coreos_installer_files) $(boxname_workdir)/serve.tar
ifneq ($(build),0)
	@printf '[!] Building template %s using var-file %s: %s\n' '$(boxname_workdir)/$(boxname).json' '$(boxname_workdir)/$(boxname)-vars.json' '$(boxname_template)'
	packer build $(foreach opt,$(options),-$(opt)) -var-file '$(boxname_workdir)/$(boxname)-vars.json' -var 'headless=$(headless_option)' -var 'guest-config=$(outdir)/$(output_config)' -var 'serve-directory-archive=$(boxname_workdir)/serve.tar' '$(boxname_workdir)/$(boxname).json'
else
	@printf '[!] Refusing to build template %s due to BUILD being set to %d\n' '$@' '$(build)'
	@printf 'packer build %s -var-file %c%s%c -var %cheadless=%s%c -var %cguest-config=%s%c -var %cserve-directory-archive=%s%c %c%s%c\n' '$(foreach opt,$(options),-$(opt))' "'" '$(boxname_workdir)/$(boxname)-vars.json' "'" "'" '$(headless_option)' "'" "'" '$(outdir)/$(output_config)' "'" "'" '$(boxname_workdir)/serve.tar' "'" "'" '$(boxname_workdir)/$(boxname).json' "'"
	@false
endif

# Build json file containing all information about the iso
$(boxname_workdir)/$(boxname)-vars.json.iso: $(workdir)/$(coreos_iso) $(boxname_workdir)/$(coreos_iso).$(checksum_type).json-raw $(foreach req,$(coreos_required),$(workdir)/$(req).verified) 	| $(boxname_workdir)
	@printf '[-] Generating iso variables for %s: %s\n' '$@' '$<'
	@jq -n --arg checksum_type '$(checksum_type)' --arg url '$<' --slurpfile iso_checksum '$(boxname_workdir)/$(coreos_iso).$(checksum_type).json-raw' '{ "iso-checksum-type": $$checksum_type, "iso-url": $$url, "iso-checksum": $$iso_checksum[0] }' >| '$@'

# Build json file containing all information for ssh'ing to the box
$(boxname_workdir)/$(boxname)-vars.json.ssh: $(outdir)/$(output_keypair_prv)	| $(boxname_workdir)
	@printf '[-] Generating SSH variables %s: %s\n' '$@' '$^'
	@jq -n --arg key '$<' '{ "provision-key": $$key }' >| '$@'

# Build json file containing any build-specific variables
$(boxname_workdir)/$(boxname)-vars.json.base: $(boxname_workdir)/$(boxname).id.json-raw	| $(boxname_workdir)
	@printf '[-] Generating build variables: %s\n' '$@'
	@jq -n --arg name '$(boxname)' --slurpfile id '$<' --arg input '$(workdir)' --arg output '$(boxname_template)' '{ "guest-name": $$name, "guest-id": $$id | join(""), "install-input": $$input, "install-output": $$output }' >| '$@'

# Concatenate entire template configuration into a single .json file
$(boxname_workdir)/$(boxname)-vars.json: $(MAKEDIR)box-vars.json $(boxname_workdir)/$(boxname)-vars.json.iso $(boxname_workdir)/$(boxname)-vars.json.ssh $(boxname_workdir)/$(boxname)-vars.json.salt $(boxname_workdir)/$(boxname)-vars.json.tools $(boxname_workdir)/$(boxname)-vars.json.base
	@printf '[*] Merging build variables together into %s: %s\n' '$@' '$^'
	@jq 'reduce inputs as $$item (.; . * $$item)' $(foreach json,$^,'$(json)') >| '$@'

# Grab all the specified tools into the tools directory and build a json for it
$(boxname_workdir)/$(boxname)-vars.json.tools: $(foreach f,$(setup_network_environment_files),$(toolsdir)/libexec/$(f)) $(foreach f,$(extra_tools_files),$(toolsdir)/bin/$(f))	| $(boxname_workdir)
	@printf '[-] Generating variables for miscellaneous CoreOS tools\n'
	@jq -n --arg tools '$(toolsdir)' '{ "coreos-tools-directory": $$tools }' >| '$@'

# Generate any necessary configuration variables for salt-stack
$(boxname_workdir)/$(boxname)-vars.json.salt: $(boxname_workdir)/salt $(boxname_workdir)/pillar $(foreach name,$(salt_bootstrap_pillar_files),$(boxname_workdir)/pillar/$(name)) $(boxname_workdir)/salt-minion.conf $(workdir)/$(salt_bootstrap_file) $(salt_patches)
	@printf '[-] Generating bootstrap variables for salt-bootstrap: %s\n' '$^'
ifneq ($(debug),0)
	@jq -n --arg options '-D $(salt_bootstrap_options)' --arg configuration '$(boxname_workdir)/salt-minion.conf' --arg installer '$(workdir)/$(salt_bootstrap_file)' --arg saltdir '$(boxname_workdir)/salt' --arg pillardir '$(boxname_workdir)/pillar' --arg version '$(salt_bootstrap_version)' --arg patchdir '$(salt_patches)' '{ "salt-bootstrap-config": $$configuration, "salt-bootstrap-installer": $$installer, "salt-bootstrap-files": $$saltdir, "salt-bootstrap-pillar": $$pillardir, "salt-bootstrap-version": $$version, "salt-bootstrap-patches": $$patchdir, "salt-bootstrap-options": $$options }' >| '$@'
else
	@jq -n --arg options '$(salt_bootstrap_options)' --arg configuration '$(boxname_workdir)/salt-minion.conf' --arg installer '$(workdir)/$(salt_bootstrap_file)' --arg saltdir '$(boxname_workdir)/salt' --arg pillardir '$(boxname_workdir)/pillar' --arg version '$(salt_bootstrap_version)' --arg patchdir '$(salt_patches)' '{ "salt-bootstrap-config": $$configuration, "salt-bootstrap-installer": $$installer, "salt-bootstrap-files": $$saltdir, "salt-bootstrap-pillar": $$pillardir, "salt-bootstrap-version": $$version, "salt-bootstrap-patches": $$patchdir, "salt-bootstrap-options": $$options }' >| '$@'
endif

# Concatenate json template into a single .json file together with plugins
$(boxname_workdir)/$(boxname).json: $(MAKEDIR)box.json $(MAKEDIR)provision.json	| $(boxname_workdir)
	@printf '[*] Merging box with enabled plugins into %s: %s\n' '$@' '$^'
	@jq 'reduce inputs as $$item (.; . * $$item)' $(foreach json,$^,'$(json)') >| '$@'

### Recipes for dealing with the public/private keypair

# If the private key for the box has already been deployed, then re-use the
# keypair that was previously generated and deployed.
ifneq ($(wildcard $(outdir)/$(output_keypair_prv)),)
$(outdir)/$(output_keypair_prv): $(outdir)/$(output_keypair_pub)	| $(outdir)
	@printf '[-] Using already existing private key: %s\n' '$<'

# Use the already existing deployed public key from the output directory
# This is required since things won't work without actually having the
# whole keypair.
$(outdir)/$(output_keypair_pub):	| $(outdir)
	@printf '[-] Using already existing public key: %s\n' '$<'

else
# If there's an encrypted key that needs to be decrypted, then decrypt it
# by asking the user for their password.
ifneq ($(wildcard $(outdir)/$(output_keypair_prv).enc),)
$(outdir)/$(output_keypair_prv): $(outdir)/$(output_keypair_prv).enc $(outdir)/$(output_keypair_pub)	| $(outdir)
	@printf '[!] Found encrypted key: %s\n' '$<'
	openssl enc -d -$(cipher) -in '$<' -out '$@'

$(outdir)/$(output_keypair_pub):	| $(outdir)
	@printf '[-] Using already existing public key: %s\n' '$<'

else
# If there's no keypair components, then use ssh-keygen to generate it
$(outdir)/$(output_keypair_prv) $(outdir)/$(output_keypair_pub):	| $(outdir)
	$(call verify_expression,$(project),No PROJECT was specified. Unable to to generate public/private keypair!)
	@printf '[-] Generating public/private keypair: %s\n' '$@'
	ssh-keygen -q -t rsa -C 'core@$(project)' -f '$(outdir)/$(output_keypair_prv)' -N ''

endif
endif

### Recipes for bootstrapping the configuration of the OS

# Validate the ignition configuration that was generated
$(boxname_workdir)/$(boxname).config.validate: $(outdir)/$(output_config)	| $(boxname_workdir)
ifneq ($(validate),0)
	@printf '[!] Validating ignition configuration %s: %s\n' '$<' '$(coreos_validate_url)'
	${PUT} '@$<' '$(coreos_validate_url)' >| '$@'
else
	@printf '[-] Skipping the validation for the ignition configuration: %s\n' '$<'
	@jq -n . >| '$@'
endif

# Validate the results from our box configuration
$(boxname_workdir)/$(boxname).config.ok: $(boxname_workdir)/$(boxname).config.validate $(outdir)/$(output_config)	| $(workdir)
	@jq '(.result // []) | .[] | select(.kind == "warning") | [(.line | tostring), (.column | tostring), .message] | @sh' '$<' | while read y x message; do \
		printf 'Validation Warning: (line %d, col %d) %s\n' $$y $$x "$$message" 1>&2; \
	done
	@jq '(.result // []) | .[] | select(.kind == "error") | .message | @sh' '$<' | while read message; do \
		printf 'Validation Error: %s\n' "$$message" 1>&2; \
		exit 1; \
	done
	@printf '[*] Successfully validated ignition configuration: %s\n' '$@'
	@touch '$@'

# Check if the box configuration has already been deployed, if not then combine
# all ignition jsons into the template to generate it.
$(outdir)/$(output_config): $(ignition_template) $(boxname_workdir)/$(boxname).config-files $(boxname_workdir)/$(boxname).config-units $(boxname_workdir)/$(boxname).config-users $(boxname_workdir)/$(boxname).config-network
	@printf '[*] Making ignition configuration with template %s: %s\n' '$<' '$@'
	@jq --slurpfile files '$(boxname_workdir)/$(boxname).config-files' --slurpfile units '$(boxname_workdir)/$(boxname).config-units' --slurpfile users '$(boxname_workdir)/$(boxname).config-users' --slurpfile networks '$(boxname_workdir)/$(boxname).config-network' '.storage.files |= $$files[0] | .systemd.units |= $$units[0] | .passwd.users |= $$users[0] | .networkd.units |= $$networks[0]' '$(ignition_template)' >| '$@'

# Write the hostname
$(boxname_workdir)/$(boxname).name:	| $(boxname_workdir)
	$(call verify_expression,$(project),No PROJECT was specified. Unable to write project name into pillar configuration!)
	@printf '[-] Writing name of host into file: %s\n' '$@'
	@printf -- '%s\n' '$(boxname)' >| '$@'

# Write the identity file
$(outdir)/$(output_identity_file): $(boxname_workdir)/$(project_filename).antinewline	| $(outdir)
	$(call verify_expression,$(wildcard $<),File not found: $<)
	@printf '[-] Calculating %s checksum for %s: $@\n' '$(call uc,md5)' '$<'
	@openssl dgst -md5 '$<' | rev | cut -d' ' -f 1 | rev >| '$@'

# Pack the machine identifier and hostname into an array
$(boxname_workdir)/$(boxname).config-identifier: $(boxname_workdir)/ignition-id.json $(boxname_workdir)/ignition-hostname.json	| $(boxname_workdir)
	@printf '[-] Packing the ignition machine identifier and hostname into an array: %s\n' '$<'
	@jq '[., inputs]' $(foreach file,$^,'$(file)') >| '$@'

# Bootstrap the ignition/sysctl directory
ifneq ($(ignition_sysctl_files),)
$(boxname_workdir)/$(boxname).config-sysctl: $(foreach f,$(ignition_sysctl_files),$(boxname_workdir)/ignition-sysctl.json-$(notdir $(f)))
	@printf '[*] Merging all ignition sysctl files into %s: %s\n' '$@' '$^'
	@jq '[., inputs]' $(foreach file,$^,'$(file)') >| '$@'
else
$(boxname_workdir)/$(boxname).config-sysctl:
	@printf '[-] Generating an empty ignition sysctl file list: %s\n' '$@'
	@jq -n '[]' >| '$@'
endif

ifneq ($(ignition_root_files),)
$(boxname_workdir)/$(boxname).config-rootfs: $(foreach name,$(ignition_root_files),$(boxname_workdir)/rootfs/$(name))
	@printf '[*] Merging all ignition root files into %s: %s\n' '$@' '$^'
	jq '[., inputs]' $(foreach file,$^,'$(file)') >| '$@'
else
$(boxname_workdir)/$(boxname).config-rootfs:
	@printf '[-] Generating an empty ignition root file list: %s\n' '$@'
	@jq -n '[]' >| '$@'
endif

# Combine all ignition file jsons into a single one
$(boxname_workdir)/$(boxname).config-files: $(boxname_workdir)/$(boxname).config-identifier $(boxname_workdir)/$(boxname).config-sysctl $(boxname_workdir)/$(boxname).config-rootfs
	@printf '[*] Merging the ignition file section into %s: %s\n' '$@' '$^'
	@jq 'reduce inputs as $$item (.; . + $$item)' $(foreach config,$^,'$(config)') >| '$@'

# Combining the ignition/units and ignition/dropins files
ifneq ($(ignition_units_names)$(ignition_dropins_names),)
$(boxname_workdir)/$(boxname).config-units: $(foreach name,$(ignition_units_names),$(boxname_workdir)/ignition-unit.json-$(name)) $(foreach name,$(ignition_dropins_names),$(boxname_workdir)/ignition-unit.json-$(name))
	@printf '[*] Merging the ignition unit section into %s: %s\n' '$@' '$^'
	@jq '[., inputs]' $(foreach unit,$^,'$(unit)') >| '$@'
else
$(boxname_workdir)/$(boxname).config-units:
	@printf '[-] Generating an empty ignition unit list: %s\n' '$@'
	@jq -n '[]' >| '$@'
endif

# Generate a json containing the sshAuthorizedKeys field in an object
$(boxname_workdir)/$(boxname).config-pubkey: $(boxname_workdir)/$(boxname).id_rsa.pub.json-raw
	@printf '[-] Generating a json with the public key in %s: %s\n' '$@' '$^'
	@jq -n --slurpfile pubkey '$<' '{ sshAuthorizedKeys: [$$pubkey[0] | rtrimstr("\n")] }' >| '$@'

# Combine all joined user objects into a single list
ifneq ($(ignition_users_files),)
$(boxname_workdir)/$(boxname).config-users: $(foreach f,$(ignition_users_files),$(boxname_workdir)/ignition-user.json-$(notdir $(f)))
	@printf '[*] Merging the ignition user section into %s: %s\n' '$@' '$^'
	@jq '[., inputs]' $(foreach user,$^,'$(user)') >| '$@'
else
$(boxname_workdir)/$(boxname).config-users:
	$(error Not having any users defined may make it impossible to authenticate to template: $@)
	@printf '[-] Generating an empty ignition user section: %s\n' '$@'
	@jq -n '[]' >| '$@'
endif

# Combine all joined network dropins into a single list
ifneq ($(ignition_network_files),)
$(boxname_workdir)/$(boxname).config-network: $(foreach f,$(ignition_network_files),$(boxname_workdir)/ignition-network.json-$(notdir $(f)))
	@printf '[*] Merging all ignition network files into %s: %s\n' '$@' '$^'
	@jq '[., inputs]' $(foreach config,$^,'$(config)') >| '$@'
else
$(boxname_workdir)/$(boxname).config-network:
	@printf '[-] Generating an empty ignition network file list: %s\n' '$@'
	@jq -n '[]' >| '$@'
endif

### Recipes required for provisioning via SaltStack
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
	@printf -- '- Source: %s\n  Algo: %s\n  Hash: %s\n\n' $(foreach f,$^,'$(shell basename $(f))' '$(checksum_type)' '$(shell openssl dgst -$(checksum_type) "$(f)" | rev | cut -d" " -f1 | rev)') >| '$@'

$(boxname_workdir)/pillar/configuration-name.sls:	| $(boxname_workdir)/pillar
	$(call verify_expression,$(project),No PROJECT was specified. Unable to write project name into pillar configuration!)
	@printf '[-] Writing project name into pillar configuration: %s\n' '$@'
	@printf -- '%s\n' '$(project)' >| '$@'

### List of recipes that are dynamically generated using macros

## Container Linux installation and configuration

# Download the CoreOS installer
$(foreach name,$(file <$(in_coreos_files)),$(eval $(call coreos_download,$(workdir)/$(name),$(name))))

# Verify hashes for all downloaded files
$(foreach f,$(filter-out %.DIGESTS,$(coreos_installer_files)),$(eval $(call checksum,$(f),$(checksum_type),$(f).checksum)))
$(foreach f,$(filter %.DIGESTS,$(coreos_installer_files)),$(eval $(call checksum_verify,$(patsubst %.DIGESTS,%,$(f)),$(patsubst %.DIGESTS,%,$(f)).checksum,$(patsubst %.DIGESTS,%,$(f)).$(checksum_type),$(patsubst %.DIGESTS,%,$(f)).verified)))

# Extract hashes for all downloaded files and generate the ones that can't be extracted
$(foreach f,$(filter %.DIGESTS,$(coreos_installer_files)),$(eval $(call checksum_extract,$(f),$(checksum_type),$(notdir $(patsubst %.DIGESTS,%,$(f))),$(patsubst %.DIGESTS,%,$(f)).$(checksum_type))))
$(foreach f,$(filter-out %.DIGESTS,$(coreos_installer_files)),$(eval $(call json_rawfile,$(f).$(checksum_type),$(boxname_workdir)/$(notdir $(f)).$(checksum_type).json-raw)))

# Fetch the acbuild tool
$(foreach u,$(shell ${GH_FETCH} '$(acbuild_metaurl)' | jq -r '.assets[].browser_download_url'),$(eval $(call gh_download,$(filesdir)/$(notdir $(u)),$(u))))

# Fetch the setup-network-environment tool into the tools working directory
$(foreach u,$(shell ${GH_FETCH} '$(setup_network_environment_metaurl)' | jq -r '.assets[].browser_download_url'),$(eval $(call gh_download,$(toolsdir)/libexec/$(notdir $(u)),$(u))))

# Transfer any required tools to the tools working directory
$(foreach f,$(extra_tools_files),$(eval $(call stage_tool,$(tools_config)/$(f),$(toolsdir)/bin/$(f))))

# Download the saltstack-bootstrap installer
$(eval $(call gh_download,$(workdir)/$(salt_bootstrap_file),$(salt_bootstrap_file_url)))

## Components used to build the Ignition configuration

# Generate a static machine identifier for the master to work around hashicorp/packer#8528
$(eval $(call antinewline_file,$(outdir)/$(output_project_name),$(boxname_workdir)/$(project_filename).antinewline))
$(eval $(call antinewline_file,$(outdir)/$(output_identity_file),$(boxname_workdir)/$(boxname).id.antinewline))

# This id is fed to the kernel at bootup in order to force the machine id
$(eval $(call json_rawfile,$(boxname_workdir)/$(boxname).id.antinewline,$(boxname_workdir)/$(boxname).id.json-raw))

# This id is fed to ignition so that the id never changes
$(eval $(call json_rawfile,$(outdir)/$(output_identity_file),$(boxname_workdir)/ignition-id.json-raw))
$(eval $(call ignition_root_file,$(boxname_workdir)/ignition-id.json-raw,$(boxname_workdir)/ignition-id.json,etc/machine-id,292))

# Generate an ignition file to write the hostname file
$(eval $(call antinewline_file,$(boxname_workdir)/$(boxname).name,$(boxname_workdir)/$(boxname).name.antinewline))
$(eval $(call json_rawfile,$(boxname_workdir)/$(boxname).name,$(boxname_workdir)/ignition-hostname.json-raw))
$(eval $(call ignition_root_file,$(boxname_workdir)/ignition-hostname.json-raw,$(boxname_workdir)/ignition-hostname.json,etc/hostname,420))

# Making the ignition sysctl list
$(foreach f,$(ignition_sysctl_files),$(eval $(call ignition_sysctl,$(boxname_workdir)/ignition-sysctl.json-$(notdir $(f)).json-raw,$(boxname_workdir)/ignition-sysctl.json-$(notdir $(f)),$(notdir $(f)),$(call decimal_mode,$(f)))))

# Making the ignition network list
$(foreach f,$(ignition_network_files),$(eval $(call ignition_dropin_file,$(notdir $(f)),$(boxname_workdir)/ignition-network.json-$(notdir $(f)).json-raw,$(boxname_workdir)/ignition-network.json-$(notdir $(f)))))

# Making the ignition units list
$(foreach name,$(ignition_units_names),$(eval $(call ignition_unit_file,$(name),$(boxname_workdir)/ignition-units.json-$(name).json-raw,$(boxname_workdir)/ignition-units.json-$(name))))

# Making the ignition unit dropins files
$(foreach name,$(ignition_dropins_names),$(foreach f,$(wildcard $(ignition_config)/dropins/$(name)/*.conf),$(eval $(call ignition_dropin_file,$(notdir $(f)),$(boxname_workdir)/ignition-dropins.json-$(name)-$(notdir $(f)).json-raw,$(boxname_workdir)/ignition-dropins.json-$(name)-$(notdir $(f))))))

# Making the ignition unit dropins list
$(foreach name,$(ignition_dropins_names),$(eval $(call ignition_unit_dropins,$(boxname_workdir)/ignition-dropins.json-$(name),$(foreach f,$(wildcard $(ignition_config)/dropins/$(name)/*.conf),$(boxname_workdir)/ignition-dropins.json-$(name)-$(notdir $(f))))))

# Recipes that compose the unit with all of its dropins
$(foreach name,$(filter $(ignition_dropins_names),$(ignition_units_names)),$(eval $(call ignition_unit,$(boxname_workdir)/ignition-unit.json-$(name),$(boxname_workdir)/ignition-units.json-$(name),$(boxname_workdir)/ignition-dropins.json-$(name))))

# Recipes that compose the unit without any dropins
$(foreach name,$(filter-out $(ignition_dropins_names),$(ignition_units_names)),$(eval $(call ignition_unit,$(boxname_workdir)/ignition-unit.json-$(name),$(boxname_workdir)/ignition-units.json-$(name))))

# Recipes that compose a missing unit with all dropins
$(foreach name,$(filter-out $(ignition_units_names),$(ignition_dropins_names)),$(eval $(call ignition_unit_missing,$(name),$(boxname_workdir)/ignition-unit.json-$(name),$(boxname_workdir)/ignition-dropins.json-$(name))))

# Combining each user with the sshAuthorizedKeys (FIXME: allow unique ssh keys per-user)
$(foreach f,$(ignition_users_files),$(eval $(call ignition_user,$(boxname_workdir)/ignition-user.json-$(notdir $(f)),$(f),$(boxname_workdir)/$(boxname).config-pubkey)))

# Raw ignition_sysctl_files contents
$(foreach f,$(ignition_sysctl_files),$(eval $(call json_rawfile,$(f),$(boxname_workdir)/ignition-sysctl.json-$(notdir $(f)).json-raw)))

# Raw ignition_network_files contents
$(foreach f,$(ignition_network_files),$(eval $(call json_rawfile,$(f),$(boxname_workdir)/ignition-network.json-$(notdir $(f)).json-raw)))

# Raw ignition_unit_files contents
$(foreach name,$(ignition_units_names),$(eval $(call json_rawfile,$(ignition_config)/units/$(name),$(boxname_workdir)/ignition-units.json-$(name).json-raw)))

# Raw ignition_dropins_names contents
$(foreach name,$(ignition_dropins_names),$(foreach f,$(wildcard $(ignition_config)/dropins/$(name)/*.conf),$(eval $(call json_rawfile,$(f),$(boxname_workdir)/ignition-dropins.json-$(name)-$(notdir $(f)).json-raw))))

# Raw ssh pubkey contents
$(eval $(call json_rawfile,$(outdir)/$(output_keypair_pub),$(boxname_workdir)/$(boxname).id_rsa.pub.json-raw))

# Directory structure for the ignition root files
$(foreach name,$(ignition_root_directories),$(eval $(call make_directory,$(boxname_workdir)/rootfs/$(name))))

# Raw ignition root files
$(foreach name,$(ignition_root_files),$(eval $(call json_rawfile,$(ignition_config)/files/$(name),$(boxname_workdir)/rootfs/$(name).json-raw)))

# Making the file entries for the ignition root files
$(foreach name,$(ignition_root_files),$(eval $(call ignition_root_file,$(boxname_workdir)/rootfs/$(name).json-raw,$(boxname_workdir)/rootfs/$(name),$(name),$(call decimal_mode,$(ignition_config)/files/$(name)))))
