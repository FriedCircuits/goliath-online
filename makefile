ver = v$(shell sed -n 's/^VERSION="\(.*\)"/\1/p' VERSION)

.PHONY: release
release:
	git pull --ff-only
	git tag -s $(ver) -m $(ver)
	git push origin $(ver)
	gh release create $(ver) --verify-tag --generate-notes
