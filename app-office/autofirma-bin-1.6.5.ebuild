# Ebuild para instalar los autofirma 1.6.5 (binários java) a partir de la
# descarga que ofrece  el Portal de Administración electrónica del Gobierno
# de España)

EAPI=7

inherit xdg-utils  # Para xdg_desktop_database_update

DESCRIPTION="Aplicación de firma electrónica desarrollada por el Ministerio de Hacienda y Administraciones Públicas"
HOMEPAGE="https://firmaelectronica.gob.es/Home/Ciudadanos/Aplicaciones-Firma.html"
SRC_URI="https://estaticos.redsara.es/comunes/autofirma/currentversion/AutoFirma_Linux.zip"

LICENSE="GPL-2 EUPL-1.1"
SLOT="0"
KEYWORDS="~amd64"

RDEPEND="dev-java/icedtea-bin
         dev-libs/openssl
         www-client/firefox-bin"  # Para tener fija la ubicación de pref
DEPEND="${RDEPEND}
        app-arch/unzip
        dev-libs/nss[utils]"


src_unpack() {
# La función por defecto no crea un directorio que necesita src_prepare

  einfo "unpack..."

  if [[ -n ${A} ]]; then  # A= Todos los archivos fuente
    mkdir ${S}  # Crear el directorio para usar src_prepare
    cd ${S}
    unpack ${A}  # unpack busca en distdir

    mkdir ${S}/deb/  # Directorio donde descomprimir el .deb
    cd ${S}/deb/
    ar x ${S}/AutoFirma_1_6_5.deb data.tar.xz

    mkdir ${S}/deb/data/  # Directorio donde descompromir data.tar.xz
    cd ${S}/deb/data/
    tar xvf ${S}/deb/data.tar.xz
  fi
}

src_install() {
  einfo "install..."

  # AutoFirma.js
  # Ponerlo en /etc/firefox/pref/ no sirve de nada
  mkdir -p  ${D}/opt/firefox/default/pref/
  cp ${S}/deb/data/etc/firefox/pref/AutoFirma.js ${D}/opt/firefox/default/pref/

  # AutoFirma
  mkdir -p ${D}/usr/bin/
  cp ${S}/deb/data/usr/bin/AutoFirma ${D}/usr/bin/

  # AutoFirma.jar
  mkdir -p ${D}/usr/lib/AutoFirma/
  cp ${S}/deb/data/usr/lib/AutoFirma/AutoFirma.jar ${D}/usr/lib/AutoFirma/

  # AutoFirma.png
  cp ${S}/deb/data/usr/lib/AutoFirma/AutoFirma.png ${D}/usr/lib/AutoFirma/

  # AutoFirmaConfigurador.jar
  cp ${S}/deb/data/usr/lib/AutoFirma/AutoFirmaConfigurador.jar ${D}/usr/lib/AutoFirma/

  # AutoFirma.svg
  mkdir	-p ${D}/usr/share/AutoFirma/
  cp ${S}/deb/data/usr/share/AutoFirma/AutoFirma.svg ${D}/usr/share/AutoFirma/

  # afirma.desktop
  mkdir -p ${D}/usr/share/applications/
  cp ${S}/deb/data/usr/share/applications/afirma.desktop ${D}/usr/share/applications/
}

pkg_postinst() {
  xdg_desktop_database_update
  # Por indicación de emerge al instalar

  java -jar /usr/lib/AutoFirma/AutoFirmaConfigurador.jar
  # Genera nuevos archivos:
  # autofirma.pfx, AutoFirma_ROOT.cer, script.sh, uninstall.sh

  chmod +x /usr/lib/AutoFirma/script.sh
  /usr/lib/AutoFirma/script.sh
  # Instala certificado en firefox

  openssl x509 -inform der -in /usr/lib/AutoFirma/AutoFirma_ROOT.cer -out /usr/lib/AutoFirma/AutoFirma_ROOT.pem
  mv /usr/lib/AutoFirma/AutoFirma_ROOT.pem /usr/lib/AutoFirma/AutoFirma_ROOT.crt
  mkdir -p /usr/local/share/ca-certificates/
  cp /usr/lib/AutoFirma/AutoFirma_ROOT.crt /usr/local/share/ca-certificates/AutoFirma_ROOT.crt
  update-ca-certificates
  # Instala certificado en sistema (SSL)
}

pkg_postrm() {
  chmod +x /usr/lib/AutoFirma/uninstall.sh
  /usr/lib/AutoFirma/uninstall.sh
  # Desinstala certificado en firefox

  rm -R /usr/lib/AutoFirma
  # Eliminamos los restos

  xdg_desktop_database_update
  # Por indicación de emerge al instalar
}

<< 'kkk'
src_prepare() {
  einfo "prepare..."
  cp ${DISTDIR}/ProfilesIni.java clienteafirma-1.6.5/afirma-keystores-mozilla/src/main/java/es/gob/afirma/keystores/mozilla/
  cp ${DISTDIR}/NSPreferences.java clienteafirma-1.6.5/afirma-keystores-mozilla/src/main/java/es/gob/afirma/keystores/mozilla/NSPreferences.java

  eapply_user
  # Obligatorio
}

src_configure() {
  einfo "configure..."
  cd ${WORKDIR}/${P}
  sed '$i\  <localRepository>${WORKDIR/${P}/maven</localRepository>' $(mvn -v | grep usr | cut -d " " -f3)/conf/settings.xml > settings-mod.xml
  # configuración personalizada para maven en este ebuild
}

src_compile() {
  einfo "compile..."
  cd ${WORKDIR}/${P}
  cd clienteafirma-1.6.5/afirma-ui-simple-configurator/
  mvn clean install -s ${WORKDIR}/${P}/settings-mod.xml -Denv=install -DskipTests
  # Contruir AutoFirmaConfigurador.jar

  cd ${WORKDIR}/${P}
  cd clienteafirma-1.6.5/afirma-simple/
  mvn clean install -s ${WORKDIR}/${P}/settings-mod.xml -Denv=install -DskipTests
  # Contruir AutoFirma.jar
}

src_install() {
  einfo "install..."
  mkdir ${D}/usr/lib/AutoFirma
  cp ${WORKDIR}/${p}/clienteafirma-1.6.5/afirma-ui-simple-configurator/target/AutoFirmaConfigurador.jar ${D}/usr/lib/AutoFirma/
  java -jar ${D}/usr/lib/AutoFirma/AutoFirmaConfigurador.jar
  chmod +x ${D}/usr/lib/AutoFirma/script.sh
  ${D}/usr/lib/AutoFirma/script.sh
  openssl x509 -inform der -in ${D}/usr/lib/AutoFirma/AutoFirma_ROOT.cer -out ${D}/usr/lilib/AutoFirma/AutoFirma_ROOT.pem
  mv ${D}/usr/lib/AutoFirma/AutoFirma_ROOT.pem ${D}/usr/lib/AutoFirma/AutoFirma_ROOT.crt
  mkdir -p ${D}/usr/local/share/ca-certificates/
  cp ${D}/usr/lib/AutoFirma/AutoFirma_ROOT.crt ${D}/usr/local/share/ca-certificates/AutoFirma_ROOT.crt
  mkdir -p ${D}/etc/firefox/pref/
  einfo "descargar zip binario y copiar AutoFirma.js a su sitio..."
}

src_postinst() {
  update-ca-certificates
}
kkk
