MAKEDIR := $(dir $(firstword $(MAKEFILE_LIST)))

.PHONY: master-image
.PHONY: master-base-download master-base-image master-base-output
master-image: master-base-download master-base-image master-base-output
	$(MAKE) -f $(MAKEDIR)project-master/Makefile master-base-download master-base-image master-base-output
	$(info "Successfully built master image.")

.PHONY: all
all:
	$(info "Please specify one of the following: master-image")
