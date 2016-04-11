class Rpmlint < Formula
  desc "Tool for checking common errors in rpm packages"
  homepage "https://github.com/rpm-software-management/rpmlint"
  url "https://github.com/rpm-software-management/rpmlint/archive/rpmlint-1.8.tar.gz"
  sha256 "ba78ad9ae556cad2590400935d406c4e5cb9cd88348d312b8f13561c76f5f105"

  depends_on "rpm4"
  depends_on "libmagic" => [:recommended, "with-python"]
  depends_on "enchant" => [:recommended, "with-python"]
  depends_on "xz"
  depends_on :python

  def install
    inreplace "rpmlint", "/usr/share/rpmlint/config", "#{HOMEBREW_PREFIX}/etc/rpmlint/config"
    %w[rpmlint rpmdiff].each do |bin|
      inreplace bin, "/usr/share/rpmlint", "#{HOMEBREW_PREFIX}/lib/rpmlint"
      inreplace bin, "/usr/bin/python", "/usr/bin/env python"
    end

    args = [
      "BINDIR=#{bin}",
      "LIBDIR=#{lib}/rpmlint",
      "ETCDIR=#{etc}",
      "MANDIR=#{man}"
    ]

    ENV.append "CFLAGS", "-undefined dynamic_lookup"
    ENV.deparallelize

    system "make", "COMPILE_PYC=1"
    system "make", "install", "prefix=#{prefix}", *args
  end
end
