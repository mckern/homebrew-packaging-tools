class Rpm4 < Formula
  desc "Version 4 of the Standard RPM Package Manager"
  homepage "http://www.rpm.org/"
  url "http://rpm.org/releases/rpm-4.12.x/rpm-4.12.0.1.tar.bz2"
  sha256 "77ddd228fc332193c874aa0b424f41db1ff8b7edbb6a338703ef747851f50229"

  depends_on "pkg-config" => :build
  depends_on "nss"
  depends_on "nspr"
  depends_on "libmagic"
  depends_on "popt"
  depends_on "lua51"
  depends_on "berkeley-db"
  depends_on "xz"
  depends_on "libarchive"
  depends_on :python

  conflicts_with "rpm", :because => "These are conflicting forks of the same tool."

  def patches
    DATA
  end

  def install
    # some of nss/nspr formulae might be keg-only:
    ENV.append "CPPFLAGS", "-I#{Formula["nss"].opt_include}/nss"
    ENV.append "CPPFLAGS", "-I#{Formula["nspr"].opt_include}/nspr"
    ENV.append "LDFLAGS", "-L#{Formula["nss"].opt_lib} -L#{Formula["nspr"].opt_lib}"

    # Append Python flags
    ENV.append "CFLAGS", "-undefined dynamic_lookup"

    # pkg-config support was removed from lua 5.2:
    ENV["LUA_CFLAGS"] = "-I#{HOMEBREW_PREFIX}/include/lua5.1"
    ENV["LUA_LIBS"] = "-L#{HOMEBREW_PREFIX}/lib -llua5.1"

    args = %W[
      --disable-dependency-tracking
      --prefix=#{prefix}
      --sysconfdir=#{HOMEBREW_PREFIX}/etc
      --localstatedir=#{HOMEBREW_PREFIX}/var
      --with-external-db
      --with-lua
      --without-hackingdocs
      --enable-python
    ]

    system "./configure", *args
    system "make"
    system "make", "install"

    # the default install makes /usr/bin/rpmquery a symlink to /bin/rpm
    # by using ../.. but that doesn"t really work with any other prefix.
    ln_sf "rpm", "#{bin}/rpmquery"
    ln_sf "rpm", "#{bin}/rpmverify"
  end

  def test_spec
    <<-EOS.undent
      Summary:   Test package
      Name:      test
      Version:   1.0
      Release:   1
      License:   Public Domain
      Group:     Development/Tools
      BuildArch: noarch

      %description
      Trivial test package

      %prep
      %build
      %install
      mkdir -p $RPM_BUILD_ROOT/tmp
      touch $RPM_BUILD_ROOT/tmp/test

      %files
      /tmp/test

      %changelog

    EOS
  end

  def rpmdir(macro)
    Pathname.new(`#{bin}/rpm --eval #{macro}`.chomp)
  end

  test do
    (testpath/"var/lib/rpm").mkpath
    (testpath/".rpmmacros").write <<-EOS.undent
      %_topdir		#{testpath}/var/lib/rpm
      %_specdir		%{_topdir}/SPECS
      %_tmppath		%{_topdir}/tmp
    EOS

    system "#{bin}/rpm", "-vv", "-qa", "--dbpath=#{testpath}"
    rpmdir("%_builddir").mkpath
    specfile = rpmdir("%_specdir")+"test.spec"
    specfile.write(test_spec)
    system "#{bin}/rpmbuild", "-ba", specfile
    assert File.exist?(testpath/"var/lib/rpm/SRPMS/test-1.0-1.src.rpm")
  end
end

__END__
diff --git a/lib/poptALL.c b/lib/poptALL.c
index 541e8c4..5cecc2a 100644
--- a/lib/poptALL.c
+++ b/lib/poptALL.c
@@ -244,7 +244,7 @@ rpmcliInit(int argc, char *const argv[], struct poptOption * optionsTable)
     int rc;
     const char *ctx, *execPath;
 
-    setprogname(argv[0]);       /* Retrofit glibc __progname */
+    xsetprogname(argv[0]);       /* Retrofit glibc __progname */
 
     /* XXX glibc churn sanity */
     if (__progname == NULL) {
diff --git a/rpm2cpio.c b/rpm2cpio.c
index 89ebdfa..f35c7c8 100644
--- a/rpm2cpio.c
+++ b/rpm2cpio.c
@@ -21,7 +21,7 @@ int main(int argc, char *argv[])
     off_t payload_size;
     FD_t gzdi;
     
-    setprogname(argv[0]);	/* Retrofit glibc __progname */
+    xsetprogname(argv[0]);	/* Retrofit glibc __progname */
     rpmReadConfigFiles(NULL, NULL);
     if (argc == 1)
 	fdi = fdDup(STDIN_FILENO);
diff --git a/rpmqv.c b/rpmqv.c
index da5f2ca..d033d21 100644
--- a/rpmqv.c
+++ b/rpmqv.c
@@ -92,8 +92,8 @@ int main(int argc, char *argv[])
 
     /* Set the major mode based on argv[0] */
 #ifdef	IAM_RPMQV
-    if (rstreq(__progname, "rpmquery"))	bigMode = MODE_QUERY;
-    if (rstreq(__progname, "rpmverify")) bigMode = MODE_VERIFY;
+    if (rstreq(__progname ? __progname : "", "rpmquery"))	bigMode = MODE_QUERY;
+    if (rstreq(__progname ? __progname : "", "rpmverify")) bigMode = MODE_VERIFY;
 #endif
 
 #if defined(IAM_RPMQV)
diff --git a/system.h b/system.h
index f3b1bab..bf264f5 100644
--- a/system.h
+++ b/system.h
@@ -21,6 +21,7 @@
 #ifdef __APPLE__
 #include <crt_externs.h>
 #define environ (*_NSGetEnviron())
+#define fdatasync fsync
 #else
 extern char ** environ;
 #endif /* __APPLE__ */
diff --git a/lib/header.c b/lib/header.c
index f78ba78..8b2701e 100644
--- a/lib/header.c
+++ b/lib/header.c
@@ -107,19 +107,6 @@ static const size_t headerMaxbytes = (32*1024*1024);
    (((_e)->info.tag >= RPMTAG_HEADERIMAGE) && ((_e)->info.tag < RPMTAG_HEADERREGIONS))
 #define    ENTRY_IN_REGION(_e) ((_e)->info.offset < 0)
 
-/* Convert a 64bit value to network byte order. */
-RPM_GNUC_CONST
-static uint64_t htonll(uint64_t n)
-{
-#if __BYTE_ORDER__ == __ORDER_LITTLE_ENDIAN__
-    uint32_t *i = (uint32_t*)&n;
-    uint32_t b = i[0];
-    i[0] = htonl(i[1]);
-    i[1] = htonl(b);
-#endif
-    return n;
-}
-
 Header headerLink(Header h)
 {
     if (h != NULL)

diff --git a/system.h b/system.h
index 3be8856..e39531c 100644
--- a/system.h
+++ b/system.h
@@ -92,10 +92,10 @@ char * stpncpy(char * dest, const char * src, size_t n);
 #if __GLIBC_MINOR__ >= 1
 #define	__progname	__assert_program_name
 #endif
-#define	setprogname(pn)
+#define	xsetprogname(pn)
 #else
 #define	__progname	program_name
-#define	setprogname(pn)	\
+#define	xsetprogname(pn)	\
   { if ((__progname = strrchr(pn, '/')) != NULL) __progname++; \
     else __progname = pn;		\
   }
