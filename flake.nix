{
  description = "MeshCore Flutter Application";

  inputs = {
    nixpkgs.url = "github:nixos/nixpkgs/nixos-unstable";
    flake-utils.url = "github:numtide/flake-utils";
  };

  outputs = { self, nixpkgs, flake-utils }:
    flake-utils.lib.eachDefaultSystem (system:
      let
        pkgs = nixpkgs.legacyPackages.${system};
      in
      {
        devShells.default = (pkgs.mkShell.override {
          stdenv = if pkgs.stdenv.hostPlatform.isLinux then pkgs.clangStdenv else pkgs.stdenv;
        }) {
          nativeBuildInputs = with pkgs; [
            cmake
            ninja
            pkg-config
          ];

          buildInputs = with pkgs; [
            # Flutter and Dart
            flutter

            # Java (required for Android development)
            jdk17

            # Android development tools
            android-tools
            gradle

            # For the shell hook to set up the environment for Flutter development
            gtk3
            glib
            sysprof
            libdatrie

            # Additional tools for installing Android SDK if not present
            curl
            unzip
          ] ++ pkgs.lib.optionals pkgs.stdenv.hostPlatform.isLinux [
            pkgs.libsysprof-capture
            pkgs.jq
            pkgs.binutils
            pkgs.util-linux
          ];

          shellHook = ''
            echo "MeshCore Flutter Development Environment"
            export LD_LIBRARY_PATH="${pkgs.lib.makeLibraryPath [pkgs.gtk3 pkgs.glib pkgs.sysprof pkgs.libdatrie]}:$LD_LIBRARY_PATH"
            
            # Setup Android SDK in home directory (standard location)
            export ANDROID_HOME="$HOME/Android/Sdk"
            export ANDROID_SDK_ROOT="$ANDROID_HOME"
            export PATH="$ANDROID_HOME/cmdline-tools/latest/bin:$ANDROID_HOME/platform-tools:$ANDROID_HOME/tools/bin:$PATH"
            
            echo "Android SDK: $ANDROID_HOME"
            echo ""
            
            # Check if Android SDK exists and offer to download if not
            if [ ! -d "$ANDROID_HOME" ]; then
              echo "WARNING: Android SDK not found at $ANDROID_HOME"
              echo ""
              echo "To download and set up the Android SDK, run this command:"
              echo ""
              cat << 'EOF'
mkdir -p ~/Android/Sdk && cd ~/Android/Sdk && \
curl -o cmdline-tools.zip ${if pkgs.stdenv.hostPlatform.isDarwin then "https://dl.google.com/android/repository/commandlinetools-mac-10406996_latest.zip" else "https://dl.google.com/android/repository/commandlinetools-linux-10406996_latest.zip"} && \
unzip -q cmdline-tools.zip && \
mkdir -p cmdline-tools/latest && \
mv cmdline-tools/* cmdline-tools/latest/ 2>/dev/null || echo "Warning: failed to move Android cmdline-tools into 'latest' directory; please check your SDK layout." >&2 && \
rm cmdline-tools.zip && \
cd cmdline-tools/latest/bin && \
yes | ./sdkmanager --sdk_root=~/Android/Sdk 'platform-tools' && \
echo "Android SDK setup complete!"
EOF
              echo ""
              echo "Then run 'flutter doctor' again to verify."
              echo ""
            else
              echo "Android SDK found at $ANDROID_HOME"
            fi
            
            echo "To check that everything is set up correctly, run 'flutter doctor' and ensure there are no issues."
          '';
        };
      }
    );
}
