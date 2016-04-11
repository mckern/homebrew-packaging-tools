class Rpmdevtools < Formula
  desc "Many scripts to aid in RPM package development."
  homepage "https://fedorahosted.org/rpmdevtools/"
  url "https://fedorahosted.org/releases/r/p/rpmdevtools/rpmdevtools-8.6.tar.xz"
  sha256 "566c6d7a05d80ab9e20414d6aa8df7328578261f3d997686e53da09917f66b38"

  depends_on "help2man"
  depends_on "rpm4"
  depends_on :python

  patch :DATA

  def install
    args = %W[
      --prefix=#{prefix}
      --localstatedir=#{var}
    ]

    ENV.append "CFLAGS", "-undefined dynamic_lookup"

    system "./configure", *args
    system "make"

    %w[
      rpmdev-bumpspec
      rpmdev-checksig
      rpmdev-rmdevelrpms
      rpmdev-rmdevelrpms.py
      rpmdev-sort
      rpmdev-vercmp
    ].each do |bin|
      inreplace bin, "#!/usr/bin/python", "#!/usr/bin/env python"
    end

    system "make", "install"
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
