# General
│00:42 <@navs> lol.

# Installation
First clone the repository for some particular project. 

    $ git clone https://github.com/arizvisa/lolfuzz3 some-software-name.lol

Python is used for some of the scripts that are required for building. These
scripts also require some external `python` modules which are packaged within
the `requirements.txt` in the root of the repository. This can be used with
`pip` in order to install all of the required modules.

    $ python -m pip install -r requirements.txt

To install them local to the current user, one can simply provide the `--user`
option to `pip`.

    $ python -m pip install --user -r requirements.txt

## HashiCorp Packer

This software depends on [HashiCorp's Packer](http://packer.io/). This software
is written in [Go](https://golang.org/) and is used to automate the building of
virtual machine templates. For more information, you can visit the "What is Packer?"
section at [http://packer.io/intro/index.html](http://packer.io/intro/index.html)

To install it, you can either visit [http://packer.io/downloads.html](http://packer.io/downloads.html)
to download it, or compile from source as documented [here](http://packer.io/intro/getting-started/install.html#compiling-from-source)
The repository containing HashiCorp's Packer is hosted at [GitHub](http://github.com/)
under [hashicorp/packer](http://github.com/hashicorp/packer/).

The following will also install using `go get` assuming you have `go` installed
and in your path. The latest version of `packer` at the time of writing this
document is tag `v1.4.4`.

    $ go get -u -v github.com/hashicorp/packer
    ...
    $ git -C $GOPATH/src/github.com/hashicorp/packer checkout v1.4.4
    $ go install github.com/hashicorp/packer/...

After downloading or compiling packer, ensure the `packer` binary somewhere in
your path. You can run `packer version` to confirm it is working.

### Post-Processor Plugin for HashiCorp Packer (packer-post-processor-vagrant-vmware-ovf)

To automatically output the resulting templates as a deploying OVF template, one
can choose to install this plugin. The plugin itself is hosted on [GitHub](https://github.com/)
and can be found under the repository [frapposelli/packer-post-processor-vagrant-vmware-ovf](https://github.com/frapposelli/packer-post-processor-vagrant-vmware-ovf).

## GNU Make (and some posix tools)

The makefiles within this software use specific features that are only available
in GNU's flavor of `make` which is hosted at [ftp://ftp.gnu.org/pub/make](ftp://ftp.gnu.org/pub/make).
Some other posix utilities are used by this software such as `bash` and `printf`
which must be in the path. On some platforms, you may find GNU's Make is named
`gmake`. You can check which name for `make` to use by passing the `--version`
option to `make` or `gmake`.

    $ make --version

If on the Windows platform, these tools can be provided by [Msys2](http://www.msys2.org/),
the [MingW/MSYS](http://www.mingw.org/wiki/MSYS) build environment, the
[Cygwin Project](http://www.cygwin.com/), or Microsoft's
[Windows Subsystem for Linux (WSL)](https://docs.microsoft.com/en-us/windows/wsl/install-win10)
that is available with Windows 10. It is, however, recommended by the author to
use [Msys2](http://www.msys2.org/) as it is GNU compliant, and is typically
faster due to linking with Microsoft's C Runtime instead of trying to simulate a
full-fledged posix environment.

When using the software on the Windows platform, in all actuality a full-fledged
posix environment is not necessary and you should be fine just having these
tools in your path. You will be calling `make` directly, so its name also
doesn't really matter.

## jq (Command-line JSON processor)

JSON is used in numerous places and as a result, the `jq` tool is required to
be in your path. This tool exposes the ability to query and transform JSON at
the command-line. For more information, the homepage for `jq` is located at
[https://stedolan.github.io/jq](https://stedolan.github.io/jq/),

In order to install `jq`, it is likely the tool is available via your package
manager if you're using a Linux distribution. If it is not available in your
package manager, or you're using Windows or another alternative platform, a list
of already built binaries can be found at [https://stedolan.github.io/jq/download](https://stedolan.github.io/jq/download/).
After downloading it, simply ensure that it is in your path by trying `jq --version`.

## OpenSSH (ssh-keygen)

The SSH protocol is used to communicate with a master template and thus in order
to facilitate authentication to a deployed template, an SSH client such as
[OpenSSH](https://www.openssh.com/) or [PuTTY](https://www.chiark.greenend.org.uk/~sgtatham/putty/)
is required.

One part of [OpenSSH](https://www.openssh.com/) which is required to build a
master box is the `ssh-keygen` binary which comes with it. The
[ssh-keygen](https://man.openbsd.org/ssh-keygen.1) tool is used during building
in order to pre-generate a public/private keypair which is used to authenticate
to a master. These generated keys are then to be committed into the repository
after the template has been deployed so that other users may have access to the
master hosts available in the project.

On the Windows platform, a binary for `ssh-keygen` may be hard to come by.
However, a [GitHub](http://github.com/) project has been created under
[PowerShell/Win32-OpenSSH](https://github.com/PowerShell/Win32-OpenSSH) which
may be used to get just the binary. Under the releases page found at
[https://github.com/PowerShell/Win32-OpenSSH/releases](https://github.com/PowerShell/Win32-OpenSSH/releases/),
one can download an archive of the release and extract just the `ssh-keygen`
binary. More information about this can be found at the repository's wiki page
found at [https://github.com/PowerShell/Win32-OpenSSH/wiki](https://github.com/PowerShell/Win32-OpenSSH/wiki/Install-Win32-OpenSSH)

Once `ssh-keygen` has finally been made available, simply ensure that it is in
your path. This is the only [OpenSSH](https://www.openssh.com/) binary required
for building templates.

## OpenSSL (Cryptography and SSL/TLS Toolkit)

In order to facilitate authorization and authentication, [OpenSSL](https://www.openssl.org/)
is needed. This is used to generate public/private keys as well as calculate
and verify signatures in a number of places. On posix environments, this tool
is likely already installed. If not, it more than likely can be found in your
distribution's package manager. Nonetheless, the source can be downloaded at
[https://www.openssl.org/source](https://www.openssl.org/source/) to build it.

If on the Windows platform, some urls to binaries that have been built by
others can be found on the wiki page at [https://wiki.openssl.org/index.php/Binaries](https://wiki.openssl.org/index.php/Binaries).
Once `openssl` has been made available through some means, simply ensure that
the `openssl` binary is in your path.

## VMware's OVFTool

If one wants to convert a VM built with HashiCorp's Packer into a packaged
template in order to simplify deployment into VMware's platforms, VMware
provides a tool to do this.

This is `ovftool`, and can be located at VMware's developer support page which
is found at [https://www.vmware.com/support/developer/ovf](https://www.vmware.com/support/developer/ovf).
Once the virtual machine has been built, `ovftool` can be used to convert it
into different formats or to even deploy it against VMware's virtualization
platform. An example of converting a virtual machine into an OVF template is as
follows.

    $ ovftool --compress=9 /path/to/machine/machine-name.vmx /target/template/path/machine-name.ovf

This will take a moment to compress the disks associated with the machine, and
archive it into a few files. The manifest file which contains signatures for
all files associated with the machine will be named `machine-name.mf`, along
with all of the hard disks which will be prefixed with `machine-name`. The
`machine-name.ovf` file can then be used to deploy the machine into your
virtualization infrastructure.
