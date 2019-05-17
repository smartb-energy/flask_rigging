pkg_origin=smartb
pkg_name=flask_rigging
pkg_version="0.1.0"
pkg_maintainer="smartB Engineering <dev@smartb.eu>"

do_build() {
  return 0
}

do_install() {
  cp --preserve --verbose --recursive "$PLAN_CONTEXT/plan_callbacks.sh" "$pkg_prefix/plan_callbacks.sh"
  cp --preserve --verbose --recursive "$PLAN_CONTEXT/hooks" "$pkg_prefix/hooks"
  return $?
}
