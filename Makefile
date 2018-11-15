# This file is licensed under the Affero General Public License version 3 or
# later. See the COPYING file.
# @author Ilja Neumann <ineumann@owncloud.com>


app_name=$(notdir $(CURDIR))
project_directory=$(CURDIR)/../$(app_name)
build_dir=$(CURDIR)/build
build_tools_directory=$(CURDIR)/build/tools
source_build_directory=$(CURDIR)/build/artifacts/source
source_package_name=$(source_build_directory)/$(app_name)
appstore_build_directory=$(CURDIR)/build/artifacts/appstore
appstore_package_name=$(appstore_build_directory)/$(app_name)
npm=$(shell which npm 2> /dev/null)
composer=$(shell which composer 2> /dev/null)

occ=$(CURDIR)/../../occ
private_key=$(HOME)/.owncloud/certificates/$(app_name).key
certificate=$(HOME)/.owncloud/certificates/$(app_name).crt
sign=php -f $(occ) integrity:sign-app --privateKey="$(private_key)" --certificate="$(certificate)"
sign_skip_msg="Skipping signing, either no key and certificate found in $(private_key) and $(certificate) or occ can not be found at $(occ)"
ifneq (,$(wildcard $(private_key)))
ifneq (,$(wildcard $(certificate)))
ifneq (,$(wildcard $(occ)))
	CAN_SIGN=true
endif
endif
endif

# composer
composer_deps=vendor
composer_dev_deps=vendor/php-cs-fixer
COMPOSER_BIN=$(build_dir)/composer.phar

#
# Basic required tools
#
#

.PHONY: all
all: $(composer_dev_deps)

# Removes the appstore build
.PHONY: clean
clean:
	rm -rf ./build/artifacts

$(COMPOSER_BIN):
	mkdir -p $(build_dir)
	cd $(build_dir) && curl -sS https://getcomposer.org/installer | php
#
# ownCloud core PHP dependencies
#
$(composer_deps): $(COMPOSER_BIN) composer.json composer.lock
	php $(COMPOSER_BIN) install --no-dev

$(composer_dev_deps): $(COMPOSER_BIN) composer.json composer.lock
	php $(COMPOSER_BIN) install --dev

# Builds the source and appstore package
.PHONY: dist
dist:
	make source
	make appstore

# Builds the source package
.PHONY: source
source:
	rm -rf $(source_build_directory)
	mkdir -p $(source_build_directory)
	tar cvzf $(source_package_name).tar.gz ../$(app_name) \
	--exclude-vcs \
	--exclude="../$(app_name)/build" \
	--exclude="../$(app_name)/js/node_modules" \
	--exclude="../$(app_name)/node_modules" \
	--exclude="../$(app_name)/*.log" \
	--exclude="../$(app_name)/js/*.log" \

# Builds the source package for the app store, ignores php and js tests
.PHONY: appstore
appstore:
	rm -rf $(appstore_build_directory)
	mkdir -p $(appstore_package_name)
	cp --parents -r \
	appinfo \
	controller \
	config \
	css \
	environment \
	http \
	img \
	l10n \
	middleware \
	preview \
	service \
	utility \
	templates \
	js \
	$(appstore_package_name)

ifdef CAN_SIGN
	$(sign) --path="$(appstore_package_name)"
else
	@echo $(sign_skip_msg)
endif
	tar -czf $(appstore_package_name).tar.gz -C $(appstore_package_name)/../ $(app_name)


# bin file definitions
PHP_CS_FIXER=php -d zend.enable_gc=0 vendor-bin/owncloud-codestyle/vendor/bin/php-cs-fixer
PHPUNIT=php -d zend.enable_gc=0  vendor/bin/phpunit
PHPUNITDBG=phpdbg -qrr -d memory_limit=4096M -d zend.enable_gc=0 "./vendor/bin/phpunit"


.PHONY: test-php-style
test-php-style:            ## Run php-cs-fixer and check owncloud code-style
test-php-style: vendor-bin/owncloud-codestyle/vendor
	$(PHP_CS_FIXER) fix -v --diff --diff-format udiff --allow-risky yes --dry-run

.PHONY: test-php-integration
test-php-integration:
test-php-integration: vendor/bin/codecept
	php vendor/bin/codecept run integration

.PHONY: test-acceptance
test-acceptance:
test-acceptance: vendor/bin/codecept
	php vendor/bin/codecept run acceptance --env chrome

.PHONY: test-php-style-fix
test-php-style-fix:        ## Run php-cs-fixer and fix code style issues
test-php-style-fix: vendor-bin/owncloud-codestyle/vendor
	$(PHP_CS_FIXER) fix -v --diff --diff-format udiff --allow-risky yes


.PHONY: test-php-unit
test-php-unit:             ## Run php unit tests
test-php-unit: vendor/bin/phpunit
	$(PHPUNIT) --configuration ./phpunit.xml --testsuite unit

.PHONY: test-php-unit-dbg
test-php-unit-dbg:             ## Run php unit tests with php dbg
test-php-unit-dbg: vendor/bin/phpunit
	$(PHPUNITDBG) --configuration ./phpunit.xml --testsuite unit

#
# Dependency management
#--------------------------------------
 composer.lock: composer.json
	@echo composer.lock is not up to date.

 vendor: composer.lock
	composer install --no-dev

 vendor/bin/phpunit: composer.lock
	composer install

 vendor/bin/codecept: composer.lock
	composer install

 vendor/bamarni/composer-bin-plugin: composer.lock
	composer install

 vendor-bin/owncloud-codestyle/vendor: vendor/bamarni/composer-bin-plugin vendor-bin/owncloud-codestyle/composer.lock
	composer bin owncloud-codestyle install --no-progress

 vendor-bin/owncloud-codestyle/composer.lock: vendor-bin/owncloud-codestyle/composer.json
	@echo owncloud-codestyle composer.lock is not up to date.

