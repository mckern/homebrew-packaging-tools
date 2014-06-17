require 'formula'

class Rpmdevtools < Formula
  homepage 'https://fedorahosted.org/rpmdevtools/'
  url 'https://fedorahosted.org/releases/r/p/rpmdevtools/rpmdevtools-8.4.tar.xz'
  version '8.4'
  sha1 'b65681bc2890d9bcc0ec7c05b893c56cac3d7402'

  depends_on 'help2man'
  depends_on 'mckern/packaging-tools/rpm'
  depends_on :python

  patch :DATA

  def install
    args = %W[
        --prefix=#{prefix}
        --localstatedir=#{var}
    ]

    system "./configure", *args
    system "make"
    system "make install"
  end
end

__END__
diff --git a/Makefile.in b/Makefile.in
index 1433144..356a9f4 100644
--- a/Makefile.in
+++ b/Makefile.in
@@ -1001,7 +1001,7 @@
 	COLUMNS=1000 $(HELP2MAN) -s 1 -N -h -h -v -v $(<D)/$(<F) -o $@
 
 %.8: %
-	COLUMNS=1000 $(HELP2MAN) -s 8 -N $(<D)/$(<F) -o $@
+	COLUMNS=1000 $(HELP2MAN) --no-discard-stderr -s 8 -N $(<D)/$(<F) -o $@
 
 install-exec-hook:
 	cd $(DESTDIR)$(bindir) && \
