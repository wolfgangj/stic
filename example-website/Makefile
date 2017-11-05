PAGES = upload/index.html

all: $(PAGES) upload/style.css
	@echo ok.

upload/%.html: pages/%.stic html-tags mod/*.stic
	stic $< $@

upload/style.css: css/*.css css/REPLACEMENTS.sed
	sed -f css/REPLACEMENTS.sed css/*.css >$@
