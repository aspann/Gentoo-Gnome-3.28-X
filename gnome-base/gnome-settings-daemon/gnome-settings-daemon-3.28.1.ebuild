# Copyright 1999-2018 Gentoo Foundation
# Distributed under the terms of the GNU General Public License v2

EAPI=6
#PYTHON_COMPAT=( python{2_7,3_4,3_5,3_6} ) # https://bugzilla.gnome.org/show_bug.cgi?id=783186
PYTHON_COMPAT=( python2_7 )
GNOME2_LA_PUNT="yes"

inherit gnome2 python-any-r1 systemd udev virtualx meson

DESCRIPTION="Gnome Settings Daemon"
HOMEPAGE="https://git.gnome.org/browse/gnome-settings-daemon"

LICENSE="GPL-2+"
SLOT="0"
IUSE="+colord +cups debug input_devices_wacom -openrc-force networkmanager policykit smartcard test +udev wayland"
REQUIRED_USE="
	input_devices_wacom? ( udev )
	smartcard? ( udev )
	wayland? ( udev )
"
KEYWORDS="~alpha amd64 ~arm ~arm64 ~ia64 ~ppc ~ppc64 ~sparc ~x86 ~x86-fbsd ~amd64-linux ~x86-linux ~x86-solaris"

COMMON_DEPEND="
	>=dev-libs/glib-2.53.0:2[dbus]
	>=x11-libs/gtk+-3.15.3:3[X,wayland?]
	>=gnome-base/gnome-desktop-3.11.1:3=
	>=gnome-base/gsettings-desktop-schemas-3.23.3
	>=gnome-base/librsvg-2.36.2:2
	media-fonts/cantarell
	media-libs/alsa-lib
	media-libs/fontconfig
	media-libs/libcanberra[gtk3]
	>=media-sound/pulseaudio-2
	>=sys-power/upower-0.99:=
	x11-libs/cairo
	x11-libs/gdk-pixbuf:2
	>=x11-libs/libnotify-0.7.3:=
	x11-libs/libX11
	x11-libs/libxkbfile
	x11-libs/libXi
	x11-libs/libXext
	x11-libs/libXfixes
	x11-libs/libXtst
	x11-libs/libXxf86misc
	x11-misc/xkeyboard-config

	>=app-misc/geoclue-2.3.1:2.0
	>=dev-libs/libgweather-3.9.5:2=
	>=sci-geosciences/geocode-glib-3.10
	>=sys-auth/polkit-0.103

	>=media-libs/lcms-2.2:2
	>=x11-misc/colord-1.0.2:=

	cups? ( >=net-print/cups-1.4[dbus] )
	input_devices_wacom? (
		>=dev-libs/libwacom-0.7
		>=x11-libs/pango-1.20
		x11-drivers/xf86-input-wacom
		virtual/libgudev:= )
	networkmanager? ( >=net-misc/networkmanager-1.0 )
	smartcard? ( >=dev-libs/nss-3.11.2 )
	udev? ( virtual/libgudev:= )
	wayland? ( dev-libs/wayland )
"
# Themes needed by g-s-d, gnome-shell, gtk+:3 apps to work properly
# <gnome-color-manager-3.1.1 has file collisions with g-s-d-3.1.x
# <gnome-power-manager-3.1.3 has file collisions with g-s-d-3.1.x
# systemd needed for power and session management, bug #464944
RDEPEND="${COMMON_DEPEND}
	gnome-base/dconf
	!openrc-force? ( sys-apps/systemd )
	!<gnome-base/gnome-control-center-2.22
	!<gnome-extra/gnome-color-manager-3.1.1
	!<gnome-extra/gnome-power-manager-3.1.3
	!<gnome-base/gnome-session-3.23.2
"
# xproto-7.0.15 needed for power plugin
DEPEND="${COMMON_DEPEND}
	cups? ( sys-apps/sed )
	test? (
		${PYTHON_DEPS}
		$(python_gen_any_dep 'dev-python/pygobject:3[${PYTHON_USEDEP}]')
		$(python_gen_any_dep 'dev-python/dbusmock[${PYTHON_USEDEP}]')
		gnome-base/gnome-session )
	dev-libs/libxml2:2
	sys-devel/gettext
	>=sys-auth/polkit-0.114
	virtual/pkgconfig
	x11-base/xorg-proto
"
PATCHES=(
	# Make Wacom devices optional
	"${FILESDIR}"/3.28.1-wacom-optional.patch
)

# TypeErrors with python3; weird test errors with python2; all in power component that was made required now
RESTRICT="!test? ( test )"

python_check_deps() {
	if use test; then
		has_version "dev-python/pygobject:3[${PYTHON_USEDEP}]" &&
		has_version "dev-python/dbusmock[${PYTHON_USEDEP}]"
	fi
}

pkg_setup() {
	use test && python-any-r1_pkg_setup
}

src_configure() {
	local emesonargs=(
		-Dudev_dir="$(get_udevdir)" \
		-Dalsa=true \
		-Dgudev=true \
		-Dcups=$(usex cups true false) \
		-Dnetwork_manager=$(usex networkmanager true false) \
		-Dsmartcard=$(usex smartcard true false) \
		-Dwayland=$(usex wayland true false) \
                -Dwacom=$(usex input_devices_wacom true false) \

	)
	meson_src_configure
}

pkg_postinst() {
	gnome2_pkg_postinst

	if ! systemd_is_booted; then
		ewarn "${PN} needs Systemd to be *running* for working"
		ewarn "properly. Please follow the this guide to migrate:"
		ewarn "https://wiki.gentoo.org/wiki/Systemd"
	fi

	if use openrc-force; then
		ewarn "You are enabling 'openrc-force' USE flag to skip systemd requirement,"
		ewarn "this can lead to unexpected problems and is not supported neither by"
		ewarn "upstream neither by Gnome Gentoo maintainers. If you suffer any problem,"
		ewarn "you will need to disable this USE flag system wide and retest before"
		ewarn "opening any bug report."
	fi
}
