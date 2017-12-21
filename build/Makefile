MAKEDIR := $(dir $(firstword $(MAKEFILE_LIST)))

.PHONY: master-image
master-image:
	$(MAKE) -f $(MAKEDIR)master.project/Makefile download-installer master-image master-output
	$(info "Successfully built master image.")

.PHONY: all
all:
	$(info "Please specify one of the following: master-image")
