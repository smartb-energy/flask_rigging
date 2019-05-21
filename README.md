# flask_rigging
This package provides a set of override Plan callbacks that can be used to
simplify the process of packaging a conventional Flask app as a Habitat Service
Package. For more about Flask, see http://flask.pocoo.org.

## Maintainers
* smartB Engineering: <dev@smartb.eu>
* Blake Irvin: <blakeirvin@me.com>

## Type of Package
Rigging (Plan templating) package

## Usage
Here's how a plan depending on `smartb/scaffolding-flask` might look:
```
# You must set the following 4 package variables to generate metadata for your
# package:
pkg_origin=<origin>
pkg_name=<name>
pkg_version="<version>"
pkg_maintainer="smartB Engineering <dev@smartb.eu>"

# Setting 'pkg_scaffolding' is required to inherit Flask-specific build logic.
pkg_scaffolding="smartb/scaffolding-flask"

# Setting 'scaffolding_python_pkg' is required if you need a specific version of
# Python. See https://bldr.habitat.sh/#/pkgs/core/python
scaffolding_python_pkg="core/python36"

# Populate this array with the names of any Pip modules you want to try to fetch
# from your Builder origin as 'vendored' modules:
scaffolding_vendored_python_modules=(
  "Cython"
  "numpy"
)
```

The `smartb/scaffolding-flask` package assumes the following directory structure
for your Flask project, where `app.py` is the expected entrypoint for Flask:
```
.
|-- requirements.txt
|-- app.py
|-- templates
|   `-- email.j2
|-- habitat
|   |-- default.toml
|   `-- plan.sh
```
