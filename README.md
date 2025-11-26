# Cosmere Grub Theme

This theme was written for a resultion of 1920x1080.

## Installation

Clone the repository:
```
$ git clone https://github.com/crizzy9/cosmere_grub_theme
```
Switch to the repository folder:
```
$ cd cosmere_grub_theme
```
Run the installation script:
```
$ ./install.sh
```

If you're on NixOS use the following derivation instead and then just import the theme in `boot.loader.grub.theme`
```nix
{ stdenv, fetchFromGitHub, lib }:

stdenv.mkDerivation rec {
  pname = "grub-theme-cosmere";
  version = "510aee2";

  src = fetchFromGitHub {
    owner = "crizzy9";
    repo = "cosmere_grub_theme";
    rev = "${version}";
    hash = "sha256-KecmSHzeeK6aYen0EOHU/SyWh7bEtDUjcn/7IX0Ki8I=";
  };

  dontBuild = true;
  dontConfigure = true;

  installPhase = ''
    runHook preInstall

    # Create the theme directory
    mkdir -p $out/

    # Copy all theme files from the stormlight directory
    cp -r $src/stormlight/* $out/

    runHook postInstall
  '';

  meta = with lib; {
    description = "Cosmere-themed GRUB bootloader theme";
    homepage = "https://github.com/crizzy9/cosmere_grub_theme";
    license = licenses.mit;
    platforms = platforms.linux;
  };
}
```

## Screenshot
![](https://github.com/semimqmo/sekiro_grub_theme/blob/main/screenshot.png?raw=true)

## Troubleshooting

### Fonts Not Displaying Correctly
If you see the background image but fonts appear as default GRUB fonts (small monospace), this is usually because the font generation step failed during installation. Try these solutions:

**Option 1: Re-run installation with font tools (Recommended)**
1. **Install GRUB font tools** (if not already installed):
   ```bash
   # Ubuntu/Debian
   sudo apt install grub2-common

   # Fedora/RHEL/CentOS
   sudo dnf install grub2-tools

   # Arch Linux
   sudo pacman -S grub

   # NixOS
   nix-shell -p grub2
   ```
2. **Re-run the installation script**:
   ```bash
   sudo ./install.sh
   ```
   The script will now detect the font tools and generate the required font files automatically.

**Option 2: Manual font regeneration**
If the above doesn't work, manually regenerate the font files:
1. **Generate font files manually**:
   ```bash
   cd /usr/share/grub/themes/stormlight
   sudo grub-mkfont -s 36 -o CaslonAntique_36.pf2 "CaslonAntique.ttf"
   sudo grub-mkfont -s 45 -o CaslonAntique_45.pf2 "CaslonAntique.ttf"
   sudo grub-mkfont -s 16 -o fira_code_16.pf2 "FiraCode-Regular.ttf"
   sudo grub-mkfont -s 20 -o fira_code_20.pf2 "FiraCode-Regular.ttf"
   ```

2. **Update GRUB configuration**:
   ```bash
   sudo update-grub
   # or on some systems:
   sudo grub-mkconfig -o /boot/grub/grub.cfg
   # or:
   sudo grub2-mkconfig -o /boot/grub2/grub.cfg
   ```

3. **Verify font files exist**:
   ```bash
   ls -la /usr/share/grub/themes/stormlight/*.pf2
   ```

### Theme Not Loading
- Ensure `GRUB_TERMINAL_OUTPUT="gfxterm"` is set in `/etc/default/grub`
- Check that the theme path is correct in `/etc/default/grub`
- Run the installation script with sudo privileges


## Theme Preview
Use the [grub2-theme-preview](https://github.com/hartwork/grub2-theme-preview) tool
For NixOs use the following derivation to use the preview tool and test it using `grub2-theme-preview ./stormlight --resolution 1920x1080 --vga virtio --display gtk --full-screen`

```nix
{ fetchFromGitHub, lib, python3, grub2_efi, qemu, xorg, libisoburn, mtools
, coreutils, makeWrapper, OVMF }:

python3.pkgs.buildPythonApplication rec {
  pname = "grub2-theme-preview";
  # version = "2.9.1";
  version = "95828b2";
  pyproject = true;

  src = fetchFromGitHub {
    owner = "hartwork";
    repo = "grub2-theme-preview";
    rev = "${version}";
    hash = "sha256-yHa5AWExpiPs/bL55gcZc6cj5Z0QH8862Rt76oHM2Lc=";
  };

  nativeBuildInputs = [ makeWrapper ];

  build-system = with python3.pkgs; [ setuptools ];

  propagatedBuildInputs = [
    grub2_efi
    qemu
    xorg.xrandr
    libisoburn # Provides xorriso command
    mtools # Provides mcopy for creating bootable images
    coreutils # Core utilities
    OVMF # UEFI firmware for QEMU
  ];

  # Wrap the binary to ensure all dependencies are in PATH
  # Set G2TP_GRUB_LIB to point to the GRUB library directory in the Nix store
  # Set G2TP_OVMF_IMAGE to point to the OVMF firmware image
  postInstall = ''
    wrapProgram $out/bin/grub2-theme-preview \
      --prefix PATH : ${
        lib.makeBinPath [
          grub2_efi
          qemu
          libisoburn
          mtools
          coreutils
          xorg.xrandr
        ]
      } \
      --set G2TP_GRUB_LIB "${grub2_efi}/lib/grub" \
      --set G2TP_OVMF_IMAGE "${OVMF.fd}/FV/OVMF_CODE.fd"
  '';

  # No tests in the repository
  doCheck = false;

  meta = with lib; {
    description = "Preview a GRUB 2.x theme using KVM/QEMU";
    homepage = "https://github.com/hartwork/grub2-theme-preview";
    license = licenses.gpl2Plus;
    platforms = platforms.linux;
    maintainers = [ ];
  };
}
```
