pkg_origin=smartb
pkg_name=scaffolding-flask
pkg_version="0.1.0"
pkg_maintainer="smartB Engineering <dev@smartb.eu>"
pkg_build_deps=(
  "core/gcc"
)
pkg_deps=(
  "core/bash"
  "core/cacerts"
  "core/curl/7.63.0"
)

do_build() {
  return 0
}

do_install() {
  cp --preserve --verbose --recursive \
    "$PLAN_CONTEXT/lib/" "$pkg_prefix/lib"
  cp --preserve --verbose --recursive \
    "$PLAN_CONTEXT/hooks" "$pkg_prefix/hooks"
  chmod 644 $pkg_prefix/lib/*
  chmod 644 $pkg_prefix/hooks/*
  return $?
}
