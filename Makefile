BUILD_DIR = pdf

now = $(shell date -u +%Y%m%d-%H%M%S)

pdf: _build_dir
	@gitbook pdf book/ $(BUILD_DIR)/navguide-$(now).pdf

_build_dir:
	@mkdir -p $(BUILD_DIR)

.PHONY: clean
clean:
	@rm -rf $(BUILD_DIR)

