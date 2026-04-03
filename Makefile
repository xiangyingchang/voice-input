.PHONY: build run install clean bundle

PRODUCT_NAME = VoiceInput
APP_NAME = Voice Input
APP_BUNDLE = $(APP_NAME).app
BUILD_DIR = .build
SDK = $(shell xcrun --show-sdk-path)
SWIFT_FILES = $(shell find Sources -name "*.swift")
FRAMEWORKS = -framework AppKit -framework Speech -framework AVFoundation -framework Carbon -framework CoreGraphics

# Build release .app bundle
build: $(BUILD_DIR)/$(PRODUCT_NAME)
	bash scripts/bundle.sh

$(BUILD_DIR)/$(PRODUCT_NAME): $(SWIFT_FILES)
	@mkdir -p $(BUILD_DIR)
	swiftc \
		-target arm64-apple-macosx14.0 \
		-sdk $(SDK) \
		$(FRAMEWORKS) \
		-O \
		-module-name $(PRODUCT_NAME) \
		-swift-version 5 \
		-o $(BUILD_DIR)/$(PRODUCT_NAME) \
		$(SWIFT_FILES)

# Build debug and run
run:
	@mkdir -p $(BUILD_DIR)
	swiftc \
		-target arm64-apple-macosx14.0 \
		-sdk $(SDK) \
		$(FRAMEWORKS) \
		-g \
		-module-name $(PRODUCT_NAME) \
		-swift-version 5 \
		-o $(BUILD_DIR)/$(PRODUCT_NAME)-debug \
		$(SWIFT_FILES)
	$(BUILD_DIR)/$(PRODUCT_NAME)-debug

# Build release and install to /Applications
install: build
	@echo "📲 Installing to /Applications..."
	rm -rf "/Applications/$(APP_BUNDLE)"
	cp -R "$(APP_BUNDLE)" "/Applications/$(APP_BUNDLE)"
	@echo "✅ Installed to /Applications/$(APP_BUNDLE)"

# Clean build artifacts
clean:
	rm -rf $(BUILD_DIR)
	rm -rf "$(APP_BUNDLE)"
	@echo "🧹 Clean complete"

# Just bundle (after build)
bundle:
	bash scripts/bundle.sh
