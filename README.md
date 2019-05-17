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
Here's how a plan depending on `smartb/flask_rigging` might look:
```
pkg_origin=origin
pkg_name=name
pkg_version="0.1.0"
pkg_channel="staging"   # If set, specifies the Builder Channel to promote to
pkg_lang="en_US.UTF-8"  # Specify the LANG value you wish to set
pkg_maintainer="smartB Engineering <dev@smartb.eu>"
pkg_deps=(
  "smartb/flask_rigging"
)
source $(hab pkg path "smartb/flask_rigging")/*.sh
```
This assumes the following Flask directory structure at the root of this repo:
```
.
|-- flask
|   |-- requirements.txt
|   |-- app.py
|   |-- templates
|       `-- email.j2
|-- habitat
|   |-- default.toml
|   |-- hooks
|   |   `-- run
|   `-- plan.sh
```
