ifeq ($(ROOTDIR),)
    $(error Please do not use this file directly as it is intended to be included)
endif

### Validation of configurable parameters
noop=
space=$(noop) $(noop)
comma=,
lc = $(subst A,a,$(subst B,b,$(subst C,c,$(subst D,d,$(subst E,e,$(subst F,f,$(subst G,g,$(subst H,h,$(subst I,i,$(subst J,j,$(subst K,k,$(subst L,l,$(subst M,m,$(subst N,n,$(subst O,o,$(subst P,p,$(subst Q,q,$(subst R,r,$(subst S,s,$(subst T,t,$(subst U,u,$(subst V,v,$(subst W,w,$(subst X,x,$(subst Y,y,$(subst Z,z,$1))))))))))))))))))))))))))

### Commands (macros)

# assert_expression '$expr' '$message'
define assert_expression
	$(if $(1),@true,$(warning $(2)))
endef

# assert_expression_not '$expr' '$message'
define assert_expression_not
	$(if $(1),$(warning $(2)),@true)
endef

# verify_expression '$expr' '$message'
define verify_expression
	$(if $(1),@true,$(error $(2)))
endef

# verify_expression_not '$expr' '$message'
define verify_expression_not
	$(if $(1),$(error $(2)),@true)
endef

### Expressions (macros)

# decimal_mode '$file'
define decimal_mode
$(shell printf '%d' $$(( 8#$(shell ${MODE} '$(1)') )) )
endef

### Recipe definitions (macros)

# make_directory '$target' '$deps'
define make_directory
$(1): $(2)
	@test -d '$$@' || mkdir -p '$$@'
endef

# output_file '$file' '$directory'
define output_file
$(2)/$(notdir $(1)): $(1)	| $(2)
	$$(call verify_expression_not,$$(wildcard $$@),Refusing to deploy $$< over already existing file: $$@)
	@printf '[*] Copying output file to %s: %s\n' '$(2)' '$$<'
	@cp '$$<' '$$@'
endef

# json_rawfile '$source.raw' '$target.json'
define json_rawfile
$(2): $(1)	| $(patsubst %/,%,$(dir $(2)))
	$$(call verify_expression,$$(wildcard $$<),File not found: $$<)
	@jq -Rs . '$(1)' >| '$(2)'
endef

## CoreOS components

# checksum '$filename' '$checksum' '$checksum_filename'
define checksum
$(3): $(1)
	$$(call verify_expression,$$(wildcard $$<),File not found: $$<)
	@printf '[-] Calculating %s checksum for %s: $$@\n' '$(2)' '$$<'
	@openssl dgst -$(2) '$$<' | rev | cut -d' ' -f 1 | rev | tr -d '\r\n' >| '$$@'
endef

