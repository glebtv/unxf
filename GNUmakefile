# use GNU Make to run tests in parallel, and without depending on RubyGems
all::
RSYNC_DEST := bogomips.org:/srv/bogomips/unxf
rfproject := rainbows
rfpackage := unxf
include pkg.mk
ifneq ($(VERSION),)
release::
	$(RAKE) raa_update VERSION=$(VERSION)
	$(RAKE) publish_news VERSION=$(VERSION)
endif
