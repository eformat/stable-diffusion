# stable-diffusion

Stable diffusion built using podman based on `quay.io/fedora/fedora:36`

![images/stable-diffusion.png](images/stable-diffusion.png)

## Prerequisites

- a working nvidia GPU with cuda (the stable diffusion model uses torch with cuda python libs)

I have a dell-xps-15 that is not new (4 years old at least), and my setup looks like this:

```bash
$ lspci | egrep -i 'nvidia|VGA'
00:02.0 VGA compatible controller: Intel Corporation HD Graphics 630 (rev 04)
01:00.0 3D controller: NVIDIA Corporation GP107M [GeForce GTX 1050 Mobile] (rev a1)
```

Note that i do not use the NVIDIA GPU for video (intel i915 gpu is fine for that). So i blacklist `nvidia, nvidia_drm` on boot and load it later. I use `dkms` and not the `akmod` kernel modules for this reason.

I use the f35 repo running fc36. There is also a f36 repo that is known not to work! be warned ... Nvidia and Cuda Setup, the abbreviated version.

```bash
# this gets me the latest nvidia driver
dnf config-manager --add-repo https://developer.download.nvidia.com/compute/cuda/repos/fedora35/x86_64/cuda-fedora35.repo
dnf -y module install nvidia-driver:latest-dkms
dnf -y install cuda
dkms install -m nvidia -v 515.48.07
# i also need this cause my nvidia card is older
dnf -y install https://mirrors.rpmfusion.org/nonfree/fedora/rpmfusion-nonfree-release-$(rpm -E %fedora).noarch.rpm
dnf -y install xorg-x11-drv-nvidia-470xx-cuda
```

You can check everything works before you start, try this locally

```bash
python3.10 -c "import torch; print(torch.cuda.is_available())"
```

- podman with oci-hook configured properly for nvidia

Nothing fancy here, this is older gpu with only 4GB RAM.

```bash
podman run --rm --security-opt=label=disable --hooks-dir=/usr/share/containers/oci/hooks.d/ docker.io/nvidia/cuda:11.2.2-base-ubi8 /usr/bin/nvidia-smi


Wed Nov 23 05:21:19 2022
+-----------------------------------------------------------------------------+
| NVIDIA-SMI 520.61.05    Driver Version: 520.61.05    CUDA Version: 11.8     |
|-------------------------------+----------------------+----------------------+
| GPU  Name        Persistence-M| Bus-Id        Disp.A | Volatile Uncorr. ECC |
| Fan  Temp  Perf  Pwr:Usage/Cap|         Memory-Usage | GPU-Util  Compute M. |
|                               |                      |               MIG M. |
|===============================+======================+======================|
|   0  NVIDIA GeForce ...  Off  | 00000000:01:00.0 Off |                  N/A |
| N/A   56C    P8    N/A /  N/A |      0MiB /  4096MiB |      0%      Default |
|                               |                      |                  N/A |
+-------------------------------+----------------------+----------------------+
                                                                               
+-----------------------------------------------------------------------------+
| Processes:                                                                  |
|  GPU   GI   CI        PID   Type   Process name                  GPU Memory |
|        ID   ID                                                   Usage      |
|=============================================================================|
|  No running processes found                                                 |
+-----------------------------------------------------------------------------+
```

## Build the OCI Image

Download the data. This will take a while and approx (12GB) disk 😲

```bash
dnf -q install aria2
./download.sh
```

Build the container  using podman

```bash
make build
```

Run it

```bash
make podman-run
```

## Demo It

Browse to `http://0.0.0.0:7860/` and type in some text. In this example i was using:

```text
forest wanderer by dominic mayer, anthony jones, Loish, painterly style by Gerald parel, craig mullins, marc simonetti, mike mignola, flat colors illustration, bright and colorful, high contrast, Mythology, cinematic, detailed, atmospheric, epic , concept art, Matte painting, Lord of the rings, Game of Thrones, shafts of lighting, mist, , photorealistic, concept art, volumetric light, cinematic epic + rule of thirds
```

![images/tmpcgvezq90.png](images/tmpcgvezq90.png)


## Attribution

Forked with 💕 from here. Check it out if you want to build other UI's.

https://github.com/AbdBarho/stable-diffusion-webui-docker