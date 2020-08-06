###############################################################################
# Makefile.inc
#
# This file contains various utilities that are used by the main Makefile in
# order to facilitate common build tasks.
###############################################################################

ifeq ($(ROOTDIR),)
    $(error Please do not use this file directly as it is intended to be included)
endif

### Simple utility macros for enabling some GNU-specific Makefile trickery
noop=
space=$(noop) $(noop)
comma=,
lc = $(subst A,a,$(subst B,b,$(subst C,c,$(subst D,d,$(subst E,e,$(subst F,f,$(subst G,g,$(subst H,h,$(subst I,i,$(subst J,j,$(subst K,k,$(subst L,l,$(subst M,m,$(subst N,n,$(subst O,o,$(subst P,p,$(subst Q,q,$(subst R,r,$(subst S,s,$(subst T,t,$(subst U,u,$(subst V,v,$(subst W,w,$(subst X,x,$(subst Y,y,$(subst Z,z,$1))))))))))))))))))))))))))
uc = $(subst a,A,$(subst b,B,$(subst c,C,$(subst d,D,$(subst e,E,$(subst f,F,$(subst g,G,$(subst h,H,$(subst i,I,$(subst j,J,$(subst k,K,$(subst l,L,$(subst m,M,$(subst n,N,$(subst o,O,$(subst p,P,$(subst q,Q,$(subst r,R,$(subst s,S,$(subst t,T,$(subst u,U,$(subst v,V,$(subst w,W,$(subst x,X,$(subst y,Y,$(subst z,Z,$1))))))))))))))))))))))))))

### Multi-line macros for performing verifications/assertions

# Evaluate the provided expression and warn with the specified message if it
# does not evaluate to true. (Assert)
#
# Usage: assert_expression($expression, $message)
define assert_expression
	$(if $(1),@true,$(warning $(2)))
endef

# Evaluate the provided expression and warn with the specified message if it
# does not evaluate to false. (!Assert)
#
# Usage: assert_expression_not($expression, $message)
define assert_expression_not
	$(if $(1),$(warning $(2)),@true)
endef

# Evaluate the provided expression and fail with the specified message if it
# does not evaluate to true. (Verify)
#
# Usage: verify_expression($expression, $message)
define verify_expression
	$(if $(1),@true,$(error $(2)))
endef

# Evaluate the provided expression and fail with the specified message if it
# does not evaluate to false. (!Verify)
#
# Usage: verify_expression_not($expression, $message)
define verify_expression_not
	$(if $(1),$(error $(2)),@true)
endef

### Multi-line macros for performing evaluation of various types of expressions

# Using the mode of the specified file, return its mode in decimal form instead
# of octal form. This is needed for output formats such as json which only
# supports base 10 integers.
#
# Usage: decimal_mode($file)
define decimal_mode
$(shell printf '%d' $$(( 8#$(shell ${MODE} '$(1)') )) )
endef

### Multi-line macros for generating recipes that perform common build tasks

# Generate a recipe that makes the target directory after evaluating any of the
# specified dependencies. The dependencies are space separated.
#
# Usage: make_directory($target, $dependencis)
define make_directory
$(1): $(2)
	@test -d '$$@' || mkdir -p '$$@'
endef

# Generate a recipe that copies the provided file into the target directory.
# The recipe that is generated depends on the existence of the directory and so
# is likely to be combined with the make_directory macro defined above.
# 
# Usage: output_file($file, $directory)
define output_file
$(2)/$(notdir $(1)): $(1)	| $(2)
	$$(call verify_expression_not,$$(wildcard $$@),Refusing to deploy $$< over already existing file: $$@)
	@printf '[*] Copying output file to %s: %s\n' '$(2)' '$$<'
	@cp '$$<' '$$@'
endef

# Same as the checksum function except the generated recipe also appends a
# newline to the file that gets written.
#
# Usage: newline_file($filename, $target)
define newline_file
$(2): $(1)	| $(patsubst %/,%,$(dir $(2)))
	@cp '$$<' '$$@'
	@echo >> '$$@'
endef

# Same as the checksum function except the generated recipe also strips any
# newlines from the file that gets written.
#
# Usage: antinewline_file($filename, $target)
define antinewline_file
$(2): $(1)	| $(patsubst %/,%,$(dir $(2)))
	@tr -d $$$$'\r\n' < '$$<' >| '$$@'
endef

# Generate a recipe that converts the source file (raw) into a json form that
# is properly escaped. This is necessary if trying to use the contents of a raw
# file as a field in json.
#
# Usage: json_rawfile($source.raw, $target.json)
define json_rawfile
$(2): $(1)	| $(patsubst %/,%,$(dir $(2)))
	$$(call verify_expression,$$(wildcard $$<),File not found: $$<)
	@jq -Rs . '$(1)' >| '$(2)'
endef

# Generate a recipe that calculates the checksum or digest of the specified
# filename using the specified type and write it as a string to the target.
# The digest is calculated using the OpenSSL binary in the current PATH, and
# as-such the type can be chosen based on the Message Digest commands that
# are are supported by it. Use `openssl help` to see what's available.
#
# Usage: checksum($filename, $type, $target)
define checksum
$(3): $(1)
	$$(call verify_expression,$$(wildcard $$<),File not found: $$<)
	@printf '[-] Calculating %s checksum for %s: $$@\n' '$$(call uc,$(2))' '$$<'
	@openssl dgst -$(2) '$$<' | rev | cut -d' ' -f 1 | rev | tr -d '\r\n' >| '$$@'
endef

# Generate a recipe that extracts the specified checksum type from a DIGESTS
# file and writes it as a string to the target.
#
# Usage: checksum_extract($infile, $type, $filename, $target)
define checksum_extract
$(4): $(1)
	$$(call verify_expression,$$(wildcard $$<),File not found: $$<)
	@printf '[-] Extracting %s checksum for %s from %s: $$@\n' '$$(call uc,$(2))' '$(3)' '$$<'
	@grep -A1 '^# $$(call uc,$(2)) HASH' '$(1)' | grep -v '^#' | grep '$(3)$$$$' | cut -d' ' -f1 | tr -d '\r\n' >| '$$@'
endef

# Generate a recipe that compares the two provided checksum files to see if
# they match. If they do, then create the described target. Otherwise, remove
# the described file.
#
# Usage: checksum_verify($file, $checksum1, $checksum2, $target)
define checksum_verify
$(4): $(1) $(2) $(3)
	$$(call verify_expression,$$(wildcard $$<),File not found: $$<)
	@printf '[-] Verifying checksum for file: %s\n' '$$<'
	-cmp -s '$(2)' '$(3)' && touch '$$@'
	-test -e '$$@' && printf '[*] Successfully verified checksum for file: %s\n' '$$<'
	-test ! -e '$$@' && printf '[!] Invalid checksum for file: %s\n' '$$<'
	-test ! -e '$$@' && rm -f '$(2)' '$(3)'
	@test -e '$$@'
endef
