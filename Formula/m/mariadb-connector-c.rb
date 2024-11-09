class MariadbConnectorC < Formula
  desc "MariaDB database connector for C applications"
  homepage "https://mariadb.org/download/?tab=connector&prod=connector-c"
  # TODO: Remove backward compatibility library symlinks on breaking version bump
  url "https://archive.mariadb.org/connector-c-3.4.1/mariadb-connector-c-3.4.1-src.tar.gz"
  mirror "https://fossies.org/linux/misc/mariadb-connector-c-3.4.1-src.tar.gz/"
  sha256 "0a7f2522a44a7369c1dda89676e43485037596a7b1534898448175178aedeb4d"
  license "LGPL-2.1-or-later"
  revision 1
  head "https://github.com/mariadb-corporation/mariadb-connector-c.git", branch: "3.4"

  # The REST API may omit the newest major/minor versions unless the
  # `olderReleases` parameter is set to `true`.
  livecheck do
    url "https://downloads.mariadb.org/rest-api/connector-c/all-releases/?olderReleases=true"
    strategy :json do |json|
      json["releases"]&.map do |_, group|
        group["children"]&.map do |release|
          next if release["status"] != "stable"

          release["release_number"]
        end
      end&.flatten
    end
  end

  bottle do
    sha256 arm64_sequoia:  "25f4e277c66f07d9a44a9fa1de9bb8ae8e48263990bd15670d7b59c453c02adf"
    sha256 arm64_sonoma:   "9ab49eed7ae6ecd45418141b22d8adaa132e34d017f35f271af537a1e25f0107"
    sha256 arm64_ventura:  "9372de968ba5aa44d100641b56f5f83776a1a983f407c6cea0825699b59b9e4e"
    sha256 arm64_monterey: "a3af823c47ba2a1bc560cd2baaed6b55b46c1ea6f88bf9e718e78b91495b56a7"
    sha256 sonoma:         "ab0d5e5a88633b85c506310c58a6a1708524f6bf193388c1a5908c664b161b19"
    sha256 ventura:        "184babcbdf95cfa26185cba6a739b4e2cf8202bab863ece1e64a23346b8cf714"
    sha256 monterey:       "fa37fe897f387a4ede7236b22e45d1009bb28f35ab373a2fb6c20c3e7a0a4ee1"
    sha256 x86_64_linux:   "13cdebe984f4f9e6344d552fda0bd4fb304099becaf1e7918140220d87de8b45"
  end

  keg_only "it conflicts with mariadb"

  depends_on "cmake" => :build
  depends_on "openssl@3"
  depends_on "zstd"

  uses_from_macos "curl"
  uses_from_macos "krb5"
  uses_from_macos "zlib"

  def install
    rm_r "external"

    args = %W[
      -DINSTALL_LIBDIR=#{lib}
      -DINSTALL_MANDIR=#{man}
      -DWITH_EXTERNAL_ZLIB=ON
      -DWITH_MYSQLCOMPAT=ON
      -DWITH_UNIT_TESTS=OFF
    ]

    system "cmake", "-S", ".", "-B", "build", *args, *std_cmake_args
    system "cmake", "--build", "build"
    system "cmake", "--install", "build"

    # Add mysql_config symlink for compatibility which simplifies building
    # some dependents. This is done in the full `mariadb` installation[^1]
    # but not in the standalone `mariadb-connector-c`.
    #
    # [^1]: https://github.com/MariaDB/server/blob/main/cmake/symlinks.cmake
    bin.install_symlink "mariadb_config" => "mysql_config"

    # Temporary symlinks for backwards compatibility.
    # TODO: Remove in future version update.
    lib.glob(shared_library("*")) { |f| (lib/"mariadb").install_symlink f }

    # TODO: Automatically compress manpages in brew
    Utils::Gzip.compress(*man3.glob("*.3"))
  end

  test do
    system bin/"mariadb_config", "--cflags"
  end
end
