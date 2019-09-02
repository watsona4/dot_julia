TWINE_OPTS =

__JLM_DUMMY_BUILDING__ = yes
export __JLM_DUMMY_BUILDING__

sdist:
	python3 setup.py sdist

## Upload to PyPI test server
test-upload:
	$(MAKE) TWINE_OPTS="--repository-url https://test.pypi.org/legacy/" upload

## Upload to PyPI
upload:
	rm -rf dist/
	python3 setup.py sdist
	twine upload $(TWINE_OPTS) dist/*
